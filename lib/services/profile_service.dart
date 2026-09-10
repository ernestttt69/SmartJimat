import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getSellerProfile() async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception('User is not logged in');
    }

    final profile = await _supabase
        .from('user')
        .select()
        .eq('id', currentUser.id)
        .single();

    Map<String, dynamic>? premise;

    if (profile['premise_code'] != null) {
      premise = await _supabase
          .from('lookup_premise')
          .select()
          .eq('premise_code', profile['premise_code'])
          .single();
    }

    return {
      'id': currentUser.id,
      'email': currentUser.email,
      'full_name': profile['full_name'],
      'phone': profile['phone'],
      'role': profile['role'],
      'premise_code': profile['premise_code'],
      'profile_image_url': profile['profile_image_url'],
      'premise': premise?['premise'],
      'premise_type': premise?['premise_type'],
      'address': premise?['address'],
      'state': premise?['state'],
      'district': premise?['district'],
    };
  }

  Future<void> updateSellerAccountInfo({
    required String fullName,
    required String phone,
  }) async {
    final currentUser =
        _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'User is not logged in',
      );
    }

    await _supabase
        .from('user')
        .update({
      'full_name': fullName,
      'phone': phone,
    })
        .eq(
      'id',
      currentUser.id,
    );
  }
}