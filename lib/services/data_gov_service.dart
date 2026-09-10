import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

class DataGovService {
  static const String _baseUrl =
      'https://storage.data.gov.my/pricecatcher';

  static const String _premiseUrl =
      '$_baseUrl/lookup_premise.csv';

  static const String _itemUrl =
      '$_baseUrl/lookup_item.csv';

  Future<Map<String, dynamic>?> findPremise({
    required int premiseCode,
    required String shopName,
  }) async {
    final response = await http.get(
      Uri.parse(_premiseUrl),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Unable to get the latest premise data from data.gov.my.',
      );
    }

    final rows = _parseCsv(
      response.bodyBytes,
    );

    if (rows.length < 2) {
      throw Exception(
        'Latest premise dataset is empty.',
      );
    }

    final headers = _headers(
      rows.first,
    );

    final premiseCodeIndex =
    headers.indexOf('premise_code');

    final premiseIndex =
    headers.indexOf('premise');

    final addressIndex =
    headers.indexOf('address');

    final premiseTypeIndex =
    headers.indexOf('premise_type');

    final stateIndex =
    headers.indexOf('state');

    final districtIndex =
    headers.indexOf('district');

    if (premiseCodeIndex == -1 ||
        premiseIndex == -1) {
      throw Exception(
        'Invalid premise dataset.',
      );
    }

