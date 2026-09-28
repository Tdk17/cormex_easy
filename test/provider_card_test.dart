import 'package:cormex_easy/features/catalog/domain/catalog_models.dart';
import 'package:cormex_easy/features/catalog/presentation/catalog_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const category = ServiceCategory(
    id: 'cat-1',
    name: 'Eletricista',
    slug: 'eletricista',
    iconKey: 'bolt',
  );
  const provider = ProviderProfile(
    id: 'provider-1',
    slug: 'eletrica-benedito',
    displayName: 'Elétrica Benedito',
    category: category,
    description: 'Instalações e manutenção residencial com garantia.',
    city: 'Benedito Novo',
    state: 'SC',
    whatsapp: '55 (47) 99999-9999',
    providerType: 'Autônomo',
    services: ['Instalações', 'Manutenção', 'Quadros elétricos'],
    serviceArea: 'Benedito Novo e região',
    availability: 'Segunda a sábado',
  );

  testWidgets('card mostra informações, gira e expõe ações de serviço',
      (tester) async {
    var contacted = false;
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              height: 390,
              child: ProviderCard(
                provider: provider,
                isFavorite: false,
                onFavorite: () {},
                onWhatsApp: () => contacted = true,
                onOpen: () => opened = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(provider.description), findsOneWidget);
    expect(find.text('Benedito Novo - SC'), findsOneWidget);
    expect(find.text('Atende: Benedito Novo e região'), findsOneWidget);

    await tester.tap(find.text('Toque para ver serviços'));
    await tester.pumpAndSettle();

    expect(find.text('SERVIÇOS OFERECIDOS'), findsOneWidget);
    expect(find.text('Instalações'), findsOneWidget);
    expect(find.text('Manutenção'), findsOneWidget);
    expect(find.text('Quadros elétricos'), findsOneWidget);

    await tester.tap(find.text('Entrar em contato no WhatsApp'));
    expect(contacted, isTrue);

    await tester.tap(find.text('Ver perfil completo'));
    expect(opened, isTrue);
  });
}
