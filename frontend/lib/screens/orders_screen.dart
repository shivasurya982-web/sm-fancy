import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/order_service.dart';
import '../models/order_item.dart';
import '../config/theme.dart';
import '../widgets/glass_toast.dart';
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
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (mounted) setState(() => _isLoading = true);
    await OrderService.fetchMyOrders();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleDeleteOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.deepCharcoal,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppTheme.platinumBorder)),
        title: const Text('REMOVE ORDER HISTORY?',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1, color: Colors.white)),
        content: const Text('Are you sure you want to remove this order from your history?',
            style: TextStyle(color: AppTheme.coolGrey, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.coolGrey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await OrderService.deleteOrder(orderId);
        await _loadOrders();
        if (mounted) {
          showGlassToast(context, 'Order removed from history.', isError: false, title: 'ORDER REMOVED');
        }
      } catch (e) {
        if (mounted) {
          showGlassToast(context, 'Failed to remove order: $e', isError: true);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;
    final bool isNarrow = screenWidth < 360;
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
                    padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, 0, isNarrow ? 16 : 24, 12),
                    child: Text(
                      'ORDERS',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        letterSpacing: 2,
                        fontSize: isNarrow ? 24 : 28,
                      ),
                    ),
                  ),
                ),

                _isLoading
                    ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum)))
                    : orders.isEmpty
                        ? SliverFillRemaining(child: _buildEmptyState())
                        : SliverPadding(
                            padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, 0, isNarrow ? 16 : 24, 120),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildOrderCard(orders[index], index, isNarrow),
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

  Widget _buildOrderCard(OrderItem order, int index, bool isNarrow) {
    final bool canDelete = order.status == 'Delivered' || order.status == 'Cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AppTheme.premiumCard(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, 16, isNarrow ? 16 : 24, 12),
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
                Row(
                  children: [
                    _buildStatusBadge(order.status),
                    if (canDelete) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _handleDeleteOrder(order.orderId),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.error.withValues(alpha: 0.3), width: 0.5),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, size: 14, color: AppTheme.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(isNarrow ? 16 : 24),
            child: Column(
              children: [
                if (order.items.isNotEmpty)
                  Row(
                    children: [
                      Container(
                        width: isNarrow ? 60 : 70,
                        height: isNarrow ? 60 : 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.glassBorder, width: 0.8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildOrderImage(order.items[0].image),
                        ),
                      ),
                      SizedBox(width: isNarrow ? 12 : 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.items[0].name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w900, 
                                fontSize: isNarrow ? 11 : 12, 
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
                
                SizedBox(height: isNarrow ? 20 : 28),
                
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order))),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppTheme.platinumBorder.withValues(alpha: 0.3), width: 1),
                          ),
                          alignment: Alignment.center,
                          child: const Text('DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.polishedSilver, letterSpacing: 1.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08), 
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
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
          const SizedBox(height: 36),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const BottomNavigation()), (route) => false);
            },
            child: const Text('GO TO SHOP', style: TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }
}
