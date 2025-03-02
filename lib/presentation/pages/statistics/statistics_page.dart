import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../../data/models/shift_type.dart';
import '../../blocs/statistics/statistics_bloc.dart';
import '../../blocs/statistics/statistics_event.dart';
import '../../blocs/statistics/statistics_state.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime _selectedMonth = DateTime.now();
  int _touchedIndex = -1; // 添加跟踪被点击扇区的索引
  int _touchedBarIndex = -1; // 添加跟踪被点击柱子的索引

  @override
  void initState() {
    super.initState();
    // 初始加载当前月份的统计数据
    context.read<StatisticsBloc>().add(
          LoadMonthlyStatistics(
            _selectedMonth.year,
            _selectedMonth.month,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<StatisticsBloc, StatisticsState>(
          builder: (context, state) {
            if (state is StatisticsInitial) {
              // 触发加载
              context.read<StatisticsBloc>().add(
                    LoadMonthlyStatistics(
                      _selectedMonth.year,
                      _selectedMonth.month,
                    ),
                  );
              return const Center(child: CircularProgressIndicator());
            } else if (state is StatisticsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is StatisticsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '加载失败',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<StatisticsBloc>().add(
                              LoadMonthlyStatistics(
                                _selectedMonth.year,
                                _selectedMonth.month,
                              ),
                            );
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            } else if (state is StatisticsLoaded) {
              return _buildStatisticsContent(context, state);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildStatisticsContent(BuildContext context, StatisticsLoaded state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 顶部月份选择栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final newMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                    setState(() {
                      _selectedMonth = newMonth;
                    });
                    context.read<StatisticsBloc>().add(
                          UpdateSelectedMonth(newMonth),
                        );
                  },
                ),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedMonth,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedMonth = picked;
                      });
                      context.read<StatisticsBloc>().add(
                            UpdateSelectedMonth(picked),
                          );
                    }
                  },
                  child: Text(
                    '${_selectedMonth.year}年${_selectedMonth.month}月',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        final newMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        );
                        setState(() {
                          _selectedMonth = newMonth;
                        });
                        context.read<StatisticsBloc>().add(
                              UpdateSelectedMonth(newMonth),
                            );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        _showDateRangeDialog(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 选择日期范围按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.date_range, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _showDateRangeDialog(context);
                  },
                  child: const Text('选择日期范围'),
                ),
              ],
            ),
          ),

          // 本月总班次
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  '本月总班次：',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${state.totalShifts}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 班次类型分布饼图
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '班次类型分布',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: state.shiftTypeCountMap.isEmpty
                        ? const Center(child: Text('暂无数据'))
                        : PieChart(
                            PieChartData(
                              sections: _buildPieChartSections(state),
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              startDegreeOffset: 180,
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // 班次类型分布详细数据
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '班次类型分布',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...state.shiftTypePercentages.entries.map(
                    (entry) => _buildDistributionItem(
                      entry.key.name,
                      '${state.shiftTypeCountMap[entry.key] ?? 0}（${entry.value.toStringAsFixed(1)}%）',
                      entry.key.colorValue,
                    ),
                  ),
                  if (state.shiftTypePercentages.isEmpty)
                    const Center(child: Text('暂无数据')),
                ],
              ),
            ),
          ),

          // 工作时长统计
          Card(
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
                      _buildStatItem('总工作时长', '${state.totalWorkHours.toStringAsFixed(1)}小时'),
                      _buildStatItem('平均每日', '${state.averageWorkHours.toStringAsFixed(1)}小时'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: state.dailyWorkHours.isEmpty
                        ? const Center(child: Text('暂无数据'))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              // 设置一个足够宽的容器，使柱状图可以横向滚动
                              width: max(MediaQuery.of(context).size.width - 64, state.dailyWorkHours.length * 40.0),
                              height: 200,
                              padding: const EdgeInsets.only(top: 16, right: 16),
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.center,
                                  maxY: _calculateMaxY(state.dailyWorkHours),
                                  minY: 0,
                                  groupsSpace: 12, // 增加柱子组之间的间距
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      tooltipBgColor: Colors.black.withOpacity(0.9),
                                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      tooltipMargin: 8,
                                      tooltipRoundedRadius: 8,
                                      maxContentWidth: 150,
                                      rotateAngle: 0,
                                      direction: TooltipDirection.top,
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        final date = state.dailyWorkHours.keys.elementAt(group.x.toInt());
                                        final hours = state.dailyWorkHours[date];
                                        // 格式化日期显示
                                        final formattedDate = date.split('-').length > 2 
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
                                    touchCallback: (FlTouchEvent event, BarTouchResponse? touchResponse) {
                                      // 添加触摸回调以增强交互性
                                      setState(() {
                                        if (event is FlPanEndEvent || event is FlTapUpEvent) {
                                          // 手指抬起时，保持高亮状态
                                          if (touchResponse != null && touchResponse.spot != null) {
                                            _touchedBarIndex = touchResponse.spot!.touchedBarGroupIndex;
                                          }
                                        } else if (event is FlTapDownEvent || event is FlPanDownEvent) {
                                          // 手指按下时，设置高亮
                                          if (touchResponse != null && touchResponse.spot != null) {
                                            _touchedBarIndex = touchResponse.spot!.touchedBarGroupIndex;
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
                                          if (value.toInt() >= 0 && value.toInt() < state.dailyWorkHours.length) {
                                            final date = state.dailyWorkHours.keys.elementAt(value.toInt());
                                            final day = date.split('-').last;
                                            return Text(
                                              day,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 10,
                                              ),
                                            );
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
                                          return Text(
                                            '${value.toInt()}h',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          );
                                        },
                                        reservedSize: 30,
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: const FlGridData(
                                    show: true,
                                    horizontalInterval: 2,
                                    drawVerticalLine: false,
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: _buildBarGroups(state.dailyWorkHours),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建饼图数据
  List<PieChartSectionData> _buildPieChartSections(StatisticsLoaded state) {
    final percentages = state.shiftTypePercentages;
    final sections = <PieChartSectionData>[];
    
    int i = 0;
    percentages.forEach((shiftType, percentage) {
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 80.0 : 60.0; // 被点击的扇区半径更大
      
      sections.add(
        PieChartSectionData(
          value: percentage,
          color: shiftType.colorValue,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: radius,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
      i++;
    });

    return sections;
  }

  // 构建柱状图数据
  List<BarChartGroupData> _buildBarGroups(Map<String, double> dailyWorkHours) {
    final groups = <BarChartGroupData>[];
    int index = 0;

    dailyWorkHours.forEach((date, hours) {
      final isSelected = index == _touchedBarIndex;
      groups.add(
        BarChartGroupData(
          x: index++,
          barRods: [
            BarChartRodData(
              toY: hours,
              color: isSelected ? Colors.blue.shade700 : Colors.blue,
              width: isSelected ? 26 : 22, // 选中时增加宽度
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)), // 添加圆角
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _calculateMaxY(dailyWorkHours),
                color: Colors.grey.withOpacity(0.1),
              ),
            ),
          ],
          showingTooltipIndicators: isSelected ? [0] : [], // 选中时显示工具提示指示器
        ),
      );
    });

    return groups;
  }

  // 计算柱状图Y轴最大值
  double _calculateMaxY(Map<String, double> dailyWorkHours) {
    if (dailyWorkHours.isEmpty) return 10;
    final maxHours = dailyWorkHours.values.reduce((a, b) => a > b ? a : b);
    return (maxHours * 1.2).ceilToDouble(); // 增加20%的空间
  }

  // 构建统计项
  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // 构建分布项
  Widget _buildDistributionItem(String title, String percentage, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (color != null)
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                title,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          Text(
            percentage,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 显示日期范围选择对话框
  void _showDateRangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择日期范围'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('本月'),
              onTap: () {
                final now = DateTime.now();
                final firstDay = DateTime(now.year, now.month, 1);
                final lastDay = DateTime(now.year, now.month + 1, 0);
                context.read<StatisticsBloc>().add(
                      LoadDateRangeStatistics(firstDay, lastDay),
                    );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('上月'),
              onTap: () {
                final now = DateTime.now();
                final firstDay = DateTime(now.year, now.month - 1, 1);
                final lastDay = DateTime(now.year, now.month, 0);
                context.read<StatisticsBloc>().add(
                      LoadDateRangeStatistics(firstDay, lastDay),
                    );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('近三个月'),
              onTap: () {
                final now = DateTime.now();
                final firstDay = DateTime(now.year, now.month - 2, 1);
                final lastDay = DateTime(now.year, now.month + 1, 0);
                context.read<StatisticsBloc>().add(
                      LoadDateRangeStatistics(firstDay, lastDay),
                    );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('自定义范围'),
              onTap: () async {
                Navigator.pop(context);
                final DateTimeRange? picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange: DateTimeRange(
                    start: DateTime.now().subtract(const Duration(days: 7)),
                    end: DateTime.now(),
                  ),
                );
                if (picked != null) {
                  context.read<StatisticsBloc>().add(
                        LoadDateRangeStatistics(
                          picked.start,
                          picked.end,
                        ),
                      );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}