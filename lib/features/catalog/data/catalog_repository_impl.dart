import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../domain/catalog_models.dart';
import '../domain/catalog_repository.dart';
import 'qa_catalog_data.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl(this.environment, this.apiClient);

  final AppEnvironment environment;
  final ApiClient apiClient;

  @override
  Future<CatalogHomeData> loadHome({String? city, double? lat, double? lng}) async {
    if (environment.useQaData) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return CatalogHomeData(
        categories: QaCatalogData.categories,
        providers: QaCatalogData.providers,
        bannerTitle: 'O serviço certo, perto de você.',
        bannerSubtitle: 'Encontre profissionais locais ou anuncie o que você faz.',
        reviewsEnabled: true,
      );
    }
    final json = await apiClient.runFunction('v1-home-get', params: {
      if (city != null && city.isNotEmpty) 'city': city,
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
    });
    final categories = (json['categories'] as List? ?? [])
        .whereType<Map>()
        .map((e) => ServiceCategory.fromJson(e.cast<String, dynamic>()))
        .toList();
    final providers = (json['providers'] as List? ?? [])
        .whereType<Map>()
        .map((e) => ProviderProfile.fromJson(e.cast<String, dynamic>()))
        .toList();
    final banner = (json['banner'] as Map?)?.cast<String, dynamic>() ?? {};
    final flags = (json['featureFlags'] as Map?)?.cast<String, dynamic>() ?? {};
    return CatalogHomeData(
      categories: categories,
      providers: providers,
      bannerTitle: banner['title']?.toString() ?? 'Serviços perto de você',
      bannerSubtitle: banner['subtitle']?.toString() ?? '',
      reviewsEnabled: flags['reviews'] == true,
    );
  }

  @override
  Future<ProviderProfile?> findProvider(String slug) async {
    if (environment.useQaData) {
      return QaCatalogData.providers.where((p) => p.slug == slug).firstOrNull;
    }
    final json = await apiClient.runFunction(
      'v1-providers-detail',
      params: {'slug': slug},
    );
    final data = (json['provider'] as Map?)?.cast<String, dynamic>();
    return data == null ? null : ProviderProfile.fromJson(data);
  }

  @override
  Future<List<ProviderProfile>> searchProviders({
    String query = '',
    String? categorySlug,
    String? city,
  }) async {
    if (environment.useQaData) {
      final needle = query.trim().toLowerCase();
      return QaCatalogData.providers.where((provider) {
        final matchesCategory = categorySlug == null ||
            categorySlug.isEmpty ||
            provider.category.slug == categorySlug;
        final haystack = '${provider.displayName} ${provider.category.name} '
                '${provider.services.join(' ')} ${provider.city}'
            .toLowerCase();
        return matchesCategory && (needle.isEmpty || haystack.contains(needle));
      }).toList();
    }
    final json = await apiClient.runFunction('v1-providers-search', params: {
      if (query.isNotEmpty) 'query': query,
      if (categorySlug != null && categorySlug.isNotEmpty)
        'categorySlug': categorySlug,
      if (city != null && city.isNotEmpty) 'city': city,
    });
    return (json['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => ProviderProfile.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}
