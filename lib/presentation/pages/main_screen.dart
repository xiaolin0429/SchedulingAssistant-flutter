import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection_container.dart' as di;
import '../../presentation/blocs/statistics/statistics_bloc.dart';
import '../../presentation/blocs/statistics/statistics_event.dart';
import 'home/home_page.dart';
import 'shift_types/shift_types_page.dart';
import 'alarm/alarm_page.dart';
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
    const AlarmPage(),
    // 使用BlocProvider包装StatisticsPage
    BlocProvider<StatisticsBloc>(
      create: (_) => di.getIt<StatisticsBloc>(),
      child: const StatisticsPage(),
    ),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '主页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '班次',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: '闹钟',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '统计',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}