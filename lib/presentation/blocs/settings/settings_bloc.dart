import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../core/notifications/notification_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';
import 'package:flutter/foundation.dart';

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
      await _notificationService.initialize();

      emit(SettingsLoaded(
        themeMode: _settingsRepository.getThemeMode(),
        language: _settingsRepository.getLanguage(),
        notificationsEnabled: false, // 强制设置为false，因为通知功能已禁用
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
        // 闹钟功能已禁用，始终强制设置为false
        debugPrint('通知功能已禁用，不执行任何操作');
        // 仍然更新存储中的设置，以保持数据一致性
        await _settingsRepository.setNotificationEnabled(false);

        // 发出设置更新事件，始终为false
        emit((state as SettingsLoaded).copyWith(notificationsEnabled: false));

        // 以下通知权限和闹钟设置相关代码已被禁用
        /*
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

            // 用户明确开启通知功能，直接请求权限
            // 这会在iOS上显示系统权限请求对话框
            debugPrint('用户主动开启通知功能，请求通知权限');
            final permissionGranted =
                await _notificationService.requestPermissionsWhenEnabled();
            debugPrint('通知权限请求结果: $permissionGranted');

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

          // 检查是否已获得权限，在获得权限的情况下发送测试通知
          if (await _notificationService.checkPermissions()) {
            // 发送测试通知
            debugPrint('通知权限已授予，发送测试通知');
            await _notificationService.showNotification(
              id: 9999,
              title: '通知已启用',
              body: '您已成功开启通知功能',
            );
          } else {
            debugPrint('未获得通知权限，将在用户授权后才能发送通知');
          }
        } else {
          // 用户关闭通知时取消所有已经设置的通知
          debugPrint('用户已关闭通知，取消所有已设置的通知');
          await _notificationService.cancelAllNotifications();
        }
        */
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
      // 通知功能已禁用，确保重置后通知仍为禁用状态
      await _settingsRepository.setNotificationEnabled(false);
      add(const LoadSettings());
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
