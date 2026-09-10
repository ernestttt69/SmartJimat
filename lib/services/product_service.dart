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
      'id, seller_id, premise_code, item_code, price, created_at, is_deleted, deleted_at',
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
      final itemResponse = await _supabase
          .from('lookup_item')
          .select(
        'item, unit, item_group, item_category',
      )
          .eq(
        'item_code',
        product['item_code'],
      )
          .maybeSingle();

      final imagesResponse = await _supabase
          .from('seller_product_images')
          .select(
        'id, image_url',
      )
          .eq(
        'product_id',
        product['id'],
      )
          .order(
        'id',
        ascending: true,
      );

      result.add({
        ...product,
        'lookup_item': itemResponse == null
            ? null
            : Map<String, dynamic>.from(
          itemResponse,
        ),
        'seller_product_images':
        List<Map<String, dynamic>>.from(
          imagesResponse,
        ),
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
      'id, seller_id, premise_code, item_code, price, created_at, is_deleted, deleted_at',
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
      final itemResponse = await _supabase
          .from('lookup_item')
          .select(
        'item, unit, item_group, item_category',
      )
          .eq(
        'item_code',
        product['item_code'],
      )
          .maybeSingle();

      final imagesResponse = await _supabase
          .from('seller_product_images')
          .select(
        'id, image_url',
      )
          .eq(
        'product_id',
        product['id'],
      )
          .order(
        'id',
        ascending: true,
      );

      result.add({
        ...product,
        'lookup_item': itemResponse == null
            ? null
            : Map<String, dynamic>.from(
          itemResponse,
        ),
        'seller_product_images':
        List<Map<String, dynamic>>.from(
          imagesResponse,
        ),
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
      'id, seller_id, premise_code, item_code, price, created_at, is_deleted, deleted_at',
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

    final itemResponse = await _supabase
        .from('lookup_item')
        .select(
      'item, unit, item_group, item_category',
    )
        .eq(
      'item_code',
      product['item_code'],
    )
        .maybeSingle();

    final premiseResponse = await _supabase
        .from('lookup_premise')
        .select(
      'premise, address, premise_type, state, district',
    )
        .eq(
      'premise_code',
      product['premise_code'],
    )
        .maybeSingle();

    final imagesResponse = await _supabase
        .from('seller_product_images')
        .select(
      'id, image_url',
    )
        .eq(
      'product_id',
      productId,
    )
        .order(
      'id',
      ascending: true,
    );

    return {
      ...product,
      'lookup_item': itemResponse == null
          ? null
          : Map<String, dynamic>.from(
        itemResponse,
      ),
      'lookup_premise': premiseResponse == null
          ? null
          : Map<String, dynamic>.from(
        premiseResponse,
      ),
      'seller_product_images':
      List<Map<String, dynamic>>.from(
        imagesResponse,
      ),
    };
  }

  Future<void> addProduct({
    required int itemCode,
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

    if (price <= 0) {
      throw Exception(
        'Price must be greater than 0',
      );
    }

    if (price > 99999.99) {
      throw Exception(
        'Price cannot exceed RM 99,999.99',
      );
    }

    if (imageFiles.length > 5) {
      throw Exception(
        'Maximum 5 product images allowed',
      );
    }

    final profile = await _supabase
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
      profile['premise_code'],
    );

    if (premiseCode == null) {
      throw Exception(
        'Seller does not have a registered premise',
      );
    }

    final product = await _supabase
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

    final productId =
    _toInt(
      product['id'],
    );

    if (productId == null) {
      throw Exception(
        'Unable to create product',
      );
    }

    if (imageFiles.isEmpty) {
      return;
    }

    await _uploadProductImages(
      productId: productId,
      imageFiles: imageFiles,
    );
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

    if (price <= 0) {
      throw Exception(
        'Price must be greater than 0',
      );
    }

    if (price > 99999.99) {
      throw Exception(
        'Price cannot exceed RM 99,999.99',
      );
    }

    final existingImagesResponse =
    await _supabase
        .from('seller_product_images')
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
      'price':
      price,
    })
        .eq(
      'id',
      productId,
    )
        .eq(
      'seller_id',
      currentUser.id,
    );

    if (newImageFiles.isEmpty) {
      return;
    }

    await _uploadProductImages(
      productId: productId,
      imageFiles: newImageFiles,
    );
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

    final List<String> uploadedPaths = [];
    final List<int> insertedImageIds = [];

    try {
      for (int i = 0;
      i < imageFiles.length;
      i++) {
        final imageFile =
        imageFiles[i];

        final extension =
        _getFileExtension(
          imageFile.path,
        );

        final timestamp =
            DateTime.now()
                .microsecondsSinceEpoch;

        final fileName =
            '${timestamp}_$i.$extension';

        final filePath =
            '${currentUser.id}/$productId/$fileName';

        await _supabase.storage
            .from(
          'product-images',
        )
            .upload(
          filePath,
          imageFile,
          fileOptions:
          const FileOptions(
            upsert: false,
          ),
        );

        uploadedPaths.add(
          filePath,
        );

        final imageUrl =
        _supabase.storage
            .from(
          'product-images',
        )
            .getPublicUrl(
          filePath,
        );

        final insertedImage =
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
          insertedImage['id'],
        );

        if (imageId != null) {
          insertedImageIds.add(
            imageId,
          );
        }
      }
    } catch (e) {
      if (insertedImageIds.isNotEmpty) {
        try {
          await _supabase
              .from(
            'seller_product_images',
          )
              .delete()
              .inFilter(
            'id',
            insertedImageIds,
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
      String path,
      ) {
    final fileName =
        path
            .split('/')
            .last
            .split('\\')
            .last;

    if (!fileName.contains('.')) {
      return 'jpg';
    }

    final extension =
    fileName
        .split('.')
        .last
        .toLowerCase();

    if (extension.isEmpty) {
      return 'jpg';
    }

    return extension;
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