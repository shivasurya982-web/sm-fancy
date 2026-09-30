import 'dart:ui';
import 'package:flutter/material.dart';
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
  List<dynamic> _banners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    final bool isSmall = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppTheme.matteBlack,
      body: Stack(
        children: [
          Positioned.fill(child: Container(decoration: AppTheme.filigreeBackground())),

          if (_banners.isNotEmpty)
            PageView.builder(
              controller: _pageController,
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
                          colors: [Colors.black.withValues(alpha: 0.2), Colors.black],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(isSmall ? 20 : 32, 20, isSmall ? 20 : 32, isSmall ? 24 : 40),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWeb ? 450 : double.infinity),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GoldButton(
                        label: 'GUEST ACCESS',
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BottomNavigation())),
                      ),
                      const SizedBox(height: 16),
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
                                    height: isSmall ? 52 : 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(color: AppTheme.glassBorder, width: 1),
                                      color: Colors.white.withValues(alpha: 0.05),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text('LOGIN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                                  child: Container(
                                    height: isSmall ? 52 : 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(color: AppTheme.glassBorder, width: 1),
                                      color: Colors.white.withValues(alpha: 0.05),
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
