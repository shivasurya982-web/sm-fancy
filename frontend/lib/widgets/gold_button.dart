import 'package:flutter/material.dart';
import '../config/theme.dart';

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool transparent;
  final double? width;
  final double? height;

  const GoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.transparent = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmall = screenWidth < 360;
    final double defaultHeight = isSmall ? 52 : 56;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width ?? double.infinity,
      height: height ?? defaultHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: transparent ? null : AppTheme.luxuryGradient,
        border: transparent ? Border.all(color: AppTheme.brushedPlatinum, width: 1.2) : null,
        boxShadow: transparent ? null : [
          BoxShadow(
            color: AppTheme.sapphireBlue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: isLoading ? null : onPressed,
          splashColor: AppTheme.sapphireBlue.withValues(alpha: 0.2),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: transparent ? AppTheme.brushedPlatinum : Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: isSmall ? 11 : 12,
                      letterSpacing: isSmall ? 1.2 : 2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
