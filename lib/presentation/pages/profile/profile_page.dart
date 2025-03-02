import 'package:flutter/material.dart';
import 'user_profile_edit_page.dart';
import 'settings_page.dart';
import 'data_management_page.dart';
import 'help_feedback_page.dart';
import 'about_page.dart';
import '../../../core/localization/app_text.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            // 个人信息卡片
            Card(
              margin: const EdgeInsets.all(16.0),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserProfileEditPage(),
                    ),
                  );
                },
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(
                    Icons.person_outline,
                    size: 32,
                    color: Colors.grey,
                  ),
                ),
                title: AppText(
                  'nickname',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: AppText('bio'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),

            // 功能列表
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.settings,
                    titleKey: 'app_settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    icon: Icons.cloud,
                    titleKey: 'data_management',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DataManagementPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    titleKey: 'help_feedback',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpFeedbackPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    titleKey: 'about',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String titleKey,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.black54),
      title: AppText(titleKey),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
} 