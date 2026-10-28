import '../widgets/space_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../models/sticker.dart';
import '../widgets/pixel_effect_widget.dart';

class StickerPestaScreen extends StatefulWidget {
  const StickerPestaScreen({super.key});

  @override
  State<StickerPestaScreen> createState() => _StickerPestaScreenState();
}

class _PlacedSticker {
  double scale = 1.0;
  String id;
  String emoji;
  String? imageAsset;
  String? rarity;
  Offset position;

  _PlacedSticker({
    required this.id,
    required this.emoji,
    required this.position,
    this.imageAsset,
    this.rarity,
    double? scale,
  }) : scale = scale ?? 1.0;
}

class _StickerPestaScreenState extends State<StickerPestaScreen> {
  final List<_PlacedSticker> _placedStickers = [];
  String _selectedBackground = 'Garden';
  
  final Map<String, List<Color>> _backgrounds = {
    'Garden': [const Color(0xFFD9F99D), const Color(0xFF4ADE80)],
    'Desert': [const Color(0xFFFDE68A), const Color(0xFFF59E0B)],
    'Space': [const Color(0xFF1E293B), const Color(0xFF0F172A)],
    'Sky': [const Color(0xFFCFFAFE), const Color(0xFF67E8F9)],
  };

  final List<Map<String, String>> _specialAssetStickers = [
    {'id': 'char_green', 'name': 'Si Hijau', 'asset': 'assets/images/characters/character_round_green.png'},
    {'id': 'char_purple', 'name': 'Si Ungu', 'asset': 'assets/images/characters/character_round_purple.png'},
    {'id': 'char_red', 'name': 'Si Merah', 'asset': 'assets/images/characters/character_round_red.png'},
    {'id': 'char_yellow', 'name': 'Si Kuning', 'asset': 'assets/images/characters/character_round_yellow.png'},
    {'id': 'fox_3d', 'name': 'Rubah', 'asset': 'assets/images/emoji/animals/fox.png'},
    {'id': 'lion_3d', 'name': 'Singa', 'asset': 'assets/images/emoji/animals/lion.png'},
    {'id': 'elephant_3d', 'name': 'Gajah', 'asset': 'assets/images/emoji/animals/elephant.png'},
    {'id': 'bee_3d', 'name': 'Lebah', 'asset': 'assets/images/emoji/animals/bee.png'},
    {'id': 'panda_3d', 'name': 'Panda', 'asset': 'assets/images/emoji/animals/panda.png'},
    {'id': 'dragon_3d', 'name': 'Naga', 'asset': 'assets/images/emoji/animals/dragon.png'},
    {'id': 'unicorn_3d', 'name': 'Kuda Poni', 'asset': 'assets/images/emoji/animals/unicorn.png'},
    {'id': 'star_3d', 'name': 'Bintang', 'asset': 'assets/images/emoji/rewards/star.png'},
    {'id': 'trophy_3d', 'name': 'Piala', 'asset': 'assets/images/emoji/rewards/trophy.png'},
    {'id': 'crown_3d', 'name': 'Mahkota', 'asset': 'assets/images/emoji/rewards/crown.png'},
    {'id': 'gem_3d', 'name': 'Permata', 'asset': 'assets/images/emoji/rewards/gem.png'},
    {'id': 'rocket_3d', 'name': 'Roket', 'asset': 'assets/images/emoji/objects/rocket.png'},
    {'id': 'castle_kenney', 'name': 'Kastil', 'asset': 'assets/images/items/castle.png'},
    {'id': 'sword_kenney', 'name': 'Pedang', 'asset': 'assets/images/items/item_sword.png'},
    {'id': 'shield_kenney', 'name': 'Perisai', 'asset': 'assets/images/items/item_shield.png'},
  ];

  @override
  void initState() {
    super.initState();
    AudioService().playHomeBGM();
  }

