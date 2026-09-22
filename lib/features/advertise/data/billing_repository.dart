import '../../../core/network/api_client.dart';

class BillingRepository {
  BillingRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> listPlans() =>
      _api.runFunction('v1-billing-plans-list');

  Future<Map<String, dynamic>> subscriptionMe() =>
      _api.runFunction('v1-billing-subscription-me');

  Future<Map<String, dynamic>> createSubscription(
    String planCode, {
    String preferredPaymentMode = 'card',
  }) =>
      _api.runFunction('v1-billing-subscription-create', params: {
        'planCode': planCode,
        'preferredPaymentMode': preferredPaymentMode,
      });

  Future<Map<String, dynamic>> sync() =>
      _api.runFunction('v1-billing-subscription-sync');

  Future<Map<String, dynamic>> pause() =>
      _api.runFunction('v1-billing-subscription-pause');

  Future<Map<String, dynamic>> resume() =>
      _api.runFunction('v1-billing-subscription-resume');

  Future<Map<String, dynamic>> cancel({String? reason}) =>
      _api.runFunction('v1-billing-subscription-cancel', params: {
        if (reason?.trim().isNotEmpty == true) 'reason': reason!.trim(),
      });

  Future<Map<String, dynamic>> changePlan(String newPlanCode) =>
      _api.runFunction('v1-billing-subscription-change-plan', params: {
        'newPlanCode': newPlanCode,
      });

  Future<Map<String, dynamic>> history({int limit = 20}) =>
      _api.runFunction('v1-billing-history', params: {
        'limit': limit,
      });
}
