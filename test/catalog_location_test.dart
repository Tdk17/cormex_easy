import 'package:cormex_easy/core/config/app_environment.dart';
import 'package:cormex_easy/core/network/api_client.dart';
import 'package:cormex_easy/features/catalog/data/favorites_service.dart';
import 'package:cormex_easy/features/catalog/data/location_service.dart';
import 'package:cormex_easy/features/catalog/domain/catalog_models.dart';
import 'package:cormex_easy/features/catalog/domain/catalog_repository.dart';
import 'package:cormex_easy/features/catalog/presentation/catalog_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const environment = AppEnvironment(
    flavor: AppFlavor.qa,
    parseServerUrl: 'https://parseapi.back4app.com',
    parseApplicationId: '',
    parseClientKey: '',
    useQaData: true,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('não presume uma cidade antes da escolha do usuário', () {
    final repository = _FakeCatalogRepository();
    final api = ApiClient(environment);
    final store = CatalogStore(
      repository,
      FavoritesService(environment, api),
      _FakeLocationService(
        const LocationResult(LocationResultType.disabled),
      ),
      environment,
      api,
    );

    expect(store.hasLocation, isFalse);
    expect(store.city.value, isEmpty);
    expect(store.state.value, isEmpty);
    expect(store.locationLabel, 'Usar minha localização');
    expect(
      store.locationMessage.value,
      'Localização não definida. Use o GPS ou informe sua cidade.',
    );
  });

  test('mantém coordenadas do GPS ao pesquisar na Home', () async {
    final repository = _FakeCatalogRepository();
    final api = ApiClient(environment);
    final store = CatalogStore(
      repository,
      FavoritesService(environment, api),
      _FakeLocationService(
        const LocationResult(
          LocationResultType.success,
          latitude: -26.3044,
          longitude: -48.8487,
          city: 'Joinville',
          state: 'SC',
        ),
      ),
      environment,
      api,
    );

    await store.useCurrentLocation();
    await store.search(value: 'eletricista');

    expect(store.usingCurrentLocation.value, isTrue);
    expect(store.locationLabel, 'Joinville, SC');
    expect(repository.searchCity, isNull);
    expect(repository.searchState, isNull);
    expect(repository.searchLatitude, -26.3044);
    expect(repository.searchLongitude, -48.8487);
  });

  test('cidade manual limpa o contexto anterior do GPS', () async {
    final repository = _FakeCatalogRepository();
    final api = ApiClient(environment);
    final store = CatalogStore(
      repository,
      FavoritesService(environment, api),
      _FakeLocationService(
        const LocationResult(
          LocationResultType.success,
          latitude: -26.3044,
          longitude: -48.8487,
          city: 'Joinville',
          state: 'SC',
        ),
      ),
      environment,
      api,
    );

    await store.useCurrentLocation();
    await store.setCity('Joinville, SC');
    await store.search();

    expect(store.usingCurrentLocation.value, isFalse);
    expect(store.latitude.value, isNull);
    expect(store.longitude.value, isNull);
    expect(store.locationLabel, 'Joinville, SC');
    expect(repository.searchCity, 'Joinville');
    expect(repository.searchState, 'SC');
    expect(repository.searchLatitude, isNull);
    expect(repository.searchLongitude, isNull);
  });
  test('salva a localização e atualiza sem pedir permissão novamente', () async {
    final repository = _FakeCatalogRepository();
    final api = ApiClient(environment);
    final location = _FakeLocationService(
      const LocationResult(
        LocationResultType.success,
        latitude: -26.3044,
        longitude: -48.8487,
        city: 'Joinville',
        state: 'SC',
      ),
    );
    final store = CatalogStore(
      repository,
      FavoritesService(environment, api),
      location,
      environment,
      api,
    );

    await store.useCurrentLocation();
    await store.refreshCurrentLocation();

    final saved = await location.loadSavedLocation();
    expect(location.requestPermissionCalls, [true, false]);
    expect(store.autoLocationEnabled.value, isTrue);
    expect(saved?.city, 'Joinville');
    expect(saved?.state, 'SC');
    expect(saved?.autoRefresh, isTrue);
  });

  test('categoria e pesquisa são aplicadas diretamente na Home', () async {
    final repository = _FakeCatalogRepository();
    final api = ApiClient(environment);
    final store = CatalogStore(
      repository,
      FavoritesService(environment, api),
      _FakeLocationService(
        const LocationResult(LocationResultType.disabled),
      ),
      environment,
      api,
    );

    await store.search(
      categorySlug: 'eletricista',
      replaceCategory: true,
    );

    expect(store.hasActiveFilters, isTrue);
    expect(store.selectedCategory.value, 'eletricista');
    expect(repository.searchCategorySlug, 'eletricista');

    await store.search(
      value: 'chuveiro',
      categorySlug: null,
      replaceCategory: true,
    );

    expect(store.query.value, 'chuveiro');
    expect(store.selectedCategory.value, isNull);
    expect(repository.searchQuery, 'chuveiro');
    expect(repository.searchCategorySlug, isNull);

    await store.clearFilters();

    expect(store.hasActiveFilters, isFalse);
    expect(store.query.value, isEmpty);
  });

}

class _FakeLocationService extends LocationService {
  _FakeLocationService(this.result);

  final LocationResult result;
  final requestPermissionCalls = <bool>[];

  @override
  Future<LocationResult> requestCurrentPosition({
    bool requestPermission = true,
  }) async {
    requestPermissionCalls.add(requestPermission);
    return result;
  }
}

class _FakeCatalogRepository implements CatalogRepository {
  String? searchQuery;
  String? searchCategorySlug;
  String? searchCity;
  String? searchState;
  double? searchLatitude;
  double? searchLongitude;

  static const emptyHome = CatalogHomeData(
    categories: [],
    providers: [],
    bannerTitle: 'Teste',
    bannerSubtitle: 'Teste',
  );

  @override
  Future<ProviderProfile?> findProvider(String slug) async => null;

  @override
  Future<CatalogHomeData> loadHome({
    String? city,
    String? state,
    double? lat,
    double? lng,
  }) async {
    return emptyHome;
  }

  @override
  Future<List<ProviderProfile>> searchProviders({
    String query = '',
    String? categorySlug,
    String? city,
    String? state,
    double? lat,
    double? lng,
  }) async {
    searchQuery = query;
    searchCategorySlug = categorySlug;
    searchCity = city;
    searchState = state;
    searchLatitude = lat;
    searchLongitude = lng;
    return [];
  }
}
