import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_date_utils.dart';
import '../../core/user_facing_errors.dart';
import '../../models/notification.dart';
import '../../repositories/challenge_invitation_repository.dart';
import '../../repositories/notification_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationRepo = NotificationRepository();
  final _inviteRepo = ChallengeInvitationRepository();
  List<AppNotification> _notifications = [];
  Set<String> _pendingInviteChallengeIds = {};
  // challengeId → true=aceptado, false=rechazado (solo para esta sesión)
  final Map<String, bool> _respondedInvitations = {};
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
      final results = await Future.wait([
        _notificationRepo.getMyNotifications(),
        _inviteRepo.getMyPendingInvitationChallengeIds(),
      ]);
      if (mounted) {
        setState(() {
          _notifications = results[0] as List<AppNotification>;
          _pendingInviteChallengeIds = results[1] as Set<String>;
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

  Future<void> _respondToInvitation(
    AppNotification notification,
    bool accept,
  ) async {
    final challengeId = notification.relatedChallengeId;
    if (challengeId == null) return;
    setState(() {
      _pendingInviteChallengeIds.remove(challengeId);
      _respondedInvitations[challengeId] = accept;
    });
    try {
      await _inviteRepo.respond(challengeId, accept: accept);
      _markAsRead(notification);
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingInviteChallengeIds.add(challengeId);
          _respondedInvitations.remove(challengeId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == notification.id);
      if (idx >= 0) {
        _notifications = List.from(_notifications);
        _notifications[idx] = notification.copyWith(isRead: true);
      }
    });
    try {
      await _notificationRepo.markAsRead(notification.id);
    } catch (_) {
      // Revertir en caso de error
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == notification.id);
        if (idx >= 0) {
          _notifications = List.from(_notifications);
          _notifications[idx] = notification;
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationRepo.markAllAsRead();
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        });
      }
    } catch (_) {
      // Ignorar error
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    _markAsRead(notification);
    if (notification.relatedPostId != null) {
      context.push('/feed?postId=${notification.relatedPostId}');
    } else if (notification.relatedChallengeId != null) {
      context.push('/challenges/${notification.relatedChallengeId}');
    }
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.comment:
        return Icons.comment;
      case NotificationType.zenit:
        return Icons.favorite;
      case NotificationType.dailyReminder:
        return Icons.notifications;
      case NotificationType.challengeInvitation:
        return Icons.flag_outlined;
      case NotificationType.expertApproved:
        return Icons.workspace_premium;
      case NotificationType.expertRejected:
        return Icons.cancel_outlined;
    }
  }

  Color _getColorForType(NotificationType type, ColorScheme colorScheme) {
    switch (type) {
      case NotificationType.follow:
        return colorScheme.primary;
      case NotificationType.comment:
        return AppSemanticColors.notificationComment;
      case NotificationType.zenit:
        return colorScheme.error;
      case NotificationType.dailyReminder:
        return AppSemanticColors.notificationReminder;
      case NotificationType.challengeInvitation:
        return AppSemanticColors.notificationChallenge;
      case NotificationType.expertApproved:
        return AppSemanticColors.notificationExpertOk;
      case NotificationType.expertRejected:
        return AppSemanticColors.notificationExpertKo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Marcar todas'),
            ),
        ],
      ),
      body: _loading
          ? const SkeletonNotificationsList()
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : _notifications.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none,
                      title: 'No hay notificaciones',
                      subtitle:
                          'Cuando alguien te siga, comente o le dé zenit a tus publicaciones, aparecerán aquí.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, i) {
                          final notification = _notifications[i];
                          final challengeId = notification.relatedChallengeId;
                          final isPending = challengeId != null &&
                              _pendingInviteChallengeIds.contains(challengeId);
                          final respondedAccepted = challengeId != null
                              ? _respondedInvitations[challengeId]
                              : null;
                          return _NotificationTile(
                            notification: notification,
                            theme: theme,
                            colorScheme: colorScheme,
                            onTap: () => _handleNotificationTap(notification),
                            getIcon: _getIconForType,
                            getColor: _getColorForType,
                            onAccept: isPending
                                ? () => _respondToInvitation(notification, true)
                                : null,
                            onDecline: isPending
                                ? () => _respondToInvitation(notification, false)
                                : null,
                            respondedAccepted: respondedAccepted,
                          );
                        },
                      ),
                    ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.theme,
    required this.colorScheme,
    required this.onTap,
    required this.getIcon,
    required this.getColor,
    this.onAccept,
    this.onDecline,
    this.respondedAccepted,
  });

  final AppNotification notification;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final IconData Function(NotificationType) getIcon;
  final Color Function(NotificationType, ColorScheme) getColor;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  /// null = sin respuesta aún; true = aceptado; false = rechazado
  final bool? respondedAccepted;

  bool get _hasActions => onAccept != null || onDecline != null;

  @override
  Widget build(BuildContext context) {
    final typeColor = getColor(notification.type, colorScheme);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? null : theme?.muted.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: typeColor.withValues(alpha: 0.2),
                child: Icon(getIcon(notification.type), color: typeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!notification.isRead && !_hasActions)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notification.body),
                    const SizedBox(height: 4),
                    Text(
                      AppDateUtils.formatRelative(notification.createdAt),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: theme?.mutedForeground,
                            fontSize: 12,
                          ),
                    ),
                    // Botones de acción para invitaciones pendientes
                    if (_hasActions) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: onDecline,
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Rechazar'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 34),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: onAccept,
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Aceptar'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 34),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Estado después de responder en esta sesión
                    if (respondedAccepted != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            respondedAccepted!
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 16,
                            color: respondedAccepted!
                                ? AppSemanticColors.success
                                : theme?.mutedForeground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            respondedAccepted! ? 'Aceptado' : 'Rechazado',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: respondedAccepted!
                                          ? Colors.green
                                          : theme?.mutedForeground,
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
      ),
    );
  }
}
