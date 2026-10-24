import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:gym_app/models/exercise.dart';
import 'package:gym_app/models/workout_template.dart';
import 'package:gym_app/services/pr_service.dart';
import 'package:gym_app/utils/number_input.dart';

Exercise ex(String id, double weight, int reps, int day, {String name = 'Bench Press'}) => Exercise(
      id: id,
      name: name,
      weight: weight,
      reps: reps,
      date: DateTime(2025, 1, day),
    );

void main() {
  group('number input', () {
    test('parses plain, comma and Arabic-Indic numbers', () {
      expect(parseNumber('80'), 80);
      expect(parseNumber('82.5'), 82.5);
      expect(parseNumber('82,5'), 82.5);
      expect(parseNumber('٨٢٫٥'), 82.5);
      expect(parseNumber('۸۰'), 80);
      expect(parseNumber(' 60 '), 60);
    });

    test('rejects invalid input instead of returning 0', () {
      expect(parseNumber(''), isNull);
      expect(parseNumber('abc'), isNull);
      expect(parseNumber('-5'), isNull);
      expect(parseNumber('1.2.3'), isNull);
      expect(parseWholeNumber('8.5'), isNull);
      expect(parseWholeNumber('٨'), 8);
    });

    test('formats whole numbers without decimals', () {
      expect(formatNumber(80), '80');
      expect(formatNumber(82.5), '82.5');
    });
  });

  group('personal records', () {
    test('first entry is a baseline, not a PR', () {
      expect(PrService.personalRecordIds([ex('a', 100, 5, 1)]), isEmpty);
    });

    test('heavier weight is a PR', () {
      final ids = PrService.personalRecordIds([ex('a', 100, 5, 1), ex('b', 105, 5, 8)]);
      expect(ids, {'b'});
    });

    test('more reps at the same weight is a PR via estimated 1RM', () {
      final ids = PrService.personalRecordIds([ex('a', 100, 5, 1), ex('b', 100, 8, 8)]);
      expect(ids, {'b'});
    });

    test('equal or lower performance is not a PR', () {
      final ids = PrService.personalRecordIds([
        ex('a', 100, 5, 1),
        ex('b', 100, 5, 8),
        ex('c', 90, 5, 15),
      ]);
      expect(ids, isEmpty);
    });

    test('is order independent and compares only against earlier sessions', () {
      final ids = PrService.personalRecordIds([
        ex('late', 90, 5, 20),
        ex('early', 100, 5, 1),
        ex('mid', 110, 5, 10),
      ]);
      expect(ids, {'mid'});
    });

    test('isPersonalRecord ignores other exercises and the candidate itself', () {
      final history = [
        ex('a', 100, 5, 1),
        ex('x', 300, 1, 2, name: 'Deadlift'),
        ex('b', 110, 5, 8),
      ];
      expect(PrService.isPersonalRecord(history[2], history), isTrue);
      expect(PrService.isPersonalRecord(ex('c', 95, 5, 9), history), isFalse);
    });
  });

  group('models', () {
    test('Exercise survives a map round trip and defaults missing reps', () {
      final original = ex('a', 82.5, 6, 3);
      final copy = Exercise.fromMap(original.toMap());
      expect(copy.id, 'a');
      expect(copy.weight, 82.5);
      expect(copy.reps, 6);
      expect(copy.date, original.date);

      final old = Map<String, dynamic>.from(original.toMap())..remove('reps')..remove('sets');
      expect(Exercise.fromMap(old).reps, 1);
      expect(Exercise.fromMap(old).sets, 1);
    });

    test('WorkoutTemplate survives a map round trip', () {
      final template = WorkoutTemplate(
        id: 't',
        name: 'Push',
        createdAt: DateTime(2025, 1, 1),
        items: const [TemplateItem(name: 'Bench Press', sets: 4, reps: 6)],
      );
      final copy = WorkoutTemplate.fromMap(template.toMap());
      expect(copy.name, 'Push');
      expect(copy.items.single.sets, 4);
      expect(copy.items.single.reps, 6);
    });
  });

  group('legacy data', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('gym_hive_test');
      Hive.init(dir.path);
    });

    tearDown(() async {
      await Hive.close();
      dir.deleteSync(recursive: true);
    });

    test('old binary records can still be read and converted to the map format', () async {
      Hive.registerAdapter(LegacyExerciseAdapter());
      final legacy = await Hive.openBox<Exercise>('exercises');
      await legacy.put('1', ex('1', 60, 1, 5));
      await legacy.close();

      final reopened = await Hive.openBox<Exercise>('exercises');
      final migrated = reopened.values.map((e) => e.toMap()).single;
      expect(Exercise.fromMap(migrated).weight, 60);
      expect(Exercise.fromMap(migrated).reps, 1);
    });
  });
}
