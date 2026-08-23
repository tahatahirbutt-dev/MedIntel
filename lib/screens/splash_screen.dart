// MEDINTEL — animated splash screen
//
// Capsule "hero" that fades in small and tilted, settles upright-ish, draws a
// glowing node constellation around itself, then the icon badge + two-tone
// wordmark + gradient underline rise in underneath.
//
// Pure Flutter — no extra packages.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:med_intel/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onFinished,
    this.dark = false,
    this.showIconBadge = true,
    this.holdAfterAnimation = const Duration(milliseconds: 600),
  });

  /// Called once the sequence (plus [holdAfterAnimation]) has finished.
  final VoidCallback? onFinished;

  /// `false` = the light splash shipping in the app. `true` = dark treatment.
  final bool dark;

  /// Keeps the mint app-icon badge between the pill and the wordmark.
  final bool showIconBadge;

  final Duration holdAfterAnimation;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _float;
  bool _done = false;

  // ---- choreography (fractions of the 2600ms intro) ----------------------
  static const _pillIn = Interval(0.00, 0.40, curve: Curves.easeOutCubic);
  static const _pillSettle = Interval(0.00, 0.55, curve: Curves.easeOutBack);
  static const _network = Interval(0.22, 0.72, curve: Curves.easeOut);
  static const _badgeIn = Interval(0.38, 0.66, curve: Curves.easeOutCubic);
  static const _wordIn = Interval(0.48, 0.78, curve: Curves.easeOutCubic);
  static const _ruleIn = Interval(0.62, 0.88, curve: Curves.easeOutCubic);
  static const _tailIn = Interval(0.74, 1.00, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });

    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Respect the OS "reduce motion" setting: show the end state, don't animate.
      final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduced) {
        _float.stop();
        _intro.value = 1.0;
      } else {
        _intro.forward();
      }
    });
  }

  Future<void> _finish() async {
    if (_done) return;
    _done = true;
    await Future<void>.delayed(widget.holdAfterAnimation);
    if (mounted) widget.onFinished?.call();
  }

  @override
  void dispose() {
    _intro.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.dark ? _SplashPalette.dark : _SplashPalette.light;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: p.background,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _float]),
        builder: (context, _) {
          final t = _intro.value;
          final bob = math.sin(_float.value * 2 * math.pi); // -1 .. 1

          return Stack(
            fit: StackFit.expand,
            children: [
              _AmbientGlow(palette: p, t: t, bob: bob),
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 6),
                    _pillHero(p, t, bob),
                    const SizedBox(height: 28),
                    if (widget.showIconBadge) ...[
                      _iconBadge(p, t),
                      const SizedBox(height: 20),
                    ],
                    _wordmark(p, t),
                    const SizedBox(height: 10),
                    _underline(p, t),
                    const SizedBox(height: 14),
                    _tagline(p, t, l10n),
                    const Spacer(flex: 7),
                    _footer(p, t, l10n),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---- hero: capsule + constellation -------------------------------------

  Widget _pillHero(_SplashPalette p, double t, double bob) {
    final appear = _pillIn.transform(t);
    final settle = _pillSettle.transform(t);
    final net = _network.transform(t);

    // Tilt eases from a steeper angle to its resting -40°, like the clip.
    final angle = _lerp(-1.02, -0.70, settle);
    final scale = _lerp(0.72, 1.0, settle);

    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Node network draws itself around the capsule.
          Opacity(
            opacity: net.clamp(0.0, 1.0),
            child: CustomPaint(
              size: const Size(300, 300),
              painter: _ConstellationPainter(palette: p, t: net, bob: bob),
            ),
          ),
          // The capsule itself, gently breathing.
          Transform.translate(
            offset: Offset(0, _lerp(18, 0, appear) + bob * 3.5),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: appear.clamp(0.0, 1.0),
                  child: Container(
                    width: 96,
                    height: 168,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(48),
                      boxShadow: [
                        BoxShadow(
                          color: p.accent.withValues(
                            alpha: 0.30 * appear * (0.75 + bob * 0.12),
                          ),
                          blurRadius: 46,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: CustomPaint(painter: _PillPainter(palette: p)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- existing splash pieces --------------------------------------------

  Widget _iconBadge(_SplashPalette p, double t) {
    final a = _badgeIn.transform(t);
    return Opacity(
      opacity: a.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: _lerp(0.86, 1.0, a),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: p.badgeFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.badgeBorder, width: 1.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.5),
            child: Image.asset(
              'assets/images/logo_mark.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _wordmark(_SplashPalette p, double t) {
    final a = _wordIn.transform(t);
    return Opacity(
      opacity: a.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, _lerp(14, 0, a)),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'MED',
                style: TextStyle(color: p.wordPrimary),
              ),
              TextSpan(text: 'INTEL', style: TextStyle(color: p.accent)),
            ],
          ),
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _underline(_SplashPalette p, double t) {
    final a = _ruleIn.transform(t);
    return Container(
      height: 3,
      width: 132 * a.clamp(0.0, 1.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(colors: [p.ruleStart, p.accent]),
      ),
    );
  }

  Widget _tagline(_SplashPalette p, double t, AppLocalizations l10n) {
    final a = _tailIn.transform(t);
    return Opacity(
      opacity: (a * 0.9).clamp(0.0, 1.0),
      child: Text(
        l10n.splashTagline,
        style: TextStyle(fontSize: 13, color: p.muted, letterSpacing: 0.3),
      ),
    );
  }

  Widget _footer(_SplashPalette p, double t, AppLocalizations l10n) {
    final a = _tailIn.transform(t);
    return Opacity(
      opacity: a.clamp(0.0, 1.0),
      child: Column(
        children: [
          SizedBox(
            width: 128,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: p.accent.withValues(alpha: 0.16),
                valueColor: AlwaysStoppedAnimation<Color>(p.accent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.splashLoadingCatalogue,
            style: TextStyle(
              fontSize: 11.5,
              color: p.muted,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

/// The two-tone capsule: gradient top half, translucent outlined bottom half,
/// a highlight streak, and the star outline sitting over the seam.
class _PillPainter extends CustomPainter {
  const _PillPainter({required this.palette});

  final _SplashPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final body = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width / 2),
    );
    final midY = size.height * 0.52;

    canvas.save();
    canvas.clipRRect(body);

    // Lower (empty) half.
    canvas.drawRect(
      Rect.fromLTRB(0, midY, size.width, size.height),
      Paint()..color = palette.pillShellFill,
    );

    // Upper (filled) half.
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, midY),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [palette.pillGradientStart, palette.pillGradientEnd],
        ).createShader(rect),
    );
    canvas.restore();

    // Hairline shell.
    canvas.drawRRect(
      body.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = palette.pillStroke,
    );

    // Glossy streak on the filled half.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.235,
          size.height * 0.135,
          size.width * 0.07,
          size.height * 0.235,
        ),
        Radius.circular(size.width * 0.05),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    // Star outline over the seam, as in the concept clip.
    canvas.drawPath(
      _starPath(Offset(size.width * 0.42, size.height * 0.63), 15),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = palette.accent,
    );
  }

  @override
  bool shouldRepaint(_PillPainter old) => old.palette != palette;
}

/// Glowing nodes, connectors and the faint crosshair behind the capsule.
class _ConstellationPainter extends CustomPainter {
  const _ConstellationPainter({
    required this.palette,
    required this.t,
    required this.bob,
  });

  final _SplashPalette palette;
  final double t; // 0..1
  final double bob; // -1..1

  // (x, y) normalised to the box, radius, start delay.
  static const List<List<double>> _nodes = [
    [0.735, 0.500, 6.5, 0.00], // anchor node beside the capsule
    [0.860, 0.640, 4.5, 0.14],
    [0.180, 0.270, 3.0, 0.22],
    [0.545, 0.170, 4.5, 0.32],
    [0.700, 0.855, 4.5, 0.44],
    [0.925, 0.745, 2.6, 0.54],
    [0.500, 0.930, 2.2, 0.62],
  ];

  // Node index pairs to connect.
  static const List<List<int>> _edges = [
    [2, 0],
    [0, 1],
    [1, 4],
    [1, 5],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    Offset at(List<double> n) => Offset(n[0] * size.width, n[1] * size.height);
    double phase(double delay) =>
        ((t - delay) / 0.42).clamp(0.0, 1.0).toDouble();

    // Faint crosshair.
    final grid = Paint()
      ..color = palette.grid.withValues(alpha: 0.6 * t)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height * 0.50),
      Offset(size.width, size.height * 0.50),
      grid,
    );
    canvas.drawLine(
      Offset(size.width * 0.545, 0),
      Offset(size.width * 0.545, size.height),
      grid,
    );

    // Connectors, drawn progressively.
    for (final e in _edges) {
      final a = at(_nodes[e[0]]);
      final b = at(_nodes[e[1]]);
      final k = phase(_nodes[e[1]][3]);
      if (k <= 0) continue;
      canvas.drawLine(
        a,
        Offset.lerp(a, b, k)!,
        Paint()
          ..color = palette.accent.withValues(alpha: 0.45 * k)
          ..strokeWidth = 1.3,
      );
    }

    // Nodes with a soft halo, breathing with the capsule.
    for (final n in _nodes) {
      final k = phase(n[3]);
      if (k <= 0) continue;
      final c = at(n);
      final r = n[2] * k * (1 + bob * 0.06);

      canvas.drawCircle(
        c,
        r * 2.9,
        Paint()
          ..color = palette.accent.withValues(alpha: 0.20 * k)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()..color = palette.accent.withValues(alpha: k),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = palette.nodeRing.withValues(alpha: k),
      );
    }

    // Small star to the upper right.
    final sk = phase(0.36);
    if (sk > 0) {
      canvas.drawPath(
        _starPath(Offset(size.width * 0.885, size.height * 0.300), 11 * sk),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..color = palette.accent.withValues(alpha: sk),
      );
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) =>
      old.t != t || old.bob != bob || old.palette != palette;
}

/// Soft radial wash behind everything.
class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.palette,
    required this.t,
    required this.bob,
  });

  final _SplashPalette palette;
  final double t;
  final double bob;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 0.95 + bob * 0.03,
          colors: [
            palette.glow.withValues(alpha: 0.85 * t),
            palette.background,
          ],
        ),
      ),
    );
  }
}

