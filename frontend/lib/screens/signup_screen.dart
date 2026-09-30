import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';
import '../widgets/gold_button.dart';
import '../widgets/sparkle_background.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _hintController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) return;
    if (password != _confirmController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.register(name: name, email: email, password: password, recoveryHint: _hintController.text.trim());
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '').replaceFirst('Error: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.error));
      }
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
                    Text('REGISTER', style: Theme.of(context).textTheme.headlineLarge?.copyWith(letterSpacing: 2, fontSize: isSmall ? 20 : 24)),
                    const SizedBox(height: 8),
                    Text('Welcome to SM Fancy.', style: Theme.of(context).textTheme.bodyMedium),

                    SizedBox(height: isSmall ? 28 : 36),

                    _buildField('FULL NAME', _nameController, hint: 'ENTER YOUR NAME'),
                    const SizedBox(height: 18),
                    _buildField('EMAIL ADDRESS', _emailController, hint: 'ENTER YOUR EMAIL'),
                    const SizedBox(height: 18),
                    _buildField('RECOVERY HINT', _hintController, hint: 'ENTER RECOVERY HINT'),
                    const SizedBox(height: 18),
                    _buildField('PASSWORD', _passwordController, obscure: true, hint: '••••••••'),
                    const SizedBox(height: 18),
                    _buildField('CONFIRM PASSWORD', _confirmController, obscure: true, hint: '••••••••'),

                    SizedBox(height: isSmall ? 28 : 36),

                    GoldButton(
                      label: 'SIGN UP',
                      onPressed: _handleSignup,
                      isLoading: _isLoading,
                    ),
                    
                    SizedBox(height: isSmall ? 24 : 32),

                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                        child: RichText(
                          text: TextSpan(
                            text: "ALREADY HAVE AN ACCOUNT? ",
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.coolGrey),
                            children: const [
                              TextSpan(
                                text: 'LOGIN',
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

  Widget _buildField(String label, TextEditingController ctrl, {bool obscure = false, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9)),
        const SizedBox(height: 10),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
