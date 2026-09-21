import 'package:get_it/get_it.dart';

import '../../features/catalog/data/catalog_repository_impl.dart';
import '../../features/catalog/data/favorites_service.dart';
import '../../features/catalog/data/location_service.dart';
import '../../features/catalog/domain/catalog_repository.dart';
import '../../features/catalog/presentation/catalog_store.dart';
import '../config/app_environment.dart';
import '../network/api_client.dart';
import '../router/app_router.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<AppEnvironment>()) return;
  final environment = AppEnvironment.fromDefines();
  getIt
    ..registerSingleton<AppEnvironment>(environment)
    ..registerLazySingleton(() => ApiClient(environment))
    ..registerLazySingleton(FavoritesService.new)
    ..registerLazySingleton(LocationService.new)
    ..registerLazySingleton<CatalogRepository>(
      () => CatalogRepositoryImpl(environment, getIt<ApiClient>()),
    )
    ..registerLazySingleton(
      () => CatalogStore(
        getIt<CatalogRepository>(),
        getIt<FavoritesService>(),
        getIt<LocationService>(),
      ),
    )
    ..registerLazySingleton(AppRouter.new);

  await getIt<CatalogStore>().initialize();
}

