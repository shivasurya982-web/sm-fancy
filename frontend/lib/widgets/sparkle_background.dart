import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class LuxurySparkleBackground extends StatefulWidget {
  final Widget child;
  const LuxurySparkleBackground({super.key, required this.child});

  @override
  State<LuxurySparkleBackground> createState() => _LuxurySparkleBackgroundState();
}

class _LuxurySparkleBackgroundState extends State<LuxurySparkleBackground> with TickerProviderStateMixin {
  final List<_AmbientSparkle> _ambientSparkles = [];
  final List<_BurstEffect> _bursts = [];
  late AnimationController _ambientController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 60; i++) {
      _ambientSparkles.add(
        _AmbientSparkle(
          position: Offset(_random.nextDouble(), _random.nextDouble()),
          size: 0.8 + _random.nextDouble() * 2.0,
          duration: Duration(milliseconds: 4000 + _random.nextInt(4000)),
          delay: _random.nextDouble(),
        ),
      );
    }
    _ambientController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    for (final burst in _bursts) {
      burst.controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    setState(() {
      final pos = details.localPosition;
      final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
      final burst = _BurstEffect(position: pos, controller: controller);
      _bursts.add(burst);
      controller.forward().then((_) {
        if (mounted) {
          setState(() {
            _bursts.remove(burst);
            burst.controller.dispose();
          });
        } else {
          burst.controller.dispose();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTapDown: _handleTap,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: AppTheme.deepCharcoal)),
            Positioned.fill(child: Container(decoration: AppTheme.filigreeBackground())),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (context, _) => CustomPaint(painter: _AmbientSparklePainter(_ambientSparkles)),
              ),
            ),
            Positioned.fill(
              child: Stack(
                children: _bursts.map((burst) => AnimatedBuilder(
                  animation: burst.controller,
                  builder: (context, _) => CustomPaint(painter: _BurstPainter(burst, burst.controller.value)),
                )).toList(),
              ),
            ),
            Positioned.fill(child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _AmbientSparkle {
  final Offset position;
  final double size;
  final Duration duration;
  final double delay;
  _AmbientSparkle({required this.position, required this.size, required this.duration, required this.delay});
}

class _AmbientSparklePainter extends CustomPainter {
  final List<_AmbientSparkle> sparkles;
  _AmbientSparklePainter(this.sparkles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var s in sparkles) {
      double time = (now / s.duration.inMilliseconds + s.delay) % 1.0;
      double opacity = 0.1 + (0.3 * sin(time * pi));
      paint.color = AppTheme.polishedSilver.withOpacity(opacity);
      canvas.drawCircle(Offset(s.position.dx * size.width, s.position.dy * size.height), s.size, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BurstEffect {
  final Offset position;
  final AnimationController controller;
  final List<_BurstParticle> particles;
  _BurstEffect({required this.position, required this.controller})
    : particles = List.generate(8, (index) {
        double angle = (2 * pi * index / 8);
        double dist = 20 + Random().nextDouble() * 20;
        return _BurstParticle(
          targetOffset: Offset(cos(angle) * dist, sin(angle) * dist),
          size: 1.0 + Random().nextDouble() * 2.0,
          color: index % 2 == 0 ? AppTheme.brushedPlatinum : AppTheme.sapphireBlue,
        );
      });
}

class _BurstParticle {
  final Offset targetOffset;
  final double size;
  final Color color;
  _BurstParticle({required this.targetOffset, required this.size, required this.color});
}

class _BurstPainter extends CustomPainter {
  final _BurstEffect burst;
  final double progress;
  _BurstPainter(this.burst, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint();
    for (var p in burst.particles) {
      double opacity = (1.0 - progress) * 0.6;
      particlePaint.color = p.color.withOpacity(opacity);
      Offset currentPos = burst.position + (p.targetOffset * progress);
      particlePaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0 * (1.0 - progress));
      canvas.drawCircle(currentPos, p.size * (1.0 + progress), particlePaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
