import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to handle call invitations between users
class CallInvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a call invitation
  /// Returns the invitation ID if successful
  Future<String?> createCallInvitation({
    required String receiverId,
    required String receiverName,
    required String callType, // 'audio' or 'video'
    required String channelName,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // Get caller info
      final callerDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final callerData = callerDoc.data();
      final callerName = callerData?['name'] ?? callerData?['email'] ?? 'Unknown';

      // Create invitation document
      final invitationRef = await _firestore.collection('call_invitations').add({
        'callerId': currentUser.uid,
        'callerName': callerName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'callType': callType, // 'audio' or 'video'
        'channelName': channelName,
        'status': 'pending', // pending, accepted, declined, cancelled, missed
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Call invitation created: ${invitationRef.id}');
      return invitationRef.id;
    } catch (e) {
      print('❌ Error creating call invitation: $e');
      return null;
    }
  }

  /// Listen to incoming call invitations for current user
  Stream<QuerySnapshot> listenToIncomingCalls() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('call_invitations')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Accept a call invitation
  Future<bool> acceptCall(String invitationId) async {
    try {
      await _firestore.collection('call_invitations').doc(invitationId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Call accepted: $invitationId');
      return true;
    } catch (e) {
      print('❌ Error accepting call: $e');
      return false;
    }
  }

  /// Decline a call invitation
  Future<bool> declineCall(String invitationId) async {
    try {
      await _firestore.collection('call_invitations').doc(invitationId).update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Call declined: $invitationId');
      return true;
    } catch (e) {
      print('❌ Error declining call: $e');
      return false;
    }
  }

  /// Cancel a call invitation (caller cancels)
  Future<bool> cancelCall(String invitationId) async {
    try {
      await _firestore.collection('call_invitations').doc(invitationId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      print('✅ Call cancelled: $invitationId');
      return true;
    } catch (e) {
      print('❌ Error cancelling call: $e');
      return false;
    }
  }

  /// Mark call as missed (if not answered within timeout)
  Future<bool> markCallAsMissed(String invitationId) async {
    try {
      await _firestore.collection('call_invitations').doc(invitationId).update({
        'status': 'missed',
        'missedAt': FieldValue.serverTimestamp(),
      });
      print('⏰ Call marked as missed: $invitationId');
      return true;
    } catch (e) {
      print('❌ Error marking call as missed: $e');
      return false;
    }
  }

  /// Listen to specific call invitation status changes
  Stream<DocumentSnapshot> listenToCallInvitation(String invitationId) {
    return _firestore
        .collection('call_invitations')
        .doc(invitationId)
        .snapshots();
  }

  /// Clean up old call invitations (optional - run periodically)
  Future<void> cleanupOldInvitations() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      final oldInvitations = await _firestore
          .collection('call_invitations')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();

      for (var doc in oldInvitations.docs) {
        await doc.reference.delete();
      }
      print('🧹 Cleaned up ${oldInvitations.docs.length} old invitations');
    } catch (e) {
      print('❌ Error cleaning up invitations: $e');
    }
  }
}