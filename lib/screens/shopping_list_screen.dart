import 'package:flutter/material.dart';

import '../services/shopping_cart_service.dart';
import 'recommendation_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() =>
      _ShoppingListScreenState();
}

class _ShoppingListScreenState
    extends State<ShoppingListScreen> {
  final ShoppingCartService cart =
      ShoppingCartService.instance;

  @override
  void initState() {
    super.initState();

    cart.addListener(refresh);
  }

  @override
  void dispose() {
    cart.removeListener(refresh);

    super.dispose();
  }

  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> updateCart(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save shopping list: $e')),
      );
    }
  }

  void confirmClearCart() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Clear Shopping List?',
          ),
          content: const Text(
            'All products will be removed from your shopping list.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                updateCart(cart.clearCart);

                Navigator.pop(context);
              },
              child: const Text(
                'Clear',
              ),
            ),
          ],
        );
      },
    );
  }

  void compareStores() {
    if (cart.items.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const RecommendationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = cart.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),

      appBar: AppBar(
        backgroundColor: Colors.white,

        title: const Text(
          'Shopping List',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Clear List',
              icon: const Icon(
                Icons.delete_sweep_outlined,
              ),
              onPressed: confirmClearCart,
            ),

          const SizedBox(width: 8),
        ],
      ),

      body: items.isEmpty
          ? const EmptyShoppingList()
          : Column(
        children: [
          Expanded(
            child: ListView(
              padding:
              const EdgeInsets.all(20),
              children: [
                const Text(
                  'My Grocery List',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${cart.totalUniqueItems} different products • '
                      '${cart.totalQuantity} total quantity',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 20),

                ...items.map(
                      (cartItem) {
                    final product =
                        cartItem.product;

                    return Padding(
                      padding:
                      const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: Card(
                        color: Colors.white,
                        elevation: 0,
                        child: Padding(
                          padding:
                          const EdgeInsets.all(
                            14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration:
                                BoxDecoration(
                                  color:
                                  const Color(
                                    0xFFE7F8EC,
                                  ),
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    14,
                                  ),
                                ),
                                child:
                                const Icon(
                                  Icons
                                      .shopping_basket_outlined,
                                  color: Color(
                                    0xFF38BB62,
                                  ),
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
                                      product.item,
                                      style:
                                      const TextStyle(
                                        fontWeight:
                                        FontWeight
                                            .w600,
                                        fontSize: 15,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Text(
                                      'Unit: ${product.unit}',
                                      style:
                                      const TextStyle(
                                        color:
                                        Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Row(
                                children: [
                                  IconButton(
                                    tooltip:
                                    'Decrease',
                                    onPressed: () {
                                      updateCart(() => cart.decreaseQuantity(product.itemCode));
                                    },
                                    icon: const Icon(
                                      Icons
                                          .remove_circle_outline,
                                    ),
                                  ),

                                  Container(
                                    constraints:
                                    const BoxConstraints(
                                      minWidth: 32,
                                    ),
                                    alignment:
                                    Alignment
                                        .center,
                                    child: Text(
                                      '${cartItem.quantity}',
                                      style:
                                      const TextStyle(
                                        fontSize: 17,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),
                                  ),

                                  IconButton(
                                    tooltip:
                                    'Increase',
                                    onPressed: () {
                                      updateCart(() => cart.increaseQuantity(product.itemCode));
                                    },
                                    icon: const Icon(
                                      Icons
                                          .add_circle_outline,
                                      color: Color(
                                        0xFF38BB62,
                                      ),
                                    ),
                                  ),

                                  IconButton(
                                    tooltip:
                                    'Remove',
                                    onPressed: () {
                                      updateCart(() => cart.removeProduct(product.itemCode));
                                    },
                                    icon: const Icon(
                                      Icons
                                          .delete_outline,
                                      color:
                                      Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom Compare Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: compareStores,
                  icon: const Icon(
                    Icons.compare_arrows,
                  ),
                  label: const Text(
                    'Compare & Suggest Store',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyShoppingList extends StatelessWidget {
  const EmptyShoppingList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFE7F8EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 52,
                color: Color(0xFF38BB62),
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Your shopping list is empty',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Add some groceries before comparing store prices.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 22),

            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.shopping_basket_outlined,
              ),
              label: const Text(
                'Browse Products',
              ),
            ),
          ],
        ),
      ),
    );
  }
}