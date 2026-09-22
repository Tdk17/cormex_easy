import 'dart:async';

import 'network_status_service_stub.dart'
    if (dart.library.js_interop) 'network_status_service_web.dart' as platform;

class NetworkStatusService {
  const NetworkStatusService._();

  static bool get isOnline => platform.isOnline();

  static Stream<void> get onlineChanges => platform.onlineChanges;
}
