import 'package:cormex_easy/core/widgets/responsive_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void _setScreenSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('mobile usa navegação leve com três destinos',
      (tester) async {
    _setScreenSize(tester, const Size(390, 844));

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveShell(
          location: '/',
          child: SizedBox.expand(),
        ),
      ),
    );

    expect(find.byKey(const Key('mobile-floating-navigation')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byTooltip('Início'), findsOneWidget);
    expect(find.byTooltip('Explorar'), findsNothing);
    expect(find.byTooltip('Anunciar'), findsNothing);
    expect(find.byTooltip('Favoritos'), findsOneWidget);
    expect(find.byTooltip('Conta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('todos os botões móveis navegam para o destino correto',
      (tester) async {
    _setScreenSize(tester, const Size(390, 844));

    final router = GoRouter(
      initialLocation: '/favoritos',
      routes: [
        ShellRoute(
          builder: (context, state, child) => ResponsiveShell(
            location: state.uri.path,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  const Center(child: Text('destino-0')),
            ),
            GoRoute(
              path: '/favoritos',
              builder: (context, state) =>
                  const Center(child: Text('destino-1')),
            ),
            GoRoute(
              path: '/conta',
              builder: (context, state) =>
                  const Center(child: Text('destino-2')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byKey(Key('mobile-nav-item-$index')));
      await tester.pumpAndSettle();

      expect(
        find.text('destino-$index'),
        findsOneWidget,
        reason: 'O botão móvel $index não abriu o destino esperado.',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('tablet mantém a navegação flutuante sem overflow',
      (tester) async {
    _setScreenSize(tester, const Size(900, 1000));

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveShell(
          location: '/conta',
          child: SizedBox.expand(),
        ),
      ),
    );

    expect(find.byKey(const Key('mobile-floating-navigation')), findsOneWidget);
    expect(find.byKey(const Key('mobile-nav-item-2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop mantém somente as rotas principais no cabeçalho',
      (tester) async {
    _setScreenSize(tester, const Size(1366, 768));

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveShell(
          location: '/',
          child: SizedBox.expand(),
        ),
      ),
    );

    expect(find.byKey(const Key('mobile-floating-navigation')), findsNothing);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Explorar'), findsNothing);
    expect(find.text('Anunciar'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
