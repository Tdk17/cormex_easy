import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_shell.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  final requestNonce = DateTime.now().microsecondsSinceEpoch.toString();
  bool loading = true;
  bool acting = false;
  String? error;
  Map<String, dynamic>? provider;
  Map<String, dynamic>? currentSubscription;
  List<Map<String, dynamic>> plans = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final environment = getIt<AppEnvironment>();
    final api = getIt<ApiClient>();
    if (environment.useQaData) {
      provider = {'publicId': 'qa-provider', 'status': 'published'};
      plans = [
        {
          'publicId': 'qa-basic',
          'code': 'basic',
          'name': 'Básico',
          'price': {'formatted': 'Grátis'},
          'billingCycle': 'none',
          'benefits': ['Perfil público', 'WhatsApp', 'Área de atendimento'],
        },
        {
          'publicId': 'qa-pro',
          'code': 'pro',
          'name': 'Pro',
          'price': {'formatted': 'R\$ 29,90'},
          'billingCycle': 'monthly',
          'trialDays': 7,
          'benefits': ['Card destacado', 'Analytics', 'Mais exposição'],
        },
      ];
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
        final results = await Future.wait([
          api.runFunction(
            'v1-plans-eligible',
            params: {'providerPublicId': providerId},
          ),
          api.runFunction(
            'v1-subscriptions-get-current',
            params: {'providerPublicId': providerId},
          ),
        ]);
        plans = (results[0]['plans'] as List? ?? [])
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList();
        currentSubscription =
            (results[1]['subscription'] as Map?)?.cast<String, dynamic>();
      }
    } on ApiException catch (exception) {
      error = exception.message;
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _choosePlan(Map<String, dynamic> plan) async {
    if (getIt<AppEnvironment>().useQaData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleção validada no ambiente QA sem cobrança real.')),
      );
      return;
    }
    final providerId = provider?['publicId']?.toString() ?? '';
    if (providerId.isEmpty) return;
    setState(() => acting = true);
    try {
      final code = plan['code']?.toString() ?? 'basic';
      final result = await getIt<ApiClient>().runFunction(
        'v1-subscriptions-create',
        params: {
          'providerPublicId': providerId,
          'planPublicId': plan['publicId'],
          'billingCycle': plan['billingCycle'] ?? 'monthly',
          if (code == 'pro') ...{
            'useTrial': true,
            'paymentMethod': 'credit_card',
            'returnUrl': Uri.base
                .replace(query: null, fragment: '/meu-anuncio')
                .toString(),
            'idempotencyKey': 'plans-$providerId-$code-$requestNonce',
          },
        },
      );
      currentSubscription =
          (result['subscription'] as Map?)?.cast<String, dynamic>();
      final status = currentSubscription?['status']?.toString();
      if (status == 'active' || status == 'trial') {
        final providerStatus = provider?['status']?.toString();
        await getIt<ApiClient>().runFunction(
          providerStatus == 'paused'
              ? 'v1-provider-profile-reactivate'
              : 'v1-provider-profile-publish',
          params: {'providerPublicId': providerId},
        );
        provider = {...provider!, 'status': 'published'};
      }
      final payment =
          (result['payment'] as Map?)?.cast<String, dynamic>();
      final checkoutUrl = payment?['checkoutUrl']?.toString();
      if (checkoutUrl?.isNotEmpty == true) {
        await launchUrl(Uri.parse(checkoutUrl!), webOnlyWindowName: '_blank');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            checkoutUrl?.isNotEmpty == true
                ? 'Conclua o pagamento na nova aba.'
                : 'Plano ativado com sucesso.',
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

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final api = getIt<ApiClient>();
    final qa = getIt<AppEnvironment>().useQaData;
    if (!qa && api.sessionToken?.isNotEmpty != true) {
      return _PlanState(
        title: 'Entre para ver os planos elegíveis',
        message: 'Os preços e benefícios dependem do seu perfil profissional.',
        action: 'Entrar',
        onTap: () => context.go('/entrar'),
      );
    }
    if (provider == null) {
      return _PlanState(
        title: 'Crie seu anúncio primeiro',
        message: error ?? 'O backend classifica seu perfil antes de mostrar os planos disponíveis.',
        action: 'Criar anúncio',
        onTap: () => context.go('/anunciar'),
      );
    }
    if (plans.isEmpty) {
      return _PlanState(
        title: 'Nenhum plano disponível',
        message: error ?? 'Tente novamente em alguns instantes.',
        action: 'Voltar ao anúncio',
        onTap: () => context.go('/meu-anuncio'),
      );
    }
    final activePlan =
        (currentSubscription?['plan'] as Map?)?.cast<String, dynamic>();
    final activeCode = activePlan?['code']?.toString();
    final activeStatus = currentSubscription?['status']?.toString();

    return SingleChildScrollView(
      child: PageWidth(
        maxWidth: 980,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 56),
          child: Column(
            children: [
              Text('Planos simples para crescer', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Preço, periodicidade e elegibilidade carregados diretamente do backend.', textAlign: TextAlign.center),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  final cards = plans.map((plan) {
                    final code = plan['code']?.toString() ?? '';
                    return _PlanCard(
                      plan: plan,
                      pro: code == 'pro',
                      current: code == activeCode && (activeStatus == 'active' || activeStatus == 'trial'),
                      loading: acting,
                      onTap: () => _choosePlan(plan),
                    );
                  }).toList();
                  return wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < cards.length; i++) ...[
                              Expanded(child: cards[i]),
                              if (i < cards.length - 1) const SizedBox(width: 16),
                            ],
                          ],
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < cards.length; i++) ...[
                              cards[i],
                              if (i < cards.length - 1) const SizedBox(height: 16),
                            ],
                          ],
                        );
                },
              ),
              const SizedBox(height: 18),
              const Text('Ser Pro representa destaque comercial e não significa melhor avaliação. O pagamento só é confirmado pelo backend.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.pro,
    required this.current,
    required this.loading,
    required this.onTap,
  });
  final Map<String, dynamic> plan;
  final bool pro;
  final bool current;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = (plan['price'] as Map?)?.cast<String, dynamic>() ?? {};
    final benefits = (plan['benefits'] as List? ?? []).map((item) => item.toString()).toList();
    final trialDays = num.tryParse(plan['trialDays']?.toString() ?? '') ?? 0;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: pro ? AppColors.wineDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pro ? AppColors.gold : const Color(0xFFE3DBDD), width: pro ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (current) const Chip(label: Text('PLANO ATUAL')) else if (pro) const Chip(label: Text('MAIS DESTAQUE')),
          Text(plan['name']?.toString() ?? 'Plano', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: pro ? Colors.white : AppColors.ink)),
          const SizedBox(height: 8),
          Text(
            price['formatted']?.toString() ?? 'Consulte',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: pro ? AppColors.gold : AppColors.wine),
          ),
          if (trialDays > 0)
            Text('$trialDays dias de teste', style: TextStyle(color: pro ? Colors.white70 : AppColors.muted)),
          const SizedBox(height: 18),
          for (final benefit in benefits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 19, color: pro ? AppColors.gold : AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(child: Text(benefit, style: TextStyle(color: pro ? Colors.white : AppColors.ink))),
                ],
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: loading || current ? null : onTap,
              style: pro ? FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.wineDark) : null,
              child: Text(current ? 'Plano ativo' : pro ? 'Quero o Pro' : 'Ativar Básico'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanState extends StatelessWidget {
  const _PlanState({required this.title, required this.message, required this.action, required this.onTap});
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
                  const Icon(Icons.workspace_premium_outlined, size: 54, color: AppColors.wine),
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
