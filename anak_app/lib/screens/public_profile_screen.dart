import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/child_profile.dart';
import '../models/community_post.dart';
import '../models/sticker.dart';
import '../services/app_state.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/full_screen_image.dart';
import 'post_detail_screen.dart';
import 'profile_screen.dart'; // For ShiningStickerSlot

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
    if (widget.targetUid.isEmpty) {
      return {'profile': null, 'testResults': null, 'posts': <CommunityPost>[]};
    }

    try {
      final futures = await Future.wait([
        _firestore.loadProfile(widget.targetUid),
        _firestore.loadTestResults(widget.targetUid),
      ]);

      // Load recent community posts by this user
      List<CommunityPost> userPosts = [];
      try {
        final querySnap = await FirebaseFirestore.instance
            .collection('community_posts')
            .where('authorId', isEqualTo: widget.targetUid)
            .limit(5)
            .get();
        userPosts = querySnap.docs
            .map((doc) => CommunityPost.fromFirestore(doc.id, doc.data()))
            .toList();
        userPosts.sort((a, b) => b.time.compareTo(a.time));
      } catch (e) {
        debugPrint('Error loading user posts: $e');
      }

      return {
        'profile': futures[0] as ChildProfile?,
        'testResults': futures[1] as TestResults?,
        'posts': userPosts,
      };
    } catch (e) {
      debugPrint('Error loading public profile data: $e');
      return {'profile': null, 'testResults': null, 'posts': <CommunityPost>[]};
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays > 0) {
      if (difference.inDays == 1) return '1 hari lalu';
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  void _showStickerDetailModal(BuildContext context, StickerInfo sticker) {
    final rarityColor = _getSlotBorderColor(sticker.rarity);
    final rarityBg = _getSlotBgColor(sticker.rarity);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: rarityBg,
                shape: BoxShape.circle,
                border: Border.all(color: rarityColor.withValues(alpha: 0.4), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: rarityColor.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(sticker.emoji, style: const TextStyle(fontSize: 42)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              sticker.name,
              style: AppTheme.heading2.copyWith(fontSize: 20, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: rarityBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: rarityColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                '★ ${sticker.rarity.toUpperCase()} ★',
                style: TextStyle(
                  color: rarityColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              sticker.description,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentUid = appState.uid;
    final isSelf = currentUid != null && currentUid.isNotEmpty && currentUid == widget.targetUid;
    final isFollowing = appState.childProfile.following.contains(widget.targetUid);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileDataFuture,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.primaryBlue),
                      const SizedBox(height: 16),
                      Text(
                        'Memuat profil pengguna...',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildFixedTopNav(context, 'Memuat Profil...'),
              ],
            );
          }

          // Error or Not Found state
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!['profile'] == null) {
            return Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF2F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_off_rounded, size: 40, color: Color(0xFFEF4444)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Profil Tidak Ditemukan',
                          style: AppTheme.heading2.copyWith(fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Data pengguna ini tidak dapat dimuat atau belum melengkapi profil.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildFixedTopNav(context, 'Profil Pengguna'),
              ],
            );
          }

          final profile = snapshot.data!['profile'] as ChildProfile;
          final testResults = snapshot.data!['testResults'] as TestResults?;
          final userPosts = (snapshot.data!['posts'] as List<CommunityPost>?) ?? [];

          final bgColor = _getColorFromString(profile.backgroundColor);
          final followersCount = profile.followers.length + (isFollowing && !profile.followers.contains(appState.uid) ? 1 : 0);

          return Stack(
            children: [
              // Main Scrollable Content
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 90,
                ),
                child: Column(
                  children: [
                    // Top Gradient Banner
                    Container(
                      width: double.infinity,
                      height: 195 + MediaQuery.of(context).padding.top,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            bgColor,
                            Color.lerp(bgColor, const Color(0xFF1E3A8A), 0.35) ?? bgColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(36),
                          bottomRight: Radius.circular(36),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: bgColor.withValues(alpha: 0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 20,
                            top: MediaQuery.of(context).padding.top + 45,
                            child: Icon(Icons.auto_awesome, color: Colors.white.withValues(alpha: 0.18), size: 68),
                          ),
                          Positioned(
                            left: 20,
                            bottom: 25,
                            child: Icon(Icons.stars_rounded, color: Colors.white.withValues(alpha: 0.15), size: 42),
                          ),
                        ],
                      ),
                    ),

                    // Overlapping Avatar and Bio Card
                    Transform.translate(
                      offset: const Offset(0, -60),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Avatar with Hero and Tap to Full Screen
                            GestureDetector(
                              onTap: profile.avatarBase64 != null
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FullScreenImageViewer(
                                            base64Image: profile.avatarBase64,
                                            tag: 'profile_avatar_${widget.targetUid}',
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: Hero(
                                tag: 'profile_avatar_${widget.targetUid}',
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    width: 112,
                                    height: 112,
                                    decoration: BoxDecoration(
                                      color: bgColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: bgColor.withValues(alpha: 0.25), width: 3),
                                      image: profile.avatarBase64 != null
                                          ? DecorationImage(
                                              image: MemoryImage(base64Decode(profile.avatarBase64!)),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: profile.avatarBase64 == null
                                        ? Center(
                                            child: profile.avatar.startsWith('assets/')
                                                ? Image.asset(profile.avatar, width: 68, height: 68)
                                                : Text(profile.avatar, style: const TextStyle(fontSize: 52)),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Display Name
                            Text(
                              profile.name.isNotEmpty ? profile.name : 'Pengguna Zikola',
                              style: AppTheme.heading1.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 6),

                            // Verification & Role Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded, color: Color(0xFF2563EB), size: 15),
                                  SizedBox(width: 6),
                                  Text(
                                    'Member Aktif Zikola',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1D4ED8),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Stats Row (Pengikut, Mengikuti, Poin XP)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildGlassStatCard(
                                    'Pengikut',
                                    followersCount.toString(),
                                    Icons.group_rounded,
                                    const Color(0xFF3B82F6),
                                    () {
                                      final List<String> followers = List.from(profile.followers);
                                      if (isFollowing && appState.uid != null && !followers.contains(appState.uid)) {
                                        followers.add(appState.uid!);
                                      }
                                      Navigator.pushNamed(context, '/follows-screen', arguments: {
                                        'title': 'Pengikut',
                                        'uids': followers,
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildGlassStatCard(
                                    'Mengikuti',
                                    profile.following.length.toString(),
                                    Icons.person_add_alt_1_rounded,
                                    const Color(0xFF10B981),
                                    () {
                                      Navigator.pushNamed(context, '/follows-screen', arguments: {
                                        'title': 'Mengikuti',
                                        'uids': profile.following,
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildGlassStatCard(
                                    'Poin XP',
                                    profile.totalPoints > 0 ? '${profile.totalPoints}' : '150',
                                    Icons.stars_rounded,
                                    const Color(0xFFF59E0B),
                                    () {},
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Action Row: Follow & Sapa Buttons OR Edit Profile if Self
                            if (isSelf)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_circle_rounded, color: Color(0xFF16A34A)),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Ini adalah pratinjau profil publik Anda.',
                                        style: TextStyle(
                                          color: Color(0xFF15803D),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/profile');
                                      },
                                      icon: const Icon(Icons.edit_rounded, size: 14),
                                      label: const Text('Edit Profil'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF16A34A),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        await appState.toggleFollow(widget.targetUid);
                                        if (!mounted) return;
                                        setState(() {});
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isFollowing
                                                  ? 'Berhenti mengikuti ${profile.name}'
                                                  : 'Berhasil mengikuti ${profile.name}! 🎉',
                                            ),
                                            duration: const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      },
                                      icon: Icon(
                                        isFollowing ? Icons.check_circle_rounded : Icons.person_add_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        isFollowing ? 'Mengikuti' : 'Ikuti Pengguna',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isFollowing ? Colors.white : AppTheme.primaryBlue,
                                        foregroundColor: isFollowing ? AppTheme.primaryBlue : Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        elevation: isFollowing ? 0 : 4,
                                        shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.35),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: BorderSide(
                                            color: isFollowing ? const Color(0xFFBFDBFE) : Colors.transparent,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Menyapa ${profile.name}! 👋 Pesan sapaan terkirim.'),
                                            duration: const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.waving_hand_rounded, size: 18, color: Color(0xFFF59E0B)),
                                      label: const Text(
                                        'Sapa',
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF334155)),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Showcase Stiker Section
                    _buildProfileSection(
                      title: 'Pameran Stiker',
                      icon: '🏆',
                      child: profile.showcasedStickers.isNotEmpty
                          ? SizedBox(
                              width: double.infinity,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: profile.showcasedStickers.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final stickerId = entry.value;
                                    final stickerInfo = StickerDatabase.getSticker(stickerId);
                                    final rarity = stickerInfo?.rarity ?? 'Common';
                                    final slotBorderColor = _getSlotBorderColor(rarity);
                                    final slotBgColor = _getSlotBgColor(rarity);

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ShiningStickerSlot(
                                            stickerId: stickerId,
                                            index: index,
                                            onTap: () {
                                              if (stickerInfo != null) {
                                                _showStickerDetailModal(context, stickerInfo);
                                              }
                                            },
                                            isLarge: true,
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: slotBgColor,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: slotBorderColor.withValues(alpha: 0.4),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Text(
                                              rarity.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.5,
                                                color: slotBorderColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: const Center(
                                child: Text(
                                  'Pengguna ini belum memamerkan stiker.',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 28),

                    // MBTI Personality Card Section
                    if (testResults != null && testResults.personality.completed && testResults.personality.type != null)
                      _buildProfileSection(
                        title: 'Kepribadian MBTI',
                        icon: '🎭',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD946EF).withValues(alpha: 0.3),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -20,
                                  top: -20,
                                  child: Icon(Icons.auto_awesome, color: Colors.white.withValues(alpha: 0.12), size: 110),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 68,
                                            height: 68,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _getMBTIEmoji(testResults.personality.type!),
                                                style: const TextStyle(fontSize: 38),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _getMBTIName(testResults.personality.type!),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.25),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    'MBTI: ${testResults.personality.type!}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      // Personality Traits
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: _getMBTITraits(testResults.personality.type!).map((trait) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              '#$trait',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                        ),
                                        child: Text(
                                          _getMBTIDesc(testResults.personality.type!),
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.95),
                                            fontSize: 13,
                                            height: 1.5,
                                            fontWeight: FontWeight.w500,
                                          ),
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

                    // User Recent Community Posts Section (if available)
                    if (userPosts.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _buildProfileSection(
                        title: 'Postingan Komunitas',
                        icon: '💬',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: userPosts.map((post) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFF1F5F9)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              post.category,
                                              style: const TextStyle(
                                                color: Color(0xFF2563EB),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatTime(post.time),
                                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        post.content,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF334155),
                                          height: 1.45,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFEF4444)),
                                          const SizedBox(width: 4),
                                          Text('${post.likes}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF3B82F6)),
                                          const SizedBox(width: 4),
                                          Text('${post.comments}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Fixed Top Navigation Bar (Always Visible, Pinned Above Content)
              _buildFixedTopNav(context, profile.name.isNotEmpty ? profile.name : 'Profil Pengguna'),
            ],
          );
        },
      ),
    );
  }

  // Pinned Top Navigation Bar
  Widget _buildFixedTopNav(BuildContext context, String title) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: topPadding > 0 ? topPadding + 6 : 16,
          left: 16,
          right: 16,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.35),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Pinned High Contrast White Circle Back Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF0F172A),
                    size: 22,
                  ),
                ),
              ),
            ),

            // Center Pill Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('👤', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Share Profile Action Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Tautan profil berhasil disalin! 📋'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.share_rounded,
                    color: Color(0xFF0F172A),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassStatCard(String label, String count, IconData icon, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 6),
            Text(
              count,
              style: AppTheme.heading2.copyWith(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTheme.heading3.copyWith(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }

  Color _getColorFromString(String colorString) {
    if (colorString.startsWith('#')) {
      try {
        return Color(int.parse(colorString.replaceFirst('#', '0xff')));
      } catch (e) {
        return const Color(0xFF3B82F6);
      }
    }
    switch (colorString.toLowerCase()) {
      case 'purple': return const Color(0xFFA855F7);
      case 'green': return const Color(0xFF22C55E);
      case 'orange': return const Color(0xFFF97316);
      case 'pink': return const Color(0xFFEC4899);
      case 'blue': default: return const Color(0xFF3B82F6);
    }
  }

  Color _getSlotBgColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'celestial': return const Color(0xFFF5F3FF); // soft cosmic lavender
      case 'mythical': return const Color(0xFFFEF2F2); // soft red
      case 'legend':
      case 'legendary': return const Color(0xFFFFFBEB); // soft gold
      case 'epic': return const Color(0xFFFAF5FF); // soft purple
      case 'rare': return const Color(0xFFEFF6FF); // soft blue
      default: return const Color(0xFFF8FAFC);
    }
  }

  Color _getSlotBorderColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'celestial': return const Color(0xFF8B5CF6); // vibrant celestial purple!
      case 'mythical': return const Color(0xFFEF4444);
      case 'legend':
      case 'legendary': return const Color(0xFFF59E0B);
      case 'epic': return const Color(0xFFA855F7);
      case 'rare': return const Color(0xFF3B82F6);
      default: return const Color(0xFF94A3B8);
    }
  }

  String _getMBTIEmoji(String type) {
    switch (type.toUpperCase()) {
      case 'ENFJ': return '🦁';
      case 'ENTJ': return '🦅';
      case 'ENFP': return '🐬';
      case 'ENTP': return '🦊';
      case 'ESFJ': return '🦘';
      case 'ESTJ': return '🐘';
      case 'ESFP': return '🦚';
      case 'ESTP': return '🐆';
      case 'INFJ': return '🐼';
      case 'INTJ': return '🦉';
      case 'INFP': return '🐰';
      case 'INTP': return '🐙';
      case 'ISFJ': return '🐻';
      case 'ISTJ': return '🐢';
      case 'ISFP': return '🐱';
      case 'ISTP': return '🐺';
      default: return '🌟';
    }
  }

  List<String> _getMBTITraits(String type) {
    switch (type.toUpperCase()) {
      case 'ENFJ': return ['Hangat', 'Inspiratif', 'Pemimpin'];
      case 'ENTJ': return ['Tegas', 'Visioner', 'Strategis'];
      case 'ENFP': return ['Kreatif', 'Ceria', 'Eksploratif'];
      case 'ENTP': return ['Cerdas', 'Kritis', 'Penuh Ide'];
      case 'ESFJ': return ['Peduli', 'Ramah', 'Suka Menolong'];
      case 'ESTJ': return ['Disiplin', 'Teratur', 'Bertanggung Jawab'];
      case 'ESFP': return ['Ceria', 'Ekspresif', 'Spontan'];
      case 'ESTP': return ['Berani', 'Aktif', 'Cepat Tanggap'];
      case 'INFJ': return ['Bijaksana', 'Peka', 'Idealis'];
      case 'INTJ': return ['Fokus', 'Mandiri', 'Analitis'];
      case 'INFP': return ['Lembut', 'Imajinatif', 'Empatik'];
      case 'INTP': return ['Penasaran', 'Logis', 'Solutif'];
      case 'ISFJ': return ['Setia', 'Penyabar', 'Penyayang'];
      case 'ISTJ': return ['Tekun', 'Jujur', 'Konsisten'];
      case 'ISFP': return ['Artistik', 'Tenang', 'Penuh Kasih'];
      case 'ISTP': return ['Praktis', 'Cekatan', 'Eksplorer'];
      default: return ['Ceria', 'Unik', 'Pintar'];
    }
  }

  String _getMBTIName(String type) {
    switch (type.toUpperCase()) {
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
      default: return 'Penjelajah Cilik';
    }
  }

  String _getMBTIDesc(String type) {
    switch (type.toUpperCase()) {
      case 'ENFJ': return 'Anak yang penuh karisma, empati tinggi, dan mampu menyemangati teman-temannya dalam berbagai aktivitas.';
      case 'ENTJ': return 'Anak yang memiliki jiwa kepemimpinan alami, suka tantangan besar, dan berpikir terstruktur.';
      case 'ENFP': return 'Anak yang penuh imajinasi ceria, antusias mencoba hal-hal baru, dan mudah bergaul.';
      case 'ENTP': return 'Anak yang sangat kritis, suka bertanya alasan di balik segala sesuatu, dan kaya akan solusi inovatif.';
      case 'ESFJ': return 'Anak yang sangat perhatian pada perasaan orang lain, senang berbagi, dan kooperatif dalam kelompok.';
      case 'ESTJ': return 'Anak yang menyukai keteraturan, dapat diandalkan menyelesaikan tugas, dan taat pada aturan positif.';
      case 'ESFP': return 'Anak yang menyebarkan keceriaan di mana saja, suka bergerak aktif, dan menikmati momen bermain bersama.';
      case 'ESTP': return 'Anak yang gesit, pemberani, suka tantangan fisik, dan cepat menemukan cara praktis menyelesaikan masalah.';
      case 'INFJ': return 'Anak yang peka, memiliki pemahaman mendalam tentang lingkungan sekitar, dan suka membantu secara tulus.';
      case 'INTJ': return 'Anak yang mandiri, senang merencanakan sesuatu dengan cermat, dan memiliki rasa ingin tahu intelektual yang tinggi.';
      case 'INFP': return 'Anak yang berhati lembut, memiliki daya cipta cerita yang kaya, dan menghargai nilai-nilai kebaikan.';
      case 'INTP': return 'Anak yang senang mengutak-atik logika, menganalisis cara kerja benda, dan memecahkan teka-teki rumit.';
      case 'ISFJ': return 'Anak yang setia kawan, rajin menjaga barang-barangnya, dan selalu bersedia melindungi sesama.';
      case 'ISTJ': return 'Anak yang tenang, berdisiplin tinggi, dapat dipercaya, dan fokus dalam menyelesaikan apa yang ia mulai.';
      case 'ISFP': return 'Anak yang memiliki kepekaan estetika dan seni yang tinggi, tenang, dan mengekspresikan diri lewat karya visual.';
      case 'ISTP': return 'Anak yang cekatan dalam menggunakan alat/mainan rakitan, tenang menghadapi masalah, dan mandiri.';
      default: return 'Anak yang unik dengan potensi besar dan karakteristik istimewa dalam tumbuh kembangnya.';
    }
  }
}
