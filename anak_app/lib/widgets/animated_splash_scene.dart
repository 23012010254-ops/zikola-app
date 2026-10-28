import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Splash artwork built from separate layers so each element can animate:
/// sky, drifting clouds, bouncing logo, tagline, popping mascot and
/// floating ornaments. Replaces the old single flattened splash image.
class AnimatedSplashScene extends StatefulWidget {
  const AnimatedSplashScene({super.key});

  @override
  State<AnimatedSplashScene> createState() => _AnimatedSplashSceneState();
}

class _Ornament {
  final String asset;
  final Offset pos; // fraction of screen size
  final double size;
  final double start; // intro start (0..1)
  final double phase; // idle float phase offset
  const _Ornament(this.asset, this.pos, this.size, this.start, this.phase);
}

class _AnimatedSplashSceneState extends State<AnimatedSplashScene>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _idle;

  static const _ornaments = [
    _Ornament('assets/images/emoji/rewards/star.png', Offset(0.07, 0.36), 38, 0.45, 0.0),
    _Ornament('assets/images/emoji/objects/rocket.png', Offset(0.83, 0.34), 40, 0.50, 0.3),
    _Ornament('assets/images/emoji/games/crayon.png', Offset(0.04, 0.58), 42, 0.55, 0.6),
    _Ornament('assets/images/emoji/feedback/heart.png', Offset(0.86, 0.60), 32, 0.60, 0.15),
    _Ornament('assets/images/emoji/games/books.png', Offset(0.10, 0.76), 46, 0.65, 0.45),
    _Ornament('assets/images/emoji/games/lightbulb.png', Offset(0.80, 0.77), 40, 0.70, 0.8),
  ];

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..forward();
    _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  Animation<double> _step(double begin, double end, [Curve curve = Curves.easeOutCubic]) {
    return CurvedAnimation(parent: _intro, curve: Interval(begin, end, curve: curve));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final logoW = math.min(w * 0.72, 340.0);
      final mascotW = math.min(w * 0.90, 420.0);

      final logo = _step(0.0, 0.45, Curves.elasticOut);
      final tagline = _step(0.30, 0.60);
      final mascot = _step(0.35, 0.80, Curves.easeOutBack);

      return AnimatedBuilder(
        animation: Listenable.merge([_intro, _idle]),
        builder: (context, _) {
          final t = _idle.value * 2 * math.pi;
          return Stack(
            children: [
              // Sky
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF6EB9FD), Color(0xFFBCE0FA), Color(0xFFEAF6FF)],
                    ),
                  ),
                ),
              ),

              // Soft sun glow, top right
              Positioned(
                top: -w * 0.25,
                right: -w * 0.25,
                child: Container(
                  width: w * 0.8,
                  height: w * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFFFFF7CC).withValues(alpha: 0.9),
                      const Color(0xFFFFF7CC).withValues(alpha: 0.0),
                    ]),
                  ),
                ),
              ),

              // Drifting clouds (two layers at different speeds)
              _cloud(w, h, y: 0.06, size: 120, speed: 1, offset: 0.1, opacity: 0.85),
              _cloud(w, h, y: 0.40, size: 90, speed: -1, offset: 0.6, opacity: 0.7),
              _cloud(w, h, y: 0.86, size: 160, speed: 1, offset: 0.35, opacity: 0.95),
              _cloud(w, h, y: 0.93, size: 130, speed: -1, offset: 0.85, opacity: 0.95),

              // Logo: drops in from above with a bounce
              Positioned(
                top: h * 0.10 - (1 - logo.value.clamp(0.0, 1.0)) * 120,
                left: (w - logoW) / 2,
                child: Opacity(
                  opacity: _intro.value < 0.02 ? 0 : 1,
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * logo.value,
                    child: Image.asset('assets/images/zikola_3d_logo.png', width: logoW),
                  ),
                ),
              ),

              // Tagline
              Positioned(
                top: h * 0.10 + logoW * 0.40 + 4 + (1 - tagline.value) * 16,
                left: 24,
                right: 24,
                child: Opacity(
                  opacity: tagline.value.clamp(0.0, 1.0),
                  child: const Text(
                    'Memahami Potensi,\nMembangun Masa Depan Anak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ),
              ),

              // Mascot & house: pops in, then floats
              Positioned(
                top: h * 0.38 + math.sin(t) * 8,
                left: (w - mascotW) / 2,
                child: Opacity(
                  opacity: mascot.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: (0.4 + 0.6 * mascot.value) * (1 + math.sin(t * 2) * 0.012),
                    child: Image.asset('assets/images/zikola_mascot_house.png', width: mascotW),
                  ),
                ),
              ),

              // Ornaments pop in one by one, then bob and wobble
              for (final o in _ornaments) _ornament(o, w, h, t),

              // Twinkling sparkles
              for (var i = 0; i < 6; i++) _sparkle(i, w, h),
            ],
          );
        },
      );
    });
  }

  Widget _cloud(double w, double h,
      {required double y, required double size, required int speed, required double offset, required double opacity}) {
    // Wraps across the screen; one full pass per idle cycle.
    final x = ((offset + _idle.value * 0.15 * speed) % 1.0) * (w + size * 2) - size;
    return Positioned(
      top: h * y,
      left: x,
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(size: Size(size, size * 0.5), painter: _CloudPainter()),
      ),
    );
  }

  Widget _ornament(_Ornament o, double w, double h, double t) {
    final appear = _step(o.start, (o.start + 0.25).clamp(0.0, 1.0), Curves.easeOutBack).value;
    final bob = math.sin(t + o.phase * 2 * math.pi) * 6;
    final wobble = math.sin(t * 1.5 + o.phase * 2 * math.pi) * 0.12;
    return Positioned(
      left: w * o.pos.dx,
      top: h * o.pos.dy + bob,
      child: Opacity(
        opacity: appear.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: wobble,
          child: Transform.scale(
            scale: appear,
            child: Image.asset(o.asset, width: o.size, height: o.size),
          ),
        ),
      ),
    );
  }

  Widget _sparkle(int i, double w, double h) {
    const pts = [
      Offset(0.20, 0.08), Offset(0.90, 0.14), Offset(0.30, 0.34),
      Offset(0.70, 0.38), Offset(0.22, 0.66), Offset(0.76, 0.86),
    ];
    final phase = (_idle.value * 3 + i * 0.17) % 1.0;
    final s = math.sin(phase * math.pi);
    return Positioned(
      left: w * pts[i].dx,
      top: h * pts[i].dy,
      child: Opacity(
        opacity: (s * _intro.value).clamp(0.0, 1.0),
        child: Icon(
          Icons.auto_awesome,
          size: 10 + 8 * s,
          color: i.isEven ? const Color(0xFFFDE047) : Colors.white,
        ),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white;
    final w = size.width;
    final hgt = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, hgt * 0.45, w, hgt * 0.55), Radius.circular(hgt * 0.3)),
      p,
    );
    canvas.drawCircle(Offset(w * 0.32, hgt * 0.5), hgt * 0.32, p);
    canvas.drawCircle(Offset(w * 0.58, hgt * 0.38), hgt * 0.40, p);
    canvas.drawCircle(Offset(w * 0.80, hgt * 0.58), hgt * 0.26, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
