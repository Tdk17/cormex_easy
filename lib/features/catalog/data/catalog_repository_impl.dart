import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../domain/catalog_models.dart';
import '../domain/catalog_repository.dart';
import 'qa_catalog_data.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl(this.environment, this.apiClient);

  final AppEnvironment environment;
  final ApiClient apiClient;

  String get _homeCacheKey =>
      'cormex_easy.${environment.flavor.name}.catalog_home.v1';
  String get _searchCacheKey =>
      'cormex_easy.${environment.flavor.name}.catalog_search.v1';

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
        bannerSubtitle:
            'Encontre profissionais locais ou anuncie o que você faz.',
        reviewsEnabled: true,
      );
    }

    final fingerprint = _locationFingerprint(city, state, lat, lng);
    late Map<String, dynamic> json;
    var isFromCache = false;
    try {
      json = await apiClient.runFunction('v1-home-get', params: {
        if (city != null && city.isNotEmpty) 'city': city,
        if (state != null && state.isNotEmpty) 'state': state,
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
      });
      await _writeCache(_homeCacheKey, fingerprint, json);
    } catch (_) {
      final cached = await _readCache(_homeCacheKey, fingerprint);
      if (cached == null) rethrow;
      json = cached;
      isFromCache = true;
    }

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
    if (!isFromCache) _trackImpressions(providers);
    return CatalogHomeData(
      categories: categories,
      providers: providers,
      bannerTitle: banner['title']?.toString() ?? 'Serviços perto de você',
      bannerSubtitle: banner['subtitle']?.toString().trim().isNotEmpty == true
          ? banner['subtitle'].toString()
          : 'Profissionais de confiança para resolver o que você precisa.',
      reviewsEnabled: flags['reviews'] == true,
      isFromCache: isFromCache,
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
    double? lat,
    double? lng,
  }) async {
    if (environment.useQaData) {
      final needle = query.trim().toLowerCase();
      return QaCatalogData.providers.where((provider) {
        final matchesCategory = categorySlug == null ||
            categorySlug.isEmpty ||
            provider.category.slug == categorySlug;
        final haystack =
            '${provider.displayName} ${provider.category.name} '
                    '${provider.services.join(' ')} ${provider.city}'
                .toLowerCase();
        return matchesCategory && (needle.isEmpty || haystack.contains(needle));
      }).toList();
    }

    final locationFingerprint =
        _locationFingerprint(city, state, lat, lng);
    final searchFingerprint = [
      query.trim().toLowerCase(),
      categorySlug ?? '',
      locationFingerprint,
    ].join('|');
    late Map<String, dynamic> json;
    var isFromCache = false;
    try {
      json = await apiClient.runFunction('v1-providers-search', params: {
        if (query.isNotEmpty) 'query': query,
        if (categorySlug != null && categorySlug.isNotEmpty)
          'categorySlug': categorySlug,
        if (city != null && city.isNotEmpty) 'city': city,
        if (state != null && state.isNotEmpty) 'state': state,
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
      });
      await _writeCache(_searchCacheKey, searchFingerprint, json);
    } catch (_) {
      json = await _readCache(_searchCacheKey, searchFingerprint) ??
          await _searchHomeCache(
            query: query,
            categorySlug: categorySlug,
            locationFingerprint: locationFingerprint,
          ) ??
          (throw StateError('Nenhum catálogo salvo para esta localização.'));
      isFromCache = true;
    }

    final providers = (json['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => ProviderProfile.fromJson(e.cast<String, dynamic>()))
        .toList();
    if (!isFromCache) _trackImpressions(providers);
    return providers;
  }

  Future<Map<String, dynamic>?> _searchHomeCache({
    required String query,
    required String? categorySlug,
    required String locationFingerprint,
  }) async {
    final home = await _readCache(_homeCacheKey, locationFingerprint);
    if (home == null) return null;
    final needle = query.trim().toLowerCase();
    final items = (home['providers'] as List? ?? []).whereType<Map>().where(
      (raw) {
        final provider = raw.cast<String, dynamic>();
        final category =
            (provider['category'] as Map?)?.cast<String, dynamic>() ?? {};
        final matchesCategory = categorySlug == null ||
            categorySlug.isEmpty ||
            category['slug']?.toString() == categorySlug;
        final location =
            (provider['location'] as Map?)?.cast<String, dynamic>() ?? {};
        final services = (provider['services'] as List? ?? []).join(' ');
        final haystack = [
          provider['displayName'],
          category['name'],
          services,
          location['city'],
        ].whereType<Object>().join(' ').toLowerCase();
        return matchesCategory &&
            (needle.isEmpty || haystack.contains(needle));
      },
    ).toList();
    return {'items': items};
  }

  String _locationFingerprint(
    String? city,
    String? state,
    double? lat,
    double? lng,
  ) {
    if (lat != null && lng != null) {
      return 'gps:${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)}';
    }
    final cityPart = city?.trim().toLowerCase() ?? '';
    final statePart = state?.trim().toUpperCase() ?? '';
    if (cityPart.isEmpty && statePart.isEmpty) return 'none';
    return 'manual:$cityPart|$statePart';
  }

  Future<void> _writeCache(
    String key,
    String fingerprint,
    Map<String, dynamic> payload,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        key,
        jsonEncode({
          'fingerprint': fingerprint,
          'savedAt': DateTime.now().toIso8601String(),
          'payload': payload,
        }),
      );
    } catch (_) {
      // Falha de cache não pode bloquear o catálogo online.
    }
  }

  Future<Map<String, dynamic>?> _readCache(
    String key,
    String fingerprint,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final envelope = decoded.cast<String, dynamic>();
      if (envelope['fingerprint']?.toString() != fingerprint) return null;
      final payload = envelope['payload'];
      return payload is Map ? payload.cast<String, dynamic>() : null;
    } catch (_) {
      return null;
    }
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
