import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsBloc(this._settingsRepository) : super(const SettingsLoading()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateLanguage>(_onUpdateLanguage);
    on<UpdateNotifications>(_onUpdateNotifications);
    on<UpdateSyncWithSystemAlarm>(_onUpdateSyncWithSystemAlarm);
    on<UpdateDefaultShiftType>(_onUpdateDefaultShiftType);
    on<UpdateBackupSettings>(_onUpdateBackupSettings);
    on<ResetSettings>(_onResetSettings);
  }

  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
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

  Future<void> _onUpdateThemeMode(UpdateThemeMode event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      try {
        await _settingsRepository.setThemeMode(event.mode);
        emit((state as SettingsLoaded).copyWith(themeMode: event.mode));
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateLanguage(UpdateLanguage event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      try {
        await _settingsRepository.setLanguage(event.languageCode);
        emit((state as SettingsLoaded).copyWith(language: event.languageCode));
        
        // 发出需要重启应用的信号
        emit(const SettingsNeedRestart(message: '语言设置已更改，请重启应用以应用更改'));
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateNotifications(UpdateNotifications event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      try {
        await _settingsRepository.setNotificationEnabled(event.enabled);
        emit((state as SettingsLoaded).copyWith(notificationsEnabled: event.enabled));
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateSyncWithSystemAlarm(UpdateSyncWithSystemAlarm event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      try {
        await _settingsRepository.setSyncWithSystemCalendar(event.enabled);
        emit((state as SettingsLoaded).copyWith(syncWithSystemCalendar: event.enabled));
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateDefaultShiftType(UpdateDefaultShiftType event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      try {
        await _settingsRepository.setDefaultShiftType(event.typeId);
        emit((state as SettingsLoaded).copyWith(defaultShiftType: event.typeId));
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateBackupSettings(UpdateBackupSettings event, Emitter<SettingsState> emit) async {
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

  Future<void> _onResetSettings(ResetSettings event, Emitter<SettingsState> emit) async {
    try {
      await _settingsRepository.resetSettings();
      add(const LoadSettings());
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
} 