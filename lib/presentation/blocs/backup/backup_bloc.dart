import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduling_assistant/domain/services/backup_service.dart';
import 'backup_event.dart';
import 'backup_state.dart';

class BackupBloc extends Bloc<BackupEvent, BackupState> {
  final BackupService _backupService;

  BackupBloc(this._backupService) : super(const BackupInitial()) {
    on<LoadBackupInfo>(_onLoadBackupInfo);
    on<LoadBackupList>(_onLoadBackupList);
    on<CreateBackup>(_onCreateBackup);
    on<ExportBackup>(_onExportBackup);
    on<RestoreFromLatestBackup>(_onRestoreFromLatestBackup);
    on<RestoreFromSpecificBackup>(_onRestoreFromSpecificBackup);
    on<RestoreFromFile>(_onRestoreFromFile);
    on<ClearCache>(_onClearCache);
    on<ClearAllData>(_onClearAllData);
  }

  Future<void> _onLoadBackupInfo(
    LoadBackupInfo event,
    Emitter<BackupState> emit,
  ) async {
    try {
      emit(const BackupLoading());
      final backupInfo = await _backupService.getBackupInfo();
      emit(BackupInfoLoaded(
        lastBackupTime: backupInfo['lastBackupTime'],
        backupSize: backupInfo['backupSize'],
        hasBackup: backupInfo['hasBackup'],
      ));
    } catch (e) {
      emit(BackupError('加载备份信息失败: $e'));
    }
  }

  Future<void> _onLoadBackupList(
    LoadBackupList event,
    Emitter<BackupState> emit,
  ) async {
    try {
      emit(const BackupLoading());
      final backupList = await _backupService.getAllBackups();
      emit(BackupListLoaded(backupList));
    } catch (e) {
      emit(BackupError('加载备份列表失败: $e'));
    }
  }

  Future<void> _onCreateBackup(
    CreateBackup event,
    Emitter<BackupState> emit,
  ) async {
    try {
      emit(const BackupLoading());
      await _backupService.createBackup();
      emit(const BackupSuccess('备份创建成功'));

      // 重新加载备份信息
      final backupInfo = await _backupService.getBackupInfo();
      emit(BackupInfoLoaded(
        lastBackupTime: backupInfo['lastBackupTime'],
        backupSize: backupInfo['backupSize'],
        hasBackup: backupInfo['hasBackup'],
      ));
    } catch (e) {
      emit(BackupError('创建备份失败: $e'));
    }
  }

  Future<void> _onExportBackup(
    ExportBackup event,
    Emitter<BackupState> emit,
  ) async {
    try {
      emit(const BackupLoading());
      await _backupService.exportBackup();
      emit(const BackupSuccess('备份导出成功'));

      // 重新加载备份信息
      final backupInfo = await _backupService.getBackupInfo();
      emit(BackupInfoLoaded(
        lastBackupTime: backupInfo['lastBackupTime'],
        backupSize: backupInfo['backupSize'],
        hasBackup: backupInfo['hasBackup'],
      ));
    } catch (e) {
      emit(BackupError('导出备份失败: $e'));
    }
  }

  Future<void> _onRestoreFromLatestBackup(
    RestoreFromLatestBackup event,
    Emitter<BackupState> emit,
  ) async {
    try {
      emit(const BackupLoading());
      await _backupService.restoreFromLatestBackup();
      emit(const RestoreSuccess('从最新备份恢复成功'));
    } catch (e) {
      emit(BackupError('从最新备份恢复失败: $e'));
    }
  }

  Future<void> _onRestoreFromSpecificBackup(
    RestoreFromSpecificBackup event,
    Emitter<BackupState> emit,
  ) async {
    try {
      emit(const BackupLoading());
      await _backupService.restoreFromBackupFile(event.backupFilePath);
      emit(const RestoreSuccess('恢复备份成功'));
    } catch (e) {
      emit(BackupError('恢复备份失败: $e'));
    }
  }

  Future<void> _onRestoreFromFile(
    RestoreFromFile event,
    Emitter<BackupState> emit,
  ) async {
    try {
      emit(const BackupLoading());
      await _backupService.restoreFromFile();
      emit(const RestoreSuccess('从文件恢复成功'));
    } catch (e) {
      emit(BackupError('从文件恢复失败: $e'));
    }
  }

  Future<void> _onClearCache(
    ClearCache event,
    Emitter<BackupState> emit,
  ) async {
    try {
      emit(const BackupLoading());
      await _backupService.clearCache();
      emit(const ClearCacheSuccess('缓存清除成功'));
    } catch (e) {
      emit(BackupError('清除缓存失败: $e'));
    }
  }

  Future<void> _onClearAllData(
    ClearAllData event,
    Emitter<BackupState> emit,
  ) async {
    try {
      emit(const BackupLoading());
      await _backupService.clearAllData();
      emit(const ClearAllDataSuccess('所有数据已清除'));
    } catch (e) {
      emit(BackupError('清除所有数据失败: $e'));
    }
  }
}
