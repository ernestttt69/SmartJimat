import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/cart_item.dart';
import '../models/shopping_plan.dart';
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
  List<ShoppingPlan> plans = [];

  @override
  void initState() {
    super.initState();
    comparePlans();
  }

  Future<void> comparePlans() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    double? latitude;
    double? longitude;

    try {
      final position =
      await locationService
          .getCurrentLocation();

      latitude = position.latitude;
      longitude = position.longitude;
    } catch (e) {
      print(
        'LOCATION UNAVAILABLE: $e',
      );
    }

    try {
      final results =
      await priceService
          .compareShoppingPlans(
        cart.items,
        userLatitude: latitude,
        userLongitude: longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        plans = results.take(2).toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  List<CartItem> getMissingItems(
      ShoppingPlan plan,
      ) {
    final coveredCodes = <int>{};

    for (final planStore
    in plan.stores) {
      for (final item
      in planStore.items) {
        coveredCodes.add(
          item.cartItem.product.itemCode,
        );
      }
    }

    return cart.items
        .where(
          (item) =>
      !coveredCodes.contains(
        item.product.itemCode,
      ),
    )
        .toList();
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
          'Shopping Plan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: comparePlans,
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
              'Finding best shopping plans...',
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
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to generate plan',
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
                onPressed: comparePlans,
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

    if (plans.isEmpty) {
      return const Center(
        child: Text(
          'No shopping plan found.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: comparePlans,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(16),
        children: [
          const Text(
            'Recommended Shopping Plans',
            style: TextStyle(
              fontSize: 22,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Plans prioritize item coverage, complete price information, price and distance.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0;
          i < plans.length;
          i++)
            buildPlanCard(
              plans[i],
              i,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget buildPlanCard(
      ShoppingPlan plan,
      int rank,
      ) {
    final isBest = rank == 0;

    final title = isBest
        ? 'BEST SHOPPING PLAN'
        : 'ALTERNATIVE PLAN';

    final missingItems =
    getMissingItems(plan);

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 16,
      ),
      padding:
      const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBest
            ? const Color(0xFFE7F8EC)
            : Colors.white,
        borderRadius:
        BorderRadius.circular(16),
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
              Icon(
                isBest
                    ? Icons
                    .workspace_premium
                    : Icons
                    .recommend_outlined,
                size: 20,
                color: isBest
                    ? const Color(
                  0xFF249347,
                )
                    : Colors.black54,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight:
                    FontWeight.bold,
                    color: isBest
                        ? const Color(
                      0xFF249347,
                    )
                        : Colors.black87,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  color: plan.isComplete
                      ? const Color(
                    0xFFDDF7E5,
                  )
                      : const Color(
                    0xFFFFEBCB,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(20),
                ),
                child: Text(
                  '${plan.coveredItemCount}/${plan.totalItemCount} Items',
                  style:
                  const TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${plan.storeCount} ${plan.storeCount == 1 ? 'Store' : 'Stores'} • ${plan.pricedItemCount}/${plan.totalItemCount} Prices Known',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0;
          i < plan.stores.length;
          i++) ...[
            buildPlanStore(
              plan.stores[i],
              i + 1,
            ),
            if (i <
                plan.stores.length - 1)
              const Padding(
                padding:
                EdgeInsets.symmetric(
                  vertical: 14,
                ),
                child: Divider(),
              ),
          ],
          if (missingItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons
                      .warning_amber_rounded,
                  color: Colors.orange,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Text(
                  '${missingItems.length} item${missingItems.length == 1 ? '' : 's'} with no store record',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item
            in missingItems)
              Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 6,
                ),
                child: Text(
                  item.product.item,
                  style:
                  const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          buildSummaryRow(
            'Known Price Total',
            'RM ${plan.knownPriceTotal.toStringAsFixed(2)}',
            true,
          ),
          const SizedBox(height: 8),
          buildSummaryRow(
            'Estimated Travel',
            '${plan.travelDistanceKm.toStringAsFixed(2)} km',
            false,
          ),
          const SizedBox(height: 8),
          buildSummaryRow(
            'Value Score',
            'RM ${plan.valueScore.toStringAsFixed(2)}',
            false,
          ),
        ],
      ),
    );
  }

  Widget buildPlanStore(
      ShoppingPlanStore planStore,
      int number,
      ) {
    final store =
        planStore.store;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment:
              Alignment.center,
              decoration:
              const BoxDecoration(
                color:
                Color(0xFF38BB62),
                shape:
                BoxShape.circle,
              ),
              child: Text(
                '$number',
                style:
                const TextStyle(
                  color: Colors.white,
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                store.premiseName,
                style:
                const TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (store.address.isNotEmpty) ...[
          const SizedBox(height: 5),
          Padding(
            padding:
            const EdgeInsets.only(
              left: 37,
            ),
            child: Text(
              store.address,
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: buildInfoBox(
                Icons
                    .shopping_bag_outlined,
                'Buy Here',
                '${planStore.itemCount} Items',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildInfoBox(
                Icons
                    .sell_outlined,
                'Prices Known',
                '${planStore.pricedItemCount}/${planStore.itemCount}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildInfoBox(
                Icons
                    .directions_car_outlined,
                'Distance',
                store.distanceKm == null
                    ? 'N/A'
                    : '${store.distanceKm!.toStringAsFixed(2)} km',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final item
        in planStore.items)
          Padding(
            padding:
            const EdgeInsets.only(
              bottom: 10,
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        item.cartItem
                            .product.item,
                        style:
                        const TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight
                              .w600,
                        ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      if (item.hasPrice)
                        Text(
                          'RM ${item.unitPrice!.toStringAsFixed(2)} × ${item.cartItem.quantity}',
                          style:
                          const TextStyle(
                            color:
                            Colors.grey,
                            fontSize: 10,
                          ),
                        )
                      else
                        const Text(
                          'Price Unavailable',
                          style: TextStyle(
                            color:
                            Colors.orange,
                            fontSize: 10,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (item.hasPrice)
                  Text(
                    'RM ${item.subtotal.toStringAsFixed(2)}',
                    style:
                    const TextStyle(
                      fontSize: 12,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  )
                else
                  const Text(
                    'Price Unavailable',
                    style: TextStyle(
                      color:
                      Colors.orange,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'Known Subtotal: RM ${planStore.subtotal.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight:
            FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child:
              FilledButton.icon(
                onPressed: () {
                  openGoogleMaps(
                    store,
                  );
                },
                style:
                FilledButton
                    .styleFrom(
                  backgroundColor:
                  const Color(
                    0xFF38BB62,
                  ),
                ),
                icon: const Icon(
                  Icons.map_outlined,
                  size: 17,
                ),
                label: const Text(
                  'Maps',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child:
              OutlinedButton.icon(
                onPressed: () {
                  openWaze(store);
                },
                icon: const Icon(
                  Icons
                      .navigation_outlined,
                  size: 17,
                ),
                label: const Text(
                  'Waze',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildInfoBox(
      IconData icon,
      String label,
      String value,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF7F7F7),
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color:
            const Color(
              0xFF249347,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style:
            const TextStyle(
              color: Colors.grey,
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              fontSize: 10,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryRow(
      String label,
      String value,
      bool highlight,
      ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlight
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize:
            highlight ? 19 : 12,
            fontWeight:
            FontWeight.bold,
            color: highlight
                ? const Color(
              0xFF249347,
            )
                : Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> openGoogleMaps(
      StoreComparison store,
      ) async {
    try {
      final position =
      await locationService
          .getCurrentLocation();

      final destination =
      store.latitude != null &&
          store.longitude != null
          ? '${store.latitude},${store.longitude}'
          : [
        store.premiseName,
        store.address,
        store.state,
      ]
          .where(
            (value) =>
        value
            .trim()
            .isNotEmpty,
      )
          .join(', ');

      final uri = Uri.https(
        'www.google.com',
        '/maps/dir/',
        {
          'api': '1',
          'origin':
          '${position.latitude},${position.longitude}',
          'destination':
          destination,
          'travelmode': 'driving',
        },
      );

      await launchUrl(
        uri,
        mode:
        LaunchMode.externalApplication,
      );
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
    final uri = store.latitude != null &&
        store.longitude != null
        ? Uri.https(
      'www.waze.com',
      '/ul',
      {
        'll':
        '${store.latitude},${store.longitude}',
        'navigate': 'yes',
      },
    )
        : Uri.https(
      'www.waze.com',
      '/ul',
      {
        'q': [
          store.premiseName,
          store.address,
          store.state,
        ]
            .where(
              (value) =>
          value
              .trim()
              .isNotEmpty,
        )
            .join(', '),
        'navigate': 'yes',
      },
    );

    await launchUrl(
      uri,
      mode:
      LaunchMode.externalApplication,
    );
  }
}