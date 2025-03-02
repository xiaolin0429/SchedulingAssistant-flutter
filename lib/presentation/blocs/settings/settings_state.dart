import 'package:equatable/equatable.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// 加载中状态
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// 加载错误状态
class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object> get props => [message];
}

/// 加载完成状态
class SettingsLoaded extends SettingsState {
  final String themeMode;
  final String language;
  final bool notificationsEnabled;
  final bool syncWithSystemCalendar;
  final int defaultShiftType;
  final bool backupEnabled;
  final int backupInterval;

  const SettingsLoaded({
    required this.themeMode,
    required this.language,
    required this.notificationsEnabled,
    required this.syncWithSystemCalendar,
    required this.defaultShiftType,
    required this.backupEnabled,
    required this.backupInterval,
  });

  @override
  List<Object> get props => [
    themeMode,
    language,
    notificationsEnabled,
    syncWithSystemCalendar,
    defaultShiftType,
    backupEnabled,
    backupInterval,
  ];

  SettingsLoaded copyWith({
    String? themeMode,
    String? language,
    bool? notificationsEnabled,
    bool? syncWithSystemCalendar,
    int? defaultShiftType,
    bool? backupEnabled,
    int? backupInterval,
  }) {
    return SettingsLoaded(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      syncWithSystemCalendar: syncWithSystemCalendar ?? this.syncWithSystemCalendar,
      defaultShiftType: defaultShiftType ?? this.defaultShiftType,
      backupEnabled: backupEnabled ?? this.backupEnabled,
      backupInterval: backupInterval ?? this.backupInterval,
    );
  }
}

class BackupInProgress extends SettingsState {}

class BackupSuccess extends SettingsState {
  final DateTime backupTime;

  const BackupSuccess(this.backupTime);

  @override
  List<Object> get props => [backupTime];
}

class BackupError extends SettingsState {
  final String message;

  const BackupError(this.message);

  @override
  List<Object> get props => [message];
}

/// 需要重启应用的状态
class SettingsNeedRestart extends SettingsState {
  final String message;

  const SettingsNeedRestart({required this.message});

  @override
  List<Object> get props => [message];
} 