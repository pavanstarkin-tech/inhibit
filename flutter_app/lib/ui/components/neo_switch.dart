import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeoSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;
  final Color inactiveColor;

  const NeoSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = AppTheme.accentGreen,
    this.inactiveColor = const Color(0xFFE2E8F0),
  });

  @override
  Widget build(BuildContext context) {
    const width = 54.0;
    const height = 30.0;
    const thumbSize = 22.0;

    final isDisabled = onChanged == null;

    return GestureDetector(
      onTap: isDisabled ? null : () => onChanged?.call(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeInOut,
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: isDisabled
              ? const Color(0xFFCBD5E1)
              : (value ? activeColor : inactiveColor),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppTheme.borderBlack,
            width: 2.5,
          ),
          boxShadow: AppTheme.hardShadow(offset: const Offset(2, 2)),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: thumbSize,
          height: thumbSize,
          decoration: BoxDecoration(
            color: value ? AppTheme.accentYellow : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.borderBlack,
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              value ? Icons.check : Icons.close,
              size: 12,
              color: AppTheme.textMain,
            ),
          ),
        ),
      ),
    );
  }
}
