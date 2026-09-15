import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';
import 'login_screen.dart';
import 'product_management_screen.dart';
import 'order_management_screen.dart';
import 'customer_database_screen.dart';
import 'notifications_management_screen.dart';
import 'splash_config_screen.dart';
import 'chat_list_screen.dart';
import 'admin_complaints_screen.dart';
import 'category_management_screen.dart';
import 'admin_analytics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIdx = 0;

  final List<Widget> _pages = [
    const AppManagementSection(),
    const CustomerDatabaseScreen(),
    const SupportHubSection(),
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.filigreeBackground(),
        child: Stack(
          children: [
            // Main Content Area
            Positioned.fill(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWeb ? 600 : double.infinity),
                  child: Column(
                    children: [
                      _buildCustomHeader(),
                      Expanded(
                        child: IndexedStack(
                          index: _currentIdx,
                          children: _pages,
                        ),
                      ),
                      const SizedBox(height: 100), // Space for floating bar
                    ],
                  ),
                ),
              ),
            ),

            // Floating Navigation Bar
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWeb ? 500 : screenWidth - 48),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppTheme.glassBorder, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(0, Icons.dashboard_customize_outlined, Icons.dashboard_customize_rounded, 'MGMT'),
                            _buildNavItem(1, Icons.people_outline_rounded, Icons.people_rounded, 'USERS'),
                            _buildNavItem(2, Icons.headset_mic_outlined, Icons.headset_mic_rounded, 'SUPPORT'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIdx == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIdx = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppTheme.brushedPlatinum : AppTheme.coolGrey,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.brushedPlatinum : AppTheme.coolGrey,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ADMIN PANEL',
                  style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                const SizedBox(height: 6),
                Text(
                  _currentIdx == 0
                      ? 'DASHBOARD'
                      : _currentIdx == 1
                      ? 'CUSTOMERS'
                      : 'SUPPORT',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.polishedSilver,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () async {
                await AuthService.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle, border: Border.all(color: AppTheme.glassBorder)),
                child: const Icon(Icons.logout_rounded, color: AppTheme.brushedPlatinum, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppManagementSection extends StatelessWidget {
  const AppManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildAdminTile(context, "Products", "Manage inventory and pricing", Icons.inventory_2_outlined, const ProductManagementScreen()),
        _buildAdminTile(context, "Categories", "Manage product categories", Icons.category_outlined, const CategoryManagementScreen()),
        _buildAdminTile(context, "Analytics", "View sales and trends", Icons.analytics_outlined, const AdminAnalyticsScreen()),
        _buildAdminTile(context, "Orders", "Manage customer orders", Icons.local_shipping_outlined, const OrderManagementScreen()),
        _buildAdminTile(context, "App Settings", "Configure splash and banners", Icons.settings_outlined, const SplashConfigScreen()),
        _buildAdminTile(context, "Notifications", "Send global announcements", Icons.campaign_outlined, const NotificationsManagementScreen()),
      ],
    );
  }
}

class CustomerRegistrySection extends StatelessWidget {
  const CustomerRegistrySection({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomerDatabaseScreen();
  }
}

class SupportHubSection extends StatelessWidget {
  const SupportHubSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildAdminTile(context, "Chat Threads", "Respond to customer messages", Icons.chat_bubble_outline_rounded, const ChatListScreen()),
        _buildAdminTile(context, "Complaints", "Resolve customer issues", Icons.report_problem_outlined, const AdminComplaintsScreen()),
      ],
    );
  }
}

Widget _buildAdminTile(BuildContext context, String title, String sub, IconData icon, Widget target) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: AppTheme.premiumCard(radius: 24),
    child: Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.brushedPlatinum, size: 20),
        ),
        title: Text(
          title.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1, color: AppTheme.polishedSilver),
        ),
        subtitle: Text(sub, style: const TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white10),
      ),
    ),
  );
}
