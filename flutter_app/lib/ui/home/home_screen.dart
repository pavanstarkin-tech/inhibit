import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/service_model.dart';
import '../../core/services/app_state.dart';
import '../../core/services/native_shield_service.dart';
import '../components/neo_badge.dart';
import '../components/neo_card.dart';
import '../settings/settings_menu_screen.dart';
import '../theme/app_theme.dart';
import 'service_settings_sheet.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;
  final Function(String serviceId) onOpenService;
  final VoidCallback onOpenSleep;
  final VoidCallback onOpenShield;
  final VoidCallback onOpenProfile;
  final VoidCallback onResetOnboarding;

  const HomeScreen({
    super.key,
    required this.appState,
    required this.onOpenService,
    required this.onOpenSleep,
    required this.onOpenShield,
    required this.onOpenProfile,
    required this.onResetOnboarding,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _reelsScrolled = 0;
  int _reelsBlocked = 0;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStats();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshStats());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStats();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStats() async {
    final stats = await NativeShieldService.getShieldStats();
    if (mounted) {
      final s = stats['totalReelsScrolled'] ?? 0;
      final b = stats['totalReelsBlocked'] ?? 0;
      if (s != _reelsScrolled || b != _reelsBlocked) {
        setState(() {
          _reelsScrolled = s;
          _reelsBlocked = b;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 12),

              // SCROLL LESS. LIVE MORE. Banner
              _buildHeroBanner(),
              const SizedBox(height: 14),

              // DISTRACTIONS BLOCKED Stat Card (REAL LIVE STATS)
              _buildDistractionsBlockedCard(),
              const SizedBox(height: 20),

              // YOUR SERVICES
              _buildSectionHeader(
                context,
                title: 'PROTECTED SERVICES',
                actionText: 'Settings →',
                onAction: () => _openServiceSettings(context, 'instagram'),
              ),
              const SizedBox(height: 10),
              _buildYourServicesGrid(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Inhibit Logo
        Image.asset(
          'assets/images/logo.png',
          height: 38,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Row(
            children: [
              Text(
                'Inhibit',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 4),
              Text('★', style: TextStyle(fontSize: 20, color: AppTheme.accentYellow)),
            ],
          ),
        ),

        // Settings gear icon
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsMenuScreen(
                  appState: widget.appState,
                ),
              ),
            );
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
            child: const Icon(Icons.settings_outlined, color: Colors.black, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return const NeoCard(
      backgroundColor: Color(0xFFFFD1DC),
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      shadowOffset: Offset(4, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SCROLL LESS.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'LIVE MORE.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Text('😊', style: TextStyle(fontSize: 36)),
        ],
      ),
    );
  }

  Widget _buildDistractionsBlockedCard() {
    final displayBlocked = _reelsBlocked > 0 ? _reelsBlocked : widget.appState.totalItemsBlocked;

    return NeoCard(
      backgroundColor: AppTheme.accentYellow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shadowOffset: const Offset(4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DOOMSCROLLS INTERCEPTED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$displayBlocked',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'today',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: _refreshStats,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderBlack, width: 2),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 26, color: Colors.black),
                ),
              ),
            ],
          ),
          if (_reelsScrolled > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderBlack, width: 1.5),
              ),
              child: Text(
                '📊 Total Reels Scrolled: $_reelsScrolled',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: Colors.black,
          ),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF444444),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildYourServicesGrid(BuildContext context) {
    final services = ServiceInfo.allServices;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: services.length,
      itemBuilder: (ctx, index) {
        final service = services[index];
        final isComingSoon = service.isComingSoon;

        if (isComingSoon) {
          return _buildComingSoonServiceCard(context: context, service: service);
        } else {
          return _buildActiveServiceCard(context: context, service: service);
        }
      },
    );
  }

  Widget _buildActiveServiceCard({
    required BuildContext context,
    required ServiceInfo service,
  }) {
    final iconBg = service.id == 'instagram' ? const Color(0xFFFFD1DC) : const Color(0xFFFF6B6B);

    return NeoCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shadowOffset: const Offset(3, 3),
      onTap: () => _openServiceSettings(context, service.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderBlack, width: 2),
                ),
                child: Icon(service.iconData, size: 18, color: Colors.black),
              ),
              GestureDetector(
                onTap: () => _openServiceSettings(context, service.id),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.more_vert, size: 16, color: Colors.black),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 3),
              const NeoBadge(
                text: 'Active',
                backgroundColor: AppTheme.accentGreen,
                fontSize: 9,
                borderWidth: 1.5,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonServiceCard({
    required BuildContext context,
    required ServiceInfo service,
  }) {
    return Opacity(
      opacity: 0.55,
      child: NeoCard(
        backgroundColor: const Color(0xFFF8FAFC),
        borderColor: const Color(0xFF94A3B8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shadowOffset: const Offset(2, 2),
        onTap: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${service.name} shield support is coming in a future update!'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1E293B),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF94A3B8), width: 1.5),
                  ),
                  child: Icon(service.iconData, size: 18, color: const Color(0xFF64748B)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Soon',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openServiceSettings(BuildContext context, String serviceId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ServiceSettingsSheet(
        serviceId: serviceId,
        appState: widget.appState,
      ),
    );
  }
}

