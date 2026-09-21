import 'package:geolocator/geolocator.dart';

enum LocationResultType { success, denied, deniedForever, disabled, error }

class LocationResult {
  const LocationResult(this.type, {this.latitude, this.longitude});

  final LocationResultType type;
  final double? latitude;
  final double? longitude;
}

class LocationService {
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
      return LocationResult(
        LocationResultType.success,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return const LocationResult(LocationResultType.error);
    }
  }
}

