import 'dart:async';

import 'package:geolocator/geolocator.dart';

class AppLocation {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String source;

  const AppLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.source,
  });
}

class LocationService {
  Future<AppLocation> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Turn on device location services and try again.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Allow precise location for SmartJimat in device Settings.');
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission is required to find nearby stores.');
    }

    // Use the device location, including an explicitly configured emulator
    // location. IP geolocation is too imprecise for nearby-store comparisons.
    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      throw Exception('Location timed out. Move to an open area and retry. On an emulator, set its location first.');
    }

    if (!position.latitude.isFinite || !position.longitude.isFinite ||
        position.latitude.abs() > 90 || position.longitude.abs() > 180) {
      throw Exception('The device returned an invalid location. Please retry.');
    }
    if (!position.accuracy.isFinite || position.accuracy < 0 ||
        position.accuracy > 200) {
      throw Exception('Location is too approximate. Enable precise location, move to an open area and retry.');
    }

    return AppLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      source: 'GPS',
    );
  }
}
