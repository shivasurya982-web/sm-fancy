import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../config/theme.dart';

class NotificationsManagementScreen extends StatefulWidget {
  const NotificationsManagementScreen({super.key});

  @override
  State<NotificationsManagementScreen> createState() => _NotificationsManagementScreenState();
}

class _NotificationsManagementScreenState extends State<NotificationsManagementScreen> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  Future<void> loadNotifications() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final list = await NotificationService.fetchAllNotifications();
      if (mounted) setState(() => notifications = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> handleBroadcast() async {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await NotificationService.broadcastNotification(title: title, body: body);
      titleController.clear();
      bodyController.clear();
      if (!mounted) return;
      Navigator.pop(context);
      loadNotifications();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification sent successfully."), backgroundColor: AppTheme.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void showBroadcastDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: AppTheme.deepCharcoal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: AppTheme.glassBorder, width: 0.5)),
        ),
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SEND NOTIFICATION', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9)),
              const SizedBox(height: 24),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 16),
              TextField(controller: bodyController, maxLines: 3, decoration: const InputDecoration(labelText: 'Message')),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(onPressed: handleBroadcast, child: const Text('SEND TO ALL')),
              ),
              const SizedBox(height: 16),
            ],
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
      appBar: AppBar(
        title: const Text('MANAGE NOTIFICATIONS'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.add_alert_rounded, color: AppTheme.brushedPlatinum), onPressed: showBroadcastDialog),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
            : notifications.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: loadNotifications,
                    color: AppTheme.brushedPlatinum,
                    backgroundColor: AppTheme.matteBlack,
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, 20, isNarrow ? 16 : 24, 40),
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (ctx, idx) {
                        final n = notifications[idx];
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.premiumCard(radius: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(n['title']?.toUpperCase() ?? 'NOTIFICATION', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5, color: AppTheme.polishedSilver))),
                                  const SizedBox(width: 8),
                                  Text(n['createdAt'] != null ? DateFormat('dd MMM • hh:mm a').format(DateTime.parse(n['createdAt']).toLocal()) : '', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 9, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(n['body'] ?? '', style: const TextStyle(color: AppTheme.coolGrey, height: 1.4, fontSize: 12)),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.glassBorder, width: 0.8)),
                                child: Text(
                                  n['userId'] == null ? "GLOBAL" : "DIRECT",
                                  style: const TextStyle(color: AppTheme.brushedPlatinum, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history_rounded, size: 60, color: Colors.white10),
          SizedBox(height: 24),
          Text('NO HISTORY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppTheme.polishedSilver)),
          SizedBox(height: 8),
          Text('Sent notifications will appear here.', style: TextStyle(color: AppTheme.coolGrey, fontSize: 12)),
        ],
      ),
    );
  }
}
