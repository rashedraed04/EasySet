import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RestTimerState {
  final int total;
  final int remaining;

  const RestTimerState({required this.total, required this.remaining});

  bool get finished => remaining <= 0;
}

/// App-wide rest timer. It keeps counting while the user moves between tabs or
/// screens; `state` is null when no timer is active.
class RestTimerService {
  static final ValueNotifier<RestTimerState?> state = ValueNotifier(null);

  static Timer? _ticker;
  static Timer? _dismissTimer;
  static DateTime? _endsAt;
  static int _total = 0;

  static void start(int seconds) {
    _cancel();
    _total = max(1, seconds);
    _endsAt = DateTime.now().add(Duration(seconds: _total));
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Adds or removes time from a running timer.
  static void adjust(int deltaSeconds) {
    final endsAt = _endsAt;
    final current = state.value;
    if (endsAt == null || current == null || current.finished) return;
    _endsAt = endsAt.add(Duration(seconds: deltaSeconds));
    _total = max(1, _total + deltaSeconds);
    _tick();
  }

  static void stop() {
    _cancel();
    state.value = null;
  }

  static void _cancel() {
    _ticker?.cancel();
    _dismissTimer?.cancel();
    _ticker = null;
    _dismissTimer = null;
    _endsAt = null;
  }

  static void _tick() {
    final endsAt = _endsAt;
    if (endsAt == null) return;
    final remainingMs = endsAt.difference(DateTime.now()).inMilliseconds;
    final remaining = (remainingMs / 1000).ceil();
    if (remaining <= 0) {
      _finish();
    } else {
      state.value = RestTimerState(total: _total, remaining: remaining);
    }
  }

  static void _finish() {
    _ticker?.cancel();
    _ticker = null;
    _endsAt = null;
    state.value = RestTimerState(total: _total, remaining: 0);
    _alert();
    _dismissTimer = Timer(const Duration(seconds: 15), stop);
  }

  static Future<void> _alert() async {
    SystemSound.play(SystemSoundType.alert);
    for (var i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }
}
