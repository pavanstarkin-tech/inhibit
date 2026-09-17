import 'package:flutter/material.dart';
import '../../core/models/service_model.dart';
import '../../core/services/app_state.dart';
import '../components/neo_badge.dart';
import '../components/neo_button.dart';
import '../components/neo_card.dart';
import '../components/neo_switch.dart';
import '../theme/app_theme.dart';

class ServiceSettingsSheet extends StatelessWidget {
  final String serviceId;
  final ServiceInfo? service;
  final AppState appState;
  final VoidCallback? onOpenInBrowser;

  const ServiceSettingsSheet({
    super.key,
    required this.appState,
    this.serviceId = 'instagram',
    this.service,
    this.onOpenInBrowser,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveId = service?.id ?? serviceId;
    final effectiveService = service ?? ServiceInfo.findById(effectiveId) ?? ServiceInfo.allServices[0];
    final isInstagram = effectiveId == 'instagram';

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.bgMain,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: AppTheme.borderBlack, width: 3),
            boxShadow: AppTheme.hardShadow(offset: const Offset(0, -6)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.borderBlack,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isInstagram ? const Color(0xFFFFD1DC) : const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderBlack, width: 2),
                    ),
                    child: Icon(effectiveService.iconData, color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        effectiveService.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const NeoBadge(
                        text: 'Active Shield',
                        backgroundColor: AppTheme.accentGreen,
                        fontSize: 9,
                        borderWidth: 1.5,
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderBlack, width: 2),
                        boxShadow: AppTheme.hardShadow(offset: const Offset(2, 2)),
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // BLOCKED SURFACES SECTION (Verified Only)
              const Text(
                'BLOCKED SURFACES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (isInstagram) ...[
                        _buildSurfaceItem(
                          title: 'Instagram Reels (Auto-Redirect)',
                          subtitle: 'Redirects Reels player to Home on swipe',
                          icon: Icons.movie_outlined,
                          iconBg: const Color(0xFFFFD1DC),
                          value: appState.nativeShieldInstaReels,
                          onChanged: (val) => appState.setGranularShield(blockInstaReels: val),
                        ),
                        const SizedBox(height: 8),
                        _buildSurfaceItem(
                          title: 'Explore Grid',
                          subtitle: 'Blocks algorithmic Explore recommendation feed',
                          icon: Icons.explore_outlined,
                          iconBg: const Color(0xFF70D6FF),
                          value: appState.nativeShieldInstaExplore,
                          onChanged: (val) => appState.setGranularShield(blockInstaExplore: val),
                        ),
                      ] else ...[
                        _buildSurfaceItem(
                          title: 'YouTube Shorts (Auto-Redirect)',
                          subtitle: 'Redirects Shorts player to Home on swipe',
                          icon: Icons.play_arrow_outlined,
                          iconBg: const Color(0xFFFF6B6B),
                          value: appState.nativeShieldYtShorts,
                          onChanged: (val) => appState.setGranularShield(blockYtShorts: val),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // SAFETY RULES (LOCKED)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ALWAYS ALLOWED SURFACES (SAFE)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildLockedSafetyItem(
                        title: isInstagram ? 'Home Feed & Posts' : 'Home Feed & Standard Videos',
                        subtitle: isInstagram
                            ? 'Normal photos, carousel posts, & stories'
                            : 'Standard long-form videos & subscriptions',
                      ),
                      const SizedBox(height: 6),
                      _buildLockedSafetyItem(
                        title: isInstagram ? 'Direct Messages & Chats' : 'Search & Channel Pages',
                        subtitle: 'Always accessible without restrictions',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // SAVE CHANGES Button
              NeoButton(
                text: 'SAVE CHANGES',
                backgroundColor: AppTheme.accentYellow,
                textColor: Colors.black,
                isFullWidth: true,
                height: 48,
                fontSize: 14,
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shield preferences saved!'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.black,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSurfaceItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return NeoCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shadowOffset: const Offset(3, 3),
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
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

  Widget _buildLockedSafetyItem({
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
          const SizedBox(width: 8),
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
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF777777)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

