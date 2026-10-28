import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/sticker.dart';
import '../services/audio_service.dart';
import '../widgets/pixel_effect_widget.dart';

class PlacedSticker {
  final String id;
  final String content; // emoji or assetPath
  final bool isEmoji;
  final String? rarity;
  double x;
  double y;
  double scale;

  PlacedSticker({
    required this.id,
    required this.content,
    this.isEmoji = true,
    this.rarity,
    required this.x,
    required this.y,
    this.scale = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'isEmoji': isEmoji,
    'rarity': rarity,
    'x': x,
    'y': y,
    'scale': scale,
  };

  factory PlacedSticker.fromJson(Map<String, dynamic> json) => PlacedSticker(
    id: json['id']?.toString() ?? '',
    content: json['content'] ?? json['assetPath'] ?? '⭐',
    isEmoji: json['isEmoji'] ?? !(json['content'] ?? json['assetPath'] ?? '').toString().contains('/'),
    rarity: json['rarity'] as String?,
    x: (json['x'] as num?)?.toDouble() ?? 50.0,
    y: (json['y'] as num?)?.toDouble() ?? 50.0,
    scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
  );
}

class StickerCollectionScreen extends StatefulWidget {
  const StickerCollectionScreen({super.key});

  @override
  State<StickerCollectionScreen> createState() => _StickerCollectionScreenState();
}

class _StickerCollectionScreenState extends State<StickerCollectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PlacedSticker> _placedStickers = [];
  String _selectedRarityFilter = 'semua';
  String _shopRarityFilter = 'semua';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlacedStickers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlacedStickers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('placed_stickers');
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        setState(() {
          _placedStickers = jsonList.map((e) => PlacedSticker.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading placed stickers: $e');
    }
  }

  Future<void> _savePlacedStickers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String data = jsonEncode(_placedStickers.map((e) => e.toJson()).toList());
      await prefs.setString('placed_stickers', data);
    } catch (e) {
      debugPrint('Error saving placed stickers: $e');
    }
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'celestial': return const Color(0xFF8B5CF6);
      case 'mythical': return const Color(0xFFEF4444);
      case 'legend':
      case 'legendary': return const Color(0xFFF59E0B);
      case 'epic': return const Color(0xFFA855F7);
      case 'rare': return const Color(0xFF3B82F6);
      default: return const Color(0xFF94A3B8);
    }
  }

  String _getRarityLabel(String rarity) {
    switch (rarity) {
      case 'celestial': return '🌌 Celestial';
      case 'mythical': return '🐉 Mythical';
      case 'legend':
      case 'legendary': return '👑 Legend';
      case 'epic': return '💎 Epic';
      case 'rare': return '⭐ Rare';
      default: return '⚪ Common';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final totalPoints = appState.totalPoints;
    final collectedList = appState.collectedStickers;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.gray700),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Toko Stiker',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Koleksi & beli stiker impianmu!',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Points Counter Badge
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '$totalPoints',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Pts',
                  style: TextStyle(
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.gray500,
          indicatorColor: AppTheme.primaryBlue,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('🛒', style: TextStyle(fontSize: 15)),
                  SizedBox(width: 6),
                  Text('Toko'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎒', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 4),
                  Flexible(child: Text('Koleksi (${collectedList.length})', maxLines: 1, overflow: TextOverflow.fade, softWrap: false)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('🎨', style: TextStyle(fontSize: 15)),
                  SizedBox(width: 4),
                  Flexible(child: Text('Scrapbook', maxLines: 1, overflow: TextOverflow.fade, softWrap: false)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShopTab(appState),
          _buildCollectionTab(appState),
          _buildScrapbookTab(appState),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: TOKO STIKER (STICKER SHOP)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildShopTab(AppState appState) {
    final allStickers = StickerDatabase.allStickers;
    final filteredStickers = allStickers.where((s) {
      if (_shopRarityFilter == 'semua') return true;
      if (_shopRarityFilter == 'legendary') return s.rarity == 'legend' || s.rarity == 'legendary';
      return s.rarity == _shopRarityFilter;
    }).toList();

    return Column(
      children: [
        // Rarity Filter Chips
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildShopFilterChip('semua', 'Semua ✨'),
              _buildShopFilterChip('celestial', '🌌 Celestial (1000 Pts)'),
              _buildShopFilterChip('mythical', '🐉 Mythical (300 Pts)'),
              _buildShopFilterChip('legendary', '👑 Legend (40 Pts)'),
              _buildShopFilterChip('epic', '💎 Epic (30 Pts)'),
              _buildShopFilterChip('rare', '⭐ Rare (20 Pts)'),
              _buildShopFilterChip('common', '⚪ Common (10 Pts)'),
            ],
          ),
        ),

        // Stickers Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            itemCount: filteredStickers.length,
            itemBuilder: (context, index) {
              final sticker = filteredStickers[index];
              final isOwned = appState.collectedStickers.contains(sticker.id);
              final canAfford = appState.totalPoints >= sticker.pointCost;

              return _buildShopCard(sticker, isOwned, canAfford, appState);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShopFilterChip(String key, String label) {
    final isSelected = _shopRarityFilter == key;
    final color = key == 'semua' ? AppTheme.primaryBlue : _getRarityColor(key);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _shopRarityFilter = key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.gray200,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : AppTheme.gray700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopCard(StickerInfo sticker, bool isOwned, bool canAfford, AppState appState) {
    final rarity = sticker.rarity;
    final isCelestial = rarity == 'celestial';
    final isMythical = rarity == 'mythical';
    final rarityColor = _getRarityColor(rarity);

    return GestureDetector(
      onTap: () => _showStickerDetailModal(sticker, appState),
      child: Container(
      decoration: BoxDecoration(
        color: isCelestial
            ? const Color(0xFF070913)
            : (isMythical ? const Color(0xFF18181B) : Colors.white),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCelestial
              ? const Color(0xFFC084FC)
              : (isMythical ? const Color(0xFFEF4444) : AppTheme.gray200),
          width: isCelestial ? 2.2 : (isMythical ? 1.8 : 1.2),
        ),
        boxShadow: [
          if (isCelestial) ...[
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
              blurRadius: 18,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFFEC4899).withValues(alpha: 0.2),
              blurRadius: 28,
              spreadRadius: 3,
            ),
          ] else if (isMythical)
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.25),
              blurRadius: 14,
              spreadRadius: 1,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Cosmic Nebula for Celestial
          if (isCelestial)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.0, -0.3),
                      radius: 1.2,
                      colors: [
                        Color(0x558B5CF6),
                        Color(0x35EC4899),
                        Color(0x103B82F6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Twinkling Corner Sparkles for Celestial
          if (isCelestial) ...[
            const Positioned(top: 8, left: 8, child: Text('✨', style: TextStyle(fontSize: 12))),
            const Positioned(top: 8, right: 8, child: Text('🌌', style: TextStyle(fontSize: 12))),
          ],

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rarity Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCelestial
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.35)
                        : rarityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: isCelestial ? Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.6)) : null,
                  ),
                  child: Text(
                    isCelestial ? '🌌 CELESTIAL SUPREME' : _getRarityLabel(rarity),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: isCelestial ? const Color(0xFFA78BFA) : rarityColor,
                      letterSpacing: isCelestial ? 0.5 : 0,
                    ),
                  ),
                ),
                const Spacer(),

                // Big Sticker Emoji with Pixel Effects & Radiant Halo
                Center(
                  child: StickerEffectBadge(
                    emoji: sticker.emoji,
                    rarity: sticker.rarity,
                    emojiSize: isCelestial ? 46 : (isMythical ? 42 : 40),
                    containerSize: 74,
                  ),
                ),
                const Spacer(),

                // Sticker Name
                Text(
                  sticker.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: (isCelestial || isMythical) ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: isCelestial ? 0.3 : 0,
                  ),
                ),
                const SizedBox(height: 3),

                // Description
                Text(
                  sticker.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: (isCelestial || isMythical) ? const Color(0xFFCBD5E1) : AppTheme.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),

                // Action Button
                if (isOwned)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Dimiliki',
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canAfford ? () => _confirmPurchase(sticker, appState) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford
                            ? (isCelestial ? const Color(0xFF8B5CF6) : AppTheme.primaryOrange)
                            : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade200,
                        disabledForegroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: canAfford ? (isCelestial ? 4 : 2) : 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(isCelestial ? '🌌' : '🪙', style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            canAfford ? '${sticker.pointCost} Poin' : '${sticker.pointCost} Pts',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: canAfford ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  void _confirmPurchase(StickerInfo sticker, AppState appState) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sticker.rarity == 'celestial' || sticker.rarity == 'mythical')
              ExplosiveStickerHeader(
                emoji: sticker.emoji,
                rarity: sticker.rarity,
                size: 80,
              )
            else
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _getRarityColor(sticker.rarity).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(sticker.emoji, style: const TextStyle(fontSize: 52)),
              ),
            const SizedBox(height: 16),
            Text(
              'Tukar dengan ${sticker.name}?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              sticker.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Biaya Tukar:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF92400E))),
                  Text('🪙 ${sticker.pointCost} Poin', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFFB45309))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sisa Poin Kamu Nanti:', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                Text('${appState.totalPoints - sticker.pointCost} Pts', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await appState.purchaseSticker(sticker.id);
              if (success) {
                HapticFeedback.heavyImpact();
                AudioService().playCorrect();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Text(sticker.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hore! Stiker Baru Terbuka!', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Kamu berhasil mendapatkan ${sticker.name}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Ya, Tukar Sekarang!'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: KOLEKSI SAYA (MY COLLECTION VAULT)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCollectionTab(AppState appState) {
    final collectedIds = appState.collectedStickers;
    final allStickers = StickerDatabase.allStickers;
    final totalAvailable = allStickers.length;
    final totalOwned = collectedIds.length;
    final percent = totalAvailable > 0 ? (totalOwned / totalAvailable) : 0.0;

    final myStickers = collectedIds
        .map((id) => StickerDatabase.getSticker(id))
        .whereType<StickerInfo>()
        .where((s) {
          if (_selectedRarityFilter == 'semua') return true;
          if (_selectedRarityFilter == 'legendary') return s.rarity == 'legend' || s.rarity == 'legendary';
          return s.rarity == _selectedRarityFilter;
        })
        .toList();

    return Column(
      children: [
        // Vault Progress Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Vault Prestasi Anak',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(percent * 100).toInt()}% Lengkap',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$totalOwned dari $totalAvailable Stiker Terkumpul',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${totalAvailable - totalOwned} Belum Diraih',
                    style: TextStyle(color: Colors.amber.shade400, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filter Bar
        Container(
          height: 48,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCollectionFilterChip('semua', 'Semua'),
              _buildCollectionFilterChip('celestial', '🌌 Celestial'),
              _buildCollectionFilterChip('mythical', '🐉 Mythical'),
              _buildCollectionFilterChip('legendary', '👑 Legend'),
              _buildCollectionFilterChip('epic', '💎 Epic'),
              _buildCollectionFilterChip('rare', '⭐ Rare'),
              _buildCollectionFilterChip('common', '⚪ Common'),
            ],
          ),
        ),

        // Collection Grid
        Expanded(
          child: myStickers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎒', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          _selectedRarityFilter == 'semua'
                              ? 'Belum ada stiker yang kamu miliki'
                              : 'Belum ada stiker $_selectedRarityFilter',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Selesaikan kuis kognitif atau tukar poin di Toko Stiker untuk mendapatkannya!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: myStickers.length,
                  itemBuilder: (context, index) {
                    final sticker = myStickers[index];
                    return _buildMyStickerCard(sticker, appState);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCollectionFilterChip(String key, String label) {
    final isSelected = _selectedRarityFilter == key;
    final color = key == 'semua' ? AppTheme.primaryBlue : _getRarityColor(key);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedRarityFilter = key);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : AppTheme.gray200, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : AppTheme.gray700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyStickerCard(StickerInfo sticker, AppState appState) {
    final rarity = sticker.rarity;
    final isCelestial = rarity == 'celestial';
    final isMythical = rarity == 'mythical';
    final isShowcased = appState.childProfile.showcasedStickers.contains(sticker.id);
    final rarityColor = _getRarityColor(rarity);

    return GestureDetector(
      onTap: () => _showStickerDetailModal(sticker, appState),
      child: Container(
        decoration: BoxDecoration(
          color: isCelestial
              ? const Color(0xFF070913)
              : (isMythical ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCelestial
                ? const Color(0xFFC084FC)
                : (isMythical ? const Color(0xFFEF4444) : (isShowcased ? AppTheme.primaryBlue : AppTheme.gray200)),
            width: isCelestial ? 2.2 : (isShowcased ? 2.5 : 1.5),
          ),
          boxShadow: [
            if (isCelestial) ...[
              BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4), blurRadius: 14, spreadRadius: 2),
              BoxShadow(color: const Color(0xFFEC4899).withValues(alpha: 0.2), blurRadius: 22, spreadRadius: 2.5),
            ] else if (isMythical)
              BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.25), blurRadius: 10)
            else
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (isCelestial)
              const Positioned(top: 6, left: 6, child: Text('✨', style: TextStyle(fontSize: 10))),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StickerEffectBadge(
                    emoji: sticker.emoji,
                    rarity: sticker.rarity,
                    emojiSize: isCelestial ? 36 : (isMythical ? 34 : 32),
                    containerSize: 56,
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      sticker.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: (isCelestial || isMythical) ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: isCelestial ? 0.3 : 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCelestial
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.3)
                          : rarityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: isCelestial ? Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.5)) : null,
                    ),
                    child: Text(
                      isCelestial ? '🌌 CELESTIAL' : rarity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: isCelestial ? const Color(0xFFA78BFA) : rarityColor,
                        letterSpacing: isCelestial ? 0.5 : 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isShowcased)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isCelestial ? const Color(0xFFC084FC) : AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showStickerDetailModal(StickerInfo sticker, AppState appState) {
    HapticFeedback.mediumImpact();
    final isCelestial = sticker.rarity == 'celestial';
    final isMythical = sticker.rarity == 'mythical';
    final rarityColor = _getRarityColor(sticker.rarity);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isCelestial
              ? const Color(0xFF070913)
              : (isMythical ? const Color(0xFF141416) : Colors.white),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: isCelestial
              ? Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4), width: 1.5)
              : (isMythical ? Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4), width: 1.5) : null),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: (isCelestial || isMythical) ? const Color(0xFF334155) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Big Emoji Display with Explosive Pixel Art & Cosmic Halo
            if (isCelestial || isMythical)
              ExplosiveStickerHeader(
                emoji: sticker.emoji,
                rarity: sticker.rarity,
                size: 110,
              )
            else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: rarityColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rarityColor.withValues(alpha: 0.25),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(sticker.emoji, style: const TextStyle(fontSize: 64)),
              ),
            const SizedBox(height: 16),

            Text(
              sticker.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: (isCelestial || isMythical) ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: isCelestial ? 0.5 : 0,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isCelestial
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.25)
                    : (isMythical ? const Color(0xFFEF4444).withValues(alpha: 0.25) : rarityColor.withValues(alpha: 0.12)),
                borderRadius: BorderRadius.circular(14),
                border: isCelestial
                    ? Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.5))
                    : (isMythical ? Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.5)) : null),
              ),
              child: Text(
                isCelestial
                    ? '🌌 KASTA KOSMIK: CELESTIAL (1000 PTS) 🌌'
                    : (isMythical ? '🐉 KASTA LEGENDA: MYTHICAL (300 PTS) 🔥' : _getRarityLabel(sticker.rarity)),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isCelestial
                      ? const Color(0xFFA78BFA)
                      : (isMythical ? const Color(0xFFFCA5A5) : rarityColor),
                  fontSize: 12,
                  letterSpacing: (isCelestial || isMythical) ? 0.5 : 0,
                ),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              sticker.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: (isCelestial || isMythical) ? const Color(0xFFCBD5E1) : Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Showcase on Profile Options
            Text(
              'Pamerkan di Profil Anak:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isCelestial
                    ? const Color(0xFFA78BFA)
                    : (isMythical ? const Color(0xFFFCA5A5) : const Color(0xFF475569)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                final isCurrent = appState.childProfile.showcasedStickers.length > index &&
                    appState.childProfile.showcasedStickers[index] == sticker.id;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    appState.setShowcasedSticker(index, sticker.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Stiker ${sticker.name} dipamerkan di Slot ${index + 1}!'),
                        backgroundColor: isCelestial
                            ? const Color(0xFF8B5CF6)
                            : (isMythical ? const Color(0xFFEF4444) : AppTheme.primaryBlue),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? (isCelestial ? const Color(0xFF8B5CF6) : (isMythical ? const Color(0xFFEF4444) : AppTheme.primaryBlue))
                          : (isCelestial ? const Color(0xFF1E1B4B) : (isMythical ? const Color(0xFF27272A) : Colors.grey.shade100)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrent
                            ? (isCelestial ? const Color(0xFFC084FC) : (isMythical ? const Color(0xFFF87171) : AppTheme.primaryBlue))
                            : (isCelestial ? const Color(0xFF6D28D9) : (isMythical ? const Color(0xFF52525B) : Colors.grey.shade300)),
                        width: 1.5,
                      ),
                      boxShadow: isCurrent && (isCelestial || isMythical) ? [
                        BoxShadow(
                          color: (isCelestial ? const Color(0xFF8B5CF6) : const Color(0xFFEF4444)).withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ] : null,
                    ),
                    child: Text(
                      'Slot ${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: isCurrent ? Colors.white : ((isCelestial || isMythical) ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: SCRAPBOOK KANVAS (INTERACTIVE STICKER COLLAGE)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScrapbookTab(AppState appState) {
    return Stack(
      children: [
        // Canvas Board with Background
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              if (_placedStickers.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('🎨', style: TextStyle(fontSize: 40)),
                        SizedBox(height: 10),
                        Text(
                          'Kanvas Scrapbook Kosong',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ketuk tombol "Tempel Stiker" di bawah untuk menghias kanvasmu!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Placed Stickers List
              ..._placedStickers.map((sticker) {
                return Positioned(
                  left: sticker.x,
                  top: sticker.y,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        sticker.x += details.delta.dx;
                        sticker.y += details.delta.dy;
                      });
                    },
                    onPanEnd: (_) {
                      HapticFeedback.lightImpact();
                      _savePlacedStickers();
                    },
                    onDoubleTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _placedStickers.remove(sticker);
                      });
                      _savePlacedStickers();
                    },
                    child: sticker.isEmoji
                        ? (sticker.rarity == 'celestial' || sticker.rarity == 'mythical')
                            ? StickerEffectBadge(
                                emoji: sticker.content,
                                rarity: sticker.rarity!,
                                emojiSize: 52 * sticker.scale,
                                containerSize: 80 * sticker.scale,
                              )
                            : Container(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  sticker.content,
                                  style: TextStyle(fontSize: 54 * sticker.scale),
                                ),
                              )
                        : Image.asset(
                            sticker.content,
                            width: 100 * sticker.scale,
                            height: 100 * sticker.scale,
                            errorBuilder: (_, _, _) => const Text('⭐', style: TextStyle(fontSize: 48)),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),

        // Clear Canvas Button Top-Right
        if (_placedStickers.isNotEmpty)
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Bersihkan Kanvas?'),
                    content: const Text('Semua stiker yang ditempel akan dihapus dari kanvas.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() => _placedStickers.clear());
                          _savePlacedStickers();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                        child: const Text('Bersihkan', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Bersihkan',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Bottom Add Sticker Floating Button
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Center(
            child: FloatingActionButton.extended(
              onPressed: () => _openScrapbookPicker(appState),
              backgroundColor: AppTheme.primaryOrange,
              elevation: 4,
              icon: const Icon(Icons.add_reaction_outlined, color: Colors.white),
              label: const Text(
                'Tempel Stiker ke Kanvas',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openScrapbookPicker(AppState appState) {
    HapticFeedback.lightImpact();
    final collected = appState.collectedStickers
        .map((id) => StickerDatabase.getSticker(id))
        .whereType<StickerInfo>()
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 14),
            const Text(
              'Pilih Stiker untuk Ditempel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            Text(
              'Pilih dari stiker yang sudah kamu kumpulkan!',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: collected.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔒', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          const Text('Belum ada stiker yang kamu koleksi', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Tukar stiker di Toko Stiker dulu yuk!', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: collected.length,
                      itemBuilder: (context, index) {
                        final sticker = collected[index];
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(ctx);
                            setState(() {
                              _placedStickers.add(PlacedSticker(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                content: sticker.emoji,
                                rarity: sticker.rarity,
                                isEmoji: true,
                                x: MediaQuery.of(context).size.width / 2 - 40,
                                y: MediaQuery.of(context).size.height / 3 - 40,
                              ));
                            });
                            _savePlacedStickers();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: (sticker.rarity == 'celestial' || sticker.rarity == 'mythical')
                                  ? const Color(0xFF0F172A)
                                  : _getRarityColor(sticker.rarity).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (sticker.rarity == 'celestial' || sticker.rarity == 'mythical')
                                    ? (sticker.rarity == 'celestial' ? const Color(0xFFC084FC) : const Color(0xFFEF4444))
                                    : _getRarityColor(sticker.rarity).withValues(alpha: 0.3),
                                width: (sticker.rarity == 'celestial' || sticker.rarity == 'mythical') ? 1.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: (sticker.rarity == 'celestial' || sticker.rarity == 'mythical')
                                  ? StickerEffectBadge(
                                      emoji: sticker.emoji,
                                      rarity: sticker.rarity,
                                      emojiSize: 26,
                                      containerSize: 42,
                                    )
                                  : Text(sticker.emoji, style: const TextStyle(fontSize: 32)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
