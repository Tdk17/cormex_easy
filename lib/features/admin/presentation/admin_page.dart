import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../../../core/widgets/state_view.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, this.preview = false});

  final bool preview;

  @override
  Widget build(BuildContext context) {
    if (!preview) {
      return const StateView(
        icon: Icons.lock_outline,
        title: 'Acesso administrativo protegido',
        message: 'Sua permissão precisa ser validada pelo backend. Ocultar menus no navegador não concede acesso.',
      );
    }
    return SingleChildScrollView(
      child: PageWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Administração', style: Theme.of(context).textTheme.headlineMedium)),
                  const Chip(label: Text('PREVIEW QA')),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Estrutura visual preparada. Dados e permissões virão da API administrativa.'),
              const SizedBox(height: 24),
              LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 580 ? 2 : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  childAspectRatio: columns == 1 ? 3.2 : 1.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: const [
                    _AdminMetric('Usuários', '—', Icons.people_outline),
                    _AdminMetric('Anúncios ativos', '—', Icons.storefront_outlined),
                    _AdminMetric('Assinaturas', '—', Icons.credit_card_outlined),
                    _AdminMetric('Denúncias abertas', '—', Icons.flag_outlined),
                  ],
                );
              }),
              const SizedBox(height: 18),
              Card(
                child: Column(
                  children: const [
                    _AdminItem('Usuários', 'Contas, status e permissões', Icons.people_outline),
                    Divider(height: 1),
                    _AdminItem('Prestadores e anúncios', 'Revisão, pausa e verificações', Icons.storefront_outlined),
                    Divider(height: 1),
                    _AdminItem('Categorias', 'Ordem, disponibilidade e conteúdo', Icons.category_outlined),
                    Divider(height: 1),
                    _AdminItem('Planos e assinaturas', 'Elegibilidade e regras comerciais', Icons.workspace_premium_outlined),
                    Divider(height: 1),
                    _AdminItem('Denúncias', 'Fila de moderação', Icons.flag_outlined),
                    Divider(height: 1),
                    _AdminItem('Feature flags e manutenção', 'Controle remoto da experiência', Icons.tune),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminMetric extends StatelessWidget {
  const _AdminMetric(this.label, this.value, this.icon);
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
            Text(value, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _AdminItem extends StatelessWidget {
  const _AdminItem(this.title, this.subtitle, this.icon);
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.wine),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

