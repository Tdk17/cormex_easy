import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection.dart';
import 'core/platform/network_status_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/catalog/presentation/catalog_store.dart';

class CormexEasyApp extends StatefulWidget {
  const CormexEasyApp({super.key});

  @override
  State<CormexEasyApp> createState() => _CormexEasyAppState();
}

class _CormexEasyAppState extends State<CormexEasyApp>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _onlineSubscription;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _onlineSubscription =
        NetworkStatusService.onlineChanges.listen((_) => _refreshLocation());
    _locationTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _refreshLocation(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshLocation();
  }

  void _refreshLocation() {
    final store = getIt<CatalogStore>();
    if (!store.autoLocationEnabled.value ||
        !NetworkStatusService.isOnline) {
      return;
    }
    unawaited(store.refreshCurrentLocation());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _onlineSubscription?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = getIt<AppRouter>().router;
    return MaterialApp.router(
      title: 'CormeX Easy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
