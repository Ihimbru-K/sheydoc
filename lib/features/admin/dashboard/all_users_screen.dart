import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheydoc_app/core/constants/app_colors.dart';

class AllUsersScreen extends StatefulWidget {
  final String userType; // 'doctor' or 'patient'

  const AllUsersScreen({super.key, required this.userType});

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, approved, pending, rejected

  @override
  Widget build(BuildContext context) {
    final isDoctors = widget.userType == 'doctor';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(isDoctors ? 'All Doctors' : 'All Patients'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search and filter
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (isDoctors) ...[
                  SizedBox(height: 12.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        _buildFilterChip('Approved', 'approved'),
                        _buildFilterChip('Pending', 'pending'),
                        _buildFilterChip('Rejected', 'rejected'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Users list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 80.sp, color: Colors.grey[300]),
                        SizedBox(height: 16.h),
                        Text(
                          'No ${widget.userType}s found',
                          style: TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toLowerCase();
                  final email = (data['email'] ?? '').toLowerCase();
                  final query = _searchQuery.toLowerCase();

                  return name.contains(query) || email.contains(query);
                }).toList();

                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData = users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;
                    return _buildUserCard(userId, userData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getUsersStream() {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: widget.userType);

    if (widget.userType == 'doctor' && _filterStatus != 'all') {
      query = query.where('approvalStatus', isEqualTo: _filterStatus);
    }

    return query.snapshots();
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;

    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterStatus = value);
        },
        selectedColor: AppColors.primaryBlue.withOpacity(0.2),
        checkmarkColor: AppColors.primaryBlue,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primaryBlue : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? 'N/A';
    final phone = data['phone'] ?? 'N/A';
    final approvalStatus = data['approvalStatus'] ?? 'N/A';
    final isDoctors = widget.userType == 'doctor';

    Color statusColor = Colors.grey;
    if (approvalStatus == 'approved') statusColor = Colors.green;
    if (approvalStatus == 'pending') statusColor = Colors.orange;
    if (approvalStatus == 'rejected') statusColor = Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12.w),
        leading: CircleAvatar(
          radius: 28.r,
          backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
          child: Icon(Icons.person, size: 28.sp, color: AppColors.primaryBlue),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(email, style: TextStyle(fontSize: 12.sp)),
            Text(phone, style: TextStyle(fontSize: 12.sp)),
            if (isDoctors) ...[
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  approvalStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 20.sp),
          onSelected: (value) => _handleAction(value, userId, data),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            if (isDoctors && approvalStatus != 'approved')
              const PopupMenuItem(value: 'approve', child: Text('Approve')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete User', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(String action, String userId, Map<String, dynamic> data) async {
    switch (action) {
      case 'view':
        _showUserDetails(data);
        break;
      case 'approve':
        await _approveUser(userId, data);
        break;
      case 'delete':
        await _deleteUser(userId, data);
        break;
    }
  }

  void _showUserDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['name'] ?? 'User Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Email', data['email'] ?? 'N/A'),
              _buildDetailItem('Phone', data['phone'] ?? 'N/A'),
              if (widget.userType == 'doctor') ...[
                _buildDetailItem('Specialty', data['specialty'] ?? 'N/A'),
                _buildDetailItem('License', data['licensingNumber'] ?? 'N/A'),
                _buildDetailItem('Status', data['approvalStatus'] ?? 'N/A'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  Future<void> _approveUser(String userId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'approvalStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'profileComplete': true,
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': 'Application Approved! 🎉',
        'body': 'Your profile has been approved',
        'type': 'approval_success',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data['name']} approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete ${data['name']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}