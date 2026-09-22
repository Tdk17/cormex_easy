import 'dart:async';

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
  final city = signal('');
  final state = signal('');
  final latitude = signal<double?>(null);
  final longitude = signal<double?>(null);
  final usingCurrentLocation = signal(false);
  final autoLocationEnabled = signal(false);
  final locationMessage = signal(
    'Localização não definida. Use o GPS ou informe sua cidade.',
  );
  final errorMessage = signal<String?>(null);

  bool _refreshingLocation = false;

  bool get hasLocation =>
      usingCurrentLocation.value || city.value.trim().isNotEmpty;

  String get locationLabel {
    final cityName = city.value.trim();
    final stateCode = state.value.trim();
    if (cityName.isNotEmpty) {
      return stateCode.isEmpty ? cityName : '$cityName, $stateCode';
    }
    return usingCurrentLocation.value
        ? 'Localização ativa'
        : 'Usar minha localização';
  }

  String get resultsLocationLabel {
    if (!hasLocation) return 'em todo o catálogo';
    return usingCurrentLocation.value
        ? 'perto de $locationLabel'
        : 'em $locationLabel';
  }

  bool get hasActiveFilters =>
      query.value.trim().isNotEmpty || selectedCategory.value != null;

  Future<void> initialize() async {
    final savedLocation = await _locationService.loadSavedLocation();
    if (savedLocation != null) _restoreLocation(savedLocation);
    favoriteIds.value = await _favorites.load();
    await loadHome();
    if (autoLocationEnabled.value) {
      unawaited(refreshCurrentLocation());
    }
  }

  void _restoreLocation(SavedLocation saved) {
    city.value = saved.city.trim();
    state.value = saved.state.trim().toUpperCase();
    latitude.value = saved.latitude;
    longitude.value = saved.longitude;
    usingCurrentLocation.value = saved.hasCoordinates;
    autoLocationEnabled.value = saved.autoRefresh;
    locationMessage.value = city.value.isEmpty
        ? 'Última localização salva no aparelho.'
        : 'Última localização salva: $locationLabel';
  }

  Future<void> loadHome({bool refresh = false}) async {
    phase.value = refresh ? LoadPhase.refreshing : LoadPhase.loading;
    errorMessage.value = null;
    try {
      final data = await _repository.loadHome(
        city: !usingCurrentLocation.value && city.value.trim().isNotEmpty
            ? city.value
            : null,
        state: !usingCurrentLocation.value && state.value.trim().isNotEmpty
            ? state.value
            : null,
        lat: usingCurrentLocation.value ? latitude.value : null,
        lng: usingCurrentLocation.value ? longitude.value : null,
      );
      home.value = data;
      if (data.isFromCache) {
        locationMessage.value = hasLocation
            ? 'Sem conexão: mostrando resultados salvos de $locationLabel.'
            : 'Sem conexão: mostrando os últimos resultados salvos.';
      }

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
      city: !usingCurrentLocation.value && city.value.trim().isNotEmpty
          ? city.value
          : null,
      state: !usingCurrentLocation.value && state.value.trim().isNotEmpty
          ? state.value
          : null,
      lat: usingCurrentLocation.value ? latitude.value : null,
      lng: usingCurrentLocation.value ? longitude.value : null,
    );
  }

  Future<void> useCurrentLocation() {
    return _updateCurrentLocation(
      requestPermission: true,
      enableAutoRefresh: true,
      silent: false,
    );
  }

  Future<void> refreshCurrentLocation() {
    return _updateCurrentLocation(
      requestPermission: false,
      enableAutoRefresh: false,
      silent: true,
    );
  }

  Future<void> _updateCurrentLocation({
    required bool requestPermission,
    required bool enableAutoRefresh,
    required bool silent,
  }) async {
    if (_refreshingLocation) return;
    _refreshingLocation = true;
    if (!silent) locationMessage.value = 'Buscando sua localização…';
    try {
      final result = await _locationService.requestCurrentPosition(
        requestPermission: requestPermission,
      );
      switch (result.type) {
        case LocationResultType.success:
          await _applyCurrentLocation(
            result,
            enableAutoRefresh: enableAutoRefresh,
            silent: silent,
          );
          return;
        case LocationResultType.denied:
        case LocationResultType.deniedForever:
          if (!silent) {
            locationMessage.value =
                'Localização não autorizada. Informe uma cidade.';
          }
          return;
        case LocationResultType.disabled:
          if (!silent) {
            locationMessage.value =
                'Ative a localização ou informe uma cidade.';
          }
          return;
        case LocationResultType.error:
          if (!silent) {
            locationMessage.value =
                'Não encontramos sua localização. Informe uma cidade.';
          }
          return;
      }
    } finally {
      _refreshingLocation = false;
    }
  }

  Future<void> _applyCurrentLocation(
    LocationResult result, {
    required bool enableAutoRefresh,
    required bool silent,
  }) async {
    if (result.latitude == null || result.longitude == null) {
      if (!silent) {
        locationMessage.value =
            'Não encontramos sua localização. Informe uma cidade.';
      }
      return;
    }

    final resolvedCity = result.city?.trim() ?? '';
    if (resolvedCity.isEmpty && hasLocation) {
      if (!silent) {
        locationMessage.value =
            'Sem internet: mantendo a última localização salva, '
            '$locationLabel.';
      }
      return;
    }

    latitude.value = result.latitude;
    longitude.value = result.longitude;
    city.value = resolvedCity;
    state.value = result.state?.trim().toUpperCase() ?? '';
    usingCurrentLocation.value = true;
    if (enableAutoRefresh) autoLocationEnabled.value = true;

    await _locationService.saveLocation(
      SavedLocation(
        city: city.value,
        state: state.value,
        latitude: latitude.value,
        longitude: longitude.value,
        updatedAt: DateTime.now(),
        autoRefresh: autoLocationEnabled.value,
      ),
    );

    locationMessage.value = city.value.isEmpty
        ? 'GPS ativo. A cidade será atualizada quando a internet voltar.'
        : 'Localização atualizada automaticamente: $locationLabel';
    await loadHome(refresh: true);
  }

  Future<void> setCity(String value) async {
    if (value.trim().isEmpty) return;
    final parts = value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    city.value = parts.first;
    state.value = parts.length > 1 ? parts.last.toUpperCase() : '';
    _clearCoordinates();
    autoLocationEnabled.value = false;
    await _locationService.saveLocation(
      SavedLocation(
        city: city.value,
        state: state.value,
        updatedAt: DateTime.now(),
        autoRefresh: false,
      ),
    );
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
          'eventId': 'favorite_add_' +
              providerId +
              '_' +
              DateTime.now().microsecondsSinceEpoch.toString(),
          'source': 'web',
        });
      } catch (_) {
        // Analytics não deve bloquear o favorito.
      }
    }
  }

  bool isFavorite(String providerId) => favoriteIds.value.contains(providerId);
}
