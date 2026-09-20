import 'package:flutter/material.dart';
import '../../core/services/app_state.dart';
import '../../core/services/native_shield_service.dart';
import '../../core/services/update_service.dart';
import '../components/neo_button.dart';
import '../components/neo_card.dart';
import '../theme/app_theme.dart';

class SettingsMenuScreen extends StatefulWidget {
  final AppState appState;

  const SettingsMenuScreen({
    super.key,
    required this.appState,
  });

  @override
  State<SettingsMenuScreen> createState() => _SettingsMenuScreenState();
}

class _SettingsMenuScreenState extends State<SettingsMenuScreen> {
  String _installedVersion = '1.0.5';

  static const String _ghBase = 'https://pavanstarkin-tech.github.io/inhibit/';
  static const String _supportPhone = '+918639122823';
  static const String _supportEmail = 'shesipavankumarswamy@gmail.com';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final v = await UpdateService.getInstalledVersion();
    if (mounted) {
      setState(() {
        _installedVersion = v;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderBlack, width: 2.5),
                        boxShadow: AppTheme.hardShadow(offset: const Offset(2, 2)),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 38), // balance back button
                ],
              ),
              const SizedBox(height: 20),

              // 1. Customer Support
              _buildMenuItem(
                icon: Icons.support_agent_rounded,
                iconBg: AppTheme.accentYellow,
                title: 'Customer Support',
                badgeText: 'Call & Email',
                onTap: () => _showCustomerSupportDialog(context),
              ),
              const SizedBox(height: 10),

              // 2. Data and Security
              _buildMenuItem(
                icon: Icons.security_rounded,
                iconBg: AppTheme.accentGreen,
                title: 'Data and Security',
                badgeText: '100% On-Device',
                onTap: () => NativeShieldService.openUrl('${_ghBase}data-safety.html'),
              ),
              const SizedBox(height: 10),

              // 3. Privacy Policy
              _buildMenuItem(
                icon: Icons.privacy_tip_outlined,
                iconBg: const Color(0xFFBAE6FD),
                title: 'Privacy Policy',
                onTap: () => NativeShieldService.openUrl('${_ghBase}privacy.html'),
              ),
              const SizedBox(height: 10),

              // 4. Terms and Conditions
              _buildMenuItem(
                icon: Icons.gavel_outlined,
                iconBg: const Color(0xFFFFD1DC),
                title: 'Terms and Conditions',
                onTap: () => NativeShieldService.openUrl('${_ghBase}terms.html'),
              ),
              const SizedBox(height: 10),

              // 5. Data Deletion
              _buildMenuItem(
                icon: Icons.delete_outline_rounded,
                iconBg: const Color(0xFFFFC0CB),
                title: 'Data Deletion',
                badgeText: 'Policy',
                onTap: () => NativeShieldService.openUrl('${_ghBase}data-deletion.html'),
              ),
              const SizedBox(height: 10),

              // 6. About Us
              _buildMenuItem(
                icon: Icons.info_outline_rounded,
                iconBg: const Color(0xFFC7D2FE),
                title: 'About Us',
                badgeText: 'v$_installedVersion',
                onTap: () => NativeShieldService.openUrl(_ghBase),
              ),

              const SizedBox(height: 36),

              // Bottom Branding Logo & Tagline
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 52,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text(
                        'Inhibit',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Same social media.\nA better you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF444444),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBg,
    required String title,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return NeoCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shadowOffset: const Offset(3, 3),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderBlack, width: 2),
            ),
            child: Icon(icon, size: 18, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          if (badgeText != null) ...[
            Text(
              badgeText,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF888888),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.chevron_right_rounded, color: Colors.black, size: 22),
        ],
      ),
    );
  }

  void _showCustomerSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderBlack, width: 2),
              ),
              child: const Icon(Icons.support_agent_rounded, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Customer Support',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We are here to help! Reach out to us directly via Phone Call or Email.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF444444), height: 1.3),
            ),
            const SizedBox(height: 14),

            // Call Option Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderBlack, width: 2),
                boxShadow: AppTheme.hardShadow(offset: const Offset(3, 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.phone_in_talk_rounded, color: Colors.black, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Direct Phone Call',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    _supportPhone,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                  ),
                  const SizedBox(height: 8),
                  NeoButton(
                    text: 'CALL NOW →',
                    backgroundColor: AppTheme.accentGreen,
                    textColor: Colors.black,
                    height: 38,
                    fontSize: 11,
                    isFullWidth: true,
                    onPressed: () {
                      NativeShieldService.openUrl('tel:$_supportPhone');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Email Option Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderBlack, width: 2),
                boxShadow: AppTheme.hardShadow(offset: const Offset(3, 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.mail_outline_rounded, color: Colors.black, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Email Support',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Shesi Pavan Kumar Swamy',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF666666)),
                  ),
                  const Text(
                    _supportEmail,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  NeoButton(
                    text: 'SEND EMAIL →',
                    backgroundColor: AppTheme.accentYellow,
                    textColor: Colors.black,
                    height: 38,
                    fontSize: 11,
                    isFullWidth: true,
                    onPressed: () {
                      NativeShieldService.openUrl('mailto:$_supportEmail?subject=Inhibit%20Support%20Request');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

