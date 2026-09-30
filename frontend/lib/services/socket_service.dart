import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:fluttertoast/fluttertoast.dart';
import '../config/theme.dart';
import 'api_service.dart';
import 'notification_service.dart';

import 'local_notification_service.dart';

class SocketService {
  static io.Socket? socket;
  static final StreamController<dynamic> _chatMessages = StreamController<dynamic>.broadcast();
  static final Set<String> _pendingRooms = <String>{};

  static Stream<dynamic> get chatMessages => _chatMessages.stream;

  static void connect(String userId) {
    socket?.disconnect();
    
    // Using the same logic as ApiService for consistency
    final String baseUrl = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

    socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1500)
          .build(),
    );

    socket!.onConnect((_) {
      debugPrint('Socket Connected to: $baseUrl');
      socket!.emit('register', userId);
      for (final roomId in _pendingRooms) {
        socket!.emit('join_room', roomId);
      }
      _pendingRooms.clear();
    });

    socket!.on('receive_message', (data) {
      _chatMessages.add({'event': 'new', 'data': data});
    });

    socket!.on('message_edited', (data) {
      _chatMessages.add({'event': 'edited', 'data': data});
    });

    socket!.on('message_deleted', (data) {
      _chatMessages.add({'event': 'deleted', 'data': data});
    });

    // Listen for new notifications
    socket!.on('new_notification', (data) {
      debugPrint('Real-time Notification Payload: $data');
      NotificationService.onNewNotificationReceived(data);
      
      // Trigger System Pop-up Notification
      LocalNotificationService.showNotification(
        title: data['title'] ?? 'Archive Alert',
        body: data['body'] ?? 'New transmission received.',
      );
      
      // Keep Toast as secondary feedback
      _showNotificationToast(data['title'] ?? 'Archive Alert', data['body'] ?? 'New transmission received.');
    });

    socket!.onDisconnect((_) {
      debugPrint('Socket Disconnected');
    });

    socket!.onError((err) {
      debugPrint('Socket Error: $err');
    });
  }

  static void joinRoom(String roomId) {
    if (socket?.connected == true) {
      socket!.emit('join_room', roomId);
    } else {
      _pendingRooms.add(roomId);
    }
  }

  static void _showNotificationToast(String title, String body) {
    Fluttertoast.showToast(
      msg: "$title\n$body",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 4,
      backgroundColor: AppTheme.brushedPlatinum,
      textColor: AppTheme.matteBlack,
      fontSize: 14.0,
    );
  }

  static void disconnect() {
    socket?.disconnect();
    _pendingRooms.clear();
  }
}
