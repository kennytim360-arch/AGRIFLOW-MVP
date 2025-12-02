/// portfolio_service.dart - Cattle group portfolio management service
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cattle_group.dart';
import '../utils/logger.dart';

class PortfolioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the Firestore path for user's portfolios
  /// Path: users/{userId}/portfolios
  String _getUserPath() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    return 'users/$userId/portfolios';
  }

  /// Load cattle groups from Firestore
  Future<List<CattleGroup>> loadGroups() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        Logger.warning('User not signed in, returning empty list');
        return [];
      }

      Logger.debug('Loading groups for user: $userId');
      final snapshot = await _firestore
          .collection(_getUserPath())
          .orderBy('created_at', descending: true)
          .get();

      Logger.info('Loaded ${snapshot.docs.length} groups');
      return snapshot.docs
          .map((doc) => CattleGroup.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      Logger.error('Error loading groups', e);
      return [];
    }
  }

  /// Add a new group to Firestore
  Future<void> addGroup(CattleGroup group) async {
    try {
      Logger.debug('Starting addGroup...');
      final userId = _auth.currentUser?.uid;
      Logger.debug('User ID: $userId');

      if (userId == null) {
        Logger.error('User not signed in! Cannot add group.');
        return;
      }

      final data = group.toMap();
      Logger.debug('Group data: $data');

      Logger.debug('Attempting to insert into Firestore...');
      await _firestore.collection(_getUserPath()).add(data);
      Logger.success('Group added to Firestore!');
    } catch (e) {
      Logger.error('Error adding group', e);
    }
  }

  /// Remove a group by ID
  Future<void> removeGroup(String id) async {
    try {
      await _firestore.collection(_getUserPath()).doc(id).delete();
      Logger.success('Group deleted: $id');
    } catch (e) {
      Logger.error('Error removing group', e);
    }
  }

  /// Clear all groups for the user
  Future<void> clearAll() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore.collection(_getUserPath()).get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      Logger.success('All groups cleared');
    } catch (e) {
      Logger.error('Error clearing groups', e);
    }
  }

  /// Get cattle groups as a real-time stream
  /// Returns a stream that automatically updates when Firestore data changes
  Stream<List<CattleGroup>> getGroupsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      Logger.warning('User not signed in, returning empty stream');
      return Stream.value([]);
    }

    return _firestore
        .collection(_getUserPath())
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          Logger.info('Real-time update: ${snapshot.docs.length} groups');
          return snapshot.docs
              .map((doc) => CattleGroup.fromMap(doc.data(), doc.id))
              .toList();
        });
  }
}
