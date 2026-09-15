import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';

class CameraSearchScreen extends StatelessWidget {
  const CameraSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text("CAMERA SEARCH"),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.glassBorder, width: 1.5),
                    boxShadow: [BoxShadow(color: AppTheme.brushedPlatinum.withOpacity(0.1), blurRadius: 40)],
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 48, color: AppTheme.brushedPlatinum),
                ).animate().fadeIn().scale(duration: 600.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 48),

                const Text(
                  "VISUAL SEARCH",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppTheme.polishedSilver),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Scan an item or upload a photo to find similar luxury pieces.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.coolGrey, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
                ),

                const SizedBox(height: 60),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt_rounded, size: 20),
                    label: const Text("OPEN CAMERA"),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.photo_library_rounded, size: 20),
                    label: const Text("CHOOSE FROM GALLERY"),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
