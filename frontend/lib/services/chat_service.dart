import 'api_service.dart';
import 'package:flutter/foundation.dart';

class ChatMessage {
  final String id;
  final String customerId;
  final String senderId;
  final String senderName;
  final String message;
  final String senderRole;
  final String? image;
  final Map<String, double>? location;
  final bool isRead;
  final bool isDeleted;
  final bool isEdited;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.customerId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.senderRole,
    this.image,
    this.location,
    this.isRead = false,
    this.isDeleted = false,
    this.isEdited = false,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final senderId = json['senderId']?.toString() ?? '';
    
    Map<String, double>? loc;
    if (json['location'] != null) {
        loc = {
            'lat': (json['location']['lat'] ?? json['location']['latitude'] as num).toDouble(),
            'lng': (json['location']['lng'] ?? json['location']['longitude'] as num).toDouble(),
        };
    }

    return ChatMessage(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      customerId: json['receiverId']?.toString() ?? '',
      senderId: senderId,
      senderName: senderId == 'admin' ? 'Store Owner' : 'Customer',
      message: json['message']?.toString() ?? '',
      senderRole: senderId == 'admin' ? 'admin' : 'user',
      image: json['image'],
      location: loc,
      isRead: json['isRead'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      isEdited: json['isEdited'] ?? false,
      createdAt: (DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now()).toLocal(),
    );
  }
}

class ChatThread {
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerAvatar;
  final String lastMessage;
  final String lastSenderRole;
  final int unreadCount;
  final DateTime lastMessageTime;

  ChatThread({
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerAvatar,
    required this.lastMessage,
    required this.lastSenderRole,
    this.unreadCount = 0,
    required this.lastMessageTime,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString() ?? '',
      customerAvatar: json['customerAvatar']?.toString() ?? '',
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastSenderRole: json['lastSenderRole']?.toString() ?? 'user',
      unreadCount: json['unreadCount'] ?? 0,
      lastMessageTime: DateTime.tryParse(json['lastMessageTime']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ChatService {
  static Future<List<ChatMessage>> fetchMessages(String customerId) async {
    try {
      final response = await ApiService.get('/chat/messages/$customerId');
      if (response is List) {
        return response.map((json) => ChatMessage.fromJson(Map<String, dynamic>.from(json))).toList();
      }
    } catch (e) {
      debugPrint('Fetch Messages Error: $e');
    }
    return [];
  }

  static Future<List<ChatThread>> fetchThreads() async {
    try {
      final response = await ApiService.get('/chat/threads');
      if (response is List) {
        return response.map((json) => ChatThread.fromJson(Map<String, dynamic>.from(json))).toList();
      }
    } catch (e) {
      debugPrint('Fetch Threads Error: $e');
    }
    return [];
  }

  static Future<ChatMessage> sendMessage(String customerId, String message, {Map<String, double>? location, String? image}) async {
    final response = await ApiService.post('/chat/messages', {
      'customerId': customerId,
      'message': message,
      'location': location,
      'image': image,
    });
    return ChatMessage.fromJson(Map<String, dynamic>.from(response));
  }

  static Future<void> deleteMessage(String id) async {
      await ApiService.delete('/chat/messages/$id');
  }

  static Future<void> editMessage(String id, String newMessage) async {
      await ApiService.put('/chat/messages/$id', {'message': newMessage});
  }
}
