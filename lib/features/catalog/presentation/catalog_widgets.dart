import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/catalog_models.dart';

IconData categoryIcon(String key) => switch (key) {
      'car' => Icons.car_repair,
      'bolt' => Icons.electrical_services,
      'water' => Icons.plumbing,
      'build' => Icons.construction,
      'handyman' => Icons.handyman,
      'clean' => Icons.cleaning_services,
      'computer' => Icons.computer,
      _ => Icons.home_repair_service,
    };

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 26,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gold, AppColors.wineSoft],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          TextButton.icon(
            onPressed: onAction,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward, size: 17),
            label: Text(action!),
          ),
      ],
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.category,
    required this.onTap,
    super.key,
    this.expanded = false,
  });

  final ServiceCategory category;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final tile = Semantics(
      button: true,
      label: 'Buscar por ${category.name}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            width: expanded ? null : 126,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE9DDE1)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.wine.withValues(alpha: .05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFEFF3),
                        AppColors.goldSoft.withValues(alpha: .55),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categoryIcon(category.iconKey),
                    color: AppColors.wine,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return expanded ? Expanded(child: tile) : tile;
  }
}

class ProviderCard extends StatelessWidget {
  const ProviderCard({
    required this.provider,
    required this.isFavorite,
    required this.onOpen,
    required this.onFavorite,
    super.key,
  });

  final ProviderProfile provider;
  final bool isFavorite;
  final VoidCallback onOpen;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final pro = provider.isPro;
    return Semantics(
      button: true,
      label: 'Abrir perfil de ${provider.displayName}',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: pro ? AppColors.gold : const Color(0xFFE8DEE1),
            width: pro ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (pro ? AppColors.wine : AppColors.ink)
                  .withValues(alpha: pro ? .14 : .07),
              blurRadius: pro ? 30 : 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProviderPhoto(provider: provider),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xA8000000)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [.42, 1],
                          ),
                        ),
                      ),
                      if (pro)
                        const Positioned(
                          left: 14,
                          top: 14,
                          child: _Badge(
                            icon: Icons.workspace_premium,
                            label: 'PRO • DESTAQUE',
                          ),
                        ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Material(
                          color: Colors.white.withValues(alpha: .94),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: onFavorite,
                            tooltip: isFavorite
                                ? 'Remover dos favoritos'
                                : 'Favoritar',
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? AppColors.wine
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                provider.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19,
                                  shadows: [Shadow(blurRadius: 8)],
                                ),
                              ),
                            ),
                            if (provider.isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 6, bottom: 2),
                                child: Icon(
                                  Icons.verified,
                                  color: Color(0xFF65B8FF),
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${provider.category.name} • ${provider.providerType}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (provider.isOpen24Hours)
                            const _StatusPill(label: '24 horas'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: AppColors.wine,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${provider.city} - ${provider.state}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (provider.distanceKm != null)
                            Text(
                              '${provider.distanceKm!.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: AppColors.wine,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProviderPhoto extends StatelessWidget {
  const ProviderPhoto({required this.provider, super.key, this.fit = BoxFit.cover});

  final ProviderProfile provider;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final imageUrl = provider.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _PhotoFallback(provider: provider);
    }
    return Image.network(
      imageUrl,
      fit: fit,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => _PhotoFallback(provider: provider),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _PhotoFallback(provider: provider),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.provider});

  final ProviderProfile provider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.wineDark, AppColors.wine, AppColors.wineSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              categoryIcon(provider.category.iconKey),
              color: Colors.white70,
              size: 42,
            ),
            const SizedBox(height: 8),
            Text(
              provider.displayName.isEmpty
                  ? 'C'
                  : provider.displayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(color: Color(0x44000000), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.wineDark),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.wineDark,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: .35,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.success,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
