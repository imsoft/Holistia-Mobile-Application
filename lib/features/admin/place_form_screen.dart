import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/user_facing_errors.dart';
import '../../models/place.dart';
import '../../repositories/place_repository.dart';

class PlaceFormScreen extends StatefulWidget {
  const PlaceFormScreen({super.key, this.placeId});

  final String? placeId;

  @override
  State<PlaceFormScreen> createState() => _PlaceFormScreenState();
}

class _PlaceFormScreenState extends State<PlaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = PlaceRepository();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();

  PlaceType _type = PlaceType.place;
  DateTime? _eventDate;
  String? _imageUrl;
  String? _pendingImagePath;

  bool _loading = false;
  bool _uploadingImage = false;
  String? _error;

  bool get _isEdit => widget.placeId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final place = await _repo.getById(widget.placeId!);
      if (place != null && mounted) {
        _nameCtrl.text = place.name;
        _descCtrl.text = place.description ?? '';
        _addressCtrl.text = place.address ?? '';
        _phoneCtrl.text = place.phone ?? '';
        _websiteCtrl.text = place.website ?? '';
        _instagramCtrl.text = place.instagram ?? '';
        _facebookCtrl.text = place.facebook ?? '';
        _tiktokCtrl.text = place.tiktok ?? '';
        setState(() {
          _type = place.type;
          _eventDate = place.eventDate;
          _imageUrl = place.imageUrl;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = userFacingErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    _tiktokCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () => ctx.pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Cámara'),
              onTap: () => ctx.pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (xFile == null || !mounted) return;

    setState(() {
      _pendingImagePath = xFile.path;
      _uploadingImage = true;
    });

    try {
      final url = await _repo.uploadImage(xFile.path);
      if (mounted) setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error subiendo imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _pickEventDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventDate ?? DateTime.now()),
    );
    if (!mounted) return;

    setState(() {
      _eventDate = time != null
          ? DateTime(
              picked.year, picked.month, picked.day, time.hour, time.minute)
          : picked;
    });
  }

  String? _nullIfEmpty(String text) =>
      text.trim().isEmpty ? null : text.trim();

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final name = _nameCtrl.text.trim();
      final description = _nullIfEmpty(_descCtrl.text);
      final address = _nullIfEmpty(_addressCtrl.text);
      final phone = _nullIfEmpty(_phoneCtrl.text);
      final website = _nullIfEmpty(_websiteCtrl.text);
      final instagram = _nullIfEmpty(_instagramCtrl.text);
      final facebook = _nullIfEmpty(_facebookCtrl.text);
      final tiktok = _nullIfEmpty(_tiktokCtrl.text);

      if (_isEdit) {
        await _repo.update(
          widget.placeId!,
          type: _type,
          name: name,
          description: description,
          address: address,
          phone: phone,
          imageUrl: _imageUrl,
          eventDate: _eventDate,
          clearEventDate: _type != PlaceType.event,
          website: website,
          instagram: instagram,
          facebook: facebook,
          tiktok: tiktok,
        );
      } else {
        await _repo.insert(
          type: _type,
          name: name,
          description: description,
          address: address,
          phone: phone,
          imageUrl: _imageUrl,
          eventDate: _type == PlaceType.event ? _eventDate : null,
          website: website,
          instagram: instagram,
          facebook: facebook,
          tiktok: tiktok,
        );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar lugar' : 'Nuevo lugar'),
      ),
      body: _loading && _isEdit
          ? const Center(child: CircularProgressIndicator.adaptive())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Imagen ────────────────────────────────────────────
                    _ImagePicker(
                      imageUrl: _imageUrl,
                      localPath: _pendingImagePath,
                      uploading: _uploadingImage,
                      onTap: _pickImage,
                    ),
                    const SizedBox(height: 24),

                    // ── Tipo ──────────────────────────────────────────────
                    DropdownButtonFormField<PlaceType>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Tipo *',
                        border: OutlineInputBorder(),
                      ),
                      items: PlaceType.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Row(
                                  children: [
                                    Icon(t.icon, size: 18),
                                    const SizedBox(width: 8),
                                    Text(t.label),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _type = v);
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Nombre ────────────────────────────────────────────
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Descripción ───────────────────────────────────────
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // ── Dirección ─────────────────────────────────────────
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // ── Teléfono ──────────────────────────────────────────
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    // ── Fecha evento (solo si type == event) ──────────────
                    if (_type == PlaceType.event) ...[
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined),
                        title: Text(
                          _eventDate != null
                              ? _formatDateTime(_eventDate!)
                              : 'Fecha y hora del evento',
                          style: _eventDate == null
                              ? TextStyle(color: theme.colorScheme.outline)
                              : null,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: theme.colorScheme.outline),
                        ),
                        onTap: _pickEventDate,
                        trailing: _eventDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () =>
                                    setState(() => _eventDate = null),
                              )
                            : null,
                      ),
                    ],

                    // ── Redes sociales ────────────────────────────────────
                    const SizedBox(height: 24),
                    _SectionHeader(
                      icon: Icons.link,
                      label: 'Redes sociales y contacto',
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _websiteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Sitio web',
                        prefixIcon: Icon(Icons.language_outlined),
                        hintText: 'https://ejemplo.com',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _instagramCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Instagram',
                        prefixIcon: _SocialIcon('instagram'),
                        hintText: '@usuario o URL',
                        border: OutlineInputBorder(),
                      ),
                      autocorrect: false,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _facebookCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Facebook',
                        prefixIcon: _SocialIcon('facebook'),
                        hintText: '@página o URL',
                        border: OutlineInputBorder(),
                      ),
                      autocorrect: false,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _tiktokCtrl,
                      decoration: const InputDecoration(
                        labelText: 'TikTok',
                        prefixIcon: _SocialIcon('tiktok'),
                        hintText: '@usuario o URL',
                        border: OutlineInputBorder(),
                      ),
                      autocorrect: false,
                    ),

                    // ── Error ─────────────────────────────────────────────
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Botón submit ──────────────────────────────────────
                    FilledButton(
                      onPressed: (_loading || _uploadingImage) ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEdit ? 'Guardar cambios' : 'Crear lugar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final d =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleSmall
              ?.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: theme.colorScheme.primary.withAlpha(60)),
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon(this.network);
  final String network;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Text(
        switch (network) {
          'instagram' => 'IG',
          'facebook' => 'FB',
          'tiktok' => 'TK',
          _ => '🌐',
        },
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.imageUrl,
    required this.localPath,
    required this.uploading,
    required this.onTap,
  });

  final String? imageUrl;
  final String? localPath;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withAlpha(80)),
        ),
        clipBehavior: Clip.antiAlias,
        child: uploading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(imageUrl!, fit: BoxFit.cover),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: FilledButton.tonal(
                          onPressed: onTap,
                          child: const Text('Cambiar'),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        'Agregar imagen',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
      ),
    );
  }
}
