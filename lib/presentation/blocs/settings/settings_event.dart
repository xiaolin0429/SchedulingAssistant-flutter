import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class UpdateThemeMode extends SettingsEvent {
  final String mode;

  const UpdateThemeMode(this.mode);

  @override
  List<Object> get props => [mode];
}

class UpdateNotifications extends SettingsEvent {
  final bool enabled;

  const UpdateNotifications(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class UpdateSyncWithSystemAlarm extends SettingsEvent {
  final bool enabled;

  const UpdateSyncWithSystemAlarm(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class UpdateDefaultShiftType extends SettingsEvent {
  final int typeId;

  const UpdateDefaultShiftType(this.typeId);

  @override
  List<Object> get props => [typeId];
}

class UpdateBackupSettings extends SettingsEvent {
  final bool enabled;
  final int? interval;

  const UpdateBackupSettings({
    required this.enabled,
    this.interval,
  });

  @override
  List<Object?> get props => [enabled, interval];
}

class UpdateLanguage extends SettingsEvent {
  final String languageCode;

  const UpdateLanguage(this.languageCode);

  @override
  List<Object> get props => [languageCode];
}

class PerformBackup extends SettingsEvent {
  const PerformBackup();
}

class ResetSettings extends SettingsEvent {
  const ResetSettings();
} 