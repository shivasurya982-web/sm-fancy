import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'screens/home_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/user_chat_redirect.dart';
import 'services/notification_service.dart';
import 'services/cart_service.dart';
import 'services/api_service.dart';
import '../config/theme.dart';
import 'widgets/sparkle_background.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (ApiService.isLoggedIn) {
      NotificationService.fetchMyNotifications();
    }
  }

  final List<Map<String, dynamic>> _navigationItems = [
    {
      'title': 'HOME',
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home_rounded,
      'screen': const HomeScreen(),
      'requiresAuth': false,
    },
    {
      'title': 'WISHLIST',
      'icon': Icons.favorite_border_rounded,
      'activeIcon': Icons.favorite_rounded,
      'screen': const WishlistScreen(),
      'requiresAuth': true,
    },
    {
      'title': 'CART',
      'icon': Icons.shopping_bag_outlined,
      'activeIcon': Icons.shopping_bag_rounded,
      'screen': const CartScreen(),
      'requiresAuth': true,
    },
    {
      'title': 'ORDERS',
      'icon': Icons.receipt_long_outlined,
      'activeIcon': Icons.receipt_long_rounded,
      'screen': const OrdersScreen(),
      'requiresAuth': true,
    },
    {
      'title': 'PROFILE',
      'icon': Icons.person_outline_rounded,
      'activeIcon': Icons.person_rounded,
      'screen': const ProfileScreen(),
      'requiresAuth': true,
    },
  ];

  void _onTabTapped(int index) {
    final item = _navigationItems[index];
    if (item['requiresAuth'] == true && !ApiService.isLoggedIn) {
      _showLoginPrompt();
      return;
    }
    setState(() => currentIndex = index);
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.deepCharcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: const BorderSide(color: AppTheme.platinumBorder)),
        title: Text('LOGIN REQUIRED', style: Theme.of(context).textTheme.labelSmall),
        content: const Text('Please log in to use this feature.', style: TextStyle(color: AppTheme.coolGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DISMISS', style: TextStyle(color: AppTheme.coolGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
            },
            child: const Text('LOGIN'),
          ),
        ],
      ),
    );
  }

  void _showNotificationOverlay() {
    // Mark as read when opening the box
    NotificationService.markAllRead();
    
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black54, // Dim background
      builder: (ctx) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWeb ? 500 : double.infinity, 
            maxHeight: MediaQuery.of(context).size.height * 0.6
          ),
          child: Container(
            margin: const EdgeInsets.all(16), // Floating effect
            decoration: BoxDecoration(
              color: AppTheme.deepCharcoal.withOpacity(0.98),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppTheme.glassBorder, width: 1.2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 30, offset: const Offset(0, -10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('NOTIFICATIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
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
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.notifications_none_rounded, size: 48, color: Colors.white10),
                              const SizedBox(height: 16),
                              Text('NO NEW ALERTS', style: TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final n = notifications[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppTheme.brushedPlatinum.withOpacity(0.1), shape: BoxShape.circle),
                                  child: Icon(
                                    n['type'] == 'order' ? Icons.shopping_bag_outlined : Icons.info_outline_rounded, 
                                    color: AppTheme.brushedPlatinum, 
                                    size: 16
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(n['title']?.toString().toUpperCase() ?? 'ALERT', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                                      const SizedBox(height: 4),
                                      Text(n['body'] ?? '', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
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
    final topBarHeight = MediaQuery.of(context).padding.top + 70;
    
    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      extendBody: true,
      body: LuxurySparkleBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 500 : double.infinity),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IndexedStack(
                    index: currentIndex,
                    children: _navigationItems.map((item) {
                      final int itemIndex = _navigationItems.indexOf(item);
                      return Padding(
                        padding: EdgeInsets.only(
                          top: itemIndex == 0 ? 0 : topBarHeight,
                          bottom: 100,
                        ),
                        child: item['screen'] as Widget,
                      );
                    }).toList(),
                  ),
                ),

                _buildPlatinumTopBar(context),

                if (MediaQuery.of(context).viewInsets.bottom == 0)
                  _buildPlatinumBottomBar(),
              ],
            ),
          ),
        ),
      ),
      drawer: isWeb ? null : _buildPlatinumDrawer(context),
    );
  }

  Widget _buildPlatinumTopBar(BuildContext context) {
    final bool isLoggedIn = ApiService.isLoggedIn;
    
    return Positioned(
      top: 10,
      left: 16,
      right: 16,
      child: SafeArea(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppTheme.glassBorder, width: 0.8),
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.platinumBorder.withOpacity(0.3), width: 1),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo1.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoggedIn ? 'WELCOME BACK,' : 'GUEST',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8, color: AppTheme.coolGrey),
                        ),
                        Text(
                          isLoggedIn ? ApiService.currentUserName.toUpperCase() : 'Explore Shop',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9, color: AppTheme.polishedSilver),
                        ),
                      ],
                    ),
                  ),
                  
                  if (!isLoggedIn) ...[
                    IconButton(
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen())),
                      icon: const Icon(Icons.home_outlined, color: AppTheme.brushedPlatinum, size: 20),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: const Text('LOGIN', style: TextStyle(color: AppTheme.brushedPlatinum, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                  ],
                  
                  IconButton(
                    onPressed: () {
                       if (!ApiService.isLoggedIn) {
                         _showLoginPrompt();
                       } else {
                         _showNotificationOverlay();
                       }
                    },
                    icon: _buildNotificationBell(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatinumBottomBar() {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
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
              children: List.generate(_navigationItems.length, (index) {
                final item = _navigationItems[index];
                final isSelected = currentIndex == index;
                return GestureDetector(
                  onTap: () => _onTabTapped(index),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(8),
                          decoration: isSelected ? BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: AppTheme.sapphireGlow(),
                          ) : null,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                isSelected ? item['activeIcon'] : item['icon'],
                                color: isSelected ? Colors.white : AppTheme.coolGrey,
                                size: 22,
                              ),
                              if (item['title'] == 'CART')
                                ValueListenableBuilder<int>(
                                  valueListenable: CartService.cartCount,
                                  builder: (context, count, _) {
                                    if (count == 0) return const SizedBox.shrink();
                                    return Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.sapphireBlue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$count',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Text(
                            item['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.unreadCount,
      builder: (context, count, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined, color: AppTheme.brushedPlatinum, size: 22),
            if (count > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppTheme.brushedPlatinum, shape: BoxShape.circle),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPlatinumDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.deepCharcoal.withOpacity(0.85),
          border: Border(right: BorderSide(color: AppTheme.glassBorder, width: 0.8)),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/logo1.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(indent: 32, endIndent: 32, color: AppTheme.glassBorder),
                const SizedBox(height: 20),
                
                // Chat Support
                _buildDrawerItem(Icons.chat_bubble_outline_rounded, 'CHAT SUPPORT', () {
                  if (ApiService.isLoggedIn) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UserChatRedirect()));
                  } else {
                    Navigator.pop(context);
                    _showLoginPrompt();
                  }
                }),

                const SizedBox(height: 20),
                const Divider(indent: 32, endIndent: 32, color: AppTheme.glassBorder),
                const SizedBox(height: 20),

                // Bottom Nav Features (Simple English)
                _buildDrawerItem(Icons.explore_outlined, 'HOME', () { Navigator.pop(context); setState(() => currentIndex = 0); }),
                _buildDrawerItem(Icons.favorite_border_rounded, 'WISHLIST', () { Navigator.pop(context); _onTabTapped(1); }),
                _buildDrawerItem(Icons.shopping_bag_outlined, 'CART', () { Navigator.pop(context); _onTabTapped(2); }),
                _buildDrawerItem(Icons.receipt_long_outlined, 'ORDERS', () { Navigator.pop(context); _onTabTapped(3); }),
                _buildDrawerItem(Icons.person_outline_rounded, 'PROFILE', () { Navigator.pop(context); _onTabTapped(4); }),

                const Spacer(),
                
                _buildDrawerItem(Icons.home_outlined, 'WELCOME SCREEN', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()))),
                
                if (ApiService.isLoggedIn)
                  _buildDrawerItem(Icons.logout_rounded, 'LOGOUT', () => ApiService.logout().then((_) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())))),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.brushedPlatinum, size: 20),
        title: Text(title, style: const TextStyle(color: AppTheme.polishedSilver, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      ),
    );
  }
}
