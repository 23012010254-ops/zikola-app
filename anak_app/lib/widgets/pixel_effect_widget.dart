import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Komponen pemutar sekuens frame animasi pixel art retro berkecepatan tinggi.
class PixelSpriteAnimation extends StatefulWidget {
  final List<String> framePaths;
  final Duration duration;
  final bool loop;
  final Duration? loopDelay;
  final double? width;
  final double? height;
  final BoxFit fit;
  final VoidCallback? onCompleted;
  final Color? color;
  final BlendMode? blendMode;

  const PixelSpriteAnimation({
    super.key,
    required this.framePaths,
    this.duration = const Duration(milliseconds: 750),
    this.loop = true,
    this.loopDelay,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.onCompleted,
    this.color,
    this.blendMode,
  });

  /// Factory untuk ledakan kosmik violet Celestial (10 frames)
  static PixelSpriteAnimation celestialBurst({
    Key? key,
    double size = 96,
    bool loop = true,
    Duration? loopDelay = const Duration(milliseconds: 600),
    Duration duration = const Duration(milliseconds: 700),
    VoidCallback? onCompleted,
  }) {
    final frames = List.generate(
      10,
      (i) => 'assets/images/effects/celestial_burst/frame${i.toString().padLeft(4, '0')}.png',
    );
    return PixelSpriteAnimation(
      key: key,
      framePaths: frames,
      duration: duration,
      loop: loop,
      loopDelay: loopDelay,
      width: size,
      height: size,
      onCompleted: onCompleted,
    );
  }

  /// Factory untuk kilat magis violet Celestial (8 frames)
  static PixelSpriteAnimation celestialLightning({
    Key? key,
    double size = 80,
    bool loop = true,
    Duration? loopDelay = const Duration(milliseconds: 800),
    Duration duration = const Duration(milliseconds: 550),
    VoidCallback? onCompleted,
  }) {
    final frames = List.generate(
      8,
      (i) => 'assets/images/effects/celestial_lightning/frame${i.toString().padLeft(4, '0')}.png',
    );
    return PixelSpriteAnimation(
      key: key,
      framePaths: frames,
      duration: duration,
      loop: loop,
      loopDelay: loopDelay,
      width: size,
      height: size,
      onCompleted: onCompleted,
    );
  }

  /// Factory untuk ledakan api epik Mythical (13 frames)
  static PixelSpriteAnimation mythicExplosion({
    Key? key,
    double size = 96,
    bool loop = true,
    Duration? loopDelay = const Duration(milliseconds: 500),
    Duration duration = const Duration(milliseconds: 800),
    VoidCallback? onCompleted,
  }) {
    final frames = List.generate(
      13,
      (i) => 'assets/images/effects/mythic_explosion/frame${i.toString().padLeft(4, '0')}.png',
    );
    return PixelSpriteAnimation(
      key: key,
      framePaths: frames,
      duration: duration,
      loop: loop,
      loopDelay: loopDelay,
      width: size,
      height: size,
      onCompleted: onCompleted,
    );
  }

  /// Factory untuk pendar partikel emas berkilau (24 frames)
  static PixelSpriteAnimation sparkleGold({
    Key? key,
    double size = 70,
    bool loop = true,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    final frames = List.generate(
      24,
      (i) => 'assets/images/effects/sparkle_gold/frame${i.toString().padLeft(4, '0')}.png',
    );
    return PixelSpriteAnimation(
      key: key,
      framePaths: frames,
      duration: duration,
      loop: loop,
      width: size,
      height: size,
    );
  }

  @override
  State<PixelSpriteAnimation> createState() => _PixelSpriteAnimationState();
}

class _PixelSpriteAnimationState extends State<PixelSpriteAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _delayTimer;
  bool _isInDelay = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.loop) {
          if (widget.loopDelay != null && widget.loopDelay! > Duration.zero) {
            setState(() => _isInDelay = true);
            _delayTimer = Timer(widget.loopDelay!, () {
              if (mounted) {
                setState(() => _isInDelay = false);
                _controller.forward(from: 0.0);
              }
            });
          } else {
            _controller.forward(from: 0.0);
          }
        } else {
          widget.onCompleted?.call();
        }
      }
    });

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant PixelSpriteAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.framePaths.isEmpty || _isInDelay) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final frameCount = widget.framePaths.length;
        int frameIndex = (_controller.value * frameCount).floor();
        if (frameIndex >= frameCount) {
          frameIndex = frameCount - 1;
        }

        final path = widget.framePaths[frameIndex];
        return Image.asset(
          path,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          filterQuality: FilterQuality.none, // Pixel art tetap tajam & retro
          color: widget.color,
          colorBlendMode: widget.blendMode,
        );
      },
    );
  }
}

