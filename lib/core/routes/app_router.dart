import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.routeHome:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Home Screen'))),
        );
      case AppConstants.routeShifts:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Shifts Screen'))),
        );
      case AppConstants.routeAlarms:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Alarms Screen'))),
        );
      case AppConstants.routeSettings:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Settings Screen'))),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  const AppRouter._(); // 私有构造函数，防止实例化
} 