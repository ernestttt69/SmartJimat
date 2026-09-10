import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import 'shopping_cart_service.dart';

class AiChatService {
  static const String apiKey =
      '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';

  static const String apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String model =
      'openai/gpt-oss-20b';

  final SupabaseClient supabase =
      Supabase.instance.client;

  final ShoppingCartService cart =
      ShoppingCartService.instance;

  Future<String> sendMessage(
      String userMessage,
      ) async {
    final requestUserId = cart.userId;
    if (requestUserId == null) throw StateError('Please log in first.');
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'temperature': 0.2,
        'messages': [
          {
            'role': 'system',
            'content': '''
You are SmartJimat AI, a grocery shopping assistant for Malaysia.

Your job is to understand the user's shopping request.

Always write user-facing replies, including the JSON "message" field, in English,
even when the user writes in Malay or another language.
Keep original database product names, category names, units, and store names unchanged.
The "keyword" field must still use Malay grocery search terms to match the database.

If the user wants to add grocery products or ingredients to the cart, return ONLY valid JSON in this format:

{
  "action": "add_to_cart",
  "message": "Short reply to the user",
  "items": [
    {
      "name": "English product name",
      "keyword": "Malay grocery keyword suitable for searching a Malaysian grocery database",
      "quantity": 1
    }
  ]
}

Examples of keyword conversion:
rice -> BERAS
chicken -> AYAM
egg -> TELUR
cooking oil -> MINYAK MASAK
milk -> SUSU
sugar -> GULA
salt -> GARAM
flour -> TEPUNG
bread -> ROTI
fish -> IKAN
onion -> BAWANG
garlic -> BAWANG PUTIH
carrot -> LOBAK
soy sauce -> KICAP
coffee -> KOPI
tea -> TEH

If the user mentions a recipe, identify the common basic grocery ingredients required for that recipe.

If the user is only asking a normal grocery question and does not want anything added to the cart, return ONLY:

{
  "action": "chat",
  "message": "Your helpful response",
  "items": []
}

Do not use markdown.
Do not add text outside the JSON.
'''
          },
          {
            'role': 'user',
            'content': userMessage,
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Groq API failed: ${response.statusCode} ${response.body}',
      );
    }

    final data =
    jsonDecode(response.body);

    final content =
    data['choices'][0]['message']['content']
        .toString()
        .trim();

    final cleanContent =
    _cleanJson(content);

    final aiResult =
    jsonDecode(cleanContent);

    final action =
        aiResult['action']?.toString() ?? 'chat';

    final message =
        aiResult['message']?.toString() ??
            'Done.';

    if (action != 'add_to_cart') {
      return message;
    }

    final rawItems =
    aiResult['items'];

    if (rawItems is! List ||
        rawItems.isEmpty) {
      return message;
    }

    final List<String> addedItems = [];
    final List<String> notFoundItems = [];

    for (final rawItem in rawItems) {
      if (rawItem is! Map) {
        continue;
      }

      final name =
          rawItem['name']
              ?.toString()
              .trim() ??
              '';

      final keyword =
          rawItem['keyword']
              ?.toString()
              .trim() ??
              '';

      int quantity =
          int.tryParse(
            rawItem['quantity']
                ?.toString() ??
                '1',
          ) ??
              1;

      if (quantity < 1) {
        quantity = 1;
      }

      if (keyword.isEmpty) {
        notFoundItems.add(name);
        continue;
      }

      final product =
      await _findProduct(
        keyword,
        name,
      );

      if (product == null) {
        notFoundItems.add(
          name.isEmpty ? keyword : name,
        );
        continue;
      }

      for (int i = 0;
      i < quantity;
      i++) {
        await cart.addProduct(product, expectedUserId: requestUserId);
      }

      addedItems.add(
        '${product.item} ×$quantity',
      );
    }

    if (addedItems.isEmpty) {
      return 'I understood your request, but I could not find matching products in the SmartJimat database.';
    }

    String result =
        'Added to your shopping list:\n${addedItems.join('\n')}';

    if (notFoundItems.isNotEmpty) {
      result +=
      '\n\nCould not find:\n${notFoundItems.join('\n')}';
    }

    return result;
  }

  Future<Product?> _findProduct(
      String keyword,
      String name,
      ) async {
    final keywordResult =
    await supabase
        .from('lookup_item')
        .select(
      'item_code, item, unit, item_group, item_category',
    )
        .ilike(
      'item',
      '%$keyword%',
    )
        .limit(1);

    if (keywordResult.isNotEmpty) {
      return Product.fromMap(
        Map<String, dynamic>.from(
          keywordResult.first,
        ),
      );
    }

    if (name.isNotEmpty) {
      final nameResult =
      await supabase
          .from('lookup_item')
          .select(
        'item_code, item, unit, item_group, item_category',
      )
          .ilike(
        'item',
        '%$name%',
      )
          .limit(1);

      if (nameResult.isNotEmpty) {
        return Product.fromMap(
          Map<String, dynamic>.from(
            nameResult.first,
          ),
        );
      }
    }

    return null;
  }

  String _cleanJson(String value) {
    String result = value.trim();

    if (result.startsWith('```json')) {
      result =
          result.substring(7);
    } else if (result.startsWith('```')) {
      result =
          result.substring(3);
    }

    if (result.endsWith('```')) {
      result = result.substring(
        0,
        result.length - 3,
      );
    }

    return result.trim();
  }
}
