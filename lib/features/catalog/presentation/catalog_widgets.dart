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
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.category,
    required this.onTap,
    super.key,
  });

  final ServiceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Buscar por ${category.name}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 116,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9E1E4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5EAED),
                  shape: BoxShape.circle,
                ),
                child: Icon(categoryIcon(category.iconKey), color: AppColors.wine),
              ),
              const SizedBox(height: 10),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
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
      child: Card(
        color: pro ? AppColors.wineDark : Colors.white,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: pro ? AppColors.gold : const Color(0xFFF2E7EA),
                      foregroundColor: pro ? AppColors.wineDark : AppColors.wine,
                      child: Text(
                        provider.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
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
                                  provider.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: pro ? Colors.white : AppColors.ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              if (provider.isVerified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.verified, color: Color(0xFF49A6FF), size: 18),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${provider.category.name} • ${provider.providerType}',
                            style: TextStyle(
                              color: pro ? Colors.white70 : AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onFavorite,
                      tooltip: isFavorite ? 'Remover dos favoritos' : 'Favoritar',
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? (pro ? AppColors.gold : AppColors.wine)
                            : (pro ? Colors.white70 : AppColors.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (pro)
                      const _Pill(
                        icon: Icons.workspace_premium,
                        label: 'PRO • Destaque patrocinado',
                        dark: true,
                      ),
                    if (provider.isOpen24Hours)
                      _Pill(icon: Icons.schedule, label: '24 horas', dark: pro),
                  ],
                ),
                const Spacer(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 18, color: pro ? Colors.white70 : AppColors.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${provider.city} - ${provider.state}',
                        style: TextStyle(color: pro ? Colors.white70 : AppColors.muted),
                      ),
                    ),
                    if (provider.distanceKm != null)
                      Text(
                        '${provider.distanceKm!.toStringAsFixed(1)} km',
                        style: TextStyle(
                          color: pro ? Colors.white : AppColors.wine,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.dark});

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: .12) : const Color(0xFFF4ECEE),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: dark ? AppColors.gold : AppColors.wine),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : AppColors.wine,
            ),
          ),
        ],
      ),
    );
  }
}

