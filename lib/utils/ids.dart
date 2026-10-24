import 'dart:math';

final Random _rng = Random.secure();

/// Collision-safe id, so entries created on different devices never clash.
String newId() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final salt = _rng.nextInt(1 << 32).toRadixString(36);
  return '$time-$salt';
}
