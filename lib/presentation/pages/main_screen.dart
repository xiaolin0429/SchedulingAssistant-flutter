import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection_container.dart' as di;
import '../../presentation/blocs/statistics/statistics_bloc.dart';
import '../../presentation/blocs/statistics/statistics_event.dart';
// import '../../presentation/blocs/alarm/alarm_bloc.dart'; // 注释掉闹钟相关导入
import '../../core/localization/app_text.dart';
import '../../core/utils/logger.dart';
import 'home/home_page.dart';
import 'shift_types/shift_types_page.dart';
// import 'alarm/alarm_page.dart'; // 注释掉闹钟页面导入
import 'statistics/statistics_page.dart';
import 'profile/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 页面列表
  final List<Widget> _pages = [
    const HomePage(),
    const ShiftTypesPage(),
    // 移除闹钟页面
    BlocProvider(
      create: (context) {
        final bloc = di.getIt<StatisticsBloc>();
        // 获取当前年月
        final now = DateTime.now();
        bloc.add(LoadMonthlyStatistics(now.year, now.month));
        return bloc;
      },
      child: const StatisticsPage(),
    ),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();

    // 记录应用启动后的首页访问
    final logger = di.getIt<LogService>();
    logger.logPageVisit('主屏幕');
    logger.logAppState('应用前台运行', details: '应用进入前台状态');
  }

  void _onDestinationSelected(int index) {
    // 不要在相同页面重复导航
    if (_currentIndex == index) return;

    // 记录页面切换
    final pageNames = ['主页', '班次', '统计', '我的'];
    final logger = di.getIt<LogService>();
    logger.logPageVisit(pageNames[index]);

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onDestinationSelected,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'home'.trOr(context, '主页'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today),
            label: 'shifts'.trOr(context, '班次'),
          ),
          // 移除闹钟导航项
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: 'statistics'.trOr(context, '统计'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'me'.trOr(context, '我的'),
          ),
        ],
      ),
    );
  }
}
