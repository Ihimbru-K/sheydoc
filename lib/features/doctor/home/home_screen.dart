import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sheydoc_app/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = FirebaseAuth.instance.currentUser;

  int _selectedNavIndex = 0;
  int appointmentsCount = 0;
  int patientsCount = 0;
  int videoCallsCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    if (user == null) return;
    final appointmentsSnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: user!.uid)
        .get();
    final uniquePatients = <String>{};
    int videoCallCount = 0;
    for (var doc in appointmentsSnapshot.docs) {
      final data = doc.data();
      uniquePatients.add(data['patientId']);
      if (data['appointmentType'] == 'video') videoCallCount++;
    }
    setState(() {
      appointmentsCount = appointmentsSnapshot.docs.length;
      patientsCount = uniquePatients.length;
      videoCallsCount = videoCallCount;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0: // Home - do nothing, already here
        break;
      case 1: // Community - TODO
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Community feature coming soon!')),
        );
        break;
      case 2: // Patients - show all patients tab
        _tabController.animateTo(1);
        break;
      case 3: // Messages
        Navigator.pushNamed(context, '/doctor/messages');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildActionCards(),
            SizedBox(height: 2.h),
            _buildMetricsCards(),
            SizedBox(height: 2.h),
            _buildQuickActions(),
            SizedBox(height: 8.h),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildRequestsTab(), _buildAllPatientsTab(), _buildBookedTab()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: AppColors.primaryBlue,
            child: Icon(Icons.person, color: Colors.white, size: 20.sp),
          ),
          const Spacer(),
          IconButton(icon: Icon(Icons.settings, size: 24.sp, color: Colors.black), onPressed: () {}),
          _buildNotificationButton(),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user?.uid)
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications, size: 24.sp, color: Colors.black),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
            ),
            if (count > 0)
              Positioned(
                right: 8, top: 8,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.h),
                  child: Text(
                    count > 9 ? '9+' : count.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActionCards() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildActionCard('Connect with a\nPatient', Icons.video_call, AppColors.primaryBlue,
                      () => Navigator.pushNamed(context, '/doctor/video-patients'))),
              SizedBox(width: 12.w),
              Expanded(child: _buildActionCard('View Appointments', Icons.calendar_today, const Color(0xFF87CEEB),
                      () => _tabController.animateTo(2))),
            ],
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
              decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(12.r)),
              child: Row(
                children: [
                  Icon(Icons.add_circle, color: Colors.white, size: 24.sp),
                  SizedBox(width: 12.w),
                  Text('Create Educational Resources', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3)),
            SizedBox(height: 8.h),
            Icon(icon, color: Colors.white, size: 24.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCards() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(child: _buildMetricCard(Icons.calendar_today, 'Appointments', appointmentsCount.toString())),
          SizedBox(width: 12.w),
          Expanded(child: _buildMetricCard(Icons.people, 'Patients', patientsCount.toString())),
          SizedBox(width: 12.w),
          Expanded(child: _buildMetricCard(Icons.videocam, 'Video Calls', videoCallsCount.toString())),
        ],
      ),
    );
  }

  Widget _buildMetricCard(IconData icon, String label, String count) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24.sp, color: AppColors.primaryBlue),
          SizedBox(height: 8.h),
          Text(count, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black)),
          SizedBox(height: 4.h),
          Text(label, style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(child: _buildQuickAction(Icons.message, 'Message', () => Navigator.pushNamed(context, '/doctor/messages'))),
          SizedBox(width: 12.w),
          Expanded(child: _buildQuickAction(Icons.video_call, 'Video call', () => Navigator.pushNamed(context, '/doctor/video-patients'))),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8.r), border: Border.all(color: Colors.grey[300]!)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20.sp, color: Colors.grey[700]),
            SizedBox(width: 8.w),
            Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.black, fontWeight: FontWeight.w500)),
            SizedBox(width: 4.w),
            Icon(Icons.arrow_forward_ios, size: 12.sp, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryBlue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primaryBlue,
        labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        tabs: const [Tab(text: 'Requests'), Tab(text: 'All Patients'), Tab(text: 'Booked')],
      ),
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState('No appointment requests yet');
        final appointments = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text('Patient requests  ${appointments.length}', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: appointments.length,
                itemBuilder: (c, i) => _buildRequestCard(appointments[i].data() as Map<String, dynamic>, appointments[i].id),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data, String appointmentId) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 24.r, backgroundColor: Colors.grey[200], child: Icon(Icons.person, size: 24.sp, color: Colors.grey[600])),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['patientName'] ?? 'Unknown Patient', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.black)),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14.sp, color: Colors.grey[600]),
                    SizedBox(width: 4.w),
                    Text(data['appointmentTime'] ?? 'N/A', style: TextStyle(fontSize: 14.sp, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            children: [
              SizedBox(
                width: 90.w,
                child: ElevatedButton(
                  onPressed: () => _confirmAppointment(appointmentId, data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: Text('Confirm', style: TextStyle(fontSize: 13.sp, color: Colors.white)),
                ),
              ),
              SizedBox(height: 6.h),
              SizedBox(
                width: 90.w,
                child: OutlinedButton(
                  onPressed: () => _deleteAppointment(appointmentId, data),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: Text('Delete', style: TextStyle(fontSize: 13.sp, color: Colors.grey[700])),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllPatientsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').where('doctorId', isEqualTo: user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState('No patients yet');
        final patientsMap = <String, Map<String, dynamic>>{};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (!patientsMap.containsKey(data['patientId'])) patientsMap[data['patientId']] = data;
        }
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: patientsMap.length,
          itemBuilder: (c, i) => _buildPatientCard(patientsMap.values.toList()[i]),
        );
      },
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> data) {
    final type = data['appointmentType'] ?? 'video';
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.primaryBlue, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 28.r, backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  child: Icon(Icons.person, size: 28.sp, color: AppColors.primaryBlue)),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['patientName'] ?? 'Unknown', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 4.h),
                    Row(children: [Icon(Icons.location_on, size: 14.sp, color: Colors.grey[600]), SizedBox(width: 4.w),
                      Text(data['location'] ?? 'Unknown', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]))]),
                    SizedBox(height: 2.h),
                    Row(children: [Icon(Icons.phone, size: 14.sp, color: Colors.grey[600]), SizedBox(width: 4.w),
                      Text(data['patientPhone'] ?? 'N/A', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]))]),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: type == 'video' ? AppColors.primaryBlue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  children: [
                    Icon(type == 'video' ? Icons.videocam : Icons.phone, size: 14.sp, color: type == 'video' ? AppColors.primaryBlue : Colors.orange),
                    SizedBox(width: 4.w),
                    Text(type == 'video' ? 'Video' : 'Audio',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: type == 'video' ? AppColors.primaryBlue : Colors.orange)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          OutlinedButton.icon(
            onPressed: () => _startChat(data['patientId']),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primaryBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              minimumSize: Size(double.infinity, 40.h),
            ),
            icon: Icon(Icons.chat_bubble_outline, size: 18.sp, color: AppColors.primaryBlue),
            label: Text('Message Patient', style: TextStyle(color: AppColors.primaryBlue, fontSize: 14.sp, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookedTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState('No confirmed appointments');
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (c, i) => _buildBookedAppointmentCard(snapshot.data!.docs[i].data() as Map<String, dynamic>, snapshot.data!.docs[i].id),
        );
      },
    );
  }

  Widget _buildBookedAppointmentCard(Map<String, dynamic> data, String appointmentId) {
    final date = (data['appointmentDate'] as Timestamp?)?.toDate();
    final type = data['appointmentType'] ?? 'video';
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.green.withOpacity(0.3), width: 1.5)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 55.w,
                child: Column(
                  children: [
                    Text(date != null ? date.day.toString() : '12', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                    Text(date != null ? DateFormat('MMM').format(date) : 'Mar', style: TextStyle(fontSize: 14.sp, color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(type == 'video' ? Icons.videocam : Icons.phone, size: 16.sp, color: type == 'video' ? AppColors.primaryBlue : Colors.orange),
                        SizedBox(width: 6.w),
                        Text(type == 'video' ? 'Video Appointment' : 'Audio Call', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black)),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(data['patientName'] ?? 'Unknown', style: TextStyle(fontSize: 15.sp, color: Colors.black, fontWeight: FontWeight.w500)),
                    SizedBox(height: 2.h),
                    Row(children: [Icon(Icons.location_on, size: 12.sp, color: Colors.grey[600]), SizedBox(width: 4.w),
                      Text(data['location'] ?? 'Unknown', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]))]),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
                child: Text(data['appointmentTime'] ?? '10:00 AM', style: TextStyle(fontSize: 13.sp, color: Colors.green[700], fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _startVideoCall(appointmentId, data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  icon: Icon(Icons.videocam, size: 18.sp),
                  label: Text('Join Call', style: TextStyle(fontSize: 14.sp)),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _startChat(data['patientId']),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    side: BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  icon: Icon(Icons.chat, size: 18.sp, color: AppColors.primaryBlue),
                  label: Text('Chat', style: TextStyle(fontSize: 14.sp, color: AppColors.primaryBlue)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64.sp, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text(message, style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _confirmAppointment(String appointmentId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': data['patientId'],
        'title': 'Appointment Confirmed! 🎉',
        'body': 'Your appointment has been confirmed for ${data['appointmentTime']}',
        'type': 'appointment_confirmed',
        'appointmentId': appointmentId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment confirmed for ${data['patientName']}'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to confirm appointment'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteAppointment(String appointmentId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': data['patientId'],
        'title': 'Appointment Cancelled',
        'body': 'Your appointment request has been declined',
        'type': 'appointment_cancelled',
        'appointmentId': appointmentId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment deleted'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete appointment'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startVideoCall(String appointmentId, Map<String, dynamic> data) {
    Navigator.pushNamed(context, '/doctor/video-patients');
  }

  void _startChat(String patientId) {
    Navigator.pushNamed(context, '/doctor/messages');
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.people, 'Community', 1),
          _buildNavItem(Icons.medical_services, 'Patients', 2),
          _buildNavItem(Icons.message, 'Message', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24.sp, color: isSelected ? AppColors.primaryBlue : Colors.grey),
          SizedBox(height: 4.h),
          Text(label, style: TextStyle(fontSize: 12.sp, color: isSelected ? AppColors.primaryBlue : Colors.grey)),
        ],
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
//
// class DoctorHomeScreen extends StatefulWidget {
//   const DoctorHomeScreen({super.key});
//
//   @override
//   State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
// }
//
// class _DoctorHomeScreenState extends State<DoctorHomeScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final user = FirebaseAuth.instance.currentUser;
//
//   int appointmentsCount = 0;
//   int patientsCount = 0;
//   int videoCallsCount = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _loadMetrics();
//   }
//
//   Future<void> _loadMetrics() async {
//     if (user == null) return;
//     final appointmentsSnapshot = await FirebaseFirestore.instance
//         .collection('appointments')
//         .where('doctorId', isEqualTo: user!.uid)
//         .get();
//     final uniquePatients = <String>{};
//     int videoCallCount = 0;
//     for (var doc in appointmentsSnapshot.docs) {
//       final data = doc.data();
//       uniquePatients.add(data['patientId']);
//       if (data['appointmentType'] == 'video') videoCallCount++;
//     }
//     setState(() {
//       appointmentsCount = appointmentsSnapshot.docs.length;
//       patientsCount = uniquePatients.length;
//       videoCallsCount = videoCallCount;
//     });
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildHeader(),
//             _buildActionCards(),
//             SizedBox(height: 2.h),
//             _buildMetricsCards(),
//             SizedBox(height: 2.h),
//             _buildQuickActions(),
//             SizedBox(height: 8.h),
//             _buildTabBar(),
//             Expanded(
//               child: TabBarView(
//                 controller: _tabController,
//                 children: [_buildRequestsTab(), _buildAllPatientsTab(), _buildBookedTab()],
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: _buildBottomNav(),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Container(
//       color: Colors.white,
//       padding: EdgeInsets.all(16.w),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 20.r,
//             backgroundColor: AppColors.primaryBlue,
//             child: Icon(Icons.person, color: Colors.white, size: 20.sp),
//           ),
//           const Spacer(),
//           IconButton(icon: Icon(Icons.settings, size: 24.sp, color: Colors.black), onPressed: () {}),
//           _buildNotificationButton(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNotificationButton() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('notifications')
//           .where('userId', isEqualTo: user?.uid)
//           .where('read', isEqualTo: false)
//           .snapshots(),
//       builder: (context, snapshot) {
//         final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
//         return Stack(
//           children: [
//             IconButton(
//               icon: Icon(Icons.notifications, size: 24.sp, color: Colors.black),
//               onPressed: () => Navigator.pushNamed(context, '/notifications'),
//             ),
//             if (count > 0)
//               Positioned(
//                 right: 8, top: 8,
//                 child: Container(
//                   padding: EdgeInsets.all(4.w),
//                   decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
//                   constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.h),
//                   child: Text(
//                     count > 9 ? '9+' : count.toString(),
//                     style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildActionCards() {
//     return Container(
//       color: Colors.white,
//       padding: EdgeInsets.all(16.w),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(child: _buildActionCard('Connect with a\nPatient', Icons.video_call, AppColors.primaryBlue,
//                       () => Navigator.pushNamed(context, '/doctor/video-patients'))),
//               SizedBox(width: 12.w),
//               Expanded(child: _buildActionCard('View Appointments', Icons.calendar_today, const Color(0xFF87CEEB),
//                       () => _tabController.animateTo(2))),
//             ],
//           ),
//           SizedBox(height: 12.h),
//           GestureDetector(
//             onTap: () {},
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
//               decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(12.r)),
//               child: Row(
//                 children: [
//                   Icon(Icons.add_circle, color: Colors.white, size: 24.sp),
//                   SizedBox(width: 12.w),
//                   Text('Create Educational Resources', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.all(16.w),
//         decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12.r)),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3)),
//             SizedBox(height: 8.h),
//             Icon(icon, color: Colors.white, size: 24.sp),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMetricsCards() {
//     return Container(
//       color: Colors.white,
//       padding: EdgeInsets.all(16.w),
//       child: Row(
//         children: [
//           Expanded(child: _buildMetricCard(Icons.calendar_today, 'Appointments', appointmentsCount.toString())),
//           SizedBox(width: 12.w),
//           Expanded(child: _buildMetricCard(Icons.people, 'Patients', patientsCount.toString())),
//           SizedBox(width: 12.w),
//           Expanded(child: _buildMetricCard(Icons.videocam, 'Video Calls', videoCallsCount.toString())),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMetricCard(IconData icon, String label, String count) {
//     return Container(
//       padding: EdgeInsets.all(12.w),
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(12.r),
//         border: Border.all(color: Colors.grey[200]!),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, size: 24.sp, color: AppColors.primaryBlue),
//           SizedBox(height: 8.h),
//           Text(count, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black)),
//           SizedBox(height: 4.h),
//           Text(label, style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]), textAlign: TextAlign.center),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildQuickActions() {
//     return Container(
//       color: Colors.white,
//       padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
//       child: Row(
//         children: [
//           Expanded(child: _buildQuickAction(Icons.message, 'Message', () => Navigator.pushNamed(context, '/doctor/messages'))),
//           SizedBox(width: 12.w),
//           Expanded(child: _buildQuickAction(Icons.video_call, 'Video call', () => Navigator.pushNamed(context, '/doctor/video-patients'))),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: 12.h),
//         decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8.r), border: Border.all(color: Colors.grey[300]!)),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 20.sp, color: Colors.grey[700]),
//             SizedBox(width: 8.w),
//             Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.black, fontWeight: FontWeight.w500)),
//             SizedBox(width: 4.w),
//             Icon(Icons.arrow_forward_ios, size: 12.sp, color: Colors.grey),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTabBar() {
//     return Container(
//       color: Colors.white,
//       child: TabBar(
//         controller: _tabController,
//         labelColor: AppColors.primaryBlue,
//         unselectedLabelColor: Colors.grey,
//         indicatorColor: AppColors.primaryBlue,
//         labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
//         tabs: const [Tab(text: 'Requests'), Tab(text: 'All Patients'), Tab(text: 'Booked')],
//       ),
//     );
//   }
//
//   Widget _buildRequestsTab() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('appointments')
//           .where('doctorId', isEqualTo: user?.uid)
//          // .where('status', isEqualTo: 'pending')
//          // .orderBy('createdAt', descending: true)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState('No appointment requests yet');
//         final appointments = snapshot.data!.docs;
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: EdgeInsets.all(16.w),
//               child: Text('Patient requests  ${appointments.length}', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 padding: EdgeInsets.symmetric(horizontal: 16.w),
//                 itemCount: appointments.length,
//                 itemBuilder: (c, i) => _buildRequestCard(appointments[i].data() as Map<String, dynamic>, appointments[i].id),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildRequestCard(Map<String, dynamic> data, String appointmentId) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 12.h),
//       padding: EdgeInsets.all(16.w),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12.r),
//         border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 1.5),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(radius: 24.r, backgroundColor: Colors.grey[200], child: Icon(Icons.person, size: 24.sp, color: Colors.grey[600])),
//           SizedBox(width: 12.w),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(data['patientName'] ?? 'Unknown Patient', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.black)),
//                 SizedBox(height: 4.h),
//                 Row(
//                   children: [
//                     Icon(Icons.access_time, size: 14.sp, color: Colors.grey[600]),
//                     SizedBox(width: 4.w),
//                     Text(data['appointmentTime'] ?? 'N/A', style: TextStyle(fontSize: 14.sp, color: Colors.grey[600])),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(width: 8.w),
//           Column(
//             children: [
//               SizedBox(
//                 width: 90.w,
//                 child: ElevatedButton(
//                   onPressed: () => _confirmAppointment(appointmentId, data),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primaryBlue,
//                     padding: EdgeInsets.symmetric(vertical: 8.h),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
//                   ),
//                   child: Text('Confirm', style: TextStyle(fontSize: 13.sp, color: Colors.white)),
//                 ),
//               ),
//               SizedBox(height: 6.h),
//               SizedBox(
//                 width: 90.w,
//                 child: OutlinedButton(
//                   onPressed: () => _deleteAppointment(appointmentId, data),
//                   style: OutlinedButton.styleFrom(
//                     padding: EdgeInsets.symmetric(vertical: 8.h),
//                     side: BorderSide(color: Colors.grey[400]!),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
//                   ),
//                   child: Text('Delete', style: TextStyle(fontSize: 13.sp, color: Colors.grey[700])),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAllPatientsTab() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance.collection('appointments').where('doctorId', isEqualTo: user?.uid).snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState('No patients yet');
//         final patientsMap = <String, Map<String, dynamic>>{};
//         for (var doc in snapshot.data!.docs) {
//           final data = doc.data() as Map<String, dynamic>;
//           if (!patientsMap.containsKey(data['patientId'])) patientsMap[data['patientId']] = data;
//         }
//         return ListView.builder(
//           padding: EdgeInsets.all(16.w),
//           itemCount: patientsMap.length,
//           itemBuilder: (c, i) => _buildPatientCard(patientsMap.values.toList()[i]),
//         );
//       },
//     );
//   }
//
//   Widget _buildPatientCard(Map<String, dynamic> data) {
//     final type = data['appointmentType'] ?? 'video';
//     return Container(
//       margin: EdgeInsets.only(bottom: 12.h),
//       padding: EdgeInsets.all(16.w),
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.primaryBlue, width: 2)),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               CircleAvatar(radius: 28.r, backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
//                   child: Icon(Icons.person, size: 28.sp, color: AppColors.primaryBlue)),
//               SizedBox(width: 12.w),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(data['patientName'] ?? 'Unknown', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black)),
//                     SizedBox(height: 4.h),
//                     Row(children: [Icon(Icons.location_on, size: 14.sp, color: Colors.grey[600]), SizedBox(width: 4.w),
//                       Text(data['location'] ?? 'Unknown', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]))]),
//                     SizedBox(height: 2.h),
//                     Row(children: [Icon(Icons.phone, size: 14.sp, color: Colors.grey[600]), SizedBox(width: 4.w),
//                       Text(data['patientPhone'] ?? 'N/A', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]))]),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
//                 decoration: BoxDecoration(
//                   color: type == 'video' ? AppColors.primaryBlue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(6.r),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(type == 'video' ? Icons.videocam : Icons.phone, size: 14.sp, color: type == 'video' ? AppColors.primaryBlue : Colors.orange),
//                     SizedBox(width: 4.w),
//                     Text(type == 'video' ? 'Video' : 'Audio',
//                         style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: type == 'video' ? AppColors.primaryBlue : Colors.orange)),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 12.h),
//           OutlinedButton.icon(
//             onPressed: () => _startChat(data['patientId']),
//             style: OutlinedButton.styleFrom(
//               side: BorderSide(color: AppColors.primaryBlue),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
//               minimumSize: Size(double.infinity, 40.h),
//             ),
//             icon: Icon(Icons.chat_bubble_outline, size: 18.sp, color: AppColors.primaryBlue),
//             label: Text('Message Patient', style: TextStyle(color: AppColors.primaryBlue, fontSize: 14.sp, fontWeight: FontWeight.w600)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBookedTab() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('appointments')
//           .where('doctorId', isEqualTo: user?.uid)
//           //.where('status', isEqualTo: 'confirmed')
//           //.orderBy('appointmentDate')
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState('No confirmed appointments');
//         return ListView.builder(
//           padding: EdgeInsets.all(16.w),
//           itemCount: snapshot.data!.docs.length,
//           itemBuilder: (c, i) => _buildBookedAppointmentCard(snapshot.data!.docs[i].data() as Map<String, dynamic>, snapshot.data!.docs[i].id),
//         );
//       },
//     );
//   }
//
//   Widget _buildBookedAppointmentCard(Map<String, dynamic> data, String appointmentId) {
//     final date = (data['appointmentDate'] as Timestamp?)?.toDate();
//     final type = data['appointmentType'] ?? 'video';
//     return Container(
//       margin: EdgeInsets.only(bottom: 12.h),
//       padding: EdgeInsets.all(16.w),
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.green.withOpacity(0.3), width: 1.5)),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 55.w,
//                 child: Column(
//                   children: [
//                     Text(date != null ? date.day.toString() : '12', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
//                     Text(date != null ? DateFormat('MMM').format(date) : 'Mar', style: TextStyle(fontSize: 14.sp, color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
//                   ],
//                 ),
//               ),
//               SizedBox(width: 16.w),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(type == 'video' ? Icons.videocam : Icons.phone, size: 16.sp, color: type == 'video' ? AppColors.primaryBlue : Colors.orange),
//                         SizedBox(width: 6.w),
//                         Text(type == 'video' ? 'Video Appointment' : 'Audio Call', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black)),
//                       ],
//                     ),
//                     SizedBox(height: 4.h),
//                     Text(data['patientName'] ?? 'Unknown', style: TextStyle(fontSize: 15.sp, color: Colors.black, fontWeight: FontWeight.w500)),
//                     SizedBox(height: 2.h),
//                     Row(children: [Icon(Icons.location_on, size: 12.sp, color: Colors.grey[600]), SizedBox(width: 4.w),
//                       Text(data['location'] ?? 'Unknown', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]))]),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
//                 decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
//                 child: Text(data['appointmentTime'] ?? '10:00 AM', style: TextStyle(fontSize: 13.sp, color: Colors.green[700], fontWeight: FontWeight.w600)),
//               ),
//             ],
//           ),
//           SizedBox(height: 12.h),
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () => _startVideoCall(appointmentId, data),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primaryBlue,
//                     padding: EdgeInsets.symmetric(vertical: 10.h),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
//                   ),
//                   icon: Icon(Icons.videocam, size: 18.sp),
//                   label: Text('Join Call', style: TextStyle(fontSize: 14.sp)),
//                 ),
//               ),
//               SizedBox(width: 8.w),
//               Expanded(
//                 child: OutlinedButton.icon(
//                   onPressed: () => _startChat(data['patientId']),
//                   style: OutlinedButton.styleFrom(
//                     padding: EdgeInsets.symmetric(vertical: 10.h),
//                     side: BorderSide(color: AppColors.primaryBlue),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
//                   ),
//                   icon: Icon(Icons.chat, size: 18.sp, color: AppColors.primaryBlue),
//                   label: Text('Chat', style: TextStyle(fontSize: 14.sp, color: AppColors.primaryBlue)),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyState(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.inbox, size: 64.sp, color: Colors.grey[300]),
//           SizedBox(height: 16.h),
//           Text(message, style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _confirmAppointment(String appointmentId, Map<String, dynamic> data) async {
//     try {
//       await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
//         'status': 'confirmed',
//         'confirmedAt': FieldValue.serverTimestamp(),
//       });
//       await FirebaseFirestore.instance.collection('notifications').add({
//         'userId': data['patientId'],
//         'title': 'Appointment Confirmed! 🎉',
//         'body': 'Your appointment has been confirmed for ${data['appointmentTime']}',
//         'type': 'appointment_confirmed',
//         'appointmentId': appointmentId,
//         'createdAt': FieldValue.serverTimestamp(),
//         'read': false,
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Appointment confirmed for ${data['patientName']}'), backgroundColor: Colors.green),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to confirm appointment'), backgroundColor: Colors.red),
//       );
//     }
//   }
//
//   Future<void> _deleteAppointment(String appointmentId, Map<String, dynamic> data) async {
//     try {
//       await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
//         'status': 'cancelled',
//         'cancelledAt': FieldValue.serverTimestamp(),
//       });
//       await FirebaseFirestore.instance.collection('notifications').add({
//         'userId': data['patientId'],
//         'title': 'Appointment Cancelled',
//         'body': 'Your appointment request has been declined',
//         'type': 'appointment_cancelled',
//         'appointmentId': appointmentId,
//         'createdAt': FieldValue.serverTimestamp(),
//         'read': false,
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Appointment deleted'), backgroundColor: Colors.orange),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to delete appointment'), backgroundColor: Colors.red),
//       );
//     }
//   }
//
//   void _startVideoCall(String appointmentId, Map<String, dynamic> data) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Starting video call with ${data['patientName']}')),
//     );
//   }
//
//   void _startChat(String patientId) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Opening chat...')),
//     );
//   }
//
//   Widget _buildBottomNav() {
//     return Container(
//       height: 70.h,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _buildNavItem(Icons.home, 'Home', true),
//           _buildNavItem(Icons.people, 'Community', false),
//           _buildNavItem(Icons.medical_services, 'Patients', false),
//           _buildNavItem(Icons.message, 'Message', false),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNavItem(IconData icon, String label, bool isSelected) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(icon, size: 24.sp, color: isSelected ? AppColors.primaryBlue : Colors.grey),
//         SizedBox(height: 4.h),
//         Text(label, style: TextStyle(fontSize: 12.sp, color: isSelected ? AppColors.primaryBlue : Colors.grey)),
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
// //
// //
// // import 'package:flutter/material.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:sheydoc_app/core/constants/app_colors.dart';
// // import 'package:intl/intl.dart';
// //
// // class DoctorHomeScreen extends StatefulWidget {
// //   const DoctorHomeScreen({super.key});
// //
// //   @override
// //   State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
// // }
// //
// // class _DoctorHomeScreenState extends State<DoctorHomeScreen> with SingleTickerProviderStateMixin {
// //   late TabController _tabController;
// //   final user = FirebaseAuth.instance.currentUser;
// //
// //   int appointmentsCount = 0;
// //   int patientsCount = 0;
// //   int videoCallsCount = 0;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _tabController = TabController(length: 3, vsync: this);
// //     _loadMetrics();
// //   }
// //
// //   Future<void> _loadMetrics() async {
// //     if (user == null) return;
// //
// //     // Count total appointments
// //     final appointmentsSnapshot = await FirebaseFirestore.instance
// //         .collection('appointments')
// //         .where('doctorId', isEqualTo: user!.uid)
// //         .get();
// //
// //     // Count unique patients
// //     final uniquePatients = <String>{};
// //     int videoCallCount = 0;
// //
// //     for (var doc in appointmentsSnapshot.docs) {
// //       final data = doc.data();
// //       uniquePatients.add(data['patientId']);
// //       if (data['appointmentType'] == 'video') {
// //         videoCallCount++;
// //       }
// //     }
// //
// //     setState(() {
// //       appointmentsCount = appointmentsSnapshot.docs.length;
// //       patientsCount = uniquePatients.length;
// //       videoCallsCount = videoCallCount;
// //     });
// //   }
// //
// //   @override
// //   void dispose() {
// //     _tabController.dispose();
// //     super.dispose();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.grey[50],
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             // Header
// //             Container(
// //               color: Colors.white,
// //               padding: EdgeInsets.all(16.w),
// //               child: Row(
// //                 children: [
// //                   CircleAvatar(
// //                     radius: 20.r,
// //                     backgroundColor: AppColors.primaryBlue,
// //                     child: Icon(Icons.person, color: Colors.white, size: 20.sp),
// //                   ),
// //                   const Spacer(),
// //                   IconButton(
// //                     icon: Icon(Icons.settings, size: 24.sp, color: Colors.black),
// //                     onPressed: () {},
// //                   ),
// //                   IconButton(
// //                     icon: Icon(Icons.notifications, size: 24.sp, color: Colors.black),
// //                     onPressed: () {
// //                       // Navigate to notifications
// //                     },
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             // Action Cards
// //             Container(
// //               color: Colors.white,
// //               padding: EdgeInsets.all(16.w),
// //               child: Column(
// //                 children: [
// //                   Row(
// //                     children: [
// //                       Expanded(
// //                         child: _buildActionCard(
// //                           'Connect with a\nPatient',
// //                           Icons.video_call,
// //                           AppColors.primaryBlue,
// //                               () {
// //                             // Navigate to connect with patient
// //                           },
// //                         ),
// //                       ),
// //                       SizedBox(width: 12.w),
// //                       Expanded(
// //                         child: _buildActionCard(
// //                           'View Appointments',
// //                           Icons.calendar_today,
// //                           const Color(0xFF87CEEB),
// //                               () {
// //                             _tabController.animateTo(2); // Go to Booked tab
// //                           },
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   SizedBox(height: 12.h),
// //                   Container(
// //                     width: double.infinity,
// //                     padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
// //                     decoration: BoxDecoration(
// //                       color: AppColors.primaryBlue,
// //                       borderRadius: BorderRadius.circular(12.r),
// //                     ),
// //                     child: Row(
// //                       children: [
// //                         Icon(Icons.add_circle, color: Colors.white, size: 24.sp),
// //                         SizedBox(width: 12.w),
// //                         Text(
// //                           'Create Educational Resources',
// //                           style: TextStyle(
// //                             fontSize: 16.sp,
// //                             fontWeight: FontWeight.w600,
// //                             color: Colors.white,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             SizedBox(height: 2.h),
// //
// //             // Metrics Cards
// //             Container(
// //               color: Colors.white,
// //               padding: EdgeInsets.all(16.w),
// //               child: Row(
// //                 children: [
// //                   Expanded(
// //                     child: _buildMetricCard(
// //                       Icons.calendar_today,
// //                       'Appointments',
// //                       appointmentsCount.toString(),
// //                     ),
// //                   ),
// //                   SizedBox(width: 12.w),
// //                   Expanded(
// //                     child: _buildMetricCard(
// //                       Icons.people,
// //                       'Patients',
// //                       patientsCount.toString(),
// //                     ),
// //                   ),
// //                   SizedBox(width: 12.w),
// //                   Expanded(
// //                     child: _buildMetricCard(
// //                       Icons.videocam,
// //                       'Video Calls',
// //                       videoCallsCount.toString(),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             SizedBox(height: 2.h),
// //
// //             // Quick Actions
// //             Container(
// //               color: Colors.white,
// //               padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
// //               child: Row(
// //                 children: [
// //                   Expanded(
// //                     child: _buildQuickAction(Icons.message, 'Message', () {}),
// //                   ),
// //                   SizedBox(width: 12.w),
// //                   Expanded(
// //                     child: _buildQuickAction(Icons.video_call, 'Video call', () {}),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             SizedBox(height: 8.h),
// //
// //             // Tab Bar
// //             Container(
// //               color: Colors.white,
// //               child: TabBar(
// //                 controller: _tabController,
// //                 labelColor: AppColors.primaryBlue,
// //                 unselectedLabelColor: Colors.grey,
// //                 indicatorColor: AppColors.primaryBlue,
// //                 labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
// //                 tabs: const [
// //                   Tab(text: 'Requests'),
// //                   Tab(text: 'All Patients'),
// //                   Tab(text: 'Booked'),
// //                 ],
// //               ),
// //             ),
// //
// //             // Tab Views
// //             Expanded(
// //               child: TabBarView(
// //                 controller: _tabController,
// //                 children: [
// //                   _buildRequestsTab(),
// //                   _buildAllPatientsTab(),
// //                   _buildBookedTab(),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //       bottomNavigationBar: _buildBottomNav(),
// //     );
// //   }
// //
// //   Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         padding: EdgeInsets.all(16.w),
// //         decoration: BoxDecoration(
// //           color: color,
// //           borderRadius: BorderRadius.circular(12.r),
// //         ),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text(
// //               title,
// //               style: TextStyle(
// //                 fontSize: 14.sp,
// //                 fontWeight: FontWeight.w600,
// //                 color: Colors.white,
// //                 height: 1.3,
// //               ),
// //             ),
// //             SizedBox(height: 8.h),
// //             Icon(icon, color: Colors.white, size: 24.sp),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildMetricCard(IconData icon, String label, String count) {
// //     return Container(
// //       padding: EdgeInsets.all(12.w),
// //       decoration: BoxDecoration(
// //         color: Colors.grey[50],
// //         borderRadius: BorderRadius.circular(12.r),
// //         border: Border.all(color: Colors.grey[200]!),
// //       ),
// //       child: Column(
// //         children: [
// //           Icon(icon, size: 24.sp, color: AppColors.primaryBlue),
// //           SizedBox(height: 8.h),
// //           Text(
// //             count,
// //             style: TextStyle(
// //               fontSize: 20.sp,
// //               fontWeight: FontWeight.bold,
// //               color: Colors.black,
// //             ),
// //           ),
// //           SizedBox(height: 4.h),
// //           Text(
// //             label,
// //             style: TextStyle(
// //               fontSize: 11.sp,
// //               color: Colors.grey[600],
// //             ),
// //             textAlign: TextAlign.center,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         padding: EdgeInsets.symmetric(vertical: 12.h),
// //         decoration: BoxDecoration(
// //           color: Colors.grey[50],
// //           borderRadius: BorderRadius.circular(8.r),
// //           border: Border.all(color: Colors.grey[300]!),
// //         ),
// //         child: Row(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(icon, size: 20.sp, color: Colors.grey[700]),
// //             SizedBox(width: 8.w),
// //             Text(
// //               label,
// //               style: TextStyle(
// //                 fontSize: 14.sp,
// //                 color: Colors.black,
// //                 fontWeight: FontWeight.w500,
// //               ),
// //             ),
// //             SizedBox(width: 4.w),
// //             Icon(Icons.arrow_forward_ios, size: 12.sp, color: Colors.grey),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // REQUESTS TAB - Show all pending appointments
// //   Widget _buildRequestsTab() {
// //     return StreamBuilder<QuerySnapshot>(
// //       stream: FirebaseFirestore.instance
// //           .collection('appointments')
// //           .where('doctorId', isEqualTo: user?.uid)
// //           .orderBy('createdAt', descending: true)
// //           .snapshots(),
// //       builder: (context, snapshot) {
// //         if (snapshot.connectionState == ConnectionState.waiting) {
// //           return const Center(child: CircularProgressIndicator());
// //         }
// //
// //         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// //           return _buildEmptyState('No appointment requests yet');
// //         }
// //
// //         final appointments = snapshot.data!.docs;
// //
// //         return Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Padding(
// //               padding: EdgeInsets.all(16.w),
// //               child: Text(
// //                 'Patient requests  ${appointments.length}',
// //                 style: TextStyle(
// //                   fontSize: 18.sp,
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //             ),
// //             Expanded(
// //               child: ListView.builder(
// //                 padding: EdgeInsets.symmetric(horizontal: 16.w),
// //                 itemCount: appointments.length,
// //                 itemBuilder: (context, index) {
// //                   final data = appointments[index].data() as Map<String, dynamic>;
// //                   final appointmentId = appointments[index].id;
// //                   return _buildRequestCard(data, appointmentId);
// //                 },
// //               ),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildRequestCard(Map<String, dynamic> data, String appointmentId) {
// //     final patientName = data['patientName'] ?? 'Unknown Patient';
// //     final appointmentType = data['appointmentType'] ?? 'video';
// //     final date = (data['appointmentDate'] as Timestamp?)?.toDate();
// //     final time = data['appointmentTime'] ?? 'N/A';
// //
// //     return Container(
// //       margin: EdgeInsets.only(bottom: 12.h),
// //       padding: EdgeInsets.all(16.w),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12.r),
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
// //                 radius: 24.r,
// //                 backgroundColor: Colors.grey[200],
// //                 child: Icon(Icons.person, size: 24.sp, color: Colors.grey),
// //               ),
// //               SizedBox(width: 12.w),
// //               Expanded(
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text(
// //                       patientName,
// //                       style: TextStyle(
// //                         fontSize: 16.sp,
// //                         fontWeight: FontWeight.w600,
// //                       ),
// //                     ),
// //                     Text(
// //                       date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Date N/A',
// //                       style: TextStyle(fontSize: 12.sp, color: Colors.grey),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               Icon(Icons.more_vert, color: Colors.grey),
// //             ],
// //           ),
// //           SizedBox(height: 12.h),
// //           Row(
// //             children: [
// //               Icon(
// //                 appointmentType == 'video' ? Icons.videocam : Icons.phone,
// //                 size: 16.sp,
// //                 color: AppColors.primaryBlue,
// //               ),
// //               SizedBox(width: 8.w),
// //               Text(
// //                 appointmentType == 'video' ? 'Video Call' : 'Audio Call',
// //                 style: TextStyle(fontSize: 14.sp),
// //               ),
// //               SizedBox(width: 16.w),
// //               Icon(Icons.access_time, size: 16.sp, color: Colors.grey),
// //               SizedBox(width: 8.w),
// //               Text(
// //                 time,
// //                 style: TextStyle(fontSize: 14.sp),
// //               ),
// //             ],
// //           ),
// //           SizedBox(height: 12.h),
// //           Row(
// //             children: [
// //               Expanded(
// //                 child: ElevatedButton.icon(
// //                   onPressed: () => _startVideoCall(appointmentId, data),
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: AppColors.primaryBlue,
// //                     padding: EdgeInsets.symmetric(vertical: 10.h),
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(8.r),
// //                     ),
// //                   ),
// //                   icon: Icon(Icons.videocam, size: 18.sp),
// //                   label: Text('Join Call', style: TextStyle(fontSize: 14.sp)),
// //                 ),
// //               ),
// //               SizedBox(width: 8.w),
// //               Expanded(
// //                 child: OutlinedButton.icon(
// //                   onPressed: () => _startChat(data['patientId']),
// //                   style: OutlinedButton.styleFrom(
// //                     padding: EdgeInsets.symmetric(vertical: 10.h),
// //                     side: BorderSide(color: AppColors.primaryBlue),
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(8.r),
// //                     ),
// //                   ),
// //                   icon: Icon(Icons.chat, size: 18.sp, color: AppColors.primaryBlue),
// //                   label: Text(
// //                     'Chat',
// //                     style: TextStyle(fontSize: 14.sp, color: AppColors.primaryBlue),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ALL PATIENTS TAB - Show unique patients who ever booked
// //   Widget _buildAllPatientsTab() {
// //     return StreamBuilder<QuerySnapshot>(
// //       stream: FirebaseFirestore.instance
// //           .collection('appointments')
// //           .where('doctorId', isEqualTo: user?.uid)
// //           .snapshots(),
// //       builder: (context, snapshot) {
// //         if (snapshot.connectionState == ConnectionState.waiting) {
// //           return const Center(child: CircularProgressIndicator());
// //         }
// //
// //         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// //           return _buildEmptyState('No patients yet');
// //         }
// //
// //         // Get unique patients
// //         final patientsMap = <String, Map<String, dynamic>>{};
// //         for (var doc in snapshot.data!.docs) {
// //           final data = doc.data() as Map<String, dynamic>;
// //           final patientId = data['patientId'];
// //           if (!patientsMap.containsKey(patientId)) {
// //             patientsMap[patientId] = data;
// //           }
// //         }
// //
// //         final patients = patientsMap.values.toList();
// //
// //         return ListView.builder(
// //           padding: EdgeInsets.all(16.w),
// //           itemCount: patients.length,
// //           itemBuilder: (context, index) {
// //             final data = patients[index];
// //             return _buildPatientCard(data);
// //           },
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildPatientCard(Map<String, dynamic> data) {
// //     final patientName = data['patientName'] ?? 'Unknown';
// //     final location = data['location'] ?? 'Unknown';
// //
// //     return Container(
// //       margin: EdgeInsets.only(bottom: 12.h),
// //       padding: EdgeInsets.all(16.w),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12.r),
// //         border: Border.all(color: AppColors.primaryBlue, width: 2),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               CircleAvatar(
// //                 radius: 24.r,
// //                 backgroundColor: Colors.grey[200],
// //                 child: Icon(Icons.person, size: 24.sp, color: Colors.grey),
// //               ),
// //               SizedBox(width: 12.w),
// //               Expanded(
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text(
// //                       patientName,
// //                       style: TextStyle(
// //                         fontSize: 16.sp,
// //                         fontWeight: FontWeight.w600,
// //                       ),
// //                     ),
// //                     Row(
// //                       children: [
// //                         Icon(Icons.location_on, size: 14.sp, color: Colors.grey),
// //                         SizedBox(width: 4.w),
// //                         Text(
// //                           location,
// //                           style: TextStyle(fontSize: 12.sp, color: Colors.grey),
// //                         ),
// //                       ],
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           ),
// //           SizedBox(height: 12.h),
// //           Row(
// //             children: [
// //               Expanded(
// //                 child: OutlinedButton.icon(
// //                   onPressed: () => _startChat(data['patientId']),
// //                   style: OutlinedButton.styleFrom(
// //                     side: BorderSide(color: AppColors.primaryBlue),
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(8.r),
// //                     ),
// //                   ),
// //                   icon: Icon(Icons.chat, size: 18.sp, color: AppColors.primaryBlue),
// //                   label: Text('Message', style: TextStyle(color: AppColors.primaryBlue)),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // BOOKED TAB - Show upcoming appointments
// //   Widget _buildBookedTab() {
// //     return StreamBuilder<QuerySnapshot>(
// //       stream: FirebaseFirestore.instance
// //           .collection('appointments')
// //           .where('doctorId', isEqualTo: user?.uid)
// //           .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.now())
// //           .orderBy('appointmentDate')
// //           .snapshots(),
// //       builder: (context, snapshot) {
// //         if (snapshot.connectionState == ConnectionState.waiting) {
// //           return const Center(child: CircularProgressIndicator());
// //         }
// //
// //         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// //           return _buildEmptyState('No upcoming appointments');
// //         }
// //
// //         final appointments = snapshot.data!.docs;
// //
// //         return ListView.builder(
// //           padding: EdgeInsets.all(16.w),
// //           itemCount: appointments.length,
// //           itemBuilder: (context, index) {
// //             final data = appointments[index].data() as Map<String, dynamic>;
// //             return _buildBookedAppointmentCard(data);
// //           },
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildBookedAppointmentCard(Map<String, dynamic> data) {
// //     final patientName = data['patientName'] ?? 'Unknown';
// //     final location = data['location'] ?? 'Unknown';
// //     final date = (data['appointmentDate'] as Timestamp?)?.toDate();
// //     final time = data['appointmentTime'] ?? '10:00 AM';
// //
// //     return Container(
// //       margin: EdgeInsets.only(bottom: 12.h),
// //       padding: EdgeInsets.all(16.w),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12.r),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.grey.withOpacity(0.1),
// //             blurRadius: 4,
// //             offset: const Offset(0, 2),
// //           ),
// //         ],
// //       ),
// //       child: Row(
// //         children: [
// //           Container(
// //             width: 50.w,
// //             child: Column(
// //               children: [
// //                 Text(
// //                   date != null ? date.day.toString() : '12',
// //                   style: TextStyle(
// //                     fontSize: 28.sp,
// //                     fontWeight: FontWeight.bold,
// //                     color: Colors.grey[600],
// //                   ),
// //                 ),
// //                 Text(
// //                   date != null ? DateFormat('MMM').format(date) : 'Mar',
// //                   style: TextStyle(
// //                     fontSize: 14.sp,
// //                     color: Colors.grey[600],
// //                     fontWeight: FontWeight.w500,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           SizedBox(width: 16.w),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   'Check-up',
// //                   style: TextStyle(
// //                     fontSize: 16.sp,
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //                 Text(
// //                   patientName,
// //                   style: TextStyle(
// //                     fontSize: 14.sp,
// //                     color: Colors.grey[700],
// //                     fontWeight: FontWeight.w500,
// //                   ),
// //                 ),
// //                 Text(
// //                   location,
// //                   style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           Text(
// //             time,
// //             style: TextStyle(
// //               fontSize: 14.sp,
// //               color: Colors.grey[600],
// //               fontWeight: FontWeight.w500,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildEmptyState(String message) {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(Icons.inbox, size: 64.sp, color: Colors.grey[300]),
// //           SizedBox(height: 16.h),
// //           Text(
// //             message,
// //             style: TextStyle(fontSize: 16.sp, color: Colors.grey),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   void _startVideoCall(String appointmentId, Map<String, dynamic> data) {
// //     // Generate channel name for Agora
// //     final channelName = 'appointment_$appointmentId';
// //
// //     // TODO: Navigate to video call screen
// //     // Navigator.push(
// //     //   context,
// //     //   MaterialPageRoute(
// //     //     builder: (context) => VideoCallScreen(
// //     //       channelName: channelName,
// //     //       appointmentId: appointmentId,
// //     //       patientName: data['patientName'],
// //     //     ),
// //     //   ),
// //     // );
// //
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text('Starting video call with ${data['patientName']}')),
// //     );
// //   }
// //
// //   void _startChat(String patientId) {
// //     // TODO: Navigate to chat screen
// //     // Navigator.push(
// //     //   context,
// //     //   MaterialPageRoute(
// //     //     builder: (context) => ChatScreen(
// //     //       userId: patientId,
// //     //     ),
// //     //   ),
// //     // );
// //
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(content: Text('Opening chat...')),
// //     );
// //   }
// //
// //   Widget _buildBottomNav() {
// //     return Container(
// //       height: 70.h,
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.grey.withOpacity(0.1),
// //             blurRadius: 10,
// //             offset: const Offset(0, -2),
// //           ),
// //         ],
// //       ),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //         children: [
// //           _buildNavItem(Icons.home, 'Home', true),
// //           _buildNavItem(Icons.people, 'Community', false),
// //           _buildNavItem(Icons.medical_services, 'Patients', false),
// //           _buildNavItem(Icons.message, 'Message', false),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildNavItem(IconData icon, String label, bool isSelected) {
// //     return Column(
// //       mainAxisAlignment: MainAxisAlignment.center,
// //       children: [
// //         Icon(
// //           icon,
// //           size: 24.sp,
// //           color: isSelected ? AppColors.primaryBlue : Colors.grey,
// //         ),
// //         SizedBox(height: 4.h),
// //         Text(
// //           label,
// //           style: TextStyle(
// //             fontSize: 12.sp,
// //             color: isSelected ? AppColors.primaryBlue : Colors.grey,
// //           ),
// //         ),
// //       ],
// //     );
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
// //
// //
// //
// //
// //
// //
// //
// //
// // //
// // //
// // //
// // //
// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // // // import 'package:firebase_auth/firebase_auth.dart';
// // // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // // import 'package:sheydoc_app/core/constants/app_colors.dart';
// // // // import 'package:intl/intl.dart';
// // // //
// // // // class DoctorHomeScreen extends StatefulWidget {
// // // //   const DoctorHomeScreen({super.key});
// // // //
// // // //   @override
// // // //   State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
// // // // }
// // // //
// // // // class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
// // // //   String selectedTab = 'Requests';
// // //   final user = FirebaseAuth.instance.currentUser;
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: Colors.grey[50],
// // //       body: SafeArea(
// // //         child: Column(
// // //           children: [
// // //             // Header
// // //             Container(
// // //               padding: EdgeInsets.all(16.w),
// // //               color: Colors.white,
// // //               child: Row(
// // //                 children: [
// // //                   CircleAvatar(
// // //                     radius: 20.r,
// // //                     backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
// // //                     child: Icon(Icons.person, color: AppColors.primaryBlue, size: 24.sp),
// // //                   ),
// // //                   SizedBox(width: 60.w),
// // //                   IconButton(
// // //                     icon: Icon(Icons.settings, size: 24.sp, color: Colors.grey[700]),
// // //                     onPressed: () {},
// // //                   ),
// // //                   IconButton(
// // //                     icon: Icon(Icons.notifications, size: 24.sp, color: Colors.grey[700]),
// // //                     onPressed: () {},
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //
// // //             // Tab Selector
// // //             Container(
// // //               padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
// // //               color: Colors.white,
// // //               child: Row(
// // //                 children: [
// // //                   _buildTab('Requests', selectedTab == 'Requests'),
// // //                   SizedBox(width: 8.w),
// // //                   _buildTab('All Patients', selectedTab == 'All Patients'),
// // //                   SizedBox(width: 8.w),
// // //                   _buildTab('Booked Patients', selectedTab == 'Booked Patients'),
// // //                 ],
// // //               ),
// // //             ),
// // //
// // //             // Content
// // //             Expanded(
// // //               child: selectedTab == 'Requests'
// // //                   ? _buildRequestsView()
// // //                   : selectedTab == 'All Patients'
// // //                   ? _buildAllPatientsView()
// // //                   : _buildBookedPatientsView(),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //       bottomNavigationBar: _buildBottomNav(),
// // //     );
// // //   }
// // //
// // //   Widget _buildTab(String title, bool isSelected) {
// // //     return GestureDetector(
// // //       onTap: () => setState(() => selectedTab = title),
// // //       child: Container(
// // //         padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
// // //         decoration: BoxDecoration(
// // //           color: isSelected ? AppColors.primaryBlue : Colors.transparent,
// // //           borderRadius: BorderRadius.circular(20.r),
// // //           border: Border.all(
// // //             color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
// // //           ),
// // //         ),
// // //         child: Text(
// // //           title,
// // //           style: TextStyle(
// // //             fontSize: 13.sp,
// // //             fontWeight: FontWeight.w500,
// // //             color: isSelected ? Colors.white : Colors.black,
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildRequestsView() {
// // //     return StreamBuilder<QuerySnapshot>(
// // //       stream: FirebaseFirestore.instance
// // //           .collection('appointments')
// // //           .where('doctorId', isEqualTo: user?.uid)
// // //           .where('status', isEqualTo: 'pending')
// // //           .orderBy('createdAt', descending: true)
// // //           .snapshots(),
// // //       builder: (context, snapshot) {
// // //         if (snapshot.connectionState == ConnectionState.waiting) {
// // //           return const Center(child: CircularProgressIndicator());
// // //         }
// // //
// // //         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// // //           return Center(
// // //             child: Text(
// // //               'No pending requests',
// // //               style: TextStyle(fontSize: 16.sp, color: Colors.grey),
// // //             ),
// // //           );
// // //         }
// // //
// // //         final requests = snapshot.data!.docs;
// // //
// // //         return Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             Padding(
// // //               padding: EdgeInsets.all(16.w),
// // //               child: Text(
// // //                 'Patient requests  ${requests.length}',
// // //                 style: TextStyle(
// // //                   fontSize: 18.sp,
// // //                   fontWeight: FontWeight.bold,
// // //                   color: Colors.black,
// // //                 ),
// // //               ),
// // //             ),
// // //             Expanded(
// // //               child: ListView.builder(
// // //                 padding: EdgeInsets.symmetric(horizontal: 16.w),
// // //                 itemCount: requests.length,
// // //                 itemBuilder: (context, index) {
// // //                   final data = requests[index].data() as Map<String, dynamic>;
// // //                   final appointmentId = requests[index].id;
// // //                   return _buildRequestCard(data, appointmentId);
// // //                 },
// // //               ),
// // //             ),
// // //           ],
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   Widget _buildRequestCard(Map<String, dynamic> data, String appointmentId) {
// // //     return FutureBuilder<DocumentSnapshot>(
// // //       future: FirebaseFirestore.instance
// // //           .collection('users')
// // //           .doc(data['patientId'])
// // //           .get(),
// // //       builder: (context, snapshot) {
// // //         String patientName = 'Patient';
// // //         if (snapshot.hasData && snapshot.data!.exists) {
// // //           final patientData = snapshot.data!.data() as Map<String, dynamic>;
// // //           patientName = patientData['name'] ?? patientData['email'] ?? 'Patient';
// // //         }
// // //
// // //         return Container(
// // //           margin: EdgeInsets.only(bottom: 12.h),
// // //           padding: EdgeInsets.all(16.w),
// // //           decoration: BoxDecoration(
// // //             color: Colors.white,
// // //             borderRadius: BorderRadius.circular(12.r),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: Colors.grey.withOpacity(0.1),
// // //                 blurRadius: 8,
// // //                 offset: const Offset(0, 2),
// // //               ),
// // //             ],
// // //           ),
// // //           child: Row(
// // //             children: [
// // //               CircleAvatar(
// // //                 radius: 24.r,
// // //                 backgroundColor: Colors.grey[200],
// // //                 child: Icon(Icons.person, size: 24.sp, color: Colors.grey),
// // //               ),
// // //               SizedBox(width: 12.w),
// // //               Expanded(
// // //                 child: Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   children: [
// // //                     Text(
// // //                       patientName,
// // //                       style: TextStyle(
// // //                         fontSize: 16.sp,
// // //                         fontWeight: FontWeight.w600,
// // //                         color: Colors.black,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //               SizedBox(width: 8.w),
// // //               ElevatedButton(
// // //                 onPressed: () => _confirmAppointment(appointmentId),
// // //                 style: ElevatedButton.styleFrom(
// // //                   backgroundColor: AppColors.primaryBlue,
// // //                   shape: RoundedRectangleBorder(
// // //                     borderRadius: BorderRadius.circular(8.r),
// // //                   ),
// // //                   padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
// // //                 ),
// // //                 child: Text(
// // //                   'Confirm',
// // //                   style: TextStyle(fontSize: 14.sp, color: Colors.white),
// // //                 ),
// // //               ),
// // //               SizedBox(width: 8.w),
// // //               OutlinedButton(
// // //                 onPressed: () => _deleteAppointment(appointmentId),
// // //                 style: OutlinedButton.styleFrom(
// // //                   side: BorderSide(color: Colors.grey[300]!),
// // //                   shape: RoundedRectangleBorder(
// // //                     borderRadius: BorderRadius.circular(8.r),
// // //                   ),
// // //                   padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
// // //                 ),
// // //                 child: Text(
// // //                   'Delete',
// // //                   style: TextStyle(fontSize: 14.sp, color: Colors.black),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   Widget _buildAllPatientsView() {
// // //     return StreamBuilder<QuerySnapshot>(
// // //       stream: FirebaseFirestore.instance
// // //           .collection('appointments')
// // //           .where('doctorId', isEqualTo: user?.uid)
// // //           .where('status', isEqualTo: 'confirmed')
// // //           .snapshots(),
// // //       builder: (context, snapshot) {
// // //         if (snapshot.connectionState == ConnectionState.waiting) {
// // //           return const Center(child: CircularProgressIndicator());
// // //         }
// // //
// // //         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// // //           return Center(
// // //             child: Text(
// // //               'No patients yet',
// // //               style: TextStyle(fontSize: 16.sp, color: Colors.grey),
// // //             ),
// // //           );
// // //         }
// // //
// // //         final appointments = snapshot.data!.docs;
// // //
// // //         return ListView.builder(
// // //           padding: EdgeInsets.all(16.w),
// // //           itemCount: appointments.length,
// // //           itemBuilder: (context, index) {
// // //             final data = appointments[index].data() as Map<String, dynamic>;
// // //             return _buildPatientCard(data);
// // //           },
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   Widget _buildPatientCard(Map<String, dynamic> data) {
// // //     return FutureBuilder<DocumentSnapshot>(
// // //       future: FirebaseFirestore.instance
// // //           .collection('users')
// // //           .doc(data['patientId'])
// // //           .get(),
// // //       builder: (context, snapshot) {
// // //         String patientName = 'Patient';
// // //         String location = 'Douala';
// // //
// // //         if (snapshot.hasData && snapshot.data!.exists) {
// // //           final patientData = snapshot.data!.data() as Map<String, dynamic>;
// // //           patientName = patientData['name'] ?? patientData['email'] ?? 'Patient';
// // //         }
// // //
// // //         final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
// // //         final appointmentType = data['appointmentType'] ?? 'Audio call';
// // //
// // //         return Container(
// // //           margin: EdgeInsets.only(bottom: 16.h),
// // //           padding: EdgeInsets.all(16.w),
// // //           decoration: BoxDecoration(
// // //             color: Colors.white,
// // //             borderRadius: BorderRadius.circular(12.r),
// // //             border: Border.all(color: AppColors.primaryBlue, width: 1.5),
// // //           ),
// // //           child: Column(
// // //             children: [
// // //               Row(
// // //                 children: [
// // //                   CircleAvatar(
// // //                     radius: 24.r,
// // //                     backgroundColor: Colors.grey[200],
// // //                     child: Icon(Icons.person, size: 24.sp, color: Colors.grey),
// // //                   ),
// // //                   SizedBox(width: 12.w),
// // //                   Expanded(
// // //                     child: Column(
// // //                       crossAxisAlignment: CrossAxisAlignment.start,
// // //                       children: [
// // //                         Text(
// // //                           patientName,
// // //                           style: TextStyle(
// // //                             fontSize: 16.sp,
// // //                             fontWeight: FontWeight.w600,
// // //                             color: Colors.black,
// // //                           ),
// // //                         ),
// // //                         SizedBox(height: 4.h),
// // //                         Row(
// // //                           children: [
// // //                             Icon(Icons.location_on, size: 14.sp, color: Colors.grey),
// // //                             SizedBox(width: 4.w),
// // //                             Text(
// // //                               location,
// // //                               style: TextStyle(fontSize: 13.sp, color: Colors.grey),
// // //                             ),
// // //                           ],
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //               SizedBox(height: 12.h),
// // //               Row(
// // //                 children: [
// // //                   Icon(
// // //                     appointmentType == 'Video call' ? Icons.videocam : Icons.phone,
// // //                     size: 18.sp,
// // //                     color: Colors.grey[600],
// // //                   ),
// // //                   SizedBox(width: 8.w),
// // //                   Text(
// // //                     appointmentType,
// // //                     style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ],
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   Widget _buildBookedPatientsView() {
// // //     return StreamBuilder<QuerySnapshot>(
// // //       stream: FirebaseFirestore.instance
// // //           .collection('appointments')
// // //           .where('doctorId', isEqualTo: user?.uid)
// // //           .where('status', isEqualTo: 'confirmed')
// // //           .snapshots(),
// // //       builder: (context, snapshot) {
// // //         if (snapshot.connectionState == ConnectionState.waiting) {
// // //           return const Center(child: CircularProgressIndicator());
// // //         }
// // //
// // //         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// // //           return Center(
// // //             child: Text(
// // //               'No booked appointments',
// // //               style: TextStyle(fontSize: 16.sp, color: Colors.grey),
// // //             ),
// // //           );
// // //         }
// // //
// // //         final appointments = snapshot.data!.docs;
// // //
// // //         return ListView.builder(
// // //           padding: EdgeInsets.all(16.w),
// // //           itemCount: appointments.length,
// // //           itemBuilder: (context, index) {
// // //             final data = appointments[index].data() as Map<String, dynamic>;
// // //             return _buildBookedPatientCard(data);
// // //           },
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   Widget _buildBookedPatientCard(Map<String, dynamic> data) {
// // //     return FutureBuilder<DocumentSnapshot>(
// // //       future: FirebaseFirestore.instance
// // //           .collection('users')
// // //           .doc(data['patientId'])
// // //           .get(),
// // //       builder: (context, snapshot) {
// // //         String patientName = 'Patient';
// // //
// // //         if (snapshot.hasData && snapshot.data!.exists) {
// // //           final patientData = snapshot.data!.data() as Map<String, dynamic>;
// // //           patientName = patientData['name'] ?? patientData['email'] ?? 'Patient';
// // //         }
// // //
// // //         final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
// // //         final appointmentType = data['appointmentType'] ?? 'Video Appointment';
// // //
// // //         return Container(
// // //           margin: EdgeInsets.only(bottom: 16.h),
// // //           padding: EdgeInsets.all(16.w),
// // //           decoration: BoxDecoration(
// // //             color: Colors.white,
// // //             borderRadius: BorderRadius.circular(12.r),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: Colors.grey.withOpacity(0.1),
// // //                 blurRadius: 8,
// // //                 offset: const Offset(0, 2),
// // //               ),
// // //             ],
// // //           ),
// // //           child: Row(
// // //             children: [
// // //               CircleAvatar(
// // //                 radius: 24.r,
// // //                 backgroundColor: Colors.grey[200],
// // //                 child: Icon(Icons.person, size: 24.sp, color: Colors.grey),
// // //               ),
// // //               SizedBox(width: 12.w),
// // //               Expanded(
// // //                 child: Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   children: [
// // //                     Text(
// // //                       patientName,
// // //                       style: TextStyle(
// // //                         fontSize: 16.sp,
// // //                         fontWeight: FontWeight.w600,
// // //                         color: Colors.black,
// // //                       ),
// // //                     ),
// // //                     SizedBox(height: 4.h),
// // //                     Row(
// // //                       children: [
// // //                         Icon(Icons.calendar_today, size: 12.sp, color: Colors.grey),
// // //                         SizedBox(width: 4.w),
// // //                         Text(
// // //                           DateFormat('dd MMMM yyyy').format(appointmentDate),
// // //                           style: TextStyle(fontSize: 12.sp, color: Colors.grey),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                     SizedBox(height: 2.h),
// // //                     Row(
// // //                       children: [
// // //                         Icon(Icons.access_time, size: 12.sp, color: Colors.grey),
// // //                         SizedBox(width: 4.w),
// // //                         Text(
// // //                           DateFormat('hh:mm a').format(appointmentDate),
// // //                           style: TextStyle(fontSize: 12.sp, color: Colors.grey),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                     SizedBox(height: 2.h),
// // //                     Row(
// // //                       children: [
// // //                         Icon(Icons.videocam, size: 12.sp, color: Colors.grey),
// // //                         SizedBox(width: 4.w),
// // //                         Text(
// // //                           appointmentType,
// // //                           style: TextStyle(fontSize: 12.sp, color: Colors.grey),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //               ElevatedButton(
// // //                 onPressed: () => _startCall(data),
// // //                 style: ElevatedButton.styleFrom(
// // //                   backgroundColor: AppColors.primaryBlue,
// // //                   shape: RoundedRectangleBorder(
// // //                     borderRadius: BorderRadius.circular(8.r),
// // //                   ),
// // //                   padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
// // //                 ),
// // //                 child: Text(
// // //                   'Call Patient',
// // //                   style: TextStyle(fontSize: 13.sp, color: Colors.white),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   Future<void> _confirmAppointment(String appointmentId) async {
// // //     try {
// // //       await FirebaseFirestore.instance
// // //           .collection('appointments')
// // //           .doc(appointmentId)
// // //           .update({
// // //         'status': 'confirmed',
// // //         'confirmedAt': FieldValue.serverTimestamp(),
// // //       });
// // //
// // //       if (mounted) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(content: Text('Appointment confirmed')),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       if (mounted) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(content: Text('Error: $e')),
// // //         );
// // //       }
// // //     }
// // //   }
// // //
// // //   Future<void> _deleteAppointment(String appointmentId) async {
// // //     try {
// // //       await FirebaseFirestore.instance
// // //           .collection('appointments')
// // //           .doc(appointmentId)
// // //           .delete();
// // //
// // //       if (mounted) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(content: Text('Appointment deleted')),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       if (mounted) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(content: Text('Error: $e')),
// // //         );
// // //       }
// // //     }
// // //   }
// // //
// // //   void _startCall(Map<String, dynamic> appointmentData) {
// // //     // TODO: Navigate to video call screen with Agora
// // //     // You'll implement this with your Agora integration
// // //     final callId = appointmentData['callId'] ?? 'default_call';
// // //
// // //     // Navigator.push(
// // //     //   context,
// // //     //   MaterialPageRoute(
// // //     //     builder: (context) => VideocallScreen(callID: callId),
// // //     //   ),
// // //     // );
// // //
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       const SnackBar(content: Text('Starting call... (Agora integration needed)')),
// // //     );
// // //   }
// // //
// // //   Widget _buildBottomNav() {
// // //     return Container(
// // //       height: 70.h,
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.grey.withOpacity(0.1),
// // //             blurRadius: 10,
// // //             offset: const Offset(0, -2),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Row(
// // //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // //         children: [
// // //           _buildNavItem(Icons.home, 'Home', false),
// // //           _buildNavItem(Icons.people, 'Community', false),
// // //           _buildNavItem(Icons.calendar_today, 'Patients', true),
// // //           _buildNavItem(Icons.message, 'Message', false),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildNavItem(IconData icon, String label, bool isSelected) {
// // //     return Column(
// // //       mainAxisAlignment: MainAxisAlignment.center,
// // //       children: [
// // //         Icon(
// // //           icon,
// // //           size: 24.sp,
// // //           color: isSelected ? AppColors.primaryBlue : Colors.grey,
// // //         ),
// // //         SizedBox(height: 4.h),
// // //         Text(
// // //           label,
// // //           style: TextStyle(
// // //             fontSize: 12.sp,
// // //             color: isSelected ? AppColors.primaryBlue : Colors.grey,
// // //             fontWeight: FontWeight.w500,
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // }
// // //
// // //
// // //
// // //
// // //
// // // // // features/doctor/home/home_screen.dart
// // // // import 'package:flutter/material.dart';
// // // // class DoctorHomeScreen extends StatelessWidget {
// // // //   const DoctorHomeScreen({super.key});
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: const Text('Doctor Dashboard'),
// // // //       ),
// // // //       body: Center(
// // // //         child: Text('Welcome Doctor!'),
// // // //       ),
// // // //     );
// // // //   }
// // // // }
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:sheydoc_app/features/onboarding/role_selection_screen.dart';
// // // // // import '../../auth/doctors/talk_to_doctor_screen.dart';
// // // // //
// // // // //
// // // // // class HomeScreen extends StatefulWidget {
// // // // //   final String? role;
// // // // //   const HomeScreen({super.key, this.role});
// // // // //
// // // // //   @override
// // // // //   State<HomeScreen> createState() => _HomeScreenState();
// // // // // }
// // // // //
// // // // // class _HomeScreenState extends State<HomeScreen> {
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Scaffold(
// // // // //       appBar: AppBar(
// // // // //           leading: GestureDetector(
// // // // //             child: Icon(Icons.back_hand),
// // // // //             onTap: () {
// // // // //               Navigator.push(
// // // // //                   context,
// // // // //                   MaterialPageRoute(builder: (context) => RoleSelectionScreen())
// // // // //               );
// // // // //             },
// // // // //           )
// // // // //       ),
// // // // //       body: SingleChildScrollView(
// // // // //         child: Padding(
// // // // //           padding: EdgeInsets.all(16.0),
// // // // //           child: Column(
// // // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // // //             children: [
// // // // //               Text(
// // // // //                 "Home Screen",
// // // // //                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
// // // // //               ),
// // // // //               SizedBox(height: 10),
// // // // //               Text("Role: ${widget.role ?? 'Unknown'}"),
// // // // //               SizedBox(height: 30),
// // // // //
// // // // //               // Test button for Talk to Doctor UI
// // // // //               Container(
// // // // //                 width: double.infinity,
// // // // //                 child: ElevatedButton(
// // // // //                   onPressed: () {
// // // // //                     Navigator.push(
// // // // //                         context,
// // // // //                         MaterialPageRoute(builder: (context) => TalkToDoctorScreen())
// // // // //                     );
// // // // //                   },
// // // // //                   style: ElevatedButton.styleFrom(
// // // // //                     padding: EdgeInsets.symmetric(vertical: 15),
// // // // //                   ),
// // // // //                   child: Text(
// // // // //                     "Test Talk to Doctor UI",
// // // // //                     style: TextStyle(fontSize: 16),
// // // // //                   ),
// // // // //                 ),
// // // // //               ),
// // // // //
// // // // //               SizedBox(height: 20),
// // // // //               Text(
// // // // //                 "Other features coming soon...",
// // // // //                 style: TextStyle(color: Colors.grey),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }
// // // // //
// // // // //
// // // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:sheydoc_app/features/onboarding/role_selection_screen.dart';
// // // // //
// // // // // class HomeScreen extends StatefulWidget {
// // // // //   const HomeScreen({super.key});
// // // // //
// // // // //   @override
// // // // //   State<HomeScreen> createState() => _HomeScreenState();
// // // // // }
// // // // //
// // // // // class _HomeScreenState extends State<HomeScreen> {
// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Scaffold(
// // // // //       appBar:AppBar(
// // // // //         leading: GestureDetector(child: Icon(Icons.back_hand, ), onTap: (){Navigator.push(context, MaterialPageRoute(builder: (context)=>RoleSelectionScreen()));},)
// // // // //
// // // // //
// // // // //       ),
// // // // //       body: SingleChildScrollView(
// // // // //         child: Column(children: [
// // // // //           Text("ddkd")
// // // // //         ],),
// // // // //
// // // // //
// // // // //       ),
// // // // //
// // // // //     );
// // // // //   }
// // // // // }
