import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/localization/app_localizations.dart';
import 'dart:math';

class WorkHoursChart extends StatefulWidget {
  final Map<DateTime, double> dailyWorkHours;
  final double totalWorkHours;
  final double averageWorkHours;

  const WorkHoursChart({
    super.key,
    required this.dailyWorkHours,
    required this.totalWorkHours,
    required this.averageWorkHours,
  });

  @override
  State<WorkHoursChart> createState() => _WorkHoursChartState();
}

class _WorkHoursChartState extends State<WorkHoursChart> {
  int _touchedBarIndex = -1;
  bool _isTooltipVisible = false;

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
              AppLocalizations.of(context).translate('work_hours_statistics'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                    AppLocalizations.of(context).translate('total_work_hours'),
                    '${widget.totalWorkHours.toStringAsFixed(1)}${AppLocalizations.of(context).translate('hours_unit')}'),
                _buildStatItem(
                    AppLocalizations.of(context).translate('average_daily'),
                    '${widget.averageWorkHours.toStringAsFixed(1)}${AppLocalizations.of(context).translate('hours_unit')}'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: widget.dailyWorkHours.isEmpty
                  ? Center(
                      child: Text(
                          AppLocalizations.of(context).translate('no_data')))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        // 设置一个足够宽的容器，使柱状图可以横向滚动
                        width: max(MediaQuery.of(context).size.width - 64,
                            widget.dailyWorkHours.length * 40.0),
                        height: 200,
                        padding: const EdgeInsets.only(top: 16, right: 16),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.center,
                            maxY: _calculateMaxY(),
                            minY: 0,
                            groupsSpace: 12, // 增加柱子组之间的间距
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                tooltipBgColor:
                                    const Color.fromARGB(230, 0, 0, 0),
                                tooltipPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                tooltipMargin: 8,
                                tooltipRoundedRadius: 8,
                                maxContentWidth: 150,
                                rotateAngle: 0,
                                direction: TooltipDirection.top,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  if (groupIndex != _touchedBarIndex &&
                                      !_isTooltipVisible) {
                                    return null;
                                  }

                                  final date = widget.dailyWorkHours.keys
                                      .elementAt(group.x.toInt());
                                  final hours = widget.dailyWorkHours[date];
                                  // 格式化日期显示
                                  final formattedDate =
                                      '${date.month}-${date.day}';
                                  return BarTooltipItem(
                                    formattedDate,
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: '\n',
                                      ),
                                      TextSpan(
                                        text:
                                            '${hours?.toStringAsFixed(1)} ${AppLocalizations.of(context).translate('hours_unit')}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              touchCallback: (FlTouchEvent event,
                                  BarTouchResponse? touchResponse) {
                                // 修改触摸回调以增强交互性
                                setState(() {
                                  if (event is FlTapUpEvent) {
                                    // 点击抬起时，切换高亮状态
                                    if (touchResponse != null &&
                                        touchResponse.spot != null) {
                                      if (_touchedBarIndex ==
                                          touchResponse
                                              .spot!.touchedBarGroupIndex) {
                                        // 如果点击的是当前已高亮的柱子，则取消高亮
                                        _touchedBarIndex = -1;
                                        _isTooltipVisible = false;
                                      } else {
                                        // 否则高亮点击的柱子
                                        _touchedBarIndex = touchResponse
                                            .spot!.touchedBarGroupIndex;
                                        _isTooltipVisible = true;
                                      }
                                    } else {
                                      // 点击空白区域，取消高亮
                                      _touchedBarIndex = -1;
                                      _isTooltipVisible = false;
                                    }
                                  } else if (event is FlPanStartEvent ||
                                      event is FlLongPressStart) {
                                    // 长按或拖动开始时，设置高亮
                                    if (touchResponse != null &&
                                        touchResponse.spot != null) {
                                      _touchedBarIndex = touchResponse
                                          .spot!.touchedBarGroupIndex;
                                      _isTooltipVisible = true;
                                    }
                                  }
                                });
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: _bottomTitles,
                                  reservedSize: 30,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: _leftTitles,
                                  reservedSize: 30,
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: false,
                            ),
                            gridData: const FlGridData(
                              show: true,
                              horizontalInterval: 1,
                            ),
                            barGroups: _createBarGroups(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateMaxY() {
    if (widget.dailyWorkHours.isEmpty) return 10;
    final maxVal =
        widget.dailyWorkHours.values.reduce((a, b) => a > b ? a : b) +
            1; // Add 1 to give some space at the top
    return maxVal < 10 ? 10 : maxVal;
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
    final sortedDates = widget.dailyWorkHours.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
      final date = sortedDates[value.toInt()];
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _leftTitles(double value, TitleMeta meta) {
    if (value == 0) {
      return const SizedBox.shrink();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        value.toInt().toString(),
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups() {
    final sortedEntries = widget.dailyWorkHours.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return List.generate(
      sortedEntries.length,
      (index) {
        final entry = sortedEntries[index];
        final isTouched = index == _touchedBarIndex;
        final barColor = isTouched
            ? const Color(0xFF3399FF) // 点击状态为深蓝色
            : const Color(0xFFB3DAFF); // 正常状态为浅蓝色

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: entry.value,
              color: barColor,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}
