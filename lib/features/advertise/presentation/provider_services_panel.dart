import 'package:flutter/material.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../data/billing_repository.dart';
import '../data/provider_services_repository.dart';

class ProviderServicesPanel extends StatefulWidget {
  const ProviderServicesPanel({required this.providerPublicId, super.key});

  final String providerPublicId;

  @override
  State<ProviderServicesPanel> createState() => _ProviderServicesPanelState();
}

class _ProviderServicesPanelState extends State<ProviderServicesPanel> {
  bool loading = true;
  bool acting = false;
  String? error;
  List<Map<String, dynamic>> services = const [];
  List<Map<String, dynamic>> categories = const [];
  Map<String, dynamic>? entitlement;

  int get serviceLimit => int.tryParse(entitlement?['serviceLimit']?.toString() ?? '') ?? 0;
  int get categoryLimit => int.tryParse(entitlement?['categoryLimit']?.toString() ?? '') ?? 0;
  bool get atLimit => serviceLimit > 0 && services.length >= serviceLimit;

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
    if (getIt<AppEnvironment>().useQaData) {
      services = const [{'publicId': 'qa-service-1', 'name': 'Instalação e manutenção', 'description': 'Atendimento residencial e comercial.', 'priceLabel': 'A partir de R\$ 120', 'status': 'active', 'category': {'publicId': 'qa-category-1', 'name': 'Serviços gerais'}}];
      categories = const [{'publicId': 'qa-category-1', 'name': 'Serviços gerais'}, {'publicId': 'qa-category-2', 'name': 'Manutenção'}];
      entitlement = const {'active': true, 'serviceLimit': 5, 'categoryLimit': 1};
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final api = getIt<ApiClient>();
      final results = await Future.wait([
        ProviderServicesRepository(api).list(widget.providerPublicId),
        api.runFunction('v1-categories-list', params: {'limit': 100}),
        BillingRepository(api).subscriptionMe(),
      ]);
      services = results[0] as List<Map<String, dynamic>>;
      categories = ((results[1] as Map<String, dynamic>)['items'] as List? ?? const []).whereType<Map>().map((item) => item.cast<String, dynamic>()).toList();
      entitlement = ((results[2] as Map<String, dynamic>)['entitlement'] as Map?)?.cast<String, dynamic>();
    } on ApiException catch (exception) {
      error = exception.message;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _edit([Map<String, dynamic>? service]) async {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhuma categoria disponível.')));
      return;
    }
    final name = TextEditingController(text: service?['name']?.toString());
    final description = TextEditingController(text: service?['description']?.toString());
    final price = TextEditingController(text: service?['priceLabel']?.toString());
    final existingCategory = (service?['category'] as Map?)?['publicId']?.toString();
    var categoryId = categories.any((item) => item['publicId']?.toString() == existingCategory) ? existingCategory! : categories.first['publicId'].toString();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: Text(service == null ? 'Novo serviço' : 'Editar serviço'),
        content: SizedBox(width: 460, child: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nome do serviço'), validator: (value) => value?.trim().isEmpty == true ? 'Informe o nome.' : null),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: categoryId, decoration: const InputDecoration(labelText: 'Categoria'), items: categories.map((item) => DropdownMenuItem(value: item['publicId'].toString(), child: Text(item['name']?.toString() ?? 'Categoria'))).toList(), onChanged: (value) => setDialogState(() => categoryId = value ?? categoryId)),
          const SizedBox(height: 12),
          TextFormField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Descrição')),
          const SizedBox(height: 12),
          TextFormField(controller: price, decoration: const InputDecoration(labelText: 'Faixa de preço', hintText: 'Ex.: A partir de R\$ 120')),
        ])))),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')), FilledButton(onPressed: () { if (formKey.currentState?.validate() == true) Navigator.pop(context, true); }, child: const Text('Salvar'))],
      )),
    );
    if (confirmed != true || !mounted) return;
    setState(() => acting = true);
    try {
      if (getIt<AppEnvironment>().useQaData) {
        final value = {'publicId': service?['publicId'] ?? 'qa-service-${services.length + 1}', 'name': name.text.trim(), 'description': description.text.trim(), 'priceLabel': price.text.trim(), 'status': 'active', 'category': categories.firstWhere((item) => item['publicId'] == categoryId)};
        services = service == null ? [...services, value] : services.map((item) => item['publicId'] == service['publicId'] ? value : item).toList();
      } else {
        final repository = ProviderServicesRepository(getIt<ApiClient>());
        final saved = service == null
            ? await repository.create(providerPublicId: widget.providerPublicId, categoryPublicId: categoryId, name: name.text.trim(), description: description.text.trim(), priceLabel: price.text.trim())
            : await repository.update(providerPublicId: widget.providerPublicId, servicePublicId: service['publicId'].toString(), categoryPublicId: categoryId, name: name.text.trim(), description: description.text.trim(), priceLabel: price.text.trim());
        services = service == null ? [...services, saved] : services.map((item) => item['publicId'] == saved['publicId'] ? saved : item).toList();
      }
      if (mounted) setState(() {});
    } on ApiException catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      name.dispose(); description.dispose(); price.dispose();
      if (mounted) setState(() => acting = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> service) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Excluir serviço?'), content: Text('O serviço “${service['name']}” deixará de aparecer no perfil.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir'))]));
    if (confirmed != true) return;
    setState(() => acting = true);
    try {
      if (!getIt<AppEnvironment>().useQaData) await ProviderServicesRepository(getIt<ApiClient>()).delete(providerPublicId: widget.providerPublicId, servicePublicId: service['publicId'].toString());
      services = services.where((item) => item['publicId'] != service['publicId']).toList();
      if (mounted) setState(() {});
    } on ApiException catch (exception) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Expanded(child: Text('Meus serviços', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))), FilledButton.tonalIcon(onPressed: loading || acting || atLimit ? null : _edit, icon: const Icon(Icons.add), label: const Text('Adicionar'))]),
      const SizedBox(height: 5),
      Text(serviceLimit > 0 ? '${services.length} de $serviceLimit serviços • até $categoryLimit categoria${categoryLimit == 1 ? '' : 's'}' : '${services.length} serviços', style: const TextStyle(color: AppColors.muted)),
      if (atLimit) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Limite do plano atingido. Troque de plano para adicionar mais.', style: TextStyle(color: AppColors.wine, fontWeight: FontWeight.w700))),
      if (loading) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
      else if (error != null) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.error_outline), title: Text(error!), trailing: TextButton(onPressed: _load, child: const Text('Tentar novamente')))
      else if (services.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Text('Cadastre os serviços que você oferece para aparecer nas buscas certas.'))
      else ...services.map((service) {
        final category = (service['category'] as Map?)?.cast<String, dynamic>() ?? const {};
        return ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.handyman_outlined)), title: Text(service['name']?.toString() ?? 'Serviço'), subtitle: Text([category['name'], service['priceLabel']].where((value) => value?.toString().isNotEmpty == true).join(' • ')), trailing: PopupMenuButton<String>(enabled: !acting, onSelected: (value) => value == 'edit' ? _edit(service) : _delete(service), itemBuilder: (context) => const [PopupMenuItem(value: 'edit', child: Text('Editar')), PopupMenuItem(value: 'delete', child: Text('Excluir'))]));
      }),
    ])));
  }
}
