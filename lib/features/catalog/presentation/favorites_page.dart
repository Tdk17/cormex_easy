import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../../../core/widgets/state_view.dart';
import 'catalog_store.dart';
import 'catalog_widgets.dart';

class FavoritesPage extends StatelessWidget {
  FavoritesPage({super.key});

  final store = getIt<CatalogStore>();

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final providers = (store.home.value?.providers ?? [])
          .where((provider) => store.favoriteIds.value.contains(provider.id))
          .toList();
      return PageWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seus favoritos', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Favoritos sem conta ficam salvos somente neste dispositivo.'),
              const SizedBox(height: 24),
              if (providers.isEmpty)
                StateView(
                  icon: Icons.favorite_border,
                  title: 'Nenhum favorito ainda',
                  message: 'Toque no coração de um prestador para encontrá-lo aqui.',
                  actionLabel: 'Explorar serviços',
                  onAction: () => context.go('/explorar'),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1320
                        ? 4
                        : constraints.maxWidth >= 960
                            ? 3
                            : constraints.maxWidth >= 640
                            ? 2
                            : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: providers.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        mainAxisExtent: 326,
                      ),
                      itemBuilder: (context, index) {
                        final provider = providers[index];
                        return ProviderCard(
                          provider: provider,
                          isFavorite: true,
                          onFavorite: () => store.toggleFavorite(provider.id),
                          onOpen: () => context.go('/prestador/${provider.slug}'),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      );
    });
  }
}
