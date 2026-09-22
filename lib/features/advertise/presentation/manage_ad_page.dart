import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/platform/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../data/billing_repository.dart';
import 'provider_services_panel.dart';

class ManageAdPage extends StatefulWidget {
  const ManageAdPage({super.key});

  @override
  State<ManageAdPage> createState() => _ManageAdPageState();
}

class _ManageAdPageState extends State<ManageAdPage> {
  bool loading = true;
  bool acting = false;
  String? error;
  Map<String, dynamic>? provider;
  Map<String, dynamic>? subscription;
  Map<String, dynamic> totals = const {};
  List<Map<String, dynamic>> portfolio = const [];
  bool analyticsNotIncluded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final environment = getIt<AppEnvironment>();
    final api = getIt<ApiClient>();
    if (environment.useQaData) {
      provider = {
        'publicId': 'qa-provider',
        'slug': 'qa-prestador',
        'displayName': 'Anúncio de teste QA',
        'status': 'published',
        'location': {'city': 'Blumenau', 'state': 'SC'},
        'category': {'name': 'Serviços gerais'},
      };
      subscription = {
        'status': 'active',
        'planCode': 'EASY_PROFISSIONAL',
        'amount': 29.90,
        'currency': 'BRL',
      };
      portfolio = const [];
      totals = {
        'impressions': 1280,
        'profileViews': 164,
        'whatsappClicks': 37,
        'favorites': 21,
      };
      if (mounted) setState(() => loading = false);
      return;
    }
    if (api.sessionToken?.isNotEmpty != true) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final mine = await api.runFunction('v1-provider-profile-get-mine');
      provider = (mine['provider'] as Map?)?.cast<String, dynamic>();
      final providerId = provider?['publicId']?.toString();
      if (providerId?.isNotEmpty == true) {
        final current = await BillingRepository(api).subscriptionMe();
        subscription =
            (current['subscription'] as Map?)?.cast<String, dynamic>();
        try {
          final analytics = await api.runFunction(
            'v1-provider-analytics-summary',
            params: {'providerPublicId': providerId, 'period': '30d'},
          );
          totals =
              (analytics['totals'] as Map?)?.cast<String, dynamic>() ?? {};
          analyticsNotIncluded = analytics['featureNotIncluded'] == true;
        } catch (_) {
          totals = const {};
        }
        final slug = provider?['slug']?.toString() ?? '';
        if (provider?['status'] == 'published' && slug.isNotEmpty) {
          try {
            final detail = await api.runFunction(
              'v1-providers-detail',
              params: {'slug': slug},
            );
            final publicProvider =
                (detail['provider'] as Map?)?.cast<String, dynamic>() ?? {};
            portfolio = (publicProvider['portfolio'] as List? ?? [])
                .whereType<Map>()
                .map((item) => item.cast<String, dynamic>())
                .toList();
          } catch (_) {
            portfolio = const [];
          }
        }
      }
    } on ApiException catch (exception) {
      error = exception.message;
      if (exception.type == ApiFailureType.unauthorized) {
        await api.setSessionToken(null);
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _uploadPortfolio() async {
    final providerId = provider?['publicId']?.toString() ?? '';
    if (providerId.isEmpty) return;
    setState(() => acting = true);
    try {
      final prepared = await getIt<ApiClient>().runFunction(
        'v1-provider-portfolio-upload-prepare',
        params: {'providerPublicId': providerId},
      );
      final upload =
          (prepared['upload'] as Map?)?.cast<String, dynamic>() ?? {};
      final image = await pickPortfolioImage();
      if (image == null) return;
      final maxBytes = num.tryParse(upload['maxBytes']?.toString() ?? '') ?? 0;
      if (maxBytes > 0 && image.sizeBytes > maxBytes) {
        throw const ApiException(
          ApiFailureType.badRequest,
          'A imagem ultrapassa o tamanho permitido pelo plano.',
        );
      }
      final result = await getIt<ApiClient>().runFunction(
        'v1-provider-portfolio-upload',
        params: {
          'providerPublicId': providerId,
          'fileName': image.name,
          'mimeType': image.mimeType,
          'sizeBytes': image.sizeBytes,
          'base64': image.base64,
        },
      );
      final item = (result['item'] as Map?)?.cast<String, dynamic>();
      if (item != null) portfolio = [...portfolio, item];
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagem adicionada ao portfólio.')),
      );
      setState(() {});
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exception.message)),
      );
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  Future<void> _deletePortfolio(Map<String, dynamic> item) async {
    final itemId = item['publicId']?.toString() ?? '';
    if (itemId.isEmpty) return;
    setState(() => acting = true);
    try {
      await getIt<ApiClient>().runFunction(
        'v1-provider-portfolio-delete',
        params: {
          'providerPublicId': provider!['publicId'],
          'itemPublicId': itemId,
        },
      );
      portfolio = portfolio
          .where((candidate) => candidate['publicId'] != itemId)
          .toList();
      if (mounted) setState(() {});
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exception.message)),
      );
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  Future<void> _changeStatus() async {
    final current = provider?['status']?.toString() ?? 'draft';
    final providerId = provider?['publicId']?.toString() ?? '';
    if (providerId.isEmpty) return;
    final function = switch (current) {
      'published' => 'v1-provider-profile-pause',
      'paused' => 'v1-provider-profile-reactivate',
      _ => 'v1-provider-profile-publish',
    };
    setState(() => acting = true);
    try {
      final result = await getIt<ApiClient>().runFunction(
        function,
        params: {'providerPublicId': providerId},
      );
      provider = {...provider!, 'status': result['status'] ?? 'published'};
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider!['status'] == 'published'
                ? 'Anúncio publicado.'
                : 'Anúncio pausado.',
          ),
        ),
      );
      setState(() {});
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exception.message)),
      );
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  Future<void> _reactivateSubscription() async {
    setState(() => acting = true);
    try {
      final result =
          await BillingRepository(getIt<ApiClient>()).resume();
      subscription =
          (result['subscription'] as Map?)?.cast<String, dynamic>();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assinatura reativada.')),
        );
        setState(() {});
      }
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exception.message)),
      );
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar assinatura?'),
        content: const Text(
          'O anúncio continuará na modalidade permitida pelo backend, sem os benefícios ativos do plano.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar cancelamento'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => acting = true);
    try {
      final result = await BillingRepository(getIt<ApiClient>()).cancel(
        reason: 'Cancelado pelo cliente no aplicativo',
      );
      subscription =
          (result['subscription'] as Map?)?.cast<String, dynamic>();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cancelamento registrado.')),
        );
        setState(() {});
      }
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exception.message)),
      );
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final api = getIt<ApiClient>();
    final qa = getIt<AppEnvironment>().useQaData;
    if (!qa && api.sessionToken?.isNotEmpty != true) {
      return _AccessState(
        icon: Icons.lock_outline,
        title: 'Entre para gerenciar seu anúncio',
        message: 'A área comercial usa sua sessão para proteger alterações, plano e métricas.',
        action: 'Entrar',
        onTap: () => context.go('/entrar'),
      );
    }
    if (provider == null) {
      return _AccessState(
        icon: Icons.add_business,
        title: 'Você ainda não possui um anúncio',
        message: error ?? 'Crie seu perfil para aparecer no catálogo.',
        action: 'Criar anúncio',
        onTap: () => context.go('/anunciar'),
      );
    }

    final status = provider!['status']?.toString() ?? 'draft';
    final slug = provider!['slug']?.toString() ?? '';
    final planCode = subscription?['planCode']?.toString() ?? '';
    final planName = switch (planCode) {
      'EASY_PROFISSIONAL' => 'Profissional',
      'EASY_NEGOCIOS' => 'Negócios',
      _ => 'Nenhum plano ativo',
    };
    final subscriptionStatus =
        subscription?['status']?.toString() ?? 'sem assinatura';
    final location =
        (provider!['location'] as Map?)?.cast<String, dynamic>() ?? {};
    final category =
        (provider!['category'] as Map?)?.cast<String, dynamic>() ?? {};
    final statusAction = status == 'published'
        ? 'Pausar anúncio'
        : status == 'paused'
            ? 'Reativar anúncio'
            : 'Publicar anúncio';

    return SingleChildScrollView(
      child: PageWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 20,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meu anúncio', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      Text(provider!['displayName']?.toString() ?? 'Seu perfil profissional'),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: acting ? null : () => context.go('/anunciar'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar anúncio'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: Icon(
                    status == 'published' ? Icons.check_circle : Icons.info_outline,
                    color: status == 'published' ? AppColors.success : AppColors.wine,
                  ),
                  title: Text('Status: ${_statusLabel(status)}'),
                  subtitle: Text(
                    '${category['name'] ?? 'Categoria'} • ${location['city'] ?? ''} - ${location['state'] ?? ''}',
                  ),
                  trailing: Chip(label: Text(status.toUpperCase())),
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 920 ? 4 : constraints.maxWidth >= 620 ? 2 : 1;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    childAspectRatio: columns == 1 ? 3.1 : 1.45,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _Metric(label: 'Impressões', value: _metric('impressions'), icon: Icons.visibility_outlined),
                      _Metric(label: 'Visitas ao perfil', value: _metric('profileViews'), icon: Icons.person_search),
                      _Metric(label: 'Cliques no WhatsApp', value: _metric('whatsappClicks'), icon: Icons.chat_outlined),
                      _Metric(label: 'Favoritos', value: _metric('favorites'), icon: Icons.favorite_outline),
                    ],
                  );
                },
              ),
              if (analyticsNotIncluded)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('Analytics detalhado é um benefício do plano Pro.', style: TextStyle(color: AppColors.muted)),
                ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Plano e assinatura', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(child: Icon(Icons.workspace_premium_outlined)),
                        title: Text(planName),
                        subtitle: Text('Status: $subscriptionStatus'),
                        trailing: Chip(label: Text(planCode.isEmpty ? '—' : planCode)),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton(
                            onPressed: acting ? null : () => context.go('/planos'),
                            child: const Text('Ver planos disponíveis'),
                          ),
                          if (subscription != null && subscriptionStatus != 'cancelled')
                            TextButton(
                              onPressed: acting ? null : _cancelSubscription,
                              child: const Text('Cancelar assinatura'),
                            ),
                          if ({'paused', 'canceled', 'cancelled'}.contains(subscriptionStatus))
                            TextButton(
                              onPressed: acting ? null : _reactivateSubscription,
                              child: const Text('Reativar assinatura'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ProviderServicesPanel(
                providerPublicId: provider!['publicId'].toString(),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Logo e portfólio', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: acting ? null : _uploadPortfolio,
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Adicionar foto'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (portfolio.isEmpty)
                        const Text(
                          'Adicione fotos reais dos seus serviços. Formatos aceitos: JPG, PNG e WebP.',
                          style: TextStyle(color: AppColors.muted),
                        )
                      else
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: portfolio.map((item) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    item['url']?.toString() ?? '',
                                    width: 150,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const SizedBox(
                                      width: 150,
                                      height: 110,
                                      child: ColoredBox(
                                        color: Color(0xFFF0E8EA),
                                        child: Icon(Icons.broken_image_outlined),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: IconButton.filled(
                                    onPressed: acting ? null : () => _deletePortfolio(item),
                                    tooltip: 'Remover foto',
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      enabled: status == 'published' && slug.isNotEmpty,
                      leading: const Icon(Icons.storefront_outlined),
                      title: const Text('Visualizar anúncio público'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: status == 'published' && slug.isNotEmpty
                          ? () => context.go('/prestador/$slug')
                          : null,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('Área de atendimento e disponibilidade'),
                      subtitle: const Text('Edite os dados públicos do perfil'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/anunciar'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(status == 'published' ? Icons.pause_circle_outline : Icons.play_circle_outline),
                      title: Text(statusAction),
                      trailing: acting
                          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.chevron_right),
                      onTap: acting ? null : _changeStatus,
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

  String _metric(String key) {
    final value = NumberFormatHelper.compact(totals[key]);
    return value;
  }

  static String _statusLabel(String status) => switch (status) {
        'published' => 'Publicado',
        'paused' => 'Pausado',
        'draft' => 'Rascunho',
        'suspended' => 'Suspenso',
        'rejected' => 'Rejeitado',
        _ => status,
      };
}

class NumberFormatHelper {
  static String compact(dynamic raw) {
    final value = num.tryParse(raw?.toString() ?? '') ?? 0;
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)} mi';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)} mil';
    return value.toInt().toString();
  }
}

class _AccessState extends StatelessWidget {
  const _AccessState({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String message;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 54, color: AppColors.wine),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: onTap, child: Text(action)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.wine),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
