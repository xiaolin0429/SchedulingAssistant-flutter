import 'package:equatable/equatable.dart';
import 'dart:io';

abstract class BackupEvent extends Equatable {
  const BackupEvent();

  @override
  List<Object?> get props => [];
}

class LoadBackupInfo extends BackupEvent {
  const LoadBackupInfo();
}

class CreateBackup extends BackupEvent {
  const CreateBackup();
}

class ExportBackup extends BackupEvent {
  const ExportBackup();
}

class RestoreFromLatestBackup extends BackupEvent {
  const RestoreFromLatestBackup();
}

class RestoreFromFile extends BackupEvent {
  final File backupFile;

  const RestoreFromFile(this.backupFile);

  @override
  List<Object?> get props => [backupFile];
}

class ClearCache extends BackupEvent {
  const ClearCache();
}

class ClearAllData extends BackupEvent {
  const ClearAllData();
} 