import 'package:flutter/material.dart';
import '../localization.dart';
import '../models/workout_template.dart';
import '../services/db_service.dart';
import '../utils/ids.dart';
import '../widgets/number_stepper.dart';

class TemplateEditorScreen extends StatefulWidget {
  final WorkoutTemplate? template;

  const TemplateEditorScreen({super.key, this.template});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  late final TextEditingController _nameController;
  late List<TemplateItem> _items;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _items = [...?widget.template?.items];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ExercisePicker(),
    );
    if (name == null || !mounted) return;
    // Reuse the numbers from the last item so building a routine is quick.
    final previous = _items.isEmpty ? null : _items.last;
    setState(() => _items.add(TemplateItem(
          name: name,
          sets: previous?.sets ?? 3,
          reps: previous?.reps ?? 8,
        )));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    String? problem;
    if (name.isEmpty) {
      problem = translate('Give the routine a name');
    } else if (_items.isEmpty) {
      problem = translate('Add at least one exercise');
    }
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
      return;
    }

    final existing = widget.template;
    await DBService.saveTemplate(WorkoutTemplate(
      id: existing?.id ?? newId(),
      name: name,
      items: _items,
      createdAt: existing?.createdAt ?? DateTime.now(),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          translate(widget.template == null ? 'New Routine' : 'Edit Routine'),
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          TextButton(onPressed: _save, child: Text(translate('Save'))),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        buildDefaultDragHandles: false,
        header: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: translate('Routine Name'),
              hintText: translate('e.g. Push Day'),
            ),
          ),
        ),
        footer: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: Text(translate('Add Exercise')),
            onPressed: _addExercise,
          ),
        ),
        itemCount: _items.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            _items.insert(newIndex, _items.removeAt(oldIndex));
          });
        },
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            key: ObjectKey(item),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      onPressed: () => setState(() => _items.removeAt(index)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: NumberStepper(
                        label: translate('Sets'),
                        value: item.sets,
                        max: 50,
                        onChanged: (v) => setState(() => _items[index] = item.copyWith(sets: v)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NumberStepper(
                        label: translate('Reps'),
                        value: item.reps,
                        max: 200,
                        onChanged: (v) => setState(() => _items[index] = item.copyWith(reps: v)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Bottom sheet that returns the chosen exercise name.
class _ExercisePicker extends StatefulWidget {
  const _ExercisePicker();

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  late List<String> _options = DBService.getExerciseOptions();

  Future<void> _createNew() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate('Add New Exercise')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: translate('Exercise Name')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(translate('Cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(translate('Add')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await DBService.addExerciseOption(name);
    if (!mounted) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    _options = DBService.getExerciseOptions();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: Icon(Icons.add, color: Theme.of(context).primaryColor),
              title: Text(
                translate('Add New Exercise'),
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              onTap: _createNew,
            ),
            for (final name in _options)
              ListTile(title: Text(name), onTap: () => Navigator.pop(context, name)),
          ],
        ),
      ),
    );
  }
}
