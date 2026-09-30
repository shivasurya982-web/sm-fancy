import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../config/theme.dart';
import '../widgets/gold_button.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String _selectedPeriod = '30days';

  final Map<String, String> _periods = {
    'today': 'Today',
    'yesterday': 'Yesterday',
    '7days': 'Last 7 Days',
    '30days': 'Last 30 Days',
    'thisMonth': 'This Month',
    'lastMonth': 'Last Month',
    'thisYear': 'This Year',
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/analytics/dashboard?period=$_selectedPeriod');
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Analytics Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load analytics: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;
    final bool isNarrow = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text('BUSINESS ANALYTICS'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchData),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
            : _data == null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    color: AppTheme.brushedPlatinum,
                    backgroundColor: AppTheme.matteBlack,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, 0, isNarrow ? 16 : 24, 100),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isWeb ? 800 : double.infinity),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPeriodFilter(),
                              const SizedBox(height: 20),
                              _buildHealthSummary(),
                              const SizedBox(height: 24),
                              _buildKPIGrid(),
                              const SizedBox(height: 24),
                              _buildInsightsSection(),
                              const SizedBox(height: 24),
                              _buildSalesTrend(),
                              const SizedBox(height: 24),
                              _buildTopProducts(),
                              const SizedBox(height: 24),
                              _buildCategoryPerformance(),
                              const SizedBox(height: 24),
                              _buildAttentionSection(),
                              const SizedBox(height: 24),
                              _buildFeedbackSection(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periods.entries.map((e) {
          final isSelected = _selectedPeriod == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500, letterSpacing: 0.5)),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedPeriod = e.key);
                  _fetchData();
                }
              },
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: AppTheme.brushedPlatinum,
              labelStyle: TextStyle(color: isSelected ? Colors.black : AppTheme.coolGrey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100), side: BorderSide(color: isSelected ? AppTheme.brushedPlatinum : AppTheme.glassBorder, width: 0.5)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHealthSummary() {
    final insights = _data!['insights'] as List? ?? [];
    final bool isBad = insights.any((i) => i['type'] == 'bad' || i['type'] == 'problem');
    final bool isGood = insights.any((i) => i['type'] == 'good');

    String title = 'BUSINESS IS STEADY';
    Color color = AppTheme.brushedPlatinum;
    IconData icon = Icons.info_outline_rounded;

    if (isBad) {
        title = 'NEEDS ATTENTION';
        color = AppTheme.error;
        icon = Icons.warning_amber_rounded;
    } else if (isGood) {
        title = 'BUSINESS IS GROWING';
        color = AppTheme.success;
        icon = Icons.trending_up_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCard(radius: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                const SizedBox(height: 4),
                const Text('Based on measurable trends this period.', style: TextStyle(color: AppTheme.coolGrey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildKPIGrid() {
    final over = _data!['overview'] ?? {};
    final double screenWidth = MediaQuery.of(context).size.width;

    return GridView.count(
      crossAxisCount: screenWidth > 600 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: screenWidth < 360 ? 1.0 : 1.1,
      children: [
        _buildKPICard('REVENUE', over['sales'], '₹', Icons.payments_outlined),
        _buildKPICard('ORDERS', over['orders'], '', Icons.shopping_bag_outlined),
        _buildKPICard('NEW USERS', over['customers'], '', Icons.person_add_outlined, useNewKey: true),
        _buildKPICard('AVG ORDER', over['aov'], '₹', Icons.receipt_long_outlined),
      ],
    );
  }

  Widget _buildKPICard(String label, dynamic stats, String prefix, IconData icon, {bool useNewKey = false}) {
    final dynamic current = useNewKey ? stats['new'] : stats['current'];
    final dynamic previous = useNewKey ? stats['prevNew'] : stats['previous'];
    
    double change = 0;
    if (previous != null && previous != 0) {
        change = ((current - previous) / previous) * 100;
    }

    final isPositive = change >= 0;
    final color = isPositive ? AppTheme.success : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.premiumCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Icon(icon, color: AppTheme.coolGrey, size: 16),
                if (previous != null && previous != 0)
                    Text(
                        '${isPositive ? '↑' : '↓'} ${change.abs().toStringAsFixed(0)}%',
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.coolGrey, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 4),
              FittedBox(child: Text('$prefix${current.round()}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    final insights = _data!['insights'] as List? ?? [];
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BUSINESS INSIGHTS', style: TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        ...insights.map((i) => _buildInsightTile(i)),
      ],
    );
  }

  Widget _buildInsightTile(dynamic i) {
    Color color = AppTheme.brushedPlatinum;
    IconData icon = Icons.info_outline_rounded;
    
    switch (i['type']) {
        case 'good': color = AppTheme.success; icon = Icons.check_circle_outline_rounded; break;
        case 'bad': 
        case 'problem': color = AppTheme.error; icon = Icons.error_outline_rounded; break;
        case 'attention': color = Colors.orangeAccent; icon = Icons.priority_high_rounded; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i['title']?.toString().toUpperCase() ?? 'INSIGHT', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(i['text'] ?? '', style: const TextStyle(color: AppTheme.polishedSilver, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTrend() {
    final List<dynamic> trend = _data!['salesTrend'] ?? [];
    if (trend.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCard(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SALES TREND', style: TextStyle(color: AppTheme.polishedSilver, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['sales'] as num).toDouble())).toList(),
                    isCurved: true,
                    color: AppTheme.brushedPlatinum,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppTheme.brushedPlatinum.withValues(alpha: 0.05)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Your sales trajectory for the selected period.', style: TextStyle(color: AppTheme.coolGrey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    final List<dynamic> products = _data!['topProductsUnits'] ?? [];
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🏆 TOP 5 SELLING PRODUCTS', style: TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        ...products.asMap().entries.map((e) => _buildProductRankTile(e.value, e.key + 1)),
      ],
    );
  }

  Widget _buildProductRankTile(dynamic p, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.premiumCard(radius: 20),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: rank <= 3 ? AppTheme.brushedPlatinum : Colors.white10, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$rank', style: TextStyle(color: rank <= 3 ? Colors.black : Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.glassBorder)),
            child: ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: p['image'] ?? '', fit: BoxFit.cover, errorWidget: (_,__,___) => const Icon(Icons.diamond_outlined, size: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name']?.toString().toUpperCase() ?? 'PRODUCT', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text('₹${(p['revenue'] as num).round()} Revenue', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
                Text('${p['sold']} SOLD', style: const TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 11)),
                Text('${p['stock']} IN STOCK', style: TextStyle(color: (p['stock'] as num) < 10 ? AppTheme.error : AppTheme.success, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformance() {
    final List<dynamic> cats = _data!['categoryPerformance'] ?? [];
    if (cats.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCard(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CATEGORY PERFORMANCE', style: TextStyle(color: AppTheme.polishedSilver, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 20),
          ...cats.map((c) {
              final double progress = (c['sales'] as num) / (cats[0]['sales'] as num);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(c['_id']?.toString().toUpperCase() ?? 'OTHER', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('₹${(c['sales'] as num).round()}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: const AlwaysStoppedAnimation(AppTheme.brushedPlatinum),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              );
          }),
        ],
      ),
    );
  }

  Widget _buildAttentionSection() {
    final List<dynamic> attention = _data!['attentionProducts'] ?? [];
    if (attention.isEmpty) return const SizedBox.shrink();

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const Text('📦 PRODUCTS NEEDING ATTENTION', style: TextStyle(color: AppTheme.error, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            ...attention.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.error.withValues(alpha: 0.2))),
                child: Row(
                    children: [
                        const Icon(Icons.inventory_2_outlined, color: AppTheme.error, size: 18),
                        const SizedBox(width: 14),
                        Expanded(child: Text(p['name']?.toString().toUpperCase() ?? 'PRODUCT', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11))),
                        Text(p['stock'] == 0 ? 'OUT OF STOCK' : '${p['stock']} REMAINING', style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 10)),
                    ],
                ),
            )),
        ],
    );
  }

  Widget _buildFeedbackSection() {
    final rating = _data!['ratingData'] ?? {};
    final double avg = (rating['avgRating'] as num?)?.toDouble() ?? 0;
    
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.premiumCard(radius: 24),
        child: Row(
            children: [
                Expanded(
                    flex: 1,
                    child: Column(
                        children: [
                            Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.brushedPlatinum)),
                            const SizedBox(height: 4),
                            const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Icon(Icons.star_rounded, color: Colors.amber, size: 12), Icon(Icons.star_rounded, color: Colors.amber, size: 12), Icon(Icons.star_rounded, color: Colors.amber, size: 12), Icon(Icons.star_rounded, color: Colors.amber, size: 12), Icon(Icons.star_half_rounded, color: Colors.amber, size: 12)],
                            ),
                            const SizedBox(height: 4),
                            Text('${rating['totalReviews']} REVIEWS', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 8, fontWeight: FontWeight.bold)),
                        ],
                    ),
                ),
                Container(width: 1, height: 50, color: AppTheme.glassBorder, margin: const EdgeInsets.symmetric(horizontal: 16)),
                Expanded(
                    flex: 2,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            const Text('CUSTOMER FEEDBACK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Text(avg >= 4 ? 'Generally positive sentiment.' : 'Requires review focus.', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 10)),
                        ],
                    ),
                ),
            ],
        ),
    );
  }

  Widget _buildErrorState() {
      return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  const Icon(Icons.analytics_outlined, size: 64, color: Colors.white10),
                  const SizedBox(height: 24),
                  const Text('ANALYTICS UNAVAILABLE', style: TextStyle(color: AppTheme.coolGrey, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 32),
                  GoldButton(width: 200, label: 'RETRY', onPressed: _fetchData),
              ],
          ),
      );
  }
}
