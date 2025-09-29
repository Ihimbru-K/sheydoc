import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheydoc_app/features/doctor/home/home_screen.dart';
import 'package:sheydoc_app/features/auth/doctors/approved_screen.dart';

import '../auth/patients/home/home_screen.dart';
import 'onboarding_screen1.dart';
import 'role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () async {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is logged in - check Firestore for profile data
        try {
          final snap = await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get();

          if (snap.exists) {
            final data = snap.data() as Map<String, dynamic>;
            final role = data['role'] as String?;
            final profileComplete = data['profileComplete'] == true;
            final approvalStatus = data['approvalStatus'] as String?;

            if (role == "doctor") {
              // Handle Doctor routing
              if (profileComplete && approvalStatus == 'approved') {
                // Doctor is fully set up and approved
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorHomeScreen()),
                );
              } else if (profileComplete && approvalStatus == 'pending') {
                // Doctor is awaiting approval
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ApprovalScreen(role: "doctor")),
                );
              } else {
                // Doctor profile incomplete - send to role selection to restart
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                );
              }
            } else if (role == "patient") {
              // Handle Patient routing
              if (profileComplete && approvalStatus == 'approved') {
                // Patient is fully set up (auto-approved)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
                );
              } else {
                // Patient profile incomplete - send to role selection to restart
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                );
              }
            } else {
              // No role assigned yet - send to role selection
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              );
            }
          } else {
            // User logged in but no profile document - send to role selection
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
            );
          }
        } catch (e) {
          // Error reading Firestore - send to role selection
          debugPrint("Error reading user profile: $e");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          );
        }
      } else {
        // No user logged in - show onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen1()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          "assets/images/logos/logo.png",
          width: 250,
          height: 250,
        ),
      ),
    );
  }
}




























// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:sheydoc_app/features/doctor/home/home_screen.dart';
//
// import 'onboarding_screen1.dart';
// import 'role_selection_screen.dart';
//
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//
//     Timer(const Duration(seconds: 3), () async {
//       final user = FirebaseAuth.instance.currentUser;
//
//       if (user != null) {
//         // check Firestore for role
//         final snap = await FirebaseFirestore.instance
//             .collection("users")
//             .doc(user.uid)
//             .get();
//
//         if (snap.exists) {
//           final role = snap["role"];
//           if (role == "doctor") {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const HomeScreen()),
//             );
//           } else {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const HomeScreen()),
//             );
//           }
//         } else {
//           // user logged in but no role → send to role selection
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
//           );
//         }
//       } else {
//         // new user → onboarding
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const OnboardingScreen1()),
//         );
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Image.asset(
//           "assets/images/logos/logo.png",
//           width: 250,
//           height: 250,
//         ),
//       ),
//     );
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
//
//
// // import 'dart:async';
// // import 'package:flutter/material.dart';
// //
// // import 'onboarding_screen1.dart';
// //
// //
// //
// //
// // class SplashScreen extends StatefulWidget {
// //   const SplashScreen({super.key});
// //
// //   @override
// //   State<SplashScreen> createState() => _SplashScreenState();
// // }
// //
// // class _SplashScreenState extends State<SplashScreen> {
// //   @override
// //   void initState() {
// //     super.initState();
// //     // Set splash duration (2 seconds)
// //     Timer(const Duration(seconds: 3), () {
// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(builder: (context) => const OnboardingScreen1()),
// //       );
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       body: Center(
// //         child: Image.asset(
// //           "assets/images/logos/logo.png",
// //           width: 250,
// //           height: 250,
// //         ),
// //       ),
// //     );
// //   }
// // }