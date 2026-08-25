import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

class FollowsScreen extends StatefulWidget {
  const FollowsScreen({super.key});

  @override
  State<FollowsScreen> createState() => _FollowsScreenState();
}

class _FollowsScreenState extends State<FollowsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _profiles = [];
  String _title = 'Daftar Pengguna';
  List<String> _uids = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _title = args['title'] ?? 'Pengguna';
        _uids = List<String>.from(args['uids'] ?? []);
      }
      _loadProfiles();
    }
  }

  Future<void> _loadProfiles() async {
    if (_uids.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await _firestoreService.getProfiles(_uids);
      if (mounted) {
        setState(() {
          _profiles = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profiles: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_title, style: AppTheme.heading3.copyWith(color: AppTheme.gray900)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.gray600),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: AppTheme.gray300),
                      const SizedBox(height: 16),
                      Text('Belum ada pengguna', style: AppTheme.heading3.copyWith(color: AppTheme.gray500)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _profiles.length,
                  separatorBuilder: (context, index) => Divider(color: AppTheme.gray200, height: 1),
                  itemBuilder: (context, index) {
                    final profile = _profiles[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.orange100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: profile['avatarBase64'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  base64Decode(profile['avatarBase64']),
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Center(child: Text(profile['avatar'] ?? '👤', style: const TextStyle(fontSize: 24))),
                                ),
                              )
                            : Center(
                                child: Text(profile['avatar'] ?? '👤', style: const TextStyle(fontSize: 24)),
                              ),
                      ),
                      title: Text(
                        profile['name'],
                        style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.bold, color: AppTheme.gray900),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.gray400),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/public-profile',
                          arguments: {'targetUid': profile['uid']},
                        );
                      },
                    );
                  },
                ),
    );
  }
}
