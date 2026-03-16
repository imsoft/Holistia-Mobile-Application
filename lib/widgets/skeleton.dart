import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

/// Placeholder animado (shimmer) para cargas.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme?.muted ?? Colors.grey.shade200,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

/// Envuelve hijos en efecto shimmer.
class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = baseColor ?? (theme?.muted ?? Colors.grey.shade300);
    final highlight = highlightColor ??
        (isDark ? Colors.grey.shade600 : Colors.grey.shade100);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: child,
    );
  }
}

/// Lista de retos (skeleton para Home).
class SkeletonChallengeList extends StatelessWidget {
  const SkeletonChallengeList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();

    return ShimmerSkeleton(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, i) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Skeleton(height: 18, width: 180, borderRadius: BorderRadius.circular(4)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Skeleton(height: 14, width: 120, borderRadius: BorderRadius.circular(4)),
            ),
            trailing: const Skeleton(width: 24, height: 24, borderRadius: BorderRadius.all(Radius.circular(4))),
          ),
        ),
      ),
    );
  }
}

/// Lista de posts (skeleton para Feed).
class SkeletonPostList extends StatelessWidget {
  const SkeletonPostList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();

    return ShimmerSkeleton(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, i) => Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Skeleton(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Skeleton(height: 16, width: 120, borderRadius: BorderRadius.circular(4)),
                          const SizedBox(height: 6),
                          Skeleton(height: 12, width: 80, borderRadius: BorderRadius.circular(4)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Skeleton(height: 14, width: double.infinity, borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: 6),
                Skeleton(height: 14, width: 200, borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Skeleton(height: 24, width: 60, borderRadius: BorderRadius.circular(12)),
                    const SizedBox(width: 16),
                    Skeleton(height: 24, width: 50, borderRadius: BorderRadius.circular(12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Detalle de reto (skeleton para ChallengeDetail).
class SkeletonChallengeDetail extends StatelessWidget {
  const SkeletonChallengeDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ShimmerSkeleton(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(height: 22, width: 160, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 8),
                      Skeleton(height: 16, width: 200, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 16),
                      Skeleton(height: 8, width: double.infinity, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Skeleton(height: 52, width: double.infinity, borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8)),
              const SizedBox(height: 24),
              Skeleton(height: 16, width: 80, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 12),
              ...List.generate(5, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Skeleton(height: 20, width: 100, borderRadius: BorderRadius.circular(4)),
                    const Spacer(),
                    Skeleton(height: 20, width: 40, borderRadius: BorderRadius.circular(4)),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista de ajustes (skeleton para Settings/Profile).
class SkeletonSettingsList extends StatelessWidget {
  const SkeletonSettingsList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();

    return ShimmerSkeleton(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Skeleton(height: 14, width: 60, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Skeleton(height: 18, width: 120, borderRadius: BorderRadius.circular(4)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Skeleton(height: 14, width: 200, borderRadius: BorderRadius.circular(4)),
                  ),
                  trailing: const Skeleton(width: 48, height: 28, borderRadius: BorderRadius.all(Radius.circular(14))),
                ),
                ListTile(
                  title: Skeleton(height: 18, width: 80, borderRadius: BorderRadius.circular(4)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Skeleton(height: 14, width: 100, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Skeleton(height: 14, width: 60, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
            ),
            child: ListTile(
              leading: const Skeleton(width: 24, height: 24, borderRadius: BorderRadius.all(Radius.circular(4))),
              title: Skeleton(height: 18, width: 120, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Comentarios (skeleton para PostDetailSheet).
class SkeletonComments extends StatelessWidget {
  const SkeletonComments({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(height: 16, width: 100, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 12),
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(width: 32, height: 32, borderRadius: BorderRadius.all(Radius.circular(16))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(height: 14, width: 80, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 6),
                      Skeleton(height: 14, width: double.infinity, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 4),
                      Skeleton(height: 12, width: 60, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

/// Lista de notificaciones (skeleton para NotificationsScreen).
class SkeletonNotificationsList extends StatelessWidget {
  const SkeletonNotificationsList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();

    return ShimmerSkeleton(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, i) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
          ),
          child: ListTile(
            leading: const Skeleton(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
            title: Skeleton(height: 16, width: 150, borderRadius: BorderRadius.circular(4)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(height: 14, width: double.infinity, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 4),
                  Skeleton(height: 12, width: 80, borderRadius: BorderRadius.circular(4)),
                ],
              ),
            ),
            trailing: const Skeleton(width: 8, height: 8, borderRadius: BorderRadius.all(Radius.circular(4))),
          ),
        ),
      ),
    );
  }
}

/// Lista de lugares (skeleton para ProfessionalsScreen).
class SkeletonPlaceList extends StatelessWidget {
  const SkeletonPlaceList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();

    return ShimmerSkeleton(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, i) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme?.radiusLg ?? 12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Skeleton(height: 160, width: double.infinity),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Skeleton(height: 20, width: 160, borderRadius: BorderRadius.circular(4)),
                        ),
                        const SizedBox(width: 8),
                        Skeleton(height: 24, width: 70, borderRadius: BorderRadius.circular(12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Skeleton(height: 14, width: double.infinity, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 4),
                    Skeleton(height: 14, width: 120, borderRadius: BorderRadius.circular(4)),
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

/// Contenido de perfil de usuario en carga (skeleton para UserProfileScreen).
class SkeletonUserProfile extends StatelessWidget {
  const SkeletonUserProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();

    return ShimmerSkeleton(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Skeleton(width: 88, height: 88, borderRadius: BorderRadius.all(Radius.circular(44))),
            const SizedBox(height: 12),
            Skeleton(height: 24, width: 140, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 8),
            Skeleton(height: 18, width: 100, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Skeleton(height: 36, width: 60, borderRadius: BorderRadius.circular(4)),
                const SizedBox(width: 24),
                Skeleton(height: 36, width: 60, borderRadius: BorderRadius.circular(4)),
              ],
            ),
            const SizedBox(height: 24),
            Skeleton(height: 16, width: 120, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 12),
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(height: 14, width: 80, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 12),
                      Skeleton(height: 120, width: double.infinity, borderRadius: BorderRadius.circular(8)),
                      const SizedBox(height: 12),
                      Skeleton(height: 14, width: double.infinity, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
