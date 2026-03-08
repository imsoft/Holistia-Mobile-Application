import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/onboarding_storage.dart';
import '../../theme/app_theme.dart';
import '../../widgets/holistia_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const List<({String title, String body, IconData icon})> _pages = [
    (
      title: 'Tus retos, a tu manera',
      body: 'Crea retos personalizados: días seguidos, veces por semana o metas por unidades. Tú defines la meta.',
      icon: Icons.flag_outlined,
    ),
    (
      title: 'Progreso visible',
      body: 'Registra tu avance y mira niveles e insignias. Así sabes dónde estás y qué sigue.',
      icon: Icons.trending_up_outlined,
    ),
    (
      title: 'Comunidad y Zenit',
      body: 'Comparte tus avances y recibe Zenit de otros. Constancia y energía social en un solo lugar.',
      icon: Icons.auto_awesome_outlined,
    ),
  ];

  Future<void> _finish() async {
    await setOnboardingSeen();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: HolistiaLogo(width: 100),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          p.icon,
                          size: 80,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          p.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.body,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: theme?.mutedForeground,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i
                          ? colorScheme.primary
                          : (theme?.mutedForeground ?? Colors.grey).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _page < _pages.length - 1
                          ? () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : _finish,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                        ),
                      ),
                      child: Text(_page < _pages.length - 1 ? 'Siguiente' : 'Comenzar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _page < _pages.length - 1
                        ? () {
                            _pageController.animateToPage(
                              _pages.length - 1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : _finish,
                    child: Text(_page < _pages.length - 1 ? 'Omitir' : 'Listo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
