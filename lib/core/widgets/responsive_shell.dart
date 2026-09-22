import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'brand_logo.dart';

class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    required this.child,
    required this.location,
    super.key,
  });

  final Widget child;
  final String location;

  static const _destinations = [
    ('/', 'Início', Icons.home_outlined, Icons.home_rounded),
    ('/explorar', 'Explorar', Icons.search_outlined, Icons.search_rounded),
    ('/anunciar', 'Anunciar', Icons.add_business_outlined, Icons.add_business_rounded),
    ('/favoritos', 'Favoritos', Icons.favorite_border, Icons.favorite),
    ('/conta', 'Conta', Icons.person_outline, Icons.person),
  ];

  int get _selectedIndex {
    if (location.startsWith('/prestador') ||
        location.startsWith('/categoria') ||
        location.startsWith('/categorias')) {
      return 1;
    }
    if (location.startsWith('/meu-anuncio') ||
        location.startsWith('/planos')) {
      return 2;
    }
    if (location.startsWith('/entrar')) return 4;
    final index = _destinations.indexWhere((item) {
      if (item.$1 == '/') return location == '/';
      return location.startsWith(item.$1);
    });
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 1100;
    final page = desktop
        ? child
        : Padding(
            padding: const EdgeInsets.only(bottom: 92),
            child: child,
          );
    return Scaffold(
      extendBody: !desktop,
      appBar: desktop
          ? AppBar(
              toolbarHeight: 76,
              titleSpacing: 28,
              title: InkWell(
                onTap: () => context.go('/'),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: BrandLogo(onDark: true),
                ),
              ),
              actions: [
                for (var i = 0; i < _destinations.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: TextButton.icon(
                      onPressed: () => context.go(_destinations[i].$1),
                      icon: Icon(
                        i == _selectedIndex
                            ? _destinations[i].$4
                            : _destinations[i].$3,
                        size: 19,
                      ),
                      label: Text(_destinations[i].$2),
                      style: TextButton.styleFrom(
                        foregroundColor: i == _selectedIndex
                            ? Colors.white
                            : Colors.white70,
                        backgroundColor: i == _selectedIndex
                            ? AppColors.wine
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 24),
              ],
            )
          : AppBar(
              toolbarHeight: 66,
              title: InkWell(
                onTap: () => context.go('/'),
                borderRadius: BorderRadius.circular(12),
                child: const BrandLogo(onDark: true),
              ),
            ),
      body: _AppBackground(child: page),
      bottomNavigationBar: desktop
          ? null
          : _MobileFloatingNavigation(
              selectedIndex: _selectedIndex,
              destinations: _destinations,
              onSelected: (index) => context.go(_destinations[index].$1),
            ),
    );
  }
}

class _MobileFloatingNavigation extends StatelessWidget {
  const _MobileFloatingNavigation({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<(String, String, IconData, IconData)> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                key: const Key('mobile-floating-navigation'),
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xE6111114),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .15),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    for (var index = 0; index < destinations.length; index++)
                      Expanded(
                        child: _MobileNavItem(
                          key: Key('mobile-nav-item-$index'),
                          label: destinations[index].$2,
                          icon: destinations[index].$3,
                          selectedIcon: destinations[index].$4,
                          selected: index == selectedIndex,
                          onTap: () => onSelected(index),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: selected ? 58 : 48,
              height: 54,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [AppColors.wine, AppColors.wineDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(selected ? 22 : 18),
                border: selected
                    ? Border.all(
                        color: AppColors.gold.withValues(alpha: .55),
                      )
                    : null,
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x557A1830),
                          blurRadius: 16,
                          offset: Offset(0, 7),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    selected ? selectedIcon : icon,
                    color: selected ? Colors.white : Colors.white70,
                    size: selected ? 28 : 26,
                  ),
                  if (selected)
                    const Positioned(
                      bottom: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(dimension: 4),
                      ),
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

class PageWidth extends StatelessWidget {
  const PageWidth({required this.child, super.key, this.maxWidth = 1480});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 20,
          vertical: compact ? 10 : 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5F5),
              borderRadius: BorderRadius.circular(compact ? 24 : 34),
              border: Border.all(color: Colors.white.withValues(alpha: .16)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 34,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AppBackground extends StatelessWidget {
  const _AppBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF170308),
                AppColors.wineDark,
                Color(0xFF09090B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -170,
          right: -90,
          child: _Glow(
            color: AppColors.wineSoft.withValues(alpha: .28),
            size: 430,
          ),
        ),
        Positioned(
          top: 280,
          left: -230,
          child: _Glow(
            color: Colors.black.withValues(alpha: .42),
            size: 560,
          ),
        ),
        Positioned(
          bottom: -240,
          right: 80,
          child: _Glow(
            color: AppColors.wine.withValues(alpha: .22),
            size: 520,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
