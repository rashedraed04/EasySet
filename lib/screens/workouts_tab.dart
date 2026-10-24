import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../localization.dart';
import '../models/exercise.dart';
import '../services/db_service.dart';
import '../services/pr_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/exercise_card.dart';

class WorkoutsTab extends StatelessWidget {
  final void Function(Exercise) onEdit;

  const WorkoutsTab({super.key, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: DBService.exercisesListenable,
      builder: (context, _, __) {
        final exercises = DBService.getExercises();
        final theme = Theme.of(context);

        if (exercises.isEmpty) {
          return Center(
            child: Text(
              translate('No exercises logged yet.'),
              style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            ),
          );
        }

        final Map<String, List<Exercise>> groupedExercises = {};
        for (final ex in exercises) {
          groupedExercises.putIfAbsent(ex.name, () => []).add(ex);
        }
        final sortedNames = groupedExercises.keys.toList()..sort();

        return ListView.builder(
          itemCount: sortedNames.length,
          padding: const EdgeInsets.only(bottom: 80, top: 16),
          itemBuilder: (context, index) {
            final name = sortedNames[index];
            final group = groupedExercises[name]!; // already newest first
            final prIds = PrService.personalRecordIds(group);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  iconColor: theme.primaryColor,
                  collapsedIconColor: theme.primaryColor,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () => _confirmDeleteGroup(context, name, group),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${group.length} ${translate('sessions')}',
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                  ),
                  children: group.map((ex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ExerciseCard(
                        exercise: ex,
                        isPr: prIds.contains(ex.id),
                        onEdit: () => onEdit(ex),
                        onDelete: () => _confirmDelete(context, ex),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Exercise exercise) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Exercise',
      message: '${translate('Are you sure you want to delete this session of')} ${translate(exercise.name)}?',
    );
    if (confirmed) await DBService.deleteExercise(exercise.id);
  }

  Future<void> _confirmDeleteGroup(BuildContext context, String name, List<Exercise> group) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Exercise',
      message: '${translate('Are you sure you want to delete all sessions of')} ${translate(name)}?',
    );
    if (confirmed) await DBService.deleteExercises(group.map((e) => e.id));
  }
}
