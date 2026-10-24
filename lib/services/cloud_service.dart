import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';
import '../models/exercise.dart';
import '../models/workout_template.dart';
import 'db_service.dart';
import 'settings_service.dart';

enum SyncState { signedOut, syncing, synced, error }

/// Google sign-in plus Firestore backup.
///
/// Hive stays the source of truth for the UI, so the app works offline and
/// before sign-in. While signed in, every local change is mirrored to
/// `users/{uid}/...` (Firestore queues writes made offline), and changes made on
/// other devices are applied to Hive through a snapshot listener.
///
/// First sign-in on a device uploads whatever exists locally but not in the
/// cloud yet (the "migration"), so nobody's existing history is stranded.
class CloudService {
  /// False when Firebase is not configured for this build/platform; the app
  /// then simply runs without cloud backup.
  static bool available = false;

  static final ValueNotifier<User?> currentUser = ValueNotifier(null);
  static final ValueNotifier<SyncState> syncState = ValueNotifier(SyncState.signedOut);
  static final ValueNotifier<String?> syncError = ValueNotifier(null);

  static String? _uid;
  static int _generation = 0;
  static final List<StreamSubscription<dynamic>> _subs = [];
  static Future<void>? _googleInit;

  static Future<void> init() async {
    final supported = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!supported) return;

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      _log('Cloud backup disabled: $e');
      return;
    }
    available = true;
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  // -------------------------------------------------------------- auth

  /// Returns null on success or when the user cancelled, otherwise a message.
  static Future<String?> signInWithGoogle() async {
    if (!available) return 'Cloud backup is not set up yet.';
    try {
      _googleInit ??= GoogleSignIn.instance.initialize();
      await _googleInit;
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return 'Google did not return an ID token.';
      await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      return e.description ?? e.code.name;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      _googleInit = null;
      return e.toString();
    }
  }

  /// Local data stays on the device, so the app keeps working after sign-out.
  static Future<void> signOut() async {
    if (!available) return;
    try {
      await FirebaseFirestore.instance
          .waitForPendingWrites()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Offline: queued writes are kept by Firestore and sent on next sign-in.
    }
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }

  static Future<void> retrySync() => _onAuthChanged(FirebaseAuth.instance.currentUser);

  static Future<void> _onAuthChanged(User? user) async {
    final generation = ++_generation;
    currentUser.value = user;
    await _stopSync();
    if (user == null) {
      syncState.value = SyncState.signedOut;
      syncError.value = null;
      return;
    }
    await _startSync(user.uid, generation);
  }

  // -------------------------------------------------------------- sync

  static Future<void> _stopSync() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    _uid = null;
  }

  static DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  static Future<void> _startSync(String uid, int generation) async {
    syncState.value = SyncState.syncing;
    syncError.value = null;
    try {
      final boundUid = SettingsService.cloudUid;
      var needsUpload = boundUid == null || SettingsService.localDirty;

      // The data on this device belongs to another account: never mix it in.
      if (boundUid != null && boundUid != uid) {
        await DBService.clearAllLocal();
        await SettingsService.setLocalDirty(false);
        needsUpload = false;
      }

      // From here on local changes are written to Firestore too.
      _uid = uid;
      final root = _userDoc(uid);

      if (needsUpload) await _uploadLocalOnlyData(root);
      if (generation != _generation) return;

      await SettingsService.setCloudUid(uid);
      _listen(root, generation);
      syncState.value = SyncState.synced;
    } catch (e) {
      if (generation != _generation) return;
      _log('Sync failed: $e');
      syncError.value = e.toString();
      syncState.value = SyncState.error;
    }
  }

  /// Uploads local workouts/routines/exercise names that the cloud does not
  /// have yet. Cloud data is never overwritten, so this is safe to repeat.
  static Future<void> _uploadLocalOnlyData(DocumentReference<Map<String, dynamic>> root) async {
    const server = GetOptions(source: Source.server);
    // Cleared first so edits made while this runs set it again.
    await SettingsService.setLocalDirty(false);
    try {
      final remoteExercises = await root.collection('exercises').get(server);
      final remoteTemplates = await root.collection('templates').get(server);
      final optionsRef = root.collection('meta').doc('options');
      final remoteOptions = await optionsRef.get(server);

      final writes = <void Function(WriteBatch)>[];

      final remoteExerciseIds = remoteExercises.docs.map((d) => d.id).toSet();
      DBService.localExerciseMaps().forEach((id, map) {
        if (!remoteExerciseIds.contains(id)) {
          writes.add((b) => b.set(root.collection('exercises').doc(id), map));
        }
      });

      final remoteTemplateIds = remoteTemplates.docs.map((d) => d.id).toSet();
      DBService.localTemplateMaps().forEach((id, map) {
        if (!remoteTemplateIds.contains(id)) {
          writes.add((b) => b.set(root.collection('templates').doc(id), map));
        }
      });

      // An untouched device only has the built-in defaults: don't resurrect
      // names the user deleted on another device.
      if (DBService.optionsInitialized) {
        final remoteNames =
            ((remoteOptions.data()?['names'] as List?) ?? const []).cast<String>();
        final merged = {...remoteNames, ...DBService.getExerciseOptions()}.toList()..sort();
        if (merged.length != remoteNames.length) {
          writes.add((b) => b.set(optionsRef, {'names': merged}));
        }
      }

      // Firestore batches are limited to 500 operations.
      for (var i = 0; i < writes.length; i += 400) {
        final batch = FirebaseFirestore.instance.batch();
        for (final write in writes.skip(i).take(400)) {
          write(batch);
        }
        await batch.commit();
      }
    } catch (_) {
      await SettingsService.setLocalDirty(true);
      rethrow;
    }
  }

  static void _listen(DocumentReference<Map<String, dynamic>> root, int generation) {
    void onError(Object e) {
      if (generation != _generation) return;
      _log('Sync listener error: $e');
      syncError.value = e.toString();
      syncState.value = SyncState.error;
    }

    // Changes that still have pending local writes are our own echo: the local
    // box already has them.
    void apply(
      QuerySnapshot<Map<String, dynamic>> snap,
      Future<void> Function(Map<String, Map<String, dynamic>>) upsert,
      Future<void> Function(Iterable<String>) remove,
    ) {
      final upserts = <String, Map<String, dynamic>>{};
      final removed = <String>[];
      for (final change in snap.docChanges) {
        if (change.doc.metadata.hasPendingWrites) continue;
        if (change.type == DocumentChangeType.removed) {
          removed.add(change.doc.id);
        } else {
          final data = change.doc.data();
          if (data != null) upserts[change.doc.id] = {...data, 'id': change.doc.id};
        }
      }
      if (upserts.isNotEmpty) upsert(upserts);
      if (removed.isNotEmpty) remove(removed);
    }

    _subs.add(root.collection('exercises').snapshots().listen(
          (snap) => apply(snap, DBService.applyRemoteExercises, DBService.removeLocalExercises),
          onError: onError,
        ));
    _subs.add(root.collection('templates').snapshots().listen(
          (snap) => apply(snap, DBService.applyRemoteTemplates, DBService.removeLocalTemplates),
          onError: onError,
        ));
    _subs.add(root.collection('meta').doc('options').snapshots().listen(
      (doc) {
        if (doc.metadata.hasPendingWrites) return;
        final names = (doc.data()?['names'] as List?)?.cast<String>();
        if (names != null) DBService.replaceOptions(names);
      },
      onError: onError,
    ));
  }

  // ------------------------------------------- mirroring local changes

  static void pushExercise(Exercise e) =>
      _write((root) => root.collection('exercises').doc(e.id).set(e.toMap()));

  static void removeExercise(String id) =>
      _write((root) => root.collection('exercises').doc(id).delete());

  static void pushTemplate(WorkoutTemplate t) =>
      _write((root) => root.collection('templates').doc(t.id).set(t.toMap()));

  static void removeTemplate(String id) =>
      _write((root) => root.collection('templates').doc(id).delete());

  static void pushOptions(List<String> names) =>
      _write((root) => root.collection('meta').doc('options').set({'names': names}));

  static void _write(Future<void> Function(DocumentReference<Map<String, dynamic>> root) op) {
    final uid = _uid;
    if (uid == null) {
      // Not syncing right now: remember to upload on the next sign-in.
      SettingsService.setLocalDirty(true);
      return;
    }
    // Completes only once the server confirms, so it is deliberately not awaited
    // (Firestore keeps the write queued while offline).
    unawaited(op(_userDoc(uid)).catchError((Object e) {
      _log('Cloud write failed: $e');
    }));
  }

  /// Debug builds only: Firebase errors can contain the user's id (in document
  /// paths), and release builds should not write that to the device log.
  static void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
