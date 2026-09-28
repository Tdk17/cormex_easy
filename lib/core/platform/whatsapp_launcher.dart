import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

String normalizeWhatsAppPhone(String phone) {
  return phone.replaceAll(RegExp(r'\D'), '');
}

Uri desktopWhatsAppUri({
  required String phone,
  required String message,
}) {
  return Uri.https(
    'web.whatsapp.com',
    '/send',
    {'phone': normalizeWhatsAppPhone(phone), 'text': message},
  );
}

Uri mobileWhatsAppUri({
  required String phone,
  required String message,
}) {
  return Uri.https(
    'wa.me',
    '/${normalizeWhatsAppPhone(phone)}',
    {'text': message},
  );
}

Uri nativeWhatsAppUri({
  required String phone,
  required String message,
}) {
  return Uri(
    scheme: 'whatsapp',
    host: 'send',
    queryParameters: {
      'phone': normalizeWhatsAppPhone(phone),
      'text': message,
    },
  );
}

Future<bool> launchWhatsApp({
  required String phone,
  required String message,
}) async {
  if (normalizeWhatsAppPhone(phone).isEmpty) return false;

  if (kIsWeb) {
    final isMobileBrowser = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final uri = isMobileBrowser
        ? mobileWhatsAppUri(phone: phone, message: message)
        : desktopWhatsAppUri(phone: phone, message: message);
    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }

  try {
    final openedApp = await launchUrl(
      nativeWhatsAppUri(phone: phone, message: message),
      mode: LaunchMode.externalApplication,
    );
    if (openedApp) return true;
  } catch (_) {
    // Se o aplicativo não estiver instalado, o link HTTPS é o fallback.
  }

  return launchUrl(
    mobileWhatsAppUri(phone: phone, message: message),
    mode: LaunchMode.externalApplication,
  );
}
