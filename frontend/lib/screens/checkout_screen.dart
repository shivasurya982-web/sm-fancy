import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/payment_service.dart';
import '../config/theme.dart';
import '../widgets/gold_button.dart';
import '../bottom_navigation.dart';
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
  bool _isLoading = false;
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _pinController.dispose();
    super.dispose();
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
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _streetController.text.isEmpty || _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all details")));
      return;
    }
    
    if (_paymentMethod == 'UPI') {
        _startDynamicUPIPayment();
    } else {
        _confirmOrderCOD();
    }
  }

  // --- Dynamic UPI QR Flow ---

  Future<void> _startDynamicUPIPayment() async {
    setState(() => _isLoading = true);
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

      // 1. Create Order on Backend (Returns Dynamic UPI Intent Payload)
      final orderData = await PaymentService.initiateUPIDynamicQR(
          items: cartItemsMap, 
          address: shippingAddress,
          shipping: _currentShippingFee,
      );

      final String upiPayload = orderData['upiPayload'];
      final String orderId = orderData['fancyWorldOrderId'];
      final double amount = (orderData['amount'] as num).toDouble();

      // 2. Show Dynamic QR Dialog
      if (mounted) {
        _showDynamicQRDialog(upiPayload, orderId, amount);
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to initiate payment: $e"), backgroundColor: AppTheme.error));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDynamicQRDialog(String payload, String orderId, double amount) {
      Timer? statusTimer;
      bool isVerifying = false;

      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                  backgroundColor: AppTheme.deepCharcoal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32), side: const BorderSide(color: AppTheme.glassBorder)),
                  title: const Center(child: Text('SCAN TO PAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.polishedSilver, letterSpacing: 2))),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 20),
                          Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                              child: QrImageView(
                                  data: payload,
                                  version: QrVersions.auto,
                                  size: 160,
                                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                              ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Scan using Google Pay, PhonePe, or Paytm', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.coolGrey, fontSize: 11)),
                          const SizedBox(height: 12),
                          if (isVerifying) 
                              const Column(
                                  children: [
                                      SizedBox(height: 8, width: 8, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brushedPlatinum)),
                                      SizedBox(height: 12),
                                      Text('WAITING FOR BANK CONFIRMATION...', style: TextStyle(color: AppTheme.brushedPlatinum, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                  ],
                              ),
                      ],
                    ),
                  ),
                  actions: [
                      TextButton(
                          onPressed: () { 
                              statusTimer?.cancel();
                              Navigator.pop(ctx); 
                              if (mounted) setState(() => _isLoading = false); 
                          },
                          child: const Text('CANCEL', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold))
                      ),
                      ElevatedButton(
                          onPressed: isVerifying ? null : () async {
                              setDialogState(() => isVerifying = true);
                              
                              // Polling mechanism to check real backend status
                              int attempts = 0;
                              statusTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
                                  attempts++;
                                  final res = await PaymentService.checkPaymentStatus(orderId);
                                  if (res['paymentStatus'] == 'Paid') {
                                      timer.cancel();
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      _postOrderSuccess(orderId);
                                  }
                                  if (attempts > 15) { // Timeout after 1 min
                                      timer.cancel();
                                      setDialogState(() => isVerifying = false);
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Auto-verification timed out. If you paid, our team will confirm manually.")));
                                      }
                                  }
                              });
                          },
                          child: const Text('I HAVE PAID')
                      ),
                  ],
              ),
          )
      );
  }

  Future<void> _postOrderSuccess(String orderId) async {
      await CartService.clearCart();
      try {
          final addr = AddressModel(
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              address: _streetController.text.trim(),
              city: _cityController.text.trim(),
              pincode: _pinController.text.trim(),
          );
          await AddressService.saveAddress(addr);
      } catch (_) {}

      if (!mounted) return;
      setState(() => _isLoading = false);
      try {
          final fullOrder = await OrderService.getOrderById(orderId);
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: fullOrder)));
          }
      } catch (e) {
          if (mounted) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const BottomNavigation()), (_) => false);
          }
      }
  }

  // --- COD Logic ---

  Future<void> _confirmOrderCOD() async {
    setState(() => _isLoading = true);
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
        paymentMethod: 'COD',
        items: cartItemsMap,
        subtotal: CartService.cartTotal,
        shipping: _currentShippingFee,
        total: CartService.cartTotal + _currentShippingFee,
      );

      await CartService.clearCart();
      try {
          await AddressService.saveAddress(AddressModel(
              name: shippingAddress['fullName']!,
              phone: shippingAddress['phone']!,
              address: shippingAddress['addressLine1']!,
              city: shippingAddress['city']!,
              pincode: shippingAddress['pincode']!,
          ));
      } catch (_) {}

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order Failed: $e"), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;
    final bool isNarrow = screenWidth < 360;
    final total = CartService.cartTotal + _currentShippingFee;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: Text('CHECKOUT', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 4)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Stack(
            children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWeb ? 500 : double.infinity),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('SHIPPING ADDRESS'),
                          const SizedBox(height: 14),
                          _buildAddressForm(),
                          
                          const SizedBox(height: 32),
                          _buildSectionHeader('PAYMENT METHOD'),
                          const SizedBox(height: 14),
                          _buildPaymentOption('COD', Icons.payments_outlined, 'Pay when you receive'),
                          const SizedBox(height: 12),
                          _buildPaymentOption('UPI', Icons.qr_code_scanner_rounded, 'Secure Dynamic QR Code'),
                          
                          const SizedBox(height: 32),
                          _buildSectionHeader('ORDER SUMMARY'),
                          const SizedBox(height: 14),
                          _buildSummaryCard(total),
                          
                          const SizedBox(height: 40),
                          GoldButton(
                            label: _paymentMethod == 'UPI' ? 'GENERATE PAYMENT QR' : 'PLACE ORDER', 
                            onPressed: _isLoading ? null : _handlePlaceOrder,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
                
                if (_isLoading)
                  Container(
                      color: Colors.black54,
                      child: const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum)),
                  ),
            ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(title, style: Theme.of(context).textTheme.labelSmall);

  Widget _buildAddressForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCard(),
      child: Column(
        children: [
          _buildField('Full Name', _nameController),
          const SizedBox(height: 14),
          _buildField('Phone Number', _phoneController, keyboard: TextInputType.phone),
          const SizedBox(height: 14),
          _buildField('Address', _streetController),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildField('City', _cityController)),
              const SizedBox(width: 14),
              Expanded(child: _buildField('Pin Code', _pinController, keyboard: TextInputType.number)),
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

  Widget _buildPaymentOption(String name, IconData icon, String sub) {
    final isSelected = _paymentMethod == name;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.matteBlack,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.brushedPlatinum : AppTheme.glassBorder, width: isSelected ? 1.2 : 0.8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.brushedPlatinum : AppTheme.coolGrey, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(name, style: TextStyle(color: isSelected ? AppTheme.polishedSilver : AppTheme.coolGrey, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w400, fontSize: 11, letterSpacing: 1)),
                      Text(sub, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w500)),
                  ],
              ),
            ),
            if (isSelected) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.brushedPlatinum, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppTheme.brushedPlatinum, blurRadius: 4)])),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCard(),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', '₹${CartService.cartTotal.toStringAsFixed(0)}'),
          const SizedBox(height: 10),
          _buildSummaryRow('Shipping', '₹${_currentShippingFee.toStringAsFixed(0)}', isPlatinum: true),
          const Divider(height: 28, color: AppTheme.glassBorder, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL AMOUNT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppTheme.coolGrey)),
              Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.polishedSilver)),
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
