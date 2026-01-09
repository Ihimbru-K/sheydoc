import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart'; // Import our new service

class EnhancedAppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  /// Book an appointment with notification
  Future<String?> bookAppointment({
    required String doctorId,
    required String doctorName,
    required DateTime appointmentDate,
    required String appointmentTime,
    required double fee,
    required String appointmentType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final patientDoc = await _firestore.collection('users').doc(user.uid).get();
      final patientData = patientDoc.data();
      final patientName = patientData?['name'] ?? user.email ?? 'Unknown Patient';
      final patientPhone = patientData?['phone'] ?? '';

      final appointmentRef = await _firestore.collection('appointments').add({
        'doctorId': doctorId,
        'doctorName': doctorName,
        'patientId': user.uid,
        'patientName': patientName,
        'patientEmail': user.email,
        'patientPhone': patientPhone,
        'appointmentDate': Timestamp.fromDate(appointmentDate),
        'appointmentTime': appointmentTime,
        'appointmentType': appointmentType,
        'fee': fee,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'location': patientData?['location'] ?? 'Douala',
      });

      // Create notification for doctor (will trigger FCM via Firestore listener)
      await createNotification(
        userId: doctorId,
        title: 'New Appointment Request',
        body: '$patientName has requested an appointment for $appointmentTime',
        type: 'appointment_request',
        appointmentId: appointmentRef.id,
      );

      print('✅ Appointment booked: ${appointmentRef.id}');
      return appointmentRef.id;
    } catch (e) {
      print('❌ Error booking appointment: $e');
      return null;
    }
  }

  /// Confirm appointment (Doctor action) + Schedule reminder
  Future<void> confirmAppointment(String appointmentId) async {
    try {
      final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
      final data = appointmentDoc.data()!;

      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      // Notify patient
      await createNotification(
        userId: data['patientId'],
        title: 'Appointment Confirmed! 🎉',
        body: 'Dr. ${data['doctorName']} has confirmed your appointment',
        type: 'appointment_confirmed',
        appointmentId: appointmentId,
      );

      // ⭐ SCHEDULE LOCAL REMINDER (30 minutes before)
      final appointmentDateTime = _parseAppointmentDateTime(
        data['appointmentDate'],
        data['appointmentTime'],
      );

      await _notificationService.scheduleAppointmentReminder(
        appointmentId: appointmentId,
        appointmentDateTime: appointmentDateTime,
        doctorName: data['doctorName'],
        appointmentType: data['appointmentType'],
      );

      print('✅ Appointment confirmed & reminder scheduled');
    } catch (e) {
      throw Exception('Failed to confirm appointment: $e');
    }
  }

  /// Delete/Cancel appointment + Cancel reminder
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
      final data = appointmentDoc.data()!;

      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Notify patient
      await createNotification(
        userId: data['patientId'],
        title: 'Appointment Cancelled',
        body: 'Your appointment with Dr. ${data['doctorName']} has been cancelled',
        type: 'appointment_cancelled',
        appointmentId: appointmentId,
      );

      // ⭐ CANCEL SCHEDULED REMINDER
      await _notificationService.cancelAppointmentReminder(appointmentId);

      print('✅ Appointment cancelled & reminder removed');
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  /// Create notification in Firestore (triggers FCM)
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? appointmentId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'appointmentId': appointmentId,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  /// Helper: Parse appointment date and time into DateTime
  DateTime _parseAppointmentDateTime(Timestamp dateTimestamp, String timeString) {
    final date = dateTimestamp.toDate();

    // Parse time string (e.g., "10:30 AM" or "14:30")
    final timeParts = timeString.replaceAll(RegExp(r'[^\d:]'), '').split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Handle AM/PM if present
    if (timeString.toUpperCase().contains('PM') && hour != 12) {
      hour += 12;
    } else if (timeString.toUpperCase().contains('AM') && hour == 12) {
      hour = 0;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  /// Get pending appointments (Requests tab)
  Stream<QuerySnapshot> getPendingAppointments(String doctorId) {
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get confirmed appointments (Booked tab)
  Stream<QuerySnapshot> getConfirmedAppointments(String doctorId) {
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'confirmed')
        .orderBy('appointmentDate')
        .snapshots();
  }

  /// Get all unique patients for doctor
  Stream<QuerySnapshot> getAllDoctorAppointments(String doctorId) {
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots();
  }

  /// Get patient details
  Future<Map<String, dynamic>?> getPatientDetails(String patientId) async {
    try {
      final doc = await _firestore.collection('users').doc(patientId).get();
      return doc.data();
    } catch (e) {
      print('Error fetching patient details: $e');
      return null;
    }
  }

  /// Initialize chat between doctor and patient
  Future<String> initializeChat(String doctorId, String patientId) async {
    try {
      final chatId = doctorId.compareTo(patientId) < 0
          ? '${doctorId}_$patientId'
          : '${patientId}_$doctorId';

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'participants': [doctorId, patientId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      }

      return chatId;
    } catch (e) {
      throw Exception('Failed to initialize chat: $e');
    }
  }

  /// Send chat message with notification
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
  }) async {
    try {
      // Add message to messages subcollection
      await _firestore.collection('chats').doc(chatId).collection('messages').add({
        'senderId': senderId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update chat document with last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // ⭐ NOTIFY THE RECIPIENT
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final participants = List<String>.from(chatDoc.data()!['participants']);
      final recipientId = participants.firstWhere((id) => id != senderId);

      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final senderName = senderDoc.data()?['name'] ?? 'Someone';

      await createNotification(
        userId: recipientId,
        title: 'New message from $senderName',
        body: message,
        type: 'chat_message',
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get chat messages
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get all chats for user
  Stream<QuerySnapshot> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Generate video call channel
  String generateVideoCallChannel(String appointmentId) {
    return 'appointment_$appointmentId';
  }

  /// Get doctor metrics
  Future<Map<String, int>> getDoctorMetrics(String doctorId) async {
    try {
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final uniquePatients = <String>{};
      int videoCallsCount = 0;

      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        uniquePatients.add(data['patientId']);
        if (data['appointmentType'] == 'video') {
          videoCallsCount++;
        }
      }

      return {
        'appointments': appointmentsSnapshot.docs.length,
        'patients': uniquePatients.length,
        'videoCalls': videoCallsCount,
      };
    } catch (e) {
      print('Error getting metrics: $e');
      return {
        'appointments': 0,
        'patients': 0,
        'videoCalls': 0,
      };
    }
  }
}








// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class EnhancedAppointmentService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   /// Book an appointment with notification
//   Future<String?> bookAppointment({
//     required String doctorId,
//     required String doctorName,
//     required DateTime appointmentDate,
//     required String appointmentTime,
//     required double fee,
//     required String appointmentType,
//   }) async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) throw Exception('User not logged in');
//
//       final patientDoc = await _firestore.collection('users').doc(user.uid).get();
//       final patientData = patientDoc.data();
//       final patientName = patientData?['name'] ?? user.email ?? 'Unknown Patient';
//       final patientPhone = patientData?['phone'] ?? '';
//
//       final appointmentRef = await _firestore.collection('appointments').add({
//         'doctorId': doctorId,
//         'doctorName': doctorName,
//         'patientId': user.uid,
//         'patientName': patientName,
//         'patientEmail': user.email,
//         'patientPhone': patientPhone,
//         'appointmentDate': Timestamp.fromDate(appointmentDate),
//         'appointmentTime': appointmentTime,
//         'appointmentType': appointmentType,
//         'fee': fee,
//         'status': 'pending', // pending, confirmed, cancelled, completed
//         'createdAt': FieldValue.serverTimestamp(),
//         'location': patientData?['location'] ?? 'Douala',
//       });
//
//       // Create notification for doctor
//       await createNotification(
//         userId: doctorId,
//         title: 'New Appointment Request',
//         body: '$patientName has requested an appointment for $appointmentTime',
//         type: 'appointment_request',
//         appointmentId: appointmentRef.id,
//       );
//
//       print('✅ Appointment booked: ${appointmentRef.id}');
//       return appointmentRef.id;
//     } catch (e) {
//       print('❌ Error booking appointment: $e');
//       return null;
//     }
//   }
//
//   /// Confirm appointment (Doctor action)
//   Future<void> confirmAppointment(String appointmentId) async {
//     try {
//       final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
//       final data = appointmentDoc.data()!;
//
//       await _firestore.collection('appointments').doc(appointmentId).update({
//         'status': 'confirmed',
//         'confirmedAt': FieldValue.serverTimestamp(),
//       });
//
//       // Notify patient
//       await createNotification(
//         userId: data['patientId'],
//         title: 'Appointment Confirmed! 🎉',
//         body: 'Dr. ${data['doctorName']} has confirmed your appointment',
//         type: 'appointment_confirmed',
//         appointmentId: appointmentId,
//       );
//
//       print('✅ Appointment confirmed');
//     } catch (e) {
//       throw Exception('Failed to confirm appointment: $e');
//     }
//   }
//
//   /// Delete/Cancel appointment
//   Future<void> deleteAppointment(String appointmentId) async {
//     try {
//       final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
//       final data = appointmentDoc.data()!;
//
//       await _firestore.collection('appointments').doc(appointmentId).update({
//         'status': 'cancelled',
//         'cancelledAt': FieldValue.serverTimestamp(),
//       });
//
//       // Notify patient
//       await createNotification(
//         userId: data['patientId'],
//         title: 'Appointment Cancelled',
//         body: 'Your appointment with Dr. ${data['doctorName']} has been cancelled',
//         type: 'appointment_cancelled',
//         appointmentId: appointmentId,
//       );
//
//       print('✅ Appointment cancelled');
//     } catch (e) {
//       throw Exception('Failed to cancel appointment: $e');
//     }
//   }
//
//   /// Create notification
//   Future<void> createNotification({
//     required String userId,
//     required String title,
//     required String body,
//     required String type,
//     String? appointmentId,
//   }) async {
//     await _firestore.collection('notifications').add({
//       'userId': userId,
//       'title': title,
//       'body': body,
//       'type': type,
//       'appointmentId': appointmentId,
//       'createdAt': FieldValue.serverTimestamp(),
//       'read': false,
//     });
//   }
//
//   /// Get pending appointments (Requests tab)
//   Stream<QuerySnapshot> getPendingAppointments(String doctorId) {
//     return _firestore
//         .collection('appointments')
//         .where('doctorId', isEqualTo: doctorId)
//         .where('status', isEqualTo: 'pending')
//         .orderBy('createdAt', descending: true)
//         .snapshots();
//   }
//
//   /// Get confirmed appointments (Booked tab)
//   Stream<QuerySnapshot> getConfirmedAppointments(String doctorId) {
//     return _firestore
//         .collection('appointments')
//         .where('doctorId', isEqualTo: doctorId)
//         .where('status', isEqualTo: 'confirmed')
//         .orderBy('appointmentDate')
//         .snapshots();
//   }
//
//   /// Get all unique patients for doctor
//   Stream<QuerySnapshot> getAllDoctorAppointments(String doctorId) {
//     return _firestore
//         .collection('appointments')
//         .where('doctorId', isEqualTo: doctorId)
//         .snapshots();
//   }
//
//   /// Get patient details
//   Future<Map<String, dynamic>?> getPatientDetails(String patientId) async {
//     try {
//       final doc = await _firestore.collection('users').doc(patientId).get();
//       return doc.data();
//     } catch (e) {
//       print('Error fetching patient details: $e');
//       return null;
//     }
//   }
//
//   /// Initialize chat between doctor and patient
//   Future<String> initializeChat(String doctorId, String patientId) async {
//     try {
//       // Create a unique chat ID (sorted to ensure consistency)
//       final chatId = doctorId.compareTo(patientId) < 0
//           ? '${doctorId}_$patientId'
//           : '${patientId}_$doctorId';
//
//       // Check if chat already exists
//       final chatDoc = await _firestore.collection('chats').doc(chatId).get();
//
//       if (!chatDoc.exists) {
//         // Create new chat
//         await _firestore.collection('chats').doc(chatId).set({
//           'participants': [doctorId, patientId],
//           'createdAt': FieldValue.serverTimestamp(),
//           'lastMessage': '',
//           'lastMessageTime': FieldValue.serverTimestamp(),
//         });
//       }
//
//       return chatId;
//     } catch (e) {
//       throw Exception('Failed to initialize chat: $e');
//     }
//   }
//
//   /// Send chat message
//   Future<void> sendMessage({
//     required String chatId,
//     required String senderId,
//     required String message,
//   }) async {
//     try {
//       // Add message to messages subcollection
//       await _firestore.collection('chats').doc(chatId).collection('messages').add({
//         'senderId': senderId,
//         'message': message,
//         'timestamp': FieldValue.serverTimestamp(),
//         'read': false,
//       });
//
//       // Update chat document with last message
//       await _firestore.collection('chats').doc(chatId).update({
//         'lastMessage': message,
//         'lastMessageTime': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       throw Exception('Failed to send message: $e');
//     }
//   }
//
//   /// Get chat messages
//   Stream<QuerySnapshot> getChatMessages(String chatId) {
//     return _firestore
//         .collection('chats')
//         .doc(chatId)
//         .collection('messages')
//         .orderBy('timestamp', descending: true)
//         .snapshots();
//   }
//
//   /// Get all chats for user
//   Stream<QuerySnapshot> getUserChats(String userId) {
//     return _firestore
//         .collection('chats')
//         .where('participants', arrayContains: userId)
//         .orderBy('lastMessageTime', descending: true)
//         .snapshots();
//   }
//
//   /// Generate video call channel
//   String generateVideoCallChannel(String appointmentId) {
//     return 'appointment_$appointmentId';
//   }
//
//   /// Get doctor metrics
//   Future<Map<String, int>> getDoctorMetrics(String doctorId) async {
//     try {
//       final appointmentsSnapshot = await _firestore
//           .collection('appointments')
//           .where('doctorId', isEqualTo: doctorId)
//           .get();
//
//       final uniquePatients = <String>{};
//       int videoCallsCount = 0;
//
//       for (var doc in appointmentsSnapshot.docs) {
//         final data = doc.data();
//         uniquePatients.add(data['patientId']);
//         if (data['appointmentType'] == 'video') {
//           videoCallsCount++;
//         }
//       }
//
//       return {
//         'appointments': appointmentsSnapshot.docs.length,
//         'patients': uniquePatients.length,
//         'videoCalls': videoCallsCount,
//       };
//     } catch (e) {
//       print('Error getting metrics: $e');
//       return {
//         'appointments': 0,
//         'patients': 0,
//         'videoCalls': 0,
//       };
//     }
//   }
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// //
// //
// //
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// //
// // class SimpleAppointmentService {
// //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// //   final FirebaseAuth _auth = FirebaseAuth.instance;
// //
// //   /// Book an appointment - Simple version (no confirmations needed)
// //   Future<String?> bookAppointment({
// //     required String doctorId,
// //     required String doctorName,
// //     required DateTime appointmentDate,
// //     required String appointmentTime,
// //     required double fee,
// //     required String appointmentType, // 'video' or 'audio'
// //   }) async {
// //     try {
// //       final user = _auth.currentUser;
// //       if (user == null) throw Exception('User not logged in');
// //
// //       // Get patient info
// //       final patientDoc = await _firestore.collection('users').doc(user.uid).get();
// //       final patientData = patientDoc.data();
// //       final patientName = patientData?['name'] ?? user.email ?? 'Unknown Patient';
// //
// //       // Create appointment - directly active (no pending status)
// //       final appointmentRef = await _firestore.collection('appointments').add({
// //         'doctorId': doctorId,
// //         'doctorName': doctorName,
// //         'patientId': user.uid,
// //         'patientName': patientName,
// //         'patientEmail': user.email,
// //         'appointmentDate': Timestamp.fromDate(appointmentDate),
// //         'appointmentTime': appointmentTime,
// //         'appointmentType': appointmentType,
// //         'fee': fee,
// //         'createdAt': FieldValue.serverTimestamp(),
// //         'location': patientData?['location'] ?? 'Douala',
// //         'status': 'booked', // booked, completed, cancelled
// //       });
// //
// //       print('✅ Appointment booked: ${appointmentRef.id}');
// //       return appointmentRef.id;
// //     } catch (e) {
// //       print('❌ Error booking appointment: $e');
// //       return null;
// //     }
// //   }
// //
// //   /// Get upcoming appointments for user
// //   Stream<QuerySnapshot> getUpcomingAppointments(String userId, String role) {
// //     final field = role == 'doctor' ? 'doctorId' : 'patientId';
// //
// //     return _firestore
// //         .collection('appointments')
// //         .where(field, isEqualTo: userId)
// //         .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.now())
// //         .orderBy('appointmentDate')
// //         .snapshots();
// //   }
// //
// //   /// Get all appointments for user (including past)
// //   Stream<QuerySnapshot> getAllAppointments(String userId, String role) {
// //     final field = role == 'doctor' ? 'doctorId' : 'patientId';
// //
// //     return _firestore
// //         .collection('appointments')
// //         .where(field, isEqualTo: userId)
// //         .orderBy('createdAt', descending: true)
// //         .snapshots();
// //   }
// //
// //   /// Cancel appointment
// //   Future<void> cancelAppointment(String appointmentId) async {
// //     try {
// //       await _firestore.collection('appointments').doc(appointmentId).update({
// //         'status': 'cancelled',
// //         'cancelledAt': FieldValue.serverTimestamp(),
// //       });
// //     } catch (e) {
// //       throw Exception('Failed to cancel appointment: $e');
// //     }
// //   }
// //
// //   /// Mark appointment as completed
// //   Future<void> completeAppointment(String appointmentId) async {
// //     try {
// //       await _firestore.collection('appointments').doc(appointmentId).update({
// //         'status': 'completed',
// //         'completedAt': FieldValue.serverTimestamp(),
// //       });
// //     } catch (e) {
// //       throw Exception('Failed to complete appointment: $e');
// //     }
// //   }
// //
// //   /// Generate video call channel name
// //   String generateVideoCallChannel(String appointmentId) {
// //     return 'appointment_$appointmentId';
// //   }
// //
// //   /// Get appointment by ID
// //   Future<DocumentSnapshot> getAppointment(String appointmentId) async {
// //     return await _firestore.collection('appointments').doc(appointmentId).get();
// //   }
// //
// //   /// Check if appointment time is within 15 minutes
// //   bool isAppointmentStartingSoon(DateTime appointmentDate, String appointmentTime) {
// //     try {
// //       // Parse time (format: "10:30 AM")
// //       final timeParts = appointmentTime.split(' ');
// //       final hourMin = timeParts[0].split(':');
// //       int hour = int.parse(hourMin[0]);
// //       final minute = int.parse(hourMin[1]);
// //
// //       // Handle AM/PM
// //       if (timeParts.length > 1) {
// //         final period = timeParts[1].toUpperCase();
// //         if (period == 'PM' && hour != 12) {
// //           hour += 12;
// //         } else if (period == 'AM' && hour == 12) {
// //           hour = 0;
// //         }
// //       }
// //
// //       final appointmentDateTime = DateTime(
// //         appointmentDate.year,
// //         appointmentDate.month,
// //         appointmentDate.day,
// //         hour,
// //         minute,
// //       );
// //
// //       final now = DateTime.now();
// //       final difference = appointmentDateTime.difference(now);
// //
// //       // Within 15 minutes before or after
// //       return difference.inMinutes >= -15 && difference.inMinutes <= 15;
// //     } catch (e) {
// //       print('Error parsing time: $e');
// //       return false;
// //     }
// //   }
// //
// //   /// Get doctor's metrics
// //   Future<Map<String, int>> getDoctorMetrics(String doctorId) async {
// //     try {
// //       final appointmentsSnapshot = await _firestore
// //           .collection('appointments')
// //           .where('doctorId', isEqualTo: doctorId)
// //           .get();
// //
// //       final uniquePatients = <String>{};
// //       int videoCallsCount = 0;
// //
// //       for (var doc in appointmentsSnapshot.docs) {
// //         final data = doc.data();
// //         uniquePatients.add(data['patientId']);
// //         if (data['appointmentType'] == 'video') {
// //           videoCallsCount++;
// //         }
// //       }
// //
// //       return {
// //         'appointments': appointmentsSnapshot.docs.length,
// //         'patients': uniquePatients.length,
// //         'videoCalls': videoCallsCount,
// //       };
// //     } catch (e) {
// //       print('Error getting metrics: $e');
// //       return {
// //         'appointments': 0,
// //         'patients': 0,
// //         'videoCalls': 0,
// //       };
// //     }
// //   }
// //
// //   /// Get patient's upcoming appointments count
// //   Future<int> getPatientUpcomingAppointmentsCount(String patientId) async {
// //     try {
// //       final snapshot = await _firestore
// //           .collection('appointments')
// //           .where('patientId', isEqualTo: patientId)
// //           .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.now())
// //           .get();
// //
// //       return snapshot.docs.length;
// //     } catch (e) {
// //       return 0;
// //     }
// //   }
// // }
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // import 'package:firebase_auth/firebase_auth.dart';
// // // import 'package:flutter/material.dart';
// // //
// // // class AppointmentService {
// // //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// // //   final FirebaseAuth _auth = FirebaseAuth.instance;
// // //
// // //   /// Book an appointment and create notifications
// // //   Future<String?> bookAppointment({
// // //     required String doctorId,
// // //     required String doctorName,
// // //     required DateTime appointmentDate,
// // //     required TimeOfDay appointmentTime,
// // //     required double fee,
// // //     required String appointmentType, // 'video' or 'audio'
// // //   }) async {
// // //     try {
// // //       final user = _auth.currentUser;
// // //       if (user == null) throw Exception('User not logged in');
// // //
// // //       // Get patient info
// // //       final patientDoc = await _firestore.collection('users').doc(user.uid).get();
// // //       final patientData = patientDoc.data();
// // //       final patientName = patientData?['name'] ?? user.email ?? 'Unknown Patient';
// // //
// // //       // Combine date and time
// // //       final fullDateTime = DateTime(
// // //         appointmentDate.year,
// // //         appointmentDate.month,
// // //         appointmentDate.day,
// // //         appointmentTime.hour,
// // //         appointmentTime.minute,
// // //       );
// // //
// // //       // Create appointment
// // //       final appointmentRef = await _firestore.collection('appointments').add({
// // //         'doctorId': doctorId,
// // //         'doctorName': doctorName,
// // //         'patientId': user.uid,
// // //         'patientName': patientName,
// // //         'patientEmail': user.email,
// // //         'appointmentDate': Timestamp.fromDate(fullDateTime),
// // //         'appointmentTime': '${appointmentTime.hour}:${appointmentTime.minute.toString().padLeft(2, '0')}',
// // //         'appointmentType': appointmentType,
// // //         'fee': fee,
// // //         'status': 'pending', // pending, confirmed, rejected, completed, cancelled
// // //         'createdAt': FieldValue.serverTimestamp(),
// // //         'location': patientData?['location'] ?? 'Douala',
// // //         'paymentStatus': 'pending', // pending, paid, refunded
// // //       });
// // //
// // //       // Create notification for doctor
// // //       await _firestore.collection('notifications').add({
// // //         'userId': doctorId,
// // //         'title': 'New Appointment Request',
// // //         'body': '$patientName has requested an appointment',
// // //         'type': 'appointment_request',
// // //         'appointmentId': appointmentRef.id,
// // //         'createdAt': FieldValue.serverTimestamp(),
// // //         'read': false,
// // //         'actionUrl': '/appointments/${appointmentRef.id}',
// // //       });
// // //
// // //       // Schedule reminder notifications (to be sent 24h and 1h before)
// // //       await _scheduleReminders(appointmentRef.id, fullDateTime, doctorId, user.uid, doctorName, patientName);
// // //
// // //       return appointmentRef.id;
// // //     } catch (e) {
// // //       print('Error booking appointment: $e');
// // //       return null;
// // //     }
// // //   }
// // //
// // //   /// Schedule reminder notifications
// // //   Future<void> _scheduleReminders(
// // //       String appointmentId,
// // //       DateTime appointmentDateTime,
// // //       String doctorId,
// // //       String patientId,
// // //       String doctorName,
// // //       String patientName,
// // //       ) async {
// // //     // Calculate reminder times
// // //     final oneDayBefore = appointmentDateTime.subtract(const Duration(days: 1));
// // //     final oneHourBefore = appointmentDateTime.subtract(const Duration(hours: 1));
// // //     final fifteenMinBefore = appointmentDateTime.subtract(const Duration(minutes: 15));
// // //
// // //     // Store scheduled reminders
// // //     await _firestore.collection('scheduled_reminders').add({
// // //       'appointmentId': appointmentId,
// // //       'reminders': [
// // //         {
// // //           'scheduledFor': Timestamp.fromDate(oneDayBefore),
// // //           'type': '24h_before',
// // //           'sent': false,
// // //           'recipients': [doctorId, patientId],
// // //         },
// // //         {
// // //           'scheduledFor': Timestamp.fromDate(oneHourBefore),
// // //           'type': '1h_before',
// // //           'sent': false,
// // //           'recipients': [doctorId, patientId],
// // //         },
// // //         {
// // //           'scheduledFor': Timestamp.fromDate(fifteenMinBefore),
// // //           'type': '15m_before',
// // //           'sent': false,
// // //           'recipients': [doctorId, patientId],
// // //         },
// // //       ],
// // //       'createdAt': FieldValue.serverTimestamp(),
// // //     });
// // //   }
// // //
// // //   /// Get upcoming appointments for user
// // //   Stream<QuerySnapshot> getUpcomingAppointments(String userId, String role) {
// // //     final field = role == 'doctor' ? 'doctorId' : 'patientId';
// // //
// // //     return _firestore
// // //         .collection('appointments')
// // //         .where(field, isEqualTo: userId)
// // //         .where('status', whereIn: ['pending', 'confirmed'])
// // //         .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.now())
// // //         .orderBy('appointmentDate')
// // //         .snapshots();
// // //   }
// // //
// // //   /// Get appointment history
// // //   Stream<QuerySnapshot> getAppointmentHistory(String userId, String role) {
// // //     final field = role == 'doctor' ? 'doctorId' : 'patientId';
// // //
// // //     return _firestore
// // //         .collection('appointments')
// // //         .where(field, isEqualTo: userId)
// // //         .where('status', whereIn: ['completed', 'cancelled', 'rejected'])
// // //         .orderBy('appointmentDate', descending: true)
// // //         .limit(20)
// // //         .snapshots();
// // //   }
// // //
// // //   /// Confirm appointment (doctor only)
// // //   Future<void> confirmAppointment(String appointmentId, Map<String, dynamic> appointmentData) async {
// // //     try {
// // //       await _firestore.collection('appointments').doc(appointmentId).update({
// // //         'status': 'confirmed',
// // //         'confirmedAt': FieldValue.serverTimestamp(),
// // //       });
// // //
// // //       // Notify patient
// // //       await _firestore.collection('notifications').add({
// // //         'userId': appointmentData['patientId'],
// // //         'title': 'Appointment Confirmed! 🎉',
// // //         'body': 'Dr. ${appointmentData['doctorName']} has confirmed your appointment',
// // //         'type': 'appointment_confirmed',
// // //         'appointmentId': appointmentId,
// // //         'createdAt': FieldValue.serverTimestamp(),
// // //         'read': false,
// // //         'actionUrl': '/appointments/$appointmentId',
// // //       });
// // //     } catch (e) {
// // //       throw Exception('Failed to confirm appointment: $e');
// // //     }
// // //   }
// // //
// // //   /// Cancel appointment
// // //   Future<void> cancelAppointment(String appointmentId, String reason, String userRole) async {
// // //     try {
// // //       final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
// // //       final data = appointmentDoc.data()!;
// // //
// // //       await _firestore.collection('appointments').doc(appointmentId).update({
// // //         'status': 'cancelled',
// // //         'cancelledAt': FieldValue.serverTimestamp(),
// // //         'cancellationReason': reason,
// // //         'cancelledBy': userRole,
// // //       });
// // //
// // //       // Notify the other party
// // //       final recipientId = userRole == 'doctor' ? data['patientId'] : data['doctorId'];
// // //       final recipientName = userRole == 'doctor' ? data['patientName'] : data['doctorName'];
// // //
// // //       await _firestore.collection('notifications').add({
// // //         'userId': recipientId,
// // //         'title': 'Appointment Cancelled',
// // //         'body': 'Your appointment has been cancelled. Reason: $reason',
// // //         'type': 'appointment_cancelled',
// // //         'appointmentId': appointmentId,
// // //         'createdAt': FieldValue.serverTimestamp(),
// // //         'read': false,
// // //       });
// // //     } catch (e) {
// // //       throw Exception('Failed to cancel appointment: $e');
// // //     }
// // //   }
// // //
// // //   /// Mark appointment as completed
// // //   Future<void> completeAppointment(String appointmentId) async {
// // //     try {
// // //       await _firestore.collection('appointments').doc(appointmentId).update({
// // //         'status': 'completed',
// // //         'completedAt': FieldValue.serverTimestamp(),
// // //       });
// // //     } catch (e) {
// // //       throw Exception('Failed to complete appointment: $e');
// // //     }
// // //   }
// // //
// // //   /// Generate video call token/channel for appointment
// // //   Future<String> generateVideoCallChannel(String appointmentId) async {
// // //     // Generate a unique channel name for Agora
// // //     final channel = 'appointment_$appointmentId';
// // //
// // //     // Store channel info in appointment
// // //     await _firestore.collection('appointments').doc(appointmentId).update({
// // //       'videoCallChannel': channel,
// // //       'videoCallStartedAt': FieldValue.serverTimestamp(),
// // //     });
// // //
// // //     return channel;
// // //   }
// // //
// // //   /// Get notifications for user
// // //   Stream<QuerySnapshot> getNotifications(String userId) {
// // //     return _firestore
// // //         .collection('notifications')
// // //         .where('userId', isEqualTo: userId)
// // //         .orderBy('createdAt', descending: true)
// // //         .limit(50)
// // //         .snapshots();
// // //   }
// // //
// // //   /// Mark notification as read
// // //   Future<void> markNotificationRead(String notificationId) async {
// // //     await _firestore.collection('notifications').doc(notificationId).update({
// // //       'read': true,
// // //       'readAt': FieldValue.serverTimestamp(),
// // //     });
// // //   }
// // //
// // //   /// Get unread notification count
// // //   Stream<int> getUnreadNotificationCount(String userId) {
// // //     return _firestore
// // //         .collection('notifications')
// // //         .where('userId', isEqualTo: userId)
// // //         .where('read', isEqualTo: false)
// // //         .snapshots()
// // //         .map((snapshot) => snapshot.docs.length);
// // //   }
// // // }
// // //
// // // // Cloud Function logic (to be implemented in Firebase Functions)
// // // /*
// // // exports.sendScheduledReminders = functions.pubsub
// // //   .schedule('every 5 minutes')
// // //   .onRun(async (context) => {
// // //     const now = admin.firestore.Timestamp.now();
// // //
// // //     // Get all reminders that need to be sent
// // //     const remindersSnapshot = await admin.firestore()
// // //       .collection('scheduled_reminders')
// // //       .get();
// // //
// // //     for (const doc of remindersSnapshot.docs) {
// // //       const data = doc.data();
// // //       const reminders = data.reminders;
// // //
// // //       for (const reminder of reminders) {
// // //         if (!reminder.sent && reminder.scheduledFor <= now) {
// // //           // Send notification to all recipients
// // //           for (const userId of reminder.recipients) {
// // //             await admin.firestore().collection('notifications').add({
// // //               userId: userId,
// // //               title: getReminder Title(reminder.type),
// // //               body: getReminderBody(reminder.type, data.appointmentId),
// // //               type: 'appointment_reminder',
// // //               appointmentId: data.appointmentId,
// // //               createdAt: admin.firestore.FieldValue.serverTimestamp(),
// // //               read: false,
// // //             });
// // //           }
// // //
// // //           // Mark reminder as sent
// // //           reminder.sent = true;
// // //           await doc.ref.update({ reminders: reminders });
// // //         }
// // //       }
// // //     }
// // //   });
// // // */