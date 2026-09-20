import 'package:flutter/material.dart';
import '../../core/services/app_state.dart';
import '../components/neo_badge.dart';
import '../components/neo_button.dart';
import '../components/neo_card.dart';
import '../components/neo_switch.dart';
import '../components/neo_top_bar.dart';
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
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final unlocksRemaining = widget.appState.postUnlocksRemaining;
        final isPostMode = widget.appState.isPostModeActive;

        return Scaffold(
          backgroundColor: AppTheme.bgMain,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  NeoTopBar(appState: widget.appState),
                  const SizedBox(height: 14),

                  // Card 1: Intentional Post Mode (Active Session or Unlock View)
                  _buildIntentionalPostCard(unlocksRemaining, isPostMode),
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
                        _buildRuleProbeItem('Instagram shield', isPostMode ? 'Temporarily bypassed (Post Mode)' : 'Active & calibrated'),
                        const SizedBox(height: 8),
                        _buildRuleProbeItem('YouTube shield', isPostMode ? 'Temporarily bypassed (Post Mode)' : 'Active & calibrated'),
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
      },
    );
  }

  Widget _buildIntentionalPostCard(int unlocksRemaining, bool isPostMode) {
    if (isPostMode) {
      return NeoCard(
        backgroundColor: const Color(0xFFF0FDF4), // Light green tint
        padding: const EdgeInsets.all(16),
        shadowOffset: const Offset(4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Post Mode Active',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Distraction shield suspended to create and publish content.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF166534),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // Live Countdown Timer
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderBlack, width: 2),
                  boxShadow: AppTheme.hardShadow(offset: const Offset(3, 3)),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.appState.postModeFormattedTime,
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        fontFamily: 'monospace',
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      'time remaining until auto re-lock',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Direct App Launch Buttons
            Row(
              children: [
                Expanded(
                  child: NeoButton(
                    text: 'INSTAGRAM',
                    backgroundColor: AppTheme.accentYellow,
                    textColor: Colors.black,
                    height: 40,
                    fontSize: 11,
                    onPressed: () => widget.onOpenPostService('instagram'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NeoButton(
                    text: 'YOUTUBE',
                    backgroundColor: const Color(0xFFFF8B8B),
                    textColor: Colors.black,
                    height: 40,
                    fontSize: 11,
                    onPressed: () => widget.onOpenPostService('youtube'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Early Re-lock Button
            NeoButton(
              text: 'LOCK SHIELD NOW / FINISH SESSION',
              backgroundColor: Colors.white,
              textColor: Colors.black,
              isFullWidth: true,
              height: 38,
              fontSize: 11,
              onPressed: () async {
                await widget.appState.cancelPostSession();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shield re-engaged! Full distraction blocking active.')),
                  );
                }
              },
            ),
          ],
        ),
      );
    }

    final hasFreeLives = unlocksRemaining > 0;

    return NeoCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
      shadowOffset: const Offset(4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Intentional Post Mode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                hasFreeLives
                    ? 'Get 4 daily unlocks to create and post content without distraction deflection.'
                    : 'You have used all 4 daily lives for today. Request extra time below.',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF555555),
                  height: 1.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                Text(
                  hasFreeLives ? 'free daily unlocks remaining today' : 'free daily lives exhausted',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: hasFreeLives ? const Color(0xFF666666) : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (hasFreeLives) ...[
            // Yellow Button: UNLOCK FOR 30 MIN (1 LIFE)
            NeoButton(
              text: 'UNLOCK FOR 30 MIN (USE 1 LIFE)',
              backgroundColor: AppTheme.accentYellow,
              textColor: Colors.black,
              isFullWidth: true,
              height: 46,
              fontSize: 13,
              onPressed: () => _handleUnlockPostSession(context),
            ),
          ] else ...[
            // When 4 of 4 completed: Provide Request 30 Mins+ (₹10) and Request 60 Mins+ (₹20)
            NeoButton(
              text: '⚡ REQUEST 30 MINS+ (₹10)',
              backgroundColor: const Color(0xFFFFD1DC),
              textColor: Colors.black,
              isFullWidth: true,
              height: 46,
              fontSize: 13,
              onPressed: () => _showSimulatedPaymentDialog(context, durationMinutes: 30, amountRupees: 10),
            ),
            const SizedBox(height: 8),
            NeoButton(
              text: '⚡ REQUEST 60 MINS+ (₹20)',
              backgroundColor: const Color(0xFFE0E7FF),
              textColor: Colors.black,
              isFullWidth: true,
              height: 42,
              fontSize: 12,
              onPressed: () => _showSimulatedPaymentDialog(context, durationMinutes: 60, amountRupees: 20),
            ),
          ],
        ],
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
                    height: 42,
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

  Future<void> _handleUnlockPostSession(BuildContext context) async {
    final success = await widget.appState.startPostSession(durationMinutes: 30);
    if (!success) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: const Text('Post Session Started (30m)', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          'You have exactly 30 minutes to create and publish your post without distraction deflection.\n\nAfter 30 minutes, the shield will automatically re-lock.',
          style: TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('GOT IT', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
          ),
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

  void _showSimulatedPaymentDialog(BuildContext context, {required int durationMinutes, required int amountRupees}) {
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderBlack, width: 2),
              ),
              child: const Icon(Icons.flash_on_rounded, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Unlock $durationMinutes Mins',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderBlack, width: 2),
                boxShadow: AppTheme.hardShadow(offset: const Offset(3, 3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'TOTAL AMOUNT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF555555)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹$amountRupees.00',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderBlack, width: 1.5),
                    ),
                    child: const Text(
                      'SIMULATED PAYMENT',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '• Unlocks full Reels & Shorts access for the duration.\n• Simulated instant checkout (No card/UPI deduction).\n• Auto re-locks as soon as time expires.',
              style: TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
          ),
          NeoButton(
            text: 'PAY ₹$amountRupees & UNLOCK →',
            backgroundColor: AppTheme.accentGreen,
            textColor: Colors.black,
            height: 42,
            fontSize: 12,
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await widget.appState.startPostSessionWithPayment(durationMinutes: durationMinutes);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.black,
                    content: Text(
                      'Payment Simulated! Unlocked $durationMinutes minutes of intentional posting.',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
