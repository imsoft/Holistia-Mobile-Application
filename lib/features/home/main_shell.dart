import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/push_notification_service.dart';
import '../../repositories/notification_repository.dart';

/// Scaffold principal con barra de navegación inferior (Retos, Descubrir, Ajustes).
/// Usa [StatefulNavigationShell] para que cada pestaña conserve su estado y no se recargue al cambiar.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  final _notificationRepo = NotificationRepository();
  int _unreadCount = 0;
  StreamSubscription<dynamic>? _notificationSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUnreadCount();
    // Escuchar nuevas notificaciones push para actualizar badge inmediatamente
    _notificationSubscription = PushNotificationService().notificationStream.listen((_) {
      _loadUnreadCount();
    });
    // Recargar cada 30 segundos como respaldo (solo en foreground).
    _startRefreshTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    _stopRefreshTimer();
    super.dispose();
  }

  void _startRefreshTimer() {
    _stopRefreshTimer();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadUnreadCount());
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Cuando la app vuelve a primer plano: recargar badge y reconectar Realtime.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUnreadCount();
      PushNotificationService().restart();
      _startRefreshTimer();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopRefreshTimer();
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationRepo.getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // Ignorar errores
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex.clamp(0, 2),
        onDestinationSelected: (int index) => widget.navigationShell.goBranch(index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Retos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Descubrir',
          ),
          NavigationDestination(
            icon: _NotifBadge(count: _unreadCount, child: const Icon(Icons.person_outline)),
            selectedIcon: _NotifBadge(count: _unreadCount, child: const Icon(Icons.person)),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: _unreadCount > 0
          ? FloatingActionButton.small(
              onPressed: () {
                context.push('/notifications').then((_) => _loadUnreadCount());
              },
              child: _NotifBadge(count: _unreadCount, child: const Icon(Icons.notifications)),
            )
          : null,
    );
  }
}

/// Badge rojo con contador sobre cualquier icono.
/// Muestra "9+" cuando [count] > 9.
class _NotifBadge extends StatelessWidget {
  const _NotifBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
