import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/order_service.dart';
import '../models/order_item.dart';
import '../config/theme.dart';
import '../bottom_navigation.dart';
import 'order_tracking_screen.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (OrderService.orders.isEmpty) _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (mounted && OrderService.orders.isEmpty) setState(() => _isLoading = true);
    await OrderService.fetchMyOrders();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;
    final List<OrderItem> orders = OrderService.orders;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        color: AppTheme.brushedPlatinum,
        backgroundColor: AppTheme.matteBlack,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 500 : double.infinity),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Text(
                      'ORDERS',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        letterSpacing: 2,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),

                _isLoading
                    ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum)))
                    : orders.isEmpty
                        ? SliverFillRemaining(child: _buildEmptyState())
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildOrderCard(orders[index], index),
                                childCount: orders.length,
                              ),
                            ),
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderItem order, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: AppTheme.premiumCard(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ORDER STATUS',
                  style: TextStyle(
                    color: AppTheme.coolGrey,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (order.items.isNotEmpty)
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.glassBorder, width: 0.8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildOrderImage(order.items[0].image),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.items[0].name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900, 
                                fontSize: 12, 
                                letterSpacing: 0.5,
                                color: AppTheme.polishedSilver,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${order.items.length} ITEMS  •  ₹${order.total.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order))),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppTheme.platinumBorder.withOpacity(0.3), width: 1),
                          ),
                          alignment: Alignment.center,
                          child: const Text('DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.polishedSilver, letterSpacing: 1.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order))),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: AppTheme.brushedPlatinum,
                          ),
                          alignment: Alignment.center,
                          child: const Text('TRACK ORDER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index % 10 * 50).ms).scale(begin: const Offset(0.98, 0.98), curve: Curves.easeOut);
  }

  Widget _buildOrderImage(String url) {
    if (url.isEmpty || url.contains('aura_perfume.jpg')) {
      return const Icon(Icons.shopping_bag_outlined, color: Colors.white10, size: 24);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) => const Icon(Icons.diamond_outlined, color: Colors.white10),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Delivered': color = AppTheme.success; break;
      case 'Cancelled': color = AppTheme.error; break;
      default: color = AppTheme.brushedPlatinum;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), 
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Text(
        status.toUpperCase(), 
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 60, color: Colors.white10),
          const SizedBox(height: 24),
          const Text('NO ORDERS PLACED', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14, color: AppTheme.polishedSilver)),
          const SizedBox(height: 12),
          const Text('Your orders will appear here.', style: TextStyle(color: AppTheme.coolGrey, fontSize: 12)),
          const SizedBox(height: 48),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => BottomNavigation()), (route) => false);
            },
            child: const Text('GO TO SHOP', style: TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}
