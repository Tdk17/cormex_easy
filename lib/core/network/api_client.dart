import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_environment.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this.environment, {http.Client? client})
      : _client = client ?? http.Client();

  final AppEnvironment environment;
  final http.Client _client;
  String? sessionToken;
  static const _timeout = Duration(seconds: 18);
  static const _sessionKey = 'cormex_easy.parse_session_token';

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    sessionToken = preferences.getString(_sessionKey);
  }

  Future<void> setSessionToken(String? value) async {
    sessionToken = value?.trim();
    final preferences = await SharedPreferences.getInstance();
    if (sessionToken == null || sessionToken!.isEmpty) {
      await preferences.remove(_sessionKey);
    } else {
      await preferences.setString(_sessionKey, sessionToken!);
    }
  }

  Future<Map<String, dynamic>> runFunction(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    if (!environment.hasApi) {
      throw const ApiException(
        ApiFailureType.unavailable,
        'A API ainda não foi configurada para este ambiente.',
      );
    }
    final base = Uri.parse(environment.parseServerUrl);
    final uri = base.replace(
      path: '${base.path.replaceAll(RegExp(r'/$'), '')}/functions/$functionName'
          .replaceAll(RegExp(r'//+'), '/'),
    );

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Parse-Application-Id': environment.parseApplicationId,
        'X-Parse-Client-Key': environment.parseClientKey,
        if (sessionToken != null && sessionToken!.isNotEmpty)
          'X-Parse-Session-Token': sessionToken!,
      };
      final response = await _client
          .post(uri, headers: headers, body: jsonEncode(params ?? {}))
          .timeout(_timeout);
      _validate(response);
      return _decodeFunction(response);
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

  Map<String, dynamic> _decodeFunction(http.Response response) {
    if (response.body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        ApiFailureType.unknown,
        'A API retornou um formato inesperado.',
      );
    }
    final result = decoded['result'];
    if (result is Map) {
      final envelope = result.cast<String, dynamic>();
      if (envelope['success'] == false) {
        final error = (envelope['error'] as Map?)?.cast<String, dynamic>() ?? {};
        throw ApiException(
          ApiFailureType.unknown,
          error['message']?.toString() ?? 'Não foi possível concluir a operação.',
        );
      }
      final data = envelope['data'];
      if (data is Map) return data.cast<String, dynamic>();
      return <String, dynamic>{'value': data};
    }
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
    var message = 'Não foi possível concluir a operação.';
    try {
      final body = jsonDecode(response.body);
      final rawError = body is Map ? body['error'] : null;
      if (rawError is String && rawError.startsWith('{')) {
        final parsed = jsonDecode(rawError);
        if (parsed is Map && parsed['error'] is Map) {
          message = (parsed['error'] as Map)['message']?.toString() ?? message;
        }
      } else if (rawError is String && rawError.isNotEmpty) {
        message = rawError;
      }
    } catch (_) {}
    throw ApiException(
      type,
      message,
      statusCode: response.statusCode,
    );
  }
}
