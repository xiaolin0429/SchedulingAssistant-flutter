import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/statistics/statistics_bloc.dart';
import '../../blocs/statistics/statistics_event.dart';
import '../../blocs/statistics/statistics_state.dart';
import 'widgets/month_selector.dart';
import 'widgets/shift_type_pie_chart.dart';
import 'widgets/shift_type_distribution.dart';
import 'widgets/work_hours_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime _selectedMonth = DateTime.now();

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
              return _buildErrorState(context, state);
            } else if (state is StatisticsLoaded) {
              return _buildStatisticsContent(context, state);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, StatisticsError state) {
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
  }

  Widget _buildStatisticsContent(BuildContext context, StatisticsLoaded state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 顶部月份选择器
          MonthSelector(
            selectedMonth: _selectedMonth,
            onMonthChanged: (newMonth) {
              setState(() {
                _selectedMonth = newMonth;
              });
            },
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
          ShiftTypePieChart(
            shiftTypeCountMap: state.shiftTypeCountMap,
          ),

          // 班次类型分布详情
          ShiftTypeDistribution(
            shiftTypePercentages: state.shiftTypePercentages,
            shiftTypeCountMap: state.shiftTypeCountMap,
          ),

          // 工作时长统计图表
          WorkHoursChart(
            dailyWorkHours: state.dailyWorkHours,
            totalWorkHours: state.totalWorkHours,
            averageWorkHours: state.averageWorkHours,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDateRangeDialog(BuildContext context) {
    // 当前日期
    final now = DateTime.now();
    // 初始开始日期（当月1日）
    final initialStartDate = DateTime(now.year, now.month, 1);
    // 初始结束日期（当月最后一天）
    final initialEndDate = DateTime(now.year, now.month + 1, 0);

    // 选择的日期范围
    DateTime startDate = initialStartDate;
    DateTime endDate = initialEndDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择日期范围'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('开始日期'),
                    subtitle: Text(
                        '${startDate.year}-${startDate.month}-${startDate.day}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = picked;
                          // 确保结束日期不早于开始日期
                          if (endDate.isBefore(startDate)) {
                            endDate = startDate;
                          }
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('结束日期'),
                    subtitle:
                        Text('${endDate.year}-${endDate.month}-${endDate.day}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: startDate, // 开始日期之后
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          endDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.read<StatisticsBloc>().add(
                          LoadDateRangeStatistics(startDate, endDate),
                        );
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
