import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

enum LocationResultType { success, denied, deniedForever, disabled, error }

class LocationResult {
  const LocationResult(
    this.type, {
    this.latitude,
    this.longitude,
    this.city,
    this.state,
  });

  final LocationResultType type;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
}

class LocationService {
  LocationService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const _reverseGeocodeTimeout = Duration(seconds: 10);
  static const _brazilianStateCodes = <String, String>{
    'acre': 'AC',
    'alagoas': 'AL',
    'amapá': 'AP',
    'amazonas': 'AM',
    'bahia': 'BA',
    'ceará': 'CE',
    'distrito federal': 'DF',
    'espírito santo': 'ES',
    'goiás': 'GO',
    'maranhão': 'MA',
    'mato grosso': 'MT',
    'mato grosso do sul': 'MS',
    'minas gerais': 'MG',
    'pará': 'PA',
    'paraíba': 'PB',
    'paraná': 'PR',
    'pernambuco': 'PE',
    'piauí': 'PI',
    'rio de janeiro': 'RJ',
    'rio grande do norte': 'RN',
    'rio grande do sul': 'RS',
    'rondônia': 'RO',
    'roraima': 'RR',
    'santa catarina': 'SC',
    'são paulo': 'SP',
    'sergipe': 'SE',
    'tocantins': 'TO',
  };

  Future<LocationResult> requestCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(LocationResultType.disabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(LocationResultType.denied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationResultType.deniedForever);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final place = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );
      return LocationResult(
        LocationResultType.success,
        latitude: position.latitude,
        longitude: position.longitude,
        city: place?.city,
        state: place?.state,
      );
    } catch (_) {
      return const LocationResult(LocationResultType.error);
    }
  }

  Future<_ResolvedPlace?> _reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.https(
        'api.bigdatacloud.net',
        '/data/reverse-geocode-client',
        {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'localityLanguage': 'pt-BR',
        },
      );
      final response = await _httpClient
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_reverseGeocodeTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final city = _firstNonEmpty([
        decoded['city'],
        decoded['locality'],
      ]);
      final state = _stateCode(
        _firstNonEmpty([decoded['principalSubdivisionCode']]),
        _firstNonEmpty([decoded['principalSubdivision']]),
      );
      if (city.isEmpty && state.isEmpty) return null;
      return _ResolvedPlace(city: city, state: state);
    } catch (_) {
      return null;
    }
  }

  String _firstNonEmpty(Iterable<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _stateCode(String subdivisionCode, String subdivisionName) {
    final normalizedCode = subdivisionCode.trim().toUpperCase();
    if (normalizedCode.isNotEmpty) {
      final code = normalizedCode.split('-').last;
      if (code.length == 2) return code;
    }
    return _brazilianStateCodes[subdivisionName.trim().toLowerCase()] ?? '';
  }
}

class _ResolvedPlace {
  const _ResolvedPlace({required this.city, required this.state});

  final String city;
  final String state;
}
