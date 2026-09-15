import 'package:flutter/material.dart';
import '../services/admin_user_service.dart';
import '../config/theme.dart';

class CustomerDatabaseScreen extends StatefulWidget {
  const CustomerDatabaseScreen({super.key});

  @override
  State<CustomerDatabaseScreen> createState() => _CustomerDatabaseScreenState();
}

class _CustomerDatabaseScreenState extends State<CustomerDatabaseScreen> {
  List<dynamic> users = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final list = await AdminUserService.fetchUsers();
      if (mounted) setState(() {
          users = list;
          isLoading = false;
      });
    } catch (e) {
      debugPrint('Load Users Error: $e');
      if (mounted) {
          setState(() {
              users = [];
              isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not fetch data. Check server DB connection.')));
      }
    }
  }

  Future<void> _deleteCustomer(String id) async {
      final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.deepCharcoal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: const BorderSide(color: AppTheme.glassBorder)),
              title: const Text('DELETE ACCOUNT?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: const Text('This will permanently delete this customer profile.', style: TextStyle(color: AppTheme.coolGrey)),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL', style: TextStyle(color: AppTheme.coolGrey))),
                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), child: const Text('DELETE')),
              ],
          ),
      );
      if (confirm == true) {
          try { await AdminUserService.deleteUser(id); loadUsers(); } catch (_) {}
      }
  }

  void _showUserDetails(dynamic user) {
      showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (ctx) => Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: AppTheme.deepCharcoal, 
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(top: BorderSide(color: AppTheme.glassBorder, width: 0.5)),
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Center(
                          child: CircleAvatar(
                              radius: 40,
                              backgroundColor: AppTheme.brushedPlatinum.withOpacity(0.05),
                              child: Text(user['name']?[0]?.toUpperCase() ?? 'C', style: const TextStyle(fontSize: 28, color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900)),
                          ),
                      ),
                      const SizedBox(height: 32),
                      Text('CUSTOMER INFO', style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 24),
                      _buildDetailRow('NAME', user['name']),
                      _buildDetailRow('EMAIL', user['email']),
                      _buildDetailRow('PHONE', user['phone']?.toString() ?? 'N/A'),
                      _buildDetailRow('ROLE', user['role'].toString().toUpperCase()),
                      _buildDetailRow('JOINED', user['createdAt']?.toString().substring(0,10) ?? 'N/A'),
                      const SizedBox(height: 48),
                      SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                              onPressed: () { Navigator.pop(ctx); _deleteCustomer(user['_id']); },
                              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error)),
                              child: const Text('DELETE CUSTOMER', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
                          ),
                      ),
                      const SizedBox(height: 20),
                  ],
              ),
          ),
      );
  }

  Widget _buildDetailRow(String label, String? val) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                  Text(label, style: const TextStyle(color: AppTheme.coolGrey, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
                  Text(val ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.polishedSilver, fontSize: 12)),
              ],
          ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: TextField(
              decoration: const InputDecoration(hintText: "Search customers...", prefixIcon: Icon(Icons.search_outlined)),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
              : users.isEmpty
                  ? const Center(child: Text("No customers found.", style: TextStyle(color: AppTheme.coolGrey)))
                  : RefreshIndicator(
                      onRefresh: loadUsers,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final String name = user['name']?.toString() ?? 'User';
                          final String email = user['email']?.toString() ?? '';
                          
                          return Container(
                            decoration: AppTheme.premiumCard(radius: 24),
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                  onTap: () => _showUserDetails(user),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  leading: Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 16)),
                                  ),
                                  title: Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5, color: AppTheme.polishedSilver)),
                                  subtitle: Text(email, style: const TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.w500)),
                                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white10),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
