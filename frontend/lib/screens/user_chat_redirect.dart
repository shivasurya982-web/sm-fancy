import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';
import 'chat_list_screen.dart';

class UserChatRedirect extends StatelessWidget {
  const UserChatRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = ApiService.currentUserRole == 'admin';
    
    if (isAdmin) {
      return const ChatListScreen();
    } else {
      return const ChatScreen(customerId: 'admin', customerName: 'CHAT SUPPORT');
    }
  }
}
