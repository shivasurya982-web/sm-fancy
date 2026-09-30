import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? title;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.title,
  });

  static void show(BuildContext context, String url, {String? title}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        pageBuilder: (BuildContext context, _, __) {
          return FullScreenImageViewer(imageUrl: url, title: title);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    final Matrix4 currentMatrix = _transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();

    if (currentScale > 1.0) {
      _animation = Matrix4Tween(
        begin: currentMatrix,
        end: Matrix4.identity(),
      ).animate(CurveTween(curve: Curves.easeInOut).animate(_animationController));
    } else {
      final position = _doubleTapDetails!.localPosition;
      final double scale = 2.5;
      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);

      final Matrix4 zoomed = Matrix4.identity()
        ..translate(x, y)
        ..scale(scale);

      _animation = Matrix4Tween(
        begin: currentMatrix,
        end: zoomed,
      ).animate(CurveTween(curve: Curves.easeInOut).animate(_animationController));
    }

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: GestureDetector(
                onDoubleTapDown: _handleDoubleTapDown,
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  clipBehavior: Clip.none,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: AppTheme.brushedPlatinum),
                    ),
                    errorWidget: (context, url, error) => const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_outlined, color: AppTheme.coolGrey, size: 48),
                        SizedBox(height: 16),
                        Text('UNABLE TO LOAD IMAGE', style: TextStyle(color: AppTheme.coolGrey, fontSize: 10, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Top Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (widget.title != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          widget.title!.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.polishedSilver,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
