import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const supabaseUrl = 'https://afggmxyqarbgqedzoxkh.supabase.co';
const supabaseKey =
    'sb_publishable_lmO5FpN7j9Jfz5oANPWRXg_3auGDfMR';

const batchSize = 200;
const pageSize = 1000;

Future<void> main() async {
  final googleApiKey = Platform.environment['GOOGLE_MAPS_API_KEY'];

  if (googleApiKey == null || googleApiKey.isEmpty) {
    print('ERROR: GOOGLE_MAPS_API_KEY not found.');
    print(r'$env:GOOGLE_MAPS_API_KEY="YOUR_KEY"');
    return;
  }

  print('======================================');
  print('SmartJimat Premise Geocoding');
  print('======================================');

  try {
    print('Fetching existing premise locations...');

    final existingCodes = await fetchExistingPremiseCodes();

    print('Already geocoded: ${existingCodes.length} premises.');

    print('Fetching premises from lookup_premise...');

    final allPremises = await fetchAllPremises();

    print('Found ${allPremises.length} premises with addresses.');

    final pendingPremises = allPremises.where((premise) {
      final premiseCode =
      int.tryParse(premise['premise_code'].toString());

      if (premiseCode == null) {
        return false;
      }

      return !existingCodes.contains(premiseCode);
    }).toList();

    print('Remaining premises: ${pendingPremises.length}');

    if (pendingPremises.isEmpty) {
      print('======================================');
      print('ALL PREMISES COMPLETED!');
      print('======================================');
      return;
    }

    final currentBatch = pendingPremises.take(batchSize).toList();

    print('This run will process: ${currentBatch.length}');

    int successCount = 0;
    int failedCount = 0;

    for (int i = 0; i < currentBatch.length; i++) {
      final premise = currentBatch[i];

      final premiseCode =
      int.tryParse(premise['premise_code'].toString());

      if (premiseCode == null) {
        print('Invalid premise_code. Skipping...');
        failedCount++;
        continue;
      }

      final premiseName =
          premise['premise']?.toString().trim() ?? '';

      final address =
          premise['address']?.toString().trim() ?? '';

      final state =
          premise['state']?.toString().trim() ?? '';

      final fullAddress = buildFullAddress(
        premiseName: premiseName,
        address: address,
        state: state,
      );

      print('--------------------------------------');
      print(
        '[${i + 1}/${currentBatch.length}] '
            'Premise code: $premiseCode',
      );
      print('Premise: $premiseName');
      print('Searching: $fullAddress');

      try {
        final coordinates = await geocodeAddress(
          fullAddress,
          googleApiKey,
        );

        if (coordinates == null) {
          print('FAILED: No coordinate found.');
          failedCount++;

          await Future.delayed(
            const Duration(milliseconds: 300),
          );

          continue;
        }

        final latitude = coordinates['lat']!;
        final longitude = coordinates['lng']!;

        print('Latitude: $latitude');
        print('Longitude: $longitude');

        await saveLocation(
          premiseCode: premiseCode,
          latitude: latitude,
          longitude: longitude,
        );

        print('SAVED to premise_location.');

        successCount++;
      } catch (e) {
        print('ERROR: $e');
        failedCount++;
      }

      await Future.delayed(
        const Duration(milliseconds: 300),
      );
    }

    print('======================================');
    print('BATCH FINISHED');
    print('======================================');
    print('Processed : ${currentBatch.length}');
    print('Success   : $successCount');
    print('Failed    : $failedCount');
    print('======================================');
  } catch (e) {
    print('FATAL ERROR: $e');
  }
}

