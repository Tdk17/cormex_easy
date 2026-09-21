import 'dart:async';

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
  Future<CatalogHomeData> loadHome({
    String? city,
    String? state,
    double? lat,
    double? lng,
  }) async {
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
      if (state != null && state.isNotEmpty) 'state': state,
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
    _trackImpressions(providers);
    return CatalogHomeData(
      categories: categories,
      providers: providers,
      bannerTitle: banner['title']?.toString() ?? 'Serviços perto de você',
      bannerSubtitle: banner['subtitle']?.toString().trim().isNotEmpty == true
          ? banner['subtitle'].toString()
          : 'Profissionais de confiança para resolver o que você precisa.',
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
    String? state,
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
      if (state != null && state.isNotEmpty) 'state': state,
    });
    final providers = (json['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => ProviderProfile.fromJson(e.cast<String, dynamic>()))
        .toList();
    _trackImpressions(providers);
    return providers;
  }

  void _trackImpressions(List<ProviderProfile> providers) {
    final batch = DateTime.now().microsecondsSinceEpoch;
    for (var index = 0; index < providers.length; index++) {
      unawaited(_trackImpression(providers[index], batch, index));
    }
  }

  Future<void> _trackImpression(
    ProviderProfile provider,
    int batch,
    int index,
  ) async {
    try {
      await apiClient.runFunction('v1-providers-track-event', params: {
        'providerPublicId': provider.id,
        'eventType': 'card_impression',
        'eventId': 'card_impression_${provider.id}_${batch}_$index',
        'source': 'web',
      });
    } catch (_) {
      // Analytics não deve bloquear o catálogo.
    }
  }
}
