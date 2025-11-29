import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/price_pulse.dart';

class PricePulseService {
  final _supabase = Supabase.instance.client;

  /// Get price pulses from the last 7 days
  Stream<List<PricePulse>> getPricePulses() {
    // Supabase Realtime subscription
    return _supabase
        .from('price_pulses')
        .stream(primaryKey: ['id'])
        .order('submission_date', ascending: false)
        .map((data) {
          final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
          return data
              .map((map) => PricePulse.fromMap(map, map['id'].toString()))
              .where((pulse) => pulse.submissionDate.isAfter(sevenDaysAgo))
              .toList();
        });
  }

  /// Add a new price pulse
  Future<void> addPricePulse(PricePulse pulse) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      // Allow anonymous submissions, but log user ID if available

      final data = pulse.toMap();
      if (userId != null) {
        data['user_id'] = userId;
      }

      // Remove ID to let DB generate it
      if (pulse.id == null) {
        data.remove('id');
      }

      await _supabase.from('price_pulses').insert(data);
    } catch (e) {
      print('Error adding price pulse: $e');
    }
  }
}
