import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_shell.dart';
import '../../../core/widgets/state_view.dart';
import '../domain/catalog_models.dart';
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
    final controller = TextEditingController(text: store.locationLabel);
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
            child: LayoutBuilder(
              builder: (context, pageConstraints) {
                final horizontalPadding = pageConstraints.maxWidth >= 900 ? 28.0 : 18.0;
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    22,
                    horizontalPadding,
                    48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _Hero(
                    title: data?.bannerTitle ?? 'Serviços perto de você',
                    subtitle: data?.bannerSubtitle ??
                        'Encontre profissionais locais com rapidez e segurança.',
                    controller: _searchController,
                    onSearch: _submitSearch,
                    city: store.locationLabel,
                    locationMessage: store.locationMessage.value,
                    onCurrentLocation: store.useCurrentLocation,
                    onChooseCity: _chooseCity,
                  ),
                  const SizedBox(height: 26),
                  SectionTitle(
                    'O que você precisa?',
                    action: 'Ver todas',
                    onAction: () => context.go('/categorias'),
                  ),
                  const SizedBox(height: 14),
                  if (data == null && phase == LoadPhase.loading)
                    const _CategorySkeleton()
                  else
                    _CategoriesStrip(
                      categories: data?.categories ?? const [],
                      onTap: (slug) => context.go('/categoria/$slug'),
                    ),
                  const SizedBox(height: 28),
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
                          itemCount: data!.providers.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 18,
                            mainAxisExtent: 326,
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
                  const SizedBox(height: 30),
                  _AdvertiseBanner(onTap: () => context.go('/anunciar')),
                    ],
                  ),
                );
              },
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A0917), AppColors.wineDark, AppColors.wine],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 26 : 34),
        boxShadow: [
          BoxShadow(
            color: AppColors.wineDark.withValues(alpha: .22),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: compact ? -90 : -25,
            top: compact ? -80 : -120,
            child: Container(
              width: compact ? 230 : 380,
              height: compact ? 230 : 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: .26),
                    AppColors.gold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: compact ? 70 : 350,
            bottom: -130,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .045),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 22 : 42),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final split = constraints.maxWidth >= 920;
                final content = _HeroContent(
                  title: title,
                  subtitle: subtitle,
                  controller: controller,
                  onSearch: onSearch,
                  city: city,
                  locationMessage: locationMessage,
                  onCurrentLocation: onCurrentLocation,
                  onChooseCity: onChooseCity,
                  compact: compact,
                );
                if (!split) {
                  return Column(
                    children: [
                      content,
                      SizedBox(height: compact ? 18 : 24),
                      _HeroPeopleVisual(compact: compact),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 7, child: content),
                    const SizedBox(width: 34),
                    const Expanded(
                      flex: 5,
                      child: _HeroPeopleVisual(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.onSearch,
    required this.city,
    required this.locationMessage,
    required this.onCurrentLocation,
    required this.onChooseCity,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final String city;
  final String locationMessage;
  final VoidCallback onCurrentLocation;
  final VoidCallback onChooseCity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .1),
            border: Border.all(color: Colors.white.withValues(alpha: .12)),
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Text(
            'CORMEX EASY',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontSize: compact ? 32 : 46,
                letterSpacing: -.8,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 20),
            ],
          ),
          child: TextField(
            controller: controller,
            onSubmitted: onSearch,
            decoration: InputDecoration(
              hintText: 'Qual serviço você procura?',
              prefixIcon: const Icon(Icons.search),
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              suffixIcon: Padding(
                padding: const EdgeInsets.all(4),
                child: IconButton.filled(
                  tooltip: 'Buscar',
                  onPressed: () => onSearch(controller.text),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
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
                backgroundColor: Colors.white.withValues(alpha: .06),
                side: BorderSide(color: Colors.white.withValues(alpha: .32)),
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
    );
  }
}

class _HeroPeopleVisual extends StatelessWidget {
  const _HeroPeopleVisual({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imageHeight = compact ? 145.0 : 220.0;
    return Container(
      height: compact ? 250 : 330,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        border: Border.all(
          color: Colors.white.withValues(alpha: .13),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: Image.asset(
              'assets/images/hero-profissional-cliente.webp',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
              semanticLabel:
                  'Casal agradecendo um profissional da CormeX Easy',
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 15,
                compact ? 9 : 10,
                compact ? 12 : 15,
                compact ? 9 : 10,
              ),
              color: AppColors.ink.withValues(alpha: .72),
              child: _HeroOfferPoints(compact: compact),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroOfferPoints extends StatelessWidget {
  const _HeroOfferPoints({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tudo em um só lugar',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 12.5 : 14.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 6 : 8),
        Row(
          children: [
            Expanded(
              child: _HeroOfferPoint(
                compact: compact,
                icon: Icons.near_me_outlined,
                label: 'Profissionais perto de você',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HeroOfferPoint(
                compact: compact,
                icon: Icons.verified_user_outlined,
                label: 'Perfis claros e verificados',
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 5 : 7),
        Row(
          children: [
            Expanded(
              child: _HeroOfferPoint(
                compact: compact,
                icon: Icons.search_rounded,
                label: 'Busca rápida por categoria',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HeroOfferPoint(
                compact: compact,
                icon: Icons.chat_bubble_outline,
                label: 'Contato direto no WhatsApp',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroOfferPoint extends StatelessWidget {
  const _HeroOfferPoint({
    required this.compact,
    required this.icon,
    required this.label,
  });

  final bool compact;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 23 : 27,
          height: compact ? 23 : 27,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: .17),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.gold,
            size: compact ? 12 : 14,
          ),
        ),
        SizedBox(width: compact ? 6 : 7),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 9.2 : 10.8,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoriesStrip extends StatefulWidget {
  const _CategoriesStrip({required this.categories, required this.onTap});

  final List<ServiceCategory> categories;
  final ValueChanged<String> onTap;

  @override
  State<_CategoriesStrip> createState() => _CategoriesStripState();
}

class _CategoriesStripState extends State<_CategoriesStrip> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _boundedOffset(double value) {
    if (!_controller.hasClients) return 0;
    return value
        .clamp(0.0, _controller.position.maxScrollExtent)
        .toDouble();
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    _controller.animateTo(
      _boundedOffset(_controller.offset + delta),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final delta = event.scrollDelta.dy.abs() >= event.scrollDelta.dx.abs()
        ? event.scrollDelta.dy
        : event.scrollDelta.dx;
    _controller.jumpTo(_boundedOffset(_controller.offset + delta));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const SizedBox(height: 112);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final showArrows = constraints.maxWidth >= 700;
        final jump = constraints.maxWidth * .72;
        return SizedBox(
          height: 132,
          child: Row(
            children: [
              if (showArrows) ...[
                _CategoryScrollButton(
                  tooltip: 'Categorias anteriores',
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: () => _scrollBy(-jump),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Listener(
                  onPointerSignal: _handlePointerSignal,
                  child: Scrollbar(
                    controller: _controller,
                    thumbVisibility: true,
                    trackVisibility: true,
                    interactive: true,
                    thickness: 5,
                    radius: const Radius.circular(99),
                    child: ListView.separated(
                      controller: _controller,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 14),
                      itemCount: widget.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => CategoryTile(
                        category: widget.categories[index],
                        onTap: () => widget.onTap(
                          widget.categories[index].slug,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (showArrows) ...[
                const SizedBox(width: 10),
                _CategoryScrollButton(
                  tooltip: 'Próximas categorias',
                  icon: Icons.arrow_forward_ios_rounded,
                  onPressed: () => _scrollBy(jump),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CategoryScrollButton extends StatelessWidget {
  const _CategoryScrollButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2D6D9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.wine.withValues(alpha: .12),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: AppColors.wine,
        iconSize: 20,
        icon: Icon(icon),
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
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7E6), Color(0xFFFFECF0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0D9C9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.wine.withValues(alpha: .06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
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
