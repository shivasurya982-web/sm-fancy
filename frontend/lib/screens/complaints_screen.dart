import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../config/theme.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  Future<void> _handleSubmit() async {
      if (_subjectController.text.isEmpty || _messageController.text.isEmpty) return;
      setState(() => _isSending = true);
      try {
          await ApiService.post('/complaints', {
              'subject': _subjectController.text.trim(),
              'message': _messageController.text.trim(),
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent successfully.'), backgroundColor: AppTheme.success));
          Navigator.pop(context);
      } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      } finally {
          if (mounted) setState(() => _isSending = false);
      }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text('HELP & SUPPORT'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 500 : double.infinity),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CONTACT US', style: Theme.of(context).textTheme.headlineLarge?.copyWith(letterSpacing: 2, fontSize: 28)),
                  const SizedBox(height: 12),
                  const Text('Our team will review your message within 24-48 hours.', style: TextStyle(color: AppTheme.coolGrey, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 40),
                  
                  Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.premiumCard(radius: 24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text('SUBJECT', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8, color: Colors.white70)),
                              const SizedBox(height: 12),
                              TextField(
                                  controller: _subjectController,
                                  style: const TextStyle(fontSize: 14, color: AppTheme.polishedSilver, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                      hintText: 'Inquiry, Issue, etc.',
                                      hintStyle: const TextStyle(color: Colors.white24),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.03),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                  ),
                              ),
                              const SizedBox(height: 24),
                              Text('MESSAGE', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8, color: Colors.white70)),
                              const SizedBox(height: 12),
                              TextField(
                                  controller: _messageController,
                                  maxLines: 5,
                                  style: const TextStyle(fontSize: 14, color: AppTheme.polishedSilver, height: 1.5),
                                  decoration: InputDecoration(
                                      hintText: 'Please detail your request...',
                                      hintStyle: const TextStyle(color: Colors.white24),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.03),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                                  ),
                              ),
                          ],
                      ),
                  ).animate().fadeIn().scale(begin: const Offset(0.98, 0.98)),
                  
                  const SizedBox(height: 48),
                  SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                          onPressed: _isSending ? null : _handleSubmit,
                          child: _isSending ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.black) : const Text('SUBMIT'),
                      ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
