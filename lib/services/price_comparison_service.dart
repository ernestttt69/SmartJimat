import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import '../models/shopping_plan.dart';
import '../models/store_comparison.dart';

class PriceComparisonService {
  final SupabaseClient supabase =
      Supabase.instance.client;

  static const double nearbyRadiusKm = 15.0;
  static const double travelCostPerKm = 1.50;
  static const int maxRouteCandidates = 10;

  static const String googleMapsApiKey =
      'YOUR_GOOGLE_MAPS_API_KEY';

  Future<List<ShoppingPlan>> compareShoppingPlans(
      List<CartItem> cartItems, {
        double? userLatitude,
        double? userLongitude,
      }) async {
    if (cartItems.isEmpty) {
      return [];
    }

    final stores = await _loadNearbyStores(
      cartItems,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );

    if (stores.isEmpty) {
      return [];
    }

    final plans = <ShoppingPlan>[];

    for (final store in stores) {
      plans.add(
        _buildSingleStorePlan(
          store,
          cartItems,
        ),
      );
    }

    for (int i = 0;
    i < stores.length;
    i++) {
      for (int j = i + 1;
      j < stores.length;
      j++) {
        plans.add(
          _buildTwoStorePlan(
            stores[i],
            stores[j],
            cartItems,
          ),
        );
      }
    }

    plans.sort(_comparePlans);

    final uniquePlans =
    <ShoppingPlan>[];

    final seen = <String>{};

    for (final plan in plans) {
      final codes = plan.stores
          .map(
            (entry) =>
        entry.store.premiseCode,
      )
          .toList()
        ..sort();

      final key = codes.join('-');

      if (seen.contains(key)) {
        continue;
      }

      seen.add(key);
      uniquePlans.add(plan);

      if (uniquePlans.length == 2) {
        break;
      }
    }

    print('======================================');
    print('SHOPPING PLAN RANKING');
    print('======================================');

    for (int i = 0;
    i < uniquePlans.length;
    i++) {
      final plan = uniquePlans[i];

      print(
        '#${i + 1} | '
            '${plan.storeCount} STORE(S) | '
            '${plan.coveredItemCount}/${plan.totalItemCount} COVERED | '
            '${plan.pricedItemCount}/${plan.totalItemCount} PRICED | '
            'RM ${plan.knownPriceTotal.toStringAsFixed(2)} | '
            '${plan.travelDistanceKm.toStringAsFixed(2)} KM | '
            'SCORE RM ${plan.valueScore.toStringAsFixed(2)}',
      );
    }

    print('======================================');

    return uniquePlans;
  }

  int _comparePlans(
      ShoppingPlan a,
      ShoppingPlan b,
      ) {
    final coverage =
    b.coveredItemCount.compareTo(
      a.coveredItemCount,
    );

    if (coverage != 0) {
      return coverage;
    }

    final priced =
    b.pricedItemCount.compareTo(
      a.pricedItemCount,
    );

    if (priced != 0) {
      return priced;
    }

    return a.valueScore.compareTo(
      b.valueScore,
    );
  }

