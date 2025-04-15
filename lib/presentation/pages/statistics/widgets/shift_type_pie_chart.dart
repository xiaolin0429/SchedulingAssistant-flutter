import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../data/models/shift_type.dart';
import '../../../../core/localization/app_localizations.dart';

class ShiftTypePieChart extends StatefulWidget {
  final Map<ShiftType, int> shiftTypeCountMap;

  const ShiftTypePieChart({
    super.key,
    required this.shiftTypeCountMap,
  });

  @override
  State<ShiftTypePieChart> createState() => _ShiftTypePieChartState();
}

class _ShiftTypePieChartState extends State<ShiftTypePieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('shift_type_distribution'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: widget.shiftTypeCountMap.isEmpty
                  ? Center(
                      child: Text(
                          AppLocalizations.of(context).translate('no_data')))
                  : PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        startDegreeOffset: 180,
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final total = widget.shiftTypeCountMap.values
        .fold<int>(0, (sum, count) => sum + count);
    if (total == 0) return [];

    final List<PieChartSectionData> sections = [];
    int i = 0;

    for (final entry in widget.shiftTypeCountMap.entries) {
      final isTouched = i == _touchedIndex;
      final double radius = isTouched ? 70 : 60;
      final percentage = (entry.value / total * 100).toStringAsFixed(1);

      sections.add(
        PieChartSectionData(
          color: entry.key.colorValue,
          value: entry.value.toDouble(),
          title: '$percentage%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
          badgeWidget: isTouched
              ? _Badge(
                  entry.key.name,
                  size: 40,
                  borderColor: entry.key.colorValue,
                )
              : null,
          badgePositionPercentageOffset: 1.2,
        ),
      );
      i++;
    }

    return sections;
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final double size;
  final Color borderColor;

  const _Badge(
    this.text, {
    required this.size,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
            isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? const Color.fromRGBO(0, 0, 0, 0.3)
                : const Color.fromARGB(128, 0, 0, 0),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: size / 5,
            color: borderColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
