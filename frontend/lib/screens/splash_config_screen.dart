import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/settings_service.dart';
import '../services/upload_service.dart';
import '../config/theme.dart';
import '../widgets/gold_button.dart';

class SplashConfigScreen extends StatefulWidget {
  const SplashConfigScreen({super.key});

  @override
  State<SplashConfigScreen> createState() => _SplashConfigScreenState();
}

class _SplashConfigScreenState extends State<SplashConfigScreen> {
  final _taglineController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _localCityController = TextEditingController();
  final _localFeeController = TextEditingController();
  final _standardFeeController = TextEditingController();
  List<dynamic> _welcomeBanners = [];
  List<dynamic> _homeBanners = [];
  String? _upiQrUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _taglineController.dispose();
    _upiIdController.dispose();
    _ownerPhoneController.dispose();
    _localCityController.dispose();
    _localFeeController.dispose();
    _standardFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await SettingsService.getSettings();
      setState(() {
        _taglineController.text = settings['splashTagline'] ?? '';
        _upiIdController.text = settings['upiId'] ?? '';
        _ownerPhoneController.text = settings['ownerPhone'] ?? '9443039600';
        _localCityController.text = settings['localCity'] ?? '';
        _localFeeController.text = (settings['localShippingFee'] ?? 0.0).toString();
        _standardFeeController.text = (settings['standardShippingFee'] ?? 0.0).toString();
        _welcomeBanners = settings['onboardingBanners'] ?? [];
        _homeBanners = settings['homeBanners'] ?? [];
        _upiQrUrl = settings['upiQrCode'];
      });
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await SettingsService.updateSettings({
        'splashTagline': _taglineController.text.trim(),
        'upiId': _upiIdController.text.trim(),
        'ownerPhone': _ownerPhoneController.text.trim(),
        'upiQrCode': _upiQrUrl,
        'localCity': _localCityController.text.trim(),
        'localShippingFee': double.tryParse(_localFeeController.text) ?? 0.0,
        'standardShippingFee': double.tryParse(_standardFeeController.text) ?? 0.0,
        'onboardingBanners': _welcomeBanners,
        'homeBanners': _homeBanners,
      });
      if (mounted) { 
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated.'), backgroundColor: AppTheme.success)); 
          Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;
    final bool isNarrow = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text('APP SETTINGS'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 500 : double.infinity),
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader('GENERAL SETTINGS'),
                    const SizedBox(height: 20),
                    _buildInput('SPLASH TAGLINE', _taglineController),
                    const SizedBox(height: 14),
                    _buildInput('CONTACT PHONE', _ownerPhoneController, numeric: true),
                    const SizedBox(height: 14),
                    _buildInput('UPI ID', _upiIdController),
                    const SizedBox(height: 28),
                    const Text('UPI QR CODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.coolGrey)),
                    const SizedBox(height: 14),
                    Center(
                        child: GestureDetector(
                            onTap: () async {
                                final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                                if (img != null) { setState(() => _isLoading = true); final url = await UploadService.uploadImage(img); setState(() { _upiQrUrl = url; _isLoading = false; }); }
                            },
                            child: Container(
                                width: 160, height: 160,
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05), 
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: AppTheme.glassBorder, width: 1)
                                ),
                                child: _upiQrUrl != null 
                                    ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.network(_upiQrUrl!, fit: BoxFit.cover))
                                    : const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.brushedPlatinum, size: 48),
                            ),
                        ),
                    ),
                    const SizedBox(height: 36),
                    _buildHeader('SHIPPING FEES'),
                    const SizedBox(height: 20),
                    _buildInput('LOCAL CITY', _localCityController),
                    const SizedBox(height: 14),
                    Row(
                        children: [
                            Expanded(child: _buildInput('LOCAL FEE', _localFeeController, numeric: true)), 
                            const SizedBox(width: 14), 
                            Expanded(child: _buildInput('STANDARD FEE', _standardFeeController, numeric: true))
                        ]
                    ),
                    const SizedBox(height: 36),
                    GoldButton(label: 'SAVE SETTINGS', onPressed: _save),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) => Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9));

  Widget _buildInput(String label, TextEditingController ctrl, {bool numeric = false}) {
    return TextField(controller: ctrl, keyboardType: numeric ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 9, letterSpacing: 1)));
  }
}
