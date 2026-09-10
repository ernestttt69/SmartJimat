import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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
  final ProductService _productService =
  ProductService();

  final TextEditingController _productNameController =
  TextEditingController();

  final TextEditingController _unitController =
  TextEditingController();

  final TextEditingController _categoryController =
  TextEditingController();

  final TextEditingController _priceController =
  TextEditingController();

  final FocusNode _productNameFocusNode =
  FocusNode();

  final ImagePicker _imagePicker =
  ImagePicker();

  List<Map<String, dynamic>> _items = [];
  List<File> _selectedImages = [];

  int? _matchedItemCode;
  String? _matchedItemGroup;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isCheckingProduct = false;
  bool _productChecked = false;
  bool _productMatched = false;

  bool get _canEditManualFields {
    return _productChecked &&
        !_productMatched;
  }

  @override
  void initState() {
    super.initState();

    _loadItems();

    _productNameController.addListener(
      _onProductNameChanged,
    );
  }

  Future<void> _loadItems() async {
    try {
      final items =
      await _productService.getItems();

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load PriceCatcher products: $e',
          ),
        ),
      );
    }
  }

  void _onProductNameChanged() {
    if (!_productChecked &&
        !_productMatched) {
      return;
    }

    setState(() {
      _productChecked = false;
      _productMatched = false;
      _matchedItemCode = null;
      _matchedItemGroup = null;

      _unitController.clear();
      _categoryController.clear();
    });
  }

  String _normalizeText(
      String value,
      ) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
  }

  void _selectMatchedItem(
      Map<String, dynamic> item,
      ) {
    final itemCode =
    item['item_code'];

    _productNameController.removeListener(
      _onProductNameChanged,
    );

    setState(() {
      _productChecked = true;
      _productMatched = true;

      _matchedItemCode =
      itemCode is int
          ? itemCode
          : int.tryParse(
        itemCode.toString(),
      );

      _matchedItemGroup =
          item['item_group']
              ?.toString();

      _productNameController.text =
          item['item']
              ?.toString() ??
              '';

      _unitController.text =
          item['unit']
              ?.toString() ??
              '';

      _categoryController.text =
          item['item_category']
              ?.toString() ??
              '';
    });

    _productNameController.addListener(
      _onProductNameChanged,
    );

    _productNameFocusNode.unfocus();
  }

  Future<void> _checkProduct() async {
    final productName =
    _productNameController.text.trim();

    if (productName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a product name.',
          ),
        ),
      );

      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PriceCatcher product data is not available.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isCheckingProduct = true;
    });

    try {
      final normalizedInput =
      _normalizeText(
        productName,
      );

      final exactMatches =
      _items.where(
            (item) {
          final databaseName =
          _normalizeText(
            item['item']
                ?.toString() ??
                '',
          );

          return databaseName ==
              normalizedInput;
        },
      ).toList();

      if (!mounted) {
        return;
      }

      if (exactMatches.isEmpty) {
        setState(() {
          _productChecked = true;
          _productMatched = false;
          _matchedItemCode = null;
          _matchedItemGroup = null;

          _unitController.clear();
          _categoryController.clear();
        });

        return;
      }

      if (exactMatches.length == 1) {
        _selectMatchedItem(
          exactMatches.first,
        );
        return;
      }

      final matchedItem =
      await _showMatchingProducts(
        exactMatches,
      );

      if (!mounted) {
        return;
      }

      if (matchedItem != null) {
        _selectMatchedItem(
          matchedItem,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingProduct = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?>
  _showMatchingProducts(
      List<Map<String, dynamic>> matches,
      ) async {
    return showModalBottomSheet<
        Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(
              20,
            ),
            child: SizedBox(
              height:
              MediaQuery.of(context)
                  .size
                  .height *
                  0.55,
              child: Column(
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.grey.shade300,
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    'Select Matching Product',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  const Text(
                    'More than one PriceCatcher item has this product name.',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Expanded(
                    child:
                    ListView.separated(
                      itemCount:
                      matches.length,
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
                        matches[index];

                        return ListTile(
                          leading:
                          const CircleAvatar(
                            backgroundColor:
                            Color(
                              0xFFE8F8ED,
                            ),
                            child: Icon(
                              Icons
                                  .inventory_2_outlined,
                              color: Color(
                                0xFF38BB62,
                              ),
                            ),
                          ),
                          title: Text(
                            item['item']
                                ?.toString() ??
                                'Unknown Product',
                          ),
                          subtitle: Text(
                            '${item['unit'] ?? 'No unit'}'
                                '${item['item_category'] != null ? ' • ${item['item_category']}' : ''}',
                          ),
                          onTap: () {
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
      },
    );
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

    final images =
    await _imagePicker.pickMultiImage(
      imageQuality: 80,
    );

    if (images.isEmpty) {
      return;
    }

    final remainingSlots =
        5 - _selectedImages.length;

    final selectedFiles =
    images
        .take(
      remainingSlots,
    )
        .map(
          (image) =>
          File(
            image.path,
          ),
    )
        .toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImages.addAll(
        selectedFiles,
      );
    });

    if (images.length >
        remainingSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum 5 images allowed',
          ),
        ),
      );
    }
  }

  void _removeImage(
      int index,
      ) {
    setState(() {
      _selectedImages.removeAt(
        index,
      );
    });
  }

  Future<void> _saveProduct() async {
    final productName =
    _productNameController.text.trim();

    final unit =
    _unitController.text.trim();

    final category =
    _categoryController.text.trim();

    if (productName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter the product name.',
          ),
        ),
      );

      return;
    }

    if (!_productChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please check the product with PriceCatcher first.',
          ),
        ),
      );

      return;
    }

    if (unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter the product unit.',
          ),
        ),
      );

      return;
    }

    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter the product category.',
          ),
        ),
      );

      return;
    }

    final price =
    double.tryParse(
      _priceController.text.trim(),
    );

    if (price == null ||
        price <= 0) {
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
        itemCode:
        _matchedItemCode,
        productName:
        productName,
        unit:
        unit,
        category:
        category,
        itemGroup:
        _matchedItemGroup,
        price:
        price,
        imageFiles:
        _selectedImages,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _productMatched
                ? 'Product added and linked to PriceCatcher.'
                : 'Product added successfully.',
          ),
          backgroundColor:
          const Color(
            0xFF38BB62,
          ),
        ),
      );

      _productNameController.removeListener(
        _onProductNameChanged,
      );

      setState(() {
        _matchedItemCode = null;
        _matchedItemGroup = null;

        _productChecked = false;
        _productMatched = false;

        _productNameController.clear();
        _unitController.clear();
        _categoryController.clear();
        _priceController.clear();

        _selectedImages.clear();
      });

      _productNameController.addListener(
        _onProductNameChanged,
      );

      widget.onProductAdded?.call();
    } catch (e) {
      debugPrint(
        'ADD PRODUCT ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
          duration:
          const Duration(
            seconds: 8,
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

  Widget _buildImageSection() {
    if (_selectedImages.isEmpty) {
      return GestureDetector(
        onTap:
        _pickImages,
        child: Container(
          width:
          double.infinity,
          height:
          190,
          decoration:
          BoxDecoration(
            color:
            Colors.white,
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            border:
            Border.all(
              color:
              Colors.grey.shade300,
            ),
          ),
          child:
          const Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons
                    .add_photo_alternate_outlined,
                size: 55,
                color:
                Color(
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
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                'Optional • Maximum 5 images',
                style:
                TextStyle(
                  color:
                  Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height:
          145,
          child:
          ListView.separated(
            scrollDirection:
            Axis.horizontal,
            itemCount:
            _selectedImages.length,
            separatorBuilder:
                (
                context,
                index,
                ) =>
            const SizedBox(
              width:
              12,
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
                      fit:
                      BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top:
                    6,
                    right:
                    6,
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
                        Colors.black54,
                        child:
                        Icon(
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
        const SizedBox(
          height:
          12,
        ),
        if (_selectedImages.length < 5)
          SizedBox(
            width:
            double.infinity,
            height:
            48,
            child:
            OutlinedButton.icon(
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
    );
  }

  Widget _buildProductAutocomplete() {
    return LayoutBuilder(
      builder:
          (
          context,
          constraints,
          ) {
        return RawAutocomplete<
            Map<String, dynamic>>(
          textEditingController:
          _productNameController,
          focusNode:
          _productNameFocusNode,
          displayStringForOption:
              (item) =>
          item['item']
              ?.toString() ??
              '',
          optionsBuilder:
              (
              TextEditingValue
              textEditingValue,
              ) {
            final query =
            textEditingValue.text
                .trim()
                .toLowerCase();

            if (query.length < 2) {
              return const Iterable<
                  Map<String, dynamic>>.empty();
            }

            final startsWithMatches =
            _items.where(
                  (item) {
                final name =
                    item['item']
                        ?.toString()
                        .toLowerCase() ??
                        '';

                return name.startsWith(
                  query,
                );
              },
            );

            final containsMatches =
            _items.where(
                  (item) {
                final name =
                    item['item']
                        ?.toString()
                        .toLowerCase() ??
                        '';

                return !name.startsWith(
                  query,
                ) &&
                    name.contains(
                      query,
                    );
              },
            );

            return [
              ...startsWithMatches,
              ...containsMatches,
            ].take(
              8,
            );
          },
          onSelected:
          _selectMatchedItem,
          fieldViewBuilder:
              (
              context,
              controller,
              focusNode,
              onFieldSubmitted,
              ) {
            return TextField(
              controller:
              controller,
              focusNode:
              focusNode,
              textCapitalization:
              TextCapitalization.words,
              decoration:
              InputDecoration(
                labelText:
                'Product Name',
                hintText:
                'Enter product name',
                prefixIcon:
                const Icon(
                  Icons
                      .shopping_bag_outlined,
                ),
                suffixIcon:
                controller.text.isNotEmpty
                    ? IconButton(
                  onPressed:
                      () {
                    controller.clear();
                    focusNode.requestFocus();
                  },
                  icon:
                  const Icon(
                    Icons.clear,
                  ),
                )
                    : null,
                filled:
                true,
                fillColor:
                Colors.white,
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                focusedBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                  borderSide:
                  const BorderSide(
                    color:
                    Color(
                      0xFF38BB62,
                    ),
                    width:
                    1.5,
                  ),
                ),
              ),
            );
          },
          optionsViewBuilder:
              (
              context,
              onSelected,
              options,
              ) {
            final suggestions =
            options.toList();

            return Align(
              alignment:
              Alignment.topLeft,
              child: Material(
                elevation:
                5,
                color:
                Colors.white,
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
                child:
                SizedBox(
                  width:
                  constraints.maxWidth,
                  child:
                  ConstrainedBox(
                    constraints:
                    const BoxConstraints(
                      maxHeight:
                      300,
                    ),
                    child:
                    ListView.separated(
                      padding:
                      EdgeInsets.zero,
                      shrinkWrap:
                      true,
                      itemCount:
                      suggestions.length,
                      separatorBuilder:
                          (
                          context,
                          index,
                          ) =>
                      const Divider(
                        height:
                        1,
                      ),
                      itemBuilder:
                          (
                          context,
                          index,
                          ) {
                        final item =
                        suggestions[
                        index];

                        final productName =
                            item['item']
                                ?.toString() ??
                                'Unknown Product';

                        final unit =
                            item['unit']
                                ?.toString() ??
                                '';

                        final category =
                            item['item_category']
                                ?.toString() ??
                                '';

                        return ListTile(
                          leading:
                          const CircleAvatar(
                            backgroundColor:
                            Color(
                              0xFFE8F8ED,
                            ),
                            child: Icon(
                              Icons.search,
                              color: Color(
                                0xFF38BB62,
                              ),
                            ),
                          ),
                          title: Text(
                            productName,
                            maxLines:
                            2,
                            overflow:
                            TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              unit,
                              category,
                            ]
                                .where(
                                  (value) =>
                              value.isNotEmpty,
                            )
                                .join(
                              ' • ',
                            ),
                          ),
                          onTap:
                              () {
                            onSelected(
                              item,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMatchStatus() {
    if (!_productChecked) {
      return const SizedBox.shrink();
    }

    if (_productMatched) {
      return Container(
        width:
        double.infinity,
        padding:
        const EdgeInsets.all(
          14,
        ),
        decoration:
        BoxDecoration(
          color:
          const Color(
            0xFFE8F8ED,
          ),
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          border:
          Border.all(
            color:
            const Color(
              0xFF38BB62,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons
                  .check_circle_outline,
              color:
              Color(
                0xFF38BB62,
              ),
            ),
            const SizedBox(
              width:
              10,
            ),
            Expanded(
              child:
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product found in PriceCatcher',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.bold,
                      color:
                      Color(
                        0xFF247F43,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height:
                    4,
                  ),
                  Text(
                    'Item Code: ${_matchedItemCode ?? '-'}',
                    style:
                    const TextStyle(
                      fontSize:
                      13,
                      color:
                      Color(
                        0xFF247F43,
                      ),
                    ),
                  ),
                  if (_matchedItemGroup != null &&
                      _matchedItemGroup!
                          .isNotEmpty)
                    Text(
                      'Group: $_matchedItemGroup',
                      style:
                      const TextStyle(
                        fontSize:
                        13,
                        color:
                        Color(
                          0xFF247F43,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFFFFF7E6,
        ),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        border:
        Border.all(
          color:
          const Color(
            0xFFE0A327,
          ),
        ),
      ),
      child:
      const Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color:
            Color(
              0xFFB87900,
            ),
          ),
          SizedBox(
            width:
            10,
          ),
          Expanded(
            child:
            Text(
              'Product not found in PriceCatcher. Please enter the unit and category manually.',
              style:
              TextStyle(
                color:
                Color(
                  0xFF8A5A00,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    bool readOnly = false,
  }) {
    return TextField(
      controller:
      controller,
      enabled:
      enabled,
      readOnly:
      readOnly,
      textCapitalization:
      TextCapitalization.words,
      decoration:
      InputDecoration(
        labelText:
        label,
        hintText:
        hint,
        prefixIcon:
        Icon(
          icon,
        ),
        filled:
        true,
        fillColor:
        !enabled
            ? const Color(
          0xFFE9E9E9,
        )
            : readOnly
            ? const Color(
          0xFFF1F3F1,
        )
            : Colors.white,
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          borderSide:
          BorderSide(
            color:
            Colors.grey.shade400,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          borderSide:
          const BorderSide(
            color:
            Color(
              0xFF38BB62,
            ),
            width:
            1.5,
          ),
        ),
        disabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          borderSide:
          BorderSide(
            color:
            Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _productNameController.removeListener(
      _onProductNameChanged,
    );

    _productNameController.dispose();
    _unitController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _productNameFocusNode.dispose();

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
          'Add Product',
        ),
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,
      ),
      body:
      _isLoading
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
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Product Images',
                style:
                TextStyle(
                  fontSize:
                  20,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(
                height:
                6,
              ),
              Text(
                '${_selectedImages.length}/5 images selected',
                style:
                const TextStyle(
                  color:
                  Colors.grey,
                ),
              ),
              const SizedBox(
                height:
                15,
              ),
              _buildImageSection(),
              const SizedBox(
                height:
                30,
              ),
              const Text(
                'Product Information',
                style:
                TextStyle(
                  fontSize:
                  20,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(
                height:
                6,
              ),
              const Text(
                'Start typing to see similar PriceCatcher products.',
                style:
                TextStyle(
                  color:
                  Colors.grey,
                ),
              ),
              const SizedBox(
                height:
                16,
              ),
              _buildProductAutocomplete(),
              const SizedBox(
                height:
                12,
              ),
              SizedBox(
                width:
                double.infinity,
                height:
                48,
                child:
                OutlinedButton.icon(
                  onPressed:
                  _isCheckingProduct
                      ? null
                      : _checkProduct,
                  icon:
                  _isCheckingProduct
                      ? const SizedBox(
                    width:
                    18,
                    height:
                    18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                    ),
                  )
                      : const Icon(
                    Icons.search,
                  ),
                  label:
                  Text(
                    _isCheckingProduct
                        ? 'CHECKING...'
                        : 'CHECK PRICECATCHER',
                  ),
                ),
              ),
              const SizedBox(
                height:
                14,
              ),
              _buildMatchStatus(),
              if (_productChecked)
                const SizedBox(
                  height:
                  18,
                ),
              _buildTextField(
                controller:
                _unitController,
                label:
                'Unit',
                hint:
                'Example: 1 KG, 500 ML, 10 PCS',
                icon:
                Icons.straighten_outlined,
                enabled:
                _productMatched ||
                    _canEditManualFields,
                readOnly:
                _productMatched,
              ),
              const SizedBox(
                height:
                16,
              ),
              _buildTextField(
                controller:
                _categoryController,
                label:
                'Category',
                hint:
                'Example: Beverages',
                icon:
                Icons.category_outlined,
                enabled:
                _productMatched ||
                    _canEditManualFields,
                readOnly:
                _productMatched,
              ),
              const SizedBox(
                height:
                20,
              ),
              TextField(
                controller:
                _priceController,
                keyboardType:
                const TextInputType
                    .numberWithOptions(
                  decimal:
                  true,
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
                  'Selling Price',
                  hintText:
                  '0.00',
                  prefixText:
                  'RM ',
                  prefixIcon:
                  const Icon(
                    Icons.payments_outlined,
                  ),
                  filled:
                  true,
                  fillColor:
                  Colors.white,
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),
                  focusedBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                    borderSide:
                    const BorderSide(
                      color:
                      Color(
                        0xFF38BB62,
                      ),
                      width:
                      1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height:
                30,
              ),
              SizedBox(
                width:
                double.infinity,
                height:
                55,
                child:
                FilledButton.icon(
                  onPressed:
                  _isSaving
                      ? null
                      : _saveProduct,
                  icon:
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
                    ),
                  )
                      : const Icon(
                    Icons
                        .add_circle_outline,
                  ),
                  label:
                  Text(
                    _isSaving
                        ? 'ADDING PRODUCT...'
                        : 'ADD PRODUCT',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.w600,
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