Path _starPath(Offset center, double radius) {
  final path = Path();
  const points = 5;
  final inner = radius * 0.44;
  for (var i = 0; i < points * 2; i++) {
    final r = i.isEven ? radius : inner;
    final a = -math.pi / 2 + i * math.pi / points;
    final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

// ---------------------------------------------------------------------------
// Palettes
// ---------------------------------------------------------------------------

@immutable
class _SplashPalette {
  const _SplashPalette({
    required this.background,
    required this.glow,
    required this.accent,
    required this.pillGradientStart,
    required this.pillGradientEnd,
    required this.pillShellFill,
    required this.pillStroke,
    required this.nodeRing,
    required this.grid,
    required this.badgeFill,
    required this.badgeBorder,
    required this.wordPrimary,
    required this.ruleStart,
    required this.muted,
  });

  final Color background;
  final Color glow;
  final Color accent;
  final Color pillGradientStart;
  final Color pillGradientEnd;
  final Color pillShellFill;
  final Color pillStroke;
  final Color nodeRing;
  final Color grid;
  final Color badgeFill;
  final Color badgeBorder;
  final Color wordPrimary;
  final Color ruleStart;
  final Color muted;

  /// Matches the splash currently shipping in the app.
  static const light = _SplashPalette(
    background: Color(0xFFF5F7FB),
    glow: Color(0x2610B981),
    accent: Color(0xFF0E9F6E),
    pillGradientStart: Color(0xFF0E9F6E),
    pillGradientEnd: Color(0xFF4ADE9B),
    pillShellFill: Color(0x14101A3A),
    pillStroke: Color(0x33101A3A),
    nodeRing: Color(0xFFFFFFFF),
    grid: Color(0x1A101A3A),
    badgeFill: Color(0xFFDDF7EA),
    badgeBorder: Color(0xFFB7ECD5),
    wordPrimary: Color(0xFF14224A),
    ruleStart: Color(0xFF3B82F6),
    muted: Color(0xFF64748B),
  );

  /// The dark treatment from the concept clip.
  static const dark = _SplashPalette(
    background: Color(0xFF05090F),
    glow: Color(0x330E7490),
    accent: Color(0xFF2DD4BF),
    pillGradientStart: Color(0xFF0D9488),
    pillGradientEnd: Color(0xFF5EEAD4),
    pillShellFill: Color(0x14FFFFFF),
    pillStroke: Color(0x33FFFFFF),
    nodeRing: Color(0xFFFFFFFF),
    grid: Color(0x14FFFFFF),
    badgeFill: Color(0x1A2DD4BF),
    badgeBorder: Color(0x332DD4BF),
    wordPrimary: Color(0xFFF1F5F9),
    ruleStart: Color(0xFF38BDF8),
    muted: Color(0xFF94A3B8),
  );
}
