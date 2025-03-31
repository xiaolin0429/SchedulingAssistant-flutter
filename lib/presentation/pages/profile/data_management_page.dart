import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../../domain/services/backup_service.dart';
import '../../blocs/backup/backup_bloc.dart';
import '../../blocs/backup/backup_event.dart';
import '../../blocs/backup/backup_state.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/localization/app_text.dart';
import 'backup_list_page.dart';

class DataManagementPage extends StatelessWidget {
  const DataManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BackupBloc>(
      create: (_) => di.getIt<BackupBloc>()..add(const LoadBackupInfo()),
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('data_management'),
        ),
        body: BlocConsumer<BackupBloc, BackupState>(
          listener: (context, state) {
            if (state is BackupSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is BackupError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return ListView(
              children: [
                // 备份数据丢失警告
                _buildBackupWarning(context),

                // 备份信息
                _buildSectionHeader(context, 'backup_restore'),
                _buildBackupInfo(context, state),

                // 备份操作
                _buildSectionHeader(context, 'backup'),
                _buildBackupActions(context, state),

                // 恢复操作
                _buildSectionHeader(context, 'restore'),
                _buildRestoreActions(context, state),

                // 数据清理
                _buildSectionHeader(context, 'clear_data'),
                _buildDataCleanupActions(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String titleKey) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        titleKey.tr(context),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildBackupInfo(BuildContext context, BackupState state) {
    String lastBackupTime = 'never_backup'.tr(context);
    String backupSize = '0 KB';

    if (state is BackupInfoLoaded) {
      lastBackupTime = state.lastBackupTime;
      backupSize = state.backupSize;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('last_backup_time'.tr(context)),
                Text(lastBackupTime),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('backup_file_size'.tr(context)),
                Text(backupSize),
              ],
            ),
            if (state is BackupInfoLoaded && state.backupCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('backup_file_count'.tr(context)),
                    Text('${state.backupCount} ${'items'.tr(context)}'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupActions(BuildContext context, BackupState state) {
    final isLoading = state is BackupLoading;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text('create_backup'.tr(context)),
            subtitle: Text('backup_all_data'.tr(context)),
            onTap: isLoading
                ? null
                : () {
                    context.read<BackupBloc>().add(const CreateBackup());
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreActions(BuildContext context, BackupState state) {
    final isLoading = state is BackupLoading;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text('restore_from_backups'.tr(context)),
            subtitle: Text('restore_from_backups_desc'.tr(context)),
            onTap: isLoading
                ? null
                : () {
                    // 导航到备份列表页面
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BackupListPage(),
                      ),
                    );
                  },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: Text('restore_from_file'.tr(context)),
            subtitle: Text('restore_from_file_desc'.tr(context)),
            onTap: isLoading
                ? null
                : () async {
                    const params = OpenFileDialogParams(
                      fileExtensionsFilter: ['db'],
                      mimeTypesFilter: ['application/octet-stream'],
                    );

                    final filePath =
                        await FlutterFileDialog.pickFile(params: params);

                    if (filePath != null) {
                      final file = File(filePath);
                      if (context.mounted) {
                        _showRestoreConfirmDialog(
                          context,
                          'confirm_restore'.tr(context),
                          'confirm_restore_file_desc'.tr(context),
                          () {
                            context
                                .read<BackupBloc>()
                                .add(RestoreFromFile(file));
                          },
                        );
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildDataCleanupActions(BuildContext context, BackupState state) {
    final isLoading = state is BackupLoading;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: Text('clear_cache'.tr(context)),
            subtitle: Text('clear_cache_desc'.tr(context)),
            onTap: isLoading
                ? null
                : () async {
                    final cacheDir = await getTemporaryDirectory();
                    final cacheSize = await _calculateDirSize(cacheDir);

                    if (context.mounted) {
                      _showCleanupConfirmDialog(
                        context,
                        'clear_cache'.tr(context),
                        '${'clear_cache_confirm'.tr(context)}: ${_formatSize(cacheSize)}',
                        () async {
                          await _deleteCache();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('cache_cleared'.tr(context))),
                            );
                          }
                        },
                      );
                    }
                  },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text('clear_all_data'.tr(context),
                style: const TextStyle(color: Colors.red)),
            subtitle: Text('clear_all_data_desc'.tr(context)),
            onTap: isLoading
                ? null
                : () {
                    _showCleanupConfirmDialog(
                      context,
                      'clear_all_data'.tr(context),
                      'clear_data_warning'.tr(context),
                      () {
                        context.read<BackupBloc>().add(const ClearAllData());
                      },
                    );
                  },
          ),
        ],
      ),
    );
  }

  Future<int> _calculateDirSize(Directory dir) async {
    int totalSize = 0;
    try {
      final List<FileSystemEntity> entities = await dir.list().toList();
      for (final entity in entities) {
        if (entity is File) {
          totalSize += await entity.length();
        } else if (entity is Directory) {
          totalSize += await _calculateDirSize(entity);
        }
      }
    } catch (e) {
      debugPrint('Error calculating directory size: $e');
    }
    return totalSize;
  }

  String _formatSize(int size) {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  Future<void> _deleteCache() async {
    final cacheDir = await getTemporaryDirectory();
    if (cacheDir.existsSync()) {
      try {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      } catch (e) {
        debugPrint('Error deleting cache: $e');
      }
    }
  }

  void _showRestoreConfirmDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('cancel'.tr(context)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
              child: Text('confirm'.tr(context)),
            ),
          ],
        );
      },
    );
  }

  void _showCleanupConfirmDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('cancel'.tr(context)),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
              child: Text('confirm_clear'.tr(context)),
            ),
          ],
        );
      },
    );
  }

  // 备份数据丢失警告
  Widget _buildBackupWarning(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'backup_warning'.tr(context),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'backup_warning_desc'.tr(context),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: Text('export_backup'.tr(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () {
                  // 触发导出备份
                  final backupService = di.getIt<BackupService>();
                  backupService.getLatestBackupFile().then((backupFile) {
                    if (context.mounted) {
                      Share.shareXFiles(
                        [XFile(backupFile.path)],
                        subject:
                            '${'app_title'.tr(context)} ${'backup'.tr(context)}',
                      );
                    }
                  }).catchError((error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('no_backup_file'.tr(context)),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
