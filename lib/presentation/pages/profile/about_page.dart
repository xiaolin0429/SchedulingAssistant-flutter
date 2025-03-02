import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _appVersion = '';
  String _buildNumber = '';
  int _logoClickCount = 0;
  bool _showEasterEgg = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _loadPackageInfo();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  void _handleLogoTap() {
    setState(() {
      _logoClickCount++;
      if (_logoClickCount >= 7) {
        _showEasterEgg = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildAppInfo(),
            _buildDeveloperInfo(),
            _buildLicenseInfo(),
            _buildVersionHistory(),
            if (_showEasterEgg) _buildEasterEgg(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _handleLogoTap,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                return Transform.rotate(
                  angle: _showEasterEgg ? _controller.value * 2 * math.pi : 0,
                  child: child,
                );
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '排班助手',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '版本 $_appVersion ($_buildNumber)',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '一款简单易用的排班管理工具，帮助您轻松管理工作班次、设置提醒，并提供详细的统计分析。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '开发团队',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDeveloperItem(
              name: '开发者',
              role: '应用开发',
              email: 'developer@example.com',
            ),
            const Divider(),
            _buildDeveloperItem(
              name: '设计师',
              role: 'UI/UX 设计',
              email: 'designer@example.com',
            ),
            const Divider(),
            _buildDeveloperItem(
              name: '测试人员',
              role: '质量保证',
              email: 'tester@example.com',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperItem({
    required String name,
    required String role,
    required String email,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.primaries[
                math.Random().nextInt(Colors.primaries.length)],
            child: Text(
              name.substring(0, 1),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.email, size: 20),
            onPressed: () => _launchEmail(email),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            title: const Text('开源许可'),
            subtitle: const Text('查看第三方库许可信息'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: '排班助手',
                applicationVersion: _appVersion,
                applicationLegalese: '© 2023 排班助手团队',
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('隐私政策'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchUrl('https://example.com/privacy'),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('用户协议'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchUrl('https://example.com/terms'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionHistory() {
    final versionHistory = [
      {
        'version': '1.0.0',
        'date': '2023-12-15',
        'changes': [
          '首次发布',
          '基本排班功能',
          '闹钟提醒功能',
          '统计分析功能',
        ],
      },
      {
        'version': '1.1.0',
        'date': '2024-02-20',
        'changes': [
          '添加数据备份与恢复功能',
          '优化用户界面',
          '修复已知问题',
        ],
      },
      {
        'version': '1.2.0',
        'date': '2024-04-10',
        'changes': [
          '添加系统日历同步功能',
          '增强统计分析功能',
          '提升应用性能',
          '修复已知问题',
        ],
      },
    ];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '版本历史',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...versionHistory.map((version) => _buildVersionItem(version)),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionItem(Map<String, dynamic> version) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '版本 ${version['version']}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Text(
                version['date'],
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(
            (version['changes'] as List).length,
            (index) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(version['changes'][index]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEasterEgg() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '🎉 恭喜你发现了彩蛋！',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '感谢您使用排班助手！我们的开发团队为这款应用倾注了大量心血，希望它能为您的工作带来便利。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '— 排班助手团队',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开邮件应用')),
        );
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开链接')),
        );
      }
    }
  }
} 