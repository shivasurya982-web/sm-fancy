import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';
import '../config/theme.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  List<AddressModel> addresses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final data = await AddressService.getAddresses();
    if (mounted) setState(() { addresses = data; _isLoading = false; });
  }

  void _showAddressDialog({AddressModel? address, int? index}) {
    final name = TextEditingController(text: address?.name);
    final phone = TextEditingController(text: address?.phone);
    final addr = TextEditingController(text: address?.address);
    final city = TextEditingController(text: address?.city);
    final pin = TextEditingController(text: address?.pincode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.deepCharcoal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppTheme.platinumBorder, width: 0.5)),
        ),
        padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(address == null ? 'ADD NEW ADDRESS' : 'EDIT ADDRESS', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 32),
              _buildField('Full Name', name),
              const SizedBox(height: 16),
              _buildField('Phone Number', phone, keyboard: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField('Address', addr),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('City', city)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Pin Code', pin, keyboard: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (name.text.isEmpty || phone.text.isEmpty || addr.text.isEmpty || city.text.isEmpty || pin.text.isEmpty) return;
                    
                    final updated = AddressModel(
                        name: name.text.trim(), 
                        phone: phone.text.trim(), 
                        address: addr.text.trim(), 
                        city: city.text.trim(), 
                        pincode: pin.text.trim()
                    );

                    setState(() => _isLoading = true);
                    Navigator.pop(ctx);
                    
                    try {
                        await AddressService.saveAddress(updated);
                        await _loadAddresses();
                    } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
                        setState(() => _isLoading = false);
                    }
                  },
                  child: const Text('SAVE ADDRESS'),
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
        title: Text('SAVED ADDRESSES', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 4)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded, color: AppTheme.brushedPlatinum, size: 24), onPressed: () => _showAddressDialog()),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 500 : double.infinity),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
                : addresses.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadAddresses,
                    child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        itemCount: addresses.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (ctx, idx) => _buildAddressCard(addresses[idx], idx),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel a, int idx) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.premiumCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppTheme.brushedPlatinum, size: 18),
              const SizedBox(width: 12),
              Text(a.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5, color: AppTheme.polishedSilver)),
              const Spacer(),
              if (idx == 0) 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.brushedPlatinum.withOpacity(0.05), border: Border.all(color: AppTheme.brushedPlatinum.withOpacity(0.2))),
                  child: const Text('DEFAULT', style: TextStyle(color: AppTheme.brushedPlatinum, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(a.phone, style: const TextStyle(color: AppTheme.coolGrey, fontSize: 11)),
          const Divider(height: 32, color: AppTheme.platinumBorder, thickness: 0.5),
          Text('${a.address}, ${a.city} - ${a.pincode}', style: const TextStyle(height: 1.5, fontSize: 13, color: AppTheme.coolGrey)),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildActionBtn('DELETE', Icons.delete_outline_rounded, () async {
                if (a.id == null) return;
                setState(() => _isLoading = true);
                await AddressService.deleteAddress(a.id!);
                await _loadAddresses();
              }, isError: true),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (idx * 50).ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildActionBtn(String label, IconData icon, VoidCallback onTap, {bool isError = false}) {
    final color = isError ? AppTheme.error.withOpacity(0.7) : AppTheme.brushedPlatinum;
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, floatingLabelBehavior: FloatingLabelBehavior.always),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 60, color: AppTheme.platinumBorder),
          const SizedBox(height: 24),
          Text('NO ADDRESSES SAVED', style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 2)),
          const SizedBox(height: 12),
          const Text('Your delivery destinations will appear here.', style: TextStyle(color: AppTheme.coolGrey)),
        ],
      ),
    );
  }
}
