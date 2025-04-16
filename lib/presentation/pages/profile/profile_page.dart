import 'package:flutter/material.dart';
import 'dart:io';
import 'user_profile_edit_page.dart';
import 'settings_page.dart';
import 'data_management_page.dart';
import 'help_feedback_page.dart';
import 'about_page.dart';
import '../../../core/localization/app_text.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/di/injection_container.dart';
import '../../../domain/services/user_profile_service.dart';
import '../../../data/models/user_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 用户资料服务
  final _profileService = getIt<UserProfileService>();

  // 加载状态
  bool _isLoading = true;

  // 用户资料
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _profileService.loadUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserProfile,
          child: ListView(
            children: [
              // 个人信息卡片
              Card(
                margin: const EdgeInsets.all(16.0),
                child: ListTile(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserProfileEditPage(),
                      ),
                    );
                    // 返回后重新加载资料
                    _loadUserProfile();
                  },
                  leading: _buildProfileAvatar(),
                  title: _isLoading
                      ? const LinearProgressIndicator()
                      : Text(
                          _userProfile?.nickname ??
                              AppLocalizations.of(context)
                                  .translate('nickname'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  subtitle: _isLoading
                      ? null
                      : Text(_userProfile?.bio ??
                          AppLocalizations.of(context).translate('bio')),
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
      ),
    );
  }

  Widget _buildProfileAvatar() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    final avatarPath = _userProfile?.avatarPath;
    if (avatarPath != null && avatarPath.isNotEmpty) {
      final imageFile = File(avatarPath);
      if (imageFile.existsSync()) {
        return CircleAvatar(
          radius: 24,
          backgroundImage: FileImage(imageFile),
        );
      }
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey[200],
      child: const Icon(
        Icons.person_outline,
        size: 32,
        color: Colors.grey,
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
