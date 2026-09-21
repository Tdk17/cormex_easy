import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_shell.dart';

class AdvertisePage extends StatefulWidget {
  const AdvertisePage({super.key});

  @override
  State<AdvertisePage> createState() => _AdvertisePageState();
}

class _AdvertisePageState extends State<AdvertisePage> {
  final _formKey = GlobalKey<FormState>();
  int step = 0;
  String providerType = 'Autônomo';
  String operation = 'Atuo sozinho';
  String selectedPlan = 'basic';
  bool open24Hours = false;
  bool acceptedTerms = false;
  bool submitting = false;

  final businessName = TextEditingController();
  final category = TextEditingController();
  final description = TextEditingController();
  final whatsapp = TextEditingController();
  final city = TextEditingController();
  final ownerName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    for (final controller in [
      businessName,
      category,
      description,
      whatsapp,
      city,
      ownerName,
      email,
      phone,
      password,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _validateStep() {
    if (step == 0 || step == 1) return _formKey.currentState?.validate() ?? false;
    if (step == 3 && !acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirme os termos para continuar.')),
      );
      return false;
    }
    return true;
  }

  Future<void> _continue() async {
    if (!_validateStep()) return;
    if (step < 3) {
      setState(() => step++);
      return;
    }
    setState(() => submitting = true);
    final environment = getIt<AppEnvironment>();
    try {
      if (!environment.useQaData) {
        await getIt<ApiClient>().postJson('v1/provider-profile/draft', body: {
          'providerType': providerType,
          'operationProfile': operation,
          'displayName': businessName.text.trim(),
          'categorySearch': category.text.trim(),
          'description': description.text.trim(),
          'whatsapp': whatsapp.text.trim(),
          'city': city.text.trim(),
          'account': {
            'name': ownerName.text.trim(),
            'email': email.text.trim(),
            'phone': phone.text.trim(),
          },
          'selectedPlanId': selectedPlan,
        });
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
          title: const Text('Cadastro preparado'),
          content: Text(environment.useQaData
              ? 'Fluxo QA concluído. Nenhum anúncio real foi publicado.'
              : 'Seus dados foram enviados. Continue pelo fluxo seguro do backend.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      if (mounted) context.go('/meu-anuncio');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar o anúncio agora.')),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 56),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Anuncie seu serviço', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Clientes encontram você e o contato acontece diretamente pelo WhatsApp.'),
                const SizedBox(height: 24),
                _StepHeader(current: step),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: switch (step) {
                        0 => _BusinessStep(
                            key: const ValueKey(0),
                            providerType: providerType,
                            onTypeChanged: (value) => setState(() => providerType = value),
                            operation: operation,
                            onOperationChanged: (value) => setState(() => operation = value),
                            businessName: businessName,
                            category: category,
                            description: description,
                            whatsapp: whatsapp,
                            city: city,
                            open24Hours: open24Hours,
                            onOpen24Hours: (value) => setState(() => open24Hours = value),
                          ),
                        1 => _AccountStep(
                            key: const ValueKey(1),
                            ownerName: ownerName,
                            email: email,
                            phone: phone,
                            password: password,
                          ),
                        2 => _PlanStep(
                            key: const ValueKey(2),
                            selected: selectedPlan,
                            onSelected: (value) => setState(() => selectedPlan = value),
                          ),
                        _ => _ReviewStep(
                            key: const ValueKey(3),
                            businessName: businessName.text,
                            providerType: providerType,
                            city: city.text,
                            plan: selectedPlan,
                            accepted: acceptedTerms,
                            onAccepted: (value) => setState(() => acceptedTerms = value),
                          ),
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (step > 0)
                      TextButton.icon(
                        onPressed: submitting ? null : () => setState(() => step--),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Voltar'),
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: submitting ? null : _continue,
                      icon: submitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(step == 3 ? Icons.check : Icons.arrow_forward),
                      label: Text(step == 3 ? 'Enviar e continuar' : 'Continuar'),
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

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    const labels = ['Anúncio', 'Conta', 'Plano', 'Revisão'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= current ? AppColors.wine : const Color(0xFFE4DCDF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (i < labels.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _BusinessStep extends StatelessWidget {
  const _BusinessStep({
    required this.providerType,
    required this.onTypeChanged,
    required this.operation,
    required this.onOperationChanged,
    required this.businessName,
    required this.category,
    required this.description,
    required this.whatsapp,
    required this.city,
    required this.open24Hours,
    required this.onOpen24Hours,
    super.key,
  });

  final String providerType;
  final ValueChanged<String> onTypeChanged;
  final String operation;
  final ValueChanged<String> onOperationChanged;
  final TextEditingController businessName;
  final TextEditingController category;
  final TextEditingController description;
  final TextEditingController whatsapp;
  final TextEditingController city;
  final bool open24Hours;
  final ValueChanged<bool> onOpen24Hours;

  String? _required(String? value) => (value ?? '').trim().isEmpty ? 'Campo obrigatório' : null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Conte sobre o seu serviço', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          children: ['Autônomo', 'MEI', 'Empresa']
              .map((type) => ChoiceChip(
                    label: Text(type),
                    selected: providerType == type,
                    onSelected: (_) => onTypeChanged(type),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: operation,
          decoration: const InputDecoration(labelText: 'Como você atua?'),
          items: const ['Atuo sozinho', 'Tenho equipe de 2 a 5 pessoas', 'Tenho equipe com mais de 5 pessoas']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) => onOperationChanged(value ?? operation),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: businessName,
          validator: _required,
          decoration: const InputDecoration(labelText: 'Nome profissional ou comercial'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: category,
          validator: _required,
          decoration: const InputDecoration(labelText: 'Categoria principal', hintText: 'Ex.: Eletricista'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: description,
          validator: _required,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Descrição do serviço'),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 620;
          final fields = [
            TextFormField(
              controller: whatsapp,
              validator: _required,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'WhatsApp público'),
            ),
            TextFormField(
              controller: city,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Cidade e estado'),
            ),
          ];
          return wide
              ? Row(children: [Expanded(child: fields[0]), const SizedBox(width: 12), Expanded(child: fields[1])])
              : Column(children: [fields[0], const SizedBox(height: 12), fields[1]]);
        }),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: open24Hours,
          onChanged: onOpen24Hours,
          title: const Text('Atendimento 24 horas'),
          subtitle: const Text('É uma informação de catálogo, não uma agenda.'),
        ),
      ],
    );
  }
}

class _AccountStep extends StatelessWidget {
  const _AccountStep({
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.password,
    super.key,
  });

  final TextEditingController ownerName;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController password;

  @override
  Widget build(BuildContext context) {
    String? requiredField(String? value) => (value ?? '').trim().isEmpty ? 'Campo obrigatório' : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Crie sua conta', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text('A navegação continua aberta; a conta é necessária somente para gerenciar o anúncio.'),
        const SizedBox(height: 18),
        TextFormField(controller: ownerName, validator: requiredField, decoration: const InputDecoration(labelText: 'Seu nome')),
        const SizedBox(height: 12),
        TextFormField(
          controller: email,
          validator: (value) => (value ?? '').contains('@') ? null : 'Informe um e-mail válido',
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-mail'),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: phone, validator: requiredField, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefone')),
        const SizedBox(height: 12),
        TextFormField(
          controller: password,
          validator: (value) => (value ?? '').length >= 8 ? null : 'Use ao menos 8 caracteres',
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Senha'),
        ),
      ],
    );
  }
}

