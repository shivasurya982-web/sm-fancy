import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      setState(() => threads = result);
    } catch (e) {
      debugPrint('Load Threads Error: $e');
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                  itemCount: threads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                            ),
                            alignment: Alignment.center,
                            child: ClipOval(
                              child: thread.customerAvatar.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: thread.customerAvatar,
                                    fit: BoxFit.cover,
                                    width: 48, height: 48,
                                    placeholder: (ctx, url) => const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brushedPlatinum),
                                    errorWidget: (ctx, url, err) => Text(thread.customerName.isNotEmpty ? thread.customerName[0].toUpperCase() : 'C', style: const TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 18)),
                                  )
                                : Text(thread.customerName.isNotEmpty ? thread.customerName[0].toUpperCase() : 'C', style: const TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 18)),
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(thread.customerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5, color: AppTheme.polishedSilver)),
                              Text("${thread.lastMessageTime.hour}:${thread.lastMessageTime.minute.toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.bold)),
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
