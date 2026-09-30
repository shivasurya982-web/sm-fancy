import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/admin_user_service.dart';
import '../config/theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() => isLoading = true);
    try {
      final data = await AdminUserService.fetchUsers();
      if (mounted) setState(() { users = data; });
    } catch (_) {}
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text("USER MANAGEMENT"),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
            : users.isEmpty
                ? const Center(child: Text("No users found.", style: TextStyle(color: AppTheme.coolGrey)))
                : ListView.separated(
                    padding: EdgeInsets.all(isNarrow ? 16 : 24),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final name = user['name']?.toString() ?? 'User';
                      final email = user['email']?.toString() ?? '';
                      
                      return Container(
                        decoration: AppTheme.premiumCard(radius: 24),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            leading: Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 16)),
                            ),
                            title: Text(name.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5, color: AppTheme.polishedSilver)),
                            subtitle: Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.w500)),
                            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white10),
                          ),
                        ),
                      ).animate().fadeIn(delay: (index % 10 * 50).ms).slideX(begin: 0.05, end: 0);
                    },
                  ),
      ),
    );
  }
}
