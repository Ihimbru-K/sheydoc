
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sheydoc_app/features/shared/onboarding/role_selection_screen.dart';

// Import screens
import 'features/auth/patients/messages/patient_messages_screen.dart';
import 'features/doctor/home/home_screen.dart';
import 'features/doctor/home/notification_screen.dart';
import 'features/doctor/messages/doctor_messages_screen.dart';
import 'features/doctor/messages/chat_screen.dart';
import 'features/doctor/video/doctor_video_patients_screen.dart';

import 'features/shared/onboarding/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // Home screen
          home: const SplashScreen(),

          // Named routes
          routes: {
            // '/welcome': (context) => const WelcomeScreen(role: '',),
            '/role-selection': (context) => const RoleSelectionScreen(),
            '/doctor/home': (context) => const DoctorHomeScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/doctor/messages': (context) => const DoctorMessagesScreen(),
            '/doctor/video-patients': (context) => const DoctorVideoPatientsScreen(),
            '/patient/messages': (context) => const PatientMessagesScreen(),
          },

          // Dynamic route for chat (requires arguments)
          onGenerateRoute: (settings) {
            if (settings.name == '/chat') {
              final args = settings.arguments as Map<String, dynamic>?;

              if (args == null) {
                // Handle missing arguments
                return MaterialPageRoute(
                  builder: (context) => const Scaffold(
                    body: Center(child: Text('Error: Missing chat arguments')),
                  ),
                );
              }

              return MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: args['chatId'] ?? '',
                  otherUserId: args['otherUserId'] ?? '',
                  otherUserName: args['otherUserName'] ?? 'Unknown',
                ),
              );
            }

            // Handle unknown routes
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('404 - Page not found')),
              ),
            );
          },
        );
      },
    );
  }
}











// import 'package:agora_uikit/agora_uikit.dart';
// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   final AgoraClient client = AgoraClient(
//     agoraConnectionData: AgoraConnectionData(
//       appId: "c032b56943db459688e5aadd06cad578",
//       channelName: "test",
//       username: "user",
//     ),
//   );
//
//   @override
//   void initState() {
//     super.initState();
//     initAgora();
//   }
//
//   void initAgora() async {
//     await client.initialize();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('SheyDoc video call screen'),
//           centerTitle: true,
//         ),
//         body: SafeArea(
//           child: Stack(
//             children: [
//               AgoraVideoViewer(
//                 client: client,
//                 layoutType: Layout.floating,
//                 enableHostControls: true, // Add this to enable host controls
//               ),
//               AgoraVideoButtons(
//                 client: client,
//                 addScreenSharing: false, // Add this to enable screen sharing
//               ),
//             ],
//           ),
//         ),
//       ),
//
