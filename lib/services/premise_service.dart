import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/premise.dart';

class PremiseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Premise>> getPremises() async {
    final response = await _supabase
        .from('lookup_premise')
        .select(
      'premise_code, premise, address, premise_type, state, district',
    )
        .order('premise');

    return (response as List)
        .map(
          (data) => Premise.fromJson(
        data as Map<String, dynamic>,
      ),
    )
        .toList();
  }
}