  Future<List<StoreComparison>>
  _loadNearbyStores(
      List<CartItem> cartItems, {
        double? userLatitude,
        double? userLongitude,
      }) async {
    final itemCodes = cartItems
        .map(
          (item) =>
      item.product.itemCode,
    )
        .toSet()
        .toList();

    final cartItemMap = {
      for (final item in cartItems)
        item.product.itemCode: item,
    };

    print('======================================');
    print('PRICE COMPARISON START');
    print('ITEM CODES: $itemCodes');
    print(
      'USER LOCATION: '
          '$userLatitude, $userLongitude',
    );
    print('======================================');

    final rpcResult =
    await supabase.rpc(
      'get_latest_prices',
      params: {
        'p_item_codes': itemCodes,
      },
    );

    final rows =
    List<dynamic>.from(
      rpcResult as List,
    );

    if (rows.isEmpty) {
      print('NO PRICECATCHER RECORDS FOUND');
      return [];
    }

    final Map<int, Set<int>>
    recordsByStore = {};

    final Map<int, Map<int, double>>
    pricesByStore = {};

    for (final row in rows) {
      final premiseCode =
      int.tryParse(
        row['premise_code'].toString(),
      );

      final itemCode =
      int.tryParse(
        row['item_code'].toString(),
      );

      if (premiseCode == null ||
          itemCode == null) {
        continue;
      }

      recordsByStore.putIfAbsent(
        premiseCode,
            () => <int>{},
      );

      recordsByStore[premiseCode]!
          .add(itemCode);

      final rawPrice =
      row['price'];

      if (rawPrice == null) {
        continue;
      }

      final price =
      double.tryParse(
        rawPrice.toString(),
      );

      if (price == null) {
        continue;
      }

      pricesByStore.putIfAbsent(
        premiseCode,
            () => <int, double>{},
      );

      pricesByStore[premiseCode]![
      itemCode] = price;
    }

    final storeCodes =
    recordsByStore.keys.toList();

    if (storeCodes.isEmpty) {
      return [];
    }

    final premiseRows =
    await supabase
        .from('lookup_premise')
        .select(
      'premise_code, premise, address, premise_type, state',
    )
        .inFilter(
      'premise_code',
      storeCodes,
    );

    final locationRows =
    await supabase
        .from('premise_location')
        .select(
      'premise_code, latitude, longitude',
    )
        .inFilter(
      'premise_code',
      storeCodes,
    );

    final Map<int, Map<String, dynamic>>
    premiseMap = {};

    for (final row in premiseRows) {
      final code =
      int.tryParse(
        row['premise_code'].toString(),
      );

      if (code != null) {
        premiseMap[code] =
        Map<String, dynamic>.from(
          row,
        );
      }
    }

    final Map<int, Map<String, dynamic>>
    locationMap = {};

    for (final row in locationRows) {
      final code =
      int.tryParse(
        row['premise_code'].toString(),
      );

      if (code != null) {
        locationMap[code] =
        Map<String, dynamic>.from(
          row,
        );
      }
    }

    final stores =
    <StoreComparison>[];

    for (final premiseCode
    in storeCodes) {
      final premise =
      premiseMap[premiseCode];

      final location =
      locationMap[premiseCode];

      final recordCodes =
      recordsByStore[premiseCode];

      if (premise == null ||
          location == null ||
          recordCodes == null) {
        continue;
      }

      final latitude =
      double.tryParse(
        location['latitude'].toString(),
      );

      final longitude =
      double.tryParse(
        location['longitude'].toString(),
      );

      if (latitude == null ||
          longitude == null) {
        continue;
      }

      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        print(
          'INVALID STORE LOCATION | '
              '${premise['premise']} | '
              '$latitude,$longitude',
        );

        continue;
      }

      final recordedItems =
      <CartItem>[];

      final pricedProducts =
      <StoreProductPrice>[];

      for (final itemCode
      in recordCodes) {
        final cartItem =
        cartItemMap[itemCode];

        if (cartItem == null) {
          continue;
        }

        recordedItems.add(
          cartItem,
        );

        final price =
        pricesByStore[
        premiseCode]?[itemCode];

        if (price != null) {
          pricedProducts.add(
            StoreProductPrice(
              cartItem: cartItem,
              unitPrice: price,
            ),
          );
        }
      }

      if (recordedItems.isEmpty) {
        continue;
      }

      double? distanceKm;

      if (userLatitude != null &&
          userLongitude != null) {
        distanceKm =
            Geolocator.distanceBetween(
              userLatitude,
              userLongitude,
              latitude,
              longitude,
            ) /
                1000;
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
          pricedProducts,
          recordedItems:
          recordedItems,
          latitude:
          latitude,
          longitude:
          longitude,
          distanceKm:
          distanceKm,
        ),
      );
    }

    if (stores.isEmpty) {
      return [];
    }

    if (userLatitude == null ||
        userLongitude == null) {
      stores.sort(
        _compareStores,
      );

      return stores;
    }

    stores.sort(
          (a, b) =>
          (a.distanceKm ?? 999999)
              .compareTo(
            b.distanceKm ?? 999999,
          ),
    );

    final candidates = stores
        .take(maxRouteCandidates)
        .toList();

    print('======================================');
    print(
      'ROUTE API CANDIDATES: '
          '${candidates.length}',
    );
    print('======================================');

    final nearbyStores =
    <StoreComparison>[];

    for (final store
    in candidates) {
      double distance =
          store.distanceKm ?? 999999;

      try {
        distance =
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
          'ROUTE SUCCESS | '
              '${store.premiseName} | '
              '${distance.toStringAsFixed(2)} km',
        );
      } catch (e) {
        print(
          'ROUTE ERROR | '
              '${store.premiseName} | '
              '$e',
        );

        print(
          'USING STRAIGHT-LINE FALLBACK | '
              '${store.premiseName} | '
              '${distance.toStringAsFixed(2)} km',
        );
      }

      if (distance >
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
          recordedItems:
          store.recordedItems,
          latitude:
          store.latitude,
          longitude:
          store.longitude,
          distanceKm:
          distance,
        ),
      );
    }

    nearbyStores.sort(
      _compareStores,
    );

    print('======================================');
    print('STORE RANKING');
    print('======================================');

    for (int i = 0;
    i < nearbyStores.length;
    i++) {
      final store =
      nearbyStores[i];

      print(
        '#${i + 1} | '
            '${store.premiseName} | '
            '${store.coveredItemCount}/${cartItems.length} COVERED | '
            '${store.pricedItemCount}/${cartItems.length} PRICED | '
            'RM ${store.totalPrice.toStringAsFixed(2)} | '
            '${store.distanceKm?.toStringAsFixed(2)} KM | '
            'SCORE RM ${getValueScore(store).toStringAsFixed(2)}',
      );
    }

    print('======================================');

    return nearbyStores;
  }

  int _compareStores(
      StoreComparison a,
      StoreComparison b,
      ) {
    final coverage =
    b.coveredItemCount.compareTo(
      a.coveredItemCount,
    );

    if (coverage != 0) {
      return coverage;
    }

    final priced =
    b.pricedItemCount.compareTo(
      a.pricedItemCount,
    );

    if (priced != 0) {
      return priced;
    }

    return getValueScore(a)
        .compareTo(
      getValueScore(b),
    );
  }

  ShoppingPlan _buildSingleStorePlan(
      StoreComparison store,
      List<CartItem> cartItems,
      ) {
    final items =
    <ShoppingPlanItem>[];

    final priceMap = {
      for (final product
      in store.products)
        product.cartItem.product.itemCode:
        product.unitPrice,
    };

    for (final cartItem
    in store.recordedItems) {
      items.add(
        ShoppingPlanItem(
          cartItem:
          cartItem,
          unitPrice:
          priceMap[
          cartItem
              .product
              .itemCode],
        ),
      );
    }

    final knownTotal =
    items.fold<double>(
      0,
          (total, item) =>
      total +
          item.subtotal,
    );

    final distance =
        store.distanceKm ?? 0;

    return ShoppingPlan(
      stores: [
        ShoppingPlanStore(
          store:
          store,
          items:
          items,
        ),
      ],
      coveredItemCount:
      items.length,
      pricedItemCount:
      items
          .where(
            (item) =>
        item.hasPrice,
      )
          .length,
      totalItemCount:
      cartItems.length,
      knownPriceTotal:
      knownTotal,
      travelDistanceKm:
      distance,
      valueScore:
      knownTotal +
          distance *
              travelCostPerKm,
    );
  }

  ShoppingPlan _buildTwoStorePlan(
      StoreComparison storeA,
      StoreComparison storeB,
      List<CartItem> cartItems,
      ) {
    final recordA =
        storeA.recordedItemCodes;

    final recordB =
        storeB.recordedItemCodes;

    final priceA = {
      for (final product
      in storeA.products)
        product.cartItem.product.itemCode:
        product.unitPrice,
    };

    final priceB = {
      for (final product
      in storeB.products)
        product.cartItem.product.itemCode:
        product.unitPrice,
    };

    final itemsA =
    <ShoppingPlanItem>[];

    final itemsB =
    <ShoppingPlanItem>[];

    int covered = 0;
    int priced = 0;
    double knownTotal = 0;

    for (final cartItem
    in cartItems) {
      final code =
          cartItem.product.itemCode;

      final hasA =
      recordA.contains(code);

      final hasB =
      recordB.contains(code);

      if (!hasA && !hasB) {
        continue;
      }

      covered++;

      final aPrice =
      priceA[code];

      final bPrice =
      priceB[code];

      if (aPrice != null &&
          bPrice != null) {
        priced++;

        if (aPrice <= bPrice) {
          itemsA.add(
            ShoppingPlanItem(
              cartItem:
              cartItem,
              unitPrice:
              aPrice,
            ),
          );

          knownTotal +=
              aPrice *
                  cartItem.quantity;
        } else {
          itemsB.add(
            ShoppingPlanItem(
              cartItem:
              cartItem,
              unitPrice:
              bPrice,
            ),
          );

          knownTotal +=
              bPrice *
                  cartItem.quantity;
        }

        continue;
      }

      if (aPrice != null) {
        priced++;

        itemsA.add(
          ShoppingPlanItem(
            cartItem:
            cartItem,
            unitPrice:
            aPrice,
          ),
        );

        knownTotal +=
            aPrice *
                cartItem.quantity;

        continue;
      }

      if (bPrice != null) {
        priced++;

        itemsB.add(
          ShoppingPlanItem(
            cartItem:
            cartItem,
            unitPrice:
            bPrice,
          ),
        );

        knownTotal +=
            bPrice *
                cartItem.quantity;

        continue;
      }

      if (hasA) {
        itemsA.add(
          ShoppingPlanItem(
            cartItem:
            cartItem,
            unitPrice:
            null,
          ),
        );
      } else {
        itemsB.add(
          ShoppingPlanItem(
            cartItem:
            cartItem,
            unitPrice:
            null,
          ),
        );
      }
    }

    final planStores =
    <ShoppingPlanStore>[];

    if (itemsA.isNotEmpty) {
      planStores.add(
        ShoppingPlanStore(
          store:
          storeA,
          items:
          itemsA,
        ),
      );
    }

    if (itemsB.isNotEmpty) {
      planStores.add(
        ShoppingPlanStore(
          store:
          storeB,
          items:
          itemsB,
        ),
      );
    }

    double travelDistance = 0;

    if (planStores.length == 1) {
      travelDistance =
          planStores.first
              .store
              .distanceKm ??
              0;
    }

    if (planStores.length == 2) {
      final distanceA =
          storeA.distanceKm ?? 0;

      final distanceB =
          storeB.distanceKm ?? 0;

      double betweenStores = 0;

      if (storeA.latitude != null &&
          storeA.longitude != null &&
          storeB.latitude != null &&
          storeB.longitude != null) {
        betweenStores =
            Geolocator.distanceBetween(
              storeA.latitude!,
              storeA.longitude!,
              storeB.latitude!,
              storeB.longitude!,
            ) /
                1000;
      }

      final routeAFirst =
          distanceA +
              betweenStores;

      final routeBFirst =
          distanceB +
              betweenStores;

      travelDistance =
      routeAFirst <
          routeBFirst
          ? routeAFirst
          : routeBFirst;
    }

    return ShoppingPlan(
      stores:
      planStores,
      coveredItemCount:
      covered,
      pricedItemCount:
      priced,
      totalItemCount:
      cartItems.length,
      knownPriceTotal:
      knownTotal,
      travelDistanceKm:
      travelDistance,
      valueScore:
      knownTotal +
          travelDistance *
              travelCostPerKm,
    );
  }

  double getValueScore(
      StoreComparison store,
      ) {
    return store.totalPrice +
        (store.distanceKm ?? 0) *
            travelCostPerKm;
  }

  Future<double> getDrivingDistanceKm({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    if (googleMapsApiKey.isEmpty ||
        googleMapsApiKey ==
            'AIzaSyCw9eR0wNRnT78Pqk6l5IR6mB3MLfu468I') {
      throw Exception(
        'Google Maps API Key is missing.',
      );
    }

    print(
      'ROUTE REQUEST | '
          'ORIGIN '
          '$originLatitude,$originLongitude | '
          'DESTINATION '
          '$destinationLatitude,$destinationLongitude',
    );

    final response =
    await http.post(
      Uri.parse(
        'https://routes.googleapis.com/directions/v2:computeRoutes',
      ),
      headers: {
        'Content-Type':
        'application/json',
        'X-Goog-Api-Key':
        googleMapsApiKey,
        'X-Goog-FieldMask':
        'routes.distanceMeters,routes.duration',
      },
      body: jsonEncode({
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
      }),
    );

    if (response.statusCode != 200) {
      print(
        'ROUTES API ERROR: '
            '${response.statusCode}',
      );

      print(
        'ROUTES API BODY: '
            '${response.body}',
      );

      throw Exception(
        'Google Routes API failed: '
            '${response.statusCode}',
      );
    }

    final data =
    jsonDecode(
      response.body,
    );

    final routes =
    data['routes'] as List?;

    if (routes == null ||
        routes.isEmpty) {
      throw Exception(
        'No driving route found.',
      );
    }

    final route =
        routes.first;

    final distanceMeters =
    double.tryParse(
      route['distanceMeters']
          .toString(),
    );

    if (distanceMeters == null) {
      throw Exception(
        'Driving distance unavailable.',
      );
    }

    print(
      'ROUTE DISTANCE: '
          '${(distanceMeters / 1000).toStringAsFixed(2)} km',
    );

    return distanceMeters / 1000;
  }
}