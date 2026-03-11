import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/onboarding_storage.dart';
import '../../core/user_facing_errors.dart';
import '../../models/life_aspect.dart';
import '../../repositories/life_assessment_repository.dart';
import '../../theme/app_theme.dart';

/// Pantalla de encuesta y edición de la Rueda de Vida.
/// Se muestra automáticamente al iniciar sesión por primera vez
/// y también se puede acceder desde el botón "Editar" en la pantalla de inicio.
class LifeWheelSurveyScreen extends StatefulWidget {
  const LifeWheelSurveyScreen({super.key});

  @override
  State<LifeWheelSurveyScreen> createState() => _LifeWheelSurveyScreenState();
}

class _LifeWheelSurveyScreenState extends State<LifeWheelSurveyScreen> {
  final _repo = LifeAssessmentRepository();

  final Map<LifeAspect, int> _scores = {};
  final Map<LifeAspect, TextEditingController> _reasons = {
    for (final a in LifeAspect.values) a: TextEditingController(),
  };

  bool _saving = false;

  bool get _hasAny => _scores.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final existing = await _repo.getMyAssessments();
      if (mounted) {
        setState(() {
          for (final a in existing) {
            _scores[a.aspect] = a.score;
            _reasons[a.aspect]?.text = a.reason ?? '';
          }
        });
      }
    } catch (_) {
      // Falla silenciosa — el usuario puede rellenar desde cero
    }
  }

  @override
  void dispose() {
    for (final c in _reasons.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_hasAny) return;
    setState(() => _saving = true);
    try {
      final entries = <LifeAspect, ({int score, String? reason})>{
        for (final e in _scores.entries)
          e.key: (score: e.value, reason: _reasons[e.key]?.text),
      };
      await _repo.upsertAll(entries);
      await setLifeWheelSurveySeen();
      if (mounted) _exit();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(userFacingErrorMessage(e))));
      }
    }
  }

  Future<void> _skip() async {
    await setLifeWheelSurveySeen();
    if (mounted) _exit();
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Rueda de Vida'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text('Omitir'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                // ── Descripción ───────────────────────────────────────────
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.donut_large_outlined,
                          size: 44,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '¿Cómo te sientes en cada área\nde tu vida?',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Califica del 1 (muy mal) al 5 (excelente).\nSolo necesitas una área para continuar.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: theme?.mutedForeground,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Tarjeta por aspecto ───────────────────────────────────
                ...LifeAspect.values.map(
                  (a) => _AspectTile(
                    aspect: a,
                    score: _scores[a] ?? 0,
                    reasonController: _reasons[a]!,
                    onScoreChanged: (s) => setState(
                      () => s == 0 ? _scores.remove(a) : _scores[a] = s,
                    ),
                    theme: theme,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Botón Continuar ────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _hasAny && !_saving ? _save : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(theme?.radiusMd ?? 8),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continuar'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de un aspecto con selector de puntuación y campo de razón
// ─────────────────────────────────────────────────────────────────────────────

class _AspectTile extends StatelessWidget {
  const _AspectTile({
    required this.aspect,
    required this.score,
    required this.reasonController,
    required this.onScoreChanged,
    this.theme,
  });

  final LifeAspect aspect;
  final int score;
  final TextEditingController reasonController;
  final ValueChanged<int> onScoreChanged;
  final AppThemeExtension? theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Indicador de color del aspecto
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: score > 0 ? aspect.color : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  aspect.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                _ScoreSelector(
                  selected: score,
                  color: aspect.color,
                  onChanged: onScoreChanged,
                ),
              ],
            ),
            if (score > 0) ...[
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: '¿Por qué este puntaje? (opcional)',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: theme?.mutedForeground,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(theme?.radiusSm ?? 4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fila de 5 círculos para seleccionar puntuación
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreSelector extends StatelessWidget {
  const _ScoreSelector({
    required this.selected,
    required this.color,
    required this.onChanged,
  });

  final int selected;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final val = i + 1;
        final isSelected = selected == val;
        return GestureDetector(
          onTap: () => onChanged(isSelected ? 0 : val),
          child: Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade400,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '$val',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
