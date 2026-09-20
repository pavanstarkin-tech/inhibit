import 'package:flutter/material.dart';
import '../../core/services/app_state.dart';
import '../settings/settings_menu_screen.dart';
import '../theme/app_theme.dart';

class NeoTopBar extends StatelessWidget {
  final AppState appState;

  const NeoTopBar({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
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
                  appState: appState,
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
}
