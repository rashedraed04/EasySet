import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exercise.dart';
import '../localization.dart';
import '../services/db_service.dart';
import '../utils/ids.dart';
import '../utils/number_input.dart';
import 'number_stepper.dart';

const String _addNewMarker = '+_ADD_NEW_+';

class LogExerciseSheet extends StatefulWidget {
  final Function(Exercise) onSave;
  final Exercise? initialExercise;

  const LogExerciseSheet({super.key, required this.onSave, this.initialExercise});

  @override
  State<LogExerciseSheet> createState() => _LogExerciseSheetState();
}

class _LogExerciseSheetState extends State<LogExerciseSheet> {
  String? _selectedExercise;
  List<String> _exerciseOptions = [];

  late final TextEditingController _weightController;
  late DateTime _selectedDate;
  late int _sets;
  late int _reps;
  String? _error;

  @override
  void initState() {
    super.initState();
    _exerciseOptions = DBService.getExerciseOptions();

    final initial = widget.initialExercise;
    if (initial != null) {
      _selectedExercise = initial.name;
      // The name may have been removed from the dropdown list since this
      // session was logged. A dropdown whose value is not among its items
      // asserts, so keep the name selectable for the duration of the edit.
      if (!_exerciseOptions.contains(initial.name)) {
        _exerciseOptions = [..._exerciseOptions, initial.name]..sort();
      }
      _weightController = TextEditingController(text: formatNumber(initial.weight));
      _selectedDate = initial.date;
      _sets = initial.sets;
      _reps = initial.reps;
    } else {
      _weightController = TextEditingController(text: '');
      _selectedDate = DateTime.now();
      _sets = 3;
      _reps = 8;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<String?> _showAddExerciseDialog() {
    final customController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
          title: Text(translate('Add New Exercise'), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
          content: TextField(
            controller: customController,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: translate('Exercise Name'),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(translate('Cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, customController.text.trim()),
              child: Text(translate('Add')),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmRemoveOption(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
        title: Text(translate('Remove from list')),
        content: Text(
          '${translate('Remove this exercise from the list?')} $name\n${translate('Logged sessions are kept.')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(translate('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(translate('Remove'), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  void _save() {
    final name = _selectedExercise;
    if (name == null || name.isEmpty || name == _addNewMarker) {
      setState(() => _error = translate('Choose an exercise'));
      return;
    }
    // An unparsable weight must never be stored as 0.
    final weight = parseNumber(_weightController.text);
    if (weight == null) {
      setState(() => _error = translate('Enter a valid weight'));
      return;
    }

    final exercise = Exercise(
      id: widget.initialExercise?.id ?? newId(),
      name: name,
      weight: weight,
      date: _selectedDate,
      sets: _sets,
      reps: _reps,
    );

    widget.onSave(exercise);
    Navigator.pop(context);
  }

  void _stepWeight(double delta) {
    final current = parseNumber(_weightController.text) ?? 0.0;
    final next = (current + delta) < 0 ? 0.0 : current + delta;
    _weightController.text = formatNumber(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                translate('Log Exercise'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedExercise,
                decoration: InputDecoration(
                  labelText: translate('Exercise Name'),
                ),
                dropdownColor: theme.bottomSheetTheme.backgroundColor,
                selectedItemBuilder: (BuildContext context) {
                  final List<Widget> items = [];
                  for (final value in _exerciseOptions) {
                    items.add(Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color)));
                  }
                  items.add(Text(translate('Add New Exercise'), style: TextStyle(color: theme.primaryColor)));
                  return items;
                },
                items: [
                  ..._exerciseOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              if (!await _confirmRemoveOption(value)) return;
                              await DBService.removeExerciseOption(value);
                              if (!mounted) return;
                              setState(() {
                                _exerciseOptions.remove(value);
                                if (_selectedExercise == value) {
                                  _selectedExercise = null;
                                }
                              });
                              navigator.pop();
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  DropdownMenuItem<String>(
                    value: _addNewMarker,
                    child: Row(
                      children: [
                        Icon(Icons.add, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        Text(translate('Add New Exercise'), style: TextStyle(color: theme.primaryColor)),
                      ],
                    ),
                  ),
                ],
                onChanged: (String? newValue) async {
                  if (newValue == _addNewMarker) {
                    final customName = await _showAddExerciseDialog();
                    if (customName != null && customName.isNotEmpty) {
                      await DBService.addExerciseOption(customName);
                      if (!mounted) return;
                      setState(() {
                        if (!_exerciseOptions.contains(customName)) {
                          _exerciseOptions.add(customName);
                          _exerciseOptions.sort();
                        }
                        _selectedExercise = customName;
                        _error = null;
                      });
                    } else {
                      setState(() {});
                    }
                  } else {
                    setState(() {
                      _selectedExercise = newValue;
                      _error = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: translate('Weight (kg)'),
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          onPressed: () => _stepWeight(-2.5),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () => _stepWeight(2.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.inputDecorationTheme.fillColor ?? const Color(0xFF1A1A3A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translate('Date'),
                              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEE, MMM dd').format(_selectedDate),
                              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: NumberStepper(
                      label: translate('Sets'),
                      value: _sets,
                      max: 50,
                      onChanged: (v) => setState(() => _sets = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: NumberStepper(
                      label: translate('Reps'),
                      value: _reps,
                      max: 200,
                      onChanged: (v) => setState(() => _reps = v),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        translate('Save'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_outline, color: Colors.black),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
