import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/localization/app_text.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsBloc>(
      create: (_) => di.getIt<SettingsBloc>()..add(const LoadSettings()),
      child: Scaffold(
        appBar: AppBar(
          title: AppText('settings'),
        ),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SettingsLoaded) {
              return _buildSettingsList(context, state);
            } else if (state is SettingsError) {
              return Center(
                child: Text(
                  'loading_failed'.tr(context).replaceAll('{message}', state.message)
                ),
              );
            } else if (state is SettingsNeedRestart) {
              // 显示需要重启的提示
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'ok'.tr(context),
                      onPressed: () {
                        // 重新加载设置
                        context.read<SettingsBloc>().add(const LoadSettings());
                      },
                    ),
                  ),
                );
                // 重新加载设置
                context.read<SettingsBloc>().add(const LoadSettings());
              });
              return const Center(child: CircularProgressIndicator());
            } else {
              return Center(child: AppText('unknown_state'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, SettingsLoaded state) {
    return ListView(
      children: [
        // 外观设置
        _buildSectionHeader(context, 'appearance'),
        _buildThemeModeSetting(context, state),
        
        // 通知设置
        _buildSectionHeader(context, 'notification'),
        _buildNotificationSetting(context, state),
        
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
          title: AppText('reset_title'),
          subtitle: AppText('reset_desc'),
          trailing: ElevatedButton(
            onPressed: () => _showResetConfirmDialog(context),
            child: AppText('reset_button'),
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
      title: AppText('theme_mode'),
      subtitle: AppText('theme_mode_desc'),
      trailing: DropdownButton<String>(
        value: state.themeMode,
        onChanged: (String? newValue) {
          if (newValue != null) {
            context.read<SettingsBloc>().add(UpdateThemeMode(newValue));
          }
        },
        items: [
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

  Widget _buildNotificationSetting(BuildContext context, SettingsLoaded state) {
    return SwitchListTile(
      title: AppText('notification_enable'),
      subtitle: AppText('notification_desc'),
      value: state.notificationsEnabled,
      onChanged: (bool value) {
        context.read<SettingsBloc>().add(UpdateNotifications(value));
      },
    );
  }

  Widget _buildSyncWithSystemCalendarSetting(BuildContext context, SettingsLoaded state) {
    return SwitchListTile(
      title: AppText('sync_calendar'),
      subtitle: AppText('sync_calendar_desc'),
      value: state.syncWithSystemCalendar,
      onChanged: (bool value) {
        context.read<SettingsBloc>().add(UpdateSyncWithSystemAlarm(value));
      },
    );
  }

  Widget _buildBackupSetting(BuildContext context, SettingsLoaded state) {
    return SwitchListTile(
      title: AppText('auto_backup'),
      subtitle: AppText('auto_backup_desc'),
      value: state.backupEnabled,
      onChanged: (bool value) {
        context.read<SettingsBloc>().add(UpdateBackupSettings(enabled: value));
      },
    );
  }

  Widget _buildBackupIntervalSetting(BuildContext context, SettingsLoaded state) {
    return ListTile(
      title: AppText('backup_interval'),
      subtitle: Text(
        'backup_interval_desc'.tr(context).replaceAll('{days}', state.backupInterval.toString())
      ),
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
        items: const [
          DropdownMenuItem(
            value: 1,
            child: Text('1天'),
          ),
          DropdownMenuItem(
            value: 3,
            child: Text('3天'),
          ),
          DropdownMenuItem(
            value: 7,
            child: Text('7天'),
          ),
          DropdownMenuItem(
            value: 14,
            child: Text('14天'),
          ),
          DropdownMenuItem(
            value: 30,
            child: Text('30天'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSetting(BuildContext context, SettingsLoaded state) {
    return ListTile(
      title: AppText('language_select'),
      subtitle: AppText('language_desc'),
      trailing: DropdownButton<String>(
        value: state.language,
        onChanged: (String? newValue) {
          if (newValue != null && newValue != state.language) {
            context.read<SettingsBloc>().add(UpdateLanguage(newValue));
          }
        },
        items: [
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
          title: AppText('confirm_reset'),
          content: AppText('confirm_reset_desc'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: AppText('cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<SettingsBloc>().add(const ResetSettings());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: AppText('settings_reset')),
                );
              },
              child: AppText('confirm'),
            ),
          ],
        );
      },
    );
  }
} 