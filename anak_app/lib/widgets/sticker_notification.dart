import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';


class StickerNotificationWidget extends StatefulWidget {
  const StickerNotificationWidget({super.key});

  @override
  State<StickerNotificationWidget> createState() => _StickerNotificationWidgetState();
}

class _StickerNotificationWidgetState extends State<StickerNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final sticker = appState.stickerNotification;

    if (sticker != null) {
      _controller.forward(from: 0);
      return Material(
        color: Colors.black54,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text('Stiker Baru!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Text(sticker.emoji, style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  Text(sticker.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(sticker.description,
                      style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRarityColor(sticker.rarity).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(sticker.rarity.toUpperCase(),
                        style: TextStyle(
                            color: _getRarityColor(sticker.rarity),
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => appState.clearStickerNotification(),
                    child: const Text('Keren! 🎯'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common': return Colors.grey;
      case 'rare': return Colors.blue;
      case 'epic': return Colors.purple;
      case 'legend':
      case 'legendary': return Colors.amber;
      case 'mythical': return const Color(0xFFEF4444);
      default: return Colors.grey;
    }
  }
}
