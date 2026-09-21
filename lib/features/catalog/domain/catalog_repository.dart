import 'catalog_models.dart';

abstract interface class CatalogRepository {
  Future<CatalogHomeData> loadHome({String? city, double? lat, double? lng});
  Future<ProviderProfile?> findProvider(String slug);
  Future<List<ProviderProfile>> searchProviders({
    String query = '',
    String? categorySlug,
    String? city,
  });
}

