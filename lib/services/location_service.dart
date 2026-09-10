import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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
    try {
      final gpsLocation = await _getGpsLocation();

      print('========== GPS LOCATION ==========');
      print('Latitude: ${gpsLocation.latitude}');
      print('Longitude: ${gpsLocation.longitude}');
      print('Accuracy: ${gpsLocation.accuracy} meters');
      print('==================================');

      // Android Emulator commonly returns Google's
      // default Mountain View test coordinate.
      if (_looksLikeDefaultEmulatorLocation(
        gpsLocation.latitude,
        gpsLocation.longitude,
      )) {
        print(
          'Default emulator location detected. '
              'Trying IP location...',
        );

        return await _getIpLocation();
      }

      return gpsLocation;
    } catch (e) {
      print('GPS LOCATION ERROR: $e');
      print('Trying IP location...');

      return await _getIpLocation();
    }
  }

  Future<AppLocation> _getGpsLocation() async {
    final serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location service is disabled.',
      );
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
      await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Location permission was denied.',
      );
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        'Location permission was permanently denied.',
      );
    }

    final position =
    await Geolocator.getCurrentPosition(
      locationSettings:
      const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return AppLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      source: 'GPS',
    );
  }

  Future<AppLocation> _getIpLocation() async {
    final uri = Uri.parse(
      'https://ipwho.is/',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'IP location request failed: '
            '${response.statusCode}',
      );
    }

    final data =
    jsonDecode(response.body)
    as Map<String, dynamic>;

    if (data['success'] == false) {
      throw Exception(
        data['message']?.toString() ??
            'Unable to determine IP location.',
      );
    }

    final latitude =
    (data['latitude'] as num?)
        ?.toDouble();

    final longitude =
    (data['longitude'] as num?)
        ?.toDouble();

    if (latitude == null ||
        longitude == null) {
      throw Exception(
        'IP location did not return coordinates.',
      );
    }

    print('========== IP LOCATION ==========');
    print('Latitude: $latitude');
    print('Longitude: $longitude');
    print('City: ${data['city']}');
    print('Region: ${data['region']}');
    print('Country: ${data['country']}');
    print('=================================');

    return AppLocation(
      latitude: latitude,
      longitude: longitude,

      // IP location is approximate.
      // Do not pretend it is GPS accuracy.
      accuracy: 5000,
      source: 'IP',
    );
  }

  bool _looksLikeDefaultEmulatorLocation(
      double latitude,
      double longitude,
      ) {
    const defaultLatitude = 37.4219983;
    const defaultLongitude = -122.084;

    const tolerance = 0.01;

    final latitudeMatch =
        (latitude - defaultLatitude).abs() <
            tolerance;

    final longitudeMatch =
        (longitude - defaultLongitude).abs() <
            tolerance;

    return latitudeMatch &&
        longitudeMatch &&
        !kIsWeb;
  }
}