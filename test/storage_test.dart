import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:gym_app/localization.dart';
import 'package:gym_app/models/exercise.dart';
import 'package:gym_app/services/db_service.dart';
import 'package:gym_app/services/settings_service.dart';
import 'package:gym_app/widgets/log_exercise_sheet.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('gym_storage_test');
    Hive.init(dir.path);
    Hive.resetAdapters();
  });

  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  test('workouts saved by the old app version are migrated, not lost', () async {
    Hive.registerAdapter(LegacyExerciseAdapter());
    final legacy = await Hive.openBox<Exercise>('exercises');
    await legacy.put('a', Exercise(id: 'a', name: 'Squat', weight: 100, date: DateTime(2025, 1, 1), sets: 3));
    await legacy.put('b', Exercise(id: 'b', name: 'Deadlift', weight: 140, date: DateTime(2025, 1, 2), sets: 1));
    await legacy.close();
    Hive.resetAdapters();

    await SettingsService.init();
    await DBService.init();

    final migrated = DBService.getExercises();
    expect(migrated.map((e) => e.id).toSet(), {'a', 'b'});
    expect(migrated.firstWhere((e) => e.id == 'a').sets, 3);
    expect(migrated.firstWhere((e) => e.id == 'a').reps, 1);
    // Exercise names that were logged show up in the dropdown list.
    expect(DBService.getExerciseOptions(), containsAll(['Squat', 'Deadlift']));
    expect(SettingsService.legacyMigrated, isTrue);
  });

  test('theme, language and rest time survive an app restart', () async {
    await SettingsService.init();
    await DBService.init();
    themeNotifier.value = ThemeMode.light;
    languageNotifier.value = 'ar';
    SettingsService.restSeconds.value = 120;
    await Future<void>.delayed(Duration.zero);
    await Hive.close();
    Hive.resetAdapters();

    themeNotifier.value = ThemeMode.dark;
    languageNotifier.value = 'en';
    SettingsService.restSeconds.value = 90;
    Hive.init(dir.path);
    await SettingsService.init();

    expect(themeNotifier.value, ThemeMode.light);
    expect(languageNotifier.value, 'ar');
    expect(SettingsService.restSeconds.value, 120);
  });

  testWidgets('editing a session whose exercise was removed from the list does not crash', (tester) async {
    await tester.runAsync(() async {
      await SettingsService.init();
      await DBService.init();
      await DBService.addExerciseOption('Curl');
      await DBService.removeExerciseOption('Curl'); // gone from the dropdown list
    });
    languageNotifier.value = 'en';

    final old = Exercise(id: 'x', name: 'Curl', weight: 20, date: DateTime(2025, 1, 1));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: LogExerciseSheet(initialExercise: old, onSave: (_) {})),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Curl'), findsWidgets);
  });
}
