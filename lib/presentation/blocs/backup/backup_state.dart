import 'package:equatable/equatable.dart';

abstract class BackupState extends Equatable {
  const BackupState();

  @override
  List<Object?> get props => [];
}

class BackupInitial extends BackupState {
  const BackupInitial();
}

class BackupLoading extends BackupState {
  const BackupLoading();
}

class BackupInfoLoaded extends BackupState {
  final String lastBackupTime;
  final String backupSize;
  final bool hasBackup;
  final int backupCount;

  const BackupInfoLoaded({
    required this.lastBackupTime,
    required this.backupSize,
    required this.hasBackup,
    this.backupCount = 0,
  });

  @override
  List<Object?> get props => [lastBackupTime, backupSize, hasBackup, backupCount];
}

class BackupSuccess extends BackupState {
  final String message;

  const BackupSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class BackupError extends BackupState {
  final String message;

  const BackupError(this.message);

  @override
  List<Object?> get props => [message];
}

class RestoreSuccess extends BackupState {
  final String message;

  const RestoreSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ClearCacheSuccess extends BackupState {
  final String message;

  const ClearCacheSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ClearAllDataSuccess extends BackupState {
  final String message;

  const ClearAllDataSuccess(this.message);

  @override
  List<Object?> get props => [message];
} 