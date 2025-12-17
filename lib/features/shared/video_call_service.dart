import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to manage video call state and notifications
class VideoCallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Notify the other party that a call is starting
  Future<void> notifyCallStart({
    required String appointmentId,
    required String otherUserId,
    required String callerName,
    required String channelName,
  }) async {
    try {
      // Create notification
      await _firestore.collection('notifications').add({
        'userId': otherUserId,
        'title': 'Incoming Video Call',
        'body': '$callerName is calling you',
        'type': 'incoming_call',
        'appointmentId': appointmentId,
        'channelName': channelName,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update appointment with call status
      await _firestore.collection('appointments').doc(appointmentId).update({
        'callStatus': 'ringing',
        'lastCallAttempt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error notifying call start: $e');
    }
  }

  /// Check if there's an ongoing call for an appointment
  Future<bool> hasOngoingCall(String appointmentId) async {
    try {
      final doc = await _firestore
          .collection('call_logs')
          .doc(appointmentId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data();
      return data?['status'] == 'ongoing';
    } catch (e) {
      print('Error checking ongoing call: $e');
      return false;
    }
  }

  /// Get call details for an appointment
  Future<Map<String, dynamic>?> getCallDetails(String appointmentId) async {
    try {
      final doc = await _firestore
          .collection('call_logs')
          .doc(appointmentId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting call details: $e');
      return null;
    }
  }

  /// Listen to call status changes
  Stream<DocumentSnapshot> listenToCallStatus(String appointmentId) {
    return _firestore
        .collection('call_logs')
        .doc(appointmentId)
        .snapshots();
  }

  /// Update call quality metrics
  Future<void> updateCallQuality({
    required String appointmentId,
    required Map<String, dynamic> qualityMetrics,
  }) async {
    try {
      await _firestore
          .collection('call_logs')
          .doc(appointmentId)
          .update({
        'qualityMetrics': qualityMetrics,
        'lastQualityUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating call quality: $e');
    }
  }

  /// Record call feedback
  Future<void> submitCallFeedback({
    required String appointmentId,
    required int rating,
    required String? feedback,
    required List<String> issues,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('call_logs')
          .doc(appointmentId)
          .collection('feedback')
          .add({
        'userId': userId,
        'rating': rating,
        'feedback': feedback,
        'issues': issues,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error submitting feedback: $e');
    }
  }

  /// Get call history for a user
  Future<List<Map<String, dynamic>>> getCallHistory({
    required bool isDoctor,
    int limit = 20,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final field = isDoctor ? 'doctorId' : 'patientId';

      final snapshot = await _firestore
          .collection('call_logs')
          .where(field, isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting call history: $e');
      return [];
    }
  }

  /// Cancel a call
  Future<void> cancelCall({
    required String appointmentId,
    required String otherUserId,
  }) async {
    try {
      // Update call log
      await _firestore.collection('call_logs').doc(appointmentId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Update appointment
      await _firestore.collection('appointments').doc(appointmentId).update({
        'callStatus': 'cancelled',
      });

      // Notify other user
      await _firestore.collection('notifications').add({
        'userId': otherUserId,
        'title': 'Call Cancelled',
        'body': 'The video call was cancelled',
        'type': 'call_cancelled',
        'appointmentId': appointmentId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error cancelling call: $e');
    }
  }

  /// Mark user as in call (for presence)
  Future<void> updateUserCallStatus({
    required bool inCall,
    String? appointmentId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'inCall': inCall,
        'currentAppointmentId': appointmentId,
        'lastCallStatusUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user call status: $e');
    }
  }
}