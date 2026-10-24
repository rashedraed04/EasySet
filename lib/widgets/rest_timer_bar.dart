import 'package:flutter/material.dart';
import '../localization.dart';
import '../services/rest_timer_service.dart';
import '../services/settings_service.dart';

String formatClock(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Banner shown above the bottom navigation while a rest timer is running.
class RestTimerBar extends StatelessWidget {
  const RestTimerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RestTimerState?>(
      valueListenable: RestTimerService.state,
      builder: (context, timer, _) {
        if (timer == null) return const SizedBox.shrink();
        final theme = Theme.of(context);
        final primary = theme.primaryColor;
        return Container(
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: timer.finished ? 1 : timer.remaining / timer.total,
                  minHeight: 4,
                  color: primary,
                  backgroundColor: primary.withValues(alpha: 0.15),
                ),
              ),
              Row(
                children: [
                  Icon(timer.finished ? Icons.notifications_active : Icons.timer_outlined,
                      color: primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      timer.finished ? translate('Rest over - go!') : formatClock(timer.remaining),
                      style: TextStyle(
                        fontSize: timer.finished ? 16 : 22,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                  if (!timer.finished) ...[
                    TextButton(
                      onPressed: () => RestTimerService.adjust(-15),
                      child: const Text('-15s'),
                    ),
                    TextButton(
                      onPressed: () => RestTimerService.adjust(15),
                      child: const Text('+15s'),
                    ),
                  ],
                  IconButton(
                    tooltip: translate('Dismiss'),
                    icon: const Icon(Icons.close),
                    onPressed: RestTimerService.stop,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Lets the user start a rest timer by hand.
Future<void> showRestTimerSheet(BuildContext context) {
  const presets = [30, 60, 90, 120, 180, 300];
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translate('Rest Timer'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final seconds in presets)
                  ActionChip(
                    label: Text(formatClock(seconds)),
                    onPressed: () {
                      RestTimerService.start(seconds);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                RestTimerService.start(SettingsService.restSeconds.value);
                Navigator.pop(context);
              },
              label: Text(
                '${translate('Start default rest')} (${formatClock(SettingsService.restSeconds.value)})',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