class _PlanStep extends StatelessWidget {
  const _PlanStep({required this.selected, required this.onSelected, super.key});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Escolha como aparecer', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text('Valores, benefícios e elegibilidade serão confirmados pelo backend para o seu perfil.'),
        const SizedBox(height: 18),
        _PlanOption(
          title: 'Básico',
          subtitle: 'Perfil público, WhatsApp e área de atendimento.',
          selected: selected == 'basic',
          onTap: () => onSelected('basic'),
        ),
        const SizedBox(height: 12),
        _PlanOption(
          title: 'Pro',
          subtitle: 'Destaque comercial, maior exposição com rotação justa e analytics.',
          selected: selected == 'pro',
          pro: true,
          onTap: () => onSelected('pro'),
        ),
      ],
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({required this.title, required this.subtitle, required this.selected, required this.onTap, this.pro = false});

  final String title;
  final String subtitle;
  final bool selected;
  final bool pro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: pro ? AppColors.wineDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.gold : const Color(0xFFE1D8DB), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.gold : const Color(0xFF9E9296),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: pro ? Colors.white : AppColors.ink)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: pro ? Colors.white70 : AppColors.muted)),
                  const SizedBox(height: 8),
                  Text('Preço exibido após classificação segura', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pro ? AppColors.gold : AppColors.wine)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.businessName, required this.providerType, required this.city, required this.plan, required this.accepted, required this.onAccepted, super.key});

  final String businessName;
  final String providerType;
  final String city;
  final String plan;
  final bool accepted;
  final ValueChanged<bool> onAccepted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Revise antes de enviar', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 18),
        _ReviewRow('Anúncio', businessName),
        _ReviewRow('Perfil', providerType),
        _ReviewRow('Região', city),
        _ReviewRow('Plano solicitado', plan == 'pro' ? 'Pro' : 'Básico'),
        const Divider(height: 28),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: accepted,
          onChanged: (value) => onAccepted(value ?? false),
          title: const Text('Li e aceito os Termos de Uso e a Política de Privacidade.'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const Text('Pagamentos futuros serão criados pelo backend e confirmados somente por webhook seguro.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [SizedBox(width: 150, child: Text(label, style: const TextStyle(color: AppColors.muted))), Expanded(child: Text(value.isEmpty ? 'Não informado' : value, style: const TextStyle(fontWeight: FontWeight.w700)))]),
    );
  }
}
