import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/place.dart';
import '../../repositories/place_repository.dart';
import '../../widgets/error_retry.dart';

class PlacesTab extends StatefulWidget {
  const PlacesTab({super.key});

  @override
  State<PlacesTab> createState() => _PlacesTabState();
}

class _PlacesTabState extends State<PlacesTab>
    with AutomaticKeepAliveClientMixin {
  final _repo = PlaceRepository();

  List<Place>? _places;
  String? _error;
  PlaceType? _filter;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _places = null;
      _error = null;
    });
    try {
      final list = await _repo.getAll(type: _filter);
      if (mounted) setState(() => _places = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _delete(Place place) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar lugar'),
        content: Text('¿Eliminar "${place.name}"?'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => ctx.pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _repo.delete(place.id);
      if (mounted) {
        setState(() => _places?.removeWhere((p) => p.id == place.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          _FilterChips(
            selected: _filter,
            onSelected: (type) {
              setState(() => _filter = type);
              _load();
            },
          ),
          Expanded(
            child: _buildBody(theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/admin/places/new');
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_error != null) {
      return ErrorRetry(message: _error!, onRetry: _load);
    }

    if (_places == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_places!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.place_outlined,
                size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'Sin lugares',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _places!.length,
        itemBuilder: (context, i) => _PlaceTile(
          place: _places![i],
          onEdit: () async {
            await context.push('/admin/places/${_places![i].id}/edit');
            _load();
          },
          onDelete: () => _delete(_places![i]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final PlaceType? selected;
  final void Function(PlaceType?) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...PlaceType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(type.icon, size: 16),
                label: Text(type.label),
                selected: selected == type,
                onSelected: (_) => onSelected(selected == type ? null : type),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({
    required this.place,
    required this.onEdit,
    required this.onDelete,
  });

  final Place place;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: place.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                place.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _PlaceIcon(place.type),
              ),
            )
          : _PlaceIcon(place.type),
      title: Text(place.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TypeBadge(place.type),
          if (place.address != null)
            Text(
              place.address!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      isThreeLine: place.address != null,
      trailing: PopupMenuButton<_Action>(
        onSelected: (action) {
          if (action == _Action.edit) onEdit();
          if (action == _Action.delete) onDelete();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: _Action.edit,
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Editar'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: _Action.delete,
            child: ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Eliminar'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

enum _Action { edit, delete }

class _PlaceIcon extends StatelessWidget {
  const _PlaceIcon(this.type);
  final PlaceType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(type.icon, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge(this.type);
  final PlaceType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.label,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
      ),
    );
  }
}
