import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/challenge_categories.dart';
import '../../core/user_facing_errors.dart';
import '../../core/challenge_icons.dart';
import '../../core/challenge_templates.dart';
import '../../core/challenge_units.dart';
import '../../models/challenge.dart';
import '../../models/life_aspect.dart';
import '../../models/profile.dart';
import '../../repositories/challenge_invitation_repository.dart';
import '../../repositories/challenge_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';

class ChallengeFormScreen extends StatefulWidget {
  const ChallengeFormScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  State<ChallengeFormScreen> createState() => _ChallengeFormScreenState();
}

class _ChallengeFormScreenState extends State<ChallengeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ChallengeRepository();
  final _inviteRepo = ChallengeInvitationRepository();
  final _nameController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _targetController = TextEditingController();
  final _unitAmountController = TextEditingController();

  ChallengeType _type = ChallengeType.streak;
  String? _selectedUnit;
  ChallengeFrequency _frequency = ChallengeFrequency.weekly;
  int? _iconCodePoint;
  bool _isPublic = true;
  int _daysPerWeek = 5;   // cuántos días a la semana (solo streak)
  DateTime? _startDate;
  DateTime? _endDate;
  ChallengeCategory _category = ChallengeCategory.otro;
  LifeAspect? _lifeAspect;
  bool _loading = false;
  String? _error;

  // ── Invitaciones ──────────────────────────────────────────────────────────
  static const _maxInvites = 8;
  List<AppProfile> _followingProfiles = [];
  Set<String> _selectedInviteeIds = {};
  Set<String> _alreadyInvitedIds = {};

  @override
  void initState() {
    super.initState();
    _loadFollowingProfiles();
    if (widget.challengeId != null) _loadChallenge();
  }

  Future<void> _loadFollowingProfiles() async {
    final profiles = await _inviteRepo.getFollowingProfiles();
    if (!mounted) return;
    setState(() => _followingProfiles = profiles);

    // En modo edición: precargar quiénes ya fueron invitados
    if (widget.challengeId != null) {
      final invited = await _inviteRepo.getInvitedUserIds(widget.challengeId!);
      if (mounted) {
        setState(() {
          _alreadyInvitedIds = invited;
          _selectedInviteeIds = Set.from(invited);
        });
      }
    }
  }

  Future<void> _loadChallenge() async {
    final c = await _repo.getById(widget.challengeId!);
    if (c != null && mounted) {
      _nameController.text = c.name;
      _objectiveController.text = c.objective ?? '';
      _unitAmountController.text = c.unitAmount?.toString() ?? '';
      setState(() {
        _type = c.type;
        _frequency = c.frequency ?? ChallengeFrequency.weekly;
        _iconCodePoint = c.iconCodePoint;
        _selectedUnit = c.unit != null && c.unit!.isNotEmpty
            ? (ChallengeUnits.units.contains(c.unit) ? c.unit : null)
            : null;
        _isPublic = c.isPublic;
        _startDate = c.startDate;
        _endDate = c.endDate;
        _category = c.category;
        _lifeAspect = c.lifeAspect;
        // Recuperar días/semana del length de weekdays (0 → default 5)
        _daysPerWeek = (c.weekdays?.length ?? 5).clamp(1, 7);
        if (_type == ChallengeType.streak) {
          _targetController.text = '';  // siempre auto-calculado
        } else {
          _targetController.text = c.target.toString();
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _objectiveController.dispose();
    _targetController.dispose();
    _unitAmountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    num target;
    if (_type == ChallengeType.streak) {
      // Target = días esperados de check-in en el periodo según días/semana
      final effectiveStart = _startDate ?? DateTime.now();
      final start = DateTime(effectiveStart.year, effectiveStart.month, effectiveStart.day);
      if (_endDate != null) {
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        final totalDays = end.difference(start).inDays + 1;
        target = totalDays > 0
            ? (totalDays * _daysPerWeek / 7).ceil().clamp(1, 9999)
            : 30;
      } else {
        target = 30; // default si no hay fecha de fin
      }
    } else {
      if (_targetController.text.trim().isEmpty) {
        setState(() => _error = 'Indica cuántas veces');
        return;
      }
      final parsed = num.tryParse(_targetController.text.trim());
      if (parsed == null || parsed <= 0) {
        setState(() => _error = 'La meta debe ser un número mayor a 0');
        return;
      }
      target = parsed;
    }

    if (_selectedUnit == null) {
      setState(() => _error = 'Selecciona una unidad');
      return;
    }
    final unitAmount = num.tryParse(_unitAmountController.text.trim());
    if (unitAmount == null || unitAmount < 0) {
      setState(() => _error = 'Indica la cantidad');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      // Guardar días/semana como lista [0,1,...,N-1] para recuperarlos por .length
      final weekdaysList = _type == ChallengeType.streak
          ? List.generate(_daysPerWeek, (i) => i)
          : null;

      String challengeId;

      if (widget.challengeId != null) {
        challengeId = widget.challengeId!;
        await _repo.update(
          challengeId,
          name: _nameController.text.trim(),
          type: _type,
          target: target,
          unit: _selectedUnit,
          unitAmount: unitAmount,
          frequency: _type == ChallengeType.countTimes ? _frequency : null,
          iconCodePoint: _iconCodePoint,
          isPublic: _isPublic,
          objective: _objectiveController.text.trim().isEmpty ? null : _objectiveController.text.trim(),
          weekdays: weekdaysList,
          startDate: _startDate,
          endDate: _endDate,
          category: _category,
          lifeAspect: _lifeAspect,
          updateLifeAspect: true,
        );
      } else {
        final created = await _repo.insert(
          name: _nameController.text.trim(),
          type: _type,
          target: target,
          unit: _selectedUnit,
          unitAmount: unitAmount,
          frequency: _type == ChallengeType.countTimes ? _frequency : null,
          iconCodePoint: _iconCodePoint,
          isPublic: _isPublic,
          objective: _objectiveController.text.trim().isEmpty ? null : _objectiveController.text.trim(),
          weekdays: weekdaysList,
          startDate: _startDate,
          endDate: _endDate,
          category: _category,
          lifeAspect: _lifeAspect,
        );
        challengeId = created.id;
      }

      // Enviar invitaciones solo a los recién seleccionados (no a los ya invitados)
      final newInvitees = _selectedInviteeIds.difference(_alreadyInvitedIds);
      for (final id in newInvitees) {
        await _inviteRepo.invite(challengeId, id);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = userFacingErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Widget _buildIconCell({
    required BuildContext context,
    required IconData icon,
    required bool isSelected,
    required AppThemeExtension? theme,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : theme?.muted,
          borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Icon(
          icon,
          size: 24,
          color: isSelected
              ? colorScheme.onPrimaryContainer
              : theme?.mutedForeground,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.challengeId != null ? 'Editar reto' : 'Nuevo reto'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (widget.challengeId == null)
            TextButton.icon(
              onPressed: _showTemplateSheet,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Plantilla'),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del reto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Escribe un nombre';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _objectiveController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Objetivo',
                    hintText: 'Describe tu objetivo con este reto...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Icono', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const crossAxisCount = 6;
                    const spacing = 8.0;
                    final allItems = <Widget>[
                      _buildIconCell(
                        context: context,
                        icon: Icons.cancel_outlined,
                        isSelected: _iconCodePoint == null,
                        theme: theme,
                        colorScheme: colorScheme,
                        onTap: () => setState(() => _iconCodePoint = null),
                      ),
                      ...ChallengeIcons.icons.map((icon) {
                        final isSelected = _iconCodePoint == icon.codePoint;
                        return _buildIconCell(
                          context: context,
                          icon: icon,
                          isSelected: isSelected,
                          theme: theme,
                          colorScheme: colorScheme,
                          onTap: () => setState(() =>
                              _iconCodePoint = isSelected ? null : icon.codePoint),
                        );
                      }),
                    ];
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1,
                      children: allItems,
                    );
                  },
                ),
                const SizedBox(height: 24),
                if (_type == ChallengeType.streak) ...[
                  Text(
                    '¿Cuántos días a la semana?',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(7, (i) {
                      final val = i + 1;
                      final selected = _daysPerWeek == val;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _daysPerWeek = val),
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? colorScheme.primaryContainer
                                  : theme?.muted,
                              borderRadius: BorderRadius.circular(
                                  theme?.radiusMd ?? 8),
                              border: selected
                                  ? Border.all(
                                      color: colorScheme.primary, width: 2)
                                  : null,
                            ),
                            child: Text(
                              '$val',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selected
                                    ? colorScheme.onPrimaryContainer
                                    : theme?.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ] else ...[
                  DropdownButtonFormField<ChallengeType>(
                    value: _type,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Tipo de reto',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                      ),
                    ),
                    items: ChallengeType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _type = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Veces por periodo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Obligatorio';
                      if (num.tryParse(v.trim()) == null) return 'Escribe un número';
                      return null;
                    },
                  ),
                ],
                if (_type == ChallengeType.countTimes) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ChallengeFrequency>(
                    value: _frequency,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Periodo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                      ),
                    ),
                    items: ChallengeFrequency.values.map((f) => DropdownMenuItem(
                      value: f,
                      child: Text(f.label),
                    )).toList(),
                    onChanged: (v) { if (v != null) setState(() => _frequency = v); },
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Unidad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                    ),
                  ),
                  hint: const Text('Selecciona una unidad'),
                  selectedItemBuilder: (context) {
                    return ChallengeUnits.units.map((unit) {
                      return Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          unit,
                          overflow: TextOverflow.visible,
                          softWrap: false,
                        ),
                      );
                    }).toList();
                  },
                  items: ChallengeUnits.units.map((unit) => DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedUnit = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unitAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    hintText: _type == ChallengeType.streak
                        ? 'Ej. 5 (kilómetros por día)'
                        : 'Ej. 5 (kilómetros por sesión)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Obligatorio';
                    if (num.tryParse(v.trim()) == null) return 'Escribe un número';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _DatePickerTile(
                  label: 'Fecha de inicio',
                  date: _startDate,
                  placeholder: 'Hoy (por defecto)',
                  theme: theme,
                  onPick: _showStartDatePicker,
                  onClear: () => setState(() => _startDate = null),
                ),
                const SizedBox(height: 8),
                _DatePickerTile(
                  label: 'Fecha de fin',
                  date: _endDate,
                  placeholder: 'Sin especificar (opcional)',
                  theme: theme,
                  onPick: _showEndDatePicker,
                  onClear: () => setState(() => _endDate = null),
                ),
                if (_type == ChallengeType.streak &&
                    _endDate != null) ...[
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final start = _startDate ?? DateTime.now();
                    final end = _endDate!;
                    final totalDays =
                        end.difference(start).inDays + 1;
                    final expected = totalDays > 0
                        ? (totalDays * _daysPerWeek / 7).ceil()
                        : 0;
                    return Text(
                      'Meta estimada: $expected check-ins',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary),
                    );
                  }),
                ],
                const SizedBox(height: 24),
                Text('Categoría', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ChallengeCategory.values.map((cat) {
                    final selected = _category == cat;
                    return FilterChip(
                      avatar: Icon(
                        cat.icon,
                        size: 16,
                        color: selected
                            ? colorScheme.onPrimaryContainer
                            : theme?.mutedForeground,
                      ),
                      label: Text(cat.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _category = cat),
                      selectedColor: colorScheme.primaryContainer,
                      checkmarkColor: colorScheme.onPrimaryContainer,
                      labelStyle: TextStyle(
                        color: selected
                            ? colorScheme.onPrimaryContainer
                            : theme?.mutedForeground,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: selected
                            ? colorScheme.primary
                            : (theme?.border ?? Colors.grey),
                        width: selected ? 2 : 1,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text('Aspecto de vida', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Vincula este reto con un área de tu Rueda de Vida',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme?.mutedForeground,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Ninguno'),
                      selected: _lifeAspect == null,
                      onSelected: (_) => setState(() => _lifeAspect = null),
                      selectedColor: colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(
                        color: _lifeAspect == null
                            ? colorScheme.onSurface
                            : theme?.mutedForeground,
                        fontWeight: _lifeAspect == null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: _lifeAspect == null
                            ? colorScheme.outline
                            : (theme?.border ?? Colors.grey),
                        width: _lifeAspect == null ? 2 : 1,
                      ),
                    ),
                    ...LifeAspect.values.map((aspect) {
                      final selected = _lifeAspect == aspect;
                      return FilterChip(
                        avatar: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: aspect.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        label: Text(aspect.label),
                        selected: selected,
                        onSelected: (_) => setState(() => _lifeAspect = aspect),
                        selectedColor: aspect.color.withValues(alpha: 0.15),
                        checkmarkColor: aspect.color,
                        labelStyle: TextStyle(
                          color: selected ? aspect.color : theme?.mutedForeground,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: selected
                              ? aspect.color
                              : (theme?.border ?? Colors.grey),
                          width: selected ? 2 : 1,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Reto público'),
                  subtitle: const Text('Otros podrán ver tu progreso'),
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                ),
                if (_followingProfiles.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _InviteTile(
                    profiles: _followingProfiles,
                    selectedIds: _selectedInviteeIds,
                    alreadyInvitedIds: _alreadyInvitedIds,
                    maxInvites: _maxInvites,
                    theme: theme,
                    onTap: _showInvitePicker,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.challengeId != null ? 'Guardar' : 'Crear reto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showStartDatePicker() async {
    final now = DateTime.now();
    final initial = _startDate ?? now;
    final result = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: 'Fecha de inicio del reto',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (result != null && mounted) {
      setState(() {
        _startDate = result;
        // Si la fecha de fin es anterior a la de inicio, limpiarla
        if (_endDate != null && _endDate!.isBefore(result)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _showEndDatePicker() async {
    final now = DateTime.now();
    final firstDate = _startDate ?? now;
    final initial = _endDate != null && !_endDate!.isBefore(firstDate)
        ? _endDate!
        : DateTime(firstDate.year, firstDate.month + 1, firstDate.day);
    final result = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 10),
      helpText: 'Fecha de fin del reto',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (result != null && mounted) {
      setState(() => _endDate = result);
    }
  }

  void _applyTemplate(ChallengeTemplate t) {
    _nameController.text = t.name;
    _objectiveController.text = t.objective;
    _targetController.text = t.target.toString();
    _unitAmountController.text = t.unitAmount?.toString() ?? '';
    setState(() {
      _type = t.type;
      _category = t.category;
      _frequency = t.frequency ?? ChallengeFrequency.weekly;
      _iconCodePoint = t.icon.codePoint;
      _selectedUnit = t.unit != null && ChallengeUnits.units.contains(t.unit)
          ? t.unit
          : null;
    });
  }

  void _showInvitePicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            Theme.of(context).extension<AppThemeExtension>()?.radiusLg ?? 16,
          ),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(ctx).extension<AppThemeExtension>();
          final colorScheme = Theme.of(ctx).colorScheme;
          return DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.4,
            maxChildSize: 0.85,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: theme?.mutedForeground,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Invitar amigos',
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Text(
                        '${_selectedInviteeIds.length}/$_maxInvites',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: _selectedInviteeIds.length >= _maxInvites
                                  ? colorScheme.error
                                  : theme?.mutedForeground,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Máximo $_maxInvites personas. Las invitaciones se envían al guardar.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: theme?.mutedForeground,
                        ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _followingProfiles.isEmpty
                      ? Center(
                          child: Text(
                            'No sigues a nadie aún',
                            style: TextStyle(color: theme?.mutedForeground),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _followingProfiles.length,
                          itemBuilder: (context, i) {
                            final profile = _followingProfiles[i];
                            final isSelected =
                                _selectedInviteeIds.contains(profile.id);
                            final isAlreadyInvited =
                                _alreadyInvitedIds.contains(profile.id);
                            final atLimit =
                                _selectedInviteeIds.length >= _maxInvites &&
                                    !isSelected;

                            return ListTile(
                              leading: UserAvatar(
                                avatarUrl: profile.avatarUrl,
                                name: profile.displayName ?? profile.username ?? '?',
                                radius: 20,
                              ),
                              title: Text(profile.displayName ?? 'Usuario'),
                              subtitle: profile.username != null
                                  ? Text(
                                      '@${profile.username}',
                                      style: TextStyle(
                                          color: theme?.mutedForeground),
                                    )
                                  : null,
                              trailing: isAlreadyInvited
                                  ? Chip(
                                      label: const Text('Invitado'),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      side: BorderSide.none,
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                      labelStyle: TextStyle(
                                        fontSize: 11,
                                        color: theme?.mutedForeground,
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.add_circle_outline,
                                        color: isSelected
                                            ? colorScheme.primary
                                            : atLimit
                                                ? theme?.mutedForeground
                                                : null,
                                      ),
                                      onPressed: atLimit && !isSelected
                                          ? null
                                          : () {
                                              setState(() {
                                                if (isSelected) {
                                                  _selectedInviteeIds
                                                      .remove(profile.id);
                                                } else {
                                                  _selectedInviteeIds
                                                      .add(profile.id);
                                                }
                                              });
                                              setSheetState(() {});
                                            },
                                    ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTemplateSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            Theme.of(context).extension<AppThemeExtension>()?.radiusLg ?? 16,
          ),
        ),
      ),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final theme = Theme.of(ctx).extension<AppThemeExtension>();
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: theme?.mutedForeground,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Elige una plantilla',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: challengeTemplates.length,
                  itemBuilder: (context, i) {
                    final t = challengeTemplates[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          t.icon,
                          color: colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      title: Text(t.name),
                      subtitle: Text(
                        t.objective,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme?.mutedForeground),
                      ),
                      trailing: Chip(
                        label: Text(
                          t.category.label,
                          style: const TextStyle(fontSize: 11),
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _applyTemplate(t);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class _InviteTile extends StatelessWidget {
  const _InviteTile({
    required this.profiles,
    required this.selectedIds,
    required this.alreadyInvitedIds,
    required this.maxInvites,
    required this.theme,
    required this.onTap,
  });

  final List<AppProfile> profiles;
  final Set<String> selectedIds;
  final Set<String> alreadyInvitedIds;
  final int maxInvites;
  final AppThemeExtension? theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = profiles.where((p) => selectedIds.contains(p.id)).toList();
    final totalCount = selectedIds.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme?.muted,
          borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 18,
              color: totalCount > 0
                  ? colorScheme.primary
                  : theme?.mutedForeground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invitar amigos',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: theme?.mutedForeground,
                        ),
                  ),
                  const SizedBox(height: 4),
                  if (selected.isEmpty)
                    Text(
                      'Nadie seleccionado',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: theme?.mutedForeground,
                          ),
                    )
                  else
                    Row(
                      children: [
                        // Stacked avatars (up to 4)
                        SizedBox(
                          height: 28,
                          width: (selected.take(4).length * 20 + 8).toDouble(),
                          child: Stack(
                            children: [
                              for (var i = 0;
                                  i < selected.take(4).length;
                                  i++)
                                Positioned(
                                  left: i * 20.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            theme?.muted ?? Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: UserAvatar(
                                      name: selected[i].displayName ??
                                          selected[i].username ??
                                          '?',
                                      avatarUrl: selected[i].avatarUrl,
                                      radius: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalCount / $maxInvites',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme?.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.placeholder,
    required this.theme,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final String placeholder;
  final AppThemeExtension? theme;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDate = date != null;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme?.muted,
          borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: hasDate ? colorScheme.primary : theme?.mutedForeground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: theme?.mutedForeground,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDate ? _formatDate(date!) : placeholder,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: hasDate
                              ? colorScheme.onSurface
                              : theme?.mutedForeground,
                        ),
                  ),
                ],
              ),
            ),
            if (hasDate)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
                visualDensity: VisualDensity.compact,
                color: theme?.mutedForeground,
              ),
          ],
        ),
      ),
    );
  }
}
