import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_constants.dart';
import '../../core/local_notification_service.dart';
import '../../core/user_facing_errors.dart';
import '../../core/profile_options.dart';
import '../../core/zenit_level.dart';
import '../../models/expert_request.dart';
import '../../models/profile.dart';
import '../../repositories/expert_request_repository.dart';
import '../../repositories/follow_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/expert_badge.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/theme_mode_scope.dart';

const _keyReminderHour = 'pref_reminder_hour';
const _keyReminderMinute = 'pref_reminder_minute';
const _keyReminderEnabled = 'pref_reminder_enabled';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _profileRepo = ProfileRepository();
  final _followRepo = FollowRepository();
  final _expertRequestRepo = ExpertRequestRepository();
  String? _displayName;
  String? _username;
  String? _avatarUrl;
  String? _sex;
  DateTime? _birthDate;
  bool _isPublic = true;
  UserRole _role = UserRole.user;
  ExpertRequest? _expertRequest;
  int _followerCount = 0;
  int _followingCount = 0;
  int _zenitBalance = 0;
  bool _loading = true;
  bool _uploadingAvatar = false;
  String? _error;
  bool _reminderEnabled = true;
  int _reminderHour = 9;
  int _reminderMinute = 0;

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
      // Settings is only reachable when authenticated, so uid is always set.
      final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
      final results = await Future.wait([
        _profileRepo.getMyProfile(),
        _followRepo.getFollowerCount(uid),
        _followRepo.getFollowingCount(uid),
        _expertRequestRepo.getMyRequest(),
      ]);
      final p = results[0] as AppProfile?;
      final followers = results[1] as int;
      final following = results[2] as int;
      final expertRequest = results[3] as ExpertRequest?;
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _displayName = p?.displayName ?? '';
          _username = p?.username;
          _avatarUrl = p?.avatarUrl;
          _sex = p?.sex;
          _birthDate = p?.birthDate;
          _isPublic = p?.isPublic ?? true;
          _role = p?.role ?? UserRole.user;
          _zenitBalance = p?.zenitBalance ?? 0;
          _expertRequest = expertRequest;
          _followerCount = followers;
          _followingCount = following;
          _reminderEnabled = prefs.getBool(_keyReminderEnabled) ?? true;
          _reminderHour = prefs.getInt(_keyReminderHour) ?? 9;
          _reminderMinute = prefs.getInt(_keyReminderMinute) ?? 0;
          _loading = false;
        });
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

  Future<void> _updateIsPublic(bool value) async {
    setState(() => _isPublic = value);
    try {
      await _profileRepo.updateProfile(isPublic: value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value ? 'Perfil público' : 'Perfil privado')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublic = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _updateSex(String? value) async {
    final toSave = value == null || value.isEmpty ? null : value;
    final prev = _sex;
    setState(() => _sex = toSave);
    try {
      await _profileRepo.updateProfile(sex: value ?? '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sexo actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sex = prev);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _updateBirthDate(DateTime? value) async {
    final prev = _birthDate;
    setState(() => _birthDate = value);
    try {
      await _profileRepo.updateProfile(birthDate: value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fecha de nacimiento actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _birthDate = prev);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _updateDisplayName(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    setState(() => _displayName = trimmed);
    try {
      await _profileRepo.updateProfile(displayName: trimmed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nombre actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  void _showThemeModePicker(BuildContext context) {
    final controller = ThemeModeScope.of(context);
    final current = controller.notifier.value;

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tema',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.brightness_auto,
                color: current == ThemeMode.system
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: const Text('Sistema'),
              subtitle: const Text('Usar la configuración del dispositivo'),
              selected: current == ThemeMode.system,
              onTap: () async {
                await controller.setThemeMode(ThemeMode.system);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.light_mode_outlined,
                color: current == ThemeMode.light
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: const Text('Claro'),
              selected: current == ThemeMode.light,
              onTap: () async {
                await controller.setThemeMode(ThemeMode.light);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.dark_mode_outlined,
                color: current == ThemeMode.dark
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: const Text('Oscuro'),
              selected: current == ThemeMode.dark,
              onTap: () async {
                await controller.setThemeMode(ThemeMode.dark);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Esta acción es irreversible. Se eliminarán tu cuenta y todos tus datos permanentemente.\n\n¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar mi cuenta'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      // Llama a la función delete_user() en Supabase (ver docs/delete_user.sql)
      await Supabase.instance.client.rpc(AppConstants.deleteUserRpc);
      await Supabase.instance.client.auth.signOut();
      if (mounted) GoRouter.of(context).go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();

    final uid = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: _loading
          ? const SkeletonSettingsList()
          : _error != null
              ? ErrorRetry(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: GestureDetector(
                        onTap: _uploadingAvatar ? null : _showAvatarOptions,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: theme?.muted,
                              backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? NetworkImage(_avatarUrl!)
                                  : null,
                              child: _avatarUrl == null || _avatarUrl!.isEmpty
                                  ? Text(
                                      (_displayName ?? '?').isNotEmpty
                                          ? (_displayName!)[0].toUpperCase()
                                          : '?',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            color: theme?.mutedForeground,
                                          ),
                                    )
                                  : null,
                            ),
                            if (_uploadingAvatar)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme?.muted ?? Colors.grey),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                            )
                          else
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: IgnorePointer(
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatChip(
                          value: _followerCount,
                          label: 'Seguidores',
                          theme: theme,
                        ),
                        const SizedBox(width: 24),
                        _StatChip(
                          value: _followingCount,
                          label: 'Siguiendo',
                          theme: theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ZenitCard(balance: _zenitBalance, theme: theme),
                    if (uid != null && uid.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/user/$uid'),
                        icon: const Icon(Icons.person_outline, size: 20),
                        label: const Text('Ver mi perfil público'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: const Text('Editar perfil completo'),
                            subtitle: const Text('Nombre, usuario, sexo, fecha de nacimiento'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/settings/edit-profile').then((_) => _load()),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.photo_camera_outlined),
                            title: const Text('Cambiar foto de perfil'),
                            subtitle: Text(
                              _avatarUrl != null && _avatarUrl!.isNotEmpty ? 'Toca para cambiar' : 'Añade una foto',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: theme?.mutedForeground,
                                  ),
                            ),
                            onTap: _uploadingAvatar ? null : _showAvatarOptions,
                          ),
                          ListTile(
                            title: const Text('Perfil público'),
                            subtitle: Text(
                              _isPublic ? 'Tu perfil y retos públicos son visibles' : 'Solo tú ves tu perfil',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: theme?.mutedForeground,
                                  ),
                            ),
                            trailing: Switch(
                              value: _isPublic,
                              onChanged: _updateIsPublic,
                            ),
                          ),
                          ListTile(
                            title: const Text('Nombre'),
                            subtitle: Text(_displayName ?? 'Sin nombre'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showNameDialog(),
                            ),
                          ),
                          ListTile(
                            title: const Text('Nombre de usuario'),
                            subtitle: Text(_username != null && _username!.isNotEmpty ? '@$_username' : 'Sin configurar'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showUsernameDialog(),
                            ),
                          ),
                          ListTile(
                            title: const Text('Sexo'),
                            subtitle: Text(
                              ProfileSexOptions.getLabel(_sex) ?? 'No especificado',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: theme?.mutedForeground,
                                  ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showSexDialog(),
                            ),
                          ),
                          ListTile(
                            title: const Text('Fecha de nacimiento'),
                            subtitle: Text(
                              _birthDate != null
                                  ? '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}'
                                  : 'No especificada',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: theme?.mutedForeground,
                                  ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showBirthDatePicker(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Cuenta',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: theme?.mutedForeground,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.emoji_events_outlined),
                            title: const Text('Mis Logros'),
                            subtitle: const Text('Niveles y hitos Zenit'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/achievements'),
                          ),
                          const Divider(height: 1),
                          if (_role.isAdmin)
                            ListTile(
                              leading: const Icon(Icons.admin_panel_settings_outlined),
                              title: const Text('Panel de Administración'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/admin'),
                            ),
                          if (_role.isExpert)
                            const ListTile(
                              leading: Icon(Icons.workspace_premium, color: Colors.amber),
                              title: Text('Cuenta Experto'),
                              subtitle: Text('Tu solicitud fue aprobada'),
                              trailing: ExpertBadge(label: 'Experto'),
                            ),
                          if (_role == UserRole.user) ...[
                            if (_expertRequest?.status == ExpertRequestStatus.pending)
                              const ListTile(
                                leading: Icon(Icons.hourglass_top_outlined),
                                title: Text('Solicitud de Experto'),
                                subtitle: Text('En revisión — te avisaremos pronto'),
                                trailing: Icon(Icons.pending_outlined),
                              )
                            else
                              ListTile(
                                leading: const Icon(Icons.workspace_premium_outlined),
                                title: Text(
                                  _expertRequest?.status == ExpertRequestStatus.rejected
                                      ? 'Volver a solicitar ser Experto'
                                      : 'Solicitar ser Experto',
                                ),
                                subtitle: Text(
                                  _expertRequest?.status == ExpertRequestStatus.rejected
                                      ? 'Tu solicitud anterior no fue aprobada'
                                      : 'Crea retos para que otros usuarios los cumplan',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: theme?.mutedForeground,
                                      ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: _showExpertRequestDialog,
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Apariencia',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: theme?.mutedForeground,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.palette_outlined),
                        title: const Text('Tema'),
                        subtitle: ValueListenableBuilder<ThemeMode>(
                          valueListenable: ThemeModeScope.of(context).notifier,
                          builder: (context, mode, _) {
                            final label = mode == ThemeMode.system
                                ? 'Sistema'
                                : mode == ThemeMode.light
                                    ? 'Claro'
                                    : 'Oscuro';
                            return Text(
                              label,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: theme?.mutedForeground,
                                  ),
                            );
                          },
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showThemeModePicker(context),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Notificaciones',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: theme?.mutedForeground,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            secondary: const Icon(Icons.notifications_outlined),
                            title: const Text('Recordatorio diario'),
                            subtitle: const Text('Recibe un aviso para registrar tus retos'),
                            value: _reminderEnabled,
                            onChanged: (v) async {
                              setState(() => _reminderEnabled = v);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool(_keyReminderEnabled, v);
                              if (v) {
                                await LocalNotificationService().scheduleDailyReminder(
                                  hour: _reminderHour,
                                  minute: _reminderMinute,
                                );
                              } else {
                                await LocalNotificationService().cancelDailyReminder();
                              }
                            },
                          ),
                          if (_reminderEnabled) ...[
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.access_time_outlined),
                              title: const Text('Hora del recordatorio'),
                              trailing: Text(
                                '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                    hour: _reminderHour,
                                    minute: _reminderMinute,
                                  ),
                                  helpText: 'Hora del recordatorio',
                                );
                                if (picked != null && mounted) {
                                  setState(() {
                                    _reminderHour = picked.hour;
                                    _reminderMinute = picked.minute;
                                  });
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setInt(_keyReminderHour, picked.hour);
                                  await prefs.setInt(_keyReminderMinute, picked.minute);
                                  await LocalNotificationService().scheduleDailyReminder(
                                    hour: picked.hour,
                                    minute: picked.minute,
                                  );
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Sesión',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: theme?.mutedForeground,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.logout_outlined),
                        title: const Text('Cerrar sesión'),
                        onTap: () async {
                          final router = GoRouter.of(context);
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) router.go('/login');
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Legal',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: theme?.mutedForeground,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.privacy_tip_outlined),
                            title: const Text('Política de Privacidad'),
                            trailing: const Icon(Icons.open_in_new, size: 18),
                            onTap: () => _launchUrl(AppConstants.privacyPolicyUrl),
                          ),
                          ListTile(
                            leading: const Icon(Icons.description_outlined),
                            title: const Text('Términos de Servicio'),
                            trailing: const Icon(Icons.open_in_new, size: 18),
                            onTap: () => _launchUrl(AppConstants.termsUrl),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Zona de peligro',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_forever_outlined,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          'Eliminar cuenta',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        subtitle: const Text('Elimina tu cuenta y todos tus datos permanentemente'),
                        onTap: _deleteAccount,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
    );
  }

  Future<void> _showExpertRequestDialog() async {
    final bioController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Solicitar ser Experto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuéntanos por qué quieres ser Experto en Holistia. El equipo revisará tu solicitud.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Ej: Soy entrenador personal con 5 años de experiencia...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final bio = bioController.text.trim();
    if (bio.isEmpty) return;

    try {
      await _expertRequestRepo.submit(bio);
      if (mounted) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud enviada. Te avisaremos pronto.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(userFacingErrorMessage(e))));
      }
    }
  }

  Future<void> _showAvatarOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (xFile == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final url = await _profileRepo.uploadAvatar(xFile.path);
      if (url != null) {
        await _profileRepo.updateProfile(avatarUrl: url);
        if (mounted) {
          setState(() {
            _avatarUrl = url;
            _uploadingAvatar = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil actualizada')),
          );
        }
      } else {
        if (mounted) setState(() => _uploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir la imagen')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _showNameDialog() async {
    final controller = TextEditingController(text: _displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Tu nombre',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      _updateDisplayName(result);
    }
  }

  // username regex centralizada en AppConstants.usernameRegex

  Future<void> _showUsernameDialog() async {
    final controller = TextEditingController(text: _username);
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Nombre de usuario'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: '@username',
                    hintText: 'ej. maria_holistia',
                    errorText: error,
                    helperText: '3-30 caracteres: letras, números y _',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  final v = controller.text.trim().toLowerCase();
                  if (v.isEmpty) {
                    setDialogState(() => error = 'Elige un nombre de usuario');
                    return;
                  }
                  if (v.length < 3 || v.length > 30) {
                    setDialogState(() => error = 'Entre 3 y 30 caracteres');
                    return;
                  }
                  if (!AppConstants.usernameRegex.hasMatch(v)) {
                    setDialogState(() => error = 'Solo letras minúsculas, números y _');
                    return;
                  }
                  final uid = Supabase.instance.client.auth.currentUser?.id;
                  final available = await _profileRepo.isUsernameAvailable(v, excludeUserId: uid);
                  if (!available && mounted) {
                    setDialogState(() => error = 'Ese nombre ya está en uso');
                    return;
                  }
                  Navigator.pop(context);
                  _updateUsername(v);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateUsername(String value) async {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return;
    final previous = _username;
    setState(() => _username = trimmed);
    try {
      await _profileRepo.updateProfile(username: trimmed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nombre de usuario actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _username = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _showSexDialog() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Selecciona tu sexo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ...ProfileSexOptions.options.entries.map((e) => ListTile(
                  title: Text(e.value),
                  onTap: () => Navigator.pop(context, e.key),
                )),
            ListTile(
              title: const Text('No especificar'),
              onTap: () => Navigator.pop(context, ''),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      _updateSex(result.isEmpty ? null : result);
    }
  }

  Future<void> _showBirthDatePicker() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final result = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: initial,
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (result != null && mounted) {
      _updateBirthDate(result);
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.theme,
  });

  final int value;
  final String label;
  final AppThemeExtension? theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme?.mutedForeground,
              ),
        ),
      ],
    );
  }
}

class _ZenitCard extends StatelessWidget {
  const _ZenitCard({required this.balance, required this.theme});

  final int balance;
  final AppThemeExtension? theme;

  @override
  Widget build(BuildContext context) {
    final level = ZenitLevel.fromBalance(balance);
    final progress = level.progress(balance);
    final next = level.nextLevelAt;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(level.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  level.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: level.color,
                      ),
                ),
                const Spacer(),
                Text(
                  '$balance zenits',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme?.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: level.color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(level.color),
                minHeight: 6,
              ),
            ),
            if (next != null) ...[
              const SizedBox(height: 4),
              Text(
                '${next - balance} zenits para ${ZenitLevel.fromBalance(next).label}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: theme?.mutedForeground,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
