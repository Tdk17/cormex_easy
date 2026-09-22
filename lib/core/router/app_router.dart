import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_page.dart';
import '../../features/account/presentation/login_page.dart';
import '../../features/admin/presentation/admin_page.dart';
import '../../features/advertise/presentation/advertise_page.dart';
import '../../features/advertise/presentation/manage_ad_page.dart';
import '../../features/advertise/presentation/plans_page.dart';
import '../../features/catalog/presentation/favorites_page.dart';
import '../../features/catalog/presentation/home_page.dart';
import '../../features/catalog/presentation/provider_page.dart';
import '../../features/system/data/system_bootstrap_service.dart';
import '../../features/system/presentation/error_page.dart';
import '../../features/system/presentation/legal_page.dart';
import '../../features/system/presentation/maintenance_page.dart';
import '../config/app_environment.dart';
import '../network/api_client.dart';
import '../widgets/responsive_shell.dart';

class AppRouter {
  AppRouter(this.system, this.environment, this.apiClient);

  final SystemBootstrapService system;
  final AppEnvironment environment;
  final ApiClient apiClient;

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (system.maintenanceEnabled &&
          state.matchedLocation != '/manutencao') {
        const publicRoutes = {
          '/',
          '/explorar',
          '/categorias',
          '/privacidade',
          '/termos',
        };
        final publicDetail =
            state.matchedLocation.startsWith('/prestador/') ||
            state.matchedLocation.startsWith('/categoria/');
        if (!system.allowPublicRead ||
            (!publicRoutes.contains(state.matchedLocation) && !publicDetail)) {
          return '/manutencao';
        }
      }

      final signedIn =
          environment.useQaData || apiClient.sessionToken?.isNotEmpty == true;
      const protectedRoutes = {'/conta', '/meu-anuncio', '/planos'};
      if (!signedIn && protectedRoutes.contains(state.matchedLocation)) {
        return Uri(
          path: '/entrar',
          queryParameters: {'next': state.uri.toString()},
        ).toString();
      }
      return null;
    },
    errorBuilder: (context, state) => const ResponsiveShell(
      location: '/erro/404',
      child: ErrorPage(),
    ),
    routes: [
      GoRoute(
        path: '/manutencao',
        builder: (context, state) => MaintenancePage(
          emergency: system.maintenanceType == 'emergency' ||
              state.uri.queryParameters['tipo'] == 'emergencial',
          title: system.maintenanceTitle,
          message: system.maintenanceMessage,
          estimatedReturnAt: system.estimatedReturnAt,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => ResponsiveShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => HomePage(
              initialQuery: state.uri.queryParameters['q'] ?? '',
              initialCategory: state.uri.queryParameters['categoria'],
            ),
          ),
          GoRoute(
            path: '/explorar',
            redirect: (context, state) {
              final query = state.uri.queryParameters['q'];
              final category = state.uri.queryParameters['categoria'];
              final parameters = <String, String>{
                if (query != null && query.trim().isNotEmpty) 'q': query,
                if (category != null && category.trim().isNotEmpty)
                  'categoria': category,
              };
              return Uri(
                path: '/',
                queryParameters: parameters.isEmpty ? null : parameters,
              ).toString();
            },
          ),
          GoRoute(
            path: '/categorias',
            redirect: (context, state) => '/',
          ),
          GoRoute(
            path: '/categoria/:slug',
            redirect: (context, state) {
              final slug = state.pathParameters['slug'] ?? '';
              return Uri(
                path: '/',
                queryParameters: {'categoria': slug},
              ).toString();
            },
          ),
          GoRoute(
            path: '/prestador/:slug',
            builder: (context, state) => ProviderPage(
              slug: state.pathParameters['slug']!,
            ),
          ),
          GoRoute(
            path: '/favoritos',
            builder: (context, state) => FavoritesPage(),
          ),
          GoRoute(
            path: '/anunciar',
            builder: (context, state) => const AdvertisePage(),
          ),
          GoRoute(
            path: '/entrar',
            builder: (context, state) => LoginPage(
              nextPath: state.uri.queryParameters['next'] ?? '/conta',
            ),
          ),
          GoRoute(
            path: '/cadastro',
            redirect: (context, state) => '/conta',
          ),
          GoRoute(
            path: '/conta',
            builder: (context, state) => const AccountPage(),
          ),
          GoRoute(
            path: '/meu-anuncio',
            builder: (context, state) => const ManageAdPage(),
          ),
          GoRoute(
            path: '/planos',
            builder: (context, state) => const PlansPage(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => AdminPage(
              preview: state.uri.queryParameters['preview'] == 'qa',
            ),
          ),
          GoRoute(
            path: '/privacidade',
            builder: (context, state) =>
                const LegalPage(title: 'Política de Privacidade'),
          ),
          GoRoute(
            path: '/termos',
            builder: (context, state) =>
                const LegalPage(title: 'Termos de Uso'),
          ),
          GoRoute(
            path: '/erro/:code',
            builder: (context, state) => ErrorPage(
              code: int.tryParse(state.pathParameters['code'] ?? '') ?? 404,
            ),
          ),
        ],
      ),
    ],
  );
}
