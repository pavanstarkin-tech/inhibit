import 'package:flutter/material.dart';
import '../../core/services/app_state.dart';
import '../components/neo_badge.dart';
import '../components/neo_button.dart';
import '../components/neo_card.dart';
import '../components/neo_switch.dart';
import '../theme/app_theme.dart';

class ShieldScreen extends StatefulWidget {
  final AppState appState;
  final Function(String serviceId) onOpenPostService;
  final VoidCallback? onBack;

  const ShieldScreen({
    super.key,
    required this.appState,
    required this.onOpenPostService,
    this.onBack,
  });

  @override
  State<ShieldScreen> createState() => _ShieldScreenState();
}

class _ShieldScreenState extends State<ShieldScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.appState.checkAccessibilityPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.appState.checkAccessibilityPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocksRemaining = widget.appState.postUnlocksRemaining;

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderBlack, width: 2),
                        boxShadow: AppTheme.hardShadow(offset: const Offset(2, 2)),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                    ),
                  ),
                  const Text(
                    'Shield & Post Mode',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 38), // Balanced alignment
                ],
              ),
              const SizedBox(height: 18),

              // Card 1: Intentional Post Mode
              NeoCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shadowOffset: const Offset(4, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderBlack, width: 2),
                          ),
                          child: const Icon(Icons.edit_note_rounded, color: Colors.black, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Intentional Post Mode',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Get 4 daily unlocks to create and post content, without distractions.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Unlocks counter
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '$unlocksRemaining / 4',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              color: Colors.black,
                            ),
                          ),
                          const Text(
                            'unlocks remaining today',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Yellow Button: UNLOCK FOR 30 MIN
                    NeoButton(
                      text: 'UNLOCK FOR 30 MIN',
                      backgroundColor: AppTheme.accentYellow,
                      textColor: Colors.black,
                      isFullWidth: true,
                      height: 46,
                      fontSize: 13,
                      onPressed: unlocksRemaining > 0
                          ? () => _handleUnlockPostSession(context)
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('All 4 daily post unlocks used for today.')),
                              );
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card 2: Rule Health & Probes
              NeoCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shadowOffset: const Offset(4, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderBlack, width: 2),
                          ),
                          child: const Icon(Icons.monitor_heart_outlined, color: Colors.black, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rule Health & Probes',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
                            ),
                            Text(
                              'All systems operational.',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Checklist
                    _buildRuleProbeItem('Instagram shield', 'Active & calibrated'),
                    const SizedBox(height: 8),
                    _buildRuleProbeItem('YouTube shield', 'Active & calibrated'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Granular OS App Shield Card (Native Protection)
              _buildNativeAppShieldCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleProbeItem(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.accentGreen,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.borderBlack, width: 1.5),
          ),
          child: const Icon(Icons.check, size: 14, color: Colors.black),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black),
        ),
        const Spacer(),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildNativeAppShieldCard() {
    final isGranted = widget.appState.isAccessibilityGranted;

    return NeoCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
      shadowOffset: const Offset(4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DEVICE APP SHIELDING',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black),
              ),
              NeoBadge(
                text: isGranted ? 'ACTIVE' : 'ACTION REQUIRED',
                backgroundColor: isGranted ? AppTheme.accentGreen : AppTheme.accentYellow,
                fontSize: 9,
                borderWidth: 1.5,
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (!isGranted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withAlpha((255 * 0.4).toInt()),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderBlack, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grant Android Accessibility permission to allow Inhibit to detect and exit Reels in official apps.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  NeoButton(
                    text: 'ENABLE IN ANDROID SETTINGS →',
                    backgroundColor: AppTheme.accentYellow,
                    textColor: Colors.black,
                    isFullWidth: true,
                    height: 38,
                    fontSize: 11,
                    onPressed: () => widget.appState.openAccessibilitySettings(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          _nativeSwitchTile(
            title: 'Instagram Reels (Auto-Redirect)',
            subtitle: 'Redirects Reels tab to Home feed (DMs & posts work)',
            value: widget.appState.nativeShieldInstaReels,
            onChanged: (val) => widget.appState.setGranularShield(blockInstaReels: val),
          ),
          const SizedBox(height: 6),
          _nativeSwitchTile(
            title: 'Instagram Explore',
            subtitle: 'Auto-exits Explore algorithmic recommendation grid',
            value: widget.appState.nativeShieldInstaExplore,
            onChanged: (val) => widget.appState.setGranularShield(blockInstaExplore: val),
          ),
          const SizedBox(height: 6),
          _nativeSwitchTile(
            title: 'YouTube Shorts (Auto-Redirect)',
            subtitle: 'Redirects Shorts player to Home (regular videos work)',
            value: widget.appState.nativeShieldYtShorts,
            onChanged: (val) => widget.appState.setGranularShield(blockYtShorts: val),
          ),
        ],
      ),
    );
  }

  Widget _nativeSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderBlack, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          NeoSwitch(
            value: value,
            activeColor: AppTheme.accentGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _handleUnlockPostSession(BuildContext context) {
    widget.appState.usePostUnlock();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: const Text('Post Session Unlocked', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          'You have 30 minutes to publish your post intentionally. Feeds and short-form algorithms remain blocked.',
          style: TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w600),
        ),
        actions: [
          NeoButton(
            text: 'OPEN INSTAGRAM →',
            backgroundColor: AppTheme.accentYellow,
            textColor: Colors.black,
            height: 40,
            fontSize: 12,
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onOpenPostService('instagram');
            },
          ),
        ],
      ),
    );
  }
}
