import 'package:flutter/material.dart';

import '../services/product_service.dart';

class DeletedProductsScreen extends StatefulWidget {
  const DeletedProductsScreen({
    super.key,
  });

  @override
  State<DeletedProductsScreen> createState() =>
      _DeletedProductsScreenState();
}

class _DeletedProductsScreenState
    extends State<DeletedProductsScreen> {
  final ProductService _productService =
  ProductService();

  List<Map<String, dynamic>> _products =
  [];

  bool _isLoading = true;
  int? _restoringProductId;

  @override
  void initState() {
    super.initState();
    _loadDeletedProducts();
  }

  Future<void> _loadDeletedProducts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final products =
      await _productService
          .getDeletedSellerProducts();

      if (!mounted) {
        return;
      }

      setState(() {
        _products = products;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load deleted products: $e',
          ),
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

  Future<void> _confirmRestore(
      Map<String, dynamic> product,
      ) async {
    final item =
    product['lookup_item'] == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(
      product['lookup_item'],
    );

    final productName =
        item['item']?.toString() ??
            'this product';

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Restore Product',
          ),
          content: Text(
            'Restore "$productName" back to My Products?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'CANCEL',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
              FilledButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFF38BB62,
                ),
              ),
              child: const Text(
                'RESTORE',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final productId =
    product['id'] as int;

    await _restoreProduct(
      productId,
    );
  }

  Future<void> _restoreProduct(
      int productId,
      ) async {
    setState(() {
      _restoringProductId =
          productId;
    });

    try {
      await _productService
          .restoreProduct(
        productId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _products.removeWhere(
              (product) =>
          product['id'] ==
              productId,
        );
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Product restored successfully.',
          ),
          backgroundColor:
          Color(
            0xFF38BB62,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to restore product: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _restoringProductId =
          null;
        });
      }
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(
        0xFFF6F7F6,
      ),
      appBar: AppBar(
        title: const Text(
          'Deleted Products',
        ),
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,
      ),
      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh:
        _loadDeletedProducts,
        child:
        _products.isEmpty
            ? ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children:
          const [
            SizedBox(
              height:
              220,
            ),
            Icon(
              Icons
                  .delete_outline,
              size:
              65,
              color:
              Colors.grey,
            ),
            SizedBox(
              height:
              16,
            ),
            Text(
              'No deleted products',
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

            return _buildProductCard(
              product,
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(
      Map<String, dynamic> product,
      ) {
    final item =
    product['lookup_item'] == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(
      product['lookup_item'],
    );

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

    final productName =
        item['item']?.toString() ??
            'Unknown Product';

    final unit =
    item['unit']?.toString();

    final price =
        double.tryParse(
          product['price'].toString(),
        ) ??
            0;

    final productId =
    product['id'] as int;

    final isRestoring =
        _restoringProductId ==
            productId;

    return Card(
      elevation: 1,
      color: Colors.white,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(
          12,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
              BorderRadius.circular(
                10,
              ),
              child: Container(
                width: 85,
                height: 85,
                color:
                const Color(
                  0xFFF1F1F1,
                ),
                child: imageUrl != null &&
                    imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit:
                  BoxFit.cover,
                  errorBuilder:
                      (
                      context,
                      error,
                      stackTrace,
                      ) {
                    return const Icon(
                      Icons
                          .image_not_supported_outlined,
                      color:
                      Colors.grey,
                    );
                  },
                )
                    : const Icon(
                  Icons
                      .inventory_2_outlined,
                  size: 36,
                  color:
                  Colors.grey,
                ),
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize:
                      16,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                  if (unit != null &&
                      unit.isNotEmpty) ...[
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      unit,
                      style:
                      const TextStyle(
                        fontSize:
                        12,
                        color:
                        Colors.grey,
                      ),
                    ),
                  ],
                  const SizedBox(
                    height: 7,
                  ),
                  Text(
                    'RM ${price.toStringAsFixed(2)}',
                    style:
                    const TextStyle(
                      fontSize:
                      16,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      Color(
                        0xFF38BB62,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            isRestoring
                ? const SizedBox(
              width: 24,
              height: 24,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : IconButton(
              onPressed: () {
                _confirmRestore(
                  product,
                );
              },
              tooltip:
              'Restore',
              icon:
              const Icon(
                Icons
                    .restore_outlined,
                color:
                Color(
                  0xFF38BB62,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
