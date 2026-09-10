import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'price_history_screen.dart';

class ShopDetailsScreen
    extends StatefulWidget {
  final int premiseCode;
  final String premiseName;
  final String address;
  final String premiseType;
  final String state;

  const ShopDetailsScreen({
    super.key,
    required this.premiseCode,
    required this.premiseName,
    required this.address,
    required this.premiseType,
    required this.state,
  });

  @override
  State<ShopDetailsScreen> createState() =>
      _ShopDetailsScreenState();
}

class _ShopDetailsScreenState
    extends State<ShopDetailsScreen> {
  final SupabaseClient supabase =
      Supabase.instance.client;

  final TextEditingController
  searchController =
  TextEditingController();

  bool isLoading = true;

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>>
  filteredProducts = [];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    try {
      final priceRows = await supabase
          .from('pricecatcher')
          .select(
        'item_code, price, date',
      )
          .eq(
        'premise_code',
        widget.premiseCode,
      )
          .not(
        'price',
        'is',
        null,
      );

      final Map<int, Map<String, dynamic>>
      latestPriceByItem = {};

      for (final row in priceRows) {
        final itemCode = int.tryParse(
          row['item_code'].toString(),
        );

        final price = double.tryParse(
          row['price'].toString(),
        );

        final date =
            row['date']?.toString() ?? '';

        if (itemCode == null ||
            price == null) {
          continue;
        }

        final existing =
        latestPriceByItem[itemCode];

        if (existing == null ||
            date.compareTo(
              existing['date']
                  .toString(),
            ) >
                0) {
          latestPriceByItem[itemCode] = {
            'price': price,
            'date': date,
          };
        }
      }

      final itemCodes =
      latestPriceByItem.keys.toList();

      if (itemCodes.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          products = [];
          filteredProducts = [];
          isLoading = false;
        });

        return;
      }

      final itemRows = await supabase
          .from('lookup_item')
          .select(
        'item_code, item, unit, item_group, item_category',
      )
          .inFilter(
        'item_code',
        itemCodes,
      )
          .order('item');

      final List<Map<String, dynamic>>
      result = [];

      for (final row in itemRows) {
        final itemCode = int.tryParse(
          row['item_code'].toString(),
        );

        if (itemCode == null) {
          continue;
        }

        final latest =
        latestPriceByItem[itemCode];

        if (latest == null) {
          continue;
        }

        result.add({
          'item_code': itemCode,
          'item':
          row['item']?.toString() ?? '',
          'unit':
          row['unit']?.toString() ?? '',
          'item_group':
          row['item_group']?.toString() ??
              '',
          'item_category':
          row['item_category']
              ?.toString() ??
              '',
          'price': latest['price'],
          'date': latest['date'],
        });
      }

      if (!mounted) {
        return;
      }

      setState(() {
        products = result;
        filteredProducts = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load products: $e',
          ),
        ),
      );
    }
  }

  void filterProducts(String value) {
    final keyword =
    value.trim().toLowerCase();

    setState(() {
      if (keyword.isEmpty) {
        filteredProducts = products;
      } else {
        filteredProducts = products
            .where(
              (product) => product['item']
              .toString()
              .toLowerCase()
              .contains(keyword),
        )
            .toList();
      }
    });
  }

  void openPriceHistory(
      Map<String, dynamic> product,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PriceHistoryScreen(
          premiseCode:
          widget.premiseCode,
          premiseName:
          widget.premiseName,
          itemCode:
          product['item_code'] as int,
          itemName:
          product['item'].toString(),
          unit:
          product['unit'].toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Shop Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadProducts,
        child: ListView(
          padding:
          const EdgeInsets.all(20),
          children: [
            Container(
              padding:
              const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration:
                        BoxDecoration(
                          color: const Color(
                            0xFFE7F8EC,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            16,
                          ),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: Color(
                            0xFF38BB62,
                          ),
                          size: 30,
                        ),
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              widget.premiseName,
                              style:
                              const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                            if (widget
                                .premiseType
                                .isNotEmpty) ...[
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                widget
                                    .premiseType,
                                style:
                                const TextStyle(
                                  color: Color(
                                    0xFF38BB62,
                                  ),
                                  fontWeight:
                                  FontWeight
                                      .w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.address
                      .isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons
                              .location_on_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.address,
                            style:
                            const TextStyle(
                              color: Colors.grey,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.state
                      .isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.state,
                      style:
                      const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Products with Price Records',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${products.length} products found',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller:
              searchController,
              onChanged: filterProducts,
              decoration: InputDecoration(
                hintText:
                'Search product...',
                prefixIcon:
                const Icon(
                  Icons.search,
                ),
                filled: true,
                fillColor: Colors.white,
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                  borderSide:
                  BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (isLoading)
              const Padding(
                padding:
                EdgeInsets.all(40),
                child: Center(
                  child:
                  CircularProgressIndicator(),
                ),
              )
            else if (filteredProducts.isEmpty)
              Container(
                padding:
                const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons
                          .inventory_2_outlined,
                      size: 55,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No products found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...filteredProducts.map(
                    (product) =>
                    buildProductCard(
                      product,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildProductCard(
      Map<String, dynamic> product,
      ) {
    final price = double.tryParse(
      product['price'].toString(),
    ) ??
        0;

    final unit =
        product['unit']?.toString() ?? '';

    final date =
        product['date']?.toString() ?? '';

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: Material(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        child: InkWell(
          borderRadius:
          BorderRadius.circular(18),
          onTap: () =>
              openPriceHistory(product),
          child: Padding(
            padding:
            const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                  BoxDecoration(
                    color: const Color(
                      0xFFE7F8EC,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: const Icon(
                    Icons.shopping_basket,
                    color: Color(
                      0xFF38BB62,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['item']
                            ?.toString() ??
                            '',
                        style:
                        const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                      if (unit.isNotEmpty) ...[
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          unit,
                          style:
                          const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      if (date.isNotEmpty) ...[
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          'Recorded: $date',
                          style:
                          const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RM ${price.toStringAsFixed(2)}',
                      style:
                      const TextStyle(
                        color: Color(
                          0xFF38BB62,
                        ),
                        fontSize: 17,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Latest',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}