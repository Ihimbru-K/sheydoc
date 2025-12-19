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



