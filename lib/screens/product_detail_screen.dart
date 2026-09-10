import 'package:flutter/material.dart';

import '../services/product_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends State<ProductDetailScreen> {
  final ProductService _productService =
  ProductService();

  Map<String, dynamic>? _product;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final product =
      await _productService.getProductDetails(
        widget.productId,
      );

      if (!mounted) return;

      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'PRODUCT DETAILS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load product details.',
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
          'Product Details',
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _product == null
          ? const Center(
        child: Text(
          'Product not found',
        ),
      )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final item =
        _product!['lookup_item']
        as Map<String, dynamic>? ??
            {};

    final premise =
        _product!['lookup_premise']
        as Map<String, dynamic>? ??
            {};

    final images =
        _product!['seller_product_images']
        as List? ??
            [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          if (images.isNotEmpty)
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (
                    context,
                    index,
                    ) {
                  return ClipRRect(
                    borderRadius:
                    BorderRadius.circular(
                      15,
                    ),
                    child: Image.network(
                      images[index]
                      ['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (
                          context,
                          error,
                          stackTrace,
                          ) {
                        return _imagePlaceholder();
                      },
                    ),
                  );
                },
              ),
            )
          else
            _imagePlaceholder(),
          const SizedBox(
            height: 25,
          ),
          Text(
            item['item']?.toString() ??
                'Unknown Product',
            style: const TextStyle(
              fontSize: 24,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            'RM ${_formatPrice(_product!['price'])}',
            style: const TextStyle(
              fontSize: 25,
              fontWeight:
              FontWeight.bold,
              color:
              Color(0xFF38BB62),
            ),
          ),
          const SizedBox(
            height: 25,
          ),
          _informationCard(
            title:
            'Product Information',
            children: [
              _row(
                'Item Code',
                _product!['item_code']
                    .toString(),
              ),
              _row(
                'Unit',
                item['unit']
                    ?.toString() ??
                    '-',
              ),
              _row(
                'Group',
                item['item_group']
                    ?.toString() ??
                    '-',
              ),
              _row(
                'Category',
                item['item_category']
                    ?.toString() ??
                    '-',
              ),
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          _informationCard(
            title:
            'Premise Information',
            children: [
              _row(
                'Premise',
                premise['premise']
                    ?.toString() ??
                    '-',
              ),
              _row(
                'Type',
                premise['premise_type']
                    ?.toString() ??
                    '-',
              ),
              _row(
                'Address',
                premise['address']
                    ?.toString() ??
                    '-',
              ),
              _row(
                'District',
                premise['district']
                    ?.toString() ??
                    '-',
              ),
              _row(
                'State',
                premise['state']
                    ?.toString() ??
                    '-',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color:
        const Color(0xFFE8F8ED),
        borderRadius:
        BorderRadius.circular(
          15,
        ),
      ),
      child: const Icon(
        Icons.image_outlined,
        size: 70,
        color:
        Color(0xFF38BB62),
      ),
    );
  }

  Widget _informationCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          15,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
            const TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const Divider(
            height: 25,
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _row(
      String title,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style:
              const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(
      dynamic price,
      ) {
    final value =
        double.tryParse(
          price.toString(),
        ) ??
            0;

    return value.toStringAsFixed(
      2,
    );
  }
}