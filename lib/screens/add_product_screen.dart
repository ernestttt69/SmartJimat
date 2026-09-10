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
      _showMessage(
        'Please enter a product name.',
      );

      return;
    }

    if (_items.isEmpty) {
      _showMessage(
        'PriceCatcher product data is not available.',
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

      final matches =
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

      if (matches.isEmpty) {
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

      if (matches.length == 1) {
        _selectMatchedItem(
          matches.first,
        );

        return;
      }

      final selected =
      await _showMatchingProducts(
        matches,
      );

      if (selected != null) {
        _selectMatchedItem(
          selected,
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
                  const Text(
                    'Select Matching Product',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight:
                      FontWeight.bold,
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
                      const Divider(),
                      itemBuilder:
                          (
                          context,
                          index,
                          ) {
                        final item =
                        matches[index];

                        return ListTile(
                          title: Text(
                            item['item']
                                ?.toString() ??
                                'Unknown Product',
                          ),
                          subtitle: Text(
                            '${item['unit'] ?? ''}'
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
      _showMessage(
        'Maximum 5 images allowed',
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

    final remaining =
        5 - _selectedImages.length;

    final files =
    images
        .take(
      remaining,
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
        files,
      );
    });
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
      _showMessage(
        'Please enter the product name.',
      );

      return;
    }

    if (!_productChecked) {
      _showMessage(
        'Please check the product with PriceCatcher first.',
      );

      return;
    }

    if (unit.isEmpty) {
      _showMessage(
        'Please enter the product unit.',
      );

      return;
    }

    if (category.isEmpty) {
      _showMessage(
        'Please enter the product category.',
      );

      return;
    }

    final price =
    double.tryParse(
      _priceController.text.trim(),
    );

    if (price == null ||
        price <= 0) {
      _showMessage(
        'Please enter a valid selling price.',
      );

      return;
    }

    if (price > 99999.99) {
      _showMessage(
        'Price cannot exceed RM 99,999.99.',
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final duplicate =
      await _productService
          .findDuplicateProduct(
        itemCode:
        _matchedItemCode,
        productName:
        productName,
        unit:
        unit,
      );

      if (!mounted) {
        return;
      }

      if (duplicate != null) {
        final productId =
        duplicate['id'] is int
            ? duplicate['id'] as int
            : int.parse(
          duplicate['id']
              .toString(),
        );

        final isDeleted =
            duplicate['is_deleted'] ==
                true;

        final continueUpdate =
        await _showDuplicateDialog(
          isDeleted:
          isDeleted,
          currentPrice:
          (duplicate['price']
          as num?)
              ?.toDouble() ??
              0,
          newPrice:
          price,
        );

        if (!continueUpdate) {
          return;
        }

        if (isDeleted) {
          await _productService
              .restoreProduct(
            productId,
          );
        }

        await _productService
            .updateProduct(
          productId:
          productId,
          price:
          price,
          newImageFiles:
          _selectedImages,
        );

        if (!mounted) {
          return;
        }

        _showMessage(
          isDeleted
              ? 'Existing product restored and updated.'
              : 'Existing product updated successfully.',
          success:
          true,
        );

        _resetForm();

        widget.onProductAdded?.call();

        return;
      }

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

      _showMessage(
        _productMatched
            ? 'Product added and linked to PriceCatcher.'
            : 'Product added successfully.',
        success:
        true,
      );

      _resetForm();

      widget.onProductAdded?.call();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<bool> _showDuplicateDialog({
    required bool isDeleted,
    required double currentPrice,
    required double newPrice,
  }) async {
    final result =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isDeleted
                    ? Icons
                    .restore_outlined
                    : Icons
                    .warning_amber_rounded,
                color:
                const Color(
                  0xFFE0A327,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  isDeleted
                      ? 'Product Already Exists'
                      : 'Duplicate Product',
                ),
              ),
            ],
          ),
          content: Text(
            isDeleted
                ? 'This product already exists in your deleted products.\n\nPrevious price: RM ${currentPrice.toStringAsFixed(2)}\nNew price: RM ${newPrice.toStringAsFixed(2)}\n\nRestore it and update the price instead?'
                : 'You already added this product.\n\nCurrent price: RM ${currentPrice.toStringAsFixed(2)}\nNew price: RM ${newPrice.toStringAsFixed(2)}\n\nWould you like to update the existing product instead?',
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
              child: Text(
                isDeleted
                    ? 'RESTORE & UPDATE'
                    : 'UPDATE PRODUCT',
              ),
            ),
          ],
        );
      },
    );

    return result ??
        false;
  }

  void _resetForm() {
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
  }

  void _showMessage(
      String message, {
        bool success = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(
          message,
        ),
        backgroundColor:
        success
            ? const Color(
          0xFF38BB62,
        )
            : null,
      ),
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
              TextEditingValue value,
              ) {
            final query =
            value.text
                .trim()
                .toLowerCase();

            if (query.length < 2) {
              return const Iterable<
                  Map<String, dynamic>>.empty();
            }

            final start =
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

            final contains =
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
              ...start,
              ...contains,
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
              onSubmitted,
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
                    controller
                        .clear();

                    focusNode
                        .requestFocus();
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
              ),
            );
          },
          optionsViewBuilder:
              (
              context,
              onSelected,
              options,
              ) {
            final items =
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
                child: SizedBox(
                  width:
                  constraints.maxWidth,
                  child: ConstrainedBox(
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
                      items.length,
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
                        items[index];

                        return ListTile(
                          leading:
                          const Icon(
                            Icons.search,
                            color:
                            Color(
                              0xFF38BB62,
                            ),
                          ),
                          title: Text(
                            item['item']
                                ?.toString() ??
                                'Unknown Product',
                          ),
                          subtitle: Text(
                            '${item['unit'] ?? ''}'
                                '${item['item_category'] != null ? ' • ${item['item_category']}' : ''}',
                          ),
                          onTap: () {
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
        _productMatched
            ? const Color(
          0xFFE8F8ED,
        )
            : const Color(
          0xFFFFF7E6,
        ),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _productMatched
                ? Icons
                .check_circle_outline
                : Icons.info_outline,
            color:
            _productMatched
                ? const Color(
              0xFF38BB62,
            )
                : const Color(
              0xFFB87900,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              _productMatched
                  ? 'Product found in PriceCatcher. Item Code: ${_matchedItemCode ?? '-'}'
                  : 'Product not found in PriceCatcher. Enter the unit and category manually.',
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
    required bool enabled,
    bool readOnly = false,
  }) {
    return TextField(
      controller:
      controller,
      enabled:
      enabled,
      readOnly:
      readOnly,
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
        enabled
            ? Colors.white
            : const Color(
          0xFFE9E9E9,
        ),
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
        ),
      ),
    );
  }

  Widget _buildImages() {
    if (_selectedImages.isEmpty) {
      return GestureDetector(
        onTap:
        _pickImages,
        child: Container(
          height:
          180,
          width:
          double.infinity,
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
                size:
                50,
                color:
                Color(
                  0xFF38BB62,
                ),
              ),
              SizedBox(
                height:
                10,
              ),
              Text(
                'Select Product Images',
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
          140,
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
              10,
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
                    child: Image.file(
                      _selectedImages[
                      index],
                      width:
                      140,
                      height:
                      140,
                      fit:
                      BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right:
                    5,
                    top:
                    5,
                    child: IconButton(
                      onPressed:
                          () {
                        _removeImage(
                          index,
                        );
                      },
                      icon:
                      const Icon(
                        Icons.cancel,
                        color:
                        Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_selectedImages.length < 5)
          TextButton.icon(
            onPressed:
            _pickImages,
            icon:
            const Icon(
              Icons
                  .add_photo_alternate_outlined,
            ),
            label:
            const Text(
              'Add More Images',
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _productNameController
        .removeListener(
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
      appBar:
      AppBar(
        title:
        const Text(
          'Add Product',
        ),
        backgroundColor:
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
                15,
              ),
              _buildImages(),
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
                15,
              ),
              _buildProductAutocomplete(),
              const SizedBox(
                height:
                12,
              ),
              SizedBox(
                width:
                double.infinity,
                child:
                OutlinedButton.icon(
                  onPressed:
                  _isCheckingProduct
                      ? null
                      : _checkProduct,
                  icon:
                  const Icon(
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
                'Example: 1 KG',
                icon:
                Icons
                    .straighten_outlined,
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
                Icons
                    .category_outlined,
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
                    Icons
                        .payments_outlined,
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