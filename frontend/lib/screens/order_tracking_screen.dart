import 'package:flutter/material.dart';
import '../models/order_item.dart';
import '../services/order_service.dart';
import '../config/theme.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderItem order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late OrderItem _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _refreshOrder();
  }

  Future<void> _refreshOrder() async {
    try {
      final orders = await OrderService.fetchMyOrders();
      if (!mounted) return;
      final updated = orders.firstWhere((o) => o.orderId == _order.orderId, orElse: () => _order);
      setState(() => _order = updated);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;
    final bool isNarrow = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text('TRACK ORDER'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 500 : double.infinity),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('ORDER PROGRESS'),
                  const SizedBox(height: 32),
                  _buildTimeline(),
                  const SizedBox(height: 48),
                  _buildSectionHeader('SHIPPING ADDRESS'),
                  const SizedBox(height: 16),
                  _buildAddressCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(title, style: Theme.of(context).textTheme.labelSmall);

  Widget _buildTimeline() {
    final statusList = ['Placed', 'Packed', 'Shipped', 'Out for Delivery', 'Delivered'];
    final currentStatusIdx = statusList.indexOf(_order.status);

    return Column(
      children: statusList.asMap().entries.map((e) {
        final idx = e.key;
        final status = e.value;
        final isComp = idx <= currentStatusIdx;
        final isLast = idx == statusList.length - 1;

        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isComp ? AppTheme.brushedPlatinum : Colors.transparent,
                      border: Border.all(color: isComp ? AppTheme.brushedPlatinum : AppTheme.platinumBorder, width: 1),
                    ),
                    child: isComp ? const Icon(Icons.check, size: 12, color: AppTheme.matteBlack) : null,
                  ),
                  if (!isLast)
                    Expanded(child: Container(width: 1, color: isComp ? AppTheme.brushedPlatinum : AppTheme.platinumBorder)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status.toUpperCase(), style: TextStyle(color: isComp ? AppTheme.polishedSilver : AppTheme.coolGrey, fontWeight: isComp ? FontWeight.w900 : FontWeight.w400, fontSize: 12, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(isComp ? 'COMPLETED' : 'PENDING', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 9, letterSpacing: 0.5)),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddressCard() {
    final addr = _order.shippingAddress;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCard(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: AppTheme.brushedPlatinum, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addr['name']?.toString().toUpperCase() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.polishedSilver)),
                const SizedBox(height: 6),
                Text('${addr['street']}, ${addr['city']}, ${addr['state']} - ${addr['pincode']}', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
