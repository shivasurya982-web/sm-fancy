import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';

class VoiceSearchScreen extends StatelessWidget {
  const VoiceSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text("VOICE SEARCH"),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Center(
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
                child: const Icon(Icons.mic_rounded, size: 48, color: AppTheme.brushedPlatinum),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1), duration: 1500.ms, curve: Curves.easeInOut),

              const SizedBox(height: 48),

              const Text(
                "TAP TO SPEAK",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppTheme.polishedSilver),
              ),

              const SizedBox(height: 12),

              const Text(
                "Voice search will be available soon.",
                style: TextStyle(color: AppTheme.coolGrey, fontSize: 14, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: 220,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.mic_rounded, size: 20),
                  label: const Text("START LISTENING"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
