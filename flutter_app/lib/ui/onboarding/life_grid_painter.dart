import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/life_in_weeks.dart';
import '../theme/app_theme.dart';

class LifeGridPainter extends CustomPainter {
  final LifeInWeeks life;
  final double progress; // 0.0 to 1.0

  static const int columns = 52;
  static const double spacing = 1.6;

  LifeGridPainter({
    required this.life,
    this.progress = 1.0,
  });

  Color colorForBand(LifeBandKind kind) {
    switch (kind) {
      case LifeBandKind.past:
        return AppTheme.bandPast;
      case LifeBandKind.sleep:
        return AppTheme.bandSleep;
      case LifeBandKind.work:
        return AppTheme.bandWork;
      case LifeBandKind.hygiene:
        return AppTheme.bandHygiene;
      case LifeBandKind.scrolling:
        return AppTheme.bandScrolling;
      case LifeBandKind.free:
        return AppTheme.bandFree;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double cols = columns.toDouble();
    final double cell = (size.width - spacing * (cols - 1)) / cols;
    if (cell <= 0) return;

    final double radius = cell * 0.25;
    final int shown = (life.totalWeeks * progress).round();
    if (shown <= 0) return;

    var index = 0;
    for (final band in life.bands) {
      if (band.weeks <= 0) continue;
      if (index >= shown) break;

      final paint = Paint()
        ..color = colorForBand(band.kind)
        ..style = PaintingStyle.fill;

      final end = math.min(index + band.weeks, shown);
      for (var i = index; i < end; i++) {
        final row = i ~/ columns;
        final col = i % columns;
        final x = col * (cell + spacing);
        final y = row * (cell + spacing);

        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cell, cell),
          Radius.circular(radius),
        );
        canvas.drawRRect(rrect, paint);
      }
      index += band.weeks;
    }
  }

  @override
  bool shouldRepaint(covariant LifeGridPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.life.age != life.age ||
        oldDelegate.life.scrollHoursPerDay != life.scrollHoursPerDay;
  }
}

class LifeGridWidget extends StatelessWidget {
  final LifeInWeeks life;
  final double progress;

  const LifeGridWidget({
    super.key,
    required this.life,
    this.progress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final rows = (life.totalWeeks / LifeGridPainter.columns).ceil();
    final aspect = LifeGridPainter.columns / math.max(rows, 1).toDouble();

    return AspectRatio(
      aspectRatio: aspect,
      child: CustomPaint(
        painter: LifeGridPainter(life: life, progress: progress),
      ),
    );
  }
}
