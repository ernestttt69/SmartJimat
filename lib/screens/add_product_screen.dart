import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  final VoidCallback? onProductAdded;

  const AddProductScreen({
    super.key,
    this.onProductAdded,
  });

  @override
  State<AddProductScreen> createState() =>
      _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ProductService _productService = ProductService();

  final TextEditingController _priceController =
  TextEditingController();

  final TextEditingController _productController =
  TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  List<Map<String, dynamic>> _items = [];
  List<File> _selectedImages = [];

  int? _selectedItemCode;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _productService.getItems();

      if (!mounted) return;

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
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

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum 5 images allowed',
          ),
        ),
      );
      return;
    }

    final images = await _imagePicker.pickMultiImage(
      imageQuality: 80,
    );

    if (images.isEmpty) return;

    final remainingSlots =
        5 - _selectedImages.length;

    final selectedFiles = images
        .take(remainingSlots)
        .map(
          (image) => File(image.path),
    )
        .toList();

    if (!mounted) return;

    setState(() {
      _selectedImages.addAll(selectedFiles);
    });

    if (images.length > remainingSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum 5 images allowed',
          ),
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _showProductSelector() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No products available',
          ),
        ),
      );
      return;
    }

    final selected =
    await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return ProductSelectionSheet(
          items: _items,
        );
      },
    );

    if (selected == null) return;

    final itemCode = selected['item_code'];

    setState(() {
      _selectedItemCode = itemCode is int
          ? itemCode
          : int.parse(
        itemCode.toString(),
      );

      _productController.text =
      '${selected['item']} (${selected['unit'] ?? ''})';
    });
  }

  Future<void> _saveProduct() async {
    if (_selectedItemCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a product.',
          ),
        ),
      );
      return;
    }

    final price = double.tryParse(
      _priceController.text.trim(),
    );

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid selling price.',
          ),
        ),
      );
      return;
    }

    if (price > 99999.99) {
      ScaffoldMessenger.of(context).showSnackBar(
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
      await _productService.addProduct(
        itemCode: _selectedItemCode!,
        price: price,
        imageFiles: _selectedImages,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product added successfully.',
          ),
        ),
      );

      setState(() {
        _selectedItemCode = null;
        _selectedImages.clear();
        _productController.clear();
        _priceController.clear();
      });

      widget.onProductAdded?.call();
    } catch (e) {
      debugPrint(
        'ADD PRODUCT ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
          duration:
          const Duration(seconds: 8),
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

  @override
  void dispose() {
    _priceController.dispose();
    _productController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF6F7F6),
      appBar: AppBar(
        title: const Text(
          'Add Product',
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
          : SafeArea(
        child:
        SingleChildScrollView(
          padding:
          const EdgeInsets.all(
            20,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              const Text(
                'Product Images',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                '${_selectedImages.length}/5 images selected',
                style:
                const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              if (_selectedImages
                  .isEmpty)
                GestureDetector(
                  onTap:
                  _pickImages,
                  child: Container(
                    width:
                    double.infinity,
                    height: 190,
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.white,
                      borderRadius:
                      BorderRadius
                          .circular(
                        14,
                      ),
                      border:
                      Border.all(
                        color: Colors
                            .grey
                            .shade300,
                      ),
                    ),
                    child:
                    const Column(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                      children: [
                        Icon(
                          Icons
                              .add_photo_alternate_outlined,
                          size: 55,
                          color: Color(
                            0xFF38BB62,
                          ),
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        Text(
                          'Select Product Images',
                          style:
                          TextStyle(
                            fontSize:
                            16,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Optional • Maximum 5 images',
                          style:
                          TextStyle(
                            color: Colors
                                .grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      height: 145,
                      child:
                      ListView
                          .separated(
                        scrollDirection:
                        Axis
                            .horizontal,
                        itemCount:
                        _selectedImages
                            .length,
                        separatorBuilder:
                            (
                            context,
                            index,
                            ) =>
                        const SizedBox(
                          width: 12,
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
                                BorderRadius
                                    .circular(
                                  12,
                                ),
                                child:
                                Image.file(
                                  _selectedImages[
                                  index],
                                  width:
                                  145,
                                  height:
                                  145,
                                  fit: BoxFit
                                      .cover,
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child:
                                GestureDetector(
                                  onTap:
                                      () {
                                    _removeImage(
                                      index,
                                    );
                                  },
                                  child:
                                  const CircleAvatar(
                                    radius:
                                    15,
                                    backgroundColor:
                                    Colors
                                        .black54,
                                    child:
                                    Icon(
                                      Icons
                                          .close,
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
                    const SizedBox(
                      height: 12,
                    ),
                    if (_selectedImages
                        .length <
                        5)
                      SizedBox(
                        width:
                        double.infinity,
                        height: 48,
                        child:
                        OutlinedButton
                            .icon(
                          onPressed:
                          _pickImages,
                          icon:
                          const Icon(
                            Icons
                                .add_photo_alternate_outlined,
                          ),
                          label:
                          const Text(
                            'ADD MORE IMAGES',
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(
                height: 30,
              ),
              const Text(
                'Product Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              TextFormField(
                controller:
                _productController,
                readOnly: true,
                onTap:
                _showProductSelector,
                decoration:
                InputDecoration(
                  labelText:
                  'Product',
                  hintText:
                  'Select Product',
                  prefixIcon:
                  const Icon(
                    Icons
                        .shopping_bag_outlined,
                  ),
                  suffixIcon:
                  const Icon(
                    Icons
                        .arrow_drop_down,
                  ),
                  filled: true,
                  fillColor:
                  Colors.white,
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              TextField(
                controller: _priceController,
                keyboardType:
                const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(
                      r'^\d{0,5}(\.\d{0,2})?',
                    ),
                  ),
                ],
                decoration: InputDecoration(
                  labelText: 'Selling Price',
                  hintText: '0.00',
                  prefixText: 'RM ',
                  prefixIcon: const Icon(
                    Icons.payments_outlined,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              SizedBox(
                width:
                double.infinity,
                height: 55,
                child:
                FilledButton.icon(
                  onPressed:
                  _isSaving
                      ? null
                      : _saveProduct,
                  icon: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                    ),
                  )
                      : const Icon(
                    Icons
                        .add_circle_outline,
                  ),
                  label: Text(
                    _isSaving
                        ? 'ADDING PRODUCT...'
                        : 'ADD PRODUCT',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight
                          .w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductSelectionSheet
    extends StatefulWidget {
  final List<Map<String, dynamic>>
  items;

  const ProductSelectionSheet({
    super.key,
    required this.items,
  });

  @override
  State<ProductSelectionSheet>
  createState() =>
      _ProductSelectionSheetState();
}

class _ProductSelectionSheetState
    extends State<
        ProductSelectionSheet> {
  final TextEditingController
  _searchController =
  TextEditingController();

  late List<Map<String, dynamic>>
  _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems =
        widget.items;
  }

  void _search(String value) {
    final query =
    value.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredItems =
            widget.items;
      } else {
        _filteredItems =
            widget.items.where(
                  (item) {
                final name =
                    item['item']
                        ?.toString()
                        .toLowerCase() ??
                        '';

                final unit =
                    item['unit']
                        ?.toString()
                        .toLowerCase() ??
                        '';

                final category =
                    item['item_category']
                        ?.toString()
                        .toLowerCase() ??
                        '';

                return name
                    .contains(
                  query,
                ) ||
                    unit.contains(
                      query,
                    ) ||
                    category.contains(
                      query,
                    );
              },
            ).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController
        .dispose();
    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom:
          MediaQuery.of(context)
              .viewInsets
              .bottom +
              20,
        ),
        child: SizedBox(
          height:
          MediaQuery.of(context)
              .size
              .height *
              0.75,
          child: Column(
            children: [
              Container(
                width: 45,
                height: 5,
                decoration:
                BoxDecoration(
                  color: Colors
                      .grey.shade300,
                  borderRadius:
                  BorderRadius
                      .circular(
                    10,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Select Product',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              TextField(
                controller:
                _searchController,
                onChanged: _search,
                decoration:
                InputDecoration(
                  hintText:
                  'Search product...',
                  prefixIcon:
                  const Icon(
                    Icons.search,
                  ),
                  suffixIcon:
                  IconButton(
                    onPressed:
                        () {
                      _searchController
                          .clear();

                      _search('');
                    },
                    icon:
                    const Icon(
                      Icons.clear,
                    ),
                  ),
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Expanded(
                child:
                _filteredItems
                    .isEmpty
                    ? const Center(
                  child:
                  Text(
                    'No products found',
                  ),
                )
                    : ListView
                    .separated(
                  itemCount:
                  _filteredItems
                      .length,
                  separatorBuilder:
                      (
                      context,
                      index,
                      ) =>
                  const Divider(
                    height: 1,
                  ),
                  itemBuilder:
                      (
                      context,
                      index,
                      ) {
                    final item =
                    _filteredItems[
                    index];

                    return ListTile(
                      leading:
                      const CircleAvatar(
                        backgroundColor:
                        Color(
                          0xFFE8F8ED,
                        ),
                        child:
                        Icon(
                          Icons
                              .shopping_bag_outlined,
                          color:
                          Color(
                            0xFF38BB62,
                          ),
                        ),
                      ),
                      title:
                      Text(
                        item['item']
                            ?.toString() ??
                            'Unknown Product',
                      ),
                      subtitle:
                      Text(
                        '${item['unit'] ?? ''}'
                            '${item['item_category'] != null ? ' • ${item['item_category']}' : ''}',
                      ),
                      onTap:
                          () {
                        Navigator.pop(
                          context,
                          item,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
