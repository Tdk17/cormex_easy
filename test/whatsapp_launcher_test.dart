import 'package:cormex_easy/core/platform/whatsapp_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normaliza o telefone e cria o link do WhatsApp Web', () {
    final uri = desktopWhatsAppUri(
      phone: '+55 (47) 99999-9999',
      message: 'Olá pelo CormeX Easy',
    );

    expect(normalizeWhatsAppPhone('+55 (47) 99999-9999'), '5547999999999');
    expect(uri.host, 'web.whatsapp.com');
    expect(uri.path, '/send');
    expect(uri.queryParameters['phone'], '5547999999999');
    expect(uri.queryParameters['text'], 'Olá pelo CormeX Easy');
  });

  test('cria links compatíveis com celular e aplicativo nativo', () {
    final mobile = mobileWhatsAppUri(phone: '5547999999999', message: 'Oi');
    final native = nativeWhatsAppUri(phone: '5547999999999', message: 'Oi');

    expect(mobile.host, 'wa.me');
    expect(mobile.path, '/5547999999999');
    expect(native.scheme, 'whatsapp');
    expect(native.host, 'send');
    expect(native.queryParameters['phone'], '5547999999999');
  });
}
