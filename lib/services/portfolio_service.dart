import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cattle_group.dart';

class PortfolioService {
  final _supabase = Supabase.instance.client;

  /// Load cattle groups from Supabase
  Future<List<CattleGroup>> loadGroups() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('cattle_groups')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => CattleGroup.fromMap(data, data['id'].toString()))
          .toList();
    } catch (e) {
      print('Error loading groups: $e');
      return [];
    }
  }

  /// Add a new group to Supabase
  Future<void> addGroup(CattleGroup group) async {
    try {
      print('🔍 DEBUG: Starting addGroup...');
      final userId = _supabase.auth.currentUser?.id;
      print('🔍 DEBUG: User ID: $userId');

      if (userId == null) {
        print('❌ ERROR: User not signed in! Cannot add group.');
        return;
      }

      final data = group.toMap();
      print('🔍 DEBUG: Group data before adding user_id: $data');

      data['user_id'] = userId;
      print('🔍 DEBUG: Group data after adding user_id: $data');

      // Remove ID if it's null, let DB generate it
      if (group.id == null) {
        data.remove('id');
      }

      print('🔍 DEBUG: Attempting to insert into Supabase...');
      await _supabase.from('cattle_groups').insert(data);
      print('✅ SUCCESS: Group added to Supabase!');
    } catch (e) {
      print('❌ ERROR adding group: $e');
      print('❌ ERROR details: ${e.toString()}');
    }
  }

  /// Remove a group by ID
  Future<void> removeGroup(String id) async {
    try {
      await _supabase.from('cattle_groups').delete().eq('id', id);
    } catch (e) {
      print('Error removing group: $e');
    }
  }

  /// Clear all groups for the user
  Future<void> clearAll() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('cattle_groups').delete().eq('user_id', userId);
    } catch (e) {
      print('Error clearing groups: $e');
    }
  }
}
