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

  test('mantém coordenadas do GPS ao pesquisar em Explorar', () async {
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
        ),
      ),
      environment,
      api,
    );

    await store.useCurrentLocation();
    await store.search(value: 'eletricista');

    expect(store.usingCurrentLocation.value, isTrue);
    expect(store.locationLabel, 'Localização atual');
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
}

class _FakeLocationService extends LocationService {
  _FakeLocationService(this.result);

  final LocationResult result;

  @override
  Future<LocationResult> requestCurrentPosition() async => result;
}

class _FakeCatalogRepository implements CatalogRepository {
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
    searchCity = city;
    searchState = state;
    searchLatitude = lat;
    searchLongitude = lng;
    return [];
  }
}
