import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_constants.dart';
import '../../core/apple_auth_service.dart';
import '../../core/auth_error_localized.dart';
import '../../repositories/profile_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_sign_in_button.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../widgets/holistia_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  bool _loading = false;
  bool _loadingGoogle = false;
  bool _loadingApple = false;
  bool _obscurePassword = true;
  String? _error;
  String? _usernameAvailability; // 'available' | 'taken' | 'checking' | null
  String get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return '';
    if (p.length < 6) return 'Corta (mín. 6)';
    if (p.length >= 12 && (p.contains(RegExp(r'[0-9]')) || p.contains(RegExp(r'[^a-zA-Z0-9]')))) return 'Fuerte';
    if (p.length >= 8) return 'Aceptable';
    return 'Débil';
  }

  static String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Elige un nombre de usuario';
    final lower = v.trim().toLowerCase();
    if (lower.length < AppConstants.usernameMinLength) return 'Mínimo ${AppConstants.usernameMinLength} caracteres';
    if (lower.length > AppConstants.usernameMaxLength) return 'Máximo ${AppConstants.usernameMaxLength} caracteres';
    if (!AppConstants.usernameRegex.hasMatch(lower)) {
      return 'Solo letras minúsculas, números y _';
    }
    return null;
  }

  void _onPasswordChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _usernameFocusNode.addListener(_checkUsernameOnBlur);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _usernameFocusNode.removeListener(_checkUsernameOnBlur);
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameOnBlur() async {
    if (_usernameFocusNode.hasFocus) return;
    final v = _usernameController.text.trim().toLowerCase();
    if (v.isEmpty || v.length < AppConstants.usernameMinLength || !AppConstants.usernameRegex.hasMatch(v)) {
      if (mounted) setState(() => _usernameAvailability = null);
      return;
    }
    if (mounted) setState(() => _usernameAvailability = 'checking');
    try {
      final available = await ProfileRepository().checkUsernameAvailableRpc(v);
      if (mounted) setState(() => _usernameAvailability = available ? 'available' : 'taken');
    } catch (_) {
      if (mounted) setState(() => _usernameAvailability = null);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final username = _usernameController.text.trim().toLowerCase();
      final available = await ProfileRepository().checkUsernameAvailableRpc(username);
      if (!available && mounted) {
        setState(() {
          _error = 'Ese nombre de usuario ya está en uso. Elige otro.';
          _loading = false;
        });
        return;
      }
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'display_name': _nameController.text.trim()},
      );
      await ProfileRepository().updateProfile(username: username);
      if (mounted) context.go('/feed');
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = localizedAuthMessage(e);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Algo salió mal. Revisa tu conexión.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _error = null;
      _loadingGoogle = true;
    });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConstants.oauthRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // signInWithOAuth abre Safari y regresa de inmediato.
      // GoRouter navega automáticamente cuando onAuthStateChange dispara.
      if (mounted) setState(() => _loadingGoogle = false);
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = localizedAuthMessage(e);
          _loadingGoogle = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo crear cuenta con Google.';
          _loadingGoogle = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _error = null;
      _loadingApple = true;
    });
    final result = await AppleAuthService().signInWithApple();
    if (!mounted) return;
    setState(() => _loadingApple = false);
    switch (result) {
      case AppleSignInSuccess():
        context.go('/feed');
        break;
      case AppleSignInCancelled():
        break;
      case AppleSignInFailure(:final message):
        setState(() => _error = message);
        break;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Center(child: HolistiaLogo(width: 120)),
                const SizedBox(height: 24),
                Text(
                  'Crear cuenta',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Comienza a medir y celebrar tus retos.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: theme?.mutedForeground,
                      ),
                ),
                const SizedBox(height: 32),
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
                  focusNode: _usernameFocusNode,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    labelText: 'Nombre de usuario',
                    hintText: 'ej. maria_holistia',
                    helperText: _usernameAvailability == null
                        ? '3-30 caracteres: letras, números y _'
                        : _usernameAvailability == 'checking'
                            ? 'Comprobando...'
                            : _usernameAvailability == 'available'
                                ? 'Disponible'
                                : 'En uso',
                    helperStyle: TextStyle(
                      color: _usernameAvailability == 'available'
                          ? Colors.green
                          : _usernameAvailability == 'taken'
                              ? colorScheme.error
                              : theme?.mutedForeground,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                    ),
                  ),
                  validator: _validateUsername,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Escribe tu correo';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                if (_passwordStrength.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _passwordStrength,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _passwordStrength.startsWith('Fuerte')
                              ? Colors.green
                              : _passwordStrength.startsWith('Aceptable')
                                  ? Colors.orange
                                  : theme?.mutedForeground,
                        ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: theme?.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'o',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: theme?.mutedForeground,
                            ),
                      ),
                    ),
                    Expanded(child: Divider(color: theme?.border)),
                  ],
                ),
                const SizedBox(height: 24),
                GoogleSignInButton(
                  onPressed: _signInWithGoogle,
                  loading: _loadingGoogle,
                ),
                if (AppleSignInButton.isSupported) ...[
                  const SizedBox(height: 16),
                  AppleSignInButton(
                    onPressed: _signInWithApple,
                    loading: _loadingApple,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _submit();
                          }
                        },
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
                      : const Text('Registrarme'),
                ),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    text: 'Al registrarte aceptas nuestra ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme?.mutedForeground,
                        ),
                    children: [
                      TextSpan(
                        text: 'Política de Privacidad',
                        style: TextStyle(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _launchUrl(AppConstants.privacyPolicyUrl),
                      ),
                      const TextSpan(text: ' y los '),
                      TextSpan(
                        text: 'Términos de Servicio',
                        style: TextStyle(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _launchUrl(AppConstants.termsUrl),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  },
        ),
      ),
    );
  }
}
