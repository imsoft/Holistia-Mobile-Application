import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_constants.dart';
import '../../core/profile_options.dart';
import '../../core/user_facing_errors.dart';
import '../../repositories/profile_repository.dart';
import '../../theme/app_theme.dart';

/// Pantalla para editar perfil (nombre, usuario, sexo, fecha) en un solo formulario.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileRepo = ProfileRepository();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();

  String? _sex;
  DateTime? _birthDate;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  static String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Elige un nombre de usuario';
    final lower = v.trim().toLowerCase();
    if (lower.length < AppConstants.usernameMinLength) {
      return 'Mínimo ${AppConstants.usernameMinLength} caracteres';
    }
    if (lower.length > AppConstants.usernameMaxLength) {
      return 'Máximo ${AppConstants.usernameMaxLength} caracteres';
    }
    if (!AppConstants.usernameRegex.hasMatch(lower)) {
      return 'Solo letras minúsculas, números y _';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await _profileRepo.getMyProfile();
      if (mounted && p != null) {
        _nameController.text = p.displayName ?? '';
        _usernameController.text = p.username ?? '';
        setState(() {
          _sex = p.sex;
          _birthDate = p.birthDate;
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = userFacingErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final username = _usernameController.text.trim().toLowerCase();
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final available = await _profileRepo.isUsernameAvailable(username, excludeUserId: uid);
    if (!available && mounted) {
      setState(() => _error = 'Ese nombre de usuario ya está en uso.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await _profileRepo.updateProfile(
        displayName: _nameController.text.trim(),
        username: username,
        sex: _sex,
        birthDate: _birthDate,
      );
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = userFacingErrorMessage(e);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _pickSex() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sexo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            ...ProfileSexOptions.options.entries.map(
              (e) => ListTile(
                title: Text(e.value),
                onTap: () => Navigator.pop(context, e.key),
              ),
            ),
            ListTile(
              title: const Text('No especificar'),
              onTap: () => Navigator.pop(context, ''),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) setState(() => _sex = result.isEmpty ? null : result);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final result = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: initial,
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (result != null && mounted) setState(() => _birthDate = result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Escribe tu nombre';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: 'Nombre de usuario',
                hintText: 'ej. maria_holistia',
                helperText: '3-30 caracteres: letras, números y _',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                ),
              ),
              validator: _validateUsername,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickSex,
              borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Sexo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                  ),
                ),
                child: Text(
                  ProfileSexOptions.getLabel(_sex) ?? 'No especificado',
                  style: TextStyle(
                    color: _sex != null
                        ? null
                        : theme?.mutedForeground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickBirthDate,
              borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha de nacimiento',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                  ),
                ),
                child: Text(
                  _birthDate != null
                      ? '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}'
                      : 'No especificada',
                  style: TextStyle(
                    color: _birthDate != null
                        ? null
                        : theme?.mutedForeground,
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
