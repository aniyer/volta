import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import 'pocketbase_service.dart';

/// Service for managing missions/chores
class MissionsService {
  final PocketBaseService _pbService;
  
  MissionsService(this._pbService);
  
  /// Get all active missions
  Future<List<RecordModel>> getActiveMissions() async {
    try {
      final result = await _pbService.client
          .collection('missions')
          .getList(
            filter: 'is_active = true',
            sort: 'title',
          );
      return result.items;
    } catch (e) {
      debugPrint('Failed to get missions: $e');
      return [];
    }
  }
  
  /// Get a single mission by ID
  Future<RecordModel?> getMission(String id) async {
    try {
      return await _pbService.client
          .collection('missions')
          .getOne(id);
    } catch (e) {
      debugPrint('Failed to get mission: $e');
      return null;
    }
  }
  
  /// Submit a completed mission for review
  Future<RecordModel?> submitMission({
    required String missionId,
    required String userId,
    required List<int> photoBytes,
    required String fileName,
  }) async {
    try {
      // Create history record with photo proof
      final record = await _pbService.client
          .collection('history')
          .create(
            body: {
              'user_id': userId,
              'mission_id': missionId,
              'status': 'review',
              'timestamp': DateTime.now().toIso8601String(),
            },
            files: [
              http.MultipartFile.fromBytes(
                'photo_proof',
                photoBytes,
                filename: fileName,
              ),
            ],
          );
      return record;
    } catch (e) {
      debugPrint('Failed to submit mission: $e');
      return null;
    }
  }
  
  /// Get pending review items (for parents)
  Future<List<RecordModel>> getPendingReviews() async {
    try {
      final result = await _pbService.client
          .collection('history')
          .getList(
            filter: 'status = "review"',
            expand: 'user_id,mission_id',
            sort: '-timestamp',
          );
      return result.items;
    } catch (e) {
      debugPrint('Failed to get pending reviews: $e');
      return [];
    }
  }
  
  /// Approve a mission (parent action)
  /// Approve a mission (parent action)
  Future<bool> approveMission(String historyId, String childUserId, int pointsAwarded) async {
    try {
      // 1. Update history status
      await _pbService.client
          .collection('history')
          .update(historyId, body: {'status': 'completed'});
          
      // 2. Fetch current child user data to get current points
      final childUser = await _pbService.client.collection('users').getOne(childUserId);
      final currentPoints = childUser.getIntValue('points');
      final currentMissions = childUser.getIntValue('missions_completed');
      
      // 3. Update child points and mission count
      await _pbService.client
          .collection('users')
          .update(childUserId, body: {
            'points': currentPoints + pointsAwarded,
            'missions_completed': currentMissions + 1,
          });
      return true;
    } catch (e) {
      debugPrint('Failed to approve mission: $e');
      return false;
    }
  }
  
  /// Reject a mission (parent action) - sends back for redo
  Future<bool> rejectMission(String historyId) async {
    try {
      await _pbService.client
          .collection('history')
          .update(historyId, body: {'status': 'redo'});
      return true;
    } catch (e) {
      debugPrint('Failed to reject mission: $e');
      return false;
    }
  }

  /// Get missions marked for redo for a user
  Future<List<RecordModel>> getRedoMissions(String userId) async {
    try {
      final result = await _pbService.client
          .collection('history')
          .getList(
            filter: 'status = "redo" && user_id = "$userId"',
            expand: 'mission_id',
            sort: '-timestamp',
          );
      return result.items;
    } catch (e) {
      debugPrint('Failed to get redo missions: $e');
      return [];
    }
  }

  /// Resubmit a mission that was marked for redo
  Future<bool> resubmitMission({
    required String historyId,
    required List<int> photoBytes,
    required String fileName,
  }) async {
    try {
      await _pbService.client
          .collection('history')
          .update(
            historyId, 
            body: {
              'status': 'review',
              'timestamp': DateTime.now().toIso8601String(), // Reset timestamp to now
            },
            files: [
              http.MultipartFile.fromBytes(
                'photo_proof',
                photoBytes,
                filename: fileName,
              ),
            ],
          );
      return true;
    } catch (e) {
      debugPrint('Failed to resubmit mission: $e');
      return false;
    }
  }
  
  /// Get user's mission history
  Future<List<RecordModel>> getUserHistory(String userId) async {
    try {
      final result = await _pbService.client
          .collection('history')
          .getList(
            filter: 'user_id = "$userId"',
            expand: 'mission_id',
            sort: '-timestamp',
          );
      return result.items;
    } catch (e) {
      debugPrint('Failed to get user history: $e');
      return [];
    }
  }
}
