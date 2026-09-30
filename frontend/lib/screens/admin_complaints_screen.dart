import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../config/theme.dart';
import '../widgets/gold_button.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  List<dynamic> _complaints = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/complaints/admin/all');
      if (mounted) setState(() => _complaints = res);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _showResolveDialog(String id) {
    final responseCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setSheetState) => Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            decoration: const BoxDecoration(
              color: AppTheme.deepCharcoal,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              border: Border(top: BorderSide(color: AppTheme.glassBorder, width: 0.5)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  const Text('RESOLVE COMPLAINT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 10),
                    child: Text('REPLY MESSAGE', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ),
                  TextField(
                      controller: responseCtrl, 
                      maxLines: 4, 
                      style: const TextStyle(color: AppTheme.polishedSilver, fontSize: 14),
                      decoration: InputDecoration(
                          hintText: 'Enter your response...',
                          contentPadding: const EdgeInsets.all(18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                      )
                  ),
                  const SizedBox(height: 28),
                  GoldButton(
                      label: 'SEND REPLY',
                      isLoading: isSubmitting,
                      onPressed: isSubmitting ? null : () async {
                        if (responseCtrl.text.trim().isEmpty) return;
                        setSheetState(() => isSubmitting = true);
                        try {
                            await ApiService.put('/complaints/admin/$id', {'status': 'Resolved', 'response': responseCtrl.text.trim()});
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              _loadComplaints();
                            }
                        } catch (_) {}
                        finally { if (ctx.mounted) setSheetState(() => isSubmitting = false); }
                      },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(title: const Text('MANAGE COMPLAINTS')),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
            : _complaints.isEmpty
            ? const Center(child: Text("No complaints found.", style: TextStyle(color: AppTheme.coolGrey)))
            : RefreshIndicator(
                onRefresh: _loadComplaints,
                color: AppTheme.brushedPlatinum,
                backgroundColor: AppTheme.matteBlack,
                child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, 20, isNarrow ? 16 : 24, 120),
                    itemCount: _complaints.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (ctx, idx) {
                      final c = _complaints[idx];
                      final user = c['userId'] ?? {};
                      final isResolved = c['status'] == 'Resolved';
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.premiumCard(radius: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(c['subject']?.toUpperCase() ?? 'COMPLAINT', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5, color: AppTheme.polishedSilver))),
                                const SizedBox(width: 8),
                                _buildStatusTag(c['status']),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text('${user['name']} • ${user['email']}', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.w500)),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: AppTheme.glassBorder, height: 1, thickness: 1),
                            ),
                            Text(c['message'] ?? '', style: const TextStyle(color: AppTheme.coolGrey, height: 1.5, fontSize: 13)),
                            if (c['response']?.isNotEmpty == true) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.success.withValues(alpha: 0.2))),
                                child: Text('REPLY: ${c['response']}', style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w500)),
                              ),
                            ],
                            if (!isResolved) ...[
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton(
                                    onPressed: () => _showResolveDialog(c['_id']), 
                                    style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppTheme.platinumBorder),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))
                                    ), 
                                    child: const Text('RESOLVE NOW', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w900, color: AppTheme.polishedSilver))
                                ),
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(delay: (idx % 10 * 50).ms).slideX(begin: 0.05, end: 0);
                    },
                  ),
              ),
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    final color = status == 'Resolved' ? AppTheme.success : AppTheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }
}
