import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ The secret admin code (store this securely in production)
  // In production, consider using Firebase Remote Config or environment variables
  static const String ADMIN_SECRET_CODE = "SHEYDOC2026";

  // ✅ Pre-defined admin email (used for Firebase Auth)
  static const String ADMIN_EMAIL = "admin@sheydoc.com";
  static const String ADMIN_PASSWORD = "AdminSheyDoc2025!";

  /// Verify admin code and sign in
  Future<User?> signInAsAdmin(String code) async {
    try {
      // Step 1: Verify the admin code
      if (code != ADMIN_SECRET_CODE) {
        throw Exception("Invalid admin code");
      }

      // Step 2: Check if admin account exists, if not create it
      User? adminUser;
      try {
        // Try signing in first
        final userCred = await _auth.signInWithEmailAndPassword(
          email: ADMIN_EMAIL,
          password: ADMIN_PASSWORD,
        );
        adminUser = userCred.user;
        print("✅ Admin signed in successfully");
      } catch (e) {
        // If sign-in fails, create the admin account
        print("Admin account doesn't exist, creating...");
        final userCred = await _auth.createUserWithEmailAndPassword(
          email: ADMIN_EMAIL,
          password: ADMIN_PASSWORD,
        );
        adminUser = userCred.user;
        print("✅ Admin account created");
      }

      if (adminUser == null) {
        throw Exception("Failed to authenticate admin");
      }

      // Step 3: Create/update admin document in Firestore
      await _createOrUpdateAdminDocument(adminUser.uid);

      return adminUser;
    } catch (e) {
      print("❌ Admin sign-in failed: $e");
      throw Exception("Admin authentication failed: $e");
    }
  }

  /// Create or update admin document in Firestore
  Future<void> _createOrUpdateAdminDocument(String uid) async {
    try {
      final adminDoc = await _firestore.collection("users").doc(uid).get();

      if (!adminDoc.exists) {
        // Create new admin document
        await _firestore.collection("users").doc(uid).set({
          "uid": uid,
          "email": ADMIN_EMAIL,
          "role": "admin",
          "name": "System Administrator",
          "createdAt": FieldValue.serverTimestamp(),
          "isActive": true,
        });
        print("✅ Admin document created in Firestore");
      } else {
        // Ensure role is set to admin (in case it was changed)
        await _firestore.collection("users").doc(uid).update({
          "role": "admin",
          "lastLoginAt": FieldValue.serverTimestamp(),
        });
        print("✅ Admin document updated");
      }
    } catch (e) {
      print("❌ Error creating/updating admin document: $e");
      throw Exception("Failed to setup admin profile: $e");
    }
  }

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _firestore.collection("users").doc(currentUser.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      return userData?['role'] == 'admin';
    } catch (e) {
      print("❌ Error checking admin status: $e");
      return false;
    }
  }

  /// Get current admin user
  User? get currentAdmin => _auth.currentUser;

  /// Sign out admin
  Future<void> signOut() async {
    await _auth.signOut();
  }
}