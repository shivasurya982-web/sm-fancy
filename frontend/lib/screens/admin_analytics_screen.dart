import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../config/theme.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/analytics/dashboard');
      if (mounted) setState(() { _data = res; _isLoading = false; });
    } catch (e) {
      debugPrint('Analytics Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load analytics: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(title: const Text('ANALYTICS')),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
            : _data == null
                ? const Center(child: Text('Analytics data unavailable.', style: TextStyle(color: AppTheme.coolGrey)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BUSINESS OVERVIEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.coolGrey)),
                        const SizedBox(height: 24),
                        _buildSummaryGrid(),
                        const SizedBox(height: 32),
                        _buildSalesChart(),
                        const SizedBox(height: 32),
                        _buildCategoryDistribution(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard('TOTAL SALES', '₹${_data!['totalSales']}', Icons.payments_rounded),
        _buildStatCard('CUSTOMERS', '${_data!['totalCustomers']}', Icons.people_rounded),
        _buildStatCard('NEW ORDERS', '${_data!['newOrdersCount']}', Icons.shopping_bag_rounded),
        _buildStatCard('GROWTH', '+${_data!['newCustomersCount']}', Icons.trending_up_rounded),
      ],
    );
  }

  Widget _buildStatCard(String label, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCard(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(icon, color: AppTheme.brushedPlatinum, size: 16)
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.coolGrey, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.polishedSilver)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    final List<dynamic> trends = _data!['salesTrends'] ?? [];
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.premiumCard(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SALES TRENDS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11, color: AppTheme.brushedPlatinum)),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trends.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['sales'] as num).toDouble())).toList(),
                    isCurved: true,
                    color: AppTheme.brushedPlatinum,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppTheme.brushedPlatinum.withOpacity(0.05)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution() {
    final List<dynamic> cats = _data!['topCategories'] ?? [];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.premiumCard(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOP CATEGORIES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11, color: AppTheme.brushedPlatinum)),
          const SizedBox(height: 24),
          ...cats.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(child: Text(c['category'].toString().toUpperCase(), style: const TextStyle(color: AppTheme.coolGrey, fontSize: 11, fontWeight: FontWeight.w500))),
                Text('₹${c['sales']}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.polishedSilver, fontSize: 13)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
