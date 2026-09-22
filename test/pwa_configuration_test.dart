import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manifesto possui os requisitos de instalação do CormeX Easy', () {
    final manifest = jsonDecode(
      File('web/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    expect(manifest['name'], 'CormeX Easy');
    expect(manifest['short_name'], 'CormeX');
    expect(manifest['id'], './');
    expect(manifest['start_url'], './');
    expect(manifest['scope'], './');
    expect(manifest['display'], 'standalone');
    expect(manifest['theme_color'], '#7A1830');
    expect(manifest['lang'], 'pt-BR');

    final icons = (manifest['icons'] as List).cast<Map<String, dynamic>>();
    expect(
      icons.any((icon) =>
          icon['sizes'] == '192x192' && icon['purpose'] == 'any'),
      isTrue,
    );
    expect(
      icons.any((icon) =>
          icon['sizes'] == '512x512' && icon['purpose'] == 'any'),
      isTrue,
    );
    expect(
      icons.any((icon) => icon['purpose'] == 'maskable'),
      isTrue,
    );
    final shortcuts =
        (manifest['shortcuts'] as List).cast<Map<String, dynamic>>();
    expect(shortcuts.length, greaterThanOrEqualTo(2));
    expect(
      shortcuts.any((shortcut) => shortcut['url'] == './#/explorar'),
      isFalse,
    );
  });

  test('HTML prepara instalação no Android e no iPhone', () {
    final html = File('web/index.html').readAsStringSync();

    expect(html, contains('rel="manifest"'));
    expect(html, contains('rel="apple-touch-icon"'));
    expect(html, contains('mobile-web-app-capable'));
    expect(html, contains('apple-mobile-web-app-capable'));
    expect(html, contains('pwa_install.js'));
    expect(
      html.indexOf('pwa_install.js'),
      lessThan(html.indexOf('flutter_bootstrap.js')),
    );
  });

  test('PWA prioriza a rede e mantém uma cópia para uso offline', () {
    final installer = File('web/pwa_install.js').readAsStringSync();
    final worker =
        File('web/cormex_service_worker.js').readAsStringSync();
    final bootstrap =
        File('web/flutter_bootstrap.js').readAsStringSync();

    expect(installer, contains('beforeinstallprompt'));
    expect(installer, contains('appinstalled'));
    expect(installer, contains('cormex_service_worker.js?v=3'));
    expect(installer, contains('controllerchange'));
    expect(worker, contains("self.addEventListener('install'"));
    expect(worker, contains("self.addEventListener('activate'"));
    expect(worker, contains("self.addEventListener('fetch'"));
    expect(worker, contains('event.respondWith'));
    expect(worker, contains('ignoreSearch: true'));
    expect(worker, contains('caches.delete'));
    expect(worker, contains("cache: 'reload'"));
    expect(bootstrap, contains('{{flutter_js}}'));
    expect(bootstrap, contains('{{flutter_build_config}}'));
    expect(bootstrap, contains('_flutter.loader.load()'));
  });
}
