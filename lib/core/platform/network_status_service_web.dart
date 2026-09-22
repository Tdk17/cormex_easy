import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

final StreamController<void> _onlineController =
    StreamController<void>.broadcast();
bool _listenerAttached = false;

bool isOnline() => web.window.navigator.onLine;

Stream<void> get onlineChanges {
  _attachListener();
  return _onlineController.stream;
}

void _attachListener() {
  if (_listenerAttached) return;
  _listenerAttached = true;
  web.window.addEventListener(
    'online',
    ((web.Event _) {
      _onlineController.add(null);
    }).toJS,
  );
}
