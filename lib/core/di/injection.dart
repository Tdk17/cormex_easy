import 'dart:async';

import 'package:get_it/get_it.dart';

import '../../features/catalog/data/catalog_repository_impl.dart';
import '../../features/catalog/data/favorites_service.dart';
import '../../features/catalog/data/location_service.dart';
import '../../features/catalog/domain/catalog_repository.dart';
import '../../features/catalog/presentation/catalog_store.dart';
import '../../features/system/data/system_bootstrap_service.dart';
import '../config/app_environment.dart';
import '../network/api_client.dart';
import '../router/app_router.dart';

final getIt = GetIt.instance;

void registerDependencies() {
  if (getIt.isRegistered<AppEnvironment>()) return;
  final environment = AppEnvironment.fromDefines();
  getIt
    ..registerSingleton<AppEnvironment>(environment)
    ..registerLazySingleton(() => ApiClient(environment))
    ..registerLazySingleton(
      () => FavoritesService(environment, getIt<ApiClient>()),
    )
    ..registerLazySingleton(LocationService.new)
    ..registerLazySingleton<CatalogRepository>(
      () => CatalogRepositoryImpl(environment, getIt<ApiClient>()),
    )
    ..registerLazySingleton(
      () => CatalogStore(
        getIt<CatalogRepository>(),
        getIt<FavoritesService>(),
        getIt<LocationService>(),
        environment,
        getIt<ApiClient>(),
      ),
    )
    ..registerLazySingleton(
      () => SystemBootstrapService(environment, getIt<ApiClient>()),
    )
    ..registerLazySingleton(
      () => AppRouter(
        getIt<SystemBootstrapService>(),
        environment,
        getIt<ApiClient>(),
      ),
    );
}

Future<void> initializeDependencies() async {
  try {
    await getIt<ApiClient>().initialize().timeout(const Duration(seconds: 4));
  } catch (_) {
    // Uma preferência local indisponível não pode travar o aplicativo.
  }

  try {
    await getIt<CatalogStore>().initialize().timeout(
          const Duration(seconds: 4),
        );
  } catch (_) {
    // A Home possui tratamento próprio de erro e permanece navegável.
  }

  // Configuração remota e catálogo são atualizados sem bloquear a navegação.
  unawaited(getIt<SystemBootstrapService>().initialize());
}

Future<void> configureDependencies() async {
  registerDependencies();
  await initializeDependencies();
}
