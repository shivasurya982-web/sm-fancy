import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
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
import 'admin_profile_screen.dart';

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
  void initState() {
    super.initState();
    NotificationService.fetchMyNotifications();
  }

  void _showAdminNotificationOverlay(BuildContext context) {
    NotificationService.markAllRead();
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black54,
      builder: (ctx) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWeb ? 500 : double.infinity, maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.deepCharcoal.withOpacity(0.98),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppTheme.glassBorder, width: 1.2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 30, offset: const Offset(0, -10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
                  child: Row(
                    children: [
                      const Text('ADMIN ALERTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          NotificationService.clearAll();
                        },
                        child: const Text('CLEAR ALL', style: TextStyle(color: AppTheme.coolGrey, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.coolGrey, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.glassBorder, height: 1),
                Expanded(
                  child: ValueListenableBuilder<List<dynamic>>(
                    valueListenable: NotificationService.notificationsNotifier,
                    builder: (context, notifications, _) {
                      if (notifications.isEmpty) {
                        return const Center(child: Text('NO ADMIN ALERTS', style: TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final n = notifications[index];
                          final type = n['type']?.toString() ?? 'system';

                          IconData icon;
                          Color iconColor;
                          Widget targetScreen;

                          switch (type) {
                            case 'order':
                              icon = Icons.local_shipping_outlined;
                              iconColor = AppTheme.brushedPlatinum;
                              targetScreen = const OrderManagementScreen();
                              break;
                            case 'complaint':
                              icon = Icons.report_problem_outlined;
                              iconColor = AppTheme.error;
                              targetScreen = const AdminComplaintsScreen();
                              break;
                            case 'chat':
                              icon = Icons.chat_bubble_outline_rounded;
                              iconColor = Colors.lightBlueAccent;
                              targetScreen = const ChatListScreen();
                              break;
                            case 'stock':
                              icon = Icons.inventory_2_outlined;
                              iconColor = Colors.orangeAccent;
                              targetScreen = const ProductManagementScreen();
                              break;
                            default:
                              icon = Icons.notifications_outlined;
                              iconColor = AppTheme.brushedPlatinum;
                              targetScreen = const ProductManagementScreen();
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                                    child: Icon(icon, color: iconColor, size: 18),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n['title']?.toString().toUpperCase() ?? 'ALERT',
                                                style: TextStyle(color: iconColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              n['createdAt'] != null ? DateFormat('dd/MM • HH:mm').format(DateTime.parse(n['createdAt']).toLocal()) : '',
                                              style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(n['body'] ?? '', style: const TextStyle(color: AppTheme.polishedSilver, fontSize: 11, height: 1.4, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.05, end: 0);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
            Row(
              children: [
                IconButton(
                  onPressed: () => _showAdminNotificationOverlay(context),
                  icon: ValueListenableBuilder<int>(
                    valueListenable: NotificationService.unreadCount,
                    builder: (context, count, _) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.glassBorder),
                            ),
                            child: const Icon(Icons.notifications_outlined, color: AppTheme.brushedPlatinum, size: 20),
                          ),
                          if (count > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.error,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await AuthService.logout();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
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
        _buildAdminTile(context, "Admin Profile", "Update your identity and security", Icons.admin_panel_settings_outlined, const AdminProfileScreen()),
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
