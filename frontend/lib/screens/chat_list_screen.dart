import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../config/theme.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatThread> threads = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadThreads();
  }

  Future<void> loadThreads() async {
    setState(() => isLoading = true);
    try {
      final result = await ChatService.fetchThreads();
      if (mounted) setState(() => threads = result);
    } catch (e) {
      debugPrint('Load Threads Error: $e');
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(title: const Text('CUSTOMER CHATS')),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
            : threads.isEmpty
            ? const Center(child: Text('No active chats.', style: TextStyle(color: AppTheme.coolGrey)))
            : RefreshIndicator(
                onRefresh: loadThreads,
                color: AppTheme.brushedPlatinum,
                backgroundColor: AppTheme.matteBlack,
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, 20, isNarrow ? 16 : 24, 100),
                  itemCount: threads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final thread = threads[index];
                    return Container(
                      decoration: AppTheme.premiumCard(radius: 24),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                                customerId: thread.customerId, 
                                customerName: thread.customerName,
                                customerAvatar: thread.customerAvatar,
                            )));
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                            ),
                            alignment: Alignment.center,
                            child: ClipOval(
                              child: thread.customerAvatar.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: thread.customerAvatar,
                                    fit: BoxFit.cover,
                                    width: 44, height: 44,
                                    placeholder: (ctx, url) => const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brushedPlatinum),
                                    errorWidget: (ctx, url, err) => Text(thread.customerName.isNotEmpty ? thread.customerName[0].toUpperCase() : 'C', style: const TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 16)),
                                  )
                                : Text(thread.customerName.isNotEmpty ? thread.customerName[0].toUpperCase() : 'C', style: const TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 16)),
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(thread.customerName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5, color: AppTheme.polishedSilver))),
                              const SizedBox(width: 8),
                              Text(DateFormat('hh:mm a').format(thread.lastMessageTime.toLocal()), style: const TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(thread.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.coolGrey, fontSize: 11, fontWeight: FontWeight.w500)),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white10, size: 18),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
