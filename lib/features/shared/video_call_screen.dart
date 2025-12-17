import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sheydoc_app/core/constants/app_colors.dart';

class VideoCallScreen extends StatefulWidget {
  final String appointmentId;
  final String channelName;
  final String otherUserName;
  final String otherUserId;
  final bool isDoctor;

  const VideoCallScreen({
    super.key,
    required this.appointmentId,
    required this.channelName,
    required this.otherUserName,
    required this.otherUserId,
    required this.isDoctor,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late AgoraClient client;
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _error;
  DateTime? _callStartTime;

  // Replace with your actual Agora App ID
  static const String _appId = "c032b56943db459688e5aadd06cad578";

  @override
  void initState() {
    super.initState();
    _initializeAgora();
    _markCallAsStarted();
  }

  Future<void> _initializeAgora() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      // 🔍 DEBUGGING: Print channel info
      print('═══════════════════════════════════════════');
      print('🎥 VIDEO CALL DEBUG INFO');
      print('═══════════════════════════════════════════');
      print('📌 Appointment ID: ${widget.appointmentId}');
      print('📺 Channel Name: ${widget.channelName}');
      print('👤 User ID: ${user.uid}');
      print('🔑 App ID: ${_appId.substring(0, 8)}...');
      print('👥 Other User: ${widget.otherUserName}');
      print('🏥 Is Doctor: ${widget.isDoctor}');
      print('═══════════════════════════════════════════');

      // Initialize Agora client
      client = AgoraClient(
        agoraConnectionData: AgoraConnectionData(
          appId: _appId,
          channelName: widget.channelName,
          username: user.uid,
        ),
        enabledPermission: [
          Permission.camera,
          Permission.microphone,
        ],
      );

      print('✅ AgoraClient created, initializing...');

      // Initialize the client
      await client.initialize();

      print('✅ Agora initialized successfully!');

      setState(() {
        _isInitialized = true;
        _isLoading = false;
        _callStartTime = DateTime.now();
      });

      // Log call start in Firestore
      await _logCallStart();
    } catch (e) {
      print("Error initializing Agora: $e");
      setState(() {
        _error = "Failed to initialize video call: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _logCallStart() async {
    try {
      await FirebaseFirestore.instance
          .collection('call_logs')
          .doc(widget.appointmentId)
          .set({
        'appointmentId': widget.appointmentId,
        'channelName': widget.channelName,
        'startTime': FieldValue.serverTimestamp(),
        'doctorId': widget.isDoctor ? FirebaseAuth.instance.currentUser?.uid : widget.otherUserId,
        'patientId': widget.isDoctor ? widget.otherUserId : FirebaseAuth.instance.currentUser?.uid,
        'status': 'ongoing',
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error logging call start: $e");
    }
  }

  Future<void> _markCallAsStarted() async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'callStatus': 'ongoing',
        'callStartedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating appointment: $e");
    }
  }

  Future<void> _endCall() async {
    try {
      final duration = _callStartTime != null
          ? DateTime.now().difference(_callStartTime!).inSeconds
          : 0;

      // Update call log
      await FirebaseFirestore.instance
          .collection('call_logs')
          .doc(widget.appointmentId)
          .update({
        'endTime': FieldValue.serverTimestamp(),
        'duration': duration,
        'status': 'completed',
      });

      // Update appointment status
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'callStatus': 'completed',
        'callEndedAt': FieldValue.serverTimestamp(),
        'callDuration': duration,
      });

      // Send notification to the other user
      await _sendCallEndNotification();

    } catch (e) {
      print("Error ending call: $e");
    }
  }

  Future<void> _sendCallEndNotification() async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': widget.otherUserId,
        'title': 'Call Ended',
        'body': 'Your call with ${widget.isDoctor ? "patient" : "doctor"} has ended',
        'type': 'call_ended',
        'appointmentId': widget.appointmentId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  @override
  void dispose() {
    client.sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryBlue),
              SizedBox(height: 20.h),
              Text(
                'Connecting to ${widget.otherUserName}...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 64.sp),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 30.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Go Back',
                  style: TextStyle(fontSize: 16.sp),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Video view
            AgoraVideoViewer(
              client: client,
              layoutType: Layout.floating,
              enableHostControls: true,
              showNumberOfUsers: true,
            ),

            // Top bar with user info
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8.w,
                                height: 8.h,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            widget.otherUserName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                          onPressed: () async {
                            final shouldEnd = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('End Call'),
                                content: const Text('Are you sure you want to end this call?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('End Call'),
                                  ),
                                ],
                              ),
                            );

