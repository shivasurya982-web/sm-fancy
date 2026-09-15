import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../services/settings_service.dart';
import '../widgets/gold_button.dart';
import '../bottom_navigation.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<dynamic> _banners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.getSettings();
    if (mounted) {
      setState(() {
        _banners = settings['onboardingBanners'] ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.matteBlack,
        body: Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum)),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppTheme.matteBlack,
      body: Stack(
        children: [
          Positioned.fill(child: Container(decoration: AppTheme.filigreeBackground())),

          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: _banners.length,
            itemBuilder: (ctx, idx) {
              final banner = _banners[idx];
              return Stack(
                fit: StackFit.expand,
                children: [
                  _buildBannerImage(banner['image']),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.2), Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWeb ? 500 : double.infinity),
              child: Stack(
                children: [
                   Positioned(
                    bottom: 60,
                    left: 40,
                    right: 40,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GoldButton(
                          label: 'EXPLORE SHOP',
                          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BottomNavigation())),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                                    child: Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(color: AppTheme.glassBorder, width: 1),
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text('LOGIN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                                    child: Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(color: AppTheme.glassBorder, width: 1),
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text('SIGN UP', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return Container(color: AppTheme.matteBlack);
    
    if (imagePath == 'assets/images/logo.png' || imagePath == 'assets/images/logo1.png') {
       return Container(
         color: AppTheme.matteBlack,
         child: Center(child: Image.asset(imagePath, width: 250, opacity: const AlwaysStoppedAnimation(0.2))),
       );
    }
    
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => Container(color: AppTheme.matteBlack),
      );
    } else {
      return Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: AppTheme.matteBlack));
    }
  }
}
