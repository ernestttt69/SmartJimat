import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/store_comparison.dart';
import '../services/location_service.dart';
import '../services/price_comparison_service.dart';
import '../services/shopping_cart_service.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({
    super.key,
  });

  @override
  State<RecommendationScreen> createState() =>
      _RecommendationScreenState();
}

class _RecommendationScreenState
    extends State<RecommendationScreen> {
  final ShoppingCartService cart =
      ShoppingCartService.instance;

  final PriceComparisonService priceService =
  PriceComparisonService();

  final LocationService locationService =
  LocationService();

  bool isLoading = true;
  String? errorMessage;

  List<StoreComparison> stores = [];

  @override
  void initState() {
    super.initState();
    compareStores();
  }

  Future<void> compareStores() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    double? userLatitude;
    double? userLongitude;

    try {
      final position =
      await locationService.getCurrentLocation();

      userLatitude = position.latitude;
      userLongitude = position.longitude;
    } catch (e) {
      print(
        'LOCATION UNAVAILABLE: $e',
      );
    }

    try {
      final results =
      await priceService.compareStores(
        cart.items,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        stores = results.take(3).toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Store Recommendation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: compareStores,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Finding best value stores...',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 58,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to find stores',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign:
                TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: compareStores,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Try Again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (stores.isEmpty) {
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.store_mall_directory_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Nearby Store Found',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No store within 15 km has usable price data for your selected items.',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: compareStores,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Try Again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: compareStores,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(16),
        children: [
          const Text(
            'Top Recommendations',
            style: TextStyle(
              fontSize: 22,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ranked by shopping price and driving distance',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0;
          i < stores.length;
          i++)
            buildStoreCard(
              store: stores[i],
              rank: i,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget buildStoreCard({
    required StoreComparison store,
    required int rank,
  }) {
    final titles = [
      'BEST OPTION',
      'SECOND OPTION',
      'THIRD OPTION',
    ];

    final icons = [
      Icons.workspace_premium,
      Icons.looks_two,
      Icons.looks_3,
    ];

    final distanceText =
    store.distanceKm == null
        ? 'Distance unavailable'
        : '${store.distanceKm!.toStringAsFixed(2)} km';

    final score =
    priceService.getValueScore(
      store,
    );

    final isBest =
        rank == 0;

    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isBest
            ? const Color(0xFFE7F8EC)
            : Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: isBest
              ? const Color(0xFF38BB62)
              : const Color(0xFFE4E5E7),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  color: isBest
                      ? const Color(
                    0xFF38BB62,
                  )
                      : const Color(
                    0xFFF0F1F2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icons[rank],
                  color: isBest
                      ? Colors.white
                      : Colors.black87,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titles[rank],
                  style: TextStyle(
                    color: isBest
                        ? const Color(
                      0xFF249347,
                    )
                        : Colors.black87,
                    fontSize: 13,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            store.premiseName,
            style: const TextStyle(
              fontSize: 19,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          if (store.address.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              store.address,
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: buildInfoBox(
                  icon:
                  Icons.directions_car_outlined,
                  label:
                  'Driving Distance',
                  value:
                  distanceText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildInfoBox(
                  icon:
                  Icons.shopping_bag_outlined,
                  label: 'Items',
                  value:
                  '${store.availableItemCount}/${cart.totalUniqueItems}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Shopping Total',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'RM ${store.totalPrice.toStringAsFixed(2)}',
            style: TextStyle(
              color: isBest
                  ? const Color(
                0xFF249347,
              )
                  : Colors.black,
              fontSize: 28,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Value Score: RM ${score.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight:
              FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    openGoogleMaps(
                      store,
                    );
                  },
                  style:
                  FilledButton.styleFrom(
                    backgroundColor:
                    const Color(
                      0xFF38BB62,
                    ),
                    padding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 13,
                    ),
                  ),
                  icon: const Icon(
                    Icons.map_outlined,
                    size: 20,
                  ),
                  label: const Text(
                    'Maps',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child:
                OutlinedButton.icon(
                  onPressed: () {
                    openWaze(
                      store,
                    );
                  },
                  style:
                  OutlinedButton
                      .styleFrom(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 13,
                    ),
                  ),
                  icon: const Icon(
                    Icons.navigation_outlined,
                    size: 20,
                  ),
                  label: const Text(
                    'Waze',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildInfoBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF7F7F7),
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color:
            const Color(
              0xFF249347,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                  const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(
                  height: 1,
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openGoogleMaps(
      StoreComparison store,
      ) async {
    try {
      final position =
      await locationService
          .getCurrentLocation();

      String destination;

      if (store.latitude != null &&
          store.longitude != null) {
        destination =
        '${store.latitude},${store.longitude}';
      } else {
        destination = [
          store.premiseName,
          store.address,
          store.state,
        ]
            .where(
              (value) =>
          value.trim().isNotEmpty,
        )
            .join(', ');
      }

      final origin =
          '${position.latitude},${position.longitude}';

      final uri = Uri.https(
        'www.google.com',
        '/maps/dir/',
        {
          'api': '1',
          'origin': origin,
          'destination':
          destination,
          'travelmode': 'driving',
        },
      );

      final opened =
      await launchUrl(
        uri,
        mode:
        LaunchMode.externalApplication,
      );

      if (!opened) {
        throw Exception(
          'Unable to open Google Maps.',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open Google Maps: $e',
          ),
        ),
      );
    }
  }

  Future<void> openWaze(
      StoreComparison store,
      ) async {
    Uri uri;

    if (store.latitude != null &&
        store.longitude != null) {
      uri = Uri.https(
        'www.waze.com',
        '/ul',
        {
          'll':
          '${store.latitude},${store.longitude}',
          'navigate': 'yes',
        },
      );
    } else {
      final destination = [
        store.premiseName,
        store.address,
        store.state,
      ]
          .where(
            (value) =>
        value.trim().isNotEmpty,
      )
          .join(', ');

      uri = Uri.https(
        'www.waze.com',
        '/ul',
        {
          'q': destination,
          'navigate': 'yes',
        },
      );
    }

    final opened =
    await launchUrl(
      uri,
      mode:
      LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open Waze.',
          ),
        ),
      );
    }
  }
}