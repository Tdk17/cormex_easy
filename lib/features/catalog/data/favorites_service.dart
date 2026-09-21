import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';

class FavoritesService {
  FavoritesService(this.environment, this.apiClient);

  final AppEnvironment environment;
  final ApiClient apiClient;
  static const _key = 'cormex_easy.favorite_provider_ids';

  Future<Set<String>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final local = preferences.getStringList(_key)?.toSet() ?? <String>{};
    if (environment.useQaData || apiClient.sessionToken?.isNotEmpty != true) {
      return local;
    }
    try {
      final result = await apiClient.runFunction(
        'v1-favorites-list',
        params: {'limit': 50},
      );
      final remote = (result['items'] as List? ?? [])
          .whereType<Map>()
          .map((item) => item['providerPublicId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      for (final id in local.difference(remote)) {
        await apiClient.runFunction(
          'v1-favorites-add',
          params: {'providerPublicId': id},
        );
      }
      final merged = {...local, ...remote};
      await preferences.setStringList(_key, merged.toList());
      return merged;
    } catch (_) {
      return local;
    }
  }

  Future<void> save(Set<String> ids) async {
    final preferences = await SharedPreferences.getInstance();
    final previous = preferences.getStringList(_key)?.toSet() ?? <String>{};
    await preferences.setStringList(_key, ids.toList());
    if (environment.useQaData || apiClient.sessionToken?.isNotEmpty != true) {
      return;
    }
    try {
      for (final id in ids.difference(previous)) {
        await apiClient.runFunction(
          'v1-favorites-add',
          params: {'providerPublicId': id},
        );
      }
      for (final id in previous.difference(ids)) {
        await apiClient.runFunction(
          'v1-favorites-remove',
          params: {'providerPublicId': id},
        );
      }
    } catch (_) {
      // O estado local continua funcional e será conciliado no próximo acesso.
    }
  }
}
