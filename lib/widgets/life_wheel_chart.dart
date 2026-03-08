import 'dart:math';

import 'package:flutter/material.dart';

import '../models/life_aspect.dart';
import '../models/life_assessment.dart';
import '../theme/app_theme.dart';

/// Tipo de gráfico de la Rueda de Vida.
enum LifeWheelChartType {
  /// Gráfico circular con pétalos.
  wheel,
  /// Gráfico radar (polígono por puntuaciones).
  radar,
}

/// Rueda de Vida: gráfica circular con 8 pétalos o gráfico radar.
/// Toca el gráfico para alternar entre la vista de rueda y la de radar.
class LifeWheelChart extends StatefulWidget {
  const LifeWheelChart({
    super.key,
    required this.assessments,
    this.size = 260,
    this.selectedAspect,
    this.onAspectTap,
    this.zenitBalance,
  });

  final List<LifeAssessment> assessments;
  final double size;
  final LifeAspect? selectedAspect;
  final ValueChanged<LifeAspect>? onAspectTap;

  /// Balance de zenits del usuario. Se muestra en el centro del gráfico.
  final int? zenitBalance;

  @override
  State<LifeWheelChart> createState() => _LifeWheelChartState();
}

class _LifeWheelChartState extends State<LifeWheelChart> {
  LifeWheelChartType _chartType = LifeWheelChartType.wheel;

  void _toggleChartType() {
    setState(() {
      _chartType = _chartType == LifeWheelChartType.wheel
          ? LifeWheelChartType.radar
          : LifeWheelChartType.wheel;
    });
  }

  /// Área de toque transparente para el centro (alterna rueda/radar).
  Widget _centerHitArea() {
    final s = widget.size;
    final outerR = s / 2 * 0.46;
    final r = outerR * 0.22 * 1.5;
    return Positioned(
      left: s / 2 - r,
      top: s / 2 - r,
      width: r * 2,
      height: r * 2,
      child: GestureDetector(
        onTap: _toggleChartType,
        behavior: HitTestBehavior.opaque,
        child: const SizedBox.expand(),
      ),
    );
  }

