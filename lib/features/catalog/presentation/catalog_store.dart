import 'package:signals/signals.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../data/favorites_service.dart';
import '../data/location_service.dart';
import '../domain/catalog_models.dart';
import '../domain/catalog_repository.dart';

enum LoadPhase { initial, loading, success, empty, error, refreshing }

class CatalogStore {
  CatalogStore(
    this._repository,
    this._favorites,
    this._locationService,
    this._environment,
    this._apiClient,
  );

  final CatalogRepository _repository;
  final FavoritesService _favorites;
  final LocationService _locationService;
  final AppEnvironment _environment;
  final ApiClient _apiClient;

  final phase = signal(LoadPhase.initial);
  final home = signal<CatalogHomeData?>(null);
  final visibleProviders = signal<List<ProviderProfile>>([]);
  final favoriteIds = signal<Set<String>>(<String>{});
  final query = signal('');
  final selectedCategory = signal<String?>(null);
  final city = signal('Blumenau');
  final state = signal('SC');
  final latitude = signal<double?>(null);
  final longitude = signal<double?>(null);
  final usingCurrentLocation = signal(false);
  final locationMessage = signal('Informe sua região ou use sua localização');
  final errorMessage = signal<String?>(null);

  String get locationLabel =>
      usingCurrentLocation.value ? 'Localização atual' : '${city.value}, ${state.value}';

  String get resultsLocationLabel => usingCurrentLocation.value
      ? 'perto da sua localização atual'
      : 'em ${city.value}, ${state.value}';

  bool get hasActiveFilters =>
      query.value.trim().isNotEmpty || selectedCategory.value != null;

  Future<void> initialize() async {
    favoriteIds.value = await _favorites.load();
    await loadHome();
  }

  Future<void> loadHome({bool refresh = false}) async {
    phase.value = refresh ? LoadPhase.refreshing : LoadPhase.loading;
    errorMessage.value = null;
    try {
      final data = await _repository.loadHome(
        city: usingCurrentLocation.value ? null : city.value,
        state: usingCurrentLocation.value ? null : state.value,
        lat: usingCurrentLocation.value ? latitude.value : null,
        lng: usingCurrentLocation.value ? longitude.value : null,
      );
      home.value = data;

      if (hasActiveFilters) {
        final items = await _fetchFilteredProviders();
        visibleProviders.value = items;
        phase.value = items.isEmpty ? LoadPhase.empty : LoadPhase.success;
      } else {
        visibleProviders.value = data.providers;
        phase.value =
            data.providers.isEmpty ? LoadPhase.empty : LoadPhase.success;
      }
    } catch (_) {
      phase.value = LoadPhase.error;
      errorMessage.value = 'Não foi possível carregar os serviços agora.';
    }
  }

  Future<void> search({
    String? value,
    String? categorySlug,
    bool replaceCategory = false,
  }) async {
    if (value != null) query.value = value.trim();
    if (replaceCategory || categorySlug != null) {
      selectedCategory.value = categorySlug;
    }
    phase.value = LoadPhase.loading;
    errorMessage.value = null;
    try {
      final items = await _fetchFilteredProviders();
      visibleProviders.value = items;
      phase.value = items.isEmpty ? LoadPhase.empty : LoadPhase.success;
    } catch (_) {
      phase.value = LoadPhase.error;
      errorMessage.value = 'Não foi possível realizar a busca.';
    }
  }

  Future<void> clearFilters() {
    return search(
      value: '',
      categorySlug: null,
      replaceCategory: true,
    );
  }

  Future<List<ProviderProfile>> _fetchFilteredProviders() {
    return _repository.searchProviders(
      query: query.value,
      categorySlug: selectedCategory.value,
      city: usingCurrentLocation.value ? null : city.value,
      state: usingCurrentLocation.value ? null : state.value,
      lat: usingCurrentLocation.value ? latitude.value : null,
      lng: usingCurrentLocation.value ? longitude.value : null,
    );
  }

  Future<void> useCurrentLocation() async {
    locationMessage.value = 'Buscando sua localização…';
    final result = await _locationService.requestCurrentPosition();
    switch (result.type) {
      case LocationResultType.success:
        if (result.latitude == null || result.longitude == null) {
          _clearCoordinates();
          locationMessage.value =
              'Não encontramos sua localização. Escolha uma cidade.';
          return;
        }
        latitude.value = result.latitude;
        longitude.value = result.longitude;
        usingCurrentLocation.value = true;
        locationMessage.value = 'Localização atual ativada';
        await loadHome(refresh: true);
      case LocationResultType.denied:
      case LocationResultType.deniedForever:
        _clearCoordinates();
        locationMessage.value =
            'Localização não autorizada. Escolha uma cidade.';
      case LocationResultType.disabled:
        _clearCoordinates();
        locationMessage.value =
            'Ative a localização ou escolha uma cidade.';
      case LocationResultType.error:
        _clearCoordinates();
        locationMessage.value =
            'Não encontramos sua localização. Escolha uma cidade.';
    }
  }

  Future<void> setCity(String value) async {
    if (value.trim().isEmpty) return;
    final parts = value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    city.value = parts.first;
    if (parts.length > 1) state.value = parts.last.toUpperCase();
    _clearCoordinates();
    locationMessage.value = 'Resultados para $locationLabel';
    await loadHome(refresh: true);
  }

  void _clearCoordinates() {
    latitude.value = null;
    longitude.value = null;
    usingCurrentLocation.value = false;
  }

  Future<void> toggleFavorite(String providerId) async {
    final next = Set<String>.from(favoriteIds.value);
    final adding = !next.contains(providerId);
    adding ? next.add(providerId) : next.remove(providerId);
    favoriteIds.value = next;
    await _favorites.save(next);
    if (adding && !_environment.useQaData && _environment.hasApi) {
      try {
        await _apiClient.runFunction('v1-providers-track-event', params: {
          'providerPublicId': providerId,
          'eventType': 'favorite_add',
          'eventId':
              'favorite_add_${providerId}_${DateTime.now().microsecondsSinceEpoch}',
          'source': 'web',
        });
      } catch (_) {
        // Analytics não deve bloquear o favorito.
      }
    }
  }

  bool isFavorite(String providerId) => favoriteIds.value.contains(providerId);
}
