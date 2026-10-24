# Easy Set

Offline-first gym tracker for Android, built with Flutter. Log weight, sets and reps,
build reusable routines, track personal records and progress graphs, and use the rest
timer. Everything works without an account; signing in with Google backs the data up
to Firebase and syncs it across devices. English and Arabic (RTL), light and dark themes.

Made by Rashed Al-Awamleh.

- Feature and code map: [app_info.md](app_info.md)
- Firebase details and sync behaviour: [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

## Architecture

```
screens / widgets
      │  read and write
      ▼
DBService ──────── Hive boxes on the device (what the UI shows; works offline)
      │  mirrors every change while signed in
      ▼
CloudService ───── Firestore users/{uid}/exercises | templates | meta/options
                   ▲ changes from the user's other devices arrive via snapshot listeners
```

- **Local first:** Hive is the source of truth, so the app starts and works offline and
  before sign-in. Startup never waits for the network.
- **Backup:** Firebase Auth (Google Sign-In) + Cloud Firestore, project `easyset-rashed`.
  Firestore queues writes made offline. On a device's first sign-in, local data that is
  missing in the cloud is uploaded; cloud data is never overwritten by it.
- **Security:** every user can only access their own `users/{uid}` documents
  ([firestore.rules](firestore.rules)); Realtime Database is locked
  ([database.rules.json](database.rules.json)). The app has no server of its own.
- **Platforms:** Android. iOS code exists but Firebase is not configured for it, so it
  would run in local-only mode.

| Folder | Contents |
| --- | --- |
| `lib/models/` | `Exercise`, `WorkoutTemplate` (stored as plain maps in Hive and Firestore) |
| `lib/services/` | `db_service` (Hive), `cloud_service` (sign-in and sync), `settings_service`, `pr_service` (personal records), `rest_timer_service` |
| `lib/screens/` | the four tabs, routine editor, workout session |
| `lib/widgets/` | reusable UI pieces |
| `test/` | unit and widget tests |

## Run it locally

Requirements: Flutter 3.32.4 (stable), Android Studio (Android SDK and its bundled JDK),
an Android device or emulator.

```
flutter pub get
flutter run
```

Checks (CI runs both on every push and pull request, see `.github/workflows/ci.yml`):

```
flutter analyze
flutter test
```

Google Sign-In only works for signing keys registered in Firebase. On a new computer,
add that computer's debug SHA-1 (step 3 below) or sign-in fails in debug builds.

## What is in git and what is not

| File | Committed | Why |
| --- | --- | --- |
| `lib/firebase_options.dart`, `android/app/google-services.json` | yes | Project identifiers, not secrets. Access is controlled by the security rules. |
| `firestore.rules`, `database.rules.json`, `firebase.json`, `.firebaserc` | yes | Rules are deployed from the repo. |
| `android/key.properties`, `*.jks`, `*.keystore` | **never** | Release signing key and passwords. Git-ignored; keep backups somewhere safe. |
| `android/local.properties` | no | Paths on your machine (created by Flutter). |
| `build/symbols/` | no | Needed to read crash stack traces of obfuscated builds; keep a private copy per release. |

## Release to Google Play

1. **Choose the final package name first.** Google Play rejects `com.example.*`, and the
   package name can never change after the first upload. See
   [Change the package name](#change-the-package-name).
2. **Create the upload key** (once) and keep a backup of the file and passwords:
   ```
   keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   `keytool` is in `C:\Program Files\Android\Android Studio\jbr\bin`. Then copy
   `android/key.properties.example` to `android/key.properties` and fill it in. Release
   builds are signed with this key; without the file they fall back to the debug key,
   which Google Play rejects.
3. **Register signing fingerprints in Firebase** (Project settings → your Android app →
   Add fingerprint), SHA-1 and SHA-256 for:
   - the upload key: `keytool -list -v -keystore android/app/upload-keystore.jks -alias upload`
   - the debug key of each development computer:
     `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android`
   - the **Play App Signing** key, after the first upload (Play Console → your app →
     App integrity → App signing). Without it, Google Sign-In fails for users who install
     from Google Play even though your own builds work.

   Then download `google-services.json` again into `android/app/`.
4. **Bump the version** in `pubspec.yaml` (`version: 0.1.0+1` → `0.1.1+2`). The number
   after `+` must increase with every upload.
5. **Build the App Bundle**, obfuscated:
   ```
   flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
   ```
   Upload `build/app/outputs/bundle/release/app-release.aab`. Copy `build/symbols/` to a
   private folder named after the version; `flutter symbolize` needs it to decode crash
   stack traces from that release.
6. **Deploy the security rules** whenever they change (the repo is the source of truth):
   ```
   firebase login
   firebase deploy --only firestore:rules,database
   ```
7. **Play Console.** Create the app, upload to *Internal testing* first, and install from
   Google Play to test sign-in (that checks the Play signing fingerprint). Before
   production, Google Play also requires:
   - a **privacy policy URL** (the app stores the user's Google name, email and workout data);
   - the **Data safety** form;
   - **account deletion:** apps where users create an account must let them request deletion
     in the app and through a web page. Signing in creates a Firebase account with stored
     data, so this applies. The app does not have this feature yet.
   - new personal developer accounts must run a closed test (currently 12+ testers for
     14 days) before they can publish to production.

### Firebase console checklist

- Deploy the rules (step 6). Realtime Database was found open to anonymous reads on
  2026-10-24; `database.rules.json` closes it (or delete the unused database).
- Restrict the API key: Google Cloud console → APIs & Services → Credentials → the Android
  key → restrict to Android apps (package name + SHA-1 from step 3). Test sign-in and sync
  right after; a missing fingerprint here breaks both.
- Optional: Firebase App Check with Play Integrity, and a billing budget alert if the
  project is ever moved to the paid plan.

## Change the package name

The app id is `com.example.gym_app` today. To change it (for example to `com.rashed.easyset`):

1. In `android/app/build.gradle.kts`, change `namespace` and `applicationId`.
2. Move `android/app/src/main/kotlin/com/example/gym_app/MainActivity.kt` to the matching
   folder (`.../kotlin/com/rashed/easyset/`) and update its `package` line.
3. Run `flutterfire configure` (needs `dart pub global activate flutterfire_cli` and
   `firebase login`), choose project `easyset-rashed` and Android. It registers the new
   package as a new Android app and rewrites `google-services.json` and
   `lib/firebase_options.dart`.
4. Add the SHA fingerprints (release step 3) to the new Android app in Firebase and
   download `google-services.json` again.
5. Uninstall the old app from test devices (the new id installs as a separate app), run
   it, and test sign-in and sync.

Existing backups are not affected: cloud data belongs to the user's Firebase account in
the same project, not to the package name.

## Switch to another Firebase project

1. Create and set up the project as in [FIREBASE_SETUP.md](FIREBASE_SETUP.md) (Google
   sign-in, Firestore).
2. Run `flutterfire configure --project <new-project-id>` and add the SHA fingerprints.
3. Point the Firebase CLI at it: change `default` in `.firebaserc`, then
   `firebase deploy --only firestore:rules,database`.

Data does not move between projects; users start with an empty cloud backup (their local
data is uploaded on first sign-in).
