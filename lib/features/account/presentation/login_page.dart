import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../catalog/data/favorites_service.dart';
import '../../catalog/presentation/catalog_store.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.nextPath = '/conta'});

  final String nextPath;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!email.text.contains('@') || password.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe e-mail e senha válidos.')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      final environment = getIt<AppEnvironment>();
      if (!environment.useQaData) {
        final api = getIt<ApiClient>();
        final result = await api.runFunction('v1-auth-login', params: {
          'email': email.text.trim(),
          'password': password.text,
        });
        await api.setSessionToken(result['sessionToken']?.toString());
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }
      final syncedFavorites = await getIt<FavoritesService>().load();
      getIt<CatalogStore>().favoriteIds.value = syncedFavorites;
      if (mounted) {
        final next = widget.nextPath.startsWith('/') &&
                !widget.nextPath.startsWith('//')
            ? widget.nextPath
            : '/conta';
        context.go(next);
      }
    } catch (error) {
      if (mounted) {
        final message = error is ApiException
            ? error.message
            : 'Não foi possível entrar. Confira seus dados.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final controller = TextEditingController(text: email.text.trim());
    final address = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar senha'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-mail da conta',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (address == null || !address.contains('@')) return;
    try {
      final environment = getIt<AppEnvironment>();
      if (!environment.useQaData) {
        await getIt<ApiClient>().runFunction(
          'v1-auth-request-password-reset',
          params: {'email': address},
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se a conta existir, enviaremos as instruções por e-mail.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(alignment: Alignment.centerLeft, child: BrandLogo()),
                  const SizedBox(height: 28),
                  Text('Entre na sua conta', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text('Gerencie seu anúncio, plano e informações públicas.'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: obscure,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
                        icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: loading ? null : _resetPassword, child: const Text('Esqueci minha senha')),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: loading ? null : _login,
                    child: loading
                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => context.go('/anunciar'),
                    child: const Text('Criar conta e anunciar'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Continuar explorando sem conta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
