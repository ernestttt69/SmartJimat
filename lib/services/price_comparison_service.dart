import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import '../models/store_comparison.dart';

class PriceComparisonService {
  final SupabaseClient supabase =
      Supabase.instance.client;

  static const double nearbyRadiusKm = 15.0;
  static const double travelCostPerKm = 1.50;
  static const int maxRouteCandidates = 10;

  static const String googleMapsApiKey =
      'AIzaSyCw9eR0wNRnT78Pqk6l5IR6mB3MLfu468I';

  Future<List<StoreComparison>> compareStores(
      List<CartItem> cartItems, {
        double? userLatitude,
        double? userLongitude,
      }) async {
    if (cartItems.isEmpty) {
      return [];
    }

    final itemCodes = cartItems
        .map(
          (item) => item.product.itemCode,
    )
        .toSet()
        .toList();

    print('======================================');
    print('PRICE COMPARISON START');
    print('ITEM CODES: $itemCodes');
    print(
      'USER LOCATION: '
          '$userLatitude, $userLongitude',
    );
    print('======================================');

    final rpcResult = await supabase.rpc(
      'get_latest_prices',
      params: {
        'p_item_codes': itemCodes,
      },
    );

    final List<dynamic> priceRows =
    List<dynamic>.from(
      rpcResult as List,
    );

    final Set<int> itemsWithPrice = {};

    for (final row in priceRows) {
      final itemCode = int.tryParse(
        row['item_code'].toString(),
      );

      final price = double.tryParse(
        row['price'].toString(),
      );

      if (itemCode != null &&
          price != null) {
        itemsWithPrice.add(itemCode);
      }
    }

    if (itemsWithPrice.isEmpty) {
      return [];
    }

    final Map<int, CartItem> cartItemMap = {
      for (final cartItem in cartItems)
        cartItem.product.itemCode:
        cartItem,
    };

    final Map<int, Map<int, _LatestPrice>>
    pricesByStore = {};

    for (final row in priceRows) {
      final premiseCode = int.tryParse(
        row['premise_code'].toString(),
      );

      final itemCode = int.tryParse(
        row['item_code'].toString(),
      );

      final price = double.tryParse(
        row['price'].toString(),
      );

      final priceDate =
          row['price_date']?.toString() ?? '';

      if (premiseCode == null ||
          itemCode == null ||
          price == null) {
        continue;
      }

      pricesByStore.putIfAbsent(
        premiseCode,
            () => {},
      );

      pricesByStore[premiseCode]![itemCode] =
          _LatestPrice(
            price: price,
            date: priceDate,
          );
    }

    final List<int> completeStoreCodes = [];

    for (final entry
    in pricesByStore.entries) {
      final hasAllItems =
      itemsWithPrice.every(
            (itemCode) =>
            entry.value.containsKey(
              itemCode,
            ),
      );

      if (hasAllItems) {
        completeStoreCodes.add(
          entry.key,
        );
      }
    }

    if (completeStoreCodes.isEmpty) {
      return [];
    }

    final premiseRows = await supabase
        .from('lookup_premise')
        .select(
      'premise_code, '
          'premise, '
          'address, '
          'premise_type, '
          'state',
    )
        .inFilter(
      'premise_code',
      completeStoreCodes,
    );

    final Map<int, Map<String, dynamic>>
    premiseMap = {};

    for (final row in premiseRows) {
      final premiseCode = int.tryParse(
        row['premise_code'].toString(),
      );

      if (premiseCode != null) {
        premiseMap[premiseCode] =
        Map<String, dynamic>.from(
          row,
        );
      }
    }

    final locationRows = await supabase
        .from('premise_location')
        .select(
      'premise_code, '
          'latitude, '
          'longitude',
    )
        .inFilter(
      'premise_code',
      completeStoreCodes,
    );

    final Map<int, Map<String, dynamic>>
    locationMap = {};

    for (final row in locationRows) {
      final premiseCode = int.tryParse(
        row['premise_code'].toString(),
      );

      if (premiseCode != null) {
        locationMap[premiseCode] =
        Map<String, dynamic>.from(
          row,
        );
      }
    }

    final List<StoreComparison> stores = [];

    for (final premiseCode
    in completeStoreCodes) {
      final premise =
      premiseMap[premiseCode];

      final storePriceMap =
      pricesByStore[premiseCode];

      final location =
      locationMap[premiseCode];

      if (premise == null ||
          storePriceMap == null ||
          location == null) {
        continue;
      }

      final latitude = double.tryParse(
        location['latitude'].toString(),
      );

      final longitude = double.tryParse(
        location['longitude'].toString(),
      );

      if (latitude == null ||
          longitude == null) {
        continue;
      }

      final List<StoreProductPrice>
      storeProducts = [];

      bool complete = true;

      for (final itemCode
      in itemsWithPrice) {
        final latestPrice =
        storePriceMap[itemCode];

        final cartItem =
        cartItemMap[itemCode];

        if (latestPrice == null ||
            cartItem == null) {
          complete = false;
          break;
        }

        storeProducts.add(
          StoreProductPrice(
            cartItem: cartItem,
            unitPrice:
            latestPrice.price,
          ),
        );
      }

      if (!complete) {
        continue;
      }

      double? straightLineDistanceKm;

      if (userLatitude != null &&
          userLongitude != null) {
        final meters =
        Geolocator.distanceBetween(
          userLatitude,
          userLongitude,
          latitude,
          longitude,
        );

        straightLineDistanceKm =
            meters / 1000.0;
      }

      stores.add(
        StoreComparison(
          premiseCode:
          premiseCode,
          premiseName:
          premise['premise']
              ?.toString() ??
              '',
          address:
          premise['address']
              ?.toString() ??
              '',
          premiseType:
          premise['premise_type']
              ?.toString() ??
              '',
          state:
          premise['state']
              ?.toString() ??
              '',
          products:
          storeProducts,
          latitude:
          latitude,
          longitude:
          longitude,
          distanceKm:
          straightLineDistanceKm,
        ),
      );
    }

    if (stores.isEmpty) {
      return [];
    }

    if (userLatitude == null ||
        userLongitude == null) {
      stores.sort(
            (a, b) =>
            a.totalPrice.compareTo(
              b.totalPrice,
            ),
      );

      return stores.take(3).toList();
    }

    final straightLineCandidates =
    stores
        .where(
          (store) =>
      store.distanceKm != null,
    )
        .toList();

    straightLineCandidates.sort(
          (a, b) =>
          a.distanceKm!.compareTo(
            b.distanceKm!,
          ),
    );

    final routeCandidates =
    straightLineCandidates
        .take(maxRouteCandidates)
        .toList();

    print('======================================');
    print(
      'ROUTE API CANDIDATES: '
          '${routeCandidates.length}',
    );
    print('======================================');

    final List<StoreComparison>
    nearbyStores = [];

    for (final store
    in routeCandidates) {
      try {
        final drivingDistanceKm =
        await getDrivingDistanceKm(
          originLatitude:
          userLatitude,
          originLongitude:
          userLongitude,
          destinationLatitude:
          store.latitude!,
          destinationLongitude:
          store.longitude!,
        );

        print(
          '${store.premiseName} | '
              'STRAIGHT ${store.distanceKm!.toStringAsFixed(2)} km | '
              'DRIVING ${drivingDistanceKm.toStringAsFixed(2)} km',
        );

        if (drivingDistanceKm >
            nearbyRadiusKm) {
          continue;
        }

        nearbyStores.add(
          StoreComparison(
            premiseCode:
            store.premiseCode,
            premiseName:
            store.premiseName,
            address:
            store.address,
            premiseType:
            store.premiseType,
            state:
            store.state,
            products:
            store.products,
            latitude:
            store.latitude,
            longitude:
            store.longitude,
            distanceKm:
            drivingDistanceKm,
          ),
        );
      } catch (e) {
        print(
          'ROUTE ERROR | '
              '${store.premiseName} | '
              '$e',
        );
      }
    }

    nearbyStores.sort(
          (a, b) {
        final scoreA =
        getValueScore(a);

        final scoreB =
        getValueScore(b);

        return scoreA.compareTo(
          scoreB,
        );
      },
    );

    print('======================================');
    print('STORE VALUE RANKING');
    print('======================================');

    for (int i = 0;
    i < nearbyStores.length;
    i++) {
      final store =
      nearbyStores[i];

      print(
        '#${i + 1} '
            '${store.premiseName} | '
            '${store.distanceKm?.toStringAsFixed(2)} km | '
            'RM ${store.totalPrice.toStringAsFixed(2)} | '
            'SCORE RM ${getValueScore(store).toStringAsFixed(2)}',
      );
    }

    print('======================================');

    return nearbyStores.take(3).toList();
  }

