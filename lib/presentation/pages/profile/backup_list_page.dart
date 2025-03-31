import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_text.dart';
import '../../blocs/backup/backup_bloc.dart';
import '../../blocs/backup/backup_event.dart';
import '../../blocs/backup/backup_state.dart';
import '../../../core/di/injection_container.dart' as di;

class BackupListPage extends StatelessWidget {
  const BackupListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BackupBloc>(
      create: (_) => di.getIt<BackupBloc>()..add(const LoadBackupList()),
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('backup_list'),
        ),
        body: BlocConsumer<BackupBloc, BackupState>(
          listener: (context, state) {
            if (state is RestoreSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              // 恢复成功后返回上一页
              Navigator.of(context).pop();
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
            if (state is BackupLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is BackupListLoaded) {
              if (state.backupList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.backup_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('no_backup_file'.tr(context)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: state.backupList.length,
                itemBuilder: (context, index) {
                  final backup = state.backupList[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.backup),
                      title: Text(backup['backupTime']),
                      subtitle: Text(backup['fileSize']),
                      trailing: IconButton(
                        icon: const Icon(Icons.restore),
                        onPressed: () => _showRestoreConfirmDialog(
                            context, backup['filePath']),
                      ),
                      onTap: () => _showRestoreConfirmDialog(
                          context, backup['filePath']),
                    ),
                  );
                },
              );
            } else {
              return Center(
                child: Text('load_failed'.tr(context)),
              );
            }
          },
        ),
      ),
    );
  }

  void _showRestoreConfirmDialog(BuildContext context, String backupFilePath) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('confirm_restore'.tr(context)),
          content: Text('confirm_restore_file_desc'.tr(context)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('cancel'.tr(context)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context
                    .read<BackupBloc>()
                    .add(RestoreFromSpecificBackup(backupFilePath));
              },
              child: Text('confirm'.tr(context)),
            ),
          ],
        );
      },
    );
  }
}
