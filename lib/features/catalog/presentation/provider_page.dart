import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../../../core/widgets/state_view.dart';
import '../domain/catalog_models.dart';
import '../domain/catalog_repository.dart';
import 'catalog_store.dart';
import 'catalog_widgets.dart';

class ProviderPage extends StatefulWidget {
  const ProviderPage({required this.slug, super.key});

  final String slug;

  @override
  State<ProviderPage> createState() => _ProviderPageState();
}

class _ProviderPageState extends State<ProviderPage> {
  late final Future<ProviderProfile?> providerFuture;
  final store = getIt<CatalogStore>();

  @override
  void initState() {
    super.initState();
    providerFuture = getIt<CatalogRepository>().findProvider(widget.slug);
  }

  Future<void> _openWhatsApp(ProviderProfile provider) async {
    final message = Uri.encodeComponent('Olá! Encontrei seu serviço pelo CormeX Easy.');
    final phone = provider.whatsapp.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$phone?text=$message');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  Future<void> _share(ProviderProfile provider) async {
    final link = Uri.base.replace(path: '/prestador/${provider.slug}', query: '').toString();
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link do perfil copiado.')),
      );
    }
  }

  Future<void> _report(ProviderProfile provider) async {
    String reason = 'Informações falsas';
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Denunciar perfil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sua denúncia será analisada. O perfil não é removido automaticamente.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(labelText: 'Motivo'),
                items: const [
                  'Informações falsas',
                  'Conteúdo impróprio',
                  'Golpe ou suspeita',
                  'Número inválido',
                  'Serviço inexistente',
                  'Outro',
                ].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                onChanged: (value) => setState(() => reason = value ?? reason),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enviar')),
          ],
        ),
      ),
    );
    if (sent != true || !mounted) return;
    final environment = getIt<AppEnvironment>();
    if (!environment.useQaData) {
      try {
        const reasonCodes = {
          'Informações falsas': 'false_information',
          'Conteúdo impróprio': 'inappropriate_content',
          'Golpe ou suspeita': 'suspected_scam',
          'Número inválido': 'invalid_number',
          'Serviço inexistente': 'nonexistent_service',
          'Outro': 'other',
        };
        await getIt<ApiClient>().runFunction('v1-providers-report', params: {
          'providerPublicId': provider.id,
          'reason': reasonCodes[reason] ?? 'other',
        });
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível enviar a denúncia agora.')),
        );
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Denúncia enviada para análise.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProviderProfile?>(
      future: providerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return StateView(
            icon: Icons.cloud_off,
            title: 'Perfil indisponível',
            message: 'Não foi possível carregar este prestador.',
            actionLabel: 'Voltar ao início',
            onAction: () => context.go('/'),
          );
        }
        final provider = snapshot.data;
        if (provider == null) {
          return StateView(
            icon: Icons.person_search,
            title: 'Prestador não encontrado',
            message: 'O perfil pode ter sido removido, pausado ou o endereço está incorreto.',
            actionLabel: 'Explorar serviços',
            onAction: () => context.go('/explorar'),
          );
        }
        return Watch((context) => _ProviderContent(
              provider: provider,
              isFavorite: store.isFavorite(provider.id),
              onFavorite: () => store.toggleFavorite(provider.id),
              onWhatsApp: () => _openWhatsApp(provider),
              onShare: () => _share(provider),
              onReport: () => _report(provider),
            ));
      },
    );
  }
}

class _ProviderContent extends StatelessWidget {
  const _ProviderContent({
    required this.provider,
    required this.isFavorite,
    required this.onFavorite,
    required this.onWhatsApp,
    required this.onShare,
    required this.onReport,
  });

  final ProviderProfile provider;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onWhatsApp;
  final VoidCallback onShare;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: provider.isPro
                      ? const LinearGradient(colors: [AppColors.wineDark, AppColors.wine])
                      : null,
                  color: provider.isPro ? null : Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: provider.isPro
                                  ? AppColors.gold
                                  : const Color(0xFFE6D9DD),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ProviderPhoto(provider: provider),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (provider.isPro)
                                const Text(
                                  'PRO • DESTAQUE PATROCINADO',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      provider.displayName,
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            color: provider.isPro ? Colors.white : AppColors.ink,
                                          ),
                                    ),
                                  ),
                                  if (provider.isVerified)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: Icon(Icons.verified, color: Color(0xFF49A6FF)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${provider.category.name} • ${provider.providerType}',
                                style: TextStyle(
                                  color: provider.isPro ? Colors.white70 : AppColors.muted,
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
                            color: provider.isPro ? Colors.white : AppColors.wine,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      provider.description,
                      style: TextStyle(
                        color: provider.isPro ? Colors.white.withValues(alpha: .9) : AppColors.ink,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: onWhatsApp,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1F9D5A),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.chat),
                          label: const Text('Chamar no WhatsApp'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShare,
                          style: provider.isPro
                              ? OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54),
                                )
                              : null,
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Compartilhar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  final children = [
                    _InfoCard(
                      title: 'Serviços oferecidos',
                      icon: Icons.home_repair_service,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.services
                            .map((service) => Chip(label: Text(service)))
                            .toList(),
                      ),
                    ),
                    _InfoCard(
                      title: 'Área de atendimento',
                      icon: Icons.location_on_outlined,
                      child: Text('${provider.serviceArea}\n${provider.city} - ${provider.state}'),
                    ),
                    _InfoCard(
                      title: 'Disponibilidade',
                      icon: Icons.schedule,
                      child: Text(provider.isOpen24Hours
                          ? 'Atendimento 24 horas • ${provider.availability}'
                          : provider.availability),
                    ),
                  ];
                  return wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < children.length; i++) ...[
                              Expanded(child: children[i]),
                              if (i < children.length - 1) const SizedBox(width: 12),
                            ],
                          ],
                        )
                      : Column(
                          children: [
                            for (final child in children) ...[
                              child,
                              const SizedBox(height: 12),
                            ],
                          ],
                        );
                },
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onReport,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Denunciar este perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.wine),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
