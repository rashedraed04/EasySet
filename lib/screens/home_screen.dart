import 'package:flutter/material.dart';
import '../localization.dart';
import '../models/exercise.dart';
import '../models/workout_template.dart';
import '../services/db_service.dart';
import '../services/pr_service.dart';
import '../widgets/log_exercise_sheet.dart';
import '../widgets/rest_timer_bar.dart';
import '../utils/number_input.dart';
import 'graph_tab.dart';
import 'routines_tab.dart';
import 'settings_tab.dart';
import 'template_editor_screen.dart';
import 'workout_session_screen.dart';
import 'workouts_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _showLogExerciseSheet({Exercise? initialExercise}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomSheetTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: LogExerciseSheet(
          initialExercise: initialExercise,
          onSave: _saveExercise,
        ),
      ),
    );
  }

  Future<void> _saveExercise(Exercise exercise) async {
    await DBService.addExercise(exercise);
    final isPr = PrService.isPersonalRecord(exercise, DBService.getExercisesNamed(exercise.name));
    if (isPr && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('${translate('New PR!')} ${exercise.name} ${formatNumber(exercise.weight)}kg'),
        ));
    }
  }

  void _openEditor([WorkoutTemplate? template]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TemplateEditorScreen(template: template)),
    );
  }

  void _startWorkout(WorkoutTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkoutSessionScreen(template: template)),
    );
  }

  Widget? _buildFab() {
    switch (_currentIndex) {
      case 0:
        return FloatingActionButton(
          onPressed: () => _showLogExerciseSheet(),
          child: const Icon(Icons.add, size: 32),
        );
      case 1:
        return FloatingActionButton(
          onPressed: () => _openEditor(),
          child: const Icon(Icons.add, size: 32),
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Easy Set',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            tooltip: translate('Rest Timer'),
            icon: const Icon(Icons.timer_outlined),
            onPressed: () => showRestTimerSheet(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          WorkoutsTab(onEdit: (ex) => _showLogExerciseSheet(initialExercise: ex)),
          RoutinesTab(onStart: _startWorkout, onEdit: _openEditor),
          const GraphTab(),
          const SettingsTab(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RestTimerBar(),
          Container(
            color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.list, translate('Workouts'), 0),
                  _buildNavItem(Icons.fitness_center, translate('Routines'), 1),
                  _buildNavItem(Icons.show_chart, translate('Graph'), 2),
                  _buildNavItem(Icons.settings, translate('Settings'), 3),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final theme = Theme.of(context);
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? theme.primaryColor
        : theme.bottomNavigationBarTheme.unselectedItemColor;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
