import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_shell.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageWidth(
        maxWidth: 940,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 56),
          child: Column(
            children: [
              Text('Planos simples para crescer', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('O backend retorna preço, periodicidade, benefícios e elegibilidade para cada operação.', textAlign: TextAlign.center),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  const basic = _PlanCard(
                    title: 'Básico',
                    description: 'Presença profissional para ser encontrado.',
                    benefits: ['Perfil público', 'Contato via WhatsApp', 'Área de atendimento', 'Portfólio conforme limite do plano'],
                  );
                  const pro = _PlanCard(
                    title: 'Pro',
                    description: 'Mais exposição e dados para evoluir.',
                    benefits: ['Card destacado', 'Rotação justa entre assinantes Pro', 'Selo comercial Pro', 'Analytics do anúncio', 'Mais recursos de apresentação'],
                    pro: true,
                  );
                  return wide
                      ? const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: basic), SizedBox(width: 16), Expanded(child: pro)])
                      : const Column(children: [basic, SizedBox(height: 16), pro]);
                },
              ),
              const SizedBox(height: 18),
              const Text('Ser Pro representa destaque comercial e não significa melhor avaliação. O pagamento nunca é confirmado somente pelo navegador.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.title, required this.description, required this.benefits, this.pro = false});
  final String title;
  final String description;
  final List<String> benefits;
  final bool pro;

  @override
  Widget build(BuildContext context) {
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
          if (pro) const Chip(label: Text('MAIS DESTAQUE')),
          Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: pro ? Colors.white : AppColors.ink)),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: pro ? Colors.white70 : AppColors.muted)),
          const SizedBox(height: 20),
          Text('Valor definido para o seu perfil', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: pro ? AppColors.gold : AppColors.wine)),
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
              onPressed: () {},
              style: pro ? FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.wineDark) : null,
              child: Text(pro ? 'Quero o Pro' : 'Começar no Básico'),
            ),
          ),
        ],
      ),
    );
  }
}

