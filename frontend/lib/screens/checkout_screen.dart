import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/address_service.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../config/theme.dart';
import '../widgets/gold_button.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _pinController = TextEditingController();

  String _paymentMethod = 'COD';
  bool _isPlacingOrder = false;
  String? _upiQrUrl;
  String _localCity = 'Tiruchendur';
  double _localFee = 50.0;
  double _standardFee = 100.0;

  @override
  void initState() {
    super.initState();
    _nameController.text = ApiService.currentUserName;
    _loadSettings();
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    final addresses = await AddressService.getAddresses();
    if (addresses.isNotEmpty && mounted) {
      final a = addresses.last;
      setState(() {
        _nameController.text = a.name;
        _phoneController.text = a.phone;
        _streetController.text = a.address;
        _cityController.text = a.city;
        _pinController.text = a.pincode;
      });
    }
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.getSettings();
    if (mounted) {
      setState(() {
        _upiQrUrl = settings['upiQrCode'];
        _localCity = settings['localCity'] ?? 'Tiruchendur';
        _localFee = (settings['localShippingFee'] as num?)?.toDouble() ?? 50.0;
        _standardFee = (settings['standardShippingFee'] as num?)?.toDouble() ?? 100.0;
      });
    }
  }

  double get _currentShippingFee {
    final city = _cityController.text.trim().toLowerCase();
    if (city == _localCity.toLowerCase()) return _localFee;
    return _standardFee;
  }

  Future<void> _handlePlaceOrder() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _streetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all details")));
      return;
    }
    if (_paymentMethod == 'UPI') _showUPIDialog();
    else _confirmOrder();
  }

  void _showUPIDialog() {
    final total = CartService.cartTotal + _currentShippingFee;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: AppTheme.matteBlack,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: AppTheme.platinumBorder, width: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PAYMENT', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 24),
            Text('₹${total.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.polishedSilver)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.platinumBorder)),
              child: _upiQrUrl != null ? CachedNetworkImage(imageUrl: _upiQrUrl!, width: 200, height: 200) : const Icon(Icons.qr_code_scanner_rounded, size: 180, color: Colors.black),
            ),
            const SizedBox(height: 40),
            GoldButton(label: 'CONFIRM PAYMENT', onPressed: () { Navigator.pop(context); _confirmOrder(); }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmOrder() async {
    setState(() => _isPlacingOrder = true);
    try {
      final shippingAddress = {
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'addressLine1': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state': 'Tamil Nadu',
        'pincode': _pinController.text.trim(),
      };
      final cartItemsMap = CartService.cartItems.map((item) => {
        'product': item.productId,
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'image': item.image,
      }).toList();

      final order = await OrderService.placeOrder(
        shippingAddress: shippingAddress,
        paymentMethod: _paymentMethod,
        items: cartItemsMap,
        subtotal: CartService.cartTotal,
        shipping: _currentShippingFee,
        total: CartService.cartTotal + _currentShippingFee,
      );

      await CartService.clearCart();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order Failed: $e"), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;
    final total = CartService.cartTotal + _currentShippingFee;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: Text('CHECKOUT', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 4)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 500 : double.infinity),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('SHIPPING ADDRESS'),
                  const SizedBox(height: 16),
                  _buildAddressForm(),
                  
                  const SizedBox(height: 40),
                  _buildSectionHeader('PAYMENT METHOD'),
                  const SizedBox(height: 16),
                  _buildPaymentOption('COD', Icons.payments_outlined),
                  const SizedBox(height: 12),
                  _buildPaymentOption('UPI', Icons.qr_code_rounded),

                  const SizedBox(height: 40),
                  _buildSectionHeader('ORDER SUMMARY'),
                  const SizedBox(height: 16),
                  _buildSummaryCard(total),
                  
                  const SizedBox(height: 48),
                  GoldButton(
                    label: 'PLACE ORDER', 
                    onPressed: _isPlacingOrder ? null : _handlePlaceOrder,
                    isLoading: _isPlacingOrder,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(title, style: Theme.of(context).textTheme.labelSmall);

  Widget _buildAddressForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.premiumCard(),
      child: Column(
        children: [
          _buildField('Full Name', _nameController),
          const SizedBox(height: 16),
          _buildField('Phone Number', _phoneController, keyboard: TextInputType.phone),
          const SizedBox(height: 16),
          _buildField('Address', _streetController),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildField('City', _cityController)),
              const SizedBox(width: 16),
              Expanded(child: _buildField('Zip Code', _pinController, keyboard: TextInputType.number)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.polishedSilver),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w400, color: AppTheme.coolGrey),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }

  Widget _buildPaymentOption(String name, IconData icon) {
    final isSelected = _paymentMethod == name;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.matteBlack,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.brushedPlatinum : AppTheme.glassBorder, width: isSelected ? 1.2 : 0.8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.brushedPlatinum : AppTheme.coolGrey, size: 20),
            const SizedBox(width: 16),
            Text(name, style: TextStyle(color: isSelected ? AppTheme.polishedSilver : AppTheme.coolGrey, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w400, fontSize: 11, letterSpacing: 1)),
            const Spacer(),
            if (isSelected) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.sapphireBlue, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppTheme.sapphireBlue, blurRadius: 4)])),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.premiumCard(),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', '₹${CartService.cartTotal.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _buildSummaryRow('Shipping', '₹${_currentShippingFee.toStringAsFixed(0)}', isPlatinum: true),
          const Divider(height: 32, color: AppTheme.glassBorder, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL AMOUNT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppTheme.coolGrey)),
              Text('₹${total.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.polishedSilver)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String val, {bool isPlatinum = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.coolGrey, fontSize: 12)),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: isPlatinum ? AppTheme.brushedPlatinum : AppTheme.polishedSilver, fontSize: 13)),
      ],
    );
  }
}
