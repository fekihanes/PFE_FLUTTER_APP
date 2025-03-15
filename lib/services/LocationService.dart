import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Gets the current position (latitude & longitude)
  static Future<Position> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions are permanently denied.');
        }
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }
}
