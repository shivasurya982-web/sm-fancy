import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../widgets/gold_button.dart';
import '../bottom_navigation.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final bool isRegistration;

  const OtpScreen({
    super.key,
    required this.email,
    this.isRegistration = true,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendTimer = 30;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() => _resendTimer--);
        _startResendTimer();
      }
    });
  }

  Future<void> _verify() async {
    if (_otp.length < 6) return;
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isVerifying = false);

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const BottomNavigation()),
      (_) => false,
    );
  }

  Future<void> _resend() async {
    setState(() { _isResending = true; _resendTimer = 30; });
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isResending = false);
    _startResendTimer();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP SENT'), backgroundColor: AppTheme.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppTheme.matteBlack,
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 450 : double.infinity),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.brushedPlatinum, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'VERIFY CODE',
                      style: GoogleFonts.playfairDisplay(fontSize: 28, height: 1.1, fontWeight: FontWeight.w900, color: AppTheme.polishedSilver, letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter the 6-digit code sent to\n${widget.email}',
                      style: const TextStyle(color: AppTheme.coolGrey, fontSize: 14, height: 1.5),
                    ),
                    
                    const SizedBox(height: 60),

                    PinCodeTextField(
                      appContext: context,
                      length: 6,
                      obscureText: false,
                      animationType: AnimationType.fade,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(12),
                        fieldHeight: 50,
                        fieldWidth: 45,
                        activeFillColor: Colors.white.withOpacity(0.05),
                        inactiveFillColor: Colors.transparent,
                        selectedFillColor: Colors.white.withOpacity(0.08),
                        activeColor: AppTheme.brushedPlatinum,
                        inactiveColor: AppTheme.glassBorder,
                        selectedColor: AppTheme.brushedPlatinum,
                        borderWidth: 1,
                      ),
                      enableActiveFill: true,
                      keyboardType: TextInputType.number,
                      textStyle: const TextStyle(color: AppTheme.polishedSilver, fontSize: 20, fontWeight: FontWeight.bold),
                      onChanged: (val) => _otp = val,
                      onCompleted: (_) => _verify(),
                    ),

                    const SizedBox(height: 40),

                    GoldButton(
                      label: 'VERIFY',
                      onPressed: _isVerifying ? null : _verify,
                      isLoading: _isVerifying,
                    ),

                    const SizedBox(height: 48),

                    Center(
                      child: _resendTimer > 0
                          ? Text(
                              'Resend code in ${_resendTimer}s',
                              style: const TextStyle(color: AppTheme.coolGrey, fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w500),
                            )
                          : TextButton(
                              onPressed: _isResending ? null : _resend,
                              child: const Text(
                                'RESEND CODE',
                                style: TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 10),
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
}
