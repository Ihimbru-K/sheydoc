// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sheydoc_app/core/constants/app_colors.dart';
// import 'dart:async';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// /// 🎙️ SIMPLE WebRTC Audio Call - NO AGORA NEEDED!
// /// Uses peer-to-peer connection through Firestore signaling
// class SimpleAudioCallScreen extends StatefulWidget {
//   final String appointmentId;
//   final String channelName;
//   final String otherUserName;
//   final String otherUserId;
//   final bool isDoctor;
//
//   const SimpleAudioCallScreen({
//     super.key,
//     required this.appointmentId,
//     required this.channelName,
//     required this.otherUserName,
//     required this.otherUserId,
//     required this.isDoctor,
//   });
//
//   @override
//   State<SimpleAudioCallScreen> createState() => _SimpleAudioCallScreenState();
// }
//
// class _SimpleAudioCallScreenState extends State<SimpleAudioCallScreen> {
//   bool _isMuted = false;
//   bool _isSpeakerOn = true;
//   int _callDuration = 0;
//   Timer? _timer;
//   bool _isConnected = false;
//
//   // WebRTC objects
//   RTCPeerConnection? _peerConnection;
//   MediaStream? _localStream;
//   MediaStream? _remoteStream;
//
//   // Firestore for signaling
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   StreamSubscription? _signalingSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCall();
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     _endCall();
//     super.dispose();
//   }
//
//   Future<void> _initializeCall() async {
//     print('');
//     print('🎙️ INITIALIZING SIMPLE WEBRTC CALL');
//     print('📌 Channel: ${widget.channelName}');
//     print('👤 Other User: ${widget.otherUserName}');
//     print('');
//
//     // Request mic permission
//     await Permission.microphone.request();
//
//     // Initialize WebRTC
//     await _createPeerConnection();
//     await _getUserMedia();
//
//     // Start signaling
//     if (widget.isDoctor) {
//       // Doctor creates offer
//       await _createOffer();
//     } else {
//       // Patient waits for offer
//       _listenForOffer();
//     }
//   }
//
//   /// Create peer connection with audio only
//   Future<void> _createPeerConnection() async {
//     // Configuration for peer connection
//     Map<String, dynamic> configuration = {
//       'iceServers': [
//         {
//           'urls': [
//             'stun:stun1.l.google.com:19302',
//             'stun:stun2.l.google.com:19302',
//           ]
//         }
//       ]
//     };
//
//     // Create peer connection
//     _peerConnection = await createPeerConnection(configuration);
//
//     // Listen for ICE candidates
//     _peerConnection!.onIceCandidate = (candidate) {
//       if (candidate != null) {
//         _sendIceCandidate(candidate);
//       }
//     };
//
//     // Listen for remote stream
//     _peerConnection!.onTrack = (event) {
//       if (event.streams.isNotEmpty) {
//         setState(() {
//           _remoteStream = event.streams[0];
//           _isConnected = true;
//         });
//         _startTimer();
//         print('✅ Remote audio stream received!');
//       }
//     };
//
//     // Listen for connection state
//     _peerConnection!.onConnectionState = (state) {
//       print('🔌 Connection state: $state');
//       if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
//         setState(() => _isConnected = true);
//       }
//     };
//
//     print('✅ Peer connection created');
//   }
//
//   /// Get user's microphone audio
//   Future<void> _getUserMedia() async {
//     try {
//       final Map<String, dynamic> mediaConstraints = {
//         'audio': true,
//         'video': false,
//       };
//
//       _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
//
//       // Add local stream tracks to peer connection
//       _localStream!.getTracks().forEach((track) {
//         _peerConnection!.addTrack(track, _localStream!);
//       });
//
//       print('🎤 Local microphone stream obtained');
//     } catch (e) {
//       print('❌ Error getting microphone: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Could not access microphone: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   /// Create and send offer (Doctor side)
//   Future<void> _createOffer() async {
//     try {
//       RTCSessionDescription offer = await _peerConnection!.createOffer();
//       await _peerConnection!.setLocalDescription(offer);
//
//       // Save offer to Firestore
//       await _firestore
//           .collection('call_sessions')
//           .doc(widget.channelName)
//           .set({
//         'offer': {
//           'sdp': offer.sdp,
//           'type': offer.type,
//         },
//         'createdBy': widget.isDoctor ? 'doctor' : 'patient',
//         'createdAt': FieldValue.serverTimestamp(),
//       });
//
//       print('📤 Offer created and sent');
//
//       // Listen for answer
//       _listenForAnswer();
//     } catch (e) {
//       print('❌ Error creating offer: $e');
//     }
//   }
//
//   /// Listen for offer (Patient side)
//   void _listenForOffer() {
//     _signalingSubscription = _firestore
//         .collection('call_sessions')
//         .doc(widget.channelName)
//         .snapshots()
//         .listen((snapshot) async {
//       if (snapshot.exists) {
//         final data = snapshot.data();
//
//         // If offer exists and we haven't answered yet
//         if (data?['offer'] != null && data?['answer'] == null) {
//           final offer = data!['offer'];
//           await _peerConnection!.setRemoteDescription(
//             RTCSessionDescription(offer['sdp'], offer['type']),
//           );
//
//           // Create answer
//           await _createAnswer();
//         }
//
//         // Listen for ICE candidates
//         if (data?['candidates'] != null) {
//           final candidates = data!['candidates'] as List;
//           for (var candidate in candidates) {
//             if (candidate['addedBy'] != (widget.isDoctor ? 'doctor' : 'patient')) {
//               await _peerConnection!.addCandidate(
//                 RTCIceCandidate(
//                   candidate['candidate'],
//                   candidate['sdpMid'],
//                   candidate['sdpMLineIndex'],
//                 ),
//               );
//             }
//           }
//         }
//       }
//     });
//   }
//
//   /// Create and send answer (Patient side)
//   Future<void> _createAnswer() async {
//     try {
//       RTCSessionDescription answer = await _peerConnection!.createAnswer();
//       await _peerConnection!.setLocalDescription(answer);
//
//       // Save answer to Firestore
//       await _firestore
//           .collection('call_sessions')
//           .doc(widget.channelName)
//           .update({
//         'answer': {
//           'sdp': answer.sdp,
//           'type': answer.type,
//         },
//       });
//
//       print('📤 Answer created and sent');
//     } catch (e) {
//       print('❌ Error creating answer: $e');
//     }
//   }
//
//   /// Listen for answer (Doctor side)
//   void _listenForAnswer() {
//     _signalingSubscription = _firestore
//         .collection('call_sessions')
//         .doc(widget.channelName)
//         .snapshots()
//         .listen((snapshot) async {
//       if (snapshot.exists) {
//         final data = snapshot.data();
//
//         // If answer exists
//         if (data?['answer'] != null) {
//           final answer = data!['answer'];
//           await _peerConnection!.setRemoteDescription(
//             RTCSessionDescription(answer['sdp'], answer['type']),
//           );
//           print('✅ Answer received');
//         }
//
//         // Listen for ICE candidates
//         if (data?['candidates'] != null) {
//           final candidates = data!['candidates'] as List;
//           for (var candidate in candidates) {
//             if (candidate['addedBy'] != (widget.isDoctor ? 'doctor' : 'patient')) {
//               await _peerConnection!.addCandidate(
//                 RTCIceCandidate(
//                   candidate['candidate'],
//                   candidate['sdpMid'],
//                   candidate['sdpMLineIndex'],
//                 ),
//               );
//             }
//           }
//         }
//       }
//     });
//   }
//
//   /// Send ICE candidate
//   Future<void> _sendIceCandidate(RTCIceCandidate candidate) async {
//     try {
//       await _firestore
//           .collection('call_sessions')
//           .doc(widget.channelName)
//           .update({
//         'candidates': FieldValue.arrayUnion([
//           {
//             'candidate': candidate.candidate,
//             'sdpMid': candidate.sdpMid,
//             'sdpMLineIndex': candidate.sdpMLineIndex,
//             'addedBy': widget.isDoctor ? 'doctor' : 'patient',
//           }
//         ])
//       });
//     } catch (e) {
//       // If document doesn't exist yet, create it
//       await _firestore
//           .collection('call_sessions')
//           .doc(widget.channelName)
//           .set({
//         'candidates': [
//           {
//             'candidate': candidate.candidate,
//             'sdpMid': candidate.sdpMid,
//             'sdpMLineIndex': candidate.sdpMLineIndex,
//             'addedBy': widget.isDoctor ? 'doctor' : 'patient',
//           }
//         ]
//       }, SetOptions(merge: true));
//     }
//   }
//
//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (mounted) {
//         setState(() {
//           _callDuration++;
//         });
//       }
//     });
//   }
//
//   String _formatDuration(int seconds) {
//     final minutes = seconds ~/ 60;
//     final secs = seconds % 60;
//     return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
//   }
//
//   void _toggleMute() {
//     if (_localStream != null) {
//       final audioTrack = _localStream!.getAudioTracks().first;
//       audioTrack.enabled = !audioTrack.enabled;
//       setState(() {
//         _isMuted = !audioTrack.enabled;
//       });
//       print('🎙️ Mute toggled: $_isMuted');
//     }
//   }
//
//   void _toggleSpeaker() {
//     setState(() {
//       _isSpeakerOn = !_isSpeakerOn;
//     });
//     // Speaker toggle is handled automatically by WebRTC on mobile
//     print('🔊 Speaker toggled: $_isSpeakerOn');
//   }
//
//   Future<void> _endCall() async {
//     _timer?.cancel();
//     _signalingSubscription?.cancel();
//
//     await _localStream?.dispose();
//     await _remoteStream?.dispose();
//     await _peerConnection?.close();
//
//     // Clean up Firestore
//     try {
//       await _firestore
//           .collection('call_sessions')
//           .doc(widget.channelName)
//           .delete();
//     } catch (e) {
//       print('Error cleaning up: $e');
//     }
//
//     print('📞 Call ended after $_callDuration seconds');
//
//     if (mounted) {
//       Navigator.pop(context);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.primaryBlue,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Top section
//             Padding(
//               padding: EdgeInsets.all(24.w),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     widget.isDoctor ? 'Patient Call' : 'Doctor Call',
//                     style: TextStyle(
//                       fontSize: 16.sp,
//                       color: Colors.white70,
//                     ),
//                   ),
//                   Text(
//                     'Simple WebRTC',
//                     style: TextStyle(
//                       fontSize: 12.sp,
//                       color: Colors.white54,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const Spacer(),
//
//             // Center - User avatar and call status
//             Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Large avatar
//                 Container(
//                   width: 140.w,
//                   height: 140.h,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.white.withOpacity(0.2),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.3),
//                       width: 4,
//                     ),
//                   ),
//                   child: Center(
//                     child: Icon(
//                       Icons.person,
//                       size: 70.sp,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 24.h),
//
//                 // User name
//                 Text(
//                   widget.otherUserName,
//                   style: TextStyle(
//                     fontSize: 28.sp,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 SizedBox(height: 8.h),
//
//                 // Call status
//                 Text(
//                   _isConnected
//                       ? _formatDuration(_callDuration)
//                       : 'Connecting...',
//                   style: TextStyle(
//                     fontSize: 16.sp,
//                     color: Colors.white70,
//                   ),
//                 ),
//
//                 if (!_isConnected)
//                   Padding(
//                     padding: EdgeInsets.only(top: 16.h),
//                     child: CircularProgressIndicator(
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
//                     ),
//                   ),
//               ],
//             ),
//
//             const Spacer(),
//
//             // Bottom - Control buttons
//             Container(
//               padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       _buildControlButton(
//                         icon: _isMuted ? Icons.mic_off : Icons.mic,
//                         label: _isMuted ? 'Unmute' : 'Mute',
//                         onTap: _toggleMute,
//                         isActive: _isMuted,
//                       ),
//                       _buildControlButton(
//                         icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
//                         label: 'Speaker',
//                         onTap: _toggleSpeaker,
//                         isActive: _isSpeakerOn,
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 32.h),
//
//                   // End call button
//                   GestureDetector(
//                     onTap: _endCall,
//                     child: Container(
//                       width: 70.w,
//                       height: 70.h,
//                       decoration: BoxDecoration(
//                         color: Colors.red,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.red.withOpacity(0.3),
//                             blurRadius: 16,
//                             spreadRadius: 2,
//                           ),
//                         ],
//                       ),
//                       child: Icon(
//                         Icons.call_end,
//                         color: Colors.white,
//                         size: 32.sp,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildControlButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//     bool isActive = false,
//   }) {
//     return Column(
//       children: [
//         GestureDetector(
//           onTap: onTap,
//           child: Container(
//             width: 56.w,
//             height: 56.h,
//             decoration: BoxDecoration(
//               color: isActive
//                   ? Colors.white
//                   : Colors.white.withOpacity(0.2),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               icon,
//               color: isActive ? AppColors.primaryBlue : Colors.white,
//               size: 24.sp,
//             ),
//           ),
//         ),
//         SizedBox(height: 8.h),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12.sp,
//             color: Colors.white,
//           ),
//         ),
//       ],
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
// // import 'package:flutter/material.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // import 'package:get/get_navigation/src/extension_navigation.dart';
// // import 'package:sheydoc_app/core/constants/app_colors.dart';
// // import 'dart:async';
// // import 'package:flutter_webrtc/flutter_webrtc.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:permission_handler/permission_handler.dart';
// //
// // /// 🎙️ SIMPLE WebRTC Audio Call - NO AGORA NEEDED!
// // /// Uses peer-to-peer connection through Firestore signaling
// // class SimpleAudioCallScreen extends StatefulWidget {
// //   final String appointmentId;
// //   final String channelName;
// //   final String otherUserName;
// //   final String otherUserId;
// //   final bool isDoctor;
// //
// //   const SimpleAudioCallScreen({
// //     super.key,
// //     required this.appointmentId,
// //     required this.channelName,
// //     required this.otherUserName,
// //     required this.otherUserId,
// //     required this.isDoctor,
// //   });
// //
// //   @override
// //   State<SimpleAudioCallScreen> createState() => _SimpleAudioCallScreenState();
// // }
// //
// // class _SimpleAudioCallScreenState extends State<SimpleAudioCallScreen> {
// //   bool _isMuted = false;
// //   bool _isSpeakerOn = true;
// //   int _callDuration = 0;
// //   Timer? _timer;
// //   bool _isConnected = false;
// //
// //   // WebRTC objects
// //   RTCPeerConnection? _peerConnection;
// //   MediaStream? _localStream;
// //   MediaStream? _remoteStream;
// //
// //   // Firestore for signaling
// //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// //   StreamSubscription? _signalingSubscription;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _initializeCall();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _timer?.cancel();
// //     _endCall();
// //     super.dispose();
// //   }
// //
// //   Future<void> _initializeCall() async {
// //     print('');
// //     print('🎙️ INITIALIZING SIMPLE WEBRTC CALL');
// //     print('📌 Channel: ${widget.channelName}');
// //     print('👤 Other User: ${widget.otherUserName}');
// //     print('');
// //
// //     // Request mic permission
// //     await Permission.microphone.request();
// //
// //     // Initialize WebRTC
// //     await _createPeerConnection();
// //     await _getUserMedia();
// //
// //     // Start signaling
// //     if (widget.isDoctor) {
// //       // Doctor creates offer
// //       await _createOffer();
// //     } else {
// //       // Patient waits for offer
// //       _listenForOffer();
// //     }
// //   }
// //
// //   /// Create peer connection with audio only
// //   Future<void> _createPeerConnection() async {
// //     // Configuration for peer connection
// //     Map<String, dynamic> configuration = {
// //       'iceServers': [
// //         {
// //           'urls': [
// //             'stun:stun1.l.google.com:19302',
// //             'stun:stun2.l.google.com:19302',
// //           ]
// //         }
// //       ]
// //     };
// //
// //     // Create peer connection
// //     _peerConnection = await createPeerConnection(configuration);
// //
// //     // Listen for ICE candidates
// //     _peerConnection!.onIceCandidate = (candidate) {
// //       if (candidate != null) {
// //         _sendIceCandidate(candidate);
// //       }
// //     };
// //
// //     // Listen for remote stream
// //     _peerConnection!.onTrack = (event) {
// //       if (event.streams.isNotEmpty) {
// //         setState(() {
// //           _remoteStream = event.streams[0];
// //           _isConnected = true;
// //         });
// //         _startTimer();
// //         print('✅ Remote audio stream received!');
// //       }
// //     };
// //
// //     // Listen for connection state
// //     _peerConnection!.onConnectionState = (state) {
// //       print('🔌 Connection state: $state');
// //       if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
// //         setState(() => _isConnected = true);
// //       }
// //     };
// //
// //     print('✅ Peer connection created');
// //   }
// //
// //   /// Get user's microphone audio
// //   Future<void> _getUserMedia() async {
// //     try {
// //       final Map<String, dynamic> mediaConstraints = {
// //         'audio': true,
// //         'video': false,
// //       };
// //
// //       _localStream = await navigator?.mediaDevices.getUserMedia(mediaConstraints);
// //
// //       // Add local stream tracks to peer connection
// //       _localStream!.getTracks().forEach((track) {
// //         _peerConnection!.addTrack(track, _localStream!);
// //       });
// //
// //       print('🎤 Local microphone stream obtained');
// //     } catch (e) {
// //       print('❌ Error getting microphone: $e');
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Could not access microphone: $e'),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     }
// //   }
// //
// //   /// Create and send offer (Doctor side)
// //   Future<void> _createOffer() async {
// //     try {
// //       RTCSessionDescription offer = await _peerConnection!.createOffer();
// //       await _peerConnection!.setLocalDescription(offer);
// //
// //       // Save offer to Firestore
// //       await _firestore
// //           .collection('call_sessions')
// //           .doc(widget.channelName)
// //           .set({
// //         'offer': {
// //           'sdp': offer.sdp,
// //           'type': offer.type,
// //         },
// //         'createdBy': widget.isDoctor ? 'doctor' : 'patient',
// //         'createdAt': FieldValue.serverTimestamp(),
// //       });
// //
// //       print('📤 Offer created and sent');
// //
// //       // Listen for answer
// //       _listenForAnswer();
// //     } catch (e) {
// //       print('❌ Error creating offer: $e');
// //     }
// //   }
// //
// //   /// Listen for offer (Patient side)
// //   void _listenForOffer() {
// //     _signalingSubscription = _firestore
// //         .collection('call_sessions')
// //         .doc(widget.channelName)
// //         .snapshots()
// //         .listen((snapshot) async {
// //       if (snapshot.exists) {
// //         final data = snapshot.data();
// //
// //         // If offer exists and we haven't answered yet
// //         if (data?['offer'] != null && data?['answer'] == null) {
// //           final offer = data!['offer'];
// //           await _peerConnection!.setRemoteDescription(
// //             RTCSessionDescription(offer['sdp'], offer['type']),
// //           );
// //
// //           // Create answer
// //           await _createAnswer();
// //         }
// //
// //         // Listen for ICE candidates
// //         if (data?['candidates'] != null) {
// //           final candidates = data!['candidates'] as List;
// //           for (var candidate in candidates) {
// //             if (candidate['addedBy'] != (widget.isDoctor ? 'doctor' : 'patient')) {
// //               await _peerConnection!.addCandidate(
// //                 RTCIceCandidate(
// //                   candidate['candidate'],
// //                   candidate['sdpMid'],
// //                   candidate['sdpMLineIndex'],
// //                 ),
// //               );
// //             }
// //           }
// //         }
// //       }
// //     });
// //   }
// //
// //   /// Create and send answer (Patient side)
// //   Future<void> _createAnswer() async {
// //     try {
// //       RTCSessionDescription answer = await _peerConnection!.createAnswer();
// //       await _peerConnection!.setLocalDescription(answer);
// //
// //       // Save answer to Firestore
// //       await _firestore
// //           .collection('call_sessions')
// //           .doc(widget.channelName)
// //           .update({
// //         'answer': {
// //           'sdp': answer.sdp,
// //           'type': answer.type,
// //         },
// //       });
// //
// //       print('📤 Answer created and sent');
// //     } catch (e) {
// //       print('❌ Error creating answer: $e');
// //     }
// //   }
// //
// //   /// Listen for answer (Doctor side)
// //   void _listenForAnswer() {
// //     _signalingSubscription = _firestore
// //         .collection('call_sessions')
// //         .doc(widget.channelName)
// //         .snapshots()
// //         .listen((snapshot) async {
// //       if (snapshot.exists) {
// //         final data = snapshot.data();
// //
// //         // If answer exists
// //         if (data?['answer'] != null) {
// //           final answer = data!['answer'];
// //           await _peerConnection!.setRemoteDescription(
// //             RTCSessionDescription(answer['sdp'], answer['type']),
// //           );
// //           print('✅ Answer received');
// //         }
// //
// //         // Listen for ICE candidates
// //         if (data?['candidates'] != null) {
// //           final candidates = data!['candidates'] as List;
// //           for (var candidate in candidates) {
// //             if (candidate['addedBy'] != (widget.isDoctor ? 'doctor' : 'patient')) {
// //               await _peerConnection!.addCandidate(
// //                 RTCIceCandidate(
// //                   candidate['candidate'],
// //                   candidate['sdpMid'],
// //                   candidate['sdpMLineIndex'],
// //                 ),
// //               );
// //             }
// //           }
// //         }
// //       }
// //     });
// //   }
// //
// //   /// Send ICE candidate
// //   Future<void> _sendIceCandidate(RTCIceCandidate candidate) async {
// //     try {
// //       await _firestore
// //           .collection('call_sessions')
// //           .doc(widget.channelName)
// //           .update({
// //         'candidates': FieldValue.arrayUnion([
// //           {
// //             'candidate': candidate.candidate,
// //             'sdpMid': candidate.sdpMid,
// //             'sdpMLineIndex': candidate.sdpMLineIndex,
// //             'addedBy': widget.isDoctor ? 'doctor' : 'patient',
// //           }
// //         ])
// //       });
// //     } catch (e) {
// //       // If document doesn't exist yet, create it
// //       await _firestore
// //           .collection('call_sessions')
// //           .doc(widget.channelName)
// //           .set({
// //         'candidates': [
// //           {
// //             'candidate': candidate.candidate,
// //             'sdpMid': candidate.sdpMid,
// //             'sdpMLineIndex': candidate.sdpMLineIndex,
// //             'addedBy': widget.isDoctor ? 'doctor' : 'patient',
// //           }
// //         ]
// //       }, SetOptions(merge: true));
// //     }
// //   }
// //
// //   void _startTimer() {
// //     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
// //       if (mounted) {
// //         setState(() {
// //           _callDuration++;
// //         });
// //       }
// //     });
// //   }
// //
// //   String _formatDuration(int seconds) {
// //     final minutes = seconds ~/ 60;
// //     final secs = seconds % 60;
// //     return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
// //   }
// //
// //   void _toggleMute() {
// //     if (_localStream != null) {
// //       final audioTrack = _localStream!.getAudioTracks().first;
// //       audioTrack.enabled = !audioTrack.enabled;
// //       setState(() {
// //         _isMuted = !audioTrack.enabled;
// //       });
// //       print('🎙️ Mute toggled: $_isMuted');
// //     }
// //   }
// //
// //   void _toggleSpeaker() {
// //     setState(() {
// //       _isSpeakerOn = !_isSpeakerOn;
// //     });
// //     // Speaker toggle is handled automatically by WebRTC on mobile
// //     print('🔊 Speaker toggled: $_isSpeakerOn');
// //   }
// //
// //   Future<void> _endCall() async {
// //     _timer?.cancel();
// //     _signalingSubscription?.cancel();
// //
// //     await _localStream?.dispose();
// //     await _remoteStream?.dispose();
// //     await _peerConnection?.close();
// //
// //     // Clean up Firestore
// //     try {
// //       await _firestore
// //           .collection('call_sessions')
// //           .doc(widget.channelName)
// //           .delete();
// //     } catch (e) {
// //       print('Error cleaning up: $e');
// //     }
// //
// //     print('📞 Call ended after $_callDuration seconds');
// //
// //     if (mounted) {
// //       Navigator.pop(context);
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: AppColors.primaryBlue,
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             // Top section
// //             Padding(
// //               padding: EdgeInsets.all(24.w),
// //               child: Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   Text(
// //                     widget.isDoctor ? 'Patient Call' : 'Doctor Call',
// //                     style: TextStyle(
// //                       fontSize: 16.sp,
// //                       color: Colors.white70,
// //                     ),
// //                   ),
// //                   Text(
// //                     'Simple WebRTC',
// //                     style: TextStyle(
// //                       fontSize: 12.sp,
// //                       color: Colors.white54,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             const Spacer(),
// //
// //             // Center - User avatar and call status
// //             Column(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 // Large avatar
// //                 Container(
// //                   width: 140.w,
// //                   height: 140.h,
// //                   decoration: BoxDecoration(
// //                     shape: BoxShape.circle,
// //                     color: Colors.white.withOpacity(0.2),
// //                     border: Border.all(
// //                       color: Colors.white.withOpacity(0.3),
// //                       width: 4,
// //                     ),
// //                   ),
// //                   child: Center(
// //                     child: Icon(
// //                       Icons.person,
// //                       size: 70.sp,
// //                       color: Colors.white,
// //                     ),
// //                   ),
// //                 ),
// //                 SizedBox(height: 24.h),
// //
// //                 // User name
// //                 Text(
// //                   widget.otherUserName,
// //                   style: TextStyle(
// //                     fontSize: 28.sp,
// //                     fontWeight: FontWeight.bold,
// //                     color: Colors.white,
// //                   ),
// //                 ),
// //                 SizedBox(height: 8.h),
// //
// //                 // Call status
// //                 Text(
// //                   _isConnected
// //                       ? _formatDuration(_callDuration)
// //                       : 'Connecting...',
// //                   style: TextStyle(
// //                     fontSize: 16.sp,
// //                     color: Colors.white70,
// //                   ),
// //                 ),
// //
// //                 if (!_isConnected)
// //                   Padding(
// //                     padding: EdgeInsets.only(top: 16.h),
// //                     child: CircularProgressIndicator(
// //                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
// //                     ),
// //                   ),
// //               ],
// //             ),
// //
// //             const Spacer(),
// //
// //             // Bottom - Control buttons
// //             Container(
// //               padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
// //               child: Column(
// //                 children: [
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                     children: [
// //                       _buildControlButton(
// //                         icon: _isMuted ? Icons.mic_off : Icons.mic,
// //                         label: _isMuted ? 'Unmute' : 'Mute',
// //                         onTap: _toggleMute,
// //                         isActive: _isMuted,
// //                       ),
// //                       _buildControlButton(
// //                         icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
// //                         label: 'Speaker',
// //                         onTap: _toggleSpeaker,
// //                         isActive: _isSpeakerOn,
// //                       ),
// //                     ],
// //                   ),
// //                   SizedBox(height: 32.h),
// //
// //                   // End call button
// //                   GestureDetector(
// //                     onTap: _endCall,
// //                     child: Container(
// //                       width: 70.w,
// //                       height: 70.h,
// //                       decoration: BoxDecoration(
// //                         color: Colors.red,
// //                         shape: BoxShape.circle,
// //                         boxShadow: [
// //                           BoxShadow(
// //                             color: Colors.red.withOpacity(0.3),
// //                             blurRadius: 16,
// //                             spreadRadius: 2,
// //                           ),
// //                         ],
// //                       ),
// //                       child: Icon(
// //                         Icons.call_end,
// //                         color: Colors.white,
// //                         size: 32.sp,
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildControlButton({
// //     required IconData icon,
// //     required String label,
// //     required VoidCallback onTap,
// //     bool isActive = false,
// //   }) {
// //     return Column(
// //       children: [
// //         GestureDetector(
// //           onTap: onTap,
// //           child: Container(
// //             width: 56.w,
// //             height: 56.h,
// //             decoration: BoxDecoration(
// //               color: isActive
// //                   ? Colors.white
// //                   : Colors.white.withOpacity(0.2),
// //               shape: BoxShape.circle,
// //             ),
// //             child: Icon(
// //               icon,
// //               color: isActive ? AppColors.primaryBlue : Colors.white,
// //               size: 24.sp,
// //             ),
// //           ),
// //         ),
// //         SizedBox(height: 8.h),
// //         Text(
// //           label,
// //           style: TextStyle(
// //             fontSize: 12.sp,
// //             color: Colors.white,
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }