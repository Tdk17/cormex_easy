import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_shell.dart';

class ManageAdPage extends StatelessWidget {
  const ManageAdPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                      const Text('Área comercial separada das configurações da conta.'),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go('/anunciar'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar anúncio'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4DC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.wine),
                    SizedBox(width: 12),
                    Expanded(child: Text('Entre na sua conta para carregar o anúncio real e as permissões fornecidas pela API.')),
                  ],
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
                    children: const [
                      _Metric(label: 'Impressões', value: '—', icon: Icons.visibility_outlined),
                      _Metric(label: 'Visitas ao perfil', value: '—', icon: Icons.person_search),
                      _Metric(label: 'Cliques no WhatsApp', value: '—', icon: Icons.chat_outlined),
                      _Metric(label: 'Favoritos', value: '—', icon: Icons.favorite_outline),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Plano e assinatura', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(child: Icon(Icons.workspace_premium_outlined)),
                        title: Text('Plano carregado pela API'),
                        subtitle: Text('Status, ciclo e elegibilidade serão confirmados pelo backend.'),
                        trailing: Chip(label: Text('Não conectado')),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(onPressed: () => context.go('/planos'), child: const Text('Ver planos disponíveis')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Column(
                  children: [
                    ListTile(leading: const Icon(Icons.storefront_outlined), title: const Text('Visualizar anúncio público'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                    const Divider(height: 1),
                    ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Logo e portfólio'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                    const Divider(height: 1),
                    ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('Área de atendimento'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                    const Divider(height: 1),
                    ListTile(leading: const Icon(Icons.schedule_outlined), title: const Text('Disponibilidade'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                    const Divider(height: 1),
                    ListTile(leading: const Icon(Icons.pause_circle_outline), title: const Text('Pausar anúncio'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
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

