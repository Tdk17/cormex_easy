import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_shell.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWidth(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sua conta', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Dados pessoais e preferências ficam separados do anúncio comercial.'),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: Color(0xFFF2E7EA),
                      child: Icon(Icons.person_outline, color: AppColors.wine, size: 32),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Visitante', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          SizedBox(height: 4),
                          Text('Entre para sincronizar seus dados e gerenciar anúncios.'),
                        ],
                      ),
                    ),
                    FilledButton(onPressed: () => context.go('/entrar'), child: const Text('Entrar')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760 ? 3 : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  childAspectRatio: columns == 1 ? 3.4 : 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _ActionCard(icon: Icons.add_business, title: 'Anunciar meu serviço', subtitle: 'Crie seu perfil público.', onTap: () => context.go('/anunciar')),
                    _ActionCard(icon: Icons.storefront, title: 'Gerenciar anúncio', subtitle: 'Edite informações e plano.', onTap: () => context.go('/meu-anuncio')),
                    _ActionCard(icon: Icons.favorite_outline, title: 'Favoritos', subtitle: 'Veja os perfis que salvou.', onTap: () => context.go('/favoritos')),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            Card(
              child: Column(
                children: [
                  ListTile(leading: const Icon(Icons.security_outlined), title: const Text('Segurança e senha'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.tune), title: const Text('Preferências'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.privacy_tip_outlined), title: const Text('Privacidade e dados'), trailing: const Icon(Icons.chevron_right), onTap: () => context.go('/privacidade')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.wine, size: 30),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

