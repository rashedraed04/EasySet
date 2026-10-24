import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../localization.dart';
import '../models/workout_template.dart';
import '../services/db_service.dart';
import '../widgets/confirm_dialog.dart';

class RoutinesTab extends StatelessWidget {
  final void Function(WorkoutTemplate) onStart;
  final void Function(WorkoutTemplate) onEdit;

  const RoutinesTab({super.key, required this.onStart, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: DBService.templatesListenable,
      builder: (context, _, __) {
        final theme = Theme.of(context);
        final templates = DBService.getTemplates();

        if (templates.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                translate('No routines yet. Tap + to create one.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80, top: 16),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.54),
                        onPressed: () => onEdit(template),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(context, template),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (final item in template.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${item.name}  ·  ${item.sets} × ${item.reps}',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: Text(translate('Start Workout')),
                      onPressed: template.items.isEmpty ? null : () => onStart(template),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WorkoutTemplate template) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Routine',
      message: '${translate('Are you sure you want to delete the routine')} ${template.name}?',
    );
    if (confirmed) await DBService.deleteTemplate(template.id);
  }
}
