import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_page.dart';
import '../../features/account/presentation/login_page.dart';
import '../../features/admin/presentation/admin_page.dart';
import '../../features/advertise/presentation/advertise_page.dart';
import '../../features/advertise/presentation/manage_ad_page.dart';
import '../../features/advertise/presentation/plans_page.dart';
import '../../features/catalog/presentation/categories_page.dart';
import '../../features/catalog/presentation/explore_page.dart';
import '../../features/catalog/presentation/favorites_page.dart';
import '../../features/catalog/presentation/home_page.dart';
import '../../features/catalog/presentation/provider_page.dart';
import '../../features/system/presentation/error_page.dart';
import '../../features/system/presentation/legal_page.dart';
import '../../features/system/presentation/maintenance_page.dart';
import '../widgets/responsive_shell.dart';

class AppRouter {
  late final GoRouter router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => const ResponsiveShell(
      location: '/erro/404',
      child: ErrorPage(),
    ),
    routes: [
      GoRoute(
        path: '/manutencao',
        builder: (context, state) => MaintenancePage(
          emergency: state.uri.queryParameters['tipo'] == 'emergencial',
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => ResponsiveShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/explorar',
            builder: (context, state) => ExplorePage(
              initialQuery: state.uri.queryParameters['q'] ?? '',
              categorySlug: state.uri.queryParameters['categoria'],
            ),
          ),
          GoRoute(path: '/categorias', builder: (context, state) => CategoriesPage()),
          GoRoute(
            path: '/categoria/:slug',
            builder: (context, state) => ExplorePage(categorySlug: state.pathParameters['slug']),
          ),
          GoRoute(
            path: '/prestador/:slug',
            builder: (context, state) => ProviderPage(slug: state.pathParameters['slug']!),
          ),
          GoRoute(path: '/favoritos', builder: (context, state) => FavoritesPage()),
          GoRoute(path: '/anunciar', builder: (context, state) => const AdvertisePage()),
          GoRoute(path: '/entrar', builder: (context, state) => const LoginPage()),
          GoRoute(path: '/cadastro', redirect: (context, state) => '/anunciar'),
          GoRoute(path: '/conta', builder: (context, state) => const AccountPage()),
          GoRoute(path: '/meu-anuncio', builder: (context, state) => const ManageAdPage()),
          GoRoute(path: '/planos', builder: (context, state) => const PlansPage()),
          GoRoute(
            path: '/admin',
            builder: (context, state) => AdminPage(
              preview: state.uri.queryParameters['preview'] == 'qa',
            ),
          ),
          GoRoute(path: '/privacidade', builder: (context, state) => const LegalPage(title: 'Política de Privacidade')),
          GoRoute(path: '/termos', builder: (context, state) => const LegalPage(title: 'Termos de Uso')),
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
