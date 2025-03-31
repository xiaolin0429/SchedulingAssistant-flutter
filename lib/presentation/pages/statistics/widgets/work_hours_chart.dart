import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class WorkHoursChart extends StatefulWidget {
  final Map<String, double> dailyWorkHours;
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '工作时长统计',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                    '总工作时长', '${widget.totalWorkHours.toStringAsFixed(1)}小时'),
                _buildStatItem(
                    '平均每日', '${widget.averageWorkHours.toStringAsFixed(1)}小时'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: widget.dailyWorkHours.isEmpty
                  ? const Center(child: Text('暂无数据'))
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
                            maxY: _calculateMaxY(widget.dailyWorkHours),
                            minY: 0,
                            groupsSpace: 12, // 增加柱子组之间的间距
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: Colors.black.withOpacity(0.9),
                                tooltipPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                tooltipMargin: 8,
                                tooltipRoundedRadius: 8,
                                maxContentWidth: 150,
                                rotateAngle: 0,
                                direction: TooltipDirection.top,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  final date = widget.dailyWorkHours.keys
                                      .elementAt(group.x.toInt());
                                  final hours = widget.dailyWorkHours[date];
                                  // 格式化日期显示
                                  final formattedDate = date.split('-').length >
                                          2
                                      ? '${date.split('-')[1]}-${date.split('-')[2]}'
                                      : date;
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
                                        text: '${hours?.toStringAsFixed(1)} 小时',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                              ),
                              touchCallback: (FlTouchEvent event,
                                  BarTouchResponse? touchResponse) {
                                // 添加触摸回调以增强交互性
                                setState(() {
                                  if (event is FlPanEndEvent ||
                                      event is FlTapUpEvent) {
                                    // 手指抬起时，保持高亮状态
                                    if (touchResponse != null &&
                                        touchResponse.spot != null) {
                                      _touchedBarIndex = touchResponse
                                          .spot!.touchedBarGroupIndex;
                                    }
                                  } else if (event is FlTapDownEvent ||
                                      event is FlPanDownEvent) {
                                    // 手指按下时，设置高亮
                                    if (touchResponse != null &&
                                        touchResponse.spot != null) {
                                      _touchedBarIndex = touchResponse
                                          .spot!.touchedBarGroupIndex;
                                    }
                                  } else if (event is FlPointerExitEvent) {
                                    // 指针离开时，取消高亮
                                    _touchedBarIndex = -1;
                                  }
                                });
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 &&
                                        value.toInt() <
                                            widget.dailyWorkHours.length) {
                                      final date = widget.dailyWorkHours.keys
                                          .elementAt(value.toInt());
                                      // 简化日期显示，只显示日
                                      final parts = date.split('-');
                                      if (parts.length > 2) {
                                        return Text(parts[2]);
                                      }
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) {
                                      return const Text('0');
                                    }
                                    return Text(value.toInt().toString());
                                  },
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
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: 1,
                            ),
                            barGroups: _buildBarGroups(),
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

  double _calculateMaxY(Map<String, double> dailyWorkHours) {
    if (dailyWorkHours.isEmpty) return 10;
    final maxHours = dailyWorkHours.values.reduce(max);
    return (maxHours.ceilToDouble() + 1); // 向上取整加1，保证有足够的显示空间
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(widget.dailyWorkHours.length, (index) {
      final date = widget.dailyWorkHours.keys.elementAt(index);
      final hours = widget.dailyWorkHours[date] ?? 0;
      final isTouched = index == _touchedBarIndex;
      final barColor = isTouched ? Colors.blue.shade300 : Colors.blue;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: hours,
            color: barColor,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
