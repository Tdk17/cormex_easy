import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/widgets/responsive_shell.dart';
import 'catalog_store.dart';
import 'catalog_widgets.dart';

class CategoriesPage extends StatelessWidget {
  CategoriesPage({super.key});

  final store = getIt<CatalogStore>();

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final categories = store.home.value?.categories ?? [];
      return PageWidth(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Todas as categorias', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Escolha uma categoria para encontrar profissionais na sua região.'),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth < 560 ? 150.0 : 180.0;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final category in categories)
                        SizedBox(
                          width: width,
                          child: CategoryTile(
                            category: category,
                            onTap: () => context.go('/categoria/${category.slug}'),
                          ),
                        ),
                    ],
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

