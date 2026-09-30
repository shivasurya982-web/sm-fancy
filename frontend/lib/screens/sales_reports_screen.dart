import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../config/theme.dart';

class SalesReportsScreen extends StatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  State<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends State<SalesReportsScreen> {
  bool isLoading = false;
  List<dynamic> salesTrends = [];
  List<dynamic> topCategories = [];
  List<dynamic> paymentMethods = [];

  @override
  void initState() {
    super.initState();
    loadReportsData();
  }

  Future<void> loadReportsData() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get('/analytics/dashboard');
      if (response != null && mounted) {
        setState(() {
          salesTrends = response['salesTrends'] as List? ?? [];
          topCategories = response['topCategories'] as List? ?? [];
          paymentMethods = response['paymentMethods'] as List? ?? [];
        });
      }
    } catch (_) {}
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    final colors = [
      AppTheme.brushedPlatinum,
      AppTheme.sapphireBlue,
      AppTheme.coolGrey,
      Colors.white24,
    ];

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text("SALES REPORTS"),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
            : RefreshIndicator(
                onRefresh: loadReportsData,
                color: AppTheme.brushedPlatinum,
                backgroundColor: AppTheme.matteBlack,
                child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("SALES TRENDS"),
                        _buildChartContainer(
                          salesTrends.isEmpty
                            ? const Center(child: Text("No data found.", style: TextStyle(color: AppTheme.coolGrey)))
                            : LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: const FlTitlesData(show: false),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: List.generate(salesTrends.length, (index) => FlSpot(index.toDouble(), (salesTrends[index]['sales'] as num).toDouble())),
                                      isCurved: true,
                                      color: AppTheme.brushedPlatinum,
                                      barWidth: 2,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(show: true, color: AppTheme.brushedPlatinum.withValues(alpha: 0.05)),
                                    ),
                                  ],
                                ),
                              ),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader("TOP CATEGORIES"),
                        _buildChartContainer(
                          Row(
                            children: [
                              Expanded(
                                child: topCategories.isEmpty
                                    ? const Center(child: Text("No data", style: TextStyle(color: AppTheme.coolGrey)))
                                    : PieChart(
                                        PieChartData(
                                          sectionsSpace: 2,
                                          centerSpaceRadius: 30,
                                          sections: List.generate(topCategories.length, (index) {
                                            final val = (topCategories[index]['percentage'] as num).toDouble();
                                            return PieChartSectionData(color: colors[index % colors.length], value: val, radius: 25, showTitle: false);
                                          }),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(topCategories.length, (index) => _buildLegend(topCategories[index]['category'], colors[index % colors.length])),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader("PAYMENT METHODS"),
                        _buildChartContainer(
                          Row(
                            children: [
                              Expanded(
                                child: paymentMethods.isEmpty
                                    ? const Center(child: Text("No data", style: TextStyle(color: AppTheme.coolGrey)))
                                    : PieChart(
                                        PieChartData(
                                          sectionsSpace: 2,
                                          centerSpaceRadius: 30,
                                          sections: List.generate(paymentMethods.length, (index) {
                                            final val = (paymentMethods[index]['count'] as num).toDouble();
                                            return PieChartSectionData(color: colors[(index + 1) % colors.length], value: val, radius: 25, showTitle: false);
                                          }),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(paymentMethods.length, (index) => _buildLegend(paymentMethods[index]['method'], colors[(index + 1) % colors.length])),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                ),
            ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)));

  Widget _buildChartContainer(Widget child) => Container(
    height: 200, width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: AppTheme.premiumCard(radius: 24),
    child: child,
  );

  Widget _buildLegend(String label, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label.toUpperCase(), style: const TextStyle(color: AppTheme.coolGrey, fontSize: 9, letterSpacing: 0.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}
