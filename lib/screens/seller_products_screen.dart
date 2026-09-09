import 'package:flutter/material.dart';

import '../services/product_service.dart';
import 'product_detail_screen.dart';

class SellerProductsScreen extends StatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  State<SellerProductsScreen> createState() =>
      SellerProductsScreenState();
}

class SellerProductsScreenState
    extends State<SellerProductsScreen> {
  final ProductService _productService =
  ProductService();

  List<Map<String, dynamic>> _products = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products =
      await _productService.getSellerProducts();

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint(
        'LOAD PRODUCTS ERROR: $e',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load products.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF6F7F6),
      appBar: AppBar(
        title: const Text(
          'My Products',
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: loadProducts,
        child: _isLoading
            ? const Center(
          child:
          CircularProgressIndicator(),
        )
            : _products.isEmpty
            ? ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 250,
            ),
            Icon(
              Icons.inventory_2_outlined,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(
              height: 15,
            ),
            Center(
              child: Text(
                'No products added yet',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        )
            : ListView.separated(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(20),
          itemCount:
          _products.length,
          separatorBuilder:
              (context, index) =>
          const SizedBox(
            height: 12,
          ),
          itemBuilder:
              (context, index) {
            final product =
            _products[index];

            final item =
                product['lookup_item']
                as Map<String,
                    dynamic>? ??
                    {};

            final images =
                product['seller_product_images']
                as List? ??
                    [];

            final imageUrl =
            images.isNotEmpty
                ? images[0]
            ['image_url']
                : null;

            return Card(
              elevation: 0,
              color: Colors.white,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
              ),
              child: InkWell(
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailScreen(
                            productId:
                            product['id'],
                          ),
                    ),
                  );

                  loadProducts();
                },
                child: Padding(
                  padding:
                  const EdgeInsets.all(
                    12,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius:
                        BorderRadius
                            .circular(
                          10,
                        ),
                        child:
                        imageUrl != null
                            ? Image.network(
                          imageUrl,
                          width:
                          85,
                          height:
                          85,
                          fit: BoxFit
                              .cover,
                          errorBuilder:
                              (
                              context,
                              error,
                              stackTrace,
                              ) {
                            return _placeholder();
                          },
                        )
                            : _placeholder(),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              item['item']
                                  ?.toString() ??
                                  'Unknown Product',
                              maxLines: 2,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                              style:
                              const TextStyle(
                                fontSize:
                                16,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              item['unit']
                                  ?.toString() ??
                                  '',
                              style:
                              const TextStyle(
                                color:
                                Colors.grey,
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              'RM ${_formatPrice(product['price'])}',
                              style:
                              const TextStyle(
                                fontSize:
                                17,
                                fontWeight:
                                FontWeight
                                    .bold,
                                color: Color(
                                  0xFF38BB62,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons
                            .chevron_right,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 85,
      height: 85,
      color: const Color(0xFFE8F8ED),
      child: const Icon(
        Icons.image_outlined,
        size: 35,
        color: Color(0xFF38BB62),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    final value =
        double.tryParse(price.toString()) ?? 0;

    return value.toStringAsFixed(2);
  }
}