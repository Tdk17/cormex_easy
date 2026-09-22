import 'dart:async';

bool canInstall() => false;

bool isInstalled() => false;

bool isIos() => false;

Stream<void> get stateChanges => const Stream<void>.empty();

Future<String> install() async => 'unavailable';
