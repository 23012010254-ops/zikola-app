import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/child_profile.dart';
import '../models/test_result.dart';
import '../models/sticker.dart';
import '../services/app_state.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart'; // For ShiningStickerSlot and helper methods

class PublicProfileScreen extends StatefulWidget {
  final String targetUid;

  const PublicProfileScreen({super.key, required this.targetUid});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final FirestoreService _firestore = FirestoreService();
  late Future<Map<String, dynamic>> _profileDataFuture;

  @override
  void initState() {
    super.initState();
    _profileDataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final futures = await Future.wait([
      _firestore.loadProfile(widget.targetUid),
      _firestore.loadTestResults(widget.targetUid),
    ]);
    return {
      'profile': futures[0] as ChildProfile?,
      'testResults': futures[1] as TestResults?,
    };
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isFollowing = appState.childProfile.following.contains(widget.targetUid);
    final isSelf = appState.uid == widget.targetUid;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!['profile'] == null) {
            return const Center(child: Text('Gagal memuat profil.'));
          }

          final profile = snapshot.data!['profile'] as ChildProfile;
          final testResults = snapshot.data!['testResults'] as TestResults?;
          
          final bgColor = _getColorFromString(profile.backgroundColor);
          final followersCount = profile.followers.length + (isFollowing && !profile.followers.contains(appState.uid) ? 1 : 0);

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Top Gradient Background
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [bgColor, bgColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                    ),
                    
                    // Back Button
                    Positioned(
                      top: 40,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                    ),

