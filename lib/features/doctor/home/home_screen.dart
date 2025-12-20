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

  // ✅ NEW: Logout function
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/role-selection',
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
          IconButton(
            icon: Icon(Icons.logout, size: 24.sp, color: Colors.red),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
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
//   int _selectedNavIndex = 0;
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
//   void _onNavItemTapped(int index) {
//     setState(() {
//       _selectedNavIndex = index;
//     });
//
//     switch (index) {
//       case 0: // Home - do nothing, already here
//         break;
//       case 1: // Community - TODO
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Community feature coming soon!')),
//         );
//         break;
//       case 2: // Patients - show all patients tab
//         _tabController.animateTo(1);
//         break;
//       case 3: // Messages
//         Navigator.pushNamed(context, '/doctor/messages');
//         break;
//     }
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
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Appointment confirmed for ${data['patientName']}'), backgroundColor: Colors.green),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to confirm appointment'), backgroundColor: Colors.red),
//         );
//       }
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
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Appointment deleted'), backgroundColor: Colors.orange),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to delete appointment'), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }
//
//   void _startVideoCall(String appointmentId, Map<String, dynamic> data) {
//     Navigator.pushNamed(context, '/doctor/video-patients');
//   }
//
//   void _startChat(String patientId) {
//     Navigator.pushNamed(context, '/doctor/messages');
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
//           _buildNavItem(Icons.home, 'Home', 0),
//           _buildNavItem(Icons.people, 'Community', 1),
//           _buildNavItem(Icons.medical_services, 'Patients', 2),
//           _buildNavItem(Icons.message, 'Message', 3),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNavItem(IconData icon, String label, int index) {
//     final isSelected = _selectedNavIndex == index;
//     return GestureDetector(
//       onTap: () => _onNavItemTapped(index),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: 24.sp, color: isSelected ? AppColors.primaryBlue : Colors.grey),
//           SizedBox(height: 4.h),
//           Text(label, style: TextStyle(fontSize: 12.sp, color: isSelected ? AppColors.primaryBlue : Colors.grey)),
//         ],
//       ),
//     );
//   }
// }
//
//
//
//
//
