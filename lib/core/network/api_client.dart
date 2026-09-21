import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_environment.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this.environment, {http.Client? client})
      : _client = client ?? http.Client();

  final AppEnvironment environment;
  final http.Client _client;
  static const _timeout = Duration(seconds: 18);

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _send('GET', path, query: query);
    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _send('POST', path, body: body);
    return _decode(response);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    if (!environment.hasApi) {
      throw const ApiException(
        ApiFailureType.unavailable,
        'A API ainda não foi configurada para este ambiente.',
      );
    }
    final base = Uri.parse(environment.apiBaseUrl);
    final uri = base.replace(
      path: '${base.path.replaceAll(RegExp(r'/$'), '')}/$path'
          .replaceAll(RegExp(r'//+'), '/'),
      queryParameters: query,
    );

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      final response = method == 'POST'
          ? await _client
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_timeout)
          : await _client.get(uri, headers: headers).timeout(_timeout);
      _validate(response);
      return response;
    } on TimeoutException {
      throw const ApiException(
        ApiFailureType.timeout,
        'A resposta demorou mais do que o esperado.',
      );
    } on http.ClientException {
      throw const ApiException(
        ApiFailureType.offline,
        'Não foi possível conectar à internet.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException(
      ApiFailureType.unknown,
      'A API retornou um formato inesperado.',
    );
  }

  void _validate(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final type = switch (response.statusCode) {
      400 => ApiFailureType.badRequest,
      401 => ApiFailureType.unauthorized,
      403 => ApiFailureType.forbidden,
      404 => ApiFailureType.notFound,
      408 => ApiFailureType.timeout,
      429 => ApiFailureType.rateLimited,
      500 => ApiFailureType.server,
      502 || 503 => ApiFailureType.unavailable,
      _ => ApiFailureType.unknown,
    };
    throw ApiException(
      type,
      'Não foi possível concluir a operação.',
      statusCode: response.statusCode,
    );
  }
}

