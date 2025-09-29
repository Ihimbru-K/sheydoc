// Updated PatientHomeScreen with navigation to DoctorsListScreen in 'My Doctors' card
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sheydoc_app/core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';


import 'doctors_list_screen.dart'; // Add this import (adjust path if needed)

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'Patient Dashboard',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to profile
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBlue,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                user?.email ?? 'Patient',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24.h),

              // Quick actions grid
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.calendar_today,
                      title: 'Book Appointment',
                      color: AppColors.primaryBlue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DoctorsListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.medical_services_outlined,
                      title: 'My Doctors',
                      color: const Color(0xFF00B4D8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DoctorsListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.history,
                      title: 'Appointments',
                      color: const Color(0xFF90E0EF),
                      onTap: () {
                        // TODO: Navigate to appointment history
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.chat_bubble_outline,
                      title: 'Messages',
                      color: const Color(0xFF48CAE4),
                      onTap: () {
                        // TODO: Navigate to messages
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32.h),

              // Upcoming appointments section
              Text(
                'Upcoming Appointments',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlue,
                ),
              ),
              SizedBox(height: 16.h),

              // Placeholder for no appointments
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No upcoming appointments',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Book your first appointment with a doctor',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Sign out button (for testing)
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: OutlinedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                          (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28.sp,
                color: color,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textBlue,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sheydoc_app/core/constants/app_colors.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class PatientHomeScreen extends StatelessWidget {
//   const PatientHomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;
//
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       appBar: AppBar(
//         backgroundColor: AppColors.primaryBlue,
//         elevation: 0,
//         title: Text(
//           'Patient Dashboard',
//           style: TextStyle(
//             fontSize: 20.sp,
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_outlined, color: Colors.white),
//             onPressed: () {
//               // TODO: Navigate to notifications
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
//             onPressed: () {
//               // TODO: Navigate to profile
//             },
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(20.w),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Welcome message
//               Text(
//                 'Welcome back!',
//                 style: TextStyle(
//                   fontSize: 24.sp,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.textBlue,
//                 ),
//               ),
//               SizedBox(height: 8.h),
//               Text(
//                 user?.email ?? 'Patient',
//                 style: TextStyle(
//                   fontSize: 14.sp,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               SizedBox(height: 24.h),
//
//               // Quick actions grid
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildQuickActionCard(
//                       context,
//                       icon: Icons.calendar_today,
//                       title: 'Book Appointment',
//                       color: AppColors.primaryBlue,
//                       onTap: () {
//                         // TODO: Navigate to book appointment
//                       },
//                     ),
//                   ),
//                   SizedBox(width: 16.w),
//                   Expanded(
//                     child: _buildQuickActionCard(
//                       context,
//                       icon: Icons.medical_services_outlined,
//                       title: 'My Doctors',
//                       color: const Color(0xFF00B4D8),
//                       onTap: () {
//                         // TODO: Navigate to doctors list
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 16.h),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildQuickActionCard(
//                       context,
//                       icon: Icons.history,
//                       title: 'Appointments',
//                       color: const Color(0xFF90E0EF),
//                       onTap: () {
//                         // TODO: Navigate to appointment history
//                       },
//                     ),
//                   ),
//                   SizedBox(width: 16.w),
//                   Expanded(
//                     child: _buildQuickActionCard(
//                       context,
//                       icon: Icons.chat_bubble_outline,
//                       title: 'Messages',
//                       color: const Color(0xFF48CAE4),
//                       onTap: () {
//                         // TODO: Navigate to messages
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//
//               SizedBox(height: 32.h),
//
//               // Upcoming appointments section
//               Text(
//                 'Upcoming Appointments',
//                 style: TextStyle(
//                   fontSize: 18.sp,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.textBlue,
//                 ),
//               ),
//               SizedBox(height: 16.h),
//
//               // Placeholder for no appointments
//               Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.all(24.w),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12.r),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Icon(
//                       Icons.calendar_today_outlined,
//                       size: 48.sp,
//                       color: Colors.grey[400],
//                     ),
//                     SizedBox(height: 12.h),
//                     Text(
//                       'No upcoming appointments',
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                     SizedBox(height: 8.h),
//                     Text(
//                       'Book your first appointment with a doctor',
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         color: Colors.grey[500],
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//
//               SizedBox(height: 24.h),
//
//               // Sign out button (for testing)
//               SizedBox(
//                 width: double.infinity,
//                 height: 48.h,
//                 child: OutlinedButton(
//                   onPressed: () async {
//                     await FirebaseAuth.instance.signOut();
//                     Navigator.pushNamedAndRemoveUntil(
//                       context,
//                       '/',
//                           (route) => false,
//                     );
//                   },
//                   style: OutlinedButton.styleFrom(
//                     side: BorderSide(color: AppColors.primaryBlue),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.r),
//                     ),
//                   ),
//                   child: Text(
//                     'Sign Out',
//                     style: TextStyle(
//                       fontSize: 16.sp,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.primaryBlue,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQuickActionCard(
//       BuildContext context, {
//         required IconData icon,
//         required String title,
//         required Color color,
//         required VoidCallback onTap,
//       }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12.r),
//       child: Container(
//         padding: EdgeInsets.all(16.w),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12.r),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             Container(
//               padding: EdgeInsets.all(12.w),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 icon,
//                 size: 28.sp,
//                 color: color,
//               ),
//             ),
//             SizedBox(height: 12.h),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 14.sp,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.textBlue,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }