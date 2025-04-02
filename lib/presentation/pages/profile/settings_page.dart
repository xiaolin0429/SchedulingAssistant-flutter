import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../../../core/localization/app_text.dart';
// import '../../blocs/alarm/alarm_bloc.dart'; // 注释掉闹钟相关导入

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用已存在的SettingsBloc实例，确保设置变更立即生效
    return Scaffold(
      appBar: AppBar(
        title: const AppText('settings'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SettingsLoaded) {
            return _buildSettingsList(context, state);
          } else if (state is SettingsError) {
            return Center(
              child: Text('loading_failed'
                  .tr(context)
                  .replaceAll('{message}', state.message)),
            );
          } else {
            return const Center(child: AppText('unknown_state'));
          }
        },
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, SettingsLoaded state) {
    return ListView(
      children: [
        // 外观设置
        _buildSectionHeader(context, 'appearance'),
        _buildThemeModeSetting(context, state),

        // 通知设置部分已移除

        // 同步设置
        _buildSectionHeader(context, 'sync'),
        _buildSyncWithSystemCalendarSetting(context, state),

        // 备份设置
        _buildSectionHeader(context, 'backup'),
        _buildBackupSetting(context, state),
        _buildBackupIntervalSetting(context, state),

        // 语言设置
        _buildSectionHeader(context, 'language'),
        _buildLanguageSetting(context, state),

        // 重置设置
        _buildSectionHeader(context, 'reset'),
        ListTile(
          title: const AppText('reset_title'),
          subtitle: const AppText('reset_desc'),
          trailing: ElevatedButton(
            onPressed: () => _showResetConfirmDialog(context),
            child: const AppText('reset_button'),
          ),
        ),
      ],
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

  Widget _buildThemeModeSetting(BuildContext context, SettingsLoaded state) {
    return ListTile(
      title: const AppText('theme_mode'),
      subtitle: const AppText('theme_mode_desc'),
      trailing: DropdownButton<String>(
        value: state.themeMode,
        onChanged: (String? newValue) {
          if (newValue != null) {
            context.read<SettingsBloc>().add(UpdateThemeMode(newValue));
          }
        },
        items: const [
          DropdownMenuItem(
            value: 'system',
            child: AppText('system'),
          ),
          DropdownMenuItem(
            value: 'light',
            child: AppText('light'),
          ),
          DropdownMenuItem(
            value: 'dark',
            child: AppText('dark'),
          ),
        ],
      ),
    );
  }

  // 通知设置相关方法已移除

  Widget _buildSyncWithSystemCalendarSetting(
      BuildContext context, SettingsLoaded state) {
    return SwitchListTile(
      title: const AppText('sync_calendar'),
      subtitle: const AppText('sync_calendar_desc'),
      value: state.syncWithSystemCalendar,
      onChanged: (bool value) {
        context.read<SettingsBloc>().add(UpdateSyncWithSystemAlarm(value));
      },
    );
  }

  Widget _buildBackupSetting(BuildContext context, SettingsLoaded state) {
    return SwitchListTile(
      title: const AppText('auto_backup'),
      subtitle: const AppText('auto_backup_desc'),
      value: state.backupEnabled,
      onChanged: (bool value) {
        context.read<SettingsBloc>().add(UpdateBackupSettings(enabled: value));
      },
    );
  }

  Widget _buildBackupIntervalSetting(
      BuildContext context, SettingsLoaded state) {
    return ListTile(
      title: const AppText('backup_interval'),
      subtitle: Text('backup_interval_desc'
          .tr(context)
          .replaceAll('{days}', state.backupInterval.toString())),
      trailing: DropdownButton<int>(
        value: state.backupInterval,
        onChanged: state.backupEnabled
            ? (int? newValue) {
                if (newValue != null) {
                  context.read<SettingsBloc>().add(UpdateBackupSettings(
                        enabled: state.backupEnabled,
                        interval: newValue,
                      ));
                }
              }
            : null,
        items: [
          DropdownMenuItem(
            value: 1,
            child: Text('backup_interval_1_day'.tr(context)),
          ),
          DropdownMenuItem(
            value: 3,
            child: Text('backup_interval_3_days'.tr(context)),
          ),
          DropdownMenuItem(
            value: 7,
            child: Text('backup_interval_7_days'.tr(context)),
          ),
          DropdownMenuItem(
            value: 14,
            child: Text('backup_interval_14_days'.tr(context)),
          ),
          DropdownMenuItem(
            value: 30,
            child: Text('backup_interval_30_days'.tr(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSetting(BuildContext context, SettingsLoaded state) {
    return ListTile(
      title: const AppText('language_select'),
      subtitle: const AppText('language_desc'),
      trailing: DropdownButton<String>(
        value: state.language,
        onChanged: (String? newValue) {
          if (newValue != null && newValue != state.language) {
            context.read<SettingsBloc>().add(UpdateLanguage(newValue));
          }
        },
        items: const [
          DropdownMenuItem(
            value: 'zh',
            child: AppText('chinese'),
          ),
          DropdownMenuItem(
            value: 'en',
            child: AppText('english'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const AppText('confirm_reset'),
          content: const AppText('confirm_reset_desc'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const AppText('cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<SettingsBloc>().add(const ResetSettings());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: AppText('settings_reset')),
                );
              },
              child: const AppText('confirm'),
            ),
          ],
        );
      },
    );
  }
}