/// Badge komposit untuk stiker kasta Mythical & Celestial dengan aura & efek pixel art dinamis
class StickerEffectBadge extends StatelessWidget {
  final String emoji;
  final String rarity;
  final double emojiSize;
  final double containerSize;
  final bool showEffects;

  const StickerEffectBadge({
    super.key,
    required this.emoji,
    required this.rarity,
    this.emojiSize = 46,
    this.containerSize = 82,
    this.showEffects = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCelestial = rarity == 'celestial';
    final isMythical = rarity == 'mythical';

    if (!showEffects || (!isCelestial && !isMythical)) {
      return SizedBox(
        width: containerSize,
        height: containerSize,
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: emojiSize),
          ),
        ),
      );
    }

    if (isCelestial) {
      return SizedBox(
        width: containerSize + 16,
        height: containerSize + 16,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1. Soft Cosmic Nebula Gradient Aura
            Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                    const Color(0xFFC084FC).withValues(alpha: 0.25),
                    const Color(0xFF38BDF8).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // 2. Animated Pixel Art Celestial Cosmic Burst Behind Emoji
            Positioned(
              child: Opacity(
                opacity: 0.85,
                child: PixelSpriteAnimation.celestialBurst(
                  size: containerSize + 14,
                  loop: true,
                  loopDelay: const Duration(milliseconds: 700),
                ),
              ),
            ),

            // 3. Subtle Lightning Flash in corner
            Positioned(
              top: -4,
              right: -4,
              child: Opacity(
                opacity: 0.75,
                child: PixelSpriteAnimation.celestialLightning(
                  size: containerSize * 0.45,
                  loop: true,
                  loopDelay: const Duration(milliseconds: 1400),
                ),
              ),
            ),

            // 4. Central Emoji with slight 3D shadow
            Text(
              emoji,
              style: TextStyle(
                fontSize: emojiSize,
                shadows: const [
                  Shadow(
                    color: Color(0xFF7C3AED),
                    blurRadius: 16,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),

            // 5. Tiny Floating Celestial Sparkle
            const Positioned(
              bottom: 2,
              left: 2,
              child: Text('✦', style: TextStyle(fontSize: 10, color: Color(0xFFE9D5FF))),
            ),
          ],
        ),
      );
    }

    // Mythical: Dragon & Phoenix Fiery Explosion Effect
    return SizedBox(
      width: containerSize + 16,
      height: containerSize + 16,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Warm Fiery Ember Halo
          Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFEF4444).withValues(alpha: 0.45),
                  const Color(0xFFF97316).withValues(alpha: 0.25),
                  const Color(0xFFFBBF24).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // 2. Animated Pixel Art Fiery Explosion Behind Emoji
          Positioned(
            child: Opacity(
              opacity: 0.88,
              child: PixelSpriteAnimation.mythicExplosion(
                size: containerSize + 12,
                loop: true,
                loopDelay: const Duration(milliseconds: 600),
              ),
            ),
          ),

          // 3. Gold Sparkle Aura
          Positioned(
            bottom: -2,
            right: -2,
            child: Opacity(
              opacity: 0.7,
              child: PixelSpriteAnimation.sparkleGold(
                size: containerSize * 0.48,
                loop: true,
              ),
            ),
          ),

          // 4. Central Emoji with warm fiery drop shadow
          Text(
            emoji,
            style: TextStyle(
              fontSize: emojiSize,
              shadows: const [
                Shadow(
                  color: Color(0xFFDC2626),
                  blurRadius: 14,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),

          // 5. Fiery Ember Spark
          const Positioned(
            top: 2,
            left: 2,
            child: Text('🔥', style: TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }
}

/// Header hero ledakan spektakuler untuk Modal Detail dan Dialog Reward
class ExplosiveStickerHeader extends StatefulWidget {
  final String emoji;
  final String rarity;
  final double size;

  const ExplosiveStickerHeader({
    super.key,
    required this.emoji,
    required this.rarity,
    this.size = 130,
  });

  @override
  State<ExplosiveStickerHeader> createState() => _ExplosiveStickerHeaderState();
}

class _ExplosiveStickerHeaderState extends State<ExplosiveStickerHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCelestial = widget.rarity == 'celestial';
    final isMythical = widget.rarity == 'mythical';

    return SizedBox(
      width: widget.size * 1.5,
      height: widget.size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Ambient Glow Pulsing Layer
          ScaleTransition(
            scale: _pulseScale,
            child: Container(
              width: widget.size * 1.3,
              height: widget.size * 1.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isCelestial
                      ? [
                          const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                          const Color(0xFFEC4899).withValues(alpha: 0.3),
                          const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          Colors.transparent,
                        ]
                      : isMythical
                          ? [
                              const Color(0xFFEF4444).withValues(alpha: 0.6),
                              const Color(0xFFF97316).withValues(alpha: 0.35),
                              const Color(0xFFFACC15).withValues(alpha: 0.15),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFF3B82F6).withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                ),
              ),
            ),
          ),

          // 2. Massive Pixel Explosion Sprite Behind Emoji
          if (isCelestial)
            PixelSpriteAnimation.celestialBurst(
              size: widget.size * 1.55,
              loop: true,
              loopDelay: const Duration(milliseconds: 800),
            )
          else if (isMythical)
            PixelSpriteAnimation.mythicExplosion(
              size: widget.size * 1.55,
              loop: true,
              loopDelay: const Duration(milliseconds: 700),
            ),

          // 3. Lightning / Sparkle Accents
          if (isCelestial)
            Positioned(
              top: 0,
              right: 10,
              child: PixelSpriteAnimation.celestialLightning(
                size: widget.size * 0.6,
                loop: true,
                loopDelay: const Duration(milliseconds: 1200),
              ),
            )
          else if (isMythical)
            Positioned(
              bottom: 0,
              right: 15,
              child: PixelSpriteAnimation.sparkleGold(
                size: widget.size * 0.6,
                loop: true,
              ),
            ),

          // 4. Circular Disc Container for Central Sticker
          Container(
            width: widget.size,
            height: widget.size,
            padding: EdgeInsets.all(widget.size * 0.16),
            decoration: BoxDecoration(
              color: isCelestial
                  ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                  : isMythical
                      ? const Color(0xFF18181B).withValues(alpha: 0.85)
                      : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCelestial
                    ? const Color(0xFFC084FC)
                    : isMythical
                        ? const Color(0xFFF87171)
                        : const Color(0xFFE2E8F0),
                width: isCelestial || isMythical ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isCelestial
                          ? const Color(0xFF8B5CF6)
                          : isMythical
                              ? const Color(0xFFEF4444)
                              : Colors.black)
                      .withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.emoji,
                style: TextStyle(
                  fontSize: widget.size * 0.48,
                  shadows: [
                    Shadow(
                      color: isCelestial
                          ? const Color(0xFFA855F7)
                          : isMythical
                              ? const Color(0xFFEA580C)
                              : Colors.black26,
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