                    // Avatar Header
                    Positioned(
                      top: 100,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Hero(
                              tag: 'profile_avatar_${widget.targetUid}',
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: bgColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: bgColor.withOpacity(0.2), width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: bgColor.withOpacity(0.1),
                                  backgroundImage: profile.avatarBase64 != null 
                                      ? MemoryImage(base64Decode(profile.avatarBase64!))
                                      : null,
                                  child: profile.avatarBase64 == null 
                                      ? Text(profile.avatar, style: const TextStyle(fontSize: 60))
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 100), // Space for elevated avatar

                // Name and Bio
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        profile.name,
                        style: AppTheme.heading1.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Member Aktif Zikola',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildGlassStatCard(
                              'Pengikut', 
                              followersCount.toString(), 
                              Icons.group_rounded,
                              () {
                                final List<String> followers = List.from(profile.followers);
                                if (isFollowing && appState.uid != null && !followers.contains(appState.uid)) {
                                  followers.add(appState.uid!);
                                }
                                Navigator.pushNamed(context, '/follows-screen', arguments: {
                                  'title': 'Pengikut',
                                  'uids': followers,
                                });
                              }
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildGlassStatCard(
                              'Mengikuti', 
                              profile.following.length.toString(), 
                              Icons.person_add_alt_1_rounded,
                              () {
                                Navigator.pushNamed(context, '/follows-screen', arguments: {
                                  'title': 'Mengikuti',
                                  'uids': profile.following,
                                });
                              }
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      if (!isSelf)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await appState.toggleFollow(widget.targetUid);
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing ? Colors.white : AppTheme.primaryBlue,
                              foregroundColor: isFollowing ? AppTheme.primaryBlue : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: isFollowing ? 0 : 8,
                              shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
                              side: isFollowing ? BorderSide(color: AppTheme.primaryBlue.withOpacity(0.3)) : null,
                            ),
                            child: Text(
                              isFollowing ? '✓ Mengikuti' : 'Ikuti Pengguna',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Showcase Stiker
                if (profile.showcasedStickers.isNotEmpty)
                  _buildProfileSection(
                    title: 'Pameran Stiker',
                    icon: '🏆',
                    child: Container(
                      width: double.infinity,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: profile.showcasedStickers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final stickerId = entry.value;
                              final stickerInfo = StickerDatabase.getSticker(stickerId);
                              final rarity = stickerInfo?.rarity ?? 'Common';

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ShiningStickerSlot(
                                      stickerId: stickerId,
                                      index: index,
                                      onTap: () {},
                                      isLarge: true,
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getSlotBgColor(rarity).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: _getSlotBorderColor(rarity).withOpacity(0.2)),
                                      ),
                                      child: Text(
                                        rarity.toUpperCase(), 
                                        style: TextStyle(
                                          fontSize: 9, 
                                          fontWeight: FontWeight.w900, 
                                          letterSpacing: 0.5,
                                          color: _getSlotBorderColor(rarity)
                                        )
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // MBTI Card
                if (testResults != null && testResults.personality.completed && testResults.personality.type != null)
                  _buildProfileSection(
                    title: 'Kepribadian MBTI',
                    icon: '🎭',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD946EF).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Icon(Icons.auto_awesome, color: Colors.white.withOpacity(0.1), size: 100),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                                        ),
                                        child: Center(
                                          child: Text(_getMBTIEmoji(testResults.personality.type!), style: const TextStyle(fontSize: 40)),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getMBTIName(testResults.personality.type!),
                                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                'MBTI: ${testResults.personality.type!}',
                                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Text(
                                      _getMBTIDesc(testResults.personality.type!),
                                      style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassStatCard(String label, String count, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 20),
            const SizedBox(height: 8),
            Text(count, style: AppTheme.heading2.copyWith(fontSize: 22, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection({required String title, required String icon, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTheme.heading3.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        child,
      ],
    );
  }

  Color _getColorFromString(String colorString) {
    if (colorString.startsWith('#')) {
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    }
    switch (colorString) {
      case 'purple': return const Color(0xFFA855F7);
      case 'green': return const Color(0xFF22C55E);
      case 'orange': return const Color(0xFFF97316);
      case 'pink': return const Color(0xFFEC4899);
      case 'blue': default: return const Color(0xFF3B82F6);
    }
  }

  String _getMBTIEmoji(String type) {
    if (type.contains('E') && type.contains('J')) return '🦁'; // ENFJ, ENTJ, ESFJ, ESTJ
    if (type.contains('E') && type.contains('P')) return '🐒'; // ENFP, ENTP, ESFP, ESTP
    if (type.contains('I') && type.contains('J')) return '🦉'; // INFJ, INTJ, ISFJ, ISTJ
    return '🐢'; // INFP, INTP, ISFP, ISTP
  }

  Color _getSlotBgColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'mythical': return const Color(0xFFFEF2F2);
      case 'legend':
      case 'legendary': return const Color(0xFFFFFBEB);
      case 'epic': return const Color(0xFFFAF5FF);
      case 'rare': return const Color(0xFFEFF6FF);
      default: return Colors.white;
    }
  }

  Color _getSlotBorderColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'mythical': return const Color(0xFFEF4444);
      case 'legend':
      case 'legendary': return const Color(0xFFF59E0B);
      case 'epic': return const Color(0xFFA855F7);
      case 'rare': return const Color(0xFF3B82F6);
      default: return const Color(0xFFE2E8F0);
    }
  }

  String _getMBTIName(String type) {
    switch (type) {
      case 'ENFJ': return 'Singa Pemimpin';
      case 'ENTJ': return 'Panglima Strategi';
      case 'ENFP': return 'Inovator Antusias';
      case 'ENTP': return 'Penemu Cerdas';
      case 'ESFJ': return 'Pengasuh Ramah';
      case 'ESTJ': return 'Pengatur Andal';
      case 'ESFP': return 'Penghibur Interaktif';
      case 'ESTP': return 'Petualang Spontan';
      case 'INFJ': return 'Penasihat Bijak';
      case 'INTJ': return 'Arsitek Pemikir';
      case 'INFP': return 'Pemimpi Ideal';
      case 'INTP': return 'Pemikir Analitis';
      case 'ISFJ': return 'Pelindung Setia';
      case 'ISTJ': return 'Perencana Disiplin';
      case 'ISFP': return 'Seniman Bebas';
      case 'ISTP': return 'Pembuat Terampil';
      default: return 'Penjelajah Misterius';
    }
  }

  String _getMBTIDesc(String type) {
    if (type.contains('E')) return 'Seorang yang sangat ramah dan peduli terhadap anak-anak di sekitarnya.';
    return 'Seorang pendiam yang sangat pintar dan analitis dalam memecahkan masalah.';
  }
}
