import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../widgets/gold_button.dart';
import '../services/api_service.dart';
import '../bottom_navigation.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _hintController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _hintController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();
    final hint = _hintController.text.trim();
    final newPass = _newPasswordController.text;
    if (email.isEmpty || hint.isEmpty || newPass.isEmpty) return;

    setState(() => _isLoading = true);
    try {
        await ApiService.post('/auth/forgot-password', {'email': email, 'recoveryHint': hint, 'newPassword': newPass});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successfully.'), backgroundColor: AppTheme.success));
        Navigator.pop(context);
    } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
        if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text('FORGOT PASSWORD'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 450 : double.infinity),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle, border: Border.all(color: AppTheme.glassBorder, width: 1)),
                    child: const Icon(Icons.lock_open_rounded, size: 48, color: AppTheme.brushedPlatinum),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: AppTheme.premiumCard(radius: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RESET PASSWORD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 18, color: AppTheme.polishedSilver)),
                        const SizedBox(height: 12),
                        const Text('Please verify your details to set a new password.', style: TextStyle(color: AppTheme.coolGrey, height: 1.5, fontSize: 13)),
                        const SizedBox(height: 40),
                        _buildField('EMAIL ADDRESS', _emailController, Icons.email_outlined),
                        const SizedBox(height: 24),
                        _buildField('RECOVERY HINT', _hintController, Icons.help_outline_rounded),
                        const SizedBox(height: 24),
                        _buildField('NEW PASSWORD', _newPasswordController, Icons.lock_outline_rounded, obscure: true),
                        const SizedBox(height: 48),
                        GoldButton(label: 'RESET', onPressed: _isLoading ? null : _handleReset, isLoading: _isLoading),
                      ],
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool obscure = false}) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9)),
              const SizedBox(height: 12),
              TextField(
                  controller: ctrl,
                  obscureText: obscure,
                  style: const TextStyle(fontSize: 14, color: AppTheme.polishedSilver, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(prefixIcon: Icon(icon, color: AppTheme.brushedPlatinum, size: 18), hintText: label.toLowerCase()),
              ),
          ],
      );
  }
}