  double getValueScore(
      StoreComparison store,
      ) {
    final distanceKm =
        store.distanceKm ?? 999;

    return store.totalPrice +
        (
            distanceKm *
                travelCostPerKm
        );
  }

  Future<double> getDrivingDistanceKm({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    if (googleMapsApiKey.isEmpty ||
        googleMapsApiKey ==
            'YOUR_GOOGLE_MAPS_API_KEY') {
      throw Exception(
        'Google Maps API Key is missing.',
      );
    }

    final uri = Uri.parse(
      'https://routes.googleapis.com/'
          'directions/v2:computeRoutes',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type':
        'application/json',
        'X-Goog-Api-Key':
        googleMapsApiKey,
        'X-Goog-FieldMask':
        'routes.distanceMeters,routes.duration',
      },
      body: jsonEncode(
        {
          'origin': {
            'location': {
              'latLng': {
                'latitude':
                originLatitude,
                'longitude':
                originLongitude,
              },
            },
          },
          'destination': {
            'location': {
              'latLng': {
                'latitude':
                destinationLatitude,
                'longitude':
                destinationLongitude,
              },
            },
          },
          'travelMode':
          'DRIVE',
          'routingPreference':
          'TRAFFIC_AWARE',
          'computeAlternativeRoutes':
          false,
          'units':
          'METRIC',
        },
      ),
    );

    if (response.statusCode != 200) {
      print(
        'ROUTES API ERROR: '
            '${response.statusCode}',
      );

      print(
        response.body,
      );

      throw Exception(
        'Google Routes API failed: '
            '${response.statusCode}',
      );
    }

    final data =
    jsonDecode(
      response.body,
    ) as Map<String, dynamic>;

    final routes =
    data['routes'] as List?;

    if (routes == null ||
        routes.isEmpty) {
      throw Exception(
        'No driving route found.',
      );
    }

    final route =
    Map<String, dynamic>.from(
      routes.first as Map,
    );

    final distanceMeters =
    (route['distanceMeters']
    as num?)
        ?.toDouble();

    if (distanceMeters == null) {
      throw Exception(
        'Driving distance unavailable.',
      );
    }

    return distanceMeters / 1000.0;
  }
}

class _LatestPrice {
  final double price;
  final String date;

  const _LatestPrice({
    required this.price,
    required this.date,
  });
}