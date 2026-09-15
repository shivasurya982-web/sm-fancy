import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    await NotificationService.fetchMyNotifications();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleClearAll() async {
      setState(() => _isLoading = true);
      await NotificationService.clearAll();
      if (mounted) setState(() => _isLoading = false);
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text('NOTIFICATIONS'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        actions: [
          ValueListenableBuilder<List<dynamic>>(
            valueListenable: NotificationService.notificationsNotifier,
            builder: (context, list, _) {
              if (list.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: _handleClearAll,
                child: const Text('CLEAR ALL', style: TextStyle(color: AppTheme.brushedPlatinum, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 500 : double.infinity),
            child: ValueListenableBuilder<List<dynamic>>(
              valueListenable: NotificationService.notificationsNotifier,
              builder: (context, rawList, _) {
                final List<NotificationModel> notifications = rawList.map((j) => NotificationModel.fromJson(j)).toList();

                return _isLoading && notifications.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
                    : notifications.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppTheme.brushedPlatinum,
                            backgroundColor: AppTheme.matteBlack,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              itemCount: notifications.length,
                              separatorBuilder: (ctx, idx) => const SizedBox(height: 16),
                              itemBuilder: (ctx, idx) {
                                final n = notifications[idx];
                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: AppTheme.premiumCard(radius: 24),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                                        child: Icon(n.type == 'order' ? Icons.shopping_bag_outlined : Icons.campaign_outlined, color: AppTheme.brushedPlatinum, size: 18),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(n.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5, color: AppTheme.polishedSilver)),
                                                Text(_formatTime(n.createdAt), style: const TextStyle(color: AppTheme.coolGrey, fontSize: 9, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(n.body, style: const TextStyle(color: AppTheme.coolGrey, height: 1.4, fontSize: 12, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.error),
                                        onPressed: () => NotificationService.deleteNotification(n.id),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: (idx % 10 * 50).ms).slideX(begin: 0.05, end: 0);
                              },
                            ),
                          );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none_rounded, size: 60, color: Colors.white10),
          const SizedBox(height: 24),
          const Text('NO NOTIFICATIONS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14, color: AppTheme.polishedSilver)),
          const SizedBox(height: 12),
          const Text('No new alerts found.', style: TextStyle(color: AppTheme.coolGrey, fontSize: 12)),
        ],
      ),
    );
  }
}
