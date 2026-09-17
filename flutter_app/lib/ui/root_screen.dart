import 'package:flutter/material.dart';
import '../../core/services/app_state.dart';
import 'home/home_screen.dart';
import 'onboarding/onboarding_flow.dart';
import 'profile/profile_screen.dart';
import 'shield/shield_screen.dart';
import 'theme/app_theme.dart';

class RootScreen extends StatefulWidget {
  final AppState appState;

  const RootScreen({super.key, required this.appState});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;
  bool _forceOnboarding = false;

  void _openShieldTab() {
    setState(() => _currentIndex = 1);
  }

  void _openProfileTab() {
    setState(() => _currentIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appState.needsOnboarding || _forceOnboarding) {
      return OnboardingFlow(
        appState: widget.appState,
        onComplete: () {
          setState(() {
            _forceOnboarding = false;
          });
        },
      );
    }

    final screens = [
      HomeScreen(
        appState: widget.appState,
        onOpenService: (_) => _openShieldTab(),
        onOpenSleep: () {},
        onOpenShield: _openShieldTab,
        onOpenProfile: _openProfileTab,
        onResetOnboarding: () => setState(() => _forceOnboarding = true),
      ),
      ShieldScreen(
        appState: widget.appState,
        onOpenPostService: (_) => _openShieldTab(),
        onBack: () => setState(() => _currentIndex = 0),
      ),
      ProfileScreen(
        appState: widget.appState,
        onResetOnboarding: () => setState(() => _forceOnboarding = true),
        onOpenServices: _openShieldTab,
        onOpenSleep: () {},
        onOpenShield: _openShieldTab,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.bgMain,
          border: Border(
            top: BorderSide(color: AppTheme.borderBlack, width: AppTheme.borderHeavy),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.borderBlack,
              offset: Offset(0, -3),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, 'Home', Icons.home_outlined, AppTheme.accentYellow),
              _navItem(1, 'Shield', Icons.shield_outlined, AppTheme.accentGreen),
              _navItem(2, 'Profile', Icons.person_outline, AppTheme.accentPink),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, String label, IconData icon, Color activeColor) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppTheme.borderBlack, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: isSelected
              ? AppTheme.hardShadow(offset: const Offset(2, 2))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.black : const Color(0xFF555555),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? Colors.black : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
