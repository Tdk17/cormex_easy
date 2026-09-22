import 'package:cormex_easy/core/widgets/responsive_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _setScreenSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('mobile usa navegação inferior flutuante com cinco destinos',
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
    expect(find.byTooltip('Início'), findsOneWidget);
    expect(find.byTooltip('Explorar'), findsOneWidget);
    expect(find.byTooltip('Anunciar'), findsOneWidget);
    expect(find.byTooltip('Favoritos'), findsOneWidget);
    expect(find.byTooltip('Conta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet estreito mantém a navegação flutuante sem overflow',
      (tester) async {
    _setScreenSize(tester, const Size(900, 1000));

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveShell(
          location: '/explorar',
          child: SizedBox.expand(),
        ),
      ),
    );

    expect(find.byKey(const Key('mobile-floating-navigation')), findsOneWidget);
    expect(find.byKey(const Key('mobile-nav-item-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop mantém a navegação no cabeçalho', (tester) async {
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
    expect(find.text('Explorar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
