import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// 设置数据仓库
class SettingsRepository {
  // 键名常量
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyNotificationEnabled = 'notification_enabled';
  static const String _keySyncWithSystemCalendar = 'sync_with_system_calendar';
  static const String _keySyncWithCloud = 'sync_with_cloud';
  static const String _keyDefaultShiftType = 'default_shift_type';
  static const String _keyBackupEnabled = 'backup_enabled';
  static const String _keyBackupInterval = 'backup_interval';
  static const String _keyLastBackupTime = 'last_backup_time';

  final SharedPreferences _prefs;
  final _settingsController = StreamController<void>.broadcast();

  SettingsRepository(this._prefs);

  // 获取设置变更流
  Stream<void> get settingsStream => _settingsController.stream;

  /// 主题设置
  Future<void> setThemeMode(String value) async {
    await _prefs.setString(_keyThemeMode, value);
    _settingsController.add(null);
  }

  String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'system';
  }

  /// 语言设置
  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(_keyLanguage, languageCode);
    _settingsController.add(null);
  }

  String getLanguage() => _prefs.getString(_keyLanguage) ?? 'zh';

  /// 通知设置
  Future<void> setNotificationEnabled(bool value) async {
    // 通知功能已禁用，忽略传入值，始终设置为false
    await _prefs.setBool('notification_enabled', false);
  }

  bool getNotificationEnabled() {
    // 通知功能已禁用，始终返回false
    return false;
  }

  /// 系统日历同步设置
  Future<void> setSyncWithSystemCalendar(bool value) async {
    await _prefs.setBool(_keySyncWithSystemCalendar, value);
    _settingsController.add(null);
  }

  bool getSyncWithSystemCalendar() {
    return _prefs.getBool(_keySyncWithSystemCalendar) ?? false;
  }

  /// 云同步设置
  Future<void> setSyncWithCloud(bool value) async {
    await _prefs.setBool(_keySyncWithCloud, value);
    _settingsController.add(null);
  }

  bool getSyncWithCloud() {
    return _prefs.getBool(_keySyncWithCloud) ?? false;
  }

  /// 默认班次类型设置
  Future<void> setDefaultShiftType(int value) async {
    await _prefs.setInt(_keyDefaultShiftType, value);
    _settingsController.add(null);
  }

  int getDefaultShiftType() {
    return _prefs.getInt(_keyDefaultShiftType) ?? 0;
  }

  /// 备份设置
  Future<void> setBackupEnabled(bool value) async {
    await _prefs.setBool(_keyBackupEnabled, value);
    _settingsController.add(null);
  }

  bool getBackupEnabled() {
    return _prefs.getBool(_keyBackupEnabled) ?? false;
  }

  /// 备份间隔设置
  Future<void> setBackupInterval(int value) async {
    await _prefs.setInt(_keyBackupInterval, value);
    _settingsController.add(null);
  }

  int getBackupInterval() {
    return _prefs.getInt(_keyBackupInterval) ?? 7; // 默认7天
  }

  /// 最后备份时间设置
  Future<void> setLastBackupTime(int value) async {
    await _prefs.setInt(_keyLastBackupTime, value);
    _settingsController.add(null);
  }

  int getLastBackupTime() {
    return _prefs.getInt(_keyLastBackupTime) ?? 0;
  }

  /// 重置所有设置
  Future<void> resetSettings() async {
    await _prefs.setString(_keyThemeMode, 'system');
    await _prefs.setBool(_keyNotificationEnabled, false);
    await _prefs.setBool(_keySyncWithSystemCalendar, false);
    await _prefs.setInt(_keyDefaultShiftType, 0);
    await _prefs.setBool(_keyBackupEnabled, false);
    await _prefs.setInt(_keyBackupInterval, 7);
    await _prefs.setInt(
        _keyLastBackupTime, DateTime.now().millisecondsSinceEpoch);
    await _prefs.setString(_keyLanguage, 'zh');
    _settingsController.add(null);
  }

  /// 批量获取所有设置
  Map<String, dynamic> getAllSettings() {
    return {
      'themeMode': getThemeMode(),
      'language': getLanguage(),
      'notificationEnabled': getNotificationEnabled(),
      'syncWithSystemCalendar': getSyncWithSystemCalendar(),
      'syncWithCloud': getSyncWithCloud(),
      'defaultShiftType': getDefaultShiftType(),
      'backupEnabled': getBackupEnabled(),
      'backupInterval': getBackupInterval(),
      'lastBackupTime': getLastBackupTime(),
    };
  }

  /// 批量更新设置
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    if (settings.containsKey('themeMode')) {
      await setThemeMode(settings['themeMode']);
    }
    if (settings.containsKey('language')) {
      await setLanguage(settings['language']);
    }
    if (settings.containsKey('notificationEnabled')) {
      await setNotificationEnabled(settings['notificationEnabled']);
    }
    if (settings.containsKey('syncWithSystemCalendar')) {
      await setSyncWithSystemCalendar(settings['syncWithSystemCalendar']);
    }
    if (settings.containsKey('syncWithCloud')) {
      await setSyncWithCloud(settings['syncWithCloud']);
    }
    if (settings.containsKey('defaultShiftType')) {
      await setDefaultShiftType(settings['defaultShiftType']);
    }
    if (settings.containsKey('backupEnabled')) {
      await setBackupEnabled(settings['backupEnabled']);
    }
    if (settings.containsKey('backupInterval')) {
      await setBackupInterval(settings['backupInterval']);
    }
    if (settings.containsKey('lastBackupTime')) {
      await setLastBackupTime(settings['lastBackupTime']);
    }
  }

  void dispose() {
    _settingsController.close();
  }

  /// 获取是否自动同步日历
  bool get autoSyncCalendar => _prefs.getBool('autoSyncCalendar') ?? false;

  /// 设置是否自动同步日历
  Future<void> setAutoSyncCalendar(bool value) async {
    await _prefs.setBool('autoSyncCalendar', value);
  }

  /// 获取是否显示休息日
  bool get showRestDays => _prefs.getBool('showRestDays') ?? true;

  /// 设置是否显示休息日
  Future<void> setShowRestDays(bool value) async {
    await _prefs.setBool('showRestDays', value);
  }
}
