import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final Offset shadowOffset;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const NeoCard({
    super.key,
    required this.child,
    this.backgroundColor = AppTheme.bgCard,
    this.borderColor = AppTheme.borderBlack,
    this.borderWidth = AppTheme.borderStandard,
    this.shadowOffset = AppTheme.shadowStandard,
    this.borderRadius = 10.0,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: shadowOffset != Offset.zero
            ? AppTheme.hardShadow(offset: shadowOffset, color: borderColor)
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
