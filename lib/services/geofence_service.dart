import 'package:geolocator/geolocator.dart';

class GeofenceService {
  static Future<bool> isWithinRadius({
    required double siteLat,
    required double siteLng,
    required double radiusInMeters,
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled. Please enable them.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied. Please enable it in settings.");
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final distance = Geolocator.distanceBetween(
      siteLat,
      siteLng,
      position.latitude,
      position.longitude,
    );

    return distance <= radiusInMeters;
  }
}
