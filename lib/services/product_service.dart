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
        .select('''
          id,
          seller_id,
          premise_code,
          item_code,
          price,
          created_at,
          lookup_item (
            item,
            unit,
            item_group,
            item_category
          ),
          seller_product_images (
            id,
            image_url
          )
        ''')
        .eq(
      'seller_id',
      currentUser.id,
    )
        .order(
      'created_at',
      ascending: false,
    );

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  Future<Map<String, dynamic>>
  getProductDetails(
      int productId,
      ) async {
    final currentUser =
        _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'User is not logged in',
      );
    }

    final response = await _supabase
        .from('seller_products')
        .select('''
          id,
          seller_id,
          premise_code,
          item_code,
          price,
          created_at,
          lookup_item (
            item,
            unit,
            item_group,
            item_category
          ),
          lookup_premise (
            premise,
            address,
            premise_type,
            state,
            district
          ),
          seller_product_images (
            id,
            image_url
          )
        ''')
        .eq(
      'id',
      productId,
    )
        .eq(
      'seller_id',
      currentUser.id,
    )
        .single();

    return Map<String, dynamic>.from(
      response,
    );
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

    final profile = await _supabase
        .from('user')
        .select('premise_code')
        .eq(
      'id',
      currentUser.id,
    )
        .single();

    final premiseCode =
    profile['premise_code'];

    if (premiseCode == null) {
      throw Exception(
        'Seller does not have a registered premise',
      );
    }

    if (imageFiles.length > 5) {
      throw Exception(
        'Maximum 5 product images allowed',
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

    final product = await _supabase
        .from('seller_products')
        .upsert(
      {
        'seller_id': currentUser.id,
        'premise_code': premiseCode,
        'item_code': itemCode,
        'price': price,
      },
      onConflict: 'seller_id,premise_code,item_code',
    )
        .select('id')
        .single();

    final productId =
    product['id'];

    final List<String> uploadedPaths = [];

    try {
      for (
      int i = 0;
      i < imageFiles.length;
      i++
      ) {
        final imageFile =
        imageFiles[i];

        final extension =
        imageFile.path
            .split('.')
            .last
            .toLowerCase();

        final timestamp =
            DateTime.now()
                .millisecondsSinceEpoch;

        final fileName =
            '${timestamp}_$i.$extension';

        final filePath =
            '${currentUser.id}/$productId/$fileName';

        await _supabase.storage
            .from('product-images')
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
            .from('product-images')
            .getPublicUrl(
          filePath,
        );

        await _supabase
            .from(
          'seller_product_images',
        )
            .insert({
          'product_id':
          productId,
          'image_url':
          imageUrl,
        });
      }
    } catch (e) {
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

      try {
        await _supabase
            .from(
          'seller_products',
        )
            .delete()
            .eq(
          'id',
          productId,
        );
      } catch (_) {}

      rethrow;
    }
  }
}