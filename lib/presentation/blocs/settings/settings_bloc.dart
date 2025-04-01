import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../core/notifications/notification_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';
import 'package:flutter/foundation.dart';
import '../alarm/alarm_event.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  final NotificationService _notificationService;

  SettingsBloc(this._settingsRepository,
      {NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService(),
        super(const SettingsLoading()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateLanguage>(_onUpdateLanguage);
    on<UpdateNotifications>(_onUpdateNotifications);
    on<UpdateSyncWithSystemAlarm>(_onUpdateSyncWithSystemAlarm);
    on<UpdateDefaultShiftType>(_onUpdateDefaultShiftType);
    on<UpdateBackupSettings>(_onUpdateBackupSettings);
    on<ResetSettings>(_onResetSettings);
  }

  Future<void> _onLoadSettings(
      LoadSettings event, Emitter<SettingsState> emit) async {
    try {
      emit(SettingsLoaded(
        themeMode: _settingsRepository.getThemeMode(),
        language: _settingsRepository.getLanguage(),
        notificationsEnabled: _settingsRepository.getNotificationEnabled(),
        syncWithSystemCalendar: _settingsRepository.getSyncWithSystemCalendar(),
        defaultShiftType: _settingsRepository.getDefaultShiftType(),
        backupEnabled: _settingsRepository.getBackupEnabled(),
        backupInterval: _settingsRepository.getBackupInterval(),
      ));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onUpdateThemeMode(
      UpdateThemeMode event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      try {
        debugPrint('更新主题模式: ${event.mode}');
        await _settingsRepository.setThemeMode(event.mode);
        final newState =
            (state as SettingsLoaded).copyWith(themeMode: event.mode);
        debugPrint('新状态主题模式: ${newState.themeMode}');
        emit(newState);
      } catch (e) {
        debugPrint('更新主题模式失败: $e');
        emit(SettingsError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateLanguage(
      UpdateLanguage event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      try {
        await _settingsRepository.setLanguage(event.languageCode);
        emit((state as SettingsLoaded).copyWith(language: event.languageCode));
        // 语言设置可以立即生效，不需要重启应用提示
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateNotifications(
      UpdateNotifications event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      try {
        // 记录之前的设置状态
        final bool previousState = _settingsRepository.getNotificationEnabled();

        // 更新存储中的设置
        await _settingsRepository.setNotificationEnabled(event.enabled);
        debugPrint('通知设置已更新为: ${event.enabled}');

        // 发出设置更新事件
        emit((state as SettingsLoaded)
            .copyWith(notificationsEnabled: event.enabled));

        // 确保通知服务已初始化
        await _notificationService.initialize();

        // 处理通知开关状态变更
        if (event.enabled) {
          // 状态从关闭变为开启
          if (!previousState) {
            debugPrint('通知状态从关闭变为开启，准备重新检查权限');

            // 重新检查权限状态
            await _notificationService.checkPermissions();

            // 通知服务端刷新权限状态
            try {
              // 通知AlarmBloc重新加载并安排所有闹钟
              // 获取全局BlocProvider中的AlarmBloc实例，重新触发加载事件
              if (event.alarmBloc != null) {
                debugPrint('通知状态已开启，正在重新安排闹钟通知...');
                event.alarmBloc.add(const RescheduleAlarms());
              } else {
                debugPrint('AlarmBloc未提供，无法重新安排闹钟通知');
              }
            } catch (e) {
              debugPrint('重新安排闹钟通知失败: $e');
            }
          }

          // 用户启用通知时请求系统权限
          // 检查当前权限状态
          final hasPermission = await _notificationService.checkPermissions();

          // 如果没有权限，则请求权限
          if (!hasPermission) {
            debugPrint('用户已启用通知，开始请求系统通知权限');
            final permissionGranted =
                await _notificationService.requestPermissions();
            debugPrint('通知权限请求结果: $permissionGranted');

            // 如果权限请求被拒绝，可以在这里添加额外的逻辑
            // 如提示用户手动在系统设置中开启权限
          } else {
            debugPrint('通知权限已授予，无需重新请求');

            // 发送测试通知
            await _notificationService.showNotification(
              id: 9999,
              title: '通知已启用',
              body: '您已成功开启通知功能',
            );
          }
        } else {
          // 用户关闭通知时取消所有已经设置的通知
          debugPrint('用户已关闭通知，取消所有已设置的通知');
          await _notificationService.cancelAllNotifications();
        }
      } catch (e) {
        debugPrint('更新通知设置失败: $e');
        emit(SettingsError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateSyncWithSystemAlarm(
      UpdateSyncWithSystemAlarm event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      try {
        await _settingsRepository.setSyncWithSystemCalendar(event.enabled);
        emit((state as SettingsLoaded)
            .copyWith(syncWithSystemCalendar: event.enabled));
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateDefaultShiftType(
      UpdateDefaultShiftType event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      try {
        await _settingsRepository.setDefaultShiftType(event.typeId);
        emit(
            (state as SettingsLoaded).copyWith(defaultShiftType: event.typeId));
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateBackupSettings(
      UpdateBackupSettings event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      try {
        await _settingsRepository.setBackupEnabled(event.enabled);
        if (event.interval != null) {
          await _settingsRepository.setBackupInterval(event.interval!);
        }
        emit((state as SettingsLoaded).copyWith(
          backupEnabled: event.enabled,
          backupInterval: event.interval,
        ));
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    }
  }

  Future<void> _onResetSettings(
      ResetSettings event, Emitter<SettingsState> emit) async {
    try {
      await _settingsRepository.resetSettings();
      add(const LoadSettings());
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
