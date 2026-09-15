import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'English';

  final List<Map<String, dynamic>> _languages = [
    {'name': 'English', 'native': 'English', 'code': 'en'},
    {'name': 'Hindi', 'native': 'हिंदी', 'code': 'hi'},
    {'name': 'Tamil', 'native': 'தமிழ்', 'code': 'ta'},
    {'name': 'Arabic', 'native': 'العربية', 'code': 'ar'},
    {'name': 'French', 'native': 'Français', 'code': 'fr'},
    {'name': 'German', 'native': 'Deutsch', 'code': 'de'},
    {'name': 'Spanish', 'native': 'Español', 'code': 'es'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text('SELECT LANGUAGE'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Language saved successfully'), backgroundColor: AppTheme.success));
              Navigator.pop(context);
            },
            child: const Text('SAVE', style: TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CHOOSE YOUR PREFERRED LANGUAGE', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _languages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final lang = _languages[index];
                    final isSelected = _selected == lang['name'];
                    return GestureDetector(
                      onTap: () => setState(() => _selected = lang['name']),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.premiumCard(radius: 24),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lang['name'].toString().toUpperCase(), style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500, fontSize: 13, color: isSelected ? AppTheme.polishedSilver : AppTheme.coolGrey, letterSpacing: 1)),
                                const SizedBox(height: 4),
                                Text(lang['native'], style: const TextStyle(color: AppTheme.coolGrey, fontSize: 11, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const Spacer(),
                            if (isSelected) 
                                Container(
                                    width: 10, height: 10, 
                                    decoration: const BoxDecoration(
                                        color: AppTheme.brushedPlatinum, 
                                        shape: BoxShape.circle, 
                                        boxShadow: [BoxShadow(color: Colors.white, blurRadius: 4)]
                                    )
                                ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
