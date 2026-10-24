import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../localization.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

/// Small key/value store for app preferences. Theme and language are restored
/// on start and saved whenever they change.
class SettingsService {
  static const String _boxName = 'settings';
  static late Box _box;

  static final ValueNotifier<int> restSeconds = ValueNotifier(90);

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);

    themeNotifier.value =
        _box.get('theme', defaultValue: 'dark') == 'light' ? ThemeMode.light : ThemeMode.dark;
    final lang = _box.get('language', defaultValue: 'en') as String;
    languageNotifier.value = lang == 'ar' ? 'ar' : 'en';
    restSeconds.value = (_box.get('restSeconds', defaultValue: 90) as num).toInt();

    if (_listening) return;
    _listening = true;
    themeNotifier.addListener(() {
      _save('theme', themeNotifier.value == ThemeMode.light ? 'light' : 'dark');
    });
    languageNotifier.addListener(() => _save('language', languageNotifier.value));
    restSeconds.addListener(() => _save('restSeconds', restSeconds.value));
  }

  static bool _listening = false;

  static void _save(String key, Object value) {
    if (_box.isOpen) _box.put(key, value);
  }

  /// True once the pre-reps "exercises" box has been copied into the new log.
  static bool get legacyMigrated => _box.get('legacyMigrated', defaultValue: false) as bool;
  static Future<void> setLegacyMigrated() => _box.put('legacyMigrated', true);

  /// The account the data on this device belongs to (null = never synced).
  static String? get cloudUid => _box.get('cloudUid') as String?;
  static Future<void> setCloudUid(String? uid) =>
      uid == null ? _box.delete('cloudUid') : _box.put('cloudUid', uid);

  /// True when data was changed while no account was syncing, so the next
  /// sign-in has to upload it.
  static bool get localDirty => _box.get('localDirty', defaultValue: false) as bool;
  static Future<void> setLocalDirty(bool value) async {
    if (localDirty != value) await _box.put('localDirty', value);
  }
}
