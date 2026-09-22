import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../../catalog/data/favorites_service.dart';
import '../../catalog/presentation/catalog_store.dart';
import '../../advertise/data/billing_repository.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool loading = true;
  Map<String, dynamic>? user;
  Map<String, dynamic>? subscription;
  Map<String, dynamic>? entitlement;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final environment = getIt<AppEnvironment>();
    final api = getIt<ApiClient>();
    if (environment.useQaData) {
      user = {
        'name': 'Conta de teste QA',
        'email': 'qa@cormex.easy',
        'phone': '+55 47 99999-9999',
        'hasProviderProfile': true,
      };
      subscription = {
        'planCode': 'EASY_PROFISSIONAL',
        'status': 'active',
      };
      entitlement = {
        'active': true,
        'serviceLimit': 5,
        'categoryLimit': 1,
      };
    } else if (api.sessionToken?.isNotEmpty == true) {
      try {
        final results = await Future.wait([
          api.runFunction('v1-auth-me'),
          BillingRepository(api).subscriptionMe(),
        ]);
        user = (results[0]['user'] as Map?)?.cast<String, dynamic>();
        subscription =
            (results[1]['subscription'] as Map?)?.cast<String, dynamic>();
        entitlement =
            (results[1]['entitlement'] as Map?)?.cast<String, dynamic>();
      } on ApiException catch (exception) {
        error = exception.message;
        if (exception.type == ApiFailureType.unauthorized) {
          await api.setSessionToken(null);
        }
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _logout() async {
    final api = getIt<ApiClient>();
    try {
      if (api.sessionToken?.isNotEmpty == true) {
        await api.runFunction('v1-auth-logout');
      }
    } catch (_) {
      // O token local ainda deve ser removido se a sessão já expirou.
    }
    await api.setSessionToken(null);
    if (mounted) context.go('/');
  }

  Future<void> _resetPassword() async {
    final address = user?['email']?.toString() ?? '';
    if (address.isEmpty) return;
    try {
      if (getIt<AppEnvironment>().useQaData) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recuperação validada no ambiente QA.')),
          );
        }
        return;
      }
      await getIt<ApiClient>().runFunction(
        'v1-auth-request-password-reset',
        params: {'email': address},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instruções de senha enviadas por e-mail.')),
      );
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exception.message)),
      );
    }
  }

  Future<void> _showPreferences() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preferências'),
        content: const Text(
          'A localização continua sob controle do navegador. Você também pode limpar todos os prestadores salvos neste dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Fechar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar favoritos'),
          ),
        ],
      ),
    );
    if (clear != true) return;
    await getIt<FavoritesService>().save(<String>{});
    getIt<CatalogStore>().favoriteIds.value = <String>{};
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favoritos removidos.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final signedIn = user != null;
    final hasProviderProfile = user?['hasProviderProfile'] == true;
    return PageWidth(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sua conta', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Sua conta, seu anúncio e seus planos em um só lugar.'),
            const SizedBox(height: 24),
            if (error != null && !signedIn)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            signedIn ? user!['name']?.toString() ?? 'Sua conta' : 'Visitante',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            signedIn
                                ? user!['email']?.toString() ?? ''
                                : 'Entre para sincronizar seus dados e gerenciar anúncios.',
                          ),
                          if (signedIn && (user!['phone']?.toString().isNotEmpty ?? false))
                            Text(user!['phone'].toString()),
                          if (signedIn) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Chip(label: Text(user!['accountStatus']?.toString() ?? 'active')),
                                if (user!['hasProviderProfile'] == true)
                                  const Chip(label: Text('Prestador')),
                                for (final role in (user!['roles'] as List? ?? const []))
                                  Chip(label: Text(role.toString())),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (signedIn)
                      OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Sair'),
                      )
                    else
                      FilledButton(
                        onPressed: () => context.go('/entrar'),
                        child: const Text('Entrar'),
                      ),
                  ],
                ),
              ),
            ),
            if (signedIn && subscription != null) ...[
              const SizedBox(height: 18),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.workspace_premium_outlined),
                  ),
                  title: Text(_planName(subscription!['planCode']?.toString())),
                  subtitle: Text(
                    'Status: ${subscription!['status'] ?? '—'}'
                    '${entitlement?['active'] == true ? ' • benefícios ativos' : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/planos'),
                ),
              ),
            ],
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
                    if (hasProviderProfile) ...[
                      _ActionCard(icon: Icons.storefront, title: 'Meu perfil profissional', subtitle: 'Edite informações e disponibilidade.', onTap: () => context.go('/meu-anuncio')),
                      _ActionCard(icon: Icons.workspace_premium_outlined, title: 'Plano do anúncio', subtitle: 'Consulte ou altere o seu plano.', onTap: () => context.go('/planos')),
                    ] else
                      _ActionCard(icon: Icons.add_business, title: 'Cadastrar meu serviço', subtitle: 'Crie seu perfil profissional.', onTap: () => context.go('/anunciar')),
                    _ActionCard(icon: Icons.favorite_outline, title: 'Favoritos', subtitle: 'Veja os perfis que salvou.', onTap: () => context.go('/favoritos')),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            Card(
              child: Column(
                children: [
                  ListTile(
                    enabled: signedIn,
                    leading: const Icon(Icons.security_outlined),
                    title: const Text('Segurança e senha'),
                    subtitle: Text(signedIn ? 'Enviar redefinição para seu e-mail' : 'Entre para alterar sua senha'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: signedIn ? _resetPassword : null,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('Preferências'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showPreferences,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacidade e dados'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/privacidade'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _planName(String? code) => switch (code) {
      'EASY_PROFISSIONAL' => 'Plano Profissional',
      'EASY_NEGOCIOS' => 'Plano Negócios',
      _ => 'Plano CormeX Easy',
    };

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
