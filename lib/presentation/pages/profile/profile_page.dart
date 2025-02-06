import 'package:flutter/material.dart';

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
                  // TODO: 实现编辑个人信息功能
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
                title: const Text(
                  '输入昵称',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('输入简介'),
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
                    title: '应用设置',
                    onTap: () {
                      // TODO: 导航到应用设置页面
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    icon: Icons.cloud,
                    title: '数据管理',
                    onTap: () {
                      // TODO: 导航到数据管理页面
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: '帮助与反馈',
                    onTap: () {
                      // TODO: 导航到帮助与反馈页面
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: '关于',
                    onTap: () {
                      // TODO: 导航到关于页面
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
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.black54),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
} 