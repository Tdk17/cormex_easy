import 'package:signals/signals.dart';

import '../data/favorites_service.dart';
import '../data/location_service.dart';
import '../domain/catalog_models.dart';
import '../domain/catalog_repository.dart';

enum LoadPhase { initial, loading, success, empty, error, refreshing }

class CatalogStore {
  CatalogStore(this._repository, this._favorites, this._locationService);

  final CatalogRepository _repository;
  final FavoritesService _favorites;
  final LocationService _locationService;

  final phase = signal(LoadPhase.initial);
  final home = signal<CatalogHomeData?>(null);
  final visibleProviders = signal<List<ProviderProfile>>([]);
  final favoriteIds = signal<Set<String>>(<String>{});
  final query = signal('');
  final selectedCategory = signal<String?>(null);
  final city = signal('Blumenau');
  final state = signal('SC');

  String get locationLabel => '${city.value}, ${state.value}';
  final locationMessage = signal('Informe sua região ou use sua localização');
  final errorMessage = signal<String?>(null);

  Future<void> initialize() async {
    favoriteIds.value = await _favorites.load();
    await loadHome();
  }

  Future<void> loadHome({bool refresh = false}) async {
    phase.value = refresh ? LoadPhase.refreshing : LoadPhase.loading;
    errorMessage.value = null;
    try {
      final data = await _repository.loadHome(
        city: city.value,
        state: state.value,
      );
      home.value = data;
      visibleProviders.value = data.providers;
      phase.value = data.providers.isEmpty ? LoadPhase.empty : LoadPhase.success;
    } catch (_) {
      phase.value = LoadPhase.error;
      errorMessage.value = 'Não foi possível carregar os serviços agora.';
    }
  }

  Future<void> search({String? value, String? categorySlug}) async {
    if (value != null) query.value = value;
    if (categorySlug != null) selectedCategory.value = categorySlug;
    phase.value = LoadPhase.loading;
    try {
      final items = await _repository.searchProviders(
        query: query.value,
        categorySlug: selectedCategory.value,
        city: city.value,
        state: state.value,
      );
      visibleProviders.value = items;
      phase.value = items.isEmpty ? LoadPhase.empty : LoadPhase.success;
    } catch (_) {
      phase.value = LoadPhase.error;
      errorMessage.value = 'Não foi possível realizar a busca.';
    }
  }

  Future<void> useCurrentLocation() async {
    locationMessage.value = 'Buscando sua localização…';
    final result = await _locationService.requestCurrentPosition();
    switch (result.type) {
      case LocationResultType.success:
        locationMessage.value = 'Localização atual ativada';
        phase.value = LoadPhase.loading;
        try {
          final data = await _repository.loadHome(
            lat: result.latitude,
            lng: result.longitude,
          );
          home.value = data;
          visibleProviders.value = data.providers;
          phase.value = data.providers.isEmpty
              ? LoadPhase.empty
              : LoadPhase.success;
        } catch (_) {
          phase.value = LoadPhase.error;
        }
      case LocationResultType.denied:
      case LocationResultType.deniedForever:
        locationMessage.value = 'Localização não autorizada. Escolha uma cidade.';
      case LocationResultType.disabled:
        locationMessage.value = 'Ative a localização ou escolha uma cidade.';
      case LocationResultType.error:
        locationMessage.value = 'Não encontramos sua localização. Escolha uma cidade.';
    }
  }

  Future<void> setCity(String value) async {
    if (value.trim().isEmpty) return;
    final parts = value.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    city.value = parts.first;
    if (parts.length > 1) state.value = parts.last.toUpperCase();
    locationMessage.value = 'Resultados para $locationLabel';
    await loadHome(refresh: true);
  }

  Future<void> toggleFavorite(String providerId) async {
    final next = Set<String>.from(favoriteIds.value);
    next.contains(providerId) ? next.remove(providerId) : next.add(providerId);
    favoriteIds.value = next;
    await _favorites.save(next);
  }

  bool isFavorite(String providerId) => favoriteIds.value.contains(providerId);
}

