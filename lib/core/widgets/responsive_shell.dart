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
    final index = _destinations.indexWhere((item) {
      if (item.$1 == '/') return location == '/';
      return location.startsWith(item.$1);
    });
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: desktop
          ? AppBar(
              toolbarHeight: 76,
              backgroundColor: Colors.white.withValues(alpha: .96),
              surfaceTintColor: Colors.transparent,
              titleSpacing: 28,
              title: InkWell(
                onTap: () => context.go('/'),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: BrandLogo(),
                ),
              ),
              actions: [
                for (var i = 0; i < _destinations.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
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
                            ? AppColors.wine
                            : AppColors.ink,
                      ),
                    ),
                  ),
                const SizedBox(width: 24),
              ],
            )
          : AppBar(
              title: InkWell(
                onTap: () => context.go('/'),
                child: const BrandLogo(),
              ),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
      body: _AppBackground(child: child),
      bottomNavigationBar: desktop
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                context.go(_destinations[index].$1);
              },
              destinations: [
                for (final item in _destinations)
                  NavigationDestination(
                    icon: Icon(item.$3),
                    selectedIcon: Icon(item.$4),
                    label: item.$2,
                  ),
              ],
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
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
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
                Color(0xFFFFFCFB),
                Color(0xFFFAF3F5),
                Color(0xFFFFF9ED),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -170,
          right: -100,
          child: _Glow(color: AppColors.gold.withValues(alpha: .14), size: 430),
        ),
        Positioned(
          top: 260,
          left: -210,
          child: _Glow(color: AppColors.wine.withValues(alpha: .08), size: 520),
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
