import 'dart:async';
import '../../data/repositories/settings_repository.dart';

class SettingsService {
  final SettingsRepository _settingsRepository;

  SettingsService(this._settingsRepository);

  // 获取设置变更流
  Stream<void> get settingsStream => _settingsRepository.settingsStream;

  // 主题设置
  Future<void> setThemeMode(String mode) async {
    if (!['system', 'light', 'dark'].contains(mode)) {
      throw Exception('无效的主题模式');
    }
    await _settingsRepository.setThemeMode(mode);
  }

  String getThemeMode() => _settingsRepository.getThemeMode();

  // 通知设置
  Future<void> setNotificationEnabled(bool enabled) =>
    _settingsRepository.setNotificationEnabled(enabled);

  bool getNotificationEnabled() => 
    _settingsRepository.getNotificationEnabled();

  // 系统日历同步设置
  Future<void> setSyncWithSystemCalendar(bool enabled) =>
    _settingsRepository.setSyncWithSystemCalendar(enabled);

  bool getSyncWithSystemCalendar() =>
    _settingsRepository.getSyncWithSystemCalendar();

  // 默认班次类型设置
  Future<void> setDefaultShiftType(int typeId) async {
    if (typeId < 0) {
      throw Exception('无效的班次类型ID');
    }
    await _settingsRepository.setDefaultShiftType(typeId);
  }

  int getDefaultShiftType() => _settingsRepository.getDefaultShiftType();

  // 备份设置
  Future<void> setBackupEnabled(bool enabled) =>
    _settingsRepository.setBackupEnabled(enabled);

  bool getBackupEnabled() => _settingsRepository.getBackupEnabled();

  Future<void> setBackupInterval(int days) async {
    if (days < 1) {
      throw Exception('备份间隔不能小于1天');
    }
    await _settingsRepository.setBackupInterval(days);
  }

  int getBackupInterval() => _settingsRepository.getBackupInterval();

  Future<void> updateLastBackupTime() =>
    _settingsRepository.setLastBackupTime(
      DateTime.now().millisecondsSinceEpoch,
    );

  DateTime getLastBackupTime() => DateTime.fromMillisecondsSinceEpoch(
    _settingsRepository.getLastBackupTime(),
  );

  // 语言设置
  Future<void> setLanguage(String languageCode) async {
    if (!['zh', 'en'].contains(languageCode)) {
      throw Exception('不支持的语言');
    }
    await _settingsRepository.setLanguage(languageCode);
  }

  String getLanguage() => _settingsRepository.getLanguage();

  // 获取所有设置
  Map<String, dynamic> getAllSettings() =>
    _settingsRepository.getAllSettings();

  // 批量更新设置
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    // 验证设置值
    if (settings.containsKey('themeMode') && 
        !['system', 'light', 'dark'].contains(settings['themeMode'])) {
      throw Exception('无效的主题模式');
    }
    
    if (settings.containsKey('defaultShiftType') && 
        settings['defaultShiftType'] < 0) {
      throw Exception('无效的班次类型ID');
    }
    
    if (settings.containsKey('backupInterval') && 
        settings['backupInterval'] < 1) {
      throw Exception('备份间隔不能小于1天');
    }
    
    if (settings.containsKey('language') && 
        !['zh', 'en'].contains(settings['language'])) {
      throw Exception('不支持的语言');
    }

    await _settingsRepository.updateSettings(settings);
  }

  // 重置所有设置
  Future<void> resetSettings() => _settingsRepository.resetSettings();

  // 检查是否需要自动备份
  bool shouldPerformAutoBackup() {
    if (!getBackupEnabled()) return false;

    final lastBackup = getLastBackupTime();
    final now = DateTime.now();
    final interval = Duration(days: getBackupInterval());

    return now.difference(lastBackup) >= interval;
  }

  void dispose() {
    _settingsRepository.dispose();
  }
} 