import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../services/user_service.dart';

class LoyaltyPointsScreen extends StatefulWidget {
  const LoyaltyPointsScreen({super.key});

  @override
  State<LoyaltyPointsScreen> createState() => _LoyaltyPointsScreenState();
}

class _LoyaltyPointsScreenState extends State<LoyaltyPointsScreen> {
  int points = 0;
  double wallet = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profile = await UserService.getProfile();
      if (mounted) {
        setState(() {
          points = profile['loyaltyPoints'] ?? 0;
          wallet = (profile['wallet'] as num?)?.toDouble() ?? 0.0;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text('REWARDS & WALLET'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.brushedPlatinum,
              backgroundColor: AppTheme.matteBlack,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLoyaltyCard(),
                    const SizedBox(height: 20),
                    _buildWalletCard(),
                    const SizedBox(height: 36),
                    Text('HOW TO EARN POINTS', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
                    const SizedBox(height: 20),
                    ..._buildEarningList(),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(onPressed: () {}, child: const Text('REDEEM POINTS')),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildLoyaltyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.premiumCard(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Member Status', style: TextStyle(color: AppTheme.polishedSilver, fontWeight: FontWeight.w600, letterSpacing: 0.5, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.glassBorder, width: 0.8)),
                child: const Text('PLATINUM', style: TextStyle(color: AppTheme.brushedPlatinum, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('POINTS BALANCE', style: TextStyle(color: AppTheme.coolGrey, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('$points', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w300, letterSpacing: -1)),
          const SizedBox(height: 10),
          Text('Worth approximately ₹${(points * 0.1).toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.98, 0.98), curve: Curves.easeOut);
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCard(radius: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.brushedPlatinum, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WALLET BALANCE', style: TextStyle(color: AppTheme.coolGrey, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text('₹${wallet.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.polishedSilver)),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('TOP UP', style: TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1))),
        ],
      ),
    );
  }

  List<Widget> _buildEarningList() {
    final items = [
      {'icon': Icons.shopping_bag_outlined, 'title': 'Shopping', 'subtitle': 'Earn 1 point for every ₹100 spent'},
      {'icon': Icons.share_outlined, 'title': 'Referrals', 'subtitle': 'Earn 200 points for every friend invited'},
      {'icon': Icons.rate_review_outlined, 'title': 'Reviews', 'subtitle': 'Earn 50 points for reviewing a product'},
    ];
    return items.map((item) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.premiumCard(radius: 24),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                child: Icon(item['icon'] as IconData, color: AppTheme.brushedPlatinum, size: 18)
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.polishedSilver, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(item['subtitle'] as String, style: const TextStyle(color: AppTheme.coolGrey, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    )).toList();
  }
}
