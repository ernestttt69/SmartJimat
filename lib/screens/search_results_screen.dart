import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/shopping_cart_service.dart';
import '../services/supabase_service.dart';
import 'shopping_list_screen.dart';

class SearchResultsScreen
    extends StatefulWidget {
  final String keyword;

  const SearchResultsScreen({
    super.key,
    required this.keyword,
  });

  @override
  State<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState
    extends State<SearchResultsScreen> {
  final SupabaseService supabaseService =
  SupabaseService();

  final ShoppingCartService cart =
      ShoppingCartService.instance;

  bool isLoading = true;

  List<Product> products = [];

  Set<int> itemsWithPrice = {};

  @override
  void initState() {
    super.initState();

    searchProducts();

    cart.addListener(refreshCart);
  }

  @override
  void dispose() {
    cart.removeListener(refreshCart);

    super.dispose();
  }

  void refreshCart() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> searchProducts() async {
    try {
      final result =
      await supabaseService
          .searchProducts(
        widget.keyword,
      );

      final itemCodes = result
          .map(
            (product) => product.itemCode,
      )
          .toList();

      final priceItems =
      await supabaseService
          .getItemsWithPrice(
        itemCodes,
      );

      if (!mounted) return;

      setState(() {
        products = result;
        itemsWithPrice = priceItems;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Search failed: $e',
          ),
        ),
      );
    }
  }

  void addProduct(Product product) {
    cart.addProduct(product);

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        duration:
        const Duration(seconds: 1),
        content: Text(
          '${product.item} added to shopping list',
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

        title: Text(
          'Search: ${widget.keyword}',
        ),

        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const ShoppingListScreen(),
                    ),
                  );
                },
              ),

              if (cart.totalQuantity > 0)
                Positioned(
                  right: 4,
                  top: 3,
                  child: Container(
                    padding:
                    const EdgeInsets.all(5),
                    decoration:
                    const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.totalQuantity}',
                      style:
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : products.isEmpty
          ? Center(
        child: Text(
          'No products found for "${widget.keyword}"',
        ),
      )
          : ListView.separated(
        padding:
        const EdgeInsets.all(16),
        itemCount:
        products.length,
        separatorBuilder:
            (_, __) =>
        const SizedBox(
          height: 10,
        ),
        itemBuilder:
            (context, index) {
          final product =
          products[index];

          final added =
          cart.containsProduct(
            product.itemCode,
          );

          final hasPrice =
          itemsWithPrice
              .contains(
            product.itemCode,
          );

          return Card(
            color: Colors.white,
            elevation: 0,
            child: ListTile(
              contentPadding:
              const EdgeInsets
                  .all(12),

              leading:
              const CircleAvatar(
                backgroundColor:
                Color(
                  0xFFE7F8EC,
                ),
                child: Icon(
                  Icons
                      .shopping_basket,
                  color: Color(
                    0xFF38BB62,
                  ),
                ),
              ),

              title: Text(
                product.item,
                style:
                const TextStyle(
                  fontWeight:
                  FontWeight
                      .w600,
                ),
              ),

              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    product.unit,
                  ),

                  Text(
                    product
                        .itemCategory,
                  ),

                  if (!hasPrice) ...[
                    const SizedBox(
                      height: 4,
                    ),

                    const Row(
                      mainAxisSize:
                      MainAxisSize
                          .min,
                      children: [
                        Icon(
                          Icons
                              .warning_amber_rounded,
                          size: 16,
                          color:
                          Colors
                              .orange,
                        ),

                        SizedBox(
                          width: 4,
                        ),

                        Text(
                          'Price Unavailable',
                          style:
                          TextStyle(
                            color:
                            Colors
                                .orange,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              trailing:
              FilledButton.icon(
                onPressed: () {
                  addProduct(
                    product,
                  );
                },
                icon: Icon(
                  added
                      ? Icons.check
                      : Icons.add,
                  size: 18,
                ),
                label: Text(
                  added
                      ? 'Add More'
                      : 'Add',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}