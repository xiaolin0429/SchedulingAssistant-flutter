import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/utils/legal_document_loader.dart';

/// 法律文档页面类型
enum LegalDocumentType {
  /// 隐私政策
  privacyPolicy,

  /// 用户协议
  userAgreement,
}

/// 法律文档页面
class LegalDocumentPage extends StatefulWidget {
  /// 文档类型
  final LegalDocumentType documentType;

  const LegalDocumentPage({
    super.key,
    required this.documentType,
  });

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  /// 文档内容
  String _documentContent = '加载中...';

  /// 文档标题
  String get _title {
    switch (widget.documentType) {
      case LegalDocumentType.privacyPolicy:
        return '隐私政策';
      case LegalDocumentType.userAgreement:
        return '用户协议';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  /// 加载文档内容
  Future<void> _loadDocument() async {
    try {
      final String content = switch (widget.documentType) {
        LegalDocumentType.privacyPolicy =>
          await LegalDocumentLoader.loadPrivacyPolicy(),
        LegalDocumentType.userAgreement =>
          await LegalDocumentLoader.loadUserAgreement(),
      };

      if (mounted) {
        setState(() {
          _documentContent = content;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _documentContent = '加载文档失败：$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: Markdown(
        data: _documentContent,
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