Future<List<Map<String, dynamic>>> fetchAllPremises() async {
  final List<Map<String, dynamic>> allPremises = [];

  int offset = 0;

  while (true) {
    final uri = Uri.parse(
      '$supabaseUrl/rest/v1/lookup_premise'
          '?select=premise_code,premise,address,state'
          '&address=not.is.null'
          '&order=premise_code.asc'
          '&limit=$pageSize'
          '&offset=$offset',
    );

    final response = await http.get(
      uri,
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch premises. '
            'Status: ${response.statusCode} '
            'Body: ${response.body}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    final page = data
        .map(
          (row) => Map<String, dynamic>.from(row),
    )
        .where((row) {
      final address =
          row['address']?.toString().trim() ?? '';

      return address.isNotEmpty;
    })
        .toList();

    allPremises.addAll(page);

    print('Fetched ${allPremises.length} premises...');

    if (data.length < pageSize) {
      break;
    }

    offset += pageSize;
  }

  return allPremises;
}

Future<Set<int>> fetchExistingPremiseCodes() async {
  final Set<int> existingCodes = {};

  int offset = 0;

  while (true) {
    final uri = Uri.parse(
      '$supabaseUrl/rest/v1/premise_location'
          '?select=premise_code'
          '&order=premise_code.asc'
          '&limit=$pageSize'
          '&offset=$offset',
    );

    final response = await http.get(
      uri,
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch premise_location. '
            'Status: ${response.statusCode} '
            'Body: ${response.body}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    for (final row in data) {
      final premiseCode =
      int.tryParse(row['premise_code'].toString());

      if (premiseCode != null) {
        existingCodes.add(premiseCode);
      }
    }

    if (data.length < pageSize) {
      break;
    }

    offset += pageSize;
  }

  return existingCodes;
}

String buildFullAddress({
  required String premiseName,
  required String address,
  required String state,
}) {
  final parts = <String>[];

  if (premiseName.isNotEmpty) {
    parts.add(premiseName);
  }

  if (address.isNotEmpty) {
    parts.add(address);
  }

  if (state.isNotEmpty &&
      !address.toLowerCase().contains(state.toLowerCase())) {
    parts.add(state);
  }

  parts.add('Malaysia');

  return parts.join(', ');
}

Future<Map<String, double>?> geocodeAddress(
    String address,
    String apiKey,
    ) async {
  final uri = Uri.https(
    'maps.googleapis.com',
    '/maps/api/geocode/json',
    {
      'address': address,
      'key': apiKey,
      'region': 'my',
    },
  );

  final response = await http.get(uri);

  if (response.statusCode != 200) {
    throw Exception(
      'Google request failed. '
          'Status: ${response.statusCode}',
    );
  }

  final data = jsonDecode(response.body);

  final status = data['status']?.toString();

  if (status != 'OK') {
    print('Google status: $status');

    if (data['error_message'] != null) {
      print(
        'Google message: ${data['error_message']}',
      );
    }

    return null;
  }

  final results = data['results'] as List<dynamic>?;

  if (results == null || results.isEmpty) {
    return null;
  }

  final firstResult =
  Map<String, dynamic>.from(results.first);

  final formattedAddress =
  firstResult['formatted_address']?.toString();

  if (formattedAddress != null) {
    print('Google matched: $formattedAddress');
  }

  final geometry =
  Map<String, dynamic>.from(firstResult['geometry']);

  final location =
  Map<String, dynamic>.from(geometry['location']);

  final lat = (location['lat'] as num).toDouble();
  final lng = (location['lng'] as num).toDouble();

  return {
    'lat': lat,
    'lng': lng,
  };
}

Future<void> saveLocation({
  required int premiseCode,
  required double latitude,
  required double longitude,
}) async {
  final uri = Uri.parse(
    '$supabaseUrl/rest/v1/premise_location'
        '?on_conflict=premise_code',
  );

  final response = await http.post(
    uri,
    headers: {
      'apikey': supabaseKey,
      'Authorization': 'Bearer $supabaseKey',
      'Content-Type': 'application/json',
      'Prefer': 'resolution=merge-duplicates',
    },
    body: jsonEncode({
      'premise_code': premiseCode,
      'latitude': latitude,
      'longitude': longitude,
    }),
  );

  if (response.statusCode != 201 &&
      response.statusCode != 200) {
    throw Exception(
      'Failed to save location. '
          'Status: ${response.statusCode} '
          'Body: ${response.body}',
    );
  }
}