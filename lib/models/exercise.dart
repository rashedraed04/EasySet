import 'package:hive/hive.dart';

class Exercise {
  final String id;
  final String name;
  final double weight;
  final DateTime date;
  final int sets;
  final int reps;

  const Exercise({
    required this.id,
    required this.name,
    required this.weight,
    required this.date,
    this.sets = 1,
    this.reps = 1,
  });

  /// Epley estimate. A single rep is the weight itself.
  double get oneRepMax => reps <= 1 ? weight : weight * (1 + reps / 30);

  double get volume => weight * reps * sets;

  // Stored as a plain map (Hive and Firestore both accept it) so new fields
  // can be added later without breaking data that is already saved.
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'weight': weight,
        'date': date.millisecondsSinceEpoch,
        'sets': sets,
        'reps': reps,
      };

  factory Exercise.fromMap(Map map) => Exercise(
        id: map['id'] as String,
        name: map['name'] as String,
        weight: (map['weight'] as num).toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch((map['date'] as num).toInt()),
        sets: (map['sets'] as num?)?.toInt() ?? 1,
        reps: (map['reps'] as num?)?.toInt() ?? 1,
      );
}

/// Reads the positional binary format used before reps existed. Only used once,
/// to copy old data into the current map-based box.
class LegacyExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 0;

  @override
  Exercise read(BinaryReader reader) {
    return Exercise(
      id: reader.readString(),
      name: reader.readString(),
      weight: reader.readDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      sets: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeDouble(obj.weight);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeInt(obj.sets);
  }
}
