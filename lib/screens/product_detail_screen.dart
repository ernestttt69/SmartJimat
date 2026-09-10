import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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

  final TextEditingController
  _priceController =
  TextEditingController();

  final ImagePicker _imagePicker =
  ImagePicker();

  Map<String, dynamic>? _product;

  final List<File> _newImages =
  [];

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final product =
      await _productService
          .getProductDetails(
        widget.productId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _product = product;

        _priceController.text =
            _formatPrice(
              product['price'],
            );

        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'PRODUCT DETAILS ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load product details: $e',
          ),
        ),
      );
    }
  }

  void _startEditing() {
    if (_product == null) {
      return;
    }

    setState(() {
      _priceController.text =
          _formatPrice(
            _product!['price'],
          );

      _newImages.clear();
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    if (_product == null) {
      return;
    }

    setState(() {
      _priceController.text =
          _formatPrice(
            _product!['price'],
          );

      _newImages.clear();
      _isEditing = false;
    });
  }

  Future<void> _pickImages() async {
    final existingImages =
        _product?[
        'seller_product_images']
        as List<dynamic>? ??
            [];

    final remaining =
        5 -
            existingImages.length -
            _newImages.length;

    if (remaining <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum 5 product images allowed.',
          ),
        ),
      );

      return;
    }

    try {
      final pickedImages =
      await _imagePicker
          .pickMultiImage(
        imageQuality: 85,
      );

      if (pickedImages.isEmpty) {
        return;
      }

      final selectedImages =
      pickedImages
          .take(remaining)
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _newImages.addAll(
          selectedImages.map(
                (image) =>
                File(image.path),
          ),
        );
      });

      if (pickedImages.length >
          remaining) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Only $remaining more image(s) can be added.',
            ),
          ),
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
            'Unable to select images: $e',
          ),
        ),
      );
    }
  }

  void _removeNewImage(
      int index,
      ) {
    setState(() {
      _newImages.removeAt(
        index,
      );
    });
  }

  Future<void> _saveChanges() async {
    final price =
    double.tryParse(
      _priceController.text.trim(),
    );

    if (price == null ||
        price <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid price.',
          ),
        ),
      );

      return;
    }

    if (price > 99999.99) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Price cannot exceed RM 99,999.99.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _productService
          .updateProduct(
        productId:
        widget.productId,
        price:
        price,
        newImageFiles:
        _newImages,
      );

      _newImages.clear();

      await _loadProduct();

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Product updated successfully.',
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
            'Unable to update product: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (
          context,
          ) {
        return AlertDialog(
          title:
          const Text(
            'Delete Product',
          ),
          content:
          const Text(
            'Are you sure you want to delete this product? You can restore it later from Deleted Products.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
              const Text(
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
                Colors.red,
              ),
              child:
              const Text(
                'DELETE',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _deleteProduct();
  }

  Future<void> _deleteProduct() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await _productService
          .softDeleteProduct(
        widget.productId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Product deleted successfully.',
          ),
          backgroundColor:
          Color(
            0xFF38BB62,
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete product: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
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
        title:
        const Text(
          'Product Details',
        ),
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,
        actions: [
          if (!_isLoading &&
              _product != null &&
              !_isEditing)
            IconButton(
              onPressed:
              _startEditing,
              icon:
              const Icon(
                Icons.edit_outlined,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _product == null
          ? const Center(
        child:
        Text(
          'Product not found',
        ),
      )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final item =
    _product!['lookup_item'] ==
        null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(
      _product![
      'lookup_item'],
    );

    final premise =
    _product![
    'lookup_premise'] ==
        null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(
      _product![
      'lookup_premise'],
    );

    final images =
        _product![
        'seller_product_images']
        as List<dynamic>? ??
            [];

    return SingleChildScrollView(
      padding:
      const EdgeInsets.all(
        20,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _buildImagesSection(
            images,
          ),
          const SizedBox(
            height: 25,
          ),
          Text(
            item['item']
                ?.toString() ??
                'Unknown Product',
            style:
            const TextStyle(
              fontSize: 24,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          if (!_isEditing)
            Text(
              'RM ${_formatPrice(_product!['price'])}',
              style:
              const TextStyle(
                fontSize: 25,
                fontWeight:
                FontWeight.bold,
                color:
                Color(
                  0xFF38BB62,
                ),
              ),
            ),
          if (_isEditing)
            _buildEditSection(),
          const SizedBox(
            height: 25,
          ),
          _informationCard(
            title:
            'Product Information',
            children: [
              _row(
                'Item Code',
                _product![
                'item_code']
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
                item[
                'item_category']
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
                premise[
                'premise_type']
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
          const SizedBox(
            height: 25,
          ),
          if (!_isEditing)
            SizedBox(
              width:
              double.infinity,
              height: 52,
              child:
              OutlinedButton.icon(
                onPressed:
                _isDeleting
                    ? null
                    : _confirmDelete,
                style:
                OutlinedButton.styleFrom(
                  foregroundColor:
                  Colors.red,
                  side:
                  const BorderSide(
                    color:
                    Colors.red,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                icon:
                _isDeleting
                    ? const SizedBox(
                  width:
                  20,
                  height:
                  20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth:
                    2,
                  ),
                )
                    : const Icon(
                  Icons
                      .delete_outline,
                ),
                label:
                const Text(
                  'DELETE PRODUCT',
                ),
              ),
            ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection(
      List<dynamic> images,
      ) {
    final totalImages =
        images.length +
            _newImages.length;

    if (_isEditing) {
      return InkWell(
        onTap: _isSaving ||
            totalImages >= 5
            ? null
            : _pickImages,
        borderRadius:
        BorderRadius.circular(
          15,
        ),
        child:
        Container(
          width:
          double.infinity,
          height: 250,
          decoration:
          BoxDecoration(
            color:
            const Color(
              0xFFE8F8ED,
            ),
            borderRadius:
            BorderRadius.circular(
              15,
            ),
            border:
            Border.all(
              color:
              const Color(
                0xFF38BB62,
              ),
            ),
          ),
          child: images.isEmpty &&
              _newImages.isEmpty
              ? const Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons
                    .add_photo_alternate_outlined,
                size: 65,
                color:
                Color(
                  0xFF38BB62,
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Text(
                'Tap to add product images',
                style:
                TextStyle(
                  color:
                  Color(
                    0xFF38BB62,
                  ),
                  fontSize:
                  15,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                'Optional · Maximum 5 images',
                style:
                TextStyle(
                  color:
                  Colors.grey,
                  fontSize:
                  12,
                ),
              ),
            ],
          )
              : Stack(
            children: [
              Positioned.fill(
                child:
                ClipRRect(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                  child:
                  _buildEditPreviewImage(
                    images,
                  ),
                ),
              ),
              Positioned.fill(
                child:
                Container(
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.black.withValues(
                      alpha:
                      0.25,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      15,
                    ),
                  ),
                ),
              ),
              Center(
                child:
                Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons
                          .add_photo_alternate_outlined,
                      size: 45,
                      color:
                      Colors.white,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      totalImages >= 5
                          ? 'Maximum 5 images'
                          : 'Tap to add more images',
                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize:
                        15,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      '$totalImages of 5 images',
                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize:
                        12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (images.isEmpty) {
      return _imagePlaceholder();
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child:
          PageView.builder(
            itemCount:
            images.length,
            itemBuilder:
                (
                context,
                index,
                ) {
              final image =
              Map<String, dynamic>.from(
                images[index],
              );

              final imageUrl =
                  image['image_url']
                      ?.toString() ??
                      '';

              return ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  15,
                ),
                child:
                Image.network(
                  imageUrl,
                  width:
                  double.infinity,
                  fit:
                  BoxFit.cover,
                  errorBuilder:
                      (
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
        ),
        if (images.length > 1) ...[
          const SizedBox(
            height: 10,
          ),
          Text(
            '${images.length} images',
            style:
            const TextStyle(
              fontSize: 13,
              color:
              Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditPreviewImage(
      List<dynamic> existingImages,
      ) {
    if (_newImages.isNotEmpty) {
      return Image.file(
        _newImages.last,
        width:
        double.infinity,
        height: 250,
        fit:
        BoxFit.cover,
      );
    }

    if (existingImages.isNotEmpty) {
      final image =
      Map<String, dynamic>.from(
        existingImages.first,
      );

      final imageUrl =
          image['image_url']
              ?.toString() ??
              '';

      return Image.network(
        imageUrl,
        width:
        double.infinity,
        height: 250,
        fit:
        BoxFit.cover,
        errorBuilder:
            (
            context,
            error,
            stackTrace,
            ) {
          return _imagePlaceholder();
        },
      );
    }

    return _imagePlaceholder();
  }

  Widget _buildEditSection() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: 20,
        ),
        const Text(
          'Edit Product',
          style:
          TextStyle(
            fontSize: 22,
            fontWeight:
            FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 18,
        ),
        TextFormField(
          controller:
          _priceController,
          keyboardType:
          const TextInputType
              .numberWithOptions(
            decimal: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter
                .allow(
              RegExp(
                r'^\d{0,5}(\.\d{0,2})?',
              ),
            ),
          ],
          decoration:
          InputDecoration(
            labelText:
            'Price',
            prefixText:
            'RM ',
            prefixIcon:
            const Icon(
              Icons.payments_outlined,
            ),
            filled: true,
            fillColor:
            Colors.white,
            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
          ),
        ),
        if (_newImages.isNotEmpty) ...[
          const SizedBox(
            height: 22,
          ),
          const Text(
            'New Images',
            style:
            TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          const Text(
            'Tap the X to remove an image before saving.',
            style:
            TextStyle(
              fontSize: 12,
              color:
              Colors.grey,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          SizedBox(
            height: 105,
            child:
            ListView.separated(
              scrollDirection:
              Axis.horizontal,
              itemCount:
              _newImages.length,
              separatorBuilder:
                  (
                  context,
                  index,
                  ) =>
              const SizedBox(
                width: 10,
              ),
              itemBuilder:
                  (
                  context,
                  index,
                  ) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                      child:
                      Image.file(
                        _newImages[index],
                        width:
                        100,
                        height:
                        100,
                        fit:
                        BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child:
                      InkWell(
                        onTap:
                        _isSaving
                            ? null
                            : () {
                          _removeNewImage(
                            index,
                          );
                        },
                        child:
                        Container(
                          padding:
                          const EdgeInsets.all(
                            4,
                          ),
                          decoration:
                          const BoxDecoration(
                            color:
                            Colors.black54,
                            shape:
                            BoxShape.circle,
                          ),
                          child:
                          const Icon(
                            Icons.close,
                            size:
                            17,
                            color:
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
        const SizedBox(
          height: 22,
        ),
        Row(
          children: [
            Expanded(
              child:
              OutlinedButton(
                onPressed:
                _isSaving
                    ? null
                    : _cancelEditing,
                style:
                OutlinedButton.styleFrom(
                  minimumSize:
                  const Size(
                    double.infinity,
                    50,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                child:
                const Text(
                  'CANCEL',
                ),
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child:
              FilledButton(
                onPressed:
                _isSaving
                    ? null
                    : _saveChanges,
                style:
                FilledButton.styleFrom(
                  backgroundColor:
                  const Color(
                    0xFF38BB62,
                  ),
                  minimumSize:
                  const Size(
                    double.infinity,
                    50,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                child:
                _isSaving
                    ? const SizedBox(
                  width:
                  20,
                  height:
                  20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth:
                    2,
                    color:
                    Colors.white,
                  ),
                )
                    : const Text(
                  'SAVE',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width:
      double.infinity,
      height: 250,
      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFFE8F8ED,
        ),
        borderRadius:
        BorderRadius.circular(
          15,
        ),
      ),
      child:
      const Icon(
        Icons.image_outlined,
        size: 70,
        color:
        Color(
          0xFF38BB62,
        ),
      ),
    );
  }

  Widget _informationCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        20,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          15,
        ),
      ),
      child:
      Column(
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
      child:
      Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child:
            Text(
              title,
              style:
              const TextStyle(
                color:
                Colors.grey,
              ),
            ),
          ),
          Expanded(
            child:
            Text(
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
