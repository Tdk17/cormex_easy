import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';

class SystemBootstrapService {
  SystemBootstrapService(this.environment, this.apiClient);

  final AppEnvironment environment;
  final ApiClient apiClient;

  bool maintenanceEnabled = false;
  bool allowPublicRead = false;
  String maintenanceType = 'scheduled';
  String maintenanceTitle = '';
  String maintenanceMessage = '';
  DateTime? estimatedReturnAt;
  Map<String, dynamic> featureFlags = const {};

  Future<void> initialize() async {
    if (environment.useQaData || !environment.hasApi) return;
    try {
      final result = await apiClient.runFunction('v1-system-bootstrap');
      final maintenance =
          (result['maintenance'] as Map?)?.cast<String, dynamic>() ?? {};
      maintenanceEnabled = maintenance['enabled'] == true;
      allowPublicRead = maintenance['allowPublicRead'] == true;
      maintenanceType =
          maintenance['type']?.toString() ?? 'scheduled';
      maintenanceTitle = maintenance['title']?.toString() ?? '';
      maintenanceMessage = maintenance['message']?.toString() ?? '';
      estimatedReturnAt =
          DateTime.tryParse(maintenance['estimatedReturnAt']?.toString() ?? '');
      featureFlags =
          (result['featureFlags'] as Map?)?.cast<String, dynamic>() ?? {};
    } catch (_) {
      // Uma falha de bootstrap não deve derrubar o catálogo público.
    }
  }
}
