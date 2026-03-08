import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const kEmojiReactions = ['🔥', '💪', '⭐', '🙌', '❤️', '👍'];

/// Reacción rápida por defecto (como el "like" en Facebook).
const kDefaultQuickReaction = '❤️';

/// Botón de reacciones tipo Facebook: tap = corazón; mantener + arrastrar = elegir otra.
class EmojiReactionTrigger extends StatefulWidget {
  const EmojiReactionTrigger({
    super.key,
    required this.counts,
    required this.userEmojis,
    required this.onToggle,
    this.activeColor,
    this.inactiveColor,
  });

  final Map<String, int> counts;
  final Set<String> userEmojis;
  final void Function(String emoji) onToggle;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  State<EmojiReactionTrigger> createState() => _EmojiReactionTriggerState();
}

class _EmojiReactionTriggerState extends State<EmojiReactionTrigger> {
  OverlayEntry? _overlayEntry;
  int _selectedIndex = kEmojiReactions.indexOf(kDefaultQuickReaction);
  Rect? _stripRect;
  static const double _stripWidth = 260.0;
  static const double _stripHeight = 52.0;
  /// Margen arriba del botón para que el dedo no tape la tira al arrastrar.
  static const double _stripMargin = 72.0;

  int get _totalCount =>
      widget.counts.values.fold(0, (a, b) => a + b);

  /// Emojis que tienen al menos una reacción (orden fijo), sin mostrar su número individual.
  List<String> get _emojisWithCount =>
      kEmojiReactions.where((e) => (widget.counts[e] ?? 0) > 0).toList();

  void _onTap() {
    if (widget.userEmojis.contains(kDefaultQuickReaction)) {
      widget.onToggle(kDefaultQuickReaction);
    } else {
      for (final e in widget.userEmojis) {
        widget.onToggle(e);
      }
      widget.onToggle(kDefaultQuickReaction);
    }
  }

  void _showStrip(BuildContext context, RenderBox box) {
    final overlay = Overlay.of(context);
    final triggerRect = box.localToGlobal(Offset.zero) & box.size;
    final left = triggerRect.center.dx - _stripWidth / 2;
    final top = triggerRect.top - _stripHeight - _stripMargin;
    _stripRect = Rect.fromLTWH(
      left.clamp(8.0, MediaQuery.sizeOf(context).width - _stripWidth - 8),
      top.clamp(MediaQuery.paddingOf(context).top + 8, double.infinity),
      _stripWidth,
      _stripHeight,
    );
    _selectedIndex = kEmojiReactions.indexOf(kDefaultQuickReaction);
    if (_selectedIndex < 0) _selectedIndex = 0;

    _overlayEntry = OverlayEntry(
      builder: (context) => _ReactionStripOverlay(
        rect: _stripRect!,
        selectedIndex: _selectedIndex,
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _hideStrip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    final chosen = kEmojiReactions[_selectedIndex];
    // Como en Facebook: una sola reacción. Quitar las que tenía y poner la elegida.
    for (final e in widget.userEmojis) {
      if (e != chosen) widget.onToggle(e);
    }
    if (!widget.userEmojis.contains(chosen)) widget.onToggle(chosen);
  }

  void _onLongPressStart(LongPressStartDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    _showStrip(context, box);
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_stripRect == null) return;
    // Usar solo la posición horizontal del dedo; no requiere tocar la tira.
    // Así el dedo puede quedarse abajo y la selección sigue el movimiento.
    final localX = details.globalPosition.dx - _stripRect!.left;
    final index = (localX / _stripRect!.width * kEmojiReactions.length)
        .floor()
        .clamp(0, kEmojiReactions.length - 1);
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _hideStrip();
  }

  void _onLongPressCancel() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = widget.activeColor ?? colorScheme.primary;
    final muted = widget.inactiveColor ??
        theme.extension<AppThemeExtension>()?.mutedForeground ??
        colorScheme.onSurfaceVariant;
    final hasReaction = widget.userEmojis.isNotEmpty;
    final color = hasReaction ? primary : muted;

    final emojisWithCount = _emojisWithCount;

    return GestureDetector(
      onTap: _onTap,
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMoveUpdate,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressCancel,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emojisWithCount.isNotEmpty) ...[
              ...emojisWithCount.map(
                (emoji) => Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 18, height: 1.0),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ] else
              Icon(Icons.favorite_border, size: 22, color: color),
            const SizedBox(width: 4),
            Text(
              '$_totalCount',
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay que muestra la tira de emojis (el índice lo actualiza el padre con markNeedsBuild).
class _ReactionStripOverlay extends StatelessWidget {
  const _ReactionStripOverlay({
    required this.rect,
    required this.selectedIndex,
  });

  final Rect rect;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Material(
        elevation: 8,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(rect.height / 2),
        color: theme.colorScheme.surfaceContainerHighest,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(rect.height / 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(kEmojiReactions.length, (i) {
              final emoji = kEmojiReactions[i];
              final selected = i == selectedIndex;
              return Expanded(
                child: Center(
                  child: _AnimatedReactionEmoji(
                    emoji: emoji,
                    selected: selected,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Emoji con animación suave al seleccionar/deseleccionar.
class _AnimatedReactionEmoji extends StatefulWidget {
  const _AnimatedReactionEmoji({
    required this.emoji,
    required this.selected,
  });

  final String emoji;
  final bool selected;

  @override
  State<_AnimatedReactionEmoji> createState() => _AnimatedReactionEmojiState();
}

class _AnimatedReactionEmojiState extends State<_AnimatedReactionEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    if (widget.selected) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _AnimatedReactionEmoji oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      if (widget.selected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Text(
            widget.emoji,
            style: const TextStyle(fontSize: 24, height: 1.0),
          ),
        );
      },
    );
  }
}

/// Barra de reacciones emoji para un post (legacy, para otros usos).
class EmojiReactionBar extends StatelessWidget {
  const EmojiReactionBar({
    super.key,
    required this.counts,
    required this.userEmojis,
    required this.onToggle,
  });

  final Map<String, int> counts;
  final Set<String> userEmojis;
  final void Function(String emoji) onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: kEmojiReactions.map((emoji) {
        final count = counts[emoji] ?? 0;
        final active = userEmojis.contains(emoji);
        return _ReactionChip(
          emoji: emoji,
          count: count,
          active: active,
          onTap: () => onToggle(emoji),
        );
      }).toList(),
    );
  }
}

class _ReactionChip extends StatefulWidget {
  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_ReactionChip> createState() => _ReactionChipState();
}

class _ReactionChipState extends State<_ReactionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() async {
    await _ctrl.reverse();
    _ctrl.forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTap: _onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.active
                  ? colorScheme.primary.withValues(alpha: 0.12)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.active
                    ? colorScheme.primary.withValues(alpha: 0.4)
                    : colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 14, height: 1.0),
                  strutStyle: const StrutStyle(fontSize: 14, height: 1.0, forceStrutHeight: true),
                ),
                if (widget.count > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${widget.count}',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.0,
                      fontWeight: FontWeight.w600,
                      color: widget.active
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    strutStyle: const StrutStyle(fontSize: 12, height: 1.0, forceStrutHeight: true),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
