import 'package:cormex_easy/core/widgets/responsive_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mobile usa navegação inferior flutuante com cinco destinos',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
    await tester.binding.setSurfaceSize(const Size(1366, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
