import 'package:flutter/material.dart';
import '../../core/models/service_model.dart';
import '../../core/services/app_state.dart';
import '../components/neo_card.dart';
import '../components/neo_top_bar.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  final AppState appState;
  final VoidCallback onResetOnboarding;
  final VoidCallback onOpenServices;
  final VoidCallback onOpenSleep;
  final VoidCallback onOpenShield;

  const ProfileScreen({
    super.key,
    required this.appState,
    required this.onResetOnboarding,
    required this.onOpenServices,
    required this.onOpenSleep,
    required this.onOpenShield,
  });

  @override
  Widget build(BuildContext context) {
    final life = appState.lifeInWeeks;
    final savedDaily = appState.scrollHoursPerDay;
    final savedYearly = (savedDaily * 365).round();
    final lifetimeGained = life.yearsLostToScrolling;

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              NeoTopBar(appState: appState),
              const SizedBox(height: 14),

              // Card 1: YOUR IMPACT (Screen 11)
              NeoCard(
                backgroundColor: const Color(0xFFD1FAE5), // soft green card
                padding: const EdgeInsets.all(16),
                shadowOffset: const Offset(4, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR IMPACT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildImpactColumn(
                            value: '${savedDaily.toStringAsFixed(1)}h',
                            label: 'saved daily',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildImpactColumn(
                            value: savedYearly >= 1000 ? '${(savedYearly / 1000).toStringAsFixed(3).replaceFirst('.', ',')}h' : '${savedYearly}h',
                            label: 'yearly',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildImpactColumn(
                            value: lifetimeGained.toStringAsFixed(1),
                            label: 'years\nlifetime gained',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    const Center(
                      child: Text(
                        '✨ More time for what actually matters.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card 2: PRIVACY GUARANTEE (Screen 11)
              NeoCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shadowOffset: const Offset(4, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRIVACY GUARANTEE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildPrivacyCheckItem('No server analytics'),
                    const SizedBox(height: 10),
                    _buildPrivacyCheckItem('No cloud tracking'),
                    const SizedBox(height: 10),
                    _buildPrivacyCheckItem('All credentials stay on your device'),
                    const SizedBox(height: 10),
                    _buildPrivacyCheckItem('Open source rule engine'),
                    const SizedBox(height: 10),
                    _buildPrivacyCheckItem("You're in control"),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card 3: Installed Rule Bundles (Screen 11)
              NeoCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shadowOffset: const Offset(4, 4),
                onTap: () => _showRuleBundlesDialog(context),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderBlack, width: 2),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Installed Rule Bundles',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '${ServiceInfo.activeServices.length} active services • Instagram & YouTube',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.black, size: 22),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactColumn({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderBlack, width: 2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF555555),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCheckItem(String text) {
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
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  void _showRuleBundlesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.bgMain,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppTheme.borderBlack, width: 3),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'INSTALLED RULE BUNDLES',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...ServiceInfo.activeServices.map((svc) {
              final bundle = appState.bundles[svc.id];
              final ruleCount = bundle?.services[svc.id]?.surfaces.length ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(svc.iconData, size: 18),
                    const SizedBox(width: 8),
                    Text(svc.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('v${bundle?.version ?? 1} • $ruleCount rules', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
