import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exercise.dart';
import '../localization.dart';
import '../utils/number_input.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final bool isPr;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.isPr = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.54);
    final showVolume = exercise.sets > 1 || exercise.reps > 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  translate(exercise.name),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              Text(
                '${formatNumber(exercise.weight)}kg',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: muted,
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      constraints: const BoxConstraints(),
                      onPressed: onEdit,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      padding: const EdgeInsetsDirectional.only(start: 12),
                      constraints: const BoxConstraints(),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                DateFormat('yyyy-MM-dd').format(exercise.date),
                style: TextStyle(color: muted, fontSize: 14),
              ),
              if (showVolume) ...[
                const SizedBox(width: 12),
                Text(
                  '${exercise.sets} × ${exercise.reps}',
                  style: TextStyle(color: muted, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
              const Spacer(),
              if (isPr) _PrBadge(color: theme.primaryColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrBadge extends StatelessWidget {
  final Color color;
  const _PrBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            translate('PR'),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
