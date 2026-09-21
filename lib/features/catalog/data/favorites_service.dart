import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'cormex_easy.favorite_provider_ids';

  Future<Set<String>> load() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key)?.toSet() ?? <String>{};
  }

  Future<void> save(Set<String> ids) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_key, ids.toList());
  }
}

