import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../../../core/localization/app_localizations.dart';
import 'legal_document_page.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
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
        title: Text(AppLocalizations.of(context).translate('about')),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildAppInfo(),
            _buildDeveloperInfo(),
            _buildLicenseInfo(),
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
          Text(
            AppLocalizations.of(context).translate('app_title'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppLocalizations.of(context).translate('version')} $_appVersion ($_buildNumber)',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              AppLocalizations.of(context).translate('about_app_description'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
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
            Text(
              AppLocalizations.of(context).translate('development_team'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDeveloperItem(
              name: AppLocalizations.of(context).translate('developer'),
              role: AppLocalizations.of(context)
                  .translate('application_development'),
              email: 'developer@example.com',
            ),
            const Divider(),
            _buildDeveloperItem(
              name: AppLocalizations.of(context).translate('designer'),
              role: AppLocalizations.of(context).translate('ui_ux_design'),
              email: 'designer@example.com',
            ),
            const Divider(),
            _buildDeveloperItem(
              name: AppLocalizations.of(context).translate('tester'),
              role: AppLocalizations.of(context).translate('quality_assurance'),
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
            backgroundColor: Colors
                .primaries[math.Random().nextInt(Colors.primaries.length)],
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
            title: Text(
                AppLocalizations.of(context).translate('open_source_licenses')),
            subtitle: Text(
                AppLocalizations.of(context).translate('third_party_licenses')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName:
                    AppLocalizations.of(context).translate('app_title'),
                applicationVersion: _appVersion,
                applicationLegalese:
                    '© 2023 ${AppLocalizations.of(context).translate('app_title')}',
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            title:
                Text(AppLocalizations.of(context).translate('privacy_policy')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LegalDocumentPage(
                    documentType: LegalDocumentType.privacyPolicy,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            title:
                Text(AppLocalizations.of(context).translate('user_agreement')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LegalDocumentPage(
                    documentType: LegalDocumentType.userAgreement,
                  ),
                ),
              );
            },
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
            Text(
              AppLocalizations.of(context).translate('easter_egg_congrats'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).translate('easter_egg_message'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)
                  .translate('development_team_signature'),
              style: const TextStyle(fontStyle: FontStyle.italic),
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
          SnackBar(
              content: Text(
                  AppLocalizations.of(context).translate('email_open_fail'))),
        );
      }
    }
  }
}
