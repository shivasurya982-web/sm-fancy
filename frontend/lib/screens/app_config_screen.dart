import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';

class AppConfigScreen extends StatefulWidget {
  const AppConfigScreen({super.key});

  @override
  State<AppConfigScreen> createState() => _AppConfigScreenState();
}

class _AppConfigScreenState extends State<AppConfigScreen> {
  bool _orderNotify = true;
  bool _promoNotify = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text('SETTINGS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('NOTIFICATIONS'),
              const SizedBox(height: 16),
              Container(
                  decoration: AppTheme.premiumCard(radius: 24),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                      children: [
                        _buildToggle('Order Updates', _orderNotify, (v) => setState(() => _orderNotify = v)),
                        _buildToggle('Promotions', _promoNotify, (v) => setState(() => _promoNotify = v)),
                      ],
                  ),
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('PERMISSIONS'),
              const SizedBox(height: 16),
              _buildMenuCard([
                  _buildMenuTile(Icons.location_on_outlined, 'Location Access', () => openAppSettings()),
                  _buildMenuTile(Icons.camera_alt_outlined, 'Camera Access', () => openAppSettings()),
              ]),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
    );
  }

  Widget _buildToggle(String label, bool val, ValueChanged<bool> onChanged) {
      return Material(
          color: Colors.transparent,
          child: SwitchListTile(
              value: val,
              onChanged: onChanged,
              title: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.polishedSilver, fontWeight: FontWeight.w500)),
              activeColor: AppTheme.brushedPlatinum,
              activeTrackColor: AppTheme.brushedPlatinum.withOpacity(0.2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          ),
      );
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            leading: Icon(icon, color: AppTheme.brushedPlatinum, size: 20),
            title: Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.polishedSilver, fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
      );
  }
}
