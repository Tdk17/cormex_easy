import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('cormexPwa.canInstall')
external JSBoolean _canInstall();

@JS('cormexPwa.isInstalled')
external JSBoolean _isInstalled();

@JS('cormexPwa.isIos')
external JSBoolean _isIos();

@JS('cormexPwa.install')
external JSPromise<JSString> _install();

final StreamController<void> _stateController =
    StreamController<void>.broadcast();
bool _listenerAttached = false;

bool canInstall() => _canInstall().toDart;

bool isInstalled() => _isInstalled().toDart;

bool isIos() => _isIos().toDart;

Stream<void> get stateChanges {
  _attachListener();
  return _stateController.stream;
}

Future<String> install() async {
  final result = await _install().toDart;
  return result.toDart;
}

void _attachListener() {
  if (_listenerAttached) return;
  _listenerAttached = true;
  web.window.addEventListener(
    'cormex-pwa-state-changed',
    ((web.Event _) {
      _stateController.add(null);
    }).toJS,
  );
}
