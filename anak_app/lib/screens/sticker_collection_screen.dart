import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/sticker.dart';
import '../theme/app_theme.dart';

class StickerCollectionScreen extends StatefulWidget {
  const StickerCollectionScreen({super.key});

  @override
  State<StickerCollectionScreen> createState() => _StickerCollectionScreenState();
}

class _StickerCollectionScreenState extends State<StickerCollectionScreen> with TickerProviderStateMixin {
  String _selectedCategory = 'all';
  late AnimationController _glowController;
  late AnimationController _mythicPulseController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _mythicPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _mythicPulseController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'achievement',
      'title': 'Achievement',
      'icon': '🏆',
      'color': Colors.amber,
      'stickers': [
        'cognitive-test-complete', 'logic-master', 'attention-expert', 'memory-champion',
        'linguistic-test-complete', 'receptive-master', 'expressive-star', 'phonemic-expert',
        'animal-mbti-complete', 'alien-test-complete'
      ]
    },
    {
      'id': 'game',
      'title': 'Games',
      'icon': '🎮',
      'color': Colors.green,
      'stickers': [
        'memory-master', 'word-master', 'number-master', 'number-explorer', 'pattern-master',
        'pattern-explorer', 'puzzle-master', 'artist-star', 'motor-master', 'motor-star',
        'motor-participant', 'tips-explorer', 'cognitive-shooter', 'math-sharpshooter',
        'target-master', 'level-champion', 'alien-hunter', 'alien-master', 'space-commander',
        'galaxy-champion', 'level-master', 'desert-commander', 'logic-genius', 'abstract-master',
        'reasoning-expert', 'tank-destroyer', 'desert-survivor', 'road-master', 'road-champion',
        'story-builder', 'sentence-master', 'story-teller', 'grammar-expert', 'story-builder-complete'
      ]
    },
    {
      'id': 'character',
      'title': 'Characters',
      'icon': '🐼',
      'color': Colors.purple,
      'stickers': [
        'panda-buddy', 'unicorn-magic', 'cool-penguin', 'tiger-champ', 'happy-frog'
      ]
    },
    {
      'id': 'progress',
      'title': 'Progress',
      'icon': '📈',
      'color': Colors.blue,
      'stickers': [
        'level-up', 'first-test', 'five-days-streak', 'hot-streak', 'all-tests-done'
      ]
    },
    {
      'id': 'mythical',
      'title': 'Mythical',
      'icon': '👑',
      'color': const Color(0xFFEF4444),
      'stickers': [
        'dragon-emperor', 'phoenix-soul', 'cosmic-crystal', 'eternal-crown', 'supernova-star'
      ]
    }
  ];

  Map<String, dynamic> _getRarityStyle(String rarity) {
    switch (rarity) {
      case 'common':
        return {
          'border': const Color(0xFFE2E8F0), 
          'bg': Colors.white,
          'badgeBg': const Color(0xFF94A3B8), 
          'text': Colors.white,
          'lockedBadgeBg': const Color(0xFFE2E8F0), 
          'lockedText': const Color(0xFF64748B),
          'iconColor': const Color(0xFF64748B),
        };
      case 'rare':
        return {
          'border': const Color(0xFFBFDBFE), 
          'bg': const Color(0xFFEFF6FF),
          'badgeBg': const Color(0xFF3B82F6), 
          'text': Colors.white,
          'lockedBadgeBg': const Color(0xFFDBEAFE), 
          'lockedText': const Color(0xFF1E40AF),
          'iconColor': const Color(0xFF2563EB),
          'gradient': const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)]),
        };
      case 'epic':
        return {
          'border': const Color(0xFFE9D5FF), 
          'bg': const Color(0xFFFAF5FF),
          'badgeBg': const Color(0xFF8B5CF6), 
          'text': Colors.white,
          'lockedBadgeBg': const Color(0xFFF3E8FF), 
          'lockedText': const Color(0xFF6B21A8),
          'iconColor': const Color(0xFF9333EA),
          'gradient': const LinearGradient(colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)]),
          'badgeGradient': const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
        };
      case 'legend':
      case 'legendary':
        return {
          'border': const Color(0xFFFEF3C7),
          'bg': const Color(0xFFFFFBEB),
          'badgeBg': const Color(0xFFF59E0B),
          'text': Colors.white,
          'lockedBadgeBg': const Color(0xFFFEF3C7), 'lockedText': const Color(0xFF92400E),
          'iconColor': const Color(0xFFD97706),
          'gradient': const LinearGradient(
            colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'badgeGradient': const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'lockedBadgeGradient': const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
        };
      case 'mythical':
        return {
          'border': const Color(0xFFEF4444), // Red-500
          'bg': const Color(0xFFFEF2F2), // Red-50
          'badgeBg': const Color(0xFFDC2626), // Red-600
          'text': Colors.white,
          'lockedBadgeBg': const Color(0xFFFEE2E2), // Red-100
          'lockedText': const Color(0xFF991B1B), // Red-800
          'iconColor': const Color(0xFFEF4444),
          'gradient': const LinearGradient(
            colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'badgeGradient': const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFF991B1B), Color(0xFF450A0A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'glow': const Color(0xFFEF4444),
        };
      default:
        return {
          'border': Colors.grey.shade300, 'bg': Colors.grey.shade50,
          'badgeBg': Colors.grey.shade500, 'text': Colors.white,
          'lockedBadgeBg': const Color(0xFFB0BEC5), 'lockedText': const Color(0xFF37474F),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final collectedStickers = appState.collectedStickers;

    // Build the full sticker list mapping
    List<StickerInfo> allStickers = [];
    if (_selectedCategory == 'all') {
      for (var cat in _categories) {
        for (var sid in cat['stickers']) {
          final s = StickerDatabase.getSticker(sid);
          if (s != null) allStickers.add(s);
        }
      }
    } else {
      final cat = _categories.firstWhere((c) => c['id'] == _selectedCategory);
      for (var sid in cat['stickers']) {
        final s = StickerDatabase.getSticker(sid);
        if (s != null) allStickers.add(s);
      }
    }

    final totalStickers = StickerDatabase.stickers.length;
    final earnedCount = collectedStickers.length;
    final completionPercentage = totalStickers > 0 ? (earnedCount / totalStickers * 100).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          // Elegant Header
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF8B5CF6),
            title: const Text('Koleksi Stiker', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF472B6), Color(0xFFA855F7), Color(0xFF6366F1)], // pink to purple to indigo
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50, left: 24, right: 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$earnedCount/$totalStickers',
                                        style: AppTheme.heading1.copyWith(color: Colors.white, fontSize: 32),
                                      ),
                                      Text(
                                        'Stiker Terkumpul',
                                        style: AppTheme.bodyText.copyWith(color: Colors.pink.shade100),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(child: Icon(Icons.emoji_events, color: Colors.white, size: 32)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: completionPercentage / 100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Progress Koleksi', style: TextStyle(color: Colors.pink.shade100, fontSize: 12)),
                                  Text('$completionPercentage% Lengkap', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          appState.totalPoints.toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Category Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('all', 'Semua', '✨', Colors.purple),
                        ..._categories.map((c) => _buildCategoryChip(c['id'], c['title'], c['icon'], c['color'])).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Empty State OR Grid
                  allStickers.isEmpty
                      ? const Center(child: Text("Tidak ada stiker di kategori ini."))
                      : collectedStickers.isEmpty && _selectedCategory == 'all'
                          ? _buildEmptyState()
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.88, // Wider cards
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                              ),
                              itemCount: allStickers.length,
                              itemBuilder: (context, index) {
                                final sticker = allStickers[index];
                                final isEarned = collectedStickers.contains(sticker.id);
                                return _buildStickerCard(sticker, isEarned);
                              },
                            ),

                  // Celebration milestone
                  if (completionPercentage >= 25)
                    Container(
                      margin: const EdgeInsets.only(top: 32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.orange.shade500]),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text(
                            'Hebat! Kamu Collector Sejati!',
                            style: AppTheme.heading3.copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            completionPercentage >= 75 ? 'Master Collector!' : completionPercentage >= 50 ? 'Great Collector!' : 'Good Collector!',
                            style: AppTheme.bodyText.copyWith(color: Colors.orange.shade50),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String id, String title, String icon, Color primaryColor) {
    bool isSelected = _selectedCategory == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200),
          boxShadow: isSelected
              ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerCard(StickerInfo sticker, bool isEarned) {
    final style = _getRarityStyle(sticker.rarity);
    final rarityName = sticker.rarity.toUpperCase();
    final isMythical = sticker.rarity == 'mythical';
    final isLegendary = sticker.rarity == 'legend' || sticker.rarity == 'legendary';
    final isPremium = isMythical || isLegendary || sticker.rarity == 'epic';

    return AnimatedBuilder(
      animation: isMythical ? _mythicPulseController : _glowController,
      builder: (context, _) {
        final pulseVal = isMythical ? _mythicPulseController.value : _glowController.value;

        Widget card = Container(
          decoration: BoxDecoration(
            color: isEarned ? style['bg'] : Colors.white,
            gradient: isEarned && style['gradient'] != null ? style['gradient'] : null,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isEarned
              ? (isMythical
                  ? Color.lerp(const Color(0xFFEF4444), const Color(0xFFFF6B6B), pulseVal)!
                  : style['border'])
              : const Color(0xFFF1F5F9),
          width: isEarned
              ? (isMythical ? 4.0 + 2.0 * pulseVal : (isPremium ? 3.0 : 2.5))
              : 1.5,
        ),
            boxShadow: isEarned ? [
              BoxShadow(
                color: (style['iconColor'] as Color).withOpacity(
                    isMythical ? (0.3 + 0.4 * pulseVal) : (isPremium ? 0.15 : 0.08)),
                blurRadius: isMythical ? (16 + 20 * pulseVal) : (isPremium ? 14 : 8),
                spreadRadius: isMythical ? (2 + 4 * pulseVal) : 0,
                offset: const Offset(0, 4),
              ),
              if (isMythical)
                BoxShadow(
                  color: const Color(0xFFFF4444).withOpacity(0.2 * pulseVal),
                  blurRadius: 30,
                  spreadRadius: 6 * pulseVal,
                ),
            ] : [],
          ),
          child: Stack(
            children: [
              // Mythical shimmer overlay
              if (isEarned && isMythical)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Transform.translate(
                      offset: Offset(pulseVal * 250 - 125, -80 + pulseVal * 160),
                      child: Transform.rotate(
                        angle: 0.6,
                        child: Container(
                          width: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(0.25 * pulseVal),
                                Colors.red.withOpacity(0.08 * pulseVal),
                                Colors.white.withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Rarity Badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isEarned
                        ? (style['badgeGradient'] == null ? style['badgeBg'] : null)
                        : (style['lockedBadgeGradient'] == null ? style['lockedBadgeBg'] : null),
                    gradient: isEarned ? (style['badgeGradient'] as Gradient?) : (style['lockedBadgeGradient'] as Gradient?),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isEarned && isMythical
                        ? [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.4 * pulseVal), blurRadius: 6, spreadRadius: 1)]
                        : (isEarned ? [BoxShadow(color: (style['badgeBg'] as Color).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : []),
                  ),
                  child: Text(
                    rarityName,
                    style: TextStyle(
                      color: isEarned ? style['text'] : style['lockedText'],
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),

              // Earned Star
              if (isEarned)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                    ),
                    child: Center(child: Icon(Icons.star_rounded, color: style['iconColor'] as Color, size: 16)),
                  ),
                ),

              // Main Content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 30, 10, 10), // Reduced from 12, 38, 12, 12
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      // Emoji with glow background
                      Container(
                        width: 72,  // Reduced from 76
                        height: 72, // Reduced from 76
                        alignment: Alignment.center,
                        decoration: isEarned
                            ? BoxDecoration(
                                color: (style['iconColor'] as Color).withOpacity(isMythical ? 0.12 + 0.08 * pulseVal : 0.08),
                                shape: BoxShape.circle,
                                boxShadow: isMythical
                                    ? [
                                        BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.25 * pulseVal), blurRadius: 18, spreadRadius: 4),
                                        BoxShadow(color: Colors.white.withOpacity(0.3 * pulseVal), blurRadius: 10),
                                      ]
                                    : [],
                              )
                            : null,
                        child: Text(
                          isEarned ? sticker.emoji : '🔒',
                          style: TextStyle(
                            fontSize: isEarned ? 42 : 30, // Reduced from 44 : 32
                            shadows: isEarned
                                ? [
                                    Shadow(color: (style['iconColor'] as Color).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                                    if (isMythical) Shadow(color: Colors.white.withOpacity(0.5 * pulseVal), blurRadius: 20),
                                  ]
                                : [],
                          ),
                        ),
                      ),
                      const Spacer(flex: 1),

                      // Title
                      Text(
                        isEarned ? sticker.name : 'Terkunci',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: isEarned ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2), // Reduced from 4

                      // Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          isEarned ? sticker.description : 'Selesaikan tantangan!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            color: isEarned ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(flex: 2),

                      if (!isEarned) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 2), // Reduced from 6
                          decoration: BoxDecoration(
                            color: style['lockedBadgeBg'],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('⭐', style: TextStyle(fontSize: 10)),
                              const SizedBox(width: 4),
                              Text(
                                sticker.pointCost.toString(),
                                style: TextStyle(
                                  color: style['lockedText'],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Mythical sparkle particles
              if (isEarned && isMythical) ...[
                Positioned(
                  top: 18 + 8 * pulseVal, left: 20,
                  child: Text('✦', style: TextStyle(fontSize: 8, color: Colors.red.withOpacity(0.6 * pulseVal))),
                ),
                Positioned(
                  bottom: 24 - 4 * pulseVal, right: 16,
                  child: Text('✦', style: TextStyle(fontSize: 10, color: Colors.amber.withOpacity(0.5 * pulseVal))),
                ),
                Positioned(
                  top: 60, right: 12 + 6 * pulseVal,
                  child: Text('✧', style: TextStyle(fontSize: 7, color: Colors.orange.withOpacity(0.4 * pulseVal))),
                ),
              ],
            ],
          ),
        );

        // Click to purchase if not earned
        if (!isEarned) {
          card = GestureDetector(
            onTap: () => _showPurchaseDialog(context, sticker),
            child: Opacity(opacity: 0.75, child: card),
          );
        }

        return card;
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Stiker Terkumpul',
            style: AppTheme.heading2.copyWith(color: AppTheme.gray900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai mengerjakan tes dan game untuk mengumpulkan stiker keren!',
            style: AppTheme.bodyText.copyWith(color: AppTheme.gray600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Mulai Kumpulkan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, StickerInfo sticker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Beli Stiker Baru 🎯'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Text(sticker.emoji, style: const TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 16),
            Text(
              'Apakah kamu ingin membeli stiker "${sticker.name}" seharga ${sticker.pointCost} poin?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final appState = context.read<AppState>();
              if (appState.totalPoints >= sticker.pointCost) {
                final success = await appState.purchaseSticker(sticker.id);
                if (success) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 Hore! "${sticker.name}" berhasil didapatkan!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              } else {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('⚠️ Poin tidak cukup! Selesaikan tantangan dulu yuk!'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Beli Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
