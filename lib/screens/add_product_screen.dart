import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/data_gov_service.dart';
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

class _AddProductScreenState
    extends State<AddProductScreen> {
  final ProductService _productService =
  ProductService();

  final DataGovService _dataGovService =
  DataGovService();

  final ImagePicker _imagePicker =
  ImagePicker();

  final TextEditingController
  _productNameController =
  TextEditingController();

  final TextEditingController
  _unitController =
  TextEditingController();

  final TextEditingController
  _categoryController =
  TextEditingController();

  final TextEditingController
  _priceController =
  TextEditingController();

  final FocusNode _productNameFocusNode =
  FocusNode();

  List<Map<String, dynamic>> _items = [];
  final List<File> _selectedImages = [];

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

    _productNameController.addListener(
      _onProductNameChanged,
    );

    _loadLatestItems();
  }

  Future<void> _loadLatestItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items =
      await _dataGovService
          .getLatestItems();

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

      _showMessage(
        'We could not get the latest government product data. Please check your internet connection and tap refresh.',
      );
    }
  }

  void _onProductNameChanged() {
    if (!_productChecked &&
        !_productMatched) {
      return;
    }

    setState(() {
      _matchedItemCode = null;
      _matchedItemGroup = null;

      _productChecked = false;
      _productMatched = false;

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

  int? _toInt(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  Future<void> _selectMatchedItem(
      Map<String, dynamic> item,
      ) async {
    final itemCode =
    _toInt(
      item['item_code'],
    );

    if (itemCode == null) {
      return;
    }

    _productNameController.removeListener(
      _onProductNameChanged,
    );

    setState(() {
      _productChecked = true;
      _productMatched = true;

      _matchedItemCode = itemCode;

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
        'Please enter a product name first.',
      );

      return;
    }

    if (_items.isEmpty) {
      _showMessage(
        'Government product data is unavailable. Please tap refresh and try again.',
      );

      return;
    }

    setState(() {
      _isCheckingProduct = true;
    });

    try {
      final input =
      _normalizeText(
        productName,
      );

      final matches =
      _items.where(
            (item) {
          final name =
          _normalizeText(
            item['item']
                ?.toString() ??
                '',
          );

          return name == input;
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
        await _selectMatchedItem(
          matches.first,
        );

        return;
      }

      final selected =
      await _showMatchingProducts(
        matches,
      );

      if (selected != null) {
        await _selectMatchedItem(
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
                    'Select Product',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 15,
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
                                '',
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
        'You can upload a maximum of 5 images.',
      );

      return;
    }

    final images =
    await _imagePicker
        .pickMultiImage(
      imageQuality: 80,
    );

    if (images.isEmpty) {
      return;
    }

    final remaining =
        5 -
            _selectedImages.length;

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
      _selectedImages
          .addAll(
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

    final price =
    double.tryParse(
      _priceController.text.trim(),
    );

    if (productName.isEmpty) {
      _showMessage(
        'Please enter a product name.',
      );

      return;
    }

    if (!_productChecked) {
      _showMessage(
        'Please check the product with government data first.',
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

    if (price == null ||
        price <= 0) {
      _showMessage(
        'Please enter a valid selling price.',
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
        _toInt(
          duplicate['id'],
        );

        if (productId == null) {
          throw Exception();
        }

        final currentPrice =
            (duplicate['price']
            as num?)
                ?.toDouble() ??
                0;

        final isDeleted =
            duplicate['is_deleted'] ==
                true;

        final update =
        await _showDuplicateDialog(
          isDeleted:
          isDeleted,
          currentPrice:
          currentPrice,
          newPrice:
          price,
        );

        if (!update) {
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
              ? 'Product restored and updated successfully.'
              : 'Existing product updated successfully.',
          success:
          true,
        );

        _resetForm();

        widget.onProductAdded
            ?.call();

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
        'Product added successfully.',
        success:
        true,
      );

      _resetForm();

      widget.onProductAdded
          ?.call();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to save the product. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving =
          false;
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
      context:
      context,
      builder:
          (context) {
        return AlertDialog(
          title:
          Text(
            isDeleted
                ? 'Product Already Exists'
                : 'Duplicate Product',
          ),
          content:
          Text(
            isDeleted
                ? 'This product is in Deleted Products.\n\nPrevious Price: RM ${currentPrice.toStringAsFixed(2)}\nNew Price: RM ${newPrice.toStringAsFixed(2)}\n\nRestore and update it?'
                : 'You already added this product.\n\nCurrent Price: RM ${currentPrice.toStringAsFixed(2)}\nNew Price: RM ${newPrice.toStringAsFixed(2)}\n\nUpdate the existing product?',
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
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
              onPressed:
                  () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
              Text(
                isDeleted
                    ? 'RESTORE & UPDATE'
                    : 'UPDATE PRODUCT',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
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
            : Colors.red,
      ),
    );
  }

  Widget _buildGovernmentInfo() {
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
      ),
      child:
      const Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons
                .verified_outlined,
            color:
            Color(
              0xFF38BB62,
            ),
          ),
          SizedBox(
            width:
            10,
          ),
          Expanded(
            child: Text(
              'Check Product Information\n'
                  'Enter or select a product to check whether its information is available in the latest government data. If found, the Unit and Category will be filled in automatically.',
              style:
              TextStyle(
                fontSize:
                13,
                height:
                1.4,
              ),
            ),
          ),
        ],
      ),
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
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
            width:
            10,
          ),
          Expanded(
            child: Text(
              _productMatched
                  ? 'Product Found\nThis product matches the latest government data. The Unit and Category have been filled in automatically.'
                  : 'Product Not Found\nThis product is not listed in the latest government data. You can still add it by entering the Unit and Category yourself.',
              style:
              const TextStyle(
                fontSize:
                13,
                height:
                1.4,
              ),
            ),
          ),
        ],
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
              value,
              ) {
            final query =
            value.text
                .trim()
                .toLowerCase();

            if (query.length < 2) {
              return const Iterable<
                  Map<String, dynamic>>.empty();
            }

            final starts =
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
              ...starts,
              ...contains,
            ].take(8);
          },
          onSelected:
              (item) {
            _selectMatchedItem(
              item,
            );
          },
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
              decoration:
              InputDecoration(
                labelText:
                'Product Name',
                hintText:
                'Enter Product Name',
                prefixIcon:
                const Icon(
                  Icons
                      .shopping_bag_outlined,
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
            );
          },
          optionsViewBuilder:
              (
              context,
              onSelected,
              options,
              ) {
            final list =
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
                      list.length,
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
                        list[index];

                        return ListTile(
                          title:
                          Text(
                            item['item']
                                ?.toString() ??
                                '',
                          ),
                          subtitle:
                          Text(
                            '${item['unit'] ?? ''}'
                                '${item['item_category'] != null ? ' • ${item['item_category']}' : ''}',
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
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
        child:
        Container(
          height:
          150,
          width:
          double.infinity,
          decoration:
          BoxDecoration(
            color:
            Colors.white,
            borderRadius:
            BorderRadius.circular(
              12,
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
                45,
                color:
                Color(
                  0xFF38BB62,
                ),
              ),
              SizedBox(
                height:
                8,
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
          130,
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
                    child:
                    Image.file(
                      _selectedImages[
                      index],
                      width:
                      130,
                      height:
                      130,
                      fit:
                      BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right:
                    4,
                    top:
                    4,
                    child:
                    IconButton(
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
      appBar:
      AppBar(
        title:
        const Text(
          'Add Product',
        ),
        backgroundColor:
        Colors.white,
        actions: [
          IconButton(
            onPressed:
            _isLoading
                ? null
                : _loadLatestItems,
            tooltip:
            'Refresh latest government data',
            icon:
            const Icon(
              Icons.refresh,
            ),
          ),
        ],
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
                14,
              ),
              _buildImages(),
              const SizedBox(
                height:
                26,
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
                12,
              ),
              _buildGovernmentInfo(),
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
                        : 'CHECK PRODUCT',
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
              _buildField(
                controller:
                _unitController,
                label:
                'Unit',
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
              _buildField(
                controller:
                _categoryController,
                label:
                'Category',
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
                16,
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
                26,
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
                      color:
                      Colors.white,
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