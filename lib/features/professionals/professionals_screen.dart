import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/place.dart';
import '../../repositories/place_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_retry.dart';

class ProfessionalsScreen extends StatefulWidget {
  const ProfessionalsScreen({super.key});

  @override
  State<ProfessionalsScreen> createState() => _ProfessionalsScreenState();
}

class _ProfessionalsScreenState extends State<ProfessionalsScreen> {
  final _repo = PlaceRepository();
  List<Place> _places = [];
  PlaceType? _selectedType;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final places = await _repo.getAll();
      if (mounted) {
        setState(() {
          _places = places;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<Place> get _filtered {
    if (_selectedType == null) return _places;
    return _places.where((p) => p.type == _selectedType).toList();
  }

  Future<void> _launch(String rawUrl) async {
    final url = rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDetail(Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PlaceDetailSheet(place: place, onLaunch: _launch),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Explorar')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorRetry(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    // Filtros
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('Todos'),
                            selected: _selectedType == null,
                            onSelected: (_) =>
                                setState(() => _selectedType = null),
                          ),
                          ...PlaceType.values.map((t) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: FilterChip(
                                  avatar: Icon(t.icon, size: 14),
                                  label: Text(t.label),
                                  selected: _selectedType == t,
                                  onSelected: (_) => setState(() =>
                                      _selectedType =
                                          _selectedType == t ? null : t),
                                ),
                              )),
                        ],
                      ),
                    ),
                    // Lista
                    Expanded(
                      child: _filtered.isEmpty
                          ? const EmptyState(
                              icon: Icons.explore_outlined,
                              title: 'Aún no hay lugares',
                              subtitle:
                                  'Pronto agregaremos restaurantes, centros holísticos y más.',
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filtered.length,
                                itemBuilder: (ctx, i) => _PlaceCard(
                                  place: _filtered[i],
                                  theme: theme,
                                  colorScheme: colorScheme,
                                  onTap: () => _showDetail(_filtered[i]),
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
// Card de lugar en la lista
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.theme,
    required this.colorScheme,
    required this.onTap,
  });

  final Place place;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme?.radiusLg ?? 12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen o placeholder
            _PlaceImage(place: place, colorScheme: colorScheme, height: 160),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(place.type.label),
                        avatar: Icon(place.type.icon, size: 14),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  if (place.description != null &&
                      place.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      place.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: theme?.mutedForeground,
                          ),
                    ),
                  ],
                  if (place.address != null && place.address!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: theme?.mutedForeground),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: theme?.mutedForeground),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (place.type == PlaceType.event &&
                      place.eventDate != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.event_outlined,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          _fmtDate(place.eventDate!),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Imagen o placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceImage extends StatelessWidget {
  const _PlaceImage({
    required this.place,
    required this.colorScheme,
    required this.height,
  });

  final Place place;
  final ColorScheme colorScheme;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (place.imageUrl != null && place.imageUrl!.isNotEmpty) {
      return Image.network(
        place.imageUrl!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      height: height,
      width: double.infinity,
      color: colorScheme.primaryContainer,
      child: Icon(
        place.type.icon,
        size: height * 0.35,
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detalle completo en bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceDetailSheet extends StatelessWidget {
  const _PlaceDetailSheet({required this.place, required this.onLaunch});

  final Place place;
  final Future<void> Function(String) onLaunch;

  bool get _hasSocial =>
      (place.website?.isNotEmpty ?? false) ||
      (place.instagram?.isNotEmpty ?? false) ||
      (place.facebook?.isNotEmpty ?? false) ||
      (place.tiktok?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, controller) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Scaffold(
          body: CustomScrollView(
            controller: controller,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PlaceImage(
                        place: place, colorScheme: colorScheme, height: 220),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  place.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(place.type.label),
                                avatar: Icon(place.type.icon, size: 14),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          if (place.type == PlaceType.event &&
                              place.eventDate != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.event,
                                    size: 16, color: colorScheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  _fmtDate(place.eventDate!),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                          ],
                          if (place.description != null &&
                              place.description!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(place.description!,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          if (place.address != null &&
                              place.address!.isNotEmpty) ...[
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              text: place.address!,
                              theme: theme,
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (place.phone != null &&
                              place.phone!.isNotEmpty) ...[
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              text: place.phone!,
                              theme: theme,
                              onTap: () => onLaunch('tel:${place.phone}'),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (_hasSocial) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Redes sociales',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: theme?.mutedForeground),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (place.website?.isNotEmpty ?? false)
                                  OutlinedButton.icon(
                                    onPressed: () => onLaunch(place.website!),
                                    icon: const Icon(Icons.language, size: 16),
                                    label: const Text('Website'),
                                  ),
                                if (place.instagram?.isNotEmpty ?? false)
                                  OutlinedButton.icon(
                                    onPressed: () => onLaunch(
                                        'https://instagram.com/${place.instagram!.replaceFirst('@', '')}'),
                                    icon: const Icon(Icons.camera_alt_outlined,
                                        size: 16),
                                    label: const Text('Instagram'),
                                  ),
                                if (place.facebook?.isNotEmpty ?? false)
                                  OutlinedButton.icon(
                                    onPressed: () => onLaunch(
                                        place.facebook!.startsWith('http')
                                            ? place.facebook!
                                            : 'https://facebook.com/${place.facebook}'),
                                    icon: const Icon(Icons.facebook, size: 16),
                                    label: const Text('Facebook'),
                                  ),
                                if (place.tiktok?.isNotEmpty ?? false)
                                  OutlinedButton.icon(
                                    onPressed: () => onLaunch(
                                        'https://tiktok.com/@${place.tiktok!.replaceFirst('@', '')}'),
                                    icon: const Icon(Icons.music_note,
                                        size: 16),
                                    label: const Text('TikTok'),
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.theme,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final AppThemeExtension? theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = onTap != null
        ? Theme.of(context).colorScheme.primary
        : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme?.mutedForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color),
            ),
          ),
          if (onTap != null)
            Icon(Icons.open_in_new, size: 14, color: theme?.mutedForeground),
        ],
      ),
    );
  }
}
