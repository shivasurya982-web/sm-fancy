import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/order_item.dart';
import '../services/order_service.dart';
import '../config/theme.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  List<OrderItem> _orders = [];
  bool _isLoading = false;
  String _activeTab = 'Current';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final list = await OrderService.fetchAllOrders();
      if (mounted) setState(() => _orders = list);
    } catch (e) {
      debugPrint('Load Orders Error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load orders: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStatusChange(String orderId, String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await OrderService.updateOrderStatus(orderId, newStatus);
      _loadOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status set to $newStatus"), backgroundColor: AppTheme.success));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<OrderItem> _getFilteredOrders() {
    if (_activeTab == 'Current') return _orders.where((o) => o.status != 'Delivered' && o.status != 'Cancelled').toList();
    return _orders;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredOrders();

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text('MANAGE ORDERS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppTheme.glassBorder)
                ),
                child: Row(
                  children: ['Current', 'History'].map((tab) {
                    final isSelected = _activeTab == tab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = tab),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.brushedPlatinum : Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(tab.toUpperCase(), style: TextStyle(color: isSelected ? Colors.black : AppTheme.coolGrey, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
                  : filtered.isEmpty
                      ? const Center(child: Text('NO ORDERS FOUND', style: TextStyle(color: AppTheme.coolGrey, letterSpacing: 1)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 20),
                          itemBuilder: (ctx, i) => _buildOrderTile(filtered[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTile(OrderItem order) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.premiumCard(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ID: ${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.polishedSilver, fontSize: 11, letterSpacing: 0.5)),
              Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.brushedPlatinum, fontSize: 14)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: AppTheme.glassBorder, height: 1, thickness: 1),
          ),
          Text(order.customerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(order.items.map((e) => e.name).join(', ').toUpperCase(), style: const TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 22),
                  onPressed: () async {
                      final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                              backgroundColor: AppTheme.deepCharcoal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: const BorderSide(color: AppTheme.glassBorder)),
                              title: const Text('DELETE ORDER?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              content: const Text('Remove this order from history?', style: TextStyle(color: AppTheme.coolGrey)),
                              actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL', style: TextStyle(color: AppTheme.coolGrey))),
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), child: const Text('DELETE')),
                              ],
                          ),
                      );
                      if (confirm == true) {
                          await OrderService.deleteOrder(order.orderId);
                          _loadOrders();
                      }
                  },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: DropdownButton<String>(
                  value: order.status,
                  dropdownColor: AppTheme.deepCharcoal,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.brushedPlatinum),
                  style: const TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                  items: ['Placed', 'Processing', 'Packed', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                  onChanged: (v) {
                    if (v != null) _handleStatusChange(order.orderId, v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.98, 0.98), curve: Curves.easeOut);
  }
}
