import 'dart:convert';

import 'package:cormex_easy/core/config/app_environment.dart';
import 'package:cormex_easy/core/network/api_client.dart';
import 'package:cormex_easy/features/catalog/data/catalog_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const environment = AppEnvironment(
    flavor: AppFlavor.production,
    parseServerUrl: 'https://parseapi.back4app.com',
    parseApplicationId: 'test-app',
    parseClientKey: 'test-client',
    useQaData: false,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('usa o último catálogo salvo quando a API fica offline', () async {
    final payload = {
      'categories': [
        {
          'publicId': 'cat_1',
          'name': 'Eletricista',
          'slug': 'eletricista',
          'icon': 'bolt',
        },
      ],
      'providers': <Object>[],
      'banner': {
        'title': 'Serviços perto de você',
        'subtitle': 'Teste offline',
      },
      'featureFlags': {'reviews': false},
    };
    final onlineClient = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'result': {
            'success': true,
            'data': payload,
          },
        }),
        200,
      ),
    );
    final onlineRepository = CatalogRepositoryImpl(
      environment,
      ApiClient(environment, client: onlineClient),
    );

    final online = await onlineRepository.loadHome(
      city: 'Blumenau',
      state: 'SC',
    );

    expect(online.isFromCache, isFalse);
    expect(online.categories.single.name, 'Eletricista');

    final offlineClient = MockClient(
      (_) async => throw http.ClientException('sem internet'),
    );
    final offlineRepository = CatalogRepositoryImpl(
      environment,
      ApiClient(environment, client: offlineClient),
    );

    final offline = await offlineRepository.loadHome(
      city: 'Blumenau',
      state: 'SC',
    );

    expect(offline.isFromCache, isTrue);
    expect(offline.categories.single.slug, 'eletricista');
    expect(offline.bannerSubtitle, 'Teste offline');
  });
}