                            if (shouldEnd == true) {
                              await _endCall();
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Control buttons at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: AgoraVideoButtons(
                  client: client,
                  addScreenSharing: false,
                  disconnectButtonChild: Container(
                    width: 60.w,
                    height: 60.h,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 30.sp,
                    ),
                  ),
                  // onDisconnect: (context) async {
                  //   await _endCall();
                  // },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




// import 'package:agora_uikit/agora_uikit.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:sheydoc_app/core/constants/app_colors.dart';
//
// class VideoCallScreen extends StatefulWidget {
//   final String appointmentId;
//   final String channelName;
//   final String otherUserName;
//   final String otherUserId;
//   final bool isDoctor;
//
//   const VideoCallScreen({
//     super.key,
//     required this.appointmentId,
//     required this.channelName,
//     required this.otherUserName,
//     required this.otherUserId,
//     required this.isDoctor,
//   });
//
//   @override
//   State<VideoCallScreen> createState() => _VideoCallScreenState();
// }
//
// class _VideoCallScreenState extends State<VideoCallScreen> {
//   late AgoraClient client;
//   bool _isInitialized = false;
//   bool _isLoading = true;
//   String? _error;
//   DateTime? _callStartTime;
//
//   // Replace with your actual Agora App ID
//   static const String _appId = "c032b56943db459688e5aadd06cad578";
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeAgora();
//     _markCallAsStarted();
//   }
//
//   Future<void> _initializeAgora() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         throw Exception("User not authenticated");
//       }
//
//       // Initialize Agora client
//       client = AgoraClient(
//         agoraConnectionData: AgoraConnectionData(
//           appId: _appId,
//           channelName: widget.channelName,
//           username: user.uid,
//         ),
//         enabledPermission: [
//           Permission.camera,
//           Permission.microphone,
//         ],
//       );
//
//       // Initialize the client
//       await client.initialize();
//
//       setState(() {
//         _isInitialized = true;
//         _isLoading = false;
//         _callStartTime = DateTime.now();
//       });
//
//       // Log call start in Firestore
//       await _logCallStart();
//     } catch (e) {
//       print("Error initializing Agora: $e");
//       setState(() {
//         _error = "Failed to initialize video call: $e";
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _logCallStart() async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('call_logs')
//           .doc(widget.appointmentId)
//           .set({
//         'appointmentId': widget.appointmentId,
//         'channelName': widget.channelName,
//         'startTime': FieldValue.serverTimestamp(),
//         'doctorId': widget.isDoctor ? FirebaseAuth.instance.currentUser?.uid : widget.otherUserId,
//         'patientId': widget.isDoctor ? widget.otherUserId : FirebaseAuth.instance.currentUser?.uid,
//         'status': 'ongoing',
//       }, SetOptions(merge: true));
//     } catch (e) {
//       print("Error logging call start: $e");
//     }
//   }
//
//   Future<void> _markCallAsStarted() async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('appointments')
//           .doc(widget.appointmentId)
//           .update({
//         'callStatus': 'ongoing',
//         'callStartedAt': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       print("Error updating appointment: $e");
//     }
//   }
//
//   Future<void> _endCall() async {
//     try {
//       final duration = _callStartTime != null
//           ? DateTime.now().difference(_callStartTime!).inSeconds
//           : 0;
//
//       // Update call log
//       await FirebaseFirestore.instance
//           .collection('call_logs')
//           .doc(widget.appointmentId)
//           .update({
//         'endTime': FieldValue.serverTimestamp(),
//         'duration': duration,
//         'status': 'completed',
//       });
//
//       // Update appointment status
//       await FirebaseFirestore.instance
//           .collection('appointments')
//           .doc(widget.appointmentId)
//           .update({
//         'callStatus': 'completed',
//         'callEndedAt': FieldValue.serverTimestamp(),
//         'callDuration': duration,
//       });
//
//       // Send notification to the other user
//       await _sendCallEndNotification();
//
//     } catch (e) {
//       print("Error ending call: $e");
//     }
//   }
//
//   Future<void> _sendCallEndNotification() async {
//     try {
//       await FirebaseFirestore.instance.collection('notifications').add({
//         'userId': widget.otherUserId,
//         'title': 'Call Ended',
//         'body': 'Your call with ${widget.isDoctor ? "patient" : "doctor"} has ended',
//         'type': 'call_ended',
//         'appointmentId': widget.appointmentId,
//         'createdAt': FieldValue.serverTimestamp(),
//         'read': false,
//       });
//     } catch (e) {
//       print("Error sending notification: $e");
//     }
//   }
//
//   @override
//   void dispose() {
//     client.sessionController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         backgroundColor: Colors.black,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(color: AppColors.primaryBlue),
//               SizedBox(height: 20.h),
//               Text(
//                 'Connecting to ${widget.otherUserName}...',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     if (_error != null) {
//       return Scaffold(
//         backgroundColor: Colors.black,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.error_outline, color: Colors.red, size: 64.sp),
//               SizedBox(height: 20.h),
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 32.w),
//                 child: Text(
//                   _error!,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16.sp,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               SizedBox(height: 30.h),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(context),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primaryBlue,
//                   padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8.r),
//                   ),
//                 ),
//                 child: Text(
//                   'Go Back',
//                   style: TextStyle(fontSize: 16.sp),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     return Scaffold(
//       body: SafeArea(
//         child: Stack(
//           children: [
//             // Video view
//             AgoraVideoViewer(
//               client: client,
//               layoutType: Layout.floating,
//               enableHostControls: true,
//               showNumberOfUsers: true,
//             ),
//
//             // Top bar with user info
//             Positioned(
//               top: 0,
//               left: 0,
//               right: 0,
//               child: Container(
//                 padding: EdgeInsets.all(16.w),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.black.withOpacity(0.7),
//                       Colors.transparent,
//                     ],
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: 12.w,
//                             vertical: 6.h,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.red,
//                             borderRadius: BorderRadius.circular(4.r),
//                           ),
//                           child: Row(
//                             children: [
//                               Container(
//                                 width: 8.w,
//                                 height: 8.h,
//                                 decoration: const BoxDecoration(
//                                   color: Colors.white,
//                                   shape: BoxShape.circle,
//                                 ),
//                               ),
//                               SizedBox(width: 6.w),
//                               Text(
//                                 'LIVE',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12.sp,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         SizedBox(width: 12.w),
//                         Expanded(
//                           child: Text(
//                             widget.otherUserName,
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 16.sp,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                         IconButton(
//                           icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
//                           onPressed: () async {
//                             final shouldEnd = await showDialog<bool>(
//                               context: context,
//                               builder: (context) => AlertDialog(
//                                 title: const Text('End Call'),
//                                 content: const Text('Are you sure you want to end this call?'),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () => Navigator.pop(context, false),
//                                     child: const Text('Cancel'),
//                                   ),
//                                   TextButton(
//                                     onPressed: () => Navigator.pop(context, true),
//                                     style: TextButton.styleFrom(
//                                       foregroundColor: Colors.red,
//                                     ),
//                                     child: const Text('End Call'),
//                                   ),
//                                 ],
//                               ),
//                             );
//
//                             if (shouldEnd == true) {
//                               await _endCall();
//                               if (mounted) {
//                                 Navigator.pop(context);
//                               }
//                             }
//                           },
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             // Control buttons at bottom
//             Positioned(
//               bottom: 0,
//               left: 0,
//               right: 0,
//               child: Container(
//                 padding: EdgeInsets.all(20.w),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.bottomCenter,
//                     end: Alignment.topCenter,
//                     colors: [
//                       Colors.black.withOpacity(0.7),
//                       Colors.transparent,
//                     ],
//                   ),
//                 ),
//                 child: AgoraVideoButtons(
//                   client: client,
//                   addScreenSharing: false,
//                   disconnectButtonChild: Container(
//                     width: 60.w,
//                     height: 60.h,
//                     decoration: BoxDecoration(
//                       color: Colors.red,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.call_end,
//                       color: Colors.white,
//                       size: 30.sp,
//                     ),
//                   ),
//                   // onDisconnect: (context) async {
//                   //   await _endCall();
//                   // },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }