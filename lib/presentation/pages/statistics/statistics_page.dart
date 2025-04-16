import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_localizations.dart';
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
  StatisticsLoaded? _previousLoadedState;

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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('statistics')),
      ),
      body: BlocConsumer<StatisticsBloc, StatisticsState>(
        listener: (context, state) {
          if (state is StatisticsLoaded) {
            _previousLoadedState = state;
          }
        },
        builder: (context, state) {
          // 总是显示MonthSelector，即使在加载中
          final topSelector = MonthSelector(
            selectedMonth: _selectedMonth,
            onMonthChanged: (newMonth) {
              setState(() {
                _selectedMonth = newMonth;
              });
            },
          );

          // 如果当前状态是加载中，但有之前的数据，则使用之前的数据保持界面稳定
          if (state is StatisticsLoading && _previousLoadedState != null) {
            return Stack(
              children: [
                _buildStatisticsContent(context, _previousLoadedState!),
                // 添加半透明加载指示器覆盖
                Positioned.fill(
                  child: Container(
                    color:
                        const Color.fromARGB(128, 255, 255, 255), // 0.5透明度的白色
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ],
            );
          }

          if (state is StatisticsError) {
            return Column(
              children: [
                topSelector,
                Expanded(
                  child: Center(
                    child: Text(
                      '${AppLocalizations.of(context).translate('error_message')}: ${state.message}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          }

          if (state is StatisticsLoaded) {
            return _buildStatisticsContent(context, state);
          }

          // 首次加载时显示加载指示器
          return Column(
            children: [
              topSelector,
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          );
        },
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
                  child: Text(AppLocalizations.of(context)
                      .translate('date_range_select')),
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
                  AppLocalizations.of(context)
                      .translate('monthly_total_shifts'),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${state.totalShifts}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
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
            dailyWorkHours: _convertStringDateToDateTime(state.dailyWorkHours),
            totalWorkHours: state.totalWorkHours,
            averageWorkHours: state.averageWorkHours,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 将String日期转换为DateTime
  Map<DateTime, double> _convertStringDateToDateTime(
      Map<String, double> stringDateMap) {
    final Map<DateTime, double> dateTimeMap = {};
    for (final entry in stringDateMap.entries) {
      final parts = entry.key.split('-');
      if (parts.length == 3) {
        final date = DateTime(
          int.parse(parts[0]), // 年
          int.parse(parts[1]), // 月
          int.parse(parts[2]), // 日
        );
        dateTimeMap[date] = entry.value;
      }
    }
    return dateTimeMap;
  }

  void _showDateRangeDialog(BuildContext context) {
    // 保存外部context，确保能访问到StatisticsBloc
    final outerContext = context;

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
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(dialogContext)
                  .translate('date_range_select')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(AppLocalizations.of(dialogContext)
                        .translate('start_date')),
                    subtitle: Text(
                        '${startDate.year}-${startDate.month}-${startDate.day}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
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
                    title: Text(AppLocalizations.of(dialogContext)
                        .translate('end_date')),
                    subtitle:
                        Text('${endDate.year}-${endDate.month}-${endDate.day}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
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
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                      AppLocalizations.of(dialogContext).translate('cancel')),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    // 使用外部context访问StatisticsBloc
                    outerContext.read<StatisticsBloc>().add(
                          LoadDateRangeStatistics(startDate, endDate),
                        );
                  },
                  child: Text(
                      AppLocalizations.of(dialogContext).translate('confirm')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
