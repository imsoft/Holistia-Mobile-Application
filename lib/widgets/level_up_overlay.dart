import 'dart:math';

import 'package:flutter/material.dart';

import '../core/zenit_level.dart';
import '../models/life_aspect.dart';

/// Pantalla épica de celebración cuando el usuario sube de nivel.
///
/// Uso:
/// ```dart
/// await LevelUpOverlay.show(context, level: ZenitLevel.brote, newBalance: 105);
/// ```
class LevelUpOverlay {
  static Future<void> show(
    BuildContext context, {
    required ZenitLevel level,
    required int newBalance,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Nivel',
      barrierColor: Colors.black.withValues(alpha: 0.88),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      pageBuilder: (context, anim, secAnim) =>
          _LevelUpContent(level: level, newBalance: newBalance),
    );
  }
}

class _LevelUpContent extends StatefulWidget {
  const _LevelUpContent({required this.level, required this.newBalance});

  final ZenitLevel level;
  final int newBalance;

  @override
  State<_LevelUpContent> createState() => _LevelUpContentState();
}

class _LevelUpContentState extends State<_LevelUpContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _emojiScale;
  late final Animation<double> _labelOpacity;
  late final Animation<double> _labelSlide;
  late final Animation<double> _hintOpacity;
  late final List<_Particle> _particles;

  static const _totalDuration = Duration(milliseconds: 2800);
  static const _autoDismissDelay = Duration(milliseconds: 4200);

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(vsync: this, duration: _totalDuration);

    // Emoji: rebota hacia afuera con elasticOut
    _emojiScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.25)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 35,
      ),
    ]).animate(_ctrl);

    // Textos: aparecen después del emoji
    _labelOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.40, 0.65, curve: Curves.easeIn),
    );
    _labelSlide = Tween(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.40, 0.65, curve: Curves.easeOut),
      ),
    );
    _hintOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.70, 0.90, curve: Curves.easeIn),
    );

    // Partículas de confetti
    final rng = Random();
    final colors = [
      widget.level.color,
      Colors.white,
      Colors.amber,
      Colors.white60,
      widget.level.color.withValues(alpha: 0.6),
      Colors.cyanAccent,
    ];
    _particles = List.generate(55, (i) {
      final angle = (rng.nextDouble() * 2 * pi);
      final speed = rng.nextDouble() * 1.0 + 0.4;
      return _Particle(
        vx: cos(angle) * speed,
        vy: -(rng.nextDouble() * 1.6 + 0.5),
        size: rng.nextDouble() * 5 + 3,
        color: colors[rng.nextInt(colors.length)],
        rotation: rng.nextDouble() * pi,
        rotationSpeed: (rng.nextDouble() - 0.5) * 8,
        isCircle: rng.nextBool(),
      );
    });

    _ctrl.forward();

    Future.delayed(_autoDismissDelay, () {
      if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context, rootNavigator: true).maybePop(),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Confetti layer
                CustomPaint(
                  painter: _ConfettiPainter(_ctrl.value, _particles),
                ),
                // Glow rings
                Center(
                  child: _GlowRings(
                    color: widget.level.color,
                    progress: _ctrl.value,
                  ),
                ),
                // Content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "¡SUBISTE DE NIVEL!"
                      Opacity(
                        opacity: _labelOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, -_labelSlide.value),
                          child: Text(
                            '¡SUBISTE DE NIVEL!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  color: widget.level.color,
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Emoji
                      Transform.scale(
                        scale: _emojiScale.value,
                        child: Text(
                          widget.level.emoji,
                          style: const TextStyle(fontSize: 100),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Nombre del nivel
                      Opacity(
                        opacity: _labelOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _labelSlide.value),
                          child: Text(
                            widget.level.label.toUpperCase(),
                            style: TextStyle(
                              color: widget.level.color,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: widget.level.color.withValues(alpha: 0.6),
                                  blurRadius: 30,
                                  offset: const Offset(0, 4),
                                ),
                                Shadow(
                                  color: widget.level.color.withValues(alpha: 0.3),
                                  blurRadius: 60,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Balance
                      Opacity(
                        opacity: _labelOpacity.value,
                        child: Text(
                          '${widget.newBalance} zenits',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Tap hint
                      Opacity(
                        opacity: _hintOpacity.value,
                        child: const Text(
                          'Toca para continuar',
                          style: TextStyle(
                            color: Colors.white30,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Anillos de luz que pulsan alrededor del emoji.
class _GlowRings extends StatelessWidget {
  const _GlowRings({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    // 2 anillos que se expanden y desvanecen
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ring(color, progress, delay: 0.0),
          _ring(color, progress, delay: 0.25),
        ],
      ),
    );
  }

  Widget _ring(Color c, double p, {required double delay}) {
    final adjusted = ((p - delay).clamp(0.0, 1.0));
    final scale = 0.5 + adjusted * 1.2;
    final opacity = (1.0 - adjusted).clamp(0.0, 0.35);
    return Transform.scale(
      scale: scale,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: c.withValues(alpha: opacity),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: opacity * 0.5),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;
  final bool isCircle;

  const _Particle({
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _ConfettiPainter(this.progress, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (final p in particles) {
      // Movimiento parabólico desde el centro
      final x = cx + p.vx * progress * size.width * 0.45;
      final y = cy +
          (p.vy * progress + 1.8 * progress * progress) * size.height * 0.45;

      // Fade out en el último 30%
      final opacity = progress < 0.70
          ? 1.0
          : (1.0 - (progress - 0.70) / 0.30).clamp(0.0, 1.0);

      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity.toDouble())
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * progress);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size * 0.6, paint);
      } else {
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: p.size * 1.8,
          height: p.size * 0.8,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// ASPECT UP OVERLAY
// ─────────────────────────────────────────────────────────────────────────────

/// Celebración cuando un aspecto de la Rueda de Vida sube de puntuación.
///
/// Uso:
/// ```dart
/// await AspectUpOverlay.show(context, aspect: LifeAspect.fisico, newScore: 4);
/// ```
class AspectUpOverlay {
  static Future<void> show(
    BuildContext context, {
    required LifeAspect aspect,
    required int newScore,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Aspecto',
      barrierColor: Colors.black.withValues(alpha: 0.88),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      pageBuilder: (context, anim, secAnim) =>
          _AspectUpContent(aspect: aspect, newScore: newScore),
    );
  }
}

class _AspectUpContent extends StatefulWidget {
  const _AspectUpContent({required this.aspect, required this.newScore});

  final LifeAspect aspect;
  final int newScore;

  @override
  State<_AspectUpContent> createState() => _AspectUpContentState();
}

class _AspectUpContentState extends State<_AspectUpContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _circleScale;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _starsProgress; // 0.0 → newScore/5
  late final Animation<double> _hintOpacity;

  static const _totalDuration = Duration(milliseconds: 2400);
  static const _autoDismissDelay = Duration(milliseconds: 4000);

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(vsync: this, duration: _totalDuration);

    // Círculo de color del aspecto que "explota" hacia afuera
    _circleScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
    ]).animate(_ctrl);

    _titleOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 0.60, curve: Curves.easeIn),
    );

    // Las estrellas se "llenan" una a una entre 0.45 y 0.75
    _starsProgress = Tween(begin: 0.0, end: widget.newScore / 5.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 0.80, curve: Curves.easeOut),
      ),
    );

    _hintOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.78, 0.95, curve: Curves.easeIn),
    );

    _ctrl.forward();

    Future.delayed(_autoDismissDelay, () {
      if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.aspect.color;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context, rootNavigator: true).maybePop(),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Círculo central con icono del aspecto
                  Transform.scale(
                    scale: _circleScale.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Anillo exterior difuminado
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.12),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.45),
                                blurRadius: 48,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        // Círculo relleno
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.6),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('⭐', style: TextStyle(fontSize: 48)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // "¡ASPECTO MEJORADO!"
                  Opacity(
                    opacity: _titleOpacity.value,
                    child: Text(
                      '¡ASPECTO MEJORADO!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        shadows: [Shadow(color: color, blurRadius: 14)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Nombre del aspecto
                  Opacity(
                    opacity: _titleOpacity.value,
                    child: Text(
                      widget.aspect.label.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Estrellas animadas
                  _AnimatedStars(
                    filled: _starsProgress.value * 5,
                    color: color,
                  ),
                  const SizedBox(height: 6),
                  Opacity(
                    opacity: _titleOpacity.value,
                    child: Text(
                      '${widget.newScore} / 5',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Opacity(
                    opacity: _hintOpacity.value,
                    child: const Text(
                      'Toca para continuar',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Fila de 5 estrellas donde `filled` va de 0 a 5 (puede ser decimal).
class _AnimatedStars extends StatelessWidget {
  const _AnimatedStars({required this.filled, required this.color});

  final double filled; // 0.0 – 5.0
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        // Qué tan rellena está esta estrella (0.0–1.0)
        final starFill = (filled - i).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: [color, color, Colors.white24],
              stops: [0.0, starFill, starFill],
            ).createShader(bounds),
            child: const Text('★', style: TextStyle(fontSize: 36)),
          ),
        );
      }),
    );
  }
}
