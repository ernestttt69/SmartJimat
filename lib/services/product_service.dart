import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getItems() async {
    final response = await _supabase
        .from('lookup_item')
        .select(
      'item_code, item, unit, item_group, item_category',
    )
        .order('item');

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  Future<List<Map<String, dynamic>>>
  getSellerProducts() async {
    final currentUser =
        _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'User is not logged in',
      );
    }

    final response = await _supabase
        .from('seller_products')
        .select(
      'id, seller_id, premise_code, item_code, price, created_at, is_deleted, deleted_at, custom_item_name, custom_unit, custom_category',
    )
        .eq(
      'seller_id',
      currentUser.id,
    )
        .eq(
      'is_deleted',
      false,
    )
        .order(
      'created_at',
      ascending: false,
    );

    final products =
    List<Map<String, dynamic>>.from(
      response,
    );

    final List<Map<String, dynamic>> result = [];

    for (final product in products) {
      final itemCode =
      _toInt(
        product['item_code'],
      );

      Map<String, dynamic>? item;

      if (itemCode != null) {
        final itemResponse = await _supabase
            .from('lookup_item')
            .select(
          'item_code, item, unit, item_group, item_category',
        )
            .eq(
          'item_code',
          itemCode,
        )
            .maybeSingle();

        if (itemResponse != null) {
          item =
          Map<String, dynamic>.from(
            itemResponse,
          );
        }
      } else {
        item = {
          'item_code': null,
          'item':
          product['custom_item_name'],
          'unit':
          product['custom_unit'],
          'item_group': null,
          'item_category':
          product['custom_category'],
        };
      }

      final imageResponse = await _supabase
          .from('seller_product_images')
          .select(
        'id, product_id, image_url, created_at',
      )
          .eq(
        'product_id',
        product['id'],
      )
          .order(
        'created_at',
      );

      final images =
      List<Map<String, dynamic>>.from(
        imageResponse,
      );

      result.add({
        ...product,
        'lookup_item': item,
        'seller_product_images': images,
      });
    }

    return result;
  }

  Future<List<Map<String, dynamic>>>
  getDeletedSellerProducts() async {
    final currentUser =
        _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'User is not logged in',
      );
    }

    final response = await _supabase
        .from('seller_products')
        .select(
      'id, seller_id, premise_code, item_code, price, created_at, is_deleted, deleted_at, custom_item_name, custom_unit, custom_category',
    )
        .eq(
      'seller_id',
      currentUser.id,
    )
        .eq(
      'is_deleted',
      true,
    )
        .order(
      'deleted_at',
      ascending: false,
    );

    final products =
    List<Map<String, dynamic>>.from(
      response,
    );

    final List<Map<String, dynamic>> result = [];

    for (final product in products) {
      final itemCode =
      _toInt(
        product['item_code'],
      );

      Map<String, dynamic>? item;

      if (itemCode != null) {
        final itemResponse = await _supabase
            .from('lookup_item')
            .select(
          'item_code, item, unit, item_group, item_category',
        )
            .eq(
          'item_code',
          itemCode,
        )
            .maybeSingle();

        if (itemResponse != null) {
          item =
          Map<String, dynamic>.from(
            itemResponse,
          );
        }
      } else {
        item = {
          'item_code': null,
          'item':
          product['custom_item_name'],
          'unit':
          product['custom_unit'],
          'item_group': null,
          'item_category':
          product['custom_category'],
        };
      }

      final imageResponse = await _supabase
          .from('seller_product_images')
          .select(
        'id, product_id, image_url, created_at',
      )
          .eq(
        'product_id',
        product['id'],
      )
          .order(
        'created_at',
      );

      final images =
      List<Map<String, dynamic>>.from(
        imageResponse,
      );

      result.add({
        ...product,
        'lookup_item': item,
        'seller_product_images': images,
      });
    }

    return result;
  }

  Future<Map<String, dynamic>> getProductDetails(
      int productId,
      ) async {
    final currentUser =
        _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'User is not logged in',
      );
    }

    final productResponse = await _supabase
        .from('seller_products')
        .select(
      'id, seller_id, premise_code, item_code, price, created_at, is_deleted, deleted_at, custom_item_name, custom_unit, custom_category',
    )
        .eq(
      'id',
      productId,
    )
        .eq(
      'seller_id',
      currentUser.id,
    )
        .single();

    final product =
    Map<String, dynamic>.from(
      productResponse,
    );

    final itemCode =
    _toInt(
      product['item_code'],
    );

    Map<String, dynamic>? item;

    if (itemCode != null) {
      final itemResponse = await _supabase
          .from('lookup_item')
          .select(
        'item_code, item, unit, item_group, item_category',
      )
          .eq(
        'item_code',
        itemCode,
      )
          .maybeSingle();

      if (itemResponse != null) {
        item =
        Map<String, dynamic>.from(
          itemResponse,
        );
      }
    } else {
      item = {
        'item_code': null,
        'item':
        product['custom_item_name'],
        'unit':
        product['custom_unit'],
        'item_group': null,
        'item_category':
        product['custom_category'],
      };
    }

    final premiseCode =
    _toInt(
      product['premise_code'],
    );

    Map<String, dynamic>? premise;

    if (premiseCode != null) {
      final premiseResponse =
      await _supabase
          .from(
        'lookup_premise',
      )
          .select(
        'premise_code, premise, address, premise_type, state, district',
      )
          .eq(
        'premise_code',
        premiseCode,
      )
          .maybeSingle();

      if (premiseResponse != null) {
        premise =
        Map<String, dynamic>.from(
          premiseResponse,
        );
      }
    }

    final imageResponse = await _supabase
        .from('seller_product_images')
        .select(
      'id, product_id, image_url, created_at',
    )
        .eq(
      'product_id',
      productId,
    )
        .order(
      'created_at',
    );

    final images =
    List<Map<String, dynamic>>.from(
      imageResponse,
    );

    return {
      ...product,
      'lookup_item': item,
      'lookup_premise': premise,
      'seller_product_images': images,
    };
  }

  Future<void> addProduct({
    int? itemCode,
    required String productName,
    required String unit,
    required String category,
    String? itemGroup,
    required double price,
    required List<File> imageFiles,
  }) async {
    final currentUser =
        _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'User is not logged in',
      );
    }

    final profileResponse = await _supabase
        .from('user')
        .select(
      'premise_code',
    )
        .eq(
      'id',
      currentUser.id,
    )
        .single();

    final premiseCode =
    _toInt(
      profileResponse['premise_code'],
    );

    if (premiseCode == null) {
      throw Exception(
        'Seller premise code is not available.',
      );
    }

    if (productName.trim().isEmpty) {
      throw Exception(
        'Product name is required.',
      );
    }

    if (unit.trim().isEmpty) {
      throw Exception(
        'Product unit is required.',
      );
    }

    if (category.trim().isEmpty) {
      throw Exception(
        'Product category is required.',
      );
    }

    if (price <= 0 ||
        price > 99999.99) {
      throw Exception(
        'Please enter a valid selling price.',
      );
    }

    late Map<String, dynamic>
    productResponse;

    if (itemCode != null) {
      final response = await _supabase
          .from('seller_products')
          .upsert(
        {
          'seller_id':
          currentUser.id,
          'premise_code':
          premiseCode,
          'item_code':
          itemCode,
          'price':
          price,
          'custom_item_name':
          null,
          'custom_unit':
          null,
          'custom_category':
          null,
          'is_deleted':
          false,
          'deleted_at':
          null,
        },
        onConflict:
        'seller_id,premise_code,item_code',
      )
          .select(
        'id',
      )
          .single();

      productResponse =
      Map<String, dynamic>.from(
        response,
      );
    } else {
      final response = await _supabase
          .from('seller_products')
          .insert({
        'seller_id':
        currentUser.id,
        'premise_code':
        premiseCode,
        'item_code':
        null,
        'price':
        price,
        'custom_item_name':
        productName.trim(),
        'custom_unit':
        unit.trim(),
        'custom_category':
        category.trim(),
        'is_deleted':
        false,
        'deleted_at':
        null,
      })
          .select(
        'id',
      )
          .single();

      productResponse =
      Map<String, dynamic>.from(
        response,
      );
    }

    final productId =
    _toInt(
      productResponse['id'],
    );

    if (productId == null) {
      throw Exception(
        'Unable to create product.',
      );
    }

    if (imageFiles.isNotEmpty) {
      await _uploadProductImages(
        productId: productId,
        imageFiles: imageFiles,
      );
    }
  }

  Future<void> updateProduct({
    required int productId,
    required double price,
    required List<File> newImageFiles,
  }) async {
    final currentUser =
        _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'User is not logged in',
      );
    }

    if (price <= 0 ||
        price > 99999.99) {
      throw Exception(
        'Please enter a valid selling price.',
      );
    }

    final existingImagesResponse =
    await _supabase
        .from(
      'seller_product_images',
    )
        .select(
      'id, image_url',
    )
        .eq(
      'product_id',
      productId,
    );

    final existingImages =
    List<Map<String, dynamic>>.from(
      existingImagesResponse,
    );

    if (existingImages.length +
        newImageFiles.length >
        5) {
      throw Exception(
        'Maximum 5 product images allowed',
      );
    }

    await _supabase
        .from('seller_products')
        .update({
      'price': price,
    })
        .eq(
      'id',
      productId,
    )
        .eq(
      'seller_id',
      currentUser.id,
    );

    if (newImageFiles.isNotEmpty) {
      await _uploadProductImages(
        productId:
        productId,
        imageFiles:
        newImageFiles,
      );
    }
  }

  Future<void> softDeleteProduct(
      int productId,
      ) async {
    final currentUser =
        _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'User is not logged in',
      );
    }

    await _supabase
        .from('seller_products')
        .update({
      'is_deleted':
      true,
      'deleted_at':
      DateTime.now()
          .toIso8601String(),
    })
        .eq(
      'id',
      productId,
    )
        .eq(
      'seller_id',
      currentUser.id,
    );
  }

  Future<void> restoreProduct(
      int productId,
      ) async {
    final currentUser =
        _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'User is not logged in',
      );
    }

    await _supabase
        .from('seller_products')
        .update({
      'is_deleted':
      false,
      'deleted_at':
      null,
    })
        .eq(
      'id',
      productId,
    )
        .eq(
      'seller_id',
      currentUser.id,
    );
  }

  Future<void> _uploadProductImages({
    required int productId,
    required List<File> imageFiles,
  }) async {
    final currentUser =
        _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'User is not logged in',
      );
    }

    final uploadedPaths =
    <String>[];

    final insertedImageIds =
    <int>[];

    try {
      for (var i = 0;
      i < imageFiles.length;
      i++) {
        final file =
        imageFiles[i];

        final extension =
        _getFileExtension(
          file.path,
        );

        final fileName =
            '${DateTime.now().microsecondsSinceEpoch}_$i.$extension';

        final storagePath =
            '${currentUser.id}/$productId/$fileName';

        await _supabase.storage
            .from(
          'product-images',
        )
            .upload(
          storagePath,
          file,
          fileOptions:
          const FileOptions(
            upsert: false,
          ),
        );

        uploadedPaths.add(
          storagePath,
        );

        final imageUrl =
        _supabase.storage
            .from(
          'product-images',
        )
            .getPublicUrl(
          storagePath,
        );

        final imageResponse =
        await _supabase
            .from(
          'seller_product_images',
        )
            .insert({
          'product_id':
          productId,
          'image_url':
          imageUrl,
        })
            .select(
          'id',
        )
            .single();

        final imageId =
        _toInt(
          imageResponse['id'],
        );

        if (imageId != null) {
          insertedImageIds.add(
            imageId,
          );
        }
      }
    } catch (e) {
      for (final imageId
      in insertedImageIds) {
        try {
          await _supabase
              .from(
            'seller_product_images',
          )
              .delete()
              .eq(
            'id',
            imageId,
          );
        } catch (_) {}
      }

      if (uploadedPaths.isNotEmpty) {
        try {
          await _supabase.storage
              .from(
            'product-images',
          )
              .remove(
            uploadedPaths,
          );
        } catch (_) {}
      }

      rethrow;
    }
  }

  String _getFileExtension(
      String filePath,
      ) {
    final parts =
    filePath.split(
      '.',
    );

    if (parts.length < 2) {
      return 'jpg';
    }

    final extension =
    parts.last.toLowerCase();

    if (extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'webp') {
      return extension;
    }

    return 'jpg';
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
}
