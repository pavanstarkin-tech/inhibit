import 'package:flutter/material.dart';
import '../../core/services/app_state.dart';
import '../../core/services/native_shield_service.dart';
import '../../core/services/update_service.dart';
import '../components/neo_card.dart';
import '../onboarding/onboarding_flow.dart';
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
  String _installedVersion = '1.0.4';

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
              const SizedBox(height: 24),

              // Menu Options (Only System, About, & Policy settings - no duplicate bottom nav items)
              _buildMenuItem(
                icon: Icons.system_update_alt_rounded,
                iconBg: AppTheme.accentYellow,
                title: 'Check for Updates',
                badgeText: widget.appState.isCheckingForUpdates
                    ? 'Checking...'
                    : (widget.appState.availableUpdate != null ? 'NEW V${widget.appState.availableUpdate!.latestVersion}' : 'GitHub Release'),
                onTap: () => _handleCheckForUpdates(context),
              ),
              const SizedBox(height: 12),

              _buildMenuItem(
                icon: Icons.settings_accessibility_rounded,
                iconBg: AppTheme.accentGreen,
                title: 'System Accessibility Settings',
                badgeText: 'Android',
                onTap: () async {
                  await NativeShieldService.openAccessibilitySettings();
                },
              ),
              const SizedBox(height: 12),

              _buildMenuItem(
                icon: Icons.shop_two_outlined,
                iconBg: AppTheme.accentYellow,
                title: 'Google Play Store',
                badgeText: 'Live Track',
                onTap: () async {
                  await NativeShieldService.openUrl(UpdateService.playStoreUrl);
                },
              ),
              const SizedBox(height: 12),

              _buildMenuItem(
                icon: Icons.group_add_outlined,
                iconBg: const Color(0xFFBAE6FD),
                title: 'Join Testing Group',
                badgeText: 'Google Group',
                onTap: () async {
                  await NativeShieldService.openUrl(UpdateService.googleGroupUrl);
                },
              ),
              const SizedBox(height: 12),

              _buildMenuItem(
                icon: Icons.tour_outlined,
                iconBg: const Color(0xFFC7D2FE),
                title: 'Replay Welcome Tour',
                badgeText: '5 steps',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        body: OnboardingFlow(
                          appState: widget.appState,
                          onComplete: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildMenuItem(
                icon: Icons.info_outline_rounded,
                iconBg: const Color(0xFFE2E8F0),
                title: 'About Inhibit',
                badgeText: 'v$_installedVersion',
                onTap: () => _showAboutDialog(context),
              ),
              const SizedBox(height: 12),

              _buildMenuItem(
                icon: Icons.policy_outlined,
                iconBg: const Color(0xFFFFD1DC),
                title: 'Privacy Policy & Terms',
                onTap: () => _showPrivacyPolicyDialog(context),
              ),

              const SizedBox(height: 48),

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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: Text('Inhibit v$_installedVersion', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          'Inhibit v$_installedVersion runs a local, sandboxed, distraction-free engine directly on your device. Zero telemetry, zero cloud tracking, zero algorithms.\n\nSame social media. A better you.',
          style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
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

  Future<void> _handleCheckForUpdates(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking GitHub releases for updates...'),
        duration: Duration(seconds: 2),
      ),
    );

    final info = await widget.appState.checkForAppUpdates(manual: true);
    if (!context.mounted) return;

    if (info.hasUpdate) {
      UpdateService.showUpdateDialog(
        context: context,
        update: info,
        onDownload: () => NativeShieldService.openUrl(info.downloadUrl.isNotEmpty ? info.downloadUrl : info.releaseUrl),
        onPlayStore: () => NativeShieldService.openUrl(UpdateService.playStoreUrl),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.bgMain,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 3),
          ),
          title: const Text('You\'re on the Latest Version', style: TextStyle(fontWeight: FontWeight.w900)),
          content: Text(
            'Inhibit v${info.currentVersion} is up to date.\nChecked against official GitHub releases.',
            style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('GREAT', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
            ),
          ],
        ),
      );
    }
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: const Text('Privacy & Terms', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          '1. Inhibit does not collect or transmit your personal data.\n2. All detection and shield rules execute entirely locally on your device.\n3. Accessibility service permissions are strictly used to intercept short-form doomscrolling loops (Reels & Shorts).\n4. You remain in full control of all shield rules at all times.',
          style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('GOT IT', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

