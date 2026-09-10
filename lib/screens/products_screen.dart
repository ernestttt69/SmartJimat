import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/shopping_cart_service.dart';
import '../services/supabase_service.dart';
import 'shopping_list_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String itemGroup;
  final String itemCategory;

  const ProductsScreen({
    super.key,
    required this.itemGroup,
    required this.itemCategory,
  });

  @override
  State<ProductsScreen> createState() =>
      _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
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

    loadProducts();

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

  Future<void> loadProducts() async {
    try {
      final result =
      await supabaseService.getProductsByCategory(
        widget.itemGroup,
        widget.itemCategory,
      );

      final itemCodes = result
          .map(
            (product) => product.itemCode,
      )
          .toList();

      final priceItems =
      await supabaseService.getItemsWithPrice(
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load products: $e',
          ),
        ),
      );
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      await cart.addProduct(product);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save shopping list: $e')),
      );
      return;
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(
          '${product.item} added to shopping list',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),

      appBar: AppBar(
        backgroundColor: Colors.white,

        title: Text(
          widget.itemCategory,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.totalQuantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
        child: CircularProgressIndicator(),
      )
          : products.isEmpty
          ? const Center(
        child: Text(
          'No products found',
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.itemCategory,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            widget.itemGroup,
            style: const TextStyle(
              color: Color(0xFF38BB62),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            '${products.length} products',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 20),

          ...products.map(
                (product) {
              final added =
              cart.containsProduct(
                product.itemCode,
              );

              final hasPrice =
              itemsWithPrice.contains(
                product.itemCode,
              );

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Card(
                  color: Colors.white,
                  elevation: 0,
                  child: Padding(
                    padding:
                    const EdgeInsets.all(8),
                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),

                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFE7F8EC,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: const Icon(
                          Icons
                              .shopping_basket_outlined,
                          color: Color(
                            0xFF38BB62,
                          ),
                        ),
                      ),

                      title: Text(
                        product.item,
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),

                      subtitle: Padding(
                        padding:
                        const EdgeInsets.only(
                          top: 6,
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unit: ${product.unit}',
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                            ),

                            if (!hasPrice) ...[
                              const SizedBox(
                                height: 4,
                              ),

                              Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .warning_amber_rounded,
                                    size: 16,
                                    color:
                                    Colors.orange,
                                  ),

                                  const SizedBox(
                                    width: 4,
                                  ),

                                  Expanded(
                                    child: Text(
                                      'Price Unavailable',
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow
                                          .ellipsis,
                                      style:
                                      const TextStyle(
                                        color:
                                        Colors.orange,
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight
                                            .w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      trailing: FilledButton(
                        onPressed: () {
                          addProduct(
                            product,
                          );
                        },
                        style:
                        FilledButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          minimumSize:
                          const Size(0, 40),
                        ),
                        child: Row(
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            Icon(
                              added
                                  ? Icons.check
                                  : Icons.add,
                              size: 18,
                            ),

                            const SizedBox(
                              width: 5,
                            ),

                            Text(
                              added
                                  ? 'More'
                                  : 'Add',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
