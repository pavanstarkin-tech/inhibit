import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final bool isFullWidth;
  final double height;
  final double fontSize;
  final double borderWidth;
  final double borderRadius;
  final Offset shadowOffset;

  const NeoButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = AppTheme.accentYellow,
    this.textColor = AppTheme.textMain,
    this.icon,
    this.isFullWidth = false,
    this.height = 50.0,
    this.fontSize = 14.0,
    this.borderWidth = AppTheme.borderStandard,
    this.borderRadius = 8.0,
    this.shadowOffset = const Offset(4, 4),
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final currentBg = isDisabled
        ? const Color(0xFFE2E8F0)
        : widget.backgroundColor;
    final currentOffset = (_isPressed || isDisabled)
        ? Offset.zero
        : widget.shadowOffset;
    final translation = _isPressed
        ? widget.shadowOffset
        : Offset.zero;

    Widget buttonBody = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeInOut,
      transform: Matrix4.translationValues(translation.dx, translation.dy, 0),
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: currentBg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: AppTheme.borderBlack,
          width: widget.borderWidth,
        ),
        boxShadow: currentOffset != Offset.zero
            ? AppTheme.hardShadow(offset: currentOffset)
            : null,
      ),
      child: Row(
        mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: widget.textColor, size: widget.fontSize + 4),
            const SizedBox(width: 8),
          ],
          Text(
            widget.text,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isDisabled ? const Color(0xFF888888) : widget.textColor,
            ),
          ),
        ],
      ),
    );

    if (widget.isFullWidth) {
      buttonBody = SizedBox(width: double.infinity, child: buttonBody);
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: buttonBody,
    );
  }
}
