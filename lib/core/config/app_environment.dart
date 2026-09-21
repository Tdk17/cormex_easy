enum AppFlavor { qa, production }

class AppEnvironment {
  const AppEnvironment({
    required this.flavor,
    required this.parseServerUrl,
    required this.parseApplicationId,
    required this.parseClientKey,
    required this.useQaData,
  });

  factory AppEnvironment.fromDefines() {
    const rawFlavor = String.fromEnvironment('APP_ENV', defaultValue: 'qa');
    const serverUrl = String.fromEnvironment(
      'PARSE_SERVER_URL',
      defaultValue: 'https://parseapi.back4app.com',
    );
    const applicationId = String.fromEnvironment('PARSE_APPLICATION_ID');
    const clientKey = String.fromEnvironment('PARSE_CLIENT_KEY');
    const requestedQaData = bool.fromEnvironment(
      'USE_QA_DATA',
      defaultValue: true,
    );
    final flavor = rawFlavor.toLowerCase() == 'production'
        ? AppFlavor.production
        : AppFlavor.qa;

    final hasParseConfiguration = serverUrl.startsWith('https://') &&
        applicationId.trim().isNotEmpty &&
        clientKey.trim().isNotEmpty;

    return AppEnvironment(
      flavor: flavor,
      parseServerUrl: serverUrl.trim(),
      parseApplicationId: applicationId.trim(),
      parseClientKey: clientKey.trim(),
      useQaData: flavor == AppFlavor.qa &&
          (requestedQaData || !hasParseConfiguration),
    );
  }

  final AppFlavor flavor;
  final String parseServerUrl;
  final String parseApplicationId;
  final String parseClientKey;
  final bool useQaData;

  bool get isQa => flavor == AppFlavor.qa;
  bool get hasApi => parseServerUrl.startsWith('https://') &&
      parseApplicationId.isNotEmpty &&
      parseClientKey.isNotEmpty;
  String get label => isQa ? 'QA' : 'Produção';
}
