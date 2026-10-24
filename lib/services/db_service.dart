import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise.dart';
import '../models/workout_template.dart';
import 'cloud_service.dart';
import 'settings_service.dart';

class DBService {
  static const String _logBoxName = 'workout_log';
  static const String _legacyBoxName = 'exercises';
  static const String _optionsBoxName = 'exercise_options';
  static const String _templatesBoxName = 'templates';

  /// Call after `Hive.initFlutter()` and `SettingsService.init()`.
  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(LegacyExerciseAdapter());
    await Hive.openBox(_logBoxName);
    await Hive.openBox(_optionsBoxName);
    await Hive.openBox(_templatesBoxName);
    await _migrateLegacyBox();
  }

  /// Copies workouts saved by older app versions into the current box. The old
  /// box is left untouched, so nothing can be lost if this ever runs twice.
  static Future<void> _migrateLegacyBox() async {
    if (SettingsService.legacyMigrated) return;
    if (await Hive.boxExists(_legacyBoxName)) {
      final legacy = await Hive.openBox<Exercise>(_legacyBoxName);
      final log = _log;
      for (final old in legacy.values) {
        if (!log.containsKey(old.id)) await log.put(old.id, old.toMap());
      }
      await legacy.close();
    }
    await SettingsService.setLegacyMigrated();
  }

  static Box get _log => Hive.box(_logBoxName);
  static Box get _options => Hive.box(_optionsBoxName);
  static Box get _templates => Hive.box(_templatesBoxName);

  // ---------------------------------------------------------------- workouts

  static ValueListenable<Box> get exercisesListenable => _log.listenable();

  static List<Exercise> getExercises() {
    final exercises = _log.values.map((m) => Exercise.fromMap(m as Map)).toList();
    exercises.sort((a, b) => b.date.compareTo(a.date));
    return exercises;
  }

  static List<Exercise> getExercisesNamed(String name) =>
      getExercises().where((e) => e.name == name).toList();

  /// The most recent session of [name], used to pre-fill weights.
  static Exercise? lastEntryFor(String name) {
    final entries = getExercisesNamed(name);
    return entries.isEmpty ? null : entries.first;
  }

  static Future<void> addExercise(Exercise exercise) async {
    await _log.put(exercise.id, exercise.toMap());
    CloudService.pushExercise(exercise);
  }

  static Future<void> deleteExercise(String id) => deleteExercises([id]);

  static Future<void> deleteExercises(Iterable<String> ids) async {
    final list = ids.toList();
    await _log.deleteAll(list);
    for (final id in list) {
      CloudService.removeExercise(id);
    }
  }

  // ------------------------------------------------------- exercise options

  static List<String> getExerciseOptions() {
    final isInitialized = _options.get('initialized', defaultValue: false) as bool;
    if (!isInitialized) {
      final defaultOptions = ['Bench Press', 'Squat', 'Deadlift', 'Overhead Press'];
      final uniqueLoggedNames = _log.values.map((m) => (m as Map)['name'] as String).toSet();
      final initialOptions = {...defaultOptions, ...uniqueLoggedNames}.toList();
      for (final name in initialOptions) {
        _options.put(name, true);
      }
      _options.put('initialized', true);
      initialOptions.sort();
      return initialOptions;
    }

    final options = _options.keys
        .where((key) => key != 'initialized')
        .map((key) => key.toString())
        .toList();
    options.sort();
    return options;
  }

  static bool get optionsInitialized =>
      _options.get('initialized', defaultValue: false) as bool;

  static Future<void> addExerciseOption(String name) async {
    if (!optionsInitialized) getExerciseOptions();
    await _options.put(name, true);
    CloudService.pushOptions(getExerciseOptions());
  }

  static Future<void> removeExerciseOption(String name) async {
    if (!optionsInitialized) getExerciseOptions();
    await _options.delete(name);
    CloudService.pushOptions(getExerciseOptions());
  }

  // --------------------------------------------------------------- templates

  static ValueListenable<Box> get templatesListenable => _templates.listenable();

  static List<WorkoutTemplate> getTemplates() {
    final list = _templates.values.map((m) => WorkoutTemplate.fromMap(m as Map)).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  static Future<void> saveTemplate(WorkoutTemplate template) async {
    await _templates.put(template.id, template.toMap());
    CloudService.pushTemplate(template);
  }

  static Future<void> deleteTemplate(String id) async {
    await _templates.delete(id);
    CloudService.removeTemplate(id);
  }

  // ------------------------------------------- used by CloudService only
  // These write straight to the local boxes and never push back to the cloud.

  static Map<String, Map<String, dynamic>> localExerciseMaps() => {
        for (final e in _log.values)
          (e as Map)['id'] as String: Map<String, dynamic>.from(e),
      };

  static Map<String, Map<String, dynamic>> localTemplateMaps() => {
        for (final t in _templates.values)
          (t as Map)['id'] as String: Map<String, dynamic>.from(t),
      };

  static Future<void> applyRemoteExercises(Map<String, Map<String, dynamic>> upserts) =>
      _log.putAll(upserts);

  static Future<void> removeLocalExercises(Iterable<String> ids) => _log.deleteAll(ids);

  static Future<void> applyRemoteTemplates(Map<String, Map<String, dynamic>> upserts) =>
      _templates.putAll(upserts);

  static Future<void> removeLocalTemplates(Iterable<String> ids) => _templates.deleteAll(ids);

  static Future<void> replaceOptions(List<String> names) async {
    await _options.clear();
    await _options.putAll({for (final n in names) n: true});
    await _options.put('initialized', true);
  }

  static Future<void> clearAllLocal() async {
    await _log.clear();
    await _templates.clear();
    await _options.clear();
  }
}
