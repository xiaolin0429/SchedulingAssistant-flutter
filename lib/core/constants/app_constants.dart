class AppConstants {
  // App Info
  static const String appName = 'Scheduling Assistant';
  static const String appVersion = '1.0.0';
  
  // Shared Preferences Keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language';
  
  // Routes
  static const String routeHome = '/';
  static const String routeShifts = '/shifts';
  static const String routeAlarms = '/alarms';
  static const String routeSettings = '/settings';
  
  // Date Formats
  static const String dateFormatFull = 'yyyy-MM-dd HH:mm:ss';
  static const String dateFormatDate = 'yyyy-MM-dd';
  static const String dateFormatTime = 'HH:mm';
  
  // Method Channel Names
  static const String channelAlarm = 'com.schedule.assistant/alarm';
  static const String channelNotification = 'com.schedule.assistant/notification';
  
  const AppConstants._(); // 私有构造函数，防止实例化
} 