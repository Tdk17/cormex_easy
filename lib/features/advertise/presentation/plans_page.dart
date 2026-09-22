import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../data/billing_repository.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  bool loading = true;
  bool acting = false;
  String? error;
  String paymentMode = 'card';
  List<Map<String, dynamic>> plans = const [];
  List<Map<String, dynamic>> payments = const [];
  Map<String, dynamic>? subscription;
  Map<String, dynamic>? entitlement;

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
      plans = [_qaPlan('EASY_PROFISSIONAL', 'Profissional', 'autonomous', 39.90, 29.90, 5, 1), _qaPlan('EASY_NEGOCIOS', 'Negócios', 'company', 69.90, 49.90, 15, 3, highlight: true)];
      subscription = {'planCode': 'EASY_PROFISSIONAL', 'status': 'active', 'amount': 29.90, 'currency': 'BRL', 'paymentMode': 'card'};
      entitlement = {'active': true, 'planCode': 'EASY_PROFISSIONAL', 'serviceLimit': 5, 'categoryLimit': 1, 'metricsLevel': 'basic', 'commercialHighlight': false};
      payments = const [{'date': '2026-09-20', 'amount': 29.90, 'currency': 'BRL', 'status': 'approved', 'paymentType': 'card'}];
      if (mounted) setState(() => loading = false);
      return;
    }
    if (api.sessionToken?.isNotEmpty != true) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final repository = BillingRepository(api);
      final results = await Future.wait([
        repository.listPlans(),
        repository.subscriptionMe(),
        repository.history(),
      ]);
      plans = _items(results[0]['plans']);
      subscription = _map(results[1]['subscription']);
      entitlement = _map(results[1]['entitlement']);
      payments = _items(results[2]['items']);
    } on ApiException catch (exception) {
      error = exception.message;
      if (exception.type == ApiFailureType.unauthorized) {
        await api.setSessionToken(null);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _choose(Map<String, dynamic> plan) async {
    if (acting) return;
    setState(() => acting = true);
    try {
      final repository = BillingRepository(getIt<ApiClient>());
      final requested = plan['code'].toString();
      final current = subscription?['planCode']?.toString();
      final active = const {'active', 'paused'}.contains(subscription?['status']);
      final result = active && current != null && current != requested
          ? await repository.changePlan(requested)
          : await repository.createSubscription(requested, preferredPaymentMode: paymentMode);
      final checkoutUrl = result['checkoutUrl']?.toString();
      if (checkoutUrl?.isNotEmpty == true) {
        await launchUrl(Uri.parse(checkoutUrl!), webOnlyWindowName: '_blank');
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(checkoutUrl?.isNotEmpty == true
            ? 'Plano solicitado. Conclua o pagamento na aba aberta.'
            : 'Plano atualizado com sucesso.'),
      ));
    } on ApiException catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  Future<void> _subscriptionAction(String action) async {
    setState(() => acting = true);
    try {
      final repository = BillingRepository(getIt<ApiClient>());
      final result = switch (action) {
        'sync' => await repository.sync(),
        'pause' => await repository.pause(),
        'resume' => await repository.resume(),
        _ => await repository.cancel(reason: 'Cancelado pelo cliente no aplicativo'),
      };
      subscription = _map(result['subscription']);
      final refreshed = await repository.subscriptionMe();
      subscription = _map(refreshed['subscription']);
      entitlement = _map(refreshed['entitlement']);
      if (mounted) setState(() {});
    } on ApiException catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final qa = getIt<AppEnvironment>().useQaData;
    if (!qa && getIt<ApiClient>().sessionToken?.isNotEmpty != true) {
      return _StateCard(title: 'Entre para escolher seu plano', message: 'A assinatura fica vinculada à sua conta profissional.', action: 'Entrar', onTap: () => context.go('/entrar'));
    }
    if (error != null && plans.isEmpty) {
      return _StateCard(title: 'Não foi possível carregar os planos', message: error!, action: 'Tentar novamente', onTap: _load);
    }
    final currentCode = subscription?['planCode']?.toString();
    final status = subscription?['status']?.toString() ?? 'sem assinatura';
    return SingleChildScrollView(
      child: PageWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 56),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Planos CormeX Easy', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text('Escolha o plano oficial do seu perfil. Limites e benefícios são validados pelo servidor.'),
            const SizedBox(height: 18),
            SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'card', icon: Icon(Icons.credit_card), label: Text('Cartão')), ButtonSegment(value: 'pix', icon: Icon(Icons.pix), label: Text('Pix'))],
              selected: {paymentMode},
              onSelectionChanged: acting ? null : (value) => setState(() => paymentMode = value.first),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth >= 760 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
              return Wrap(spacing: 16, runSpacing: 16, children: plans.map((plan) => SizedBox(width: width, child: _PlanCard(plan: plan, current: plan['code'] == currentCode, acting: acting, onTap: () => _choose(plan)))).toList());
            }),
            if (subscription != null) ...[
              const SizedBox(height: 20),
              _SubscriptionCard(subscription: subscription!, entitlement: entitlement, payments: payments, acting: acting, onAction: _subscriptionAction),
            ],
            const SizedBox(height: 16),
            const Text('O preço promocional, quando ativo, é calculado no backend. O app nunca altera valores de cobrança.', style: TextStyle(color: AppColors.muted)),
          ]),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.current, required this.acting, required this.onTap});
  final Map<String, dynamic> plan;
  final bool current;
  final bool acting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final features = _map(plan['features']) ?? const {};
    final promotional = plan['promotionActive'] == true;
    final highlight = features['commercialHighlight'] == true;
    return Card(
      color: highlight ? AppColors.wine : null,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: highlight ? Colors.white : AppColors.ink),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(plan['name']?.toString() ?? 'Plano', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), if (current) const Chip(label: Text('Plano atual'))]),
            Text(plan['audience'] == 'autonomous' ? 'Para profissionais autônomos' : 'Para MEI e empresas'),
            const SizedBox(height: 18),
            if (promotional) Text(_money(plan['regularPrice']), style: const TextStyle(decoration: TextDecoration.lineThrough)),
            Text('${_money(plan['currentPrice'])}/mês', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            _feature('${features['serviceLimit'] ?? 0} serviços cadastrados'),
            _feature('${features['categoryLimit'] ?? 0} categorias'),
            _feature(features['metricsLevel'] == 'advanced' ? 'Métricas avançadas' : 'Métricas essenciais'),
            if (features['commercialHighlight'] == true) _feature('Destaque comercial'),
            if (features['businessProfile'] == true) _feature('Perfil empresarial'),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: current || acting ? null : onTap, child: Text(current ? 'Plano ativo' : 'Escolher plano'))),
          ]),
        ),
      ),
    );
  }

  Widget _feature(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [const Icon(Icons.check_circle_outline, size: 19), const SizedBox(width: 8), Expanded(child: Text(text))]));
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription, required this.entitlement, required this.payments, required this.acting, required this.onAction});
  final Map<String, dynamic> subscription;
  final Map<String, dynamic>? entitlement;
  final List<Map<String, dynamic>> payments;
  final bool acting;
  final void Function(String) onAction;

  @override
  Widget build(BuildContext context) {
    final status = subscription['status']?.toString() ?? '—';
    return Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Sua assinatura', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [Chip(label: Text(subscription['planCode']?.toString() ?? '—')), Chip(label: Text(status)), if (entitlement?['active'] == true) const Chip(avatar: Icon(Icons.verified, size: 17), label: Text('Benefícios ativos'))]),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton(onPressed: acting ? null : () => onAction('sync'), child: const Text('Atualizar cobrança')),
        if (status == 'active') OutlinedButton(onPressed: acting ? null : () => onAction('pause'), child: const Text('Pausar')),
        if (status == 'paused') OutlinedButton(onPressed: acting ? null : () => onAction('resume'), child: const Text('Retomar')),
        if (!{'canceled', 'cancelled'}.contains(status)) TextButton(onPressed: acting ? null : () => onAction('cancel'), child: const Text('Cancelar')),
      ]),
      if (payments.isNotEmpty) ...[
        const Divider(height: 28),
        const Text('Histórico recente', style: TextStyle(fontWeight: FontWeight.w700)),
        for (final payment in payments.take(3)) ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: const Icon(Icons.receipt_long_outlined), title: Text(_money(payment['amount'])), subtitle: Text('${payment['date'] ?? ''} • ${payment['status'] ?? ''}')),
      ],
    ])));
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.title, required this.message, required this.action, required this.onTap});
  final String title;
  final String message;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Card(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center), const SizedBox(height: 18), FilledButton(onPressed: onTap, child: Text(action))]))));
}

Map<String, dynamic>? _map(dynamic value) => value is Map ? value.cast<String, dynamic>() : null;
List<Map<String, dynamic>> _items(dynamic value) => (value as List? ?? const []).whereType<Map>().map((item) => item.cast<String, dynamic>()).toList();
String _money(dynamic value) => 'R\$ ${(num.tryParse(value?.toString() ?? '') ?? 0).toStringAsFixed(2).replaceFirst('.', ',')}';
Map<String, dynamic> _qaPlan(String code, String name, String audience, double regular, double launch, int services, int categories, {bool highlight = false}) => {'code': code, 'name': name, 'audience': audience, 'currency': 'BRL', 'regularPrice': regular, 'launchPrice': launch, 'currentPrice': launch, 'promotionActive': true, 'features': {'serviceLimit': services, 'categoryLimit': categories, 'metricsLevel': highlight ? 'advanced' : 'basic', 'commercialHighlight': highlight, 'businessProfile': highlight}};
