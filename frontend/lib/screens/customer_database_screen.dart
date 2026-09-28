import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/admin_user_service.dart';
import '../services/api_service.dart';
import '../config/theme.dart';

class CustomerDatabaseScreen extends StatefulWidget {
  const CustomerDatabaseScreen({super.key});

  @override
  State<CustomerDatabaseScreen> createState() => _CustomerDatabaseScreenState();
}

class _CustomerDatabaseScreenState extends State<CustomerDatabaseScreen> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final list = await AdminUserService.fetchUsers();
      if (mounted) {
        setState(() {
          users = list;
          filteredUsers = list;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load Users Error: $e');
      if (mounted) {
        setState(() {
          users = [];
          filteredUsers = [];
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().contains('503') ? 'Database connecting... try again in 5s.' : 'Failed to load customers: $e'))
        );
      }
    }
  }

  void _runFilter(String query) {
    List<dynamic> results = [];
    if (query.isEmpty) {
      results = users;
    } else {
      results = users.where((user) {
        final name = user['name']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        return name.contains(query.toLowerCase()) || email.contains(query.toLowerCase());
      }).toList();
    }
    setState(() {
      filteredUsers = results;
    });
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

  Future<void> _toggleSuspension(String id) async {
    try {
      await AdminUserService.toggleSuspension(id);
      loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User status updated'), backgroundColor: AppTheme.success)
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _showUserDetails(dynamic user) {
      final List<dynamic> addresses = user['addresses'] ?? [];
      final bool isSuspended = user['isSuspended'] ?? false;
      
      showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollController) => Container(
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  color: AppTheme.deepCharcoal, 
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border(top: BorderSide(color: AppTheme.glassBorder, width: 0.5)),
                ),
                child: ListView(
                    controller: scrollController,
                    children: [
                        Center(
                            child: Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: isSuspended ? AppTheme.error : AppTheme.glassBorder, width: 2),
                              ),
                              child: ClipOval(
                                child: user['avatar'] != null && user['avatar'].toString().isNotEmpty
                                  ? CachedNetworkImage(imageUrl: user['avatar'], fit: BoxFit.cover, placeholder: (ctx, url) => const CircularProgressIndicator(), errorWidget: (ctx, url, err) => const Icon(Icons.person, size: 50))
                                  : Center(child: Text(user['name']?[0]?.toUpperCase() ?? 'C', style: const TextStyle(fontSize: 40, color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900))),
                              ),
                            ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('CUSTOMER IDENTITY', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                            if (isSuspended)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: AppTheme.error)),
                                child: const Text('SUSPENDED', style: TextStyle(color: AppTheme.error, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow('FULL NAME', user['name']),
                        _buildDetailRow('EMAIL', user['email']),
                        _buildDetailRow('PHONE', user['phone']?.toString().isNotEmpty == true ? user['phone'] : 'NOT PROVIDED'),
                        _buildDetailRow('RECOVERY HINT', user['recoveryHint']?.toString().isNotEmpty == true ? user['recoveryHint'] : 'NOT SET'),
                        
                        const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(color: AppTheme.glassBorder)),
                        const Text('ACCOUNT STATUS', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        const SizedBox(height: 24),
                        _buildDetailRow('ROLE', user['role'].toString().toUpperCase()),
                        _buildDetailRow('JOINED ON', user['createdAt']?.toString().substring(0,10) ?? 'N/A'),

                        if (addresses.isNotEmpty) ...[
                          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(color: AppTheme.glassBorder)),
                          const Text('SAVED ADDRESSES', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          const SizedBox(height: 20),
                          ...addresses.map((addr) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.glassBorder.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.brushedPlatinum),
                                    const SizedBox(width: 8),
                                    Text(addr['label']?.toUpperCase() ?? 'HOME', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1, color: AppTheme.brushedPlatinum)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(addr['fullName'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('${addr['addressLine1']}, ${addr['city']}, ${addr['state']} - ${addr['pincode']}', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 11, height: 1.4)),
                                Text('Phone: ${addr['phone'] ?? ''}', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 11)),
                              ],
                            ),
                          )),
                        ],

                        const SizedBox(height: 48),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () { Navigator.pop(ctx); _toggleSuspension(user['_id']); },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSuspended ? AppTheme.success : AppTheme.error.withOpacity(0.8),
                            ),
                            child: Text(isSuspended ? 'UNSUSPEND USER' : 'SUSPEND USER', style: const TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
                          ),
                        ),
                        
                        const SizedBox(height: 16),

                        SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                                onPressed: () { Navigator.pop(ctx); _deleteCustomer(user['_id']); },
                                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error)),
                                child: const Text('PERMANENTLY DELETE ACCOUNT', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
                            ),
                        ),
                        const SizedBox(height: 40),
                    ],
                ),
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
                  const SizedBox(width: 24),
                  Expanded(child: Text(val ?? 'N/A', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.polishedSilver, fontSize: 12))),
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
              controller: _searchController,
              onChanged: _runFilter,
              decoration: const InputDecoration(hintText: "Search customers by name or email...", prefixIcon: Icon(Icons.search_outlined)),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
              : filteredUsers.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: loadUsers,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final String name = user['name']?.toString() ?? 'User';
                          final String email = user['email']?.toString() ?? '';
                          final String? avatar = user['avatar']?.toString();
                          final bool isSuspended = user['isSuspended'] ?? false;
                          
                          return Container(
                            decoration: AppTheme.premiumCard(radius: 24).copyWith(
                              border: isSuspended ? Border.all(color: AppTheme.error.withOpacity(0.5), width: 1.5) : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                  onTap: () => _showUserDetails(user),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  leading: SizedBox(
                                    width: 44, height: 44,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSuspended ? AppTheme.error.withOpacity(0.05) : Colors.white.withOpacity(0.05), 
                                        shape: BoxShape.circle,
                                        border: Border.all(color: isSuspended ? AppTheme.error : AppTheme.glassBorder, width: 0.5),
                                      ),
                                      alignment: Alignment.center,
                                      child: ClipOval(
                                        child: avatar != null && avatar.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: avatar, 
                                              fit: BoxFit.cover,
                                              width: 44, height: 44,
                                              placeholder: (ctx, url) => const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brushedPlatinum),
                                              errorWidget: (ctx, url, err) => Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: TextStyle(color: isSuspended ? AppTheme.error : AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 16))))
                                          : Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: TextStyle(color: isSuspended ? AppTheme.error : AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 16))),
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(child: Text(name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5, color: isSuspended ? AppTheme.error : AppTheme.polishedSilver))),
                                      if (isSuspended)
                                        const Icon(Icons.block_flipped, size: 14, color: AppTheme.error),
                                    ],
                                  ),
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

  Widget _buildEmptyState() {
      return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  const Icon(Icons.people_outline_rounded, size: 60, color: Colors.white10),
                  const SizedBox(height: 24),
                  const Text("NO CUSTOMERS FOUND", style: TextStyle(color: AppTheme.coolGrey, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 32),
                  TextButton.icon(
                      onPressed: loadUsers,
                      icon: const Icon(Icons.refresh_rounded, color: AppTheme.brushedPlatinum, size: 18),
                      label: const Text("RETRY CONNECTION", style: TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                  ),
              ],
          ),
      );
  }
}
