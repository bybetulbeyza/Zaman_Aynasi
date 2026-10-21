import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/heritage_place.dart';

class HeritageRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<HeritagePlace>> getPlaces() async {
    try {
      // Tablodaki tüm verileri çeker
      final data = await _client
          .from('heritage_places')
          .select()
          .order('id', ascending: true);

      return (data as List)
          .map((item) => HeritagePlace.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Supabase veri çekme hatası: $e');
      return [];
    }
  }
}