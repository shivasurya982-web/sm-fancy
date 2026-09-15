import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/upload_service.dart';
import '../config/theme.dart';
import '../widgets/gold_button.dart';
import 'login_screen.dart';
import 'address_screen.dart';
import 'complaints_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hintController = TextEditingController();

  String? _profileImagePath;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  bool _notificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final user = await ApiService.get('/auth/me');
      if (user != null) {
        _nameController.text = user['name'] ?? '';
        _emailController.text = user['email'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _hintController.text = user['recoveryHint'] ?? '';
        _profileImagePath = user['avatar'] ?? '';
        _notificationEnabled = user['notificationEnabled'] ?? true;

        await UserService.saveUser(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          profileImage: _profileImagePath,
        );
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final hint = _hintController.text.trim();

    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.put('/auth/me', {
        'name': name,
        'phone': phone,
        'avatar': _profileImagePath,
      });

      if (hint.isNotEmpty) {
        await ApiService.put('/auth/recovery-hint', {'recoveryHint': hint});
      }

      await UserService.saveUser(
        name: name,
        email: _emailController.text,
        phone: phone,
        profileImage: _profileImagePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.success));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final imageUrl = await UploadService.uploadImage(image);
        if (imageUrl != null) {
          setState(() => _profileImagePath = imageUrl);
          await _updateProfile();
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showEditDialog() {
    final nameEdit = TextEditingController(text: _nameController.text);
    final phoneEdit = TextEditingController(text: _phoneController.text);
    final hintEdit = TextEditingController(text: _hintController.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppTheme.deepCharcoal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: AppTheme.glassBorder, width: 0.5)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 32, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EDIT PROFILE',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontSize: 22, letterSpacing: 1.5)),
              const SizedBox(height: 40),
              _buildRegisterStyleField('FULL NAME', nameEdit, hint: 'e.g. John Doe'),
              const SizedBox(height: 24),
              _buildRegisterStyleField('EMAIL ADDRESS', _emailController,
                  hint: 'john@example.com', enabled: false),
              const SizedBox(height: 24),
              _buildRegisterStyleField('PHONE NUMBER', phoneEdit,
                  hint: 'Enter your phone', keyboard: TextInputType.phone),
              const SizedBox(height: 24),
              _buildRegisterStyleField('RECOVERY HINT', hintEdit,
                  hint: 'Security answer'),
              const SizedBox(height: 48),
              GoldButton(
                label: 'SAVE CHANGES',
                onPressed: () {
                  _nameController.text = nameEdit.text;
                  _phoneController.text = phoneEdit.text;
                  _hintController.text = hintEdit.text;
                  Navigator.pop(ctx);
                  _updateProfile();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppTheme.deepCharcoal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: AppTheme.glassBorder, width: 0.5)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 32, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CHANGE PASSWORD',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontSize: 22, letterSpacing: 1.5)),
              const SizedBox(height: 40),
              _buildRegisterStyleField('CURRENT PASSWORD', currentPass,
                  hint: '••••••••', obscure: true),
              const SizedBox(height: 24),
              _buildRegisterStyleField('NEW PASSWORD', newPass,
                  hint: '••••••••', obscure: true),
              const SizedBox(height: 24),
              _buildRegisterStyleField('CONFIRM NEW PASSWORD', confirmPass,
                  hint: '••••••••', obscure: true),
              const SizedBox(height: 48),
              GoldButton(
                label: 'UPDATE PASSWORD',
                onPressed: () async {
                  if (newPass.text != confirmPass.text) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Passwords do not match'),
                        backgroundColor: AppTheme.error));
                    return;
                  }
                  if (currentPass.text.isEmpty || newPass.text.isEmpty) return;

                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  try {
                    await ApiService.put('/auth/change-password', {
                      'currentPassword': currentPass.text,
                      'newPassword': newPass.text
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Password updated successfully'),
                          backgroundColor: AppTheme.success));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Failed to update password: $e'),
                          backgroundColor: AppTheme.error));
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterStyleField(String label, TextEditingController ctrl,
      {String? hint,
      bool enabled = true,
      bool obscure = false,
      TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontSize: 9, color: Colors.white70)),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl,
          enabled: enabled,
          obscureText: obscure,
          keyboardType: keyboard,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: enabled ? AppTheme.polishedSilver : AppTheme.coolGrey),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: const BorderSide(color: AppTheme.glassBorder)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWeb ? 500 : double.infinity),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PROFILE', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 32),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildSectionTitle('COLLECTIONS'),
                    const SizedBox(height: 16),
                    _buildMenuCard([
                      _buildMenuTile(Icons.map_outlined, 'Saved Addresses', () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AddressScreen()));
                      }),
                    ]),
                    const SizedBox(height: 32),
                    _buildSectionTitle('SECURITY'),
                    const SizedBox(height: 16),
                    _buildMenuCard([
                      _buildMenuTile(Icons.lock_outline_rounded, 'Change Password',
                          _showChangePasswordDialog),
                    ]),
                    const SizedBox(height: 32),
                    _buildSectionTitle('PREFERENCES'),
                    const SizedBox(height: 16),
                    _buildMenuCard([
                      _buildToggleTile('Notifications', _notificationEnabled, (v) {
                        setState(() => _notificationEnabled = v);
                        ApiService.put(
                            '/auth/preferences', {'notificationEnabled': v});
                      }),
                    ]),
                    const SizedBox(height: 32),
                    _buildSectionTitle('CONCIERGE'),
                    const SizedBox(height: 16),
                    _buildMenuCard([
                      _buildMenuTile(Icons.help_outline_rounded, 'Help & Support', () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ComplaintsScreen()));
                      }),
                    ]),
                    const SizedBox(height: 48),
                    _buildLogoutBtn(),
                  ],
                ),
              ),
              if (_isLoading)
                const Center(
                    child: CircularProgressIndicator(color: AppTheme.brushedPlatinum)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.premiumCard(radius: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.glassBorder, width: 1),
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: ClipOval(
                    child: _profileImagePath != null &&
                            _profileImagePath!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _profileImagePath!, fit: BoxFit.cover)
                        : const Icon(Icons.person_outline_rounded,
                            color: AppTheme.coolGrey, size: 28),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppTheme.brushedPlatinum, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 12, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.polishedSilver,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(_emailController.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.coolGrey, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            onPressed: _showEditDialog,
            icon: const Icon(Icons.edit_note_rounded,
                color: AppTheme.brushedPlatinum, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8));
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: AppTheme.premiumCard(radius: 24),
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.brushedPlatinum, size: 18),
        title: Text(title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.polishedSilver)),
        trailing: const Icon(Icons.chevron_right_rounded,
            size: 16, color: Colors.white10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  Widget _buildToggleTile(String title, bool val, ValueChanged<bool> onChanged) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        value: val,
        onChanged: onChanged,
        title: Text(title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.polishedSilver)),
        activeColor: AppTheme.brushedPlatinum,
        activeTrackColor: AppTheme.brushedPlatinum.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  Widget _buildLogoutBtn() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await AuthService.logout();
          if (mounted)
            Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.brushedPlatinum,
          side: const BorderSide(color: AppTheme.platinumBorder),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        child: const Text('LOGOUT',
            style: TextStyle(
                fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10)),
      ),
    );
  }
}
