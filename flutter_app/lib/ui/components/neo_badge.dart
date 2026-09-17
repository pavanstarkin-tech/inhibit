import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeoBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final double fontSize;
  final double borderWidth;
  final double borderRadius;
  final Offset shadowOffset;

  const NeoBadge({
    super.key,
    required this.text,
    this.backgroundColor = AppTheme.accentYellow,
    this.textColor = AppTheme.textMain,
    this.icon,
    this.fontSize = 11.0,
    this.borderWidth = 2.0,
    this.borderRadius = 6.0,
    this.shadowOffset = const Offset(2, 2),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.borderBlack,
          width: borderWidth,
        ),
        boxShadow: shadowOffset != Offset.zero
            ? AppTheme.hardShadow(offset: shadowOffset)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
