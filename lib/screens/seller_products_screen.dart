import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/local_database_service.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';

class SellerProductsScreen
    extends StatefulWidget {
  const SellerProductsScreen({
    super.key,
  });

  @override
  State<SellerProductsScreen>
  createState() =>
      SellerProductsScreenState();
}

class SellerProductsScreenState
    extends State<SellerProductsScreen> {
  final ProductService _productService =
  ProductService();

  List<Map<String, dynamic>> _products =
  [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final currentUser =
        Supabase.instance.client.auth
            .currentUser;

    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      return;
    }

    try {
      final products =
      await _productService
          .getSellerProducts();

      final List<Map<String, dynamic>>
      cacheRows = [];

      for (final product in products) {
        Map<String, dynamic>? item;

        if (product['lookup_item'] !=
            null) {
          item =
          Map<String, dynamic>.from(
            product['lookup_item'],
          );
        }

        final images =
            product[
            'seller_product_images']
            as List<dynamic>? ??
                [];

        String? imageUrl;

        if (images.isNotEmpty) {
          final firstImage =
          Map<String, dynamic>.from(
            images.first,
          );

          imageUrl =
              firstImage['image_url']
                  ?.toString();
        }

        cacheRows.add({
          'id':
          product['id'],
          'seller_id':
          currentUser.id,
          'premise_code':
          product[
          'premise_code'],
          'item_code':
          product[
          'item_code'],
          'item_name':
          item?['item']
              ?.toString() ??
              'Unknown Product',
          'unit':
          item?['unit']
              ?.toString(),
          'item_group':
          item?['item_group']
              ?.toString(),
          'item_category':
          item?['item_category']
              ?.toString(),
          'price':
          (product['price']
          as num)
              .toDouble(),
          'image_url':
          imageUrl,
          'created_at':
          product['created_at']
              ?.toString(),
          'synced_at':
          DateTime.now()
              .toIso8601String(),
        });
      }

      await LocalDatabaseService
          .instance
          .clearSellerProductCache(
        currentUser.id,
      );

      await LocalDatabaseService
          .instance
          .cacheSellerProducts(
        cacheRows,
      );

      if (!mounted) return;

      setState(() {
        _products =
            cacheRows;
      });
    } catch (e) {
      debugPrint(
        'LOAD PRODUCTS ERROR: $e',
      );

      final cachedProducts =
      await LocalDatabaseService
          .instance
          .getCachedSellerProducts(
        currentUser.id,
      );

      if (!mounted) return;

      setState(() {
        _products =
            cachedProducts;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            cachedProducts.isEmpty
                ? 'Unable to load products: $e'
                : 'Unable to connect to Supabase. Showing saved products.',
          ),
          backgroundColor:
          Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openProduct(
      Map<String, dynamic> product,
      ) async {
    final productId =
    product['id'];

    if (productId == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailScreen(
              productId:
              productId as int,
            ),
      ),
    );

    await loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(
        0xFFF7F7F7,
      ),
      appBar: AppBar(
        automaticallyImplyLeading:
        false,
        title:
        const Text(
          'My Products',
        ),
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh:
        loadProducts,
        child:
        _products.isEmpty
            ? ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children:
          const [
            SizedBox(
              height:
              230,
            ),
            Icon(
              Icons
                  .inventory_2_outlined,
              size: 62,
              color:
              Colors.grey,
            ),
            SizedBox(
              height:
              18,
            ),
            Text(
              'No products added yet',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                fontSize:
                16,
                color:
                Colors.grey,
              ),
            ),
          ],
        )
            : ListView.separated(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(
            16,
          ),
          itemCount:
          _products.length,
          separatorBuilder:
              (
              context,
              index,
              ) =>
          const SizedBox(
            height:
            12,
          ),
          itemBuilder:
              (
              context,
              index,
              ) {
            final product =
            _products[
            index];

            final imageUrl =
            product[
            'image_url']
                ?.toString();

            final productName =
                product[
                'item_name']
                    ?.toString() ??
                    'Unknown Product';

            final unit =
            product[
            'unit']
                ?.toString();

            final price =
                (product[
                'price']
                as num?)
                    ?.toDouble() ??
                    0;

            return Card(
              color:
              Colors.white,
              elevation:
              1,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
              ),
              child:
              InkWell(
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
                onTap:
                    () {
                  _openProduct(
                    product,
                  );
                },
                child:
                Padding(
                  padding:
                  const EdgeInsets.all(
                    12,
                  ),
                  child:
                  Row(
                    children:
                    [
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(
                          10,
                        ),
                        child:
                        Container(
                          width:
                          85,
                          height:
                          85,
                          color:
                          const Color(
                            0xFFF1F1F1,
                          ),
                          child:
                          imageUrl != null &&
                              imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                                context,
                                error,
                                stackTrace,
                                ) {
                              return const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              );
                            },
                          )
                              : const Icon(
                            Icons.inventory_2_outlined,
                            size: 36,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width:
                        14,
                      ),
                      Expanded(
                        child:
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children:
                          [
                            Text(
                              productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(
                                  0xFF333632,
                                ),
                              ),
                            ),
                            if (unit != null &&
                                unit.isNotEmpty) ...[
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                unit,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              'RM ${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(
                                  0xFF38BB62,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color:
                        Colors.grey,
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
}