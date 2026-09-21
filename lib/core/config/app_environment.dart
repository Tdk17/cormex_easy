enum AppFlavor { qa, production }

class AppEnvironment {
  const AppEnvironment({
    required this.flavor,
    required this.apiBaseUrl,
    required this.useQaData,
  });

  factory AppEnvironment.fromDefines() {
    const rawFlavor = String.fromEnvironment('APP_ENV', defaultValue: 'qa');
    const baseUrl = String.fromEnvironment('API_BASE_URL');
    const requestedQaData = bool.fromEnvironment(
      'USE_QA_DATA',
      defaultValue: true,
    );
    final flavor = rawFlavor.toLowerCase() == 'production'
        ? AppFlavor.production
        : AppFlavor.qa;

    return AppEnvironment(
      flavor: flavor,
      apiBaseUrl: baseUrl.trim(),
      useQaData: flavor == AppFlavor.qa && requestedQaData,
    );
  }

  final AppFlavor flavor;
  final String apiBaseUrl;
  final bool useQaData;

  bool get isQa => flavor == AppFlavor.qa;
  bool get hasApi => apiBaseUrl.startsWith('https://');
  String get label => isQa ? 'QA' : 'Produção';
}

