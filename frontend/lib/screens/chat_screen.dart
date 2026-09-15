import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/chat_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/upload_service.dart';
import '../config/theme.dart';

class ChatScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const ChatScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageController = TextEditingController();
  final listScrollController = ScrollController();
  List<ChatMessage> messages = [];
  bool isLoading = false;
  bool isUploading = false;
  bool isLocating = false;
  Timer? pollTimer;
  StreamSubscription<dynamic>? chatSubscription;
  String? editingMsgId;

  @override
  void initState() {
    super.initState();
    loadMessages();
    final roomCustomerId = ApiService.currentUserRole == 'admin' ? widget.customerId : ApiService.currentUserId;
    if (roomCustomerId != null) SocketService.joinRoom('${roomCustomerId}_admin');
    chatSubscription = SocketService.chatMessages.listen(_handleRealtimeMessage);
    pollTimer = Timer.periodic(const Duration(seconds: 4), (timer) => loadMessages(silent: true));
  }

  @override
  void dispose() { pollTimer?.cancel(); chatSubscription?.cancel(); messageController.dispose(); listScrollController.dispose(); super.dispose(); }

  void _handleRealtimeMessage(dynamic data) {
    if (!mounted || data is! Map) return;
    final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
    if (messages.any((item) => item.id == message.id)) return;
    setState(() => messages.add(message)); _scrollToBottom();
  }

  Future<void> loadMessages({bool silent = false}) async {
    if (!silent && mounted) setState(() => isLoading = true);
    try {
      final list = await ChatService.fetchMessages(widget.customerId);
      if (mounted) { setState(() => messages = list); if (!silent) _scrollToBottom(); }
    } catch (_) {}
    if (!silent && mounted) setState(() => isLoading = false);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (listScrollController.hasClients) listScrollController.animateTo(listScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  Future<void> handleSendMessage({String? image, Map<String, double>? location}) async {
    final text = messageController.text.trim();
    if (text.isEmpty && image == null && location == null) return;
    messageController.clear();
    try {
      final sent = await ChatService.sendMessage(widget.customerId, text, image: image, location: location);
      if (mounted) { setState(() => messages.add(sent)); _scrollToBottom(); }
    } catch (_) {}
  }

  Future<void> _shareLocation() async {
    if (isLocating) return;
    
    setState(() => isLocating = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission denied. Please allow location access and try again.';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. Please enable them in settings.';
      }

      // Show temporary snackbar for loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Getting your location...'), duration: Duration(seconds: 2))
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        throw 'Invalid coordinates received.';
      }

      await handleSendMessage(location: {'lat': lat, 'lng': lng});
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error)
        );
      }
    } finally {
      if (mounted) setState(() => isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      resizeToAvoidBottomInset: true, 
      appBar: AppBar(
        title: Text(widget.customerName.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 600 : double.infinity),
            child: Column(
              children: [
                if (isUploading || isLocating) 
                  const LinearProgressIndicator(minHeight: 1, valueColor: AlwaysStoppedAnimation(AppTheme.brushedPlatinum), backgroundColor: Colors.transparent),
                Expanded(
                  child: ListView.builder(
                    controller: listScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == ApiService.currentUserId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
                ),
                _buildInputArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    final hasLocation = msg.location != null;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withOpacity(0.08) : AppTheme.matteBlack.withOpacity(0.5),
          border: Border.all(color: isMe ? AppTheme.glassBorder : Colors.white10, width: 1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.image != null && msg.image!.isNotEmpty) 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: msg.image!)),
              ),
            
            if (hasLocation) _buildLocationCard(msg.location!),

            if (msg.message.isNotEmpty) 
              Text(msg.message, style: TextStyle(color: isMe ? Colors.white : AppTheme.polishedSilver, fontSize: 13, height: 1.4)),
            
            const SizedBox(height: 6),
            Text(DateFormat('hh:mm a').format(msg.createdAt.toLocal()), style: const TextStyle(color: Colors.white10, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).moveY(begin: 10, end: 0);
  }

  Widget _buildLocationCard(Map<String, double> loc) {
    final lat = loc['lat'] ?? 0.0;
    final lng = loc['lng'] ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_rounded, color: AppTheme.brushedPlatinum, size: 16),
              SizedBox(width: 8),
              Text('LOCATION SHARED', style: TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Latitude: $lat', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 11)),
          Text('Longitude: $lng', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 11)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brushedPlatinum,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                padding: EdgeInsets.zero,
              ),
              onPressed: () => _openInMaps(lat, lng),
              child: const Text('OPEN IN MAPS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.deepCharcoal.withOpacity(0.8),
          border: const Border(top: BorderSide(color: AppTheme.glassBorder, width: 0.5)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: isUploading || isLocating ? null : () async {
                final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
                if (img != null) {
                  setState(() => isUploading = true);
                  final url = await UploadService.uploadImage(img);
                  if (url != null) handleSendMessage(image: url);
                  setState(() => isUploading = false);
                }
              },
              icon: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.coolGrey, size: 22),
            ),
            IconButton(
              onPressed: isUploading || isLocating ? null : _shareLocation,
              icon: Icon(Icons.location_on_outlined, color: isLocating ? AppTheme.brushedPlatinum : AppTheme.coolGrey, size: 22),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    hintText: "Type a message...", 
                    border: InputBorder.none, 
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false, 
                    contentPadding: EdgeInsets.symmetric(vertical: 12)
                  ),
                  style: const TextStyle(fontSize: 14, color: AppTheme.polishedSilver),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppTheme.brushedPlatinum, shape: BoxShape.circle),
              child: IconButton(
                onPressed: () => handleSendMessage(), 
                icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20)
              ),
            ),
          ],
        ),
      ),
    );
  }
}
