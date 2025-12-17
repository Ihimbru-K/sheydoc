import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sheydoc_app/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

import '../../../shared/video_call_screen.dart';


class PatientSessionsScreen extends StatelessWidget {
  const PatientSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Sessions',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('patientId', isEqualTo: user?.uid)
        // Removed orderBy to avoid composite index requirement
        // We'll sort in memory below
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final appointments = snapshot.data!.docs;

          // Sort appointments by date in memory (since we can't use orderBy without index)
          appointments.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aDate = (aData['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bDate = (bData['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return aDate.compareTo(bDate); // Ascending order
          });

          // Separate into categories
          final upcoming = <QueryDocumentSnapshot>[];
          final ongoing = <QueryDocumentSnapshot>[];
          final completed = <QueryDocumentSnapshot>[];

          for (var doc in appointments) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            final callStatus = data['callStatus'];

            if (callStatus == 'ongoing') {
              ongoing.add(doc);
            } else if (status == 'confirmed') {
              upcoming.add(doc);
            } else if (status == 'completed' || callStatus == 'completed') {
              completed.add(doc);
            }
          }

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: AppColors.primaryBlue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      Tab(text: 'Ongoing (${ongoing.length})'),
                      Tab(text: 'Upcoming (${upcoming.length})'),
                      Tab(text: 'Completed (${completed.length})'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSessionsList(context, ongoing, 'ongoing'),
                      _buildSessionsList(context, upcoming, 'upcoming'),
                      _buildSessionsList(context, completed, 'completed'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionsList(
      BuildContext context,
      List<QueryDocumentSnapshot> sessions,
      String type,
      ) {
    if (sessions.isEmpty) {
      return _buildEmptyStateForTab(type);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final data = sessions[index].data() as Map<String, dynamic>;
        final appointmentId = sessions[index].id;
        return _buildSessionCard(context, data, appointmentId, type);
      },
    );
  }

  Widget _buildSessionCard(
      BuildContext context,
      Map<String, dynamic> data,
      String appointmentId,
      String type,
      ) {
    final doctorName = data['doctorName'] ?? 'Unknown Doctor';
    final doctorId = data['doctorId'] ?? '';
    final location = data['location'] ?? 'Unknown';
    final appointmentType = data['appointmentType'] ?? 'video';
    final date = (data['appointmentDate'] as Timestamp?)?.toDate();
    final time = data['appointmentTime'] ?? 'N/A';
    final status = data['status'] ?? 'pending';

    // Check if appointment is today
    final isToday = date != null &&
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    Color statusColor;
    String statusText;

    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusText = 'Confirmed';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'Completed';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: type == 'ongoing'
              ? Colors.green
              : isToday
              ? AppColors.primaryBlue
              : Colors.grey[300]!,
          width: type == 'ongoing' || isToday ? 2 : 1,
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
          Row(
            children: [
              CircleAvatar(
                radius: 28.r,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  size: 28.sp,
                  color: AppColors.primaryBlue,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doctorName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (type == 'ongoing')
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6.w,
                                  height: 6.h,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'LIVE',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isToday && type == 'upcoming')
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'TODAY',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14.sp, color: Colors.grey[600]),
                        SizedBox(width: 4.w),
                        Text(
                          location,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16.sp,
                  color: AppColors.primaryBlue,
                ),
                SizedBox(width: 8.w),
                Text(
                  date != null
                      ? DateFormat('MMM dd, yyyy').format(date)
                      : 'Date N/A',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 16.w),
                Icon(
                  Icons.access_time,
                  size: 16.sp,
                  color: AppColors.primaryBlue,
                ),
                SizedBox(width: 8.w),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          if (type == 'ongoing' || (type == 'upcoming' && status == 'confirmed'))
            ElevatedButton.icon(
              onPressed: () => _joinVideoCall(
                context,
                appointmentId,
                doctorId,
                doctorName,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: type == 'ongoing' ? Colors.green : AppColors.primaryBlue,
                minimumSize: Size(double.infinity, 44.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              icon: Icon(
                type == 'ongoing' ? Icons.videocam : Icons.video_call,
                size: 20.sp,
              ),
              label: Text(
                type == 'ongoing' ? 'Join Ongoing Call' : 'Join Video Call',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (type == 'completed')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: View session details/summary
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    icon: Icon(
                      Icons.article_outlined,
                      size: 18.sp,
                      color: AppColors.primaryBlue,
                    ),
                    label: Text(
                      'View Summary',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Book again with same doctor
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    icon: Icon(
                      Icons.refresh,
                      size: 18.sp,
                      color: AppColors.primaryBlue,
                    ),
                    label: Text(
                      'Book Again',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64.sp,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16.h),
          Text(
            'No sessions yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Book an appointment to get started',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateForTab(String type) {
    String message;
    IconData icon;

    switch (type) {
      case 'ongoing':
        message = 'No ongoing sessions';
        icon = Icons.videocam_off_outlined;
        break;
      case 'upcoming':
        message = 'No upcoming sessions';
        icon = Icons.event_busy_outlined;
        break;
      case 'completed':
        message = 'No completed sessions';
        icon = Icons.history_outlined;
        break;
      default:
        message = 'No sessions';
        icon = Icons.inbox_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64.sp,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _joinVideoCall(
      BuildContext context,
      String appointmentId,
      String doctorId,
      String doctorName,
      ) {
    // Sanitize channel name for Agora compatibility
    // Agora only allows: lowercase letters, numbers, underscores
    final sanitizedId = appointmentId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final channelName = 'appointment_$sanitizedId';

    // 🔍 DEBUGGING
    print('');
    print('🏥 PATIENT JOINING VIDEO CALL');
    print('📌 Appointment ID: $appointmentId');
    print('🧹 Sanitized ID: $sanitizedId');
    print('📺 Channel Name: $channelName');
    print('👤 Doctor: $doctorName ($doctorId)');
    print('');

    // Navigate to video call screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          appointmentId: appointmentId,
          channelName: channelName,
          otherUserName: doctorName,
          otherUserId: doctorId,
          isDoctor: false,
        ),
      ),
    );
  }
}









// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:sheydoc_app/core/constants/app_colors.dart';
// import 'package:intl/intl.dart';
// import '../../../shared/video_call_screen.dart';
//
//
// class PatientSessionsScreen extends StatelessWidget {
//   const PatientSessionsScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;
//
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text(
//           'My Sessions',
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('appointments')
//             .where('patientId', isEqualTo: user?.uid)
//         // Removed orderBy to avoid composite index requirement
//         // We'll sort in memory below
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return _buildEmptyState();
//           }
//
//           final appointments = snapshot.data!.docs;
//
//           // Sort appointments by date in memory (since we can't use orderBy without index)
//           appointments.sort((a, b) {
//             final aData = a.data() as Map<String, dynamic>;
//             final bData = b.data() as Map<String, dynamic>;
//             final aDate = (aData['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime(2000);
//             final bDate = (bData['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime(2000);
//             return aDate.compareTo(bDate); // Ascending order
//           });
//
//           // Separate into categories
//           final upcoming = <QueryDocumentSnapshot>[];
//           final ongoing = <QueryDocumentSnapshot>[];
//           final completed = <QueryDocumentSnapshot>[];
//
//           for (var doc in appointments) {
//             final data = doc.data() as Map<String, dynamic>;
//             final status = data['status'] ?? 'pending';
//             final callStatus = data['callStatus'];
//
//             if (callStatus == 'ongoing') {
//               ongoing.add(doc);
//             } else if (status == 'confirmed') {
//               upcoming.add(doc);
//             } else if (status == 'completed' || callStatus == 'completed') {
//               completed.add(doc);
//             }
//           }
//
//           return DefaultTabController(
//             length: 3,
//             child: Column(
//               children: [
//                 Container(
//                   color: Colors.white,
//                   child: TabBar(
//                     labelColor: AppColors.primaryBlue,
//                     unselectedLabelColor: Colors.grey,
//                     indicatorColor: AppColors.primaryBlue,
//                     labelStyle: TextStyle(
//                       fontSize: 14.sp,
//                       fontWeight: FontWeight.w600,
//                     ),
//                     tabs: [
//                       Tab(text: 'Ongoing (${ongoing.length})'),
//                       Tab(text: 'Upcoming (${upcoming.length})'),
//                       Tab(text: 'Completed (${completed.length})'),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: TabBarView(
//                     children: [
//                       _buildSessionsList(context, ongoing, 'ongoing'),
//                       _buildSessionsList(context, upcoming, 'upcoming'),
//                       _buildSessionsList(context, completed, 'completed'),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildSessionsList(
//       BuildContext context,
//       List<QueryDocumentSnapshot> sessions,
//       String type,
//       ) {
//     if (sessions.isEmpty) {
//       return _buildEmptyStateForTab(type);
//     }
//
//     return ListView.builder(
//       padding: EdgeInsets.all(16.w),
//       itemCount: sessions.length,
//       itemBuilder: (context, index) {
//         final data = sessions[index].data() as Map<String, dynamic>;
//         final appointmentId = sessions[index].id;
//         return _buildSessionCard(context, data, appointmentId, type);
//       },
//     );
//   }
//
//   Widget _buildSessionCard(
//       BuildContext context,
//       Map<String, dynamic> data,
//       String appointmentId,
//       String type,
//       ) {
//     final doctorName = data['doctorName'] ?? 'Unknown Doctor';
//     final doctorId = data['doctorId'] ?? '';
//     final location = data['location'] ?? 'Unknown';
//     final appointmentType = data['appointmentType'] ?? 'video';
//     final date = (data['appointmentDate'] as Timestamp?)?.toDate();
//     final time = data['appointmentTime'] ?? 'N/A';
//     final status = data['status'] ?? 'pending';
//
//     // Check if appointment is today
//     final isToday = date != null &&
//         date.year == DateTime.now().year &&
//         date.month == DateTime.now().month &&
//         date.day == DateTime.now().day;
//
//     Color statusColor;
//     String statusText;
//
//     switch (status) {
//       case 'confirmed':
//         statusColor = Colors.green;
//         statusText = 'Confirmed';
//         break;
//       case 'pending':
//         statusColor = Colors.orange;
//         statusText = 'Pending';
//         break;
//       case 'cancelled':
//         statusColor = Colors.red;
//         statusText = 'Cancelled';
//         break;
//       case 'completed':
//         statusColor = Colors.blue;
//         statusText = 'Completed';
//         break;
//       default:
//         statusColor = Colors.grey;
//         statusText = status;
//     }
//
//     return Container(
//       margin: EdgeInsets.only(bottom: 12.h),
//       padding: EdgeInsets.all(16.w),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12.r),
//         border: Border.all(
//           color: type == 'ongoing'
//               ? Colors.green
//               : isToday
//               ? AppColors.primaryBlue
//               : Colors.grey[300]!,
//           width: type == 'ongoing' || isToday ? 2 : 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               CircleAvatar(
//                 radius: 28.r,
//                 backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
//                 child: Icon(
//                   Icons.person,
//                   size: 28.sp,
//                   color: AppColors.primaryBlue,
//                 ),
//               ),
//               SizedBox(width: 12.w),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             doctorName,
//                             style: TextStyle(
//                               fontSize: 16.sp,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                         if (type == 'ongoing')
//                           Container(
//                             padding: EdgeInsets.symmetric(
//                               horizontal: 8.w,
//                               vertical: 4.h,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.green,
//                               borderRadius: BorderRadius.circular(4.r),
//                             ),
//                             child: Row(
//                               children: [
//                                 Container(
//                                   width: 6.w,
//                                   height: 6.h,
//                                   decoration: const BoxDecoration(
//                                     color: Colors.white,
//                                     shape: BoxShape.circle,
//                                   ),
//                                 ),
//                                 SizedBox(width: 4.w),
//                                 Text(
//                                   'LIVE',
//                                   style: TextStyle(
//                                     fontSize: 10.sp,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         if (isToday && type == 'upcoming')
//                           Container(
//                             padding: EdgeInsets.symmetric(
//                               horizontal: 8.w,
//                               vertical: 4.h,
//                             ),
//                             decoration: BoxDecoration(
//                               color: AppColors.primaryBlue,
//                               borderRadius: BorderRadius.circular(4.r),
//                             ),
//                             child: Text(
//                               'TODAY',
//                               style: TextStyle(
//                                 fontSize: 10.sp,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                     SizedBox(height: 4.h),
//                     Row(
//                       children: [
//                         Icon(Icons.location_on, size: 14.sp, color: Colors.grey[600]),
//                         SizedBox(width: 4.w),
//                         Text(
//                           location,
//                           style: TextStyle(
//                             fontSize: 13.sp,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 12.h),
//           Container(
//             padding: EdgeInsets.all(12.w),
//             decoration: BoxDecoration(
//               color: Colors.grey[50],
//               borderRadius: BorderRadius.circular(8.r),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.calendar_today,
//                   size: 16.sp,
//                   color: AppColors.primaryBlue,
//                 ),
//                 SizedBox(width: 8.w),
//                 Text(
//                   date != null
//                       ? DateFormat('MMM dd, yyyy').format(date)
//                       : 'Date N/A',
//                   style: TextStyle(
//                     fontSize: 14.sp,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 SizedBox(width: 16.w),
//                 Icon(
//                   Icons.access_time,
//                   size: 16.sp,
//                   color: AppColors.primaryBlue,
//                 ),
//                 SizedBox(width: 8.w),
//                 Text(
//                   time,
//                   style: TextStyle(
//                     fontSize: 14.sp,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const Spacer(),
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
//                   decoration: BoxDecoration(
//                     color: statusColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(4.r),
//                   ),
//                   child: Text(
//                     statusText,
//                     style: TextStyle(
//                       fontSize: 12.sp,
//                       fontWeight: FontWeight.w600,
//                       color: statusColor,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 12.h),
//           if (type == 'ongoing' || (type == 'upcoming' && status == 'confirmed'))
//             ElevatedButton.icon(
//               onPressed: () => _joinVideoCall(
//                 context,
//                 appointmentId,
//                 doctorId,
//                 doctorName,
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: type == 'ongoing' ? Colors.green : AppColors.primaryBlue,
//                 minimumSize: Size(double.infinity, 44.h),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8.r),
//                 ),
//               ),
//               icon: Icon(
//                 type == 'ongoing' ? Icons.videocam : Icons.video_call,
//                 size: 20.sp,
//               ),
//               label: Text(
//                 type == 'ongoing' ? 'Join Ongoing Call' : 'Join Video Call',
//                 style: TextStyle(
//                   fontSize: 14.sp,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           if (type == 'completed')
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () {
//                       // TODO: View session details/summary
//                     },
//                     style: OutlinedButton.styleFrom(
//                       side: BorderSide(color: AppColors.primaryBlue),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8.r),
//                       ),
//                     ),
//                     icon: Icon(
//                       Icons.article_outlined,
//                       size: 18.sp,
//                       color: AppColors.primaryBlue,
//                     ),
//                     label: Text(
//                       'View Summary',
//                       style: TextStyle(
//                         color: AppColors.primaryBlue,
//                         fontSize: 14.sp,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 8.w),
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () {
//                       // TODO: Book again with same doctor
//                     },
//                     style: OutlinedButton.styleFrom(
//                       side: BorderSide(color: AppColors.primaryBlue),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8.r),
//                       ),
//                     ),
//                     icon: Icon(
//                       Icons.refresh,
//                       size: 18.sp,
//                       color: AppColors.primaryBlue,
//                     ),
//                     label: Text(
//                       'Book Again',
//                       style: TextStyle(
//                         color: AppColors.primaryBlue,
//                         fontSize: 14.sp,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.calendar_today_outlined,
//             size: 64.sp,
//             color: Colors.grey[300],
//           ),
//           SizedBox(height: 16.h),
//           Text(
//             'No sessions yet',
//             style: TextStyle(
//               fontSize: 18.sp,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey[600],
//             ),
//           ),
//           SizedBox(height: 8.h),
//           Text(
//             'Book an appointment to get started',
//             style: TextStyle(
//               fontSize: 14.sp,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyStateForTab(String type) {
//     String message;
//     IconData icon;
//
//     switch (type) {
//       case 'ongoing':
//         message = 'No ongoing sessions';
//         icon = Icons.videocam_off_outlined;
//         break;
//       case 'upcoming':
//         message = 'No upcoming sessions';
//         icon = Icons.event_busy_outlined;
//         break;
//       case 'completed':
//         message = 'No completed sessions';
//         icon = Icons.history_outlined;
//         break;
//       default:
//         message = 'No sessions';
//         icon = Icons.inbox_outlined;
//     }
//
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             icon,
//             size: 64.sp,
//             color: Colors.grey[300],
//           ),
//           SizedBox(height: 16.h),
//           Text(
//             message,
//             style: TextStyle(
//               fontSize: 16.sp,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _joinVideoCall(
//       BuildContext context,
//       String appointmentId,
//       String doctorId,
//       String doctorName,
//       ) {
//     // Generate channel name from appointment ID
//     final channelName = 'appointment_$appointmentId';
//
//     // Navigate to video call screen
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => VideoCallScreen(
//           appointmentId: appointmentId,
//           channelName: channelName,
//           otherUserName: doctorName,
//           otherUserId: doctorId,
//           isDoctor: false,
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
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:sheydoc_app/core/constants/app_colors.dart';
// // import 'package:intl/intl.dart';
// // import '../../../shared/video_call_screen.dart';
// //
// //
// // class PatientSessionsScreen extends StatelessWidget {
// //   const PatientSessionsScreen({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final user = FirebaseAuth.instance.currentUser;
// //
// //     return Scaffold(
// //       backgroundColor: Colors.grey[50],
// //       appBar: AppBar(
// //         title: const Text(
// //           'My Sessions',
// //           style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
// //         ),
// //         backgroundColor: Colors.white,
// //         elevation: 0,
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back, color: Colors.black),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //       ),
// //       body: StreamBuilder<QuerySnapshot>(
// //         stream: FirebaseFirestore.instance
// //             .collection('appointments')
// //             .where('patientId', isEqualTo: user?.uid)
// //             .orderBy('appointmentDate', descending: false)
// //             .snapshots(),
// //         builder: (context, snapshot) {
// //           if (snapshot.connectionState == ConnectionState.waiting) {
// //             return const Center(child: CircularProgressIndicator());
// //           }
// //
// //           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// //             return _buildEmptyState();
// //           }
// //
// //           final appointments = snapshot.data!.docs;
// //
// //           // Separate into categories
// //           final upcoming = <QueryDocumentSnapshot>[];
// //           final ongoing = <QueryDocumentSnapshot>[];
// //           final completed = <QueryDocumentSnapshot>[];
// //
// //           for (var doc in appointments) {
// //             final data = doc.data() as Map<String, dynamic>;
// //             final status = data['status'] ?? 'pending';
// //             final callStatus = data['callStatus'];
// //
// //             if (callStatus == 'ongoing') {
// //               ongoing.add(doc);
// //             } else if (status == 'confirmed') {
// //               upcoming.add(doc);
// //             } else if (status == 'completed' || callStatus == 'completed') {
// //               completed.add(doc);
// //             }
// //           }
// //
// //           return DefaultTabController(
// //             length: 3,
// //             child: Column(
// //               children: [
// //                 Container(
// //                   color: Colors.white,
// //                   child: TabBar(
// //                     labelColor: AppColors.primaryBlue,
// //                     unselectedLabelColor: Colors.grey,
// //                     indicatorColor: AppColors.primaryBlue,
// //                     labelStyle: TextStyle(
// //                       fontSize: 14.sp,
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                     tabs: [
// //                       Tab(text: 'Ongoing (${ongoing.length})'),
// //                       Tab(text: 'Upcoming (${upcoming.length})'),
// //                       Tab(text: 'Completed (${completed.length})'),
// //                     ],
// //                   ),
// //                 ),
// //                 Expanded(
// //                   child: TabBarView(
// //                     children: [
// //                       _buildSessionsList(context, ongoing, 'ongoing'),
// //                       _buildSessionsList(context, upcoming, 'upcoming'),
// //                       _buildSessionsList(context, completed, 'completed'),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// //
// //   Widget _buildSessionsList(
// //       BuildContext context,
// //       List<QueryDocumentSnapshot> sessions,
// //       String type,
// //       ) {
// //     if (sessions.isEmpty) {
// //       return _buildEmptyStateForTab(type);
// //     }
// //
// //     return ListView.builder(
// //       padding: EdgeInsets.all(16.w),
// //       itemCount: sessions.length,
// //       itemBuilder: (context, index) {
// //         final data = sessions[index].data() as Map<String, dynamic>;
// //         final appointmentId = sessions[index].id;
// //         return _buildSessionCard(context, data, appointmentId, type);
// //       },
// //     );
// //   }
// //
// //   Widget _buildSessionCard(
// //       BuildContext context,
// //       Map<String, dynamic> data,
// //       String appointmentId,
// //       String type,
// //       ) {
// //     final doctorName = data['doctorName'] ?? 'Unknown Doctor';
// //     final doctorId = data['doctorId'] ?? '';
// //     final location = data['location'] ?? 'Unknown';
// //     final appointmentType = data['appointmentType'] ?? 'video';
// //     final date = (data['appointmentDate'] as Timestamp?)?.toDate();
// //     final time = data['appointmentTime'] ?? 'N/A';
// //     final status = data['status'] ?? 'pending';
// //
// //     // Check if appointment is today
// //     final isToday = date != null &&
// //         date.year == DateTime.now().year &&
// //         date.month == DateTime.now().month &&
// //         date.day == DateTime.now().day;
// //
// //     Color statusColor;
// //     String statusText;
// //
// //     switch (status) {
// //       case 'confirmed':
// //         statusColor = Colors.green;
// //         statusText = 'Confirmed';
// //         break;
// //       case 'pending':
// //         statusColor = Colors.orange;
// //         statusText = 'Pending';
// //         break;
// //       case 'cancelled':
// //         statusColor = Colors.red;
// //         statusText = 'Cancelled';
// //         break;
// //       case 'completed':
// //         statusColor = Colors.blue;
// //         statusText = 'Completed';
// //         break;
// //       default:
// //         statusColor = Colors.grey;
// //         statusText = status;
// //     }
// //
// //     return Container(
// //       margin: EdgeInsets.only(bottom: 12.h),
// //       padding: EdgeInsets.all(16.w),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12.r),
// //         border: Border.all(
// //           color: type == 'ongoing'
// //               ? Colors.green
// //               : isToday
// //               ? AppColors.primaryBlue
// //               : Colors.grey[300]!,
// //           width: type == 'ongoing' || isToday ? 2 : 1,
// //         ),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.grey.withOpacity(0.1),
// //             blurRadius: 4,
// //             offset: const Offset(0, 2),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               CircleAvatar(
// //                 radius: 28.r,
// //                 backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
// //                 child: Icon(
// //                   Icons.person,
// //                   size: 28.sp,
// //                   color: AppColors.primaryBlue,
// //                 ),
// //               ),
// //               SizedBox(width: 12.w),
// //               Expanded(
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Row(
// //                       children: [
// //                         Expanded(
// //                           child: Text(
// //                             doctorName,
// //                             style: TextStyle(
// //                               fontSize: 16.sp,
// //                               fontWeight: FontWeight.bold,
// //                               color: Colors.black,
// //                             ),
// //                           ),
// //                         ),
// //                         if (type == 'ongoing')
// //                           Container(
// //                             padding: EdgeInsets.symmetric(
// //                               horizontal: 8.w,
// //                               vertical: 4.h,
// //                             ),
// //                             decoration: BoxDecoration(
// //                               color: Colors.green,
// //                               borderRadius: BorderRadius.circular(4.r),
// //                             ),
// //                             child: Row(
// //                               children: [
// //                                 Container(
// //                                   width: 6.w,
// //                                   height: 6.h,
// //                                   decoration: const BoxDecoration(
// //                                     color: Colors.white,
// //                                     shape: BoxShape.circle,
// //                                   ),
// //                                 ),
// //                                 SizedBox(width: 4.w),
// //                                 Text(
// //                                   'LIVE',
// //                                   style: TextStyle(
// //                                     fontSize: 10.sp,
// //                                     fontWeight: FontWeight.bold,
// //                                     color: Colors.white,
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                         if (isToday && type == 'upcoming')
// //                           Container(
// //                             padding: EdgeInsets.symmetric(
// //                               horizontal: 8.w,
// //                               vertical: 4.h,
// //                             ),
// //                             decoration: BoxDecoration(
// //                               color: AppColors.primaryBlue,
// //                               borderRadius: BorderRadius.circular(4.r),
// //                             ),
// //                             child: Text(
// //                               'TODAY',
// //                               style: TextStyle(
// //                                 fontSize: 10.sp,
// //                                 fontWeight: FontWeight.bold,
// //                                 color: Colors.white,
// //                               ),
// //                             ),
// //                           ),
// //                       ],
// //                     ),
// //                     SizedBox(height: 4.h),
// //                     Row(
// //                       children: [
// //                         Icon(Icons.location_on, size: 14.sp, color: Colors.grey[600]),
// //                         SizedBox(width: 4.w),
// //                         Text(
// //                           location,
// //                           style: TextStyle(
// //                             fontSize: 13.sp,
// //                             color: Colors.grey[600],
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           ),
// //           SizedBox(height: 12.h),
// //           Container(
// //             padding: EdgeInsets.all(12.w),
// //             decoration: BoxDecoration(
// //               color: Colors.grey[50],
// //               borderRadius: BorderRadius.circular(8.r),
// //             ),
// //             child: Row(
// //               children: [
// //                 Icon(
// //                   Icons.calendar_today,
// //                   size: 16.sp,
// //                   color: AppColors.primaryBlue,
// //                 ),
// //                 SizedBox(width: 8.w),
// //                 Text(
// //                   date != null
// //                       ? DateFormat('MMM dd, yyyy').format(date)
// //                       : 'Date N/A',
// //                   style: TextStyle(
// //                     fontSize: 14.sp,
// //                     fontWeight: FontWeight.w500,
// //                   ),
// //                 ),
// //                 SizedBox(width: 16.w),
// //                 Icon(
// //                   Icons.access_time,
// //                   size: 16.sp,
// //                   color: AppColors.primaryBlue,
// //                 ),
// //                 SizedBox(width: 8.w),
// //                 Text(
// //                   time,
// //                   style: TextStyle(
// //                     fontSize: 14.sp,
// //                     fontWeight: FontWeight.w500,
// //                   ),
// //                 ),
// //                 const Spacer(),
// //                 Container(
// //                   padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
// //                   decoration: BoxDecoration(
// //                     color: statusColor.withOpacity(0.1),
// //                     borderRadius: BorderRadius.circular(4.r),
// //                   ),
// //                   child: Text(
// //                     statusText,
// //                     style: TextStyle(
// //                       fontSize: 12.sp,
// //                       fontWeight: FontWeight.w600,
// //                       color: statusColor,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           SizedBox(height: 12.h),
// //           if (type == 'ongoing' || (type == 'upcoming' && status == 'confirmed'))
// //             ElevatedButton.icon(
// //               onPressed: () => _joinVideoCall(
// //                 context,
// //                 appointmentId,
// //                 doctorId,
// //                 doctorName,
// //               ),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: type == 'ongoing' ? Colors.green : AppColors.primaryBlue,
// //                 minimumSize: Size(double.infinity, 44.h),
// //                 shape: RoundedRectangleBorder(
// //                   borderRadius: BorderRadius.circular(8.r),
// //                 ),
// //               ),
// //               icon: Icon(
// //                 type == 'ongoing' ? Icons.videocam : Icons.video_call,
// //                 size: 20.sp,
// //               ),
// //               label: Text(
// //                 type == 'ongoing' ? 'Join Ongoing Call' : 'Join Video Call',
// //                 style: TextStyle(
// //                   fontSize: 14.sp,
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //             ),
// //           if (type == 'completed')
// //             Row(
// //               children: [
// //                 Expanded(
// //                   child: OutlinedButton.icon(
// //                     onPressed: () {
// //                       // TODO: View session details/summary
// //                     },
// //                     style: OutlinedButton.styleFrom(
// //                       side: BorderSide(color: AppColors.primaryBlue),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(8.r),
// //                       ),
// //                     ),
// //                     icon: Icon(
// //                       Icons.article_outlined,
// //                       size: 18.sp,
// //                       color: AppColors.primaryBlue,
// //                     ),
// //                     label: Text(
// //                       'View Summary',
// //                       style: TextStyle(
// //                         color: AppColors.primaryBlue,
// //                         fontSize: 14.sp,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //                 SizedBox(width: 8.w),
// //                 Expanded(
// //                   child: OutlinedButton.icon(
// //                     onPressed: () {
// //                       // TODO: Book again with same doctor
// //                     },
// //                     style: OutlinedButton.styleFrom(
// //                       side: BorderSide(color: AppColors.primaryBlue),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(8.r),
// //                       ),
// //                     ),
// //                     icon: Icon(
// //                       Icons.refresh,
// //                       size: 18.sp,
// //                       color: AppColors.primaryBlue,
// //                     ),
// //                     label: Text(
// //                       'Book Again',
// //                       style: TextStyle(
// //                         color: AppColors.primaryBlue,
// //                         fontSize: 14.sp,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildEmptyState() {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(
// //             Icons.calendar_today_outlined,
// //             size: 64.sp,
// //             color: Colors.grey[300],
// //           ),
// //           SizedBox(height: 16.h),
// //           Text(
// //             'No sessions yet',
// //             style: TextStyle(
// //               fontSize: 18.sp,
// //               fontWeight: FontWeight.w600,
// //               color: Colors.grey[600],
// //             ),
// //           ),
// //           SizedBox(height: 8.h),
// //           Text(
// //             'Book an appointment to get started',
// //             style: TextStyle(
// //               fontSize: 14.sp,
// //               color: Colors.grey[500],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildEmptyStateForTab(String type) {
// //     String message;
// //     IconData icon;
// //
// //     switch (type) {
// //       case 'ongoing':
// //         message = 'No ongoing sessions';
// //         icon = Icons.videocam_off_outlined;
// //         break;
// //       case 'upcoming':
// //         message = 'No upcoming sessions';
// //         icon = Icons.event_busy_outlined;
// //         break;
// //       case 'completed':
// //         message = 'No completed sessions';
// //         icon = Icons.history_outlined;
// //         break;
// //       default:
// //         message = 'No sessions';
// //         icon = Icons.inbox_outlined;
// //     }
// //
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(
// //             icon,
// //             size: 64.sp,
// //             color: Colors.grey[300],
// //           ),
// //           SizedBox(height: 16.h),
// //           Text(
// //             message,
// //             style: TextStyle(
// //               fontSize: 16.sp,
// //               color: Colors.grey[500],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   void _joinVideoCall(
// //       BuildContext context,
// //       String appointmentId,
// //       String doctorId,
// //       String doctorName,
// //       ) {
// //     // Generate channel name from appointment ID
// //     final channelName = 'appointment_$appointmentId';
// //
// //     // Navigate to video call screen
// //     Navigator.push(
// //       context,
// //       MaterialPageRoute(
// //         builder: (context) => VideoCallScreen(
// //           appointmentId: appointmentId,
// //           channelName: channelName,
// //           otherUserName: doctorName,
// //           otherUserId: doctorId,
// //           isDoctor: false,
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// //
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // // import 'package:sheydoc_app/core/constants/app_colors.dart';
// // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // import 'package:firebase_auth/firebase_auth.dart';
// // // import 'package:intl/intl.dart';
// // //
// // // import '../../../shared/videocall_patient_screen.dart';
// // //
// // // class PatientSessionsScreen extends StatefulWidget {
// // //   const PatientSessionsScreen({super.key});
// // //
// // //   @override
// // //   State<PatientSessionsScreen> createState() => _PatientSessionsScreenState();
// // // }
// // //
// // // class _PatientSessionsScreenState extends State<PatientSessionsScreen> {
// // //   String _selectedFilter = 'All Sessions';
// // //   final List<String> _filterOptions = ['All Sessions', 'Upcoming', 'Completed', 'Cancelled'];
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final user = FirebaseAuth.instance.currentUser;
// // //     if (user == null) {
// // //       return const Scaffold(
// // //         body: Center(child: Text('Please log in')),
// // //       );
// // //     }
// // //
// // //     return Scaffold(
// // //       backgroundColor: Colors.white,
// // //       appBar: AppBar(
// // //         title: Text(
// // //           'Sessions',
// // //           style: TextStyle(
// // //             color: Colors.black,
// // //             fontWeight: FontWeight.w600,
// // //             fontSize: 20.sp,
// // //           ),
// // //         ),
// // //         backgroundColor: Colors.white,
// // //         elevation: 0,
// // //         leading: IconButton(
// // //           icon: const Icon(Icons.arrow_back, color: Colors.black),
// // //           onPressed: () => Navigator.pop(context),
// // //         ),
// // //       ),
// // //       body: StreamBuilder<QuerySnapshot>(
// // //         stream: FirebaseFirestore.instance
// // //             .collection('appointments')
// // //             .where('patientId', isEqualTo: user.uid)
// // //             .orderBy('appointmentDate', descending: false)
// // //             .snapshots(),
// // //         builder: (context, snapshot) {
// // //           if (snapshot.connectionState == ConnectionState.waiting) {
// // //             return const Center(child: CircularProgressIndicator());
// // //           }
// // //
// // //           if (snapshot.hasError) {
// // //             return Center(child: Text('Error: ${snapshot.error}'));
// // //           }
// // //
// // //           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// // //             return Center(
// // //               child: Column(
// // //                 mainAxisAlignment: MainAxisAlignment.center,
// // //                 children: [
// // //                   Icon(
// // //                     Icons.calendar_today_outlined,
// // //                     size: 80.sp,
// // //                     color: Colors.grey[300],
// // //                   ),
// // //                   SizedBox(height: 16.h),
// // //                   Text(
// // //                     'No appointments yet',
// // //                     style: TextStyle(
// // //                       fontSize: 18.sp,
// // //                       fontWeight: FontWeight.w600,
// // //                       color: Colors.grey[600],
// // //                     ),
// // //                   ),
// // //                   SizedBox(height: 8.h),
// // //                   Text(
// // //                     'Book an appointment to get started',
// // //                     style: TextStyle(
// // //                       fontSize: 14.sp,
// // //                       color: Colors.grey[500],
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             );
// // //           }
// // //
// // //           final appointments = snapshot.data!.docs;
// // //
// // //           // Separate upcoming and other appointments
// // //           final now = DateTime.now();
// // //           final upcomingAppointments = appointments.where((doc) {
// // //             final data = doc.data() as Map<String, dynamic>;
// // //             final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
// // //             final status = data['status'] ?? 'booked';
// // //             return appointmentDate.isAfter(now) && status == 'booked';
// // //           }).toList();
// // //
// // //           final filteredAppointments = _getFilteredAppointments(appointments);
// // //
// // //           return SingleChildScrollView(
// // //             padding: EdgeInsets.all(20.w),
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 // Upcoming Session Card (if exists)
// // //                 if (upcomingAppointments.isNotEmpty)
// // //                   _buildUpcomingSessionCard(upcomingAppointments.first),
// // //
// // //                 if (upcomingAppointments.isNotEmpty) SizedBox(height: 24.h),
// // //
// // //                 // Filter Dropdown
// // //                 Row(
// // //                   children: [
// // //                     Container(
// // //                       padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
// // //                       decoration: BoxDecoration(
// // //                         border: Border.all(color: Colors.grey[300]!),
// // //                         borderRadius: BorderRadius.circular(8.r),
// // //                       ),
// // //                       child: DropdownButton<String>(
// // //                         value: _selectedFilter,
// // //                         underline: const SizedBox(),
// // //                         icon: Icon(Icons.keyboard_arrow_down, size: 20.sp),
// // //                         style: TextStyle(
// // //                           fontSize: 14.sp,
// // //                           color: Colors.black,
// // //                           fontWeight: FontWeight.w500,
// // //                         ),
// // //                         items: _filterOptions.map((String value) {
// // //                           return DropdownMenuItem<String>(
// // //                             value: value,
// // //                             child: Text(value),
// // //                           );
// // //                         }).toList(),
// // //                         onChanged: (String? newValue) {
// // //                           setState(() {
// // //                             _selectedFilter = newValue!;
// // //                           });
// // //                         },
// // //                       ),
// // //                     ),
// // //                     const Spacer(),
// // //                     Icon(
// // //                       Icons.filter_list,
// // //                       size: 24.sp,
// // //                       color: AppColors.primaryBlue,
// // //                     ),
// // //                   ],
// // //                 ),
// // //
// // //                 SizedBox(height: 20.h),
// // //
// // //                 // All Sessions List
// // //                 if (filteredAppointments.isEmpty)
// // //                   Center(
// // //                     child: Padding(
// // //                       padding: EdgeInsets.symmetric(vertical: 40.h),
// // //                       child: Text(
// // //                         'No ${_selectedFilter.toLowerCase()}',
// // //                         style: TextStyle(
// // //                           fontSize: 16.sp,
// // //                           color: Colors.grey[500],
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   )
// // //                 else
// // //                   ...filteredAppointments.map((doc) {
// // //                     return _buildSessionCard(doc);
// // //                   }).toList(),
// // //               ],
// // //             ),
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // //
// // //   List<QueryDocumentSnapshot> _getFilteredAppointments(List<QueryDocumentSnapshot> appointments) {
// // //     final now = DateTime.now();
// // //
// // //     return appointments.where((doc) {
// // //       final data = doc.data() as Map<String, dynamic>;
// // //       final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
// // //       final status = data['status'] ?? 'booked';
// // //
// // //       switch (_selectedFilter) {
// // //         case 'Upcoming':
// // //           return appointmentDate.isAfter(now) && status == 'booked';
// // //         case 'Completed':
// // //           return status == 'completed';
// // //         case 'Cancelled':
// // //           return status == 'cancelled';
// // //         default: // All Sessions
// // //           return true;
// // //       }
// // //     }).toList();
// // //   }
// // //
// // //   Widget _buildUpcomingSessionCard(QueryDocumentSnapshot doc) {
// // //     final data = doc.data() as Map<String, dynamic>;
// // //     final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
// // //     final doctorName = data['doctorName'] ?? 'Doctor';
// // //     final specialty = data['doctorSpecialty'] ?? 'General Practitioner';
// // //     final appointmentTime = data['appointmentTime'] ?? 'N/A';
// // //     final appointmentType = data['appointmentType'] ?? 'video';
// // //
// // //     final isStartingSoon = _isAppointmentStartingSoon(appointmentDate, appointmentTime);
// // //
// // //     return Container(
// // //       padding: EdgeInsets.all(20.w),
// // //       decoration: BoxDecoration(
// // //         gradient: LinearGradient(
// // //           colors: [
// // //             AppColors.primaryBlue.withOpacity(0.3),
// // //             AppColors.primaryBlue.withOpacity(0.15),
// // //           ],
// // //           begin: Alignment.topLeft,
// // //           end: Alignment.bottomRight,
// // //         ),
// // //         borderRadius: BorderRadius.circular(16.r),
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Text(
// // //             'Upcoming Session',
// // //             style: TextStyle(
// // //               fontSize: 20.sp,
// // //               fontWeight: FontWeight.bold,
// // //               color: Colors.black,
// // //             ),
// // //           ),
// // //           SizedBox(height: 8.h),
// // //           Text(
// // //             'Dr. $doctorName, $specialty',
// // //             style: TextStyle(
// // //               fontSize: 14.sp,
// // //               color: Colors.grey[700],
// // //             ),
// // //           ),
// // //           SizedBox(height: 4.h),
// // //           Text(
// // //             '${DateFormat('h:mm a').format(appointmentDate)} - ${_getEndTime(appointmentDate, 30)}',
// // //             style: TextStyle(
// // //               fontSize: 14.sp,
// // //               color: Colors.grey[700],
// // //             ),
// // //           ),
// // //           SizedBox(height: 16.h),
// // //           ElevatedButton(
// // //             onPressed: isStartingSoon
// // //                 ? () => _joinSession(doc.id, appointmentType)
// // //                 : null,
// // //             style: ElevatedButton.styleFrom(
// // //               backgroundColor: isStartingSoon ? AppColors.primaryBlue : Colors.grey[400],
// // //               padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
// // //               shape: RoundedRectangleBorder(
// // //                 borderRadius: BorderRadius.circular(25.r),
// // //               ),
// // //             ),
// // //             child: Row(
// // //               mainAxisSize: MainAxisSize.min,
// // //               children: [
// // //                 Text(
// // //                   isStartingSoon ? 'Join Now' : 'Starting Soon',
// // //                   style: TextStyle(
// // //                     fontSize: 14.sp,
// // //                     fontWeight: FontWeight.w600,
// // //                     color: Colors.white,
// // //                   ),
// // //                 ),
// // //                 SizedBox(width: 8.w),
// // //                 Icon(
// // //                   Icons.play_circle_fill,
// // //                   size: 20.sp,
// // //                   color: Colors.white,
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildSessionCard(QueryDocumentSnapshot doc) {
// // //     final data = doc.data() as Map<String, dynamic>;
// // //     final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
// // //     final doctorName = data['doctorName'] ?? 'Doctor';
// // //     final specialty = data['doctorSpecialty'] ?? 'General Practitioner';
// // //     final appointmentTime = data['appointmentTime'] ?? 'N/A';
// // //     final status = data['status'] ?? 'booked';
// // //     final appointmentType = data['appointmentType'] ?? 'video';
// // //
// // //     final now = DateTime.now();
// // //     final isPast = appointmentDate.isBefore(now);
// // //     final isStartingSoon = _isAppointmentStartingSoon(appointmentDate, appointmentTime);
// // //     final canJoin = !isPast && status == 'booked' && isStartingSoon;
// // //
// // //     return Container(
// // //       margin: EdgeInsets.only(bottom: 16.h),
// // //       padding: EdgeInsets.all(16.w),
// // //       decoration: BoxDecoration(
// // //         color: AppColors.primaryBlue.withOpacity(0.05),
// // //         borderRadius: BorderRadius.circular(12.r),
// // //         border: Border.all(
// // //           color: AppColors.primaryBlue.withOpacity(0.2),
// // //           width: 1,
// // //         ),
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Row(
// // //             children: [
// // //               CircleAvatar(
// // //                 radius: 24.r,
// // //                 backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
// // //                 child: Icon(
// // //                   Icons.person,
// // //                   size: 28.sp,
// // //                   color: AppColors.primaryBlue,
// // //                 ),
// // //               ),
// // //               SizedBox(width: 12.w),
// // //               Expanded(
// // //                 child: Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   children: [
// // //                     Text(
// // //                       'Dr. $doctorName',
// // //                       style: TextStyle(
// // //                         fontSize: 16.sp,
// // //                         fontWeight: FontWeight.w600,
// // //                         color: Colors.black,
// // //                       ),
// // //                     ),
// // //                     Text(
// // //                       specialty,
// // //                       style: TextStyle(
// // //                         fontSize: 13.sp,
// // //                         color: Colors.grey[600],
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //               _buildStatusChip(status),
// // //             ],
// // //           ),
// // //
// // //           SizedBox(height: 12.h),
// // //
// // //           Divider(color: Colors.grey[300], height: 1),
// // //
// // //           SizedBox(height: 12.h),
// // //
// // //           Row(
// // //             children: [
// // //               Icon(Icons.calendar_today, size: 16.sp, color: Colors.grey[600]),
// // //               SizedBox(width: 8.w),
// // //               Text(
// // //                 DateFormat('MMM d, yyyy').format(appointmentDate),
// // //                 style: TextStyle(
// // //                   fontSize: 14.sp,
// // //                   color: Colors.grey[700],
// // //                 ),
// // //               ),
// // //               SizedBox(width: 24.w),
// // //               Icon(Icons.access_time, size: 16.sp, color: Colors.grey[600]),
// // //               SizedBox(width: 8.w),
// // //               Text(
// // //                 appointmentTime,
// // //                 style: TextStyle(
// // //                   fontSize: 14.sp,
// // //                   color: Colors.grey[700],
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //
// // //           SizedBox(height: 16.h),
// // //
// // //           Row(
// // //             children: [
// // //               if (canJoin)
// // //                 Expanded(
// // //                   child: ElevatedButton(
// // //                     onPressed: () => _joinSession(doc.id, appointmentType),
// // //                     style: ElevatedButton.styleFrom(
// // //                       backgroundColor: AppColors.primaryBlue,
// // //                       padding: EdgeInsets.symmetric(vertical: 12.h),
// // //                       shape: RoundedRectangleBorder(
// // //                         borderRadius: BorderRadius.circular(8.r),
// // //                       ),
// // //                     ),
// // //                     child: Text(
// // //                       'Join Now',
// // //                       style: TextStyle(
// // //                         fontSize: 14.sp,
// // //                         fontWeight: FontWeight.w600,
// // //                         color: Colors.white,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ),
// // //               if (!canJoin && status == 'booked')
// // //                 Expanded(
// // //                   child: OutlinedButton(
// // //                     onPressed: () => _showAppointmentDetails(data),
// // //                     style: OutlinedButton.styleFrom(
// // //                       side: BorderSide(color: AppColors.primaryBlue),
// // //                       padding: EdgeInsets.symmetric(vertical: 12.h),
// // //                       shape: RoundedRectangleBorder(
// // //                         borderRadius: BorderRadius.circular(8.r),
// // //                       ),
// // //                     ),
// // //                     child: Text(
// // //                       'View Details',
// // //                       style: TextStyle(
// // //                         fontSize: 14.sp,
// // //                         fontWeight: FontWeight.w600,
// // //                         color: AppColors.primaryBlue,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ),
// // //               if (status == 'completed')
// // //                 Expanded(
// // //                   child: OutlinedButton(
// // //                     onPressed: null,
// // //                     style: OutlinedButton.styleFrom(
// // //                       side: BorderSide(color: Colors.grey[400]!),
// // //                       padding: EdgeInsets.symmetric(vertical: 12.h),
// // //                       shape: RoundedRectangleBorder(
// // //                         borderRadius: BorderRadius.circular(8.r),
// // //                       ),
// // //                     ),
// // //                     child: Text(
// // //                       'Completed',
// // //                       style: TextStyle(
// // //                         fontSize: 14.sp,
// // //                         fontWeight: FontWeight.w600,
// // //                         color: Colors.grey[600],
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ),
// // //             ],
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildStatusChip(String status) {
// // //     Color backgroundColor;
// // //     Color textColor;
// // //     String displayText;
// // //
// // //     switch (status.toLowerCase()) {
// // //       case 'booked':
// // //         backgroundColor = Colors.blue[100]!;
// // //         textColor = Colors.blue[700]!;
// // //         displayText = 'Booked';
// // //         break;
// // //       case 'completed':
// // //         backgroundColor = Colors.green[100]!;
// // //         textColor = Colors.green[700]!;
// // //         displayText = 'Completed';
// // //         break;
// // //       case 'cancelled':
// // //         backgroundColor = Colors.red[100]!;
// // //         textColor = Colors.red[700]!;
// // //         displayText = 'Cancelled';
// // //         break;
// // //       default:
// // //         backgroundColor = Colors.grey[200]!;
// // //         textColor = Colors.grey[700]!;
// // //         displayText = status;
// // //     }
// // //
// // //     return Container(
// // //       padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
// // //       decoration: BoxDecoration(
// // //         color: backgroundColor,
// // //         borderRadius: BorderRadius.circular(12.r),
// // //       ),
// // //       child: Text(
// // //         displayText,
// // //         style: TextStyle(
// // //           fontSize: 12.sp,
// // //           fontWeight: FontWeight.w600,
// // //           color: textColor,
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   bool _isAppointmentStartingSoon(DateTime appointmentDate, String appointmentTime) {
// // //     try {
// // //       final now = DateTime.now();
// // //
// // //       // Parse time (format: "10:30 AM")
// // //       final timeParts = appointmentTime.split(' ');
// // //       final hourMin = timeParts[0].split(':');
// // //       int hour = int.parse(hourMin[0]);
// // //       final minute = int.parse(hourMin[1]);
// // //
// // //       // Handle AM/PM
// // //       if (timeParts.length > 1) {
// // //         final period = timeParts[1].toUpperCase();
// // //         if (period == 'PM' && hour != 12) {
// // //           hour += 12;
// // //         } else if (period == 'AM' && hour == 12) {
// // //           hour = 0;
// // //         }
// // //       }
// // //
// // //       final appointmentDateTime = DateTime(
// // //         appointmentDate.year,
// // //         appointmentDate.month,
// // //         appointmentDate.day,
// // //         hour,
// // //         minute,
// // //       );
// // //
// // //       final difference = appointmentDateTime.difference(now);
// // //
// // //       // Can join 15 minutes before and up to 30 minutes after
// // //       return difference.inMinutes >= -15 && difference.inMinutes <= 30;
// // //     } catch (e) {
// // //       print('Error parsing time: $e');
// // //       return false;
// // //     }
// // //   }
// // //
// // //   String _getEndTime(DateTime startTime, int durationMinutes) {
// // //     final endTime = startTime.add(Duration(minutes: durationMinutes));
// // //     return DateFormat('h:mm a').format(endTime);
// // //   }
// // //
// // //   void _joinSession(String appointmentId, String appointmentType) async {
// // //     // Get current user info
// // //     final user = FirebaseAuth.instance.currentUser;
// // //     if (user == null) return;
// // //
// // //     try {
// // //       final userDoc = await FirebaseFirestore.instance
// // //           .collection('users')
// // //           .doc(user.uid)
// // //           .get();
// // //       final userName = userDoc.data()?['name'] ?? 'Patient';
// // //
// // //       // Navigate to video call screen
// // //       Navigator.push(
// // //         context,
// // //         MaterialPageRoute(
// // //           builder: (context) => VideoCallScreen(
// // //             appointmentId: appointmentId,
// // //             userName: userName,
// // //             isDoctor: false, // Patient
// // //           ),
// // //         ),
// // //       );
// // //     } catch (e) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text('Error joining call: $e'),
// // //           backgroundColor: Colors.red,
// // //         ),
// // //       );
// // //     }
// // //   }
// // //
// // //   void _showAppointmentDetails(Map<String, dynamic> data) {
// // //     showModalBottomSheet(
// // //       context: context,
// // //       shape: RoundedRectangleBorder(
// // //         borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
// // //       ),
// // //       builder: (context) => Container(
// // //         padding: EdgeInsets.all(24.w),
// // //         child: Column(
// // //           mainAxisSize: MainAxisSize.min,
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             Text(
// // //               'Appointment Details',
// // //               style: TextStyle(
// // //                 fontSize: 20.sp,
// // //                 fontWeight: FontWeight.bold,
// // //               ),
// // //             ),
// // //             SizedBox(height: 20.h),
// // //             _buildDetailRow('Doctor', 'Dr. ${data['doctorName']}'),
// // //             _buildDetailRow('Date', DateFormat('MMMM d, yyyy').format((data['appointmentDate'] as Timestamp).toDate())),
// // //             _buildDetailRow('Time', data['appointmentTime']),
// // //             _buildDetailRow('Type', data['appointmentType'] == 'video' ? 'Video Call' : 'Audio Call'),
// // //             _buildDetailRow('Fee', '${data['fee']} FCFA'),
// // //             SizedBox(height: 24.h),
// // //             SizedBox(
// // //               width: double.infinity,
// // //               child: ElevatedButton(
// // //                 onPressed: () => Navigator.pop(context),
// // //                 style: ElevatedButton.styleFrom(
// // //                   backgroundColor: AppColors.primaryBlue,
// // //                   padding: EdgeInsets.symmetric(vertical: 14.h),
// // //                   shape: RoundedRectangleBorder(
// // //                     borderRadius: BorderRadius.circular(12.r),
// // //                   ),
// // //                 ),
// // //                 child: Text(
// // //                   'Close',
// // //                   style: TextStyle(
// // //                     fontSize: 16.sp,
// // //                     fontWeight: FontWeight.w600,
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildDetailRow(String label, String value) {
// // //     return Padding(
// // //       padding: EdgeInsets.only(bottom: 12.h),
// // //       child: Row(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           SizedBox(
// // //             width: 100.w,
// // //             child: Text(
// // //               '$label:',
// // //               style: TextStyle(
// // //                 fontSize: 14.sp,
// // //                 color: Colors.grey[600],
// // //               ),
// // //             ),
// // //           ),
// // //           Expanded(
// // //             child: Text(
// // //               value,
// // //               style: TextStyle(
// // //                 fontSize: 14.sp,
// // //                 fontWeight: FontWeight.w600,
// // //                 color: Colors.black,
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// //
// //
// //
// //
// //
