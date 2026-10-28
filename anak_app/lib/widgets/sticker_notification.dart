import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'pixel_effect_widget.dart';


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
      final isCelestial = sticker.rarity == 'celestial';
      final isMythical = sticker.rarity == 'mythical';
      final rarityColor = _getRarityColor(sticker.rarity);

      return Material(
        color: Colors.black.withValues(alpha: isCelestial ? 0.75 : 0.54),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.all(28),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isCelestial
                    ? const Color(0xFF090D1A)
                    : (isMythical ? const Color(0xFF18181B) : Colors.white),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isCelestial
                      ? const Color(0xFFC084FC)
                      : (isMythical ? const Color(0xFFEF4444) : Colors.transparent),
                  width: isCelestial ? 2.5 : (isMythical ? 2.0 : 0),
                ),
                boxShadow: [
                  if (isCelestial) ...[
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.25),
                      blurRadius: 50,
                      spreadRadius: 8,
                    ),
                  ] else if (isMythical)
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 2,
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Celestial Star Twinkles
                  if (isCelestial) ...[
                    const Positioned(top: -12, left: -10, child: Text('✨', style: TextStyle(fontSize: 24))),
                    const Positioned(top: -10, right: -8, child: Text('🌌', style: TextStyle(fontSize: 22))),
                    const Positioned(bottom: -8, left: -6, child: Text('✦', style: TextStyle(fontSize: 20, color: Color(0xFFA78BFA)))),
                    const Positioned(bottom: -10, right: -6, child: Text('🌠', style: TextStyle(fontSize: 24))),
                  ],

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isCelestial ? '🌌' : '🎉', style: const TextStyle(fontSize: 44)),
                      const SizedBox(height: 8),
                      Text(
                        isCelestial ? 'KASTA CELESTIAL TERBUKA!' : 'Stiker Baru Terbuka!',
                        style: TextStyle(
                          fontSize: isCelestial ? 20 : 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: isCelestial ? 0.5 : 0,
                          color: isCelestial
                              ? const Color(0xFFE2E8F0)
                              : (isMythical ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Big Explosive Pixel Art Header for Mythic & Celestial
                      if (isCelestial || isMythical)
                        ExplosiveStickerHeader(
                          emoji: sticker.emoji,
                          rarity: sticker.rarity,
                          size: 110,
                        )
                      else
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: rarityColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Text(sticker.emoji, style: const TextStyle(fontSize: 64)),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),

                      Text(
                        sticker.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: (isCelestial || isMythical) ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          sticker.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isCelestial
                                ? const Color(0xFFCBD5E1)
                                : (isMythical ? Colors.grey.shade400 : Colors.grey.shade600),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Rarity Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: isCelestial
                              ? const Color(0xFF8B5CF6).withValues(alpha: 0.25)
                              : rarityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: isCelestial
                              ? Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.5))
                              : null,
                        ),
                        child: Text(
                          isCelestial ? '🌌 CELESTIAL SUPREME' : sticker.rarity.toUpperCase(),
                          style: TextStyle(
                            color: isCelestial ? const Color(0xFFA78BFA) : rarityColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => appState.clearStickerNotification(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCelestial
                                ? const Color(0xFF8B5CF6)
                                : (isMythical ? const Color(0xFFEF4444) : const Color(0xFF2563EB)),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: isCelestial ? 4 : 2,
                          ),
                          child: Text(
                            isCelestial ? 'Klaim Kemegahan Kosmik! 🌌' : 'Keren! 🎯',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
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
      case 'celestial': return const Color(0xFF8B5CF6);
      case 'mythical': return const Color(0xFFEF4444);
      case 'legend':
      case 'legendary': return const Color(0xFFF59E0B);
      case 'epic': return const Color(0xFFA855F7);
      case 'rare': return const Color(0xFF3B82F6);
      case 'common': return Colors.grey;
      default: return Colors.grey;
    }
  }
}
