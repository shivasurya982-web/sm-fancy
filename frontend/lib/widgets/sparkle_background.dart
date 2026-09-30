import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class LuxurySparkleBackground extends StatefulWidget {
  final Widget child;

  const LuxurySparkleBackground({super.key, required this.child});

  @override
  State<LuxurySparkleBackground> createState() => _LuxurySparkleBackgroundState();
}

class _LuxurySparkleBackgroundState extends State<LuxurySparkleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Sparkle> _sparkles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    for (int i = 0; i < 25; i++) {
      _sparkles.add(_Sparkle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2.5 + 1.0,
        speed: _random.nextDouble() * 0.001 + 0.0005,
        opacity: _random.nextDouble() * 0.7 + 0.3,
        pulseSpeed: _random.nextDouble() * 2 + 1,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: AppTheme.filigreeBackground(),
          ),
        ),
        
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _SparklePainter(
                sparkles: _sparkles,
                progress: _controller.value,
              ),
              size: Size.infinite,
            );
          },
        ),

        widget.child,
      ],
    );
  }
}

class _Sparkle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double pulseSpeed;

  _Sparkle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.pulseSpeed,
  });
}

class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double progress;

  _SparklePainter({required this.sparkles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.brushedPlatinum
      ..style = PaintingStyle.fill;

    for (var sparkle in sparkles) {
      sparkle.y -= sparkle.speed;
      if (sparkle.y < 0) {
        sparkle.y = 1.0;
        sparkle.x = Random().nextDouble();
      }

      final pulse = (sin(progress * pi * 2 * sparkle.pulseSpeed) + 1) / 2;
      final currentOpacity = (sparkle.opacity * (0.3 + 0.7 * pulse)).clamp(0.0, 1.0);
      final currentSize = sparkle.size * (0.8 + 0.4 * pulse);

      paint.color = AppTheme.brushedPlatinum.withValues(alpha: currentOpacity);

      final dx = sparkle.x * size.width;
      final dy = sparkle.y * size.height;

      canvas.drawCircle(Offset(dx, dy), currentSize, paint);
      
      final glowPaint = Paint()
        ..color = AppTheme.brushedPlatinum.withValues(alpha: currentOpacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(dx, dy), currentSize * 2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => true;
}
