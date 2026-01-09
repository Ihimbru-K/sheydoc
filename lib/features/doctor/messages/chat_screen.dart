// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:sheydoc_app/core/constants/app_colors.dart';
// import 'package:intl/intl.dart';
// import 'package:sheydoc_app/services/call_invitation_service.dart';
//
//
// import '../../../shared/widgets/incoming_call_widget.dart';
// import '../../shared/audio_call_screen.dart';
// import '../../shared/simple_audiocall_screen.dart';
// import '../../shared/video_call_screen.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String chatId;
//   final String otherUserId;
//   final String otherUserName;
//
//   const ChatScreen({
//     super.key,
//     required this.chatId,
//     required this.otherUserId,
//     required this.otherUserName,
//   });
//
//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final user = FirebaseAuth.instance.currentUser;
//   final CallInvitationService _callService = CallInvitationService();
//
//   bool _isCallInProgress = false;
//   String? _activeCallInvitationId;
//
//   @override
//   void initState() {
//     super.initState();
//     _listenForIncomingCalls();
//   }
//
//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   /// Listen for incoming calls
//   void _listenForIncomingCalls() {
//     _callService.listenToIncomingCalls().listen((snapshot) {
//       if (snapshot.docs.isNotEmpty && !_isCallInProgress) {
//         // Show incoming call dialog for the most recent call
//         final callDoc = snapshot.docs.first;
//         final callData = callDoc.data() as Map<String, dynamic>;
//
//         // Only show if the call is from the current chat partner
//         if (callData['callerId'] == widget.otherUserId) {
//           _showIncomingCallDialog(callDoc.id, callData);
//         }
//       }
//     });
//   }
//
//   /// Show incoming call dialog
//   void _showIncomingCallDialog(String invitationId, Map<String, dynamic> callData) {
//     if (!mounted || _isCallInProgress) return;
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => IncomingCallDialog(
//         callerName: callData['callerName'] ?? 'Unknown',
//         callType: callData['callType'] ?? 'audio',
//         onAccept: () {
//           Navigator.pop(context);
//           _acceptCall(invitationId, callData);
//         },
//         onDecline: () {
//           Navigator.pop(context);
//           _callService.declineCall(invitationId);
//         },
//       ),
//     );
//
//     // Auto-dismiss after 30 seconds
//     Future.delayed(const Duration(seconds: 30), () {
//       if (mounted && _isCallInProgress == false) {
//         Navigator.of(context, rootNavigator: true).pop();
//         _callService.markCallAsMissed(invitationId);
//       }
//     });
//   }
//
//   /// Accept incoming call
//   Future<void> _acceptCall(String invitationId, Map<String, dynamic> callData) async {
//     setState(() {
//       _isCallInProgress = true;
//       _activeCallInvitationId = invitationId;
//     });
//
//     final accepted = await _callService.acceptCall(invitationId);
//     if (!accepted || !mounted) return;
//
//     final channelName = callData['channelName'] ?? 'default_channel';
//     final callType = callData['callType'] ?? 'audio';
//
//     // Navigate to appropriate call screen
//     if (callType == 'audio') {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => AudioCallScreen(
//             appointmentId: widget.chatId,
//             channelName: channelName,
//             otherUserName: widget.otherUserName,
//             otherUserId: widget.otherUserId,
//             isDoctor: false, // Determine based on user role
//           ),
//         ),
//       ).then((_) {
//         setState(() {
//           _isCallInProgress = false;
//           _activeCallInvitationId = null;
//         });
//       });
//     } else {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => VideoCallScreen(
//             appointmentId: widget.chatId,
//             channelName: channelName,
//             otherUserName: widget.otherUserName,
//             otherUserId: widget.otherUserId,
//             isDoctor: false,
//           ),
//         ),
//       ).then((_) {
//         setState(() {
//           _isCallInProgress = false;
//           _activeCallInvitationId = null;
//         });
//       });
//     }
//   }
//
//   /// Initiate video call
//   Future<void> _initiateVideoCall() async {
//     if (_isCallInProgress) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('A call is already in progress')),
//       );
//       return;
//     }
//
//     setState(() => _isCallInProgress = true);
//
//     // Create channel name
//     final timestamp = DateTime.now().millisecondsSinceEpoch;
//     final channelName = 'call_${widget.chatId}_$timestamp'
//         .toLowerCase()
//         .replaceAll(RegExp(r'[^a-z0-9_]'), '');
//
//     // Create call invitation
//     final invitationId = await _callService.createCallInvitation(
//       receiverId: widget.otherUserId,
//       receiverName: widget.otherUserName,
//       callType: 'video',
//       channelName: channelName,
//     );
//
//     if (invitationId == null) {
//       if (mounted) {
//         setState(() => _isCallInProgress = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to initiate call')),
//         );
//       }
//       return;
//     }
//
//     setState(() => _activeCallInvitationId = invitationId);
//
//     // Listen for call acceptance
//     _callService.listenToCallInvitation(invitationId).listen((snapshot) {
//       if (!snapshot.exists || !mounted) return;
//
//       final data = snapshot.data() as Map<String, dynamic>;
//       final status = data['status'];
//
//       if (status == 'accepted') {
//         // Other person accepted, join call
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => VideoCallScreen(
//               appointmentId: widget.chatId,
//               channelName: channelName,
//               otherUserName: widget.otherUserName,
//               otherUserId: widget.otherUserId,
//               isDoctor: false,
//             ),
//           ),
//         ).then((_) {
//           setState(() {
//             _isCallInProgress = false;
//             _activeCallInvitationId = null;
//           });
//         });
//       } else if (status == 'declined') {
//         if (mounted) {
//           setState(() {
//             _isCallInProgress = false;
//             _activeCallInvitationId = null;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Call declined')),
//           );
//         }
//       }
//     });
//
//     // Show waiting dialog
//     _showWaitingDialog(invitationId);
//   }
//
//   /// Initiate audio call
//   Future<void> _initiateAudioCall() async {
//     if (_isCallInProgress) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('A call is already in progress')),
//       );
//       return;
//     }
//
//     setState(() => _isCallInProgress = true);
//
//     // Create channel name
//     final timestamp = DateTime.now().millisecondsSinceEpoch;
//     final channelName = 'call_${widget.chatId}_$timestamp'
//         .toLowerCase()
//         .replaceAll(RegExp(r'[^a-z0-9_]'), '');
//
//     // Create call invitation
//     final invitationId = await _callService.createCallInvitation(
//       receiverId: widget.otherUserId,
//       receiverName: widget.otherUserName,
//       callType: 'audio',
//       channelName: channelName,
//     );
//
//     if (invitationId == null) {
//       if (mounted) {
//         setState(() => _isCallInProgress = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to initiate call')),
//         );
//       }
//       return;
//     }
//
//     setState(() => _activeCallInvitationId = invitationId);
//
//     // Listen for call acceptance
//     _callService.listenToCallInvitation(invitationId).listen((snapshot) {
//       if (!snapshot.exists || !mounted) return;
//
//       final data = snapshot.data() as Map<String, dynamic>;
//       final status = data['status'];
//
//       if (status == 'accepted') {
//         // Other person accepted, join call
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => SimpleAudioCallScreen(  // ✅ NEW
//               appointmentId: widget.chatId,
//               channelName: channelName,
//               otherUserName: widget.otherUserName,
//               otherUserId: widget.otherUserId,
//               isDoctor: false,
//             ),
//           ),
//           // MaterialPageRoute(
//           //   builder: (context) => AudioCallScreen(
//           //     appointmentId: widget.chatId,
//           //     channelName: channelName,
//           //     otherUserName: widget.otherUserName,
//           //     otherUserId: widget.otherUserId,
//           //     isDoctor: false,
//           //   ),
//           // ),
//         ).then((_) {
//           setState(() {
//             _isCallInProgress = false;
//             _activeCallInvitationId = null;
//           });
//         });
//       } else if (status == 'declined') {
//         if (mounted) {
//           setState(() {
//             _isCallInProgress = false;
//             _activeCallInvitationId = null;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Call declined')),
//           );
//         }
//       }
//     });
//
//     // Show waiting dialog
//     _showWaitingDialog(invitationId);
//   }
//
//   /// Show waiting for answer dialog
//   void _showWaitingDialog(String invitationId) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => WillPopScope(
//         onWillPop: () async {
//           _callService.cancelCall(invitationId);
//           setState(() {
//             _isCallInProgress = false;
//             _activeCallInvitationId = null;
//           });
//           return true;
//         },
//         child: AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16.r),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircularProgressIndicator(color: AppColors.primaryBlue),
//               SizedBox(height: 16.h),
//               Text(
//                 'Calling ${widget.otherUserName}...',
//                 style: TextStyle(
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               SizedBox(height: 8.h),
//               Text(
//                 'Waiting for answer',
//                 style: TextStyle(
//                   fontSize: 14.sp,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _callService.cancelCall(invitationId);
//                 setState(() {
//                   _isCallInProgress = false;
//                   _activeCallInvitationId = null;
//                 });
//               },
//               child: Text(
//                 'Cancel',
//                 style: TextStyle(color: Colors.red, fontSize: 14.sp),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//
//     // Auto-dismiss after 30 seconds
//     Future.delayed(const Duration(seconds: 30), () {
//       if (mounted && _isCallInProgress) {
//         Navigator.of(context, rootNavigator: true).pop();
//         _callService.markCallAsMissed(invitationId);
//         setState(() {
//           _isCallInProgress = false;
//           _activeCallInvitationId = null;
//         });
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Row(
//           children: [
//             CircleAvatar(
//               radius: 18.r,
//               backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
//               child: Icon(Icons.person, color: AppColors.primaryBlue, size: 20.sp),
//             ),
//             SizedBox(width: 12.w),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.otherUserName,
//                     style: TextStyle(
//                       fontSize: 16.sp,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                   ),
//                   Text(
//                     'Online',
//                     style: TextStyle(
//                       fontSize: 12.sp,
//                       color: Colors.green,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.videocam, color: AppColors.primaryBlue),
//             onPressed: _initiateVideoCall,
//           ),
//           IconButton(
//             icon: Icon(Icons.phone, color: AppColors.primaryBlue),
//             onPressed: _initiateAudioCall,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('chats')
//                   .doc(widget.chatId)
//                   .collection('messages')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.chat_bubble_outline,
//                           size: 64.sp,
//                           color: Colors.grey[300],
//                         ),
//                         SizedBox(height: 16.h),
//                         Text(
//                           'No messages yet',
//                           style: TextStyle(
//                             fontSize: 16.sp,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                         SizedBox(height: 8.h),
//                         Text(
//                           'Send a message to start the conversation',
//                           style: TextStyle(
//                             fontSize: 14.sp,
//                             color: Colors.grey[500],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//
//                 final messages = snapshot.data!.docs;
//
//                 // Sort messages by timestamp in memory
//                 messages.sort((a, b) {
//                   final aData = a.data() as Map<String, dynamic>;
//                   final bData = b.data() as Map<String, dynamic>;
//                   final aTime = (aData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
//                   final bTime = (bData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
//                   return bTime.compareTo(aTime);
//                 });
//
//                 return ListView.builder(
//                   controller: _scrollController,
//                   reverse: true,
//                   padding: EdgeInsets.all(16.w),
//                   itemCount: messages.length,
//                   itemBuilder: (context, index) {
//                     final messageData = messages[index].data() as Map<String, dynamic>;
//                     return _buildMessageBubble(messageData);
//                   },
//                 );
//               },
//             ),
//           ),
//           _buildMessageInput(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMessageBubble(Map<String, dynamic> messageData) {
//     final isMe = messageData['senderId'] == user?.uid;
//     final message = messageData['message'] ?? '';
//     final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate();
//
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: EdgeInsets.only(bottom: 12.h),
//         padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
//         constraints: BoxConstraints(maxWidth: 280.w),
//         decoration: BoxDecoration(
//           color: isMe ? AppColors.primaryBlue : Colors.white,
//           borderRadius: BorderRadius.circular(16.r).copyWith(
//             bottomRight: isMe ? Radius.zero : Radius.circular(16.r),
//             bottomLeft: isMe ? Radius.circular(16.r) : Radius.zero,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               message,
//               style: TextStyle(
//                 fontSize: 14.sp,
//                 color: isMe ? Colors.white : Colors.black,
//                 height: 1.4,
//               ),
//             ),
//             SizedBox(height: 4.h),
//             Text(
//               timestamp != null
//                   ? DateFormat('h:mm a').format(timestamp)
//                   : '',
//               style: TextStyle(
//                 fontSize: 11.sp,
//                 color: isMe ? Colors.white70 : Colors.grey[500],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMessageInput() {
//     return Container(
//       padding: EdgeInsets.all(16.w),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             icon: Icon(Icons.attach_file, color: AppColors.primaryBlue),
//             onPressed: () {
//               // Handle file attachment
//             },
//           ),
//           Expanded(
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 16.w),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(24.r),
//               ),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: InputDecoration(
//                   hintText: 'Type a message...',
//                   hintStyle: TextStyle(
//                     fontSize: 14.sp,
//                     color: Colors.grey[500],
//                   ),
//                   border: InputBorder.none,
//                 ),
//                 maxLines: null,
//                 textCapitalization: TextCapitalization.sentences,
//               ),
//             ),
//           ),
//           SizedBox(width: 8.w),
//           GestureDetector(
//             onTap: _sendMessage,
//             child: Container(
//               padding: EdgeInsets.all(12.w),
//               decoration: BoxDecoration(
//                 color: AppColors.primaryBlue,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.send,
//                 color: Colors.white,
//                 size: 20.sp,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;
//
//     final message = _messageController.text.trim();
//     _messageController.clear();
//
//     try {
//       await FirebaseFirestore.instance
//           .collection('chats')
//           .doc(widget.chatId)
//           .collection('messages')
//           .add({
//         'senderId': user!.uid,
//         'message': message,
//         'timestamp': FieldValue.serverTimestamp(),
//         'read': false,
//       });
//
//       await FirebaseFirestore.instance
//           .collection('chats')
//           .doc(widget.chatId)
//           .update({
//         'lastMessage': message,
//         'lastMessageTime': FieldValue.serverTimestamp(),
//       });
//
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           0,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to send message: $e')),
//         );
//       }
//     }
//   }
// }





import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sheydoc_app/core/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:sheydoc_app/features/doctor/video/doctor_video_patients_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final user = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
              child: Icon(Icons.person, color: AppColors.primaryBlue, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.videocam, color: AppColors.primaryBlue),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorVideoPatientsScreen()));
            },
          ),
          IconButton(
            icon: Icon(Icons.phone, color: AppColors.primaryBlue),
            onPressed: () {
              // Start audio call
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
              // Removed orderBy to avoid index requirement
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64.sp,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Send a message to start the conversation',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                // Sort messages by timestamp in memory
                messages.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = (aData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
                  final bTime = (bData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
                  return bTime.compareTo(aTime); // Descending (newest first)
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.all(16.w),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    return _buildMessageBubble(messageData);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData) {
    final isMe = messageData['senderId'] == user?.uid;
    final message = messageData['message'] ?? '';
    final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        constraints: BoxConstraints(maxWidth: 280.w),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(16.r).copyWith(
            bottomRight: isMe ? Radius.zero : Radius.circular(16.r),
            bottomLeft: isMe ? Radius.circular(16.r) : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 14.sp,
                color: isMe ? Colors.white : Colors.black,
                height: 1.4,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              timestamp != null
                  ? DateFormat('h:mm a').format(timestamp)
                  : '',
              style: TextStyle(
                fontSize: 11.sp,
                color: isMe ? Colors.white70 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: AppColors.primaryBlue),
            onPressed: () {
              // Handle file attachment
            },
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[500],
                  ),
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      // Add message to Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': user!.uid,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update last message in chat document
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }
}




// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:sheydoc_app/core/constants/app_colors.dart';
// import 'package:intl/intl.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String chatId;
//   final String otherUserId;
//   final String otherUserName;
//
//   const ChatScreen({
//     super.key,
//     required this.chatId,
//     required this.otherUserId,
//     required this.otherUserName,
//   });
//
//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final user = FirebaseAuth.instance.currentUser;
//
//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Row(
//           children: [
//             CircleAvatar(
//               radius: 18.r,
//               backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
//               child: Icon(Icons.person, color: AppColors.primaryBlue, size: 20.sp),
//             ),
//             SizedBox(width: 12.w),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.otherUserName,
//                     style: TextStyle(
//                       fontSize: 16.sp,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                   ),
//                   Text(
//                     'Online',
//                     style: TextStyle(
//                       fontSize: 12.sp,
//                       color: Colors.green,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.videocam, color: AppColors.primaryBlue),
//             onPressed: () {
//               // Start video call
//             },
//           ),
//           IconButton(
//             icon: Icon(Icons.phone, color: AppColors.primaryBlue),
//             onPressed: () {
//               // Start audio call
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('chats')
//                   .doc(widget.chatId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.chat_bubble_outline,
//                           size: 64.sp,
//                           color: Colors.grey[300],
//                         ),
//                         SizedBox(height: 16.h),
//                         Text(
//                           'No messages yet',
//                           style: TextStyle(
//                             fontSize: 16.sp,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                         SizedBox(height: 8.h),
//                         Text(
//                           'Send a message to start the conversation',
//                           style: TextStyle(
//                             fontSize: 14.sp,
//                             color: Colors.grey[500],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//
//                 final messages = snapshot.data!.docs;
//
//                 return ListView.builder(
//                   controller: _scrollController,
//                   reverse: true,
//                   padding: EdgeInsets.all(16.w),
//                   itemCount: messages.length,
//                   itemBuilder: (context, index) {
//                     final messageData = messages[index].data() as Map<String, dynamic>;
//                     return _buildMessageBubble(messageData);
//                   },
//                 );
//               },
//             ),
//           ),
//           _buildMessageInput(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMessageBubble(Map<String, dynamic> messageData) {
//     final isMe = messageData['senderId'] == user?.uid;
//     final message = messageData['message'] ?? '';
//     final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate();
//
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: EdgeInsets.only(bottom: 12.h),
//         padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
//         constraints: BoxConstraints(maxWidth: 280.w),
//         decoration: BoxDecoration(
//           color: isMe ? AppColors.primaryBlue : Colors.white,
//           borderRadius: BorderRadius.circular(16.r).copyWith(
//             bottomRight: isMe ? Radius.zero : Radius.circular(16.r),
//             bottomLeft: isMe ? Radius.circular(16.r) : Radius.zero,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               message,
//               style: TextStyle(
//                 fontSize: 14.sp,
//                 color: isMe ? Colors.white : Colors.black,
//                 height: 1.4,
//               ),
//             ),
//             SizedBox(height: 4.h),
//             Text(
//               timestamp != null
//                   ? DateFormat('h:mm a').format(timestamp)
//                   : '',
//               style: TextStyle(
//                 fontSize: 11.sp,
//                 color: isMe ? Colors.white70 : Colors.grey[500],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMessageInput() {
//     return Container(
//       padding: EdgeInsets.all(16.w),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             icon: Icon(Icons.attach_file, color: AppColors.primaryBlue),
//             onPressed: () {
//               // Handle file attachment
//             },
//           ),
//           Expanded(
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 16.w),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(24.r),
//               ),
//               child: TextField(
//                 controller: _messageController,
//                 decoration: InputDecoration(
//                   hintText: 'Type a message...',
//                   hintStyle: TextStyle(
//                     fontSize: 14.sp,
//                     color: Colors.grey[500],
//                   ),
//                   border: InputBorder.none,
//                 ),
//                 maxLines: null,
//                 textCapitalization: TextCapitalization.sentences,
//               ),
//             ),
//           ),
//           SizedBox(width: 8.w),
//           GestureDetector(
//             onTap: _sendMessage,
//             child: Container(
//               padding: EdgeInsets.all(12.w),
//               decoration: BoxDecoration(
//                 color: AppColors.primaryBlue,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.send,
//                 color: Colors.white,
//                 size: 20.sp,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;
//
//     final message = _messageController.text.trim();
//     _messageController.clear();
//
//     try {
//       // Add message to Firestore
//       await FirebaseFirestore.instance
//           .collection('chats')
//           .doc(widget.chatId)
//           .collection('messages')
//           .add({
//         'senderId': user!.uid,
//         'message': message,
//         'timestamp': FieldValue.serverTimestamp(),
//         'read': false,
//       });
//
//       // Update last message in chat document
//       await FirebaseFirestore.instance
//           .collection('chats')
//           .doc(widget.chatId)
//           .update({
//         'lastMessage': message,
//         'lastMessageTime': FieldValue.serverTimestamp(),
//       });
//
//       // Scroll to bottom
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           0,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to send message')),
//       );
//     }
//   }
// }