    final targetShop =
    _normalize(shopName);

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];

      final code = int.tryParse(
        _valueAt(
          row,
          premiseCodeIndex,
        ) ??
            '',
      );

      if (code != premiseCode) {
        continue;
      }

      final premiseName =
          _valueAt(
            row,
            premiseIndex,
          ) ??
              '';

      if (_normalize(premiseName) !=
          targetShop) {
        continue;
      }

      return {
        'premise_code': code,
        'premise': premiseName,
        'address': _valueAt(
          row,
          addressIndex,
        ),
        'premise_type': _valueAt(
          row,
          premiseTypeIndex,
        ),
        'state': _valueAt(
          row,
          stateIndex,
        ),
        'district': _valueAt(
          row,
          districtIndex,
        ),
      };
    }

    return null;
  }

  Future<List<Map<String, dynamic>>>
  getLatestItems() async {
    final response = await http.get(
      Uri.parse(_itemUrl),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Unable to get the latest item data from data.gov.my.',
      );
    }

    final rows = _parseCsv(
      response.bodyBytes,
    );

    if (rows.length < 2) {
      return [];
    }

    final headers = _headers(
      rows.first,
    );

    final itemCodeIndex =
    headers.indexOf('item_code');

    final itemIndex =
    headers.indexOf('item');

    final unitIndex =
    headers.indexOf('unit');

    final groupIndex =
    headers.indexOf('item_group');

    final categoryIndex =
    headers.indexOf('item_category');

    if (itemCodeIndex == -1 ||
        itemIndex == -1) {
      throw Exception(
        'Invalid item dataset.',
      );
    }

    final List<Map<String, dynamic>>
    items = [];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];

      final itemCode =
      int.tryParse(
        _valueAt(
          row,
          itemCodeIndex,
        ) ??
            '',
      );

      final itemName =
      _valueAt(
        row,
        itemIndex,
      );

      if (itemCode == null ||
          itemName == null ||
          itemName.isEmpty) {
        continue;
      }

      items.add({
        'item_code': itemCode,
        'item': itemName,
        'unit': _valueAt(
          row,
          unitIndex,
        ),
        'item_group': _valueAt(
          row,
          groupIndex,
        ),
        'item_category': _valueAt(
          row,
          categoryIndex,
        ),
      });
    }

    return items;
  }

  Future<Map<String, dynamic>?> findItem({
    required String itemName,
  }) async {
    final items =
    await getLatestItems();

    final normalizedInput =
    _normalize(itemName);

    for (final item in items) {
      final databaseName =
      _normalize(
        item['item']?.toString() ?? '',
      );

      if (databaseName ==
          normalizedInput) {
        return item;
      }
    }

    return null;
  }

  Future<List<Map<String, dynamic>>>
  searchItems({
    required String query,
    int limit = 10,
  }) async {
    final items =
    await getLatestItems();

    final normalizedQuery =
    _normalize(query);

    if (normalizedQuery.isEmpty) {
      return [];
    }

    final startsWith =
    items.where(
          (item) {
        final name =
        _normalize(
          item['item']?.toString() ?? '',
        );

        return name.startsWith(
          normalizedQuery,
        );
      },
    );

    final contains =
    items.where(
          (item) {
        final name =
        _normalize(
          item['item']?.toString() ?? '',
        );

        return !name.startsWith(
          normalizedQuery,
        ) &&
            name.contains(
              normalizedQuery,
            );
      },
    );

    return [
      ...startsWith,
      ...contains,
    ].take(limit).toList();
  }

  Future<Map<String, dynamic>>
  downloadLatestPriceData() async {
    final now = DateTime.now();

    for (var offset = 0;
    offset < 6;
    offset++) {
      final monthDate =
      DateTime(
        now.year,
        now.month - offset,
      );

      final year =
          monthDate.year;

      final month =
      monthDate.month
          .toString()
          .padLeft(
        2,
        '0',
      );

      final url =
          '$_baseUrl/pricecatcher_$year-$month.csv';

      final response =
      await http.get(
        Uri.parse(url),
      );

      if (response.statusCode == 200 &&
          response.bodyBytes.isNotEmpty) {
        return {
          'year': year,
          'month': monthDate.month,
          'month_text': month,
          'url': url,
          'bytes': response.bodyBytes,
        };
      }
    }

    throw Exception(
      'Unable to get the latest PriceCatcher price data from data.gov.my.',
    );
  }

  Future<List<Map<String, dynamic>>>
  getLatestPrices() async {
    final latest =
    await downloadLatestPriceData();

    final bytes =
    latest['bytes'] as List<int>;

    final rows =
    _parseCsv(
      bytes,
    );

    if (rows.length < 2) {
      return [];
    }

    final headers =
    _headers(
      rows.first,
    );

    final dateIndex =
    headers.indexOf('date');

    final premiseCodeIndex =
    headers.indexOf('premise_code');

    final itemCodeIndex =
    headers.indexOf('item_code');

    final priceIndex =
    headers.indexOf('price');

    if (dateIndex == -1 ||
        premiseCodeIndex == -1 ||
        itemCodeIndex == -1 ||
        priceIndex == -1) {
      throw Exception(
        'Invalid PriceCatcher price dataset.',
      );
    }

    final List<Map<String, dynamic>>
    prices = [];

    for (var i = 1; i < rows.length; i++) {
      final row =
      rows[i];

      final itemCode =
      int.tryParse(
        _valueAt(
          row,
          itemCodeIndex,
        ) ??
            '',
      );

      final premiseCode =
      int.tryParse(
        _valueAt(
          row,
          premiseCodeIndex,
        ) ??
            '',
      );

      final price =
      double.tryParse(
        _valueAt(
          row,
          priceIndex,
        ) ??
            '',
      );

      final date =
      _valueAt(
        row,
        dateIndex,
      );

      if (itemCode == null ||
          premiseCode == null ||
          price == null ||
          date == null) {
        continue;
      }

      prices.add({
        'date': date,
        'premise_code': premiseCode,
        'item_code': itemCode,
        'price': price,
      });
    }

    return prices;
  }

  Future<List<Map<String, dynamic>>>
  getLatestItemPrices({
    required int itemCode,
  }) async {
    final prices =
    await getLatestPrices();

    final results =
    prices.where(
          (row) {
        return row['item_code'] ==
            itemCode;
      },
    ).toList();

    results.sort(
          (
          a,
          b,
          ) {
        final aDate =
        DateTime.tryParse(
          a['date'].toString(),
        );

        final bDate =
        DateTime.tryParse(
          b['date'].toString(),
        );

        if (aDate == null ||
            bDate == null) {
          return 0;
        }

        return bDate.compareTo(
          aDate,
        );
      },
    );

    return results;
  }

  Future<Map<String, dynamic>?>
  getLatestItemPriceAtPremise({
    required int itemCode,
    required int premiseCode,
  }) async {
    final prices =
    await getLatestPrices();

    final matches =
    prices.where(
          (row) {
        return row['item_code'] ==
            itemCode &&
            row['premise_code'] ==
                premiseCode;
      },
    ).toList();

    if (matches.isEmpty) {
      return null;
    }

    matches.sort(
          (
          a,
          b,
          ) {
        final aDate =
        DateTime.tryParse(
          a['date'].toString(),
        );

        final bDate =
        DateTime.tryParse(
          b['date'].toString(),
        );

        if (aDate == null ||
            bDate == null) {
          return 0;
        }

        return bDate.compareTo(
          aDate,
        );
      },
    );

    return matches.first;
  }

  Future<Map<String, double>?>
  getItemPriceRange({
    required int itemCode,
  }) async {
    final prices =
    await getLatestItemPrices(
      itemCode:
      itemCode,
    );

    if (prices.isEmpty) {
      return null;
    }

    final values =
    prices
        .map(
          (row) =>
          (row['price'] as num)
              .toDouble(),
    )
        .toList();

    values.sort();

    final total =
    values.fold<double>(
      0,
          (
          previous,
          value,
          ) =>
      previous + value,
    );

    return {
      'minimum':
      values.first,
      'maximum':
      values.last,
      'average':
      total / values.length,
    };
  }

  List<List<dynamic>> _parseCsv(
      List<int> bytes,
      ) {
    final text =
    utf8.decode(
      bytes,
    );

    return const CsvToListConverter(
      shouldParseNumbers:
      false,
      eol:
      '\n',
    ).convert(
      text,
    );
  }

  List<String> _headers(
      List<dynamic> row,
      ) {
    return row
        .map(
          (value) =>
          value
              .toString()
              .trim()
              .replaceFirst(
            '\ufeff',
            '',
          ),
    )
        .toList();
  }

  String? _valueAt(
      List<dynamic> row,
      int index,
      ) {
    if (index < 0 ||
        index >= row.length) {
      return null;
    }

    final value =
    row[index]
        .toString()
        .trim();

    if (value.isEmpty) {
      return null;
    }

    return value;
  }

  String _normalize(
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
}