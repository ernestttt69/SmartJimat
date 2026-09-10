import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

class SupabaseService {
  final SupabaseClient supabase =
      Supabase.instance.client;

  // =========================================================
  // GET ITEM GROUPS
  // =========================================================

  Future<List<String>> getItemGroups() async {
    final data = await supabase
        .from('lookup_item')
        .select('item_group');

    final groups = data
        .map(
          (row) =>
      row['item_group']?.toString() ?? '',
    )
        .where(
          (group) => group.isNotEmpty,
    )
        .toSet()
        .toList();

    groups.sort();

    return groups;
  }

  // =========================================================
  // GET CATEGORIES BY GROUP
  // =========================================================

  Future<List<String>> getCategoriesByGroup(
      String group,
      ) async {
    final data = await supabase
        .from('lookup_item')
        .select('item_category')
        .eq(
      'item_group',
      group,
    );

    final categories = data
        .map(
          (row) =>
      row['item_category']?.toString() ?? '',
    )
        .where(
          (category) => category.isNotEmpty,
    )
        .toSet()
        .toList();

    categories.sort();

    return categories;
  }

  // =========================================================
  // GET PRODUCTS BY CATEGORY
  // =========================================================

  Future<List<Product>> getProductsByCategory(
      String group,
      String category,
      ) async {
    final data = await supabase
        .from('lookup_item')
        .select(
      'item_code, '
          'item, '
          'unit, '
          'item_group, '
          'item_category',
    )
        .eq(
      'item_group',
      group,
    )
        .eq(
      'item_category',
      category,
    )
        .order('item');

    return data
        .map<Product>(
          (row) => Product.fromMap(row),
    )
        .toList();
  }

  // =========================================================
  // SEARCH PRODUCTS
  // =========================================================

  Future<List<Product>> searchProducts(
      String keyword,
      ) async {
    final cleanKeyword = keyword.trim();

    if (cleanKeyword.isEmpty) {
      return [];
    }

    final data = await supabase
        .from('lookup_item')
        .select(
      'item_code, '
          'item, '
          'unit, '
          'item_group, '
          'item_category',
    )
        .ilike(
      'item',
      '%$cleanKeyword%',
    )
        .order('item')
        .limit(50);

    return data
        .map<Product>(
          (row) => Product.fromMap(row),
    )
        .toList();
  }

  // =========================================================
  // CHECK WHICH ITEMS HAVE PRICE DATA
  // =========================================================
  //
  // Uses Supabase RPC:
  // get_items_with_price(bigint[])
  //
  // An item is considered to have price data when at least
  // one PriceCatcher row exists with a non-null price.
  //
  // This avoids downloading thousands of duplicate
  // PriceCatcher rows to Flutter.
  // =========================================================

  Future<Set<int>> getItemsWithPrice(
      List<int> itemCodes,
      ) async {
    if (itemCodes.isEmpty) {
      return {};
    }

    final uniqueItemCodes =
    itemCodes.toSet().toList();

    try {
      final data = await supabase.rpc(
        'get_items_with_price',
        params: {
          'p_item_codes': uniqueItemCodes,
        },
      );

      final Set<int> itemsWithPrice = {};

      for (final row in data as List) {
        final itemCode = int.tryParse(
          row['item_code'].toString(),
        );

        if (itemCode != null) {
          itemsWithPrice.add(itemCode);
        }
      }

      print('======================================');
      print('PRODUCT PRICE AVAILABILITY');
      print('======================================');
      print(
        'PRODUCTS CHECKED: '
            '${uniqueItemCodes.length}',
      );
      print(
        'PRODUCTS WITH PRICE: '
            '${itemsWithPrice.length}',
      );
      print(
        'PRODUCTS WITHOUT PRICE: '
            '${uniqueItemCodes.length - itemsWithPrice.length}',
      );
      print('======================================');

      return itemsWithPrice;
    } catch (e) {
      print('======================================');
      print('PRODUCT PRICE CHECK ERROR');
      print('======================================');
      print(e);
      print('======================================');

      rethrow;
    }
  }
}