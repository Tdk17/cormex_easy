import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../../../core/widgets/state_view.dart';
import 'catalog_store.dart';
import 'catalog_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  final store = getIt<CatalogStore>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    final query = Uri.encodeQueryComponent(value.trim());
    context.go(query.isEmpty ? '/explorar' : '/explorar?q=$query');
  }

  Future<void> _chooseCity() async {
    final controller = TextEditingController(text: store.city.value);
    final city = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Escolha sua região', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Usaremos a cidade somente para mostrar serviços relevantes.'),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Cidade e estado',
                hintText: 'Ex.: Blumenau, SC',
                prefixIcon: Icon(Icons.location_city),
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Aplicar localização'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (city != null) await store.setCity(city);
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final data = store.home.value;
      final phase = store.phase.value;
      return RefreshIndicator(
        onRefresh: () => store.loadHome(refresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Hero(
                    title: data?.bannerTitle ?? 'Serviços perto de você',
                    subtitle: data?.bannerSubtitle ??
                        'Encontre profissionais locais com rapidez e segurança.',
                    controller: _searchController,
                    onSearch: _submitSearch,
                    city: store.city.value,
                    locationMessage: store.locationMessage.value,
                    onCurrentLocation: store.useCurrentLocation,
                    onChooseCity: _chooseCity,
                  ),
                  const SizedBox(height: 30),
                  SectionTitle(
                    'O que você precisa?',
                    action: 'Ver todas',
                    onAction: () => context.go('/categorias'),
                  ),
                  const SizedBox(height: 12),
                  if (data == null && phase == LoadPhase.loading)
                    const _CategorySkeleton()
                  else
                    SizedBox(
                      height: 116,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: data?.categories.length ?? 0,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final category = data!.categories[index];
                          return CategoryTile(
                            category: category,
                            onTap: () => context.go('/categoria/${category.slug}'),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 32),
                  const SectionTitle('Recomendados na sua região'),
                  const SizedBox(height: 12),
                  if (phase == LoadPhase.loading && data == null)
                    const _ProviderSkeleton()
                  else if (phase == LoadPhase.error)
                    StateView(
                      icon: Icons.cloud_off,
                      title: 'Não conseguimos carregar os serviços',
                      message: store.errorMessage.value ?? 'Tente novamente em instantes.',
                      actionLabel: 'Tentar novamente',
                      onAction: store.loadHome,
                    )
                  else if ((data?.providers ?? []).isEmpty)
                    StateView(
                      icon: Icons.search_off,
                      title: 'Nenhum serviço por aqui ainda',
                      message: 'Altere sua região ou seja o primeiro a anunciar.',
                      actionLabel: 'Alterar região',
                      onAction: _chooseCity,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 1050
                            ? 3
                            : constraints.maxWidth >= 680
                                ? 2
                                : 1;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: data!.providers.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 228,
                          ),
                          itemBuilder: (context, index) {
                            final provider = data.providers[index];
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
                  const SizedBox(height: 34),
                  _AdvertiseBanner(onTap: () => context.go('/anunciar')),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.onSearch,
    required this.city,
    required this.locationMessage,
    required this.onCurrentLocation,
    required this.onChooseCity,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final String city;
  final String locationMessage;
  final VoidCallback onCurrentLocation;
  final VoidCallback onChooseCity;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 22 : 38),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.wineDark, AppColors.wine],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'CORMEX EASY',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontSize: compact ? 32 : 44,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: controller,
              onSubmitted: onSearch,
              decoration: InputDecoration(
                hintText: 'Qual serviço você procura?',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  onPressed: () => onSearch(controller.text),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: Text(city),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                ),
                TextButton(
                  onPressed: onChooseCity,
                  style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                  child: const Text('Alterar cidade'),
                ),
                Text(
                  locationMessage,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvertiseBanner extends StatelessWidget {
  const _AdvertiseBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 16,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu trabalho merece ser encontrado.',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6),
                Text('Crie seu perfil e fale diretamente com clientes da sua região.'),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add_business),
            label: const Text('Anunciar meu serviço'),
          ),
        ],
      ),
    );
  }
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 116,
      child: Row(
        children: [
          Expanded(child: _PulseBox()),
          SizedBox(width: 10),
          Expanded(child: _PulseBox()),
          SizedBox(width: 10),
          Expanded(child: _PulseBox()),
        ],
      ),
    );
  }
}

class _ProviderSkeleton extends StatelessWidget {
  const _ProviderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 220, child: _PulseBox());
  }
}

class _PulseBox extends StatelessWidget {
  const _PulseBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8E9),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
