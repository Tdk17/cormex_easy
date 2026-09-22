import '../../../core/network/api_client.dart';

class ProviderServicesRepository {
  ProviderServicesRepository(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list(String providerPublicId) async {
    final result = await _api.runFunction(
      'v1-provider-services-list',
      params: {'providerPublicId': providerPublicId},
    );
    return (result['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> create({
    required String providerPublicId,
    required String categoryPublicId,
    required String name,
    required String description,
    required String priceLabel,
  }) async {
    final result = await _api.runFunction(
      'v1-provider-services-create',
      params: {
        'providerPublicId': providerPublicId,
        'categoryPublicId': categoryPublicId,
        'name': name,
        'description': description,
        'priceLabel': priceLabel,
      },
    );
    return (result['service'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> update({
    required String providerPublicId,
    required String servicePublicId,
    required String categoryPublicId,
    required String name,
    required String description,
    required String priceLabel,
  }) async {
    final result = await _api.runFunction(
      'v1-provider-services-update',
      params: {
        'providerPublicId': providerPublicId,
        'servicePublicId': servicePublicId,
        'categoryPublicId': categoryPublicId,
        'name': name,
        'description': description,
        'priceLabel': priceLabel,
      },
    );
    return (result['service'] as Map).cast<String, dynamic>();
  }

  Future<void> delete({
    required String providerPublicId,
    required String servicePublicId,
  }) async {
    await _api.runFunction(
      'v1-provider-services-delete',
      params: {
        'providerPublicId': providerPublicId,
        'servicePublicId': servicePublicId,
      },
    );
  }
}
