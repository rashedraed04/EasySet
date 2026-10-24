import 'dart:async';
import 'package:flutter/material.dart';
import '../localization.dart';
import '../models/exercise.dart';
import '../models/workout_template.dart';
import '../services/db_service.dart';
import '../services/pr_service.dart';
import '../services/rest_timer_service.dart';
import '../services/settings_service.dart';
import '../utils/ids.dart';
import '../utils/number_input.dart';
import '../widgets/number_stepper.dart';
import '../widgets/rest_timer_bar.dart';

class _SessionRow {
  final TemplateItem item;
  final Exercise? last;
  final TextEditingController weight;
  int sets;
  int reps;
  Exercise? entry;
  bool isPr = false;

  _SessionRow(this.item, this.last)
      : weight = TextEditingController(text: last == null ? '' : formatNumber(last.weight)),
        sets = item.sets,
        reps = item.reps;

  bool get logged => entry != null;
}

/// Runs a routine: pre-fills last weights, logs each exercise, flags PRs and
/// starts the rest timer after every logged exercise.
class WorkoutSessionScreen extends StatefulWidget {
  final WorkoutTemplate template;

  const WorkoutSessionScreen({super.key, required this.template});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late final List<_SessionRow> _rows;
  late final DateTime _startedAt;
  late final DateTime _day;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _day = DateUtils.dateOnly(_startedAt);
    _rows = [
      for (final item in widget.template.items) _SessionRow(item, DBService.lastEntryFor(item.name)),
    ];
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    for (final row in _rows) {
      row.weight.dispose();
    }
    super.dispose();
  }

  String get _elapsed {
    final total = DateTime.now().difference(_startedAt).inSeconds;
    final h = total ~/ 3600;
    final rest = formatClock(total % 3600);
    return h > 0 ? '$h:${rest.padLeft(5, '0')}' : rest;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _log(_SessionRow row) async {
    final weight = parseNumber(row.weight.text);
    if (weight == null) {
      _toast(translate('Enter a valid weight'));
      return;
    }

    // Logging again after a correction updates the same entry.
    final entry = Exercise(
      id: row.entry?.id ?? newId(),
      name: row.item.name,
      weight: weight,
      date: _day,
      sets: row.sets,
      reps: row.reps,
    );
    await DBService.addExercise(entry);
    final isPr = PrService.isPersonalRecord(entry, DBService.getExercisesNamed(entry.name));
    if (!mounted) return;

    setState(() {
      row.entry = entry;
      row.isPr = isPr;
    });
    if (isPr) _toast('${translate('New PR!')} ${entry.name} ${formatNumber(weight)}kg');
    RestTimerService.start(SettingsService.restSeconds.value);
  }

  Future<void> _finish() async {
    final done = _rows.where((r) => r.logged).toList();
    if (done.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final volume = done.fold<double>(0, (sum, r) => sum + r.entry!.volume);
    final prs = done.where((r) => r.isPr).length;
    final minutes = DateTime.now().difference(_startedAt).inMinutes;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate('Workout complete')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${translate('Duration')}: $minutes ${translate('min')}'),
            Text('${translate('Exercises')}: ${done.length}/${_rows.length}'),
            Text('${translate('Total volume')}: ${formatNumber(volume)}kg'),
            if (prs > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${translate('New PRs')}: $prs',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(translate('Done')),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.template.name, style: theme.textTheme.titleLarge),
            Text(_elapsed, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: translate('Rest Timer'),
            icon: const Icon(Icons.timer_outlined),
            onPressed: () => showRestTimerSheet(context),
          ),
          TextButton(onPressed: _finish, child: Text(translate('Finish'))),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rows.length,
        itemBuilder: (context, index) => _buildRow(theme, _rows[index]),
      ),
      bottomNavigationBar: const SafeArea(child: RestTimerBar()),
    );
  }

  Widget _buildRow(ThemeData theme, _SessionRow row) {
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7);
    final last = row.last;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: row.logged ? theme.primaryColor : theme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              if (row.isPr)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Icon(Icons.emoji_events, color: theme.primaryColor),
                ),
              if (row.logged) Icon(Icons.check_circle, color: theme.primaryColor),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            last == null
                ? translate('First time - pick a starting weight')
                : '${translate('Last')}: ${formatNumber(last.weight)}kg × ${last.sets} × ${last.reps}',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.weight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(labelText: translate('Weight (kg)')),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _log(row),
                icon: Icon(row.logged ? Icons.refresh : Icons.check),
                label: Text(translate(row.logged ? 'Update' : 'Log')),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: NumberStepper(
                  label: translate('Sets'),
                  value: row.sets,
                  max: 50,
                  onChanged: (v) => setState(() => row.sets = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NumberStepper(
                  label: translate('Reps'),
                  value: row.reps,
                  max: 200,
                  onChanged: (v) => setState(() => row.reps = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
