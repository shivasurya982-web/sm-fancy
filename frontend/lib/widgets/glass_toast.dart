import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/theme.dart';

void showGlassToast(BuildContext context, String message, {bool isError = false, String? title}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => _GlassToastWidget(
      message: message,
      title: title,
      isError: isError,
      onDismiss: () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      },
    ),
  );

  overlay.insert(overlayEntry);
}

class _GlassToastWidget extends StatefulWidget {
  final String message;
  final String? title;
  final bool isError;
  final VoidCallback onDismiss;

  const _GlassToastWidget({
    required this.message,
    this.title,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_GlassToastWidget> createState() => _GlassToastWidgetState();
}

class _GlassToastWidgetState extends State<_GlassToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Auto dismiss after 2.8 seconds
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top + 12;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    final Color accentColor = widget.isError ? AppTheme.error : AppTheme.brushedPlatinum;
    final IconData icon = widget.isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

    return Positioned(
      top: topPadding,
      left: isNarrow ? 12 : 20,
      right: isNarrow ? 12 : 20,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.deepCharcoal.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.isError 
                        ? AppTheme.error.withValues(alpha: 0.5) 
                        : AppTheme.glassBorder, 
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: accentColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title ?? (widget.isError ? 'NOTICE' : 'SUCCESS'),
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message,
                              style: const TextStyle(
                                color: AppTheme.polishedSilver,
                                fontSize: 12,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
