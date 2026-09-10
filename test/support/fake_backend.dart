import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Deliberately fake accounts: no request is sent to the real Supabase project.
class FakeBackend {
  String activeId = 'integration-customer';
  String role = 'customer';
  bool missingProfile = false;
  late final client = MockClient((request) async {
    final route = request.url.path;
    Object? body = <Object>[];
    if (route.endsWith('/token')) {
      final credentials = jsonDecode(request.body) as Map;
      if (credentials['password'] != 'TestPassword1!') {
        return http.Response(
          jsonEncode({'msg': 'Invalid login credentials'}),
          400,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }
      role = credentials['email'] == 'seller@example.test'
          ? 'seller'
          : 'customer';
      activeId = role == 'seller'
          ? 'integration-seller'
          : 'integration-customer';
      body = {
        'access_token': 'fake-access-token',
        'refresh_token': 'fake-refresh-token',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': activeId,
          'aud': 'authenticated',
          'role': 'authenticated',
          'email': credentials['email'],
          'app_metadata': {},
          'user_metadata': {},
          'created_at': '2026-01-01T00:00:00Z',
        },
      };
    } else if (route.endsWith('/logout')) {
      body = {};
    } else if (route.endsWith('/user')) {
      body = missingProfile
          ? null
          : {
              'id': activeId,
              'role': role,
              'full_name': 'Integration User',
              'phone': '0123456789',
              'premise_code': null,
              'profile_image_url': null,
            };
    } else if (route.endsWith('/lookup_item')) {
      body = [
        {
          'item_code': 1,
          'item': 'TEST RICE',
          'unit': '5kg',
          'item_group': 'Food',
          'item_category': 'Rice',
        },
      ];
    } else if (route.endsWith('/get_items_with_price')) {
      body = [
        {'item_code': 1},
      ];
    }
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  });
}