  @override
  void dispose() {
    AudioService().stopBGM();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final collected = appState.collectedStickers;

    return Scaffold(
      body: Stack(
        children: [
          // Canvas
          _buildCanvas(),
          
          // Header
          _buildHeader(),
          
          // Sticker Selector
          _buildStickerSelector(collected),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return GestureDetector(
      onTapDown: (details) {},
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _backgrounds[_selectedBackground] ?? [const Color(0xFFD9F99D), const Color(0xFF4ADE80)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Ambient Backdrop Texture
            if (_selectedBackground == 'Desert')
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15,
                  child: Image.asset('assets/images/backgrounds/desert_ground.png', fit: BoxFit.cover),
                ),
              ),
            if (_selectedBackground == 'Space')
              const Positioned.fill(child: SpaceBackground()),

            ..._placedStickers.map((ps) => Positioned(
              left: ps.position.dx - 40,
              top: ps.position.dy - 40,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    ps.position += details.delta;
                  });
                },
                onLongPress: () {
                  setState(() {
                    _placedStickers.remove(ps);
                  });
                  AudioService().playSwish();
                },
                child: Transform.scale(
                  scale: ps.scale,
                  child: ps.imageAsset != null
                      ? Image.asset(ps.imageAsset!, width: 75, height: 75, fit: BoxFit.contain)
                      : (ps.rarity == 'celestial' || ps.rarity == 'mythical')
                          ? StickerEffectBadge(
                              emoji: ps.emoji,
                              rarity: ps.rarity!,
                              emojiSize: 48,
                              containerSize: 76,
                            )
                          : Text(ps.emoji, style: const TextStyle(fontSize: 60)),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: _backgrounds.keys.map((bg) => GestureDetector(
                  onTap: () {
                    AudioService().playClick();
                    setState(() => _selectedBackground = bg);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Opacity(
                      opacity: _selectedBackground == bg ? 1.0 : 0.4,
                      child: Text(
                        bg == 'Garden' ? '🌳' : (bg == 'Desert' ? '🏜️' : (bg == 'Space' ? '🚀' : '☁️')),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white70),
              onPressed: () {
                AudioService().playSwish();
                setState(() => _placedStickers.clear());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerSelector(List<String> collectedIds) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 110,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          children: [
            // 2D & 3D Special Pack Stickers
            ..._specialAssetStickers.map((item) => GestureDetector(
              onTap: () {
                AudioService().playPop();
                setState(() {
                  _placedStickers.add(_PlacedSticker(
                    id: item['id']!,
                    emoji: '⭐',
                    imageAsset: item['asset']!,
                    position: const Offset(180, 260),
                  ));
                });
              },
              child: Container(
                width: 74,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Center(
                  child: Image.asset(item['asset']!, fit: BoxFit.contain),
                ),
              ),
            )),

            // Collected emoji stickers
            ...collectedIds.map((id) {
              final sticker = StickerDatabase.getSticker(id);
              if (sticker == null) return const SizedBox();
              final isCelestial = sticker.rarity == 'celestial';
              final isMythical = sticker.rarity == 'mythical';
              return GestureDetector(
                onTap: () {
                  AudioService().playPop();
                  setState(() {
                    _placedStickers.add(_PlacedSticker(
                      id: sticker.id,
                      emoji: sticker.emoji,
                      rarity: sticker.rarity,
                      position: const Offset(180, 260),
                    ));
                  });
                },
                child: Container(
                  width: 74,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isCelestial
                        ? const Color(0xFF0F172A)
                        : (isMythical ? const Color(0xFF1E1E1E) : Colors.blue.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isCelestial
                          ? const Color(0xFFC084FC)
                          : (isMythical ? const Color(0xFFEF4444) : Colors.transparent),
                      width: isCelestial || isMythical ? 1.5 : 0,
                    ),
                  ),
                  child: Center(
                    child: (isCelestial || isMythical)
                        ? StickerEffectBadge(
                            emoji: sticker.emoji,
                            rarity: sticker.rarity,
                            emojiSize: 32,
                            containerSize: 48,
                          )
                        : Text(sticker.emoji, style: const TextStyle(fontSize: 36)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
