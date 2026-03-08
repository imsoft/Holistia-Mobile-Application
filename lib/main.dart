import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_router.dart';
import 'core/auth_state.dart' as holistia_auth;
import 'core/config.dart';
import 'core/local_notification_service.dart';
import 'core/supabase_init.dart';
import 'core/theme_mode_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/theme_mode_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? supabaseInitError;
  if (Config.isSupabaseConfigured) {
    try {
      await initSupabase();
    } catch (e) {
      supabaseInitError = e;
    }
  }

  try {
    await LocalNotificationService().initialize();
  } catch (_) {
    // Plugin no disponible en esta plataforma (ej. macOS, web, Windows)
  }

  if (!Config.isSupabaseConfigured) {
    runApp(const _ConfigureSupabaseApp());
    return;
  }

  if (supabaseInitError != null) {
    runApp(_SupabaseInitErrorApp(error: supabaseInitError.toString()));
    return;
  }

  final authState = holistia_auth.HolistiaAuthState();
  await authState.checkInitialUriForPasswordReset();

  final themeController = ThemeModeController();
  await themeController.load();

  runApp(MainApp(authState: authState, themeController: themeController));
}

class _ConfigureSupabaseApp extends StatelessWidget {
  const _ConfigureSupabaseApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appThemeLight,
      darkTheme: appThemeDark,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.settings_outlined, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    'Configura Supabase',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ejecuta con --dart-define=SUPABASE_URL=... y --dart-define=SUPABASE_ANON_KEY=...',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _SupabaseInitErrorApp extends StatelessWidget {
  const _SupabaseInitErrorApp({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appThemeLight,
      darkTheme: appThemeDark,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    'No se pudo conectar con Supabase',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Revisa tus claves y el estado del proyecto en Supabase.\n\n$error',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, required this.authState, required this.themeController});

  final holistia_auth.HolistiaAuthState authState;
  final ThemeModeController themeController;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Router creado una sola vez en initState para evitar resetear la
  // navegación entera cada vez que cambia el tema (PR1).
  late final _router = createAppRouter(widget.authState);

  @override
  void initState() {
    super.initState();
    widget.themeController.notifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.themeController.notifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return ThemeModeScope(
      controller: widget.themeController,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Holistia',
        theme: appThemeLight,
        darkTheme: appThemeDark,
        themeMode: widget.themeController.notifier.value,
        locale: const Locale('es', 'ES'),
        supportedLocales: const [
          Locale('es', 'ES'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
      ),
    );
  }
}
