import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/sticker.dart';

class StickerPestaScreen extends StatefulWidget {
  const StickerPestaScreen({super.key});

  @override
  State<StickerPestaScreen> createState() => _StickerPestaScreenState();
}

class _PlacedSticker {
  double scale = 1.0;
  String id;
  String emoji;
  Offset position;

  _PlacedSticker({required this.id, required this.emoji, required this.position, double? scale}) : scale = scale ?? 1.0;
}

class _StickerPestaScreenState extends State<StickerPestaScreen> {
  final List<_PlacedSticker> _placedStickers = [];
  String _selectedBackground = 'Garden';
  
  final Map<String, List<Color>> _backgrounds = {
    'Garden': [const Color(0xFFD9F99D), const Color(0xFF4ADE80)],
    'Ocean': [const Color(0xFFBAE6FD), const Color(0xFF38BDF8)],
    'Space': [const Color(0xFF1E293B), const Color(0xFF0F172A)],
    'Sky': [const Color(0xFFCFFAFE), const Color(0xFF67E8F9)],
  };

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
      onTapDown: (details) {
        // Maybe deselect?
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _backgrounds[_selectedBackground]!,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: _placedStickers.map((ps) => Positioned(
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
              },
              child: Transform.scale(
                scale: ps.scale,
                child: Text(ps.emoji, style: const TextStyle(fontSize: 60)),
              ),
            ),
          )).toList(),
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
                  onTap: () => setState(() => _selectedBackground = bg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Opacity(
                      opacity: _selectedBackground == bg ? 1.0 : 0.4,
                      child: Text(
                        bg == 'Garden' ? '🌳' : (bg == 'Ocean' ? '🌊' : (bg == 'Space' ? '🚀' : '☁️')),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white70),
              onPressed: () => setState(() => _placedStickers.clear()),
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
        height: 120,
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: collectedIds.length,
          itemBuilder: (context, index) {
            final sticker = StickerDatabase.getSticker(collectedIds[index]);
            if (sticker == null) return const SizedBox();
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _placedStickers.add(_PlacedSticker(
                    id: sticker.id,
                    emoji: sticker.emoji,
                    position: const Offset(200, 300),
                  ));
                });
              },
              child: Container(
                width: 80,
                margin: const EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(child: Text(sticker.emoji, style: const TextStyle(fontSize: 40))),
              ),
            );
          },
        ),
      ),
    );
  }
}
