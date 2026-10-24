import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../localization.dart';
import '../models/exercise.dart';
import '../services/db_service.dart';
import '../utils/number_input.dart';

class GraphTab extends StatefulWidget {
  const GraphTab({super.key});

  @override
  State<GraphTab> createState() => _GraphTabState();
}

class _GraphTabState extends State<GraphTab> {
  String? _selectedExercise;
  bool _showOneRepMax = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: DBService.exercisesListenable,
      builder: (context, _, __) {
        final theme = Theme.of(context);
        final allExercises = DBService.getExercises();
        if (allExercises.isEmpty) {
          return Center(
            child: Text(
              translate('No exercises logged yet.'),
              style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            ),
          );
        }

        final uniqueNames = allExercises.map((e) => e.name).toSet().toList()..sort();
        final selected =
            uniqueNames.contains(_selectedExercise) ? _selectedExercise! : uniqueNames.first;

        final exercises = allExercises.where((e) => e.name == selected).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                translate('Graph'),
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selected,
                    dropdownColor: theme.colorScheme.surface,
                    icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) setState(() => _selectedExercise = newValue);
                    },
                    items: uniqueNames
                        .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(translate('Weight')),
                    selected: !_showOneRepMax,
                    onSelected: (_) => setState(() => _showOneRepMax = false),
                  ),
                  ChoiceChip(
                    label: Text(translate('Est. 1RM')),
                    selected: _showOneRepMax,
                    onSelected: (_) => setState(() => _showOneRepMax = true),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(child: _buildChart(theme, exercises)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart(ThemeData theme, List<Exercise> exercises) {
    // X is the number of days since the first session, so a gap of two weeks
    // looks like two weeks instead of one step.
    final firstDay = DateUtils.dateOnly(exercises.first.date);
    double dayOf(Exercise e) => DateUtils.dateOnly(e.date).difference(firstDay).inDays.toDouble();
    DateTime dateAt(double x) => firstDay.add(Duration(days: x.round()));

    final spots = exercises
        .map((e) => FlSpot(dayOf(e), _showOneRepMax ? e.oneRepMax : e.weight))
        .toList();

    final span = dayOf(exercises.last);
    final maxX = span < 1 ? 1.0 : span;
    final interval = (maxX / 4).ceilToDouble().clamp(1.0, double.infinity);
    final labelStyle = TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value % interval != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(DateFormat('MMM d').format(dateAt(value)), style: labelStyle),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(formatNumber(value), style: labelStyle),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touched) => touched
                .map((s) => LineTooltipItem(
                      '${DateFormat('MMM d').format(dateAt(s.x))}\n${formatNumber(s.y)}kg',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: theme.primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
