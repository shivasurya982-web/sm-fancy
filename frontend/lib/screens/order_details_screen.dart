import 'package:flutter/material.dart';
import '../models/order_item.dart';
import '../config/theme.dart';
import '../services/product_service.dart';
import 'product_details_screen.dart';
import '../services/return_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderItem order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isNavigating = false;

  Future<void> _navigateToProduct(BuildContext context, String productId) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    try {
      final product = await ProductService.getProductById(productId);
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load product details: $e')));
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  void _showReturnDialog() {
      final reasonCtrl = TextEditingController();
      final descCtrl = TextEditingController();
      bool loading = false;
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => StatefulBuilder(
              builder: (ctx, setDialogState) => Container(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
                  decoration: const BoxDecoration(color: AppTheme.deepCharcoal, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text('RETURN REQUEST', style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 24),
                          TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'REASON')),
                          const SizedBox(height: 16),
                          TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'DETAILS')),
                          const SizedBox(height: 32),
                          SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                  onPressed: loading ? null : () async {
                                      if (reasonCtrl.text.isEmpty) return;
                                      setDialogState(() => loading = true);
                                      try {
                                          await ReturnService.requestReturn(orderId: widget.order.orderId, reason: reasonCtrl.text, description: descCtrl.text);
                                          if (mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return requested'), backgroundColor: AppTheme.success)); Navigator.pop(context); }
                                      } catch (_) {}
                                      finally { if (mounted) setDialogState(() => loading = false); }
                                  },
                                  child: loading ? const CircularProgressIndicator() : const Text('SUBMIT REQUEST'),
                              ),
                          ),
                      ],
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
      appBar: AppBar(
        title: const Text('ORDER DETAILS'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 500 : double.infinity),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 32),
                      _buildSectionHeader('ITEMS'),
                      const SizedBox(height: 16),
                      ...widget.order.items.map((item) => _buildItemTile(context, item)),
                      const SizedBox(height: 32),
                      _buildSectionHeader('SHIPPING ADDRESS'),
                      const SizedBox(height: 16),
                      _buildAddressCard(),
                      if (widget.order.status == 'Delivered') ...[
                          const SizedBox(height: 48),
                          SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.error, 
                                      side: BorderSide(color: AppTheme.error.withOpacity(0.2)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))
                                  ),
                                  onPressed: _showReturnDialog,
                                  icon: const Icon(Icons.assignment_return_outlined, size: 18),
                                  label: const Text('RETURN ORDER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 10)),
                              ),
                          ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                if (_isNavigating) const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(title, style: Theme.of(context).textTheme.labelSmall);

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.premiumCard(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ORDER SUMMARY', style: TextStyle(color: AppTheme.polishedSilver, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
              _buildStatusBadge(widget.order.status),
            ],
          ),
          const Divider(height: 40, color: AppTheme.platinumBorder, thickness: 0.5),
          _buildPriceRow('Items Total', '₹${widget.order.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _buildPriceRow('Shipping Fee', '₹${widget.order.shipping.toStringAsFixed(0)}', isPlatinum: true),
          const Divider(height: 40, color: AppTheme.platinumBorder, thickness: 0.5),
          _buildPriceRow('TOTAL AMOUNT', '₹${widget.order.total.toStringAsFixed(0)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, OrderItemProduct item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.premiumCard(),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () => _navigateToProduct(context, item.productId),
          title: Text(item.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5, color: AppTheme.polishedSilver)),
          subtitle: Text('QTY: ${item.quantity}', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.w600)),
          trailing: Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    final addr = widget.order.shippingAddress;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.premiumCard(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: AppTheme.brushedPlatinum, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addr['name']?.toString().toUpperCase() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.polishedSilver)),
                const SizedBox(height: 4),
                Text(addr['phone'] ?? '', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 11)),
                const SizedBox(height: 12),
                Text('${addr['street']}, ${addr['city']}', style: const TextStyle(color: AppTheme.coolGrey, height: 1.4, fontSize: 12)),
                Text('${addr['state']} - ${addr['zipCode']}', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String val, {bool isTotal = false, bool isPlatinum = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isTotal ? AppTheme.polishedSilver : AppTheme.coolGrey, fontWeight: isTotal ? FontWeight.w900 : FontWeight.normal, fontSize: isTotal ? 12 : 11)),
        Text(val, style: TextStyle(color: (isTotal || isPlatinum) ? AppTheme.brushedPlatinum : AppTheme.polishedSilver, fontWeight: FontWeight.w900, fontSize: isTotal ? 20 : 13)),
      ],
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
        borderRadius: BorderRadius.circular(100), // Capsule/Curved Corners
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Text(
        status.toUpperCase(), 
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)
      ),
    );
  }
}
