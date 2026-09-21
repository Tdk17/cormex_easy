import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../../../core/widgets/state_view.dart';
import 'catalog_store.dart';
import 'catalog_widgets.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key, this.initialQuery = '', this.categorySlug});

  final String initialQuery;
  final String? categorySlug;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final store = getIt<CatalogStore>();
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      store.search(value: widget.initialQuery, categorySlug: widget.categorySlug ?? '');
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final data = store.home.value;
      final providers = store.visibleProviders.value;
      return PageWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Explorar serviços', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Resultados em ${store.locationLabel}'),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) => store.search(value: value),
                decoration: InputDecoration(
                  hintText: 'Prestador, serviço ou categoria',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () => store.search(value: controller.text),
                    tooltip: 'Buscar',
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: (store.selectedCategory.value ?? '').isEmpty,
                      onSelected: (_) => store.search(categorySlug: ''),
                    ),
                    const SizedBox(width: 8),
                    for (final category in data?.categories ?? []) ...[
                      ChoiceChip(
                        avatar: Icon(categoryIcon(category.iconKey), size: 16),
                        label: Text(category.name),
                        selected: store.selectedCategory.value == category.slug,
                        onSelected: (_) => store.search(categorySlug: category.slug),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (store.phase.value == LoadPhase.loading)
                const Center(child: CircularProgressIndicator())
              else if (store.phase.value == LoadPhase.error)
                StateView(
                  icon: Icons.cloud_off,
                  title: 'Busca indisponível',
                  message: store.errorMessage.value ?? 'Tente novamente.',
                  actionLabel: 'Repetir busca',
                  onAction: store.search,
                )
              else if (providers.isEmpty)
                StateView(
                  icon: Icons.search_off,
                  title: 'Nenhum resultado encontrado',
                  message: 'Tente outro termo, categoria ou região.',
                  actionLabel: 'Limpar filtros',
                  onAction: () {
                    controller.clear();
                    store.search(value: '', categorySlug: '');
                  },
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
                          isFavorite: store.isFavorite(provider.id),
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
