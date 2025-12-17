import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/utils/time_range.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Email sign up
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection("users").doc(userCred.user!.uid).set({
        "uid": userCred.user!.uid,
        "email": email,
        "role": role,
        "createdAt": FieldValue.serverTimestamp(),
        "personalInfoComplete": false,
        "professionalInfoComplete": false,
        "availabilityComplete": false,
        "profileComplete": false,
        "approvalStatus": "pending", // pending, approved, rejected
      });

      return userCred.user;
    } catch (e) {
      throw Exception("Sign up failed: $e");
    }
  }

  // ✅ Email sign in
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCred.user;
    } catch (e) {
      throw Exception("Sign in failed: $e");
    }
  }

  // ✅ NEW: Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection("users").doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("Error fetching user profile: $e");
      return null;
    }
  }

  // ✅ Save user profile info with completion tracking
  Future<void> saveUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection("users").doc(uid).update(data);

    // Check if all steps are complete and update profileComplete status
    final userDoc = await _firestore.collection("users").doc(uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final personalComplete = userData['personalInfoComplete'] ?? false;
      final professionalComplete = userData['professionalInfoComplete'] ?? false;
      final availabilityComplete = userData['availabilityComplete'] ?? false;

      if (personalComplete && professionalComplete && availabilityComplete) {
        await _firestore.collection("users").doc(uid).update({
          'profileComplete': true,
          'approvalStatus': 'pending', // Ready for admin approval
        });
      }
    }
  }

  // ✅ Upload file as Base64 string to Firestore
  Future<void> uploadFileAsBase64({
    required String uid,
    required String fieldName,
    required String? filePath,
  }) async {
    if (filePath == null || filePath.isEmpty) {
      print("⚠️ No file selected for $fieldName");
      return;
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      print("⚠️ File not found at $filePath");
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);

      await _firestore.collection("users").doc(uid).update({
        fieldName: base64Str,
      });

      print("✅ File saved as base64 under field '$fieldName'");
    } catch (e) {
      print("❌ Base64 upload failed: $e");
      throw Exception("Base64 upload failed: $e");
    }
  }

  // ✅ Save doctor details
  Future<void> saveDoctorDetails({
    required String uid,
    required String? photoBase64,
    required int yearsOfExperience,
    required double rating,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (photoBase64 != null) data["photo"] = photoBase64;
      data["yearsOfExperience"] = yearsOfExperience;
      data["rating"] = rating;

      // Use set with merge instead of update
      await _firestore.collection("users").doc(uid).set(data, SetOptions(merge: true));
      print("✅ Doctor details saved successfully");
    } catch (e) {
      print("❌ Error saving doctor details: $e");
      throw Exception("Failed to save doctor details: $e");
    }
  }

  // ✅ FIXED: Save doctor availability and mark as complete
  Future<void> saveDoctorAvailability({
    required String uid,
    required Map<int, List<TimeRange>> schedule,
    required int defaultDuration,
    required double baseFee,
  }) async {
    try {
      // Convert to a simpler flat structure for Firestore
      final List<Map<String, dynamic>> availabilityList = [];

      schedule.forEach((dayIndex, ranges) {
        for (final range in ranges) {
          availabilityList.add({
            'day': dayIndex,
            'startHour': range.start.hour,
            'startMinute': range.start.minute,
            'endHour': range.end.hour,
            'endMinute': range.end.minute,
          });
        }
      });

      print("Saving availability data: $availabilityList");

      // Use set with merge to avoid update issues if document doesn't exist
      await _firestore.collection("users").doc(uid).set({
        "availability": availabilityList,
        "defaultDuration": defaultDuration,
        "baseFee": baseFee,
        "availabilityComplete": true,
      }, SetOptions(merge: true));

      print("✅ Availability saved successfully");

      // Check if profile is now complete
      await _checkAndUpdateProfileCompletion(uid);

    } catch (e) {
      print("❌ Error saving availability: $e");
      print("Error type: ${e.runtimeType}");
      throw Exception("Failed to save availability: $e");
    }
  }

  // ✅ Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ✅ Get current user
  User? get currentUser => _auth.currentUser;

  // ✅ Helper method to check and update profile completion status
  Future<void> _checkAndUpdateProfileCompletion(String uid) async {
    try {
      final userDoc = await _firestore.collection("users").doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final personalComplete = userData['personalInfoComplete'] ?? false;
        final professionalComplete = userData['professionalInfoComplete'] ?? false;
        final availabilityComplete = userData['availabilityComplete'] ?? false;

        if (personalComplete && professionalComplete && availabilityComplete) {
          await _firestore.collection("users").doc(uid).set({
            'profileComplete': true,
            'approvalStatus': 'pending',
          }, SetOptions(merge: true));
          print("✅ Profile marked as complete");
        }
      }
    } catch (e) {
      print("❌ Error checking profile completion: $e");
    }
  }
}
















