import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../bottom_navigation.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';
import '../widgets/gold_button.dart';
import '../widgets/sparkle_background.dart';
import 'admin_dashboard_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await AuthService.login(email, password);
      if (!mounted) return;
      
      final role = response['user']['role'] ?? 'user';
      if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BottomNavigation()));
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').replaceFirst('Error: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;
    final bool isSmall = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppTheme.matteBlack,
      body: LuxurySparkleBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: isWeb ? 450 : double.infinity),
                padding: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 32, vertical: isSmall ? 24 : 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    
                    Center(
                      child: Container(
                        width: isSmall ? 100 : 120, height: isSmall ? 100 : 120,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: Image.asset('assets/images/logo1.png', fit: BoxFit.contain),
                      ),
                    ).animate().fadeIn().scale(),

                    SizedBox(height: isSmall ? 24 : 36),

                    Text(
                      'LOGIN',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(letterSpacing: 2, fontSize: isSmall ? 20 : 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome back to your luxury collective.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    SizedBox(height: isSmall ? 32 : 40),

                    _buildLabel('EMAIL ADDRESS'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(hintText: 'ENTER YOUR EMAIL'),
                    ),

                    const SizedBox(height: 20),

                    _buildLabel('PASSWORD'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(_hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppTheme.coolGrey),
                          onPressed: () => setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        child: const Text('FORGOT PASSWORD?', style: TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ),
                    ),

                    SizedBox(height: isSmall ? 28 : 36),

                    GoldButton(
                      label: 'LOGIN',
                      onPressed: _handleLogin,
                      isLoading: _isLoading,
                    ),

                    SizedBox(height: isSmall ? 32 : 40),

                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                        child: RichText(
                          text: TextSpan(
                            text: "IF YOU'R NEW, ",
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.coolGrey),
                            children: const [
                              TextSpan(
                                text: 'CREATE ACCOUNT',
                                style: TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9));
  }
}