  /// Área de toque transparente para cada pétalo.
  Widget _petalHitArea(int i) {
    final s = widget.size;
    final outerR = s / 2 * 0.46;
    final ringR = outerR * 0.64;
    final angle = -pi / 2 + i * 2 * pi / LifeAspect.values.length;
    final px = s / 2 + cos(angle) * ringR;
    final py = s / 2 + sin(angle) * ringR;
    const r = 24.0;
    final aspect = LifeAspect.values[i];
    return Positioned(
      left: px - r,
      top: py - r,
      width: r * 2,
      height: r * 2,
      child: GestureDetector(
        onTap: widget.onAspectTap != null
            ? () => widget.onAspectTap!(aspect)
            : null,
        behavior: HitTestBehavior.opaque,
        child: const SizedBox.expand(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assessmentMap = <LifeAspect, LifeAssessment>{
      for (final a in widget.assessments) a.aspect: a,
    };
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        theme?.muted ?? (isDark ? Colors.grey.shade800 : Colors.grey.shade200);
    final centerColor = Theme.of(context).colorScheme.surface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _chartType == LifeWheelChartType.radar
                      ? _RadarChartPainter(
                          assessmentMap: assessmentMap,
                          bgColor: bgColor,
                          centerColor: centerColor,
                          zenitBalance: widget.zenitBalance,
                          selectedAspect: widget.selectedAspect,
                        )
                      : _LifeWheelPainter(
                          assessmentMap: assessmentMap,
                          bgColor: bgColor,
                          centerColor: centerColor,
                          selectedAspect: widget.selectedAspect,
                          zenitBalance: widget.zenitBalance,
                        ),
                ),
              ),
              // Áreas de toque para los pétalos (debajo del centro)
              for (var i = 0; i < LifeAspect.values.length; i++)
                _petalHitArea(i),
              // Centro encima: tiene prioridad en el Stack
              _centerHitArea(),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Toca el centro para cambiar la vista',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: theme?.mutedForeground,
              ),
        ),
        const SizedBox(height: 16),
        _LegendGrid(
          assessmentMap: assessmentMap,
          selectedAspect: widget.selectedAspect,
          onAspectTap: widget.onAspectTap,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leyenda
// ─────────────────────────────────────────────────────────────────────────────

class _LegendGrid extends StatelessWidget {
  const _LegendGrid({
    required this.assessmentMap,
    this.selectedAspect,
    this.onAspectTap,
  });

  final Map<LifeAspect, LifeAssessment> assessmentMap;
  final LifeAspect? selectedAspect;
  final ValueChanged<LifeAspect>? onAspectTap;

  @override
  Widget build(BuildContext context) {
    const aspects = LifeAspect.values;
    final half = (aspects.length / 2).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final a in aspects.take(half))
                  _LegendItem(
                    aspect: a,
                    score: assessmentMap[a]?.score,
                    isSelected: selectedAspect == a,
                    onTap: onAspectTap != null ? () => onAspectTap!(a) : null,
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final a in aspects.skip(half))
                  _LegendItem(
                    aspect: a,
                    score: assessmentMap[a]?.score,
                    isSelected: selectedAspect == a,
                    onTap: onAspectTap != null ? () => onAspectTap!(a) : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.aspect,
    required this.score,
    this.isSelected = false,
    this.onTap,
  });

  final LifeAspect aspect;
  final int? score;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasScore = score != null && score! > 0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: isSelected
            ? BoxDecoration(
                color: aspect.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: aspect.color.withValues(alpha: 0.4)),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: hasScore ? aspect.color : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                aspect.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: hasScore ? null : Colors.grey.shade500,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    ),
              ),
            ),
            Text(
              hasScore ? '$score/5' : '—',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasScore ? aspect.color : Colors.grey.shade400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers de pintura
// ─────────────────────────────────────────────────────────────────────────────

/// Dibuja el balance de zenits en dos líneas centradas dentro del círculo central.
void _paintCenterZenits(
  Canvas canvas,
  Offset center,
  double centerR,
  int? zenitBalance,
) {
  final numStr = zenitBalance?.toString() ?? '—';

  final numPainter = TextPainter(
    text: TextSpan(
      text: numStr,
      style: TextStyle(
        fontSize: centerR * 0.62,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final labelPainter = TextPainter(
    text: TextSpan(
      text: 'zenits',
      style: TextStyle(
        fontSize: centerR * 0.36,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade400,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  const gap = 1.0;
  final totalH = numPainter.height + gap + labelPainter.height;
  final startY = center.dy - totalH / 2;

  numPainter.paint(
    canvas,
    Offset(center.dx - numPainter.width / 2, startY),
  );
  labelPainter.paint(
    canvas,
    Offset(center.dx - labelPainter.width / 2, startY + numPainter.height + gap),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter
// ─────────────────────────────────────────────────────────────────────────────

class _LifeWheelPainter extends CustomPainter {
  const _LifeWheelPainter({
    required this.assessmentMap,
    required this.bgColor,
    required this.centerColor,
    this.selectedAspect,
    this.zenitBalance,
  });

  final Map<LifeAspect, LifeAssessment> assessmentMap;
  final Color bgColor;
  final Color centerColor;
  final LifeAspect? selectedAspect;
  final int? zenitBalance;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width * 0.46;
    final ringR = outerR * 0.64;     // distancia del centro al centro del pétalo
    final petalW = outerR * 0.32;    // ancho del pétalo
    final petalH = outerR * 0.44;    // alto del pétalo
    final centerR = outerR * 0.22;   // radio del círculo central

    // Círculo guía exterior (tenue)
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..color = bgColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    const aspects = LifeAspect.values;
    for (var i = 0; i < aspects.length; i++) {
      final aspect = aspects[i];
      // Ángulo: empieza desde arriba (−π/2) y va en sentido horario
      final angle = -pi / 2 + i * 2 * pi / aspects.length;

      // Centro del pétalo en coordenadas del canvas
      final px = center.dx + cos(angle) * ringR;
      final py = center.dy + sin(angle) * ringR;

      final score = assessmentMap[aspect]?.score ?? 0;
      final isSelected = selectedAspect == aspect;

      canvas.save();
      canvas.translate(px, py);
      // Rotación: local +Y apunta en la dirección "hacia afuera" del centro
      canvas.rotate(angle - pi / 2);

      final scale = isSelected ? 1.18 : 1.0;
      final sw = petalW * scale;
      final sh = petalH * scale;
      final petalRect = Rect.fromCenter(
        center: Offset.zero,
        width: sw,
        height: sh,
      );

      // 1. Fondo gris del pétalo (más opaco si está seleccionado)
      canvas.drawOval(
        petalRect,
        Paint()
          ..color = isSelected ? bgColor.withValues(alpha: 0.9) : bgColor
          ..style = PaintingStyle.fill,
      );

      // 2. Relleno coloreado proporcional al score
      if (score > 0) {
        final fillH = sh * score / 5.0;
        canvas.save();
        canvas.clipRect(
          Rect.fromLTWH(-sw / 2, -sh / 2, sw, fillH),
        );
        canvas.drawOval(
          petalRect,
          Paint()
            ..color = isSelected
                ? aspect.color
                : aspect.color.withValues(alpha: 0.8)
            ..style = PaintingStyle.fill,
        );
        canvas.restore();
      }

      // 3. Borde del pétalo (más grueso y brillante si seleccionado)
      canvas.drawOval(
        petalRect,
        Paint()
          ..color = isSelected
              ? aspect.color
              : (score > 0
                  ? aspect.color.withValues(alpha: 0.85)
                  : Colors.grey.shade400)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 3.0 : (score > 0 ? 2.0 : 1.0),
      );

      canvas.restore();
    }

    // Círculo central
    canvas.drawCircle(
      center,
      centerR,
      Paint()
        ..color = centerColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      centerR,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Número de zenits (arriba) + label "zenits" (abajo) en el centro
    _paintCenterZenits(canvas, center, centerR, zenitBalance);
  }

  @override
  bool shouldRepaint(covariant _LifeWheelPainter old) =>
      old.assessmentMap != assessmentMap ||
      old.selectedAspect != selectedAspect ||
      old.zenitBalance != zenitBalance;
}

// ─────────────────────────────────────────────────────────────────────────────
// Radar chart: polígono con un eje por aspecto y radio = puntuación
// ─────────────────────────────────────────────────────────────────────────────

class _RadarChartPainter extends CustomPainter {
  const _RadarChartPainter({
    required this.assessmentMap,
    required this.bgColor,
    required this.centerColor,
    this.zenitBalance,
    this.selectedAspect,
  });

  final Map<LifeAspect, LifeAssessment> assessmentMap;
  final Color bgColor;
  final Color centerColor;
  final int? zenitBalance;
  final LifeAspect? selectedAspect;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.42;
    const maxScore = 5.0;
    const aspects = LifeAspect.values;
    final n = aspects.length;

    // Rejilla: círculos concéntricos (niveles 1..5)
    final gridPaint = Paint()
      ..color = bgColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (var level = 1; level <= 5; level++) {
      final r = maxR * (level / maxScore);
      canvas.drawCircle(center, r, gridPaint);
    }

    // Ejes desde el centro
    final axisPaint = Paint()
      ..color = bgColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (var i = 0; i < n; i++) {
      final angle = -pi / 2 + i * 2 * pi / n;
      final end = Offset(
        center.dx + cos(angle) * maxR,
        center.dy + sin(angle) * maxR,
      );
      canvas.drawLine(center, end, axisPaint);
    }

    // Puntos del polígono (radio = score/5 * maxR)
    final points = <Offset>[];
    for (var i = 0; i < n; i++) {
      final aspect = aspects[i];
      final score = assessmentMap[aspect]?.score ?? 0;
      final r = maxR * (score.clamp(0, 5) / maxScore);
      final angle = -pi / 2 + i * 2 * pi / n;
      points.add(Offset(
        center.dx + cos(angle) * r,
        center.dy + sin(angle) * r,
      ));
    }

    if (points.length >= 3) {
      // Relleno del polígono (color primario suave)
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = aspects.first.color.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill,
      );
      // Borde del polígono (mezcla de colores por segmento o un solo color)
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round;
      for (var i = 0; i < points.length; i++) {
        final next = (i + 1) % points.length;
        borderPaint.color = aspects[i].color.withValues(alpha: 0.9);
        canvas.drawLine(points[i], points[next], borderPaint);
      }
      // Puntos en los vértices
      for (var i = 0; i < points.length; i++) {
        final isSelected = aspects[i] == selectedAspect;
        final dotR = isSelected ? 7.0 : 4.0;
        canvas.drawCircle(
          points[i],
          dotR,
          Paint()
            ..color = aspects[i].color
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          points[i],
          dotR,
          Paint()
            ..color = centerColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 2.0 : 1.5,
        );
      }
    }

    // Círculo central
    final centerR = maxR * 0.18;
    canvas.drawCircle(
      center,
      centerR,
      Paint()
        ..color = centerColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      centerR,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _paintCenterZenits(canvas, center, centerR, zenitBalance);
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter old) =>
      old.assessmentMap != assessmentMap ||
      old.zenitBalance != zenitBalance ||
      old.selectedAspect != selectedAspect;
}
