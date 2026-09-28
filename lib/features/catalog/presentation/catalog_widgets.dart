import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/platform/whatsapp_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/catalog_models.dart';

Future<void> openProviderWhatsApp(
  BuildContext context,
  ProviderProfile provider,
) async {
  final opened = await launchWhatsApp(
    phone: provider.whatsapp,
    message:
        'Olá, ${provider.displayName}! Encontrei seu perfil no CormeX Easy e gostaria de saber mais sobre seus serviços.',
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
    );
  }
}

IconData categoryIcon(String key) => switch (key) {
      'car' => Icons.car_repair,
      'bolt' => Icons.electrical_services,
      'water' => Icons.plumbing,
      'build' => Icons.construction,
      'handyman' => Icons.handyman,
      'clean' => Icons.cleaning_services,
      'computer' => Icons.computer,
      'paint' => Icons.format_paint,
      'garden' => Icons.yard,
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
    this.selected = false,
  });

  final ServiceCategory category;
  final VoidCallback onTap;
  final bool expanded;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tile = Semantics(
      button: true,
      selected: selected,
      label: selected
          ? '${category.name} selecionada'
          : 'Filtrar por ${category.name}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            width: expanded ? null : 126,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.wine : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.gold : const Color(0xFFE9DDE1),
                width: selected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.wine.withValues(
                    alpha: selected ? .2 : .05,
                  ),
                  blurRadius: selected ? 20 : 18,
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
                      colors: selected
                          ? [
                              AppColors.wineSoft,
                              AppColors.wineDark,
                            ]
                          : [
                              const Color(0xFFFFEFF3),
                              AppColors.goldSoft.withValues(alpha: .55),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(
                            color: AppColors.gold.withValues(alpha: .65),
                          )
                        : null,
                  ),
                  child: Icon(
                    categoryIcon(category.iconKey),
                    color: selected ? Colors.white : AppColors.wine,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: FontWeight.w800,
                  ),
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

class ProviderCard extends StatefulWidget {
  const ProviderCard({
    required this.provider,
    required this.isFavorite,
    required this.onOpen,
    required this.onFavorite,
    required this.onWhatsApp,
    super.key,
  });

  final ProviderProfile provider;
  final bool isFavorite;
  final VoidCallback onOpen;
  final VoidCallback onFavorite;
  final VoidCallback onWhatsApp;

  @override
  State<ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<ProviderCard> {
  bool _showBack = false;

  void _flip() => setState(() => _showBack = !_showBack);

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return Semantics(
      button: true,
      label: _showBack
          ? 'Serviços de ${provider.displayName}. Toque para voltar.'
          : 'Informações de ${provider.displayName}. Toque para ver os serviços.',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: _showBack ? 1 : 0),
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeInOutCubic,
        builder: (context, value, child) {
          final angle = value * math.pi;
          final showingBack = value >= .5;
          final face = showingBack ? _buildBack() : _buildFront();
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .0012)
              ..rotateY(angle),
            child: showingBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: face,
                  )
                : face,
          );
        },
      ),
    );
  }

  BoxDecoration _decoration({bool back = false}) {
    final pro = widget.provider.isPro;
    return BoxDecoration(
      color: Colors.white,
      gradient: back
          ? const LinearGradient(
              colors: [Colors.white, Color(0xFFFFF7F2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
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
    );
  }

  Widget _buildFront() {
    final provider = widget.provider;
    final serviceArea = provider.serviceArea.isEmpty
        ? '${provider.city} e região'
        : provider.serviceArea;
    return Container(
      decoration: _decoration(),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _flip,
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
                          colors: [Colors.transparent, Color(0xB0000000)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [.38, 1],
                        ),
                      ),
                    ),
                    if (provider.isPro)
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
                          onPressed: widget.onFavorite,
                          tooltip: widget.isFavorite
                              ? 'Remover dos favoritos'
                              : 'Favoritar',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            widget.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: widget.isFavorite
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
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
                              color: AppColors.wine,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (provider.isOpen24Hours)
                          const _StatusPill(label: '24 horas'),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      provider.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InfoLine(
                      icon: Icons.location_on_outlined,
                      text: '${provider.city} - ${provider.state}',
                      trailing: provider.distanceKm == null
                          ? null
                          : '${provider.distanceKm!.toStringAsFixed(1)} km',
                    ),
                    const SizedBox(height: 5),
                    _InfoLine(
                      icon: Icons.near_me_outlined,
                      text: 'Atende: $serviceArea',
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sync, size: 16, color: AppColors.wine),
                        SizedBox(width: 5),
                        Text(
                          'Toque para ver serviços',
                          style: TextStyle(
                            color: AppColors.wine,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
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
    );
  }

  Widget _buildBack() {
    final provider = widget.provider;
    final services = provider.services.isEmpty
        ? <String>[provider.category.name]
        : provider.services;
    final visibleServices = services.take(3).toList();
    final hiddenServices = services.length - visibleServices.length;
    final serviceArea = provider.serviceArea.isEmpty
        ? '${provider.city} e região'
        : provider.serviceArea;

    return Container(
      decoration: _decoration(back: true),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _flip,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.wine,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        categoryIcon(provider.category.iconKey),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SERVIÇOS OFERECIDOS',
                            style: TextStyle(
                              color: AppColors.wine,
                              fontSize: 11,
                              letterSpacing: .65,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            provider.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _flip,
                      tooltip: 'Voltar para as informações',
                      icon: const Icon(Icons.close, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (final service in visibleServices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 19,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            service,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (hiddenServices > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9, left: 28),
                    child: Text(
                      '+ $hiddenServices ${hiddenServices == 1 ? 'outro serviço' : 'outros serviços'}',
                      style: const TextStyle(
                        color: AppColors.wine,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const Divider(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.near_me_outlined,
                      color: AppColors.wine,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Atende em $serviceArea',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        provider.whatsapp.isEmpty ? null : widget.onWhatsApp,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF128C4A),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text('Entrar em contato no WhatsApp'),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: widget.onOpen,
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: const Text('Ver perfil completo'),
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sync, size: 15, color: AppColors.muted),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Toque no card para voltar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text, this.trailing});

  final IconData icon;
  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.wine),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              color: AppColors.wine,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
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
