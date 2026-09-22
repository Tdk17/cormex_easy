import 'dart:async';

import 'pwa_install_service_stub.dart'
    if (dart.library.js_interop) 'pwa_install_service_web.dart' as platform;

enum PwaInstallOutcome {
  accepted,
  dismissed,
  unavailable,
}

class PwaInstallService {
  PwaInstallService._();

  static final PwaInstallService instance = PwaInstallService._();

  bool get canInstall => platform.canInstall();

  bool get isInstalled => platform.isInstalled();

  bool get isIos => platform.isIos();

  bool get shouldShowInstall =>
      !isInstalled && (canInstall || isIos);

  Stream<void> get stateChanges => platform.stateChanges;

  Future<PwaInstallOutcome> install() async {
    final result = await platform.install();
    return switch (result) {
      'accepted' => PwaInstallOutcome.accepted,
      'dismissed' => PwaInstallOutcome.dismissed,
      _ => PwaInstallOutcome.unavailable,
    };
  }
}
