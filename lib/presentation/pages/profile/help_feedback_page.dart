import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/localization/app_text.dart';

class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});

  @override
  State<HelpFeedbackPage> createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final _feedbackController = TextEditingController();
  final _contactController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // 将 faqs 列表移到类成员变量
  late List<Map<String, dynamic>> _faqs;

  @override
  void initState() {
    super.initState();
    // 在 initState 中初始化 faqs 列表为空
    _faqs = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 只有当 _faqs 为空时才初始化，避免重复初始化
    if (_faqs.isEmpty) {
      _faqs = [
        {
          'question': 'faq_add_shift'.tr(context),
          'answer': 'faq_add_shift_answer'.tr(context),
          'isExpanded': false,
        },
        {
          'question': 'faq_create_shift_type'.tr(context),
          'answer': 'faq_create_shift_type_answer'.tr(context),
          'isExpanded': false,
        },
        {
          'question': 'faq_set_alarm'.tr(context),
          'answer': 'faq_set_alarm_answer'.tr(context),
          'isExpanded': false,
        },
        {
          'question': 'faq_backup_data'.tr(context),
          'answer': 'faq_backup_data_answer'.tr(context),
          'isExpanded': false,
        },
        {
          'question': 'faq_view_statistics'.tr(context),
          'answer': 'faq_view_statistics_answer'.tr(context),
          'isExpanded': false,
        },
        {
          'question': 'faq_sync_calendar'.tr(context),
          'answer': 'faq_sync_calendar_answer'.tr(context),
          'isExpanded': false,
        },
      ];
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 添加日志，打印 _faqs 的状态
    debugPrint('构建 HelpFeedbackPage，FAQ 数量: ${_faqs.length}');
    for (int i = 0; i < _faqs.length; i++) {
      debugPrint(
          'FAQ[$i] 展开状态: ${_faqs[i]['isExpanded']}，问题: ${_faqs[i]['question']}');
    }

    // 移除 faqs 列表的定义
    return Scaffold(
      appBar: AppBar(
        title: Text('help_feedback_title'.trOr(context, '帮助与反馈')),
      ),
      body: ListView(
        children: [
          // 常见问题
          _buildSectionHeader(context, 'faq_section'.tr(context)),
          _buildFAQList(), // 移除参数

          // 用户反馈
          _buildSectionHeader(context, 'user_feedback_section'.tr(context)),
          _buildFeedbackForm(),

          // 联系我们
          _buildSectionHeader(context, 'contact_section'.tr(context)),
          _buildContactOptions(),

          // 日志导出
          _buildSectionHeader(context, 'log_export_section'.tr(context)),
          _buildLogExport(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildFAQList() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: _faqs.asMap().entries.map<Widget>((entry) {
          final index = entry.key;
          final faq = entry.value;
          debugPrint('构建 FAQ[$index]，问题: ${faq['question']}');

          return ExpansionTile(
            title: Text(
              faq['question']!,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            onExpansionChanged: (expanded) {
              debugPrint('FAQ[$index] 展开状态变更为: $expanded');
            },
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(faq['answer']!),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeedbackForm() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _feedbackController,
                decoration: InputDecoration(
                  labelText: 'feedback_content'.tr(context),
                  hintText: 'feedback_hint'.tr(context),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'feedback_empty'.tr(context);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: 'contact_info'.tr(context),
                  hintText: 'contact_hint'.tr(context),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('submit_feedback'.tr(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactOptions() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.email),
            title: Text('email_contact'.tr(context)),
            subtitle: const Text('support@example.com'),
            onTap: () => _launchEmail('support@example.com'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.web),
            title: Text('website'.tr(context)),
            subtitle: const Text('https://example.com'),
            onTap: () => _launchUrl('https://example.com'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.forum),
            title: Text('user_community'.tr(context)),
            subtitle: Text('community_desc'.tr(context)),
            onTap: () => _launchUrl('https://example.com/community'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogExport() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.file_download),
        title: Text('export_logs'.tr(context)),
        subtitle: Text('export_logs_desc'.tr(context)),
        onTap: _shareLogFile,
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // TODO: 实现反馈提交逻辑，可以是发送到服务器或保存到本地
        await Future.delayed(const Duration(seconds: 2)); // 模拟网络请求

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('feedback_success'.tr(context))),
          );
          _feedbackController.clear();
          _contactController.clear();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('feedback_fail'
                    .tr(context)
                    .replaceAll('{message}', e.toString()))),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': '${'app_title'.tr(context)} - ${'feedback'.tr(context)}',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('email_open_fail'.tr(context))),
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
          SnackBar(content: Text('url_open_fail'.tr(context))),
        );
      }
    }
  }

  Future<void> _shareLogFile() async {
    try {
      // 在异步操作前保存所有需要的上下文值
      final appTitle = 'app_title'.tr(context);
      final exportLogsTitle = 'export_logs'.tr(context);

      // 获取应用文档目录
      final documentsDirectory = await getApplicationDocumentsDirectory();

      // 创建临时日志文件
      final logFile = File('${documentsDirectory.path}/app_logs.txt');

      // 生成日志内容
      await logFile.writeAsString('''
日志导出时间: ${DateTime.now()}
系统信息: ${await _getSystemInfo()}
应用版本: 1.0.0
----------------------------
[INFO] 应用启动
[INFO] 加载用户设置
[INFO] 加载班次数据
[INFO] 初始化完成
''');

      // 分享日志文件
      await Share.shareXFiles(
        [XFile(logFile.path)],
        subject: '$appTitle - $exportLogsTitle',
      );
    } catch (e) {
      if (mounted) {
        // 在mounted检查后重新获取上下文值
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('export_logs_fail'
                  .tr(context)
                  .replaceAll('{message}', e.toString()))),
        );
      }
    }
  }

  Future<String> _getSystemInfo() async {
    try {
      return '${await _getPlatformVersion()} / ${await _getDeviceModel()}';
    } catch (e) {
      return '未知';
    }
  }

  Future<String> _getPlatformVersion() async {
    try {
      return await const MethodChannel('app.channel/info')
          .invokeMethod('getPlatformVersion')
          .then((value) => value.toString())
          .catchError((_) => 'Unknown');
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String> _getDeviceModel() async {
    try {
      return await const MethodChannel('app.channel/info')
          .invokeMethod('getDeviceModel')
          .then((value) => value.toString())
          .catchError((_) => 'Unknown');
    } catch (e) {
      return 'Unknown';
    }
  }
}
