import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sheydoc_app/core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sheydoc_app/features/auth/patients/home/patients_sessions_screen.dart';
import 'doctors_list_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedNavIndex = 0;

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0: // Home - stay here
        break;
      case 1: // Services - go to doctors list
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DoctorsListScreen()),
        );
        break;
      case 2: // Resources - coming soon
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resources feature coming soon!'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 3: // Chats
        Navigator.pushNamed(context, '/patient/messages');
        break;
      case 4: // Profile - show logout option
        _showProfileOptions();
        break;
    }
  }

  // ✅ NEW: Show profile options with logout
  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading: Icon(Icons.person, color: AppColors.primaryBlue),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile feature coming soon!')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: AppColors.primaryBlue),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings feature coming soon!')),
                );
              },
            ),
            Divider(height: 20.h),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Top Blue Section
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
              child: Column(
                children: [
                  // Header with profile and notification
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20.r,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.grey, size: 20.sp),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, Welcome 🎉',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              user?.email ?? 'Patient',
                              style: TextStyle(
                                fontSize: 18.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.notifications_outlined, color: Colors.white, size: 24.sp),
                        onPressed: () {
                          // TODO: Navigate to notifications
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.logout, color: Colors.white, size: 24.sp),
                        onPressed: _handleLogout,
                        tooltip: 'Logout',
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Search Bar
                  Container(
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search a doctor or health issue...',
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[500],
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20.sp),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Upcoming visits section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Upcoming visits',
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Appointment Card
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Date section
                        SizedBox(
                          width: 50.w,
                          child: Column(
                            children: [
                              Text(
                                '20',
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Mar',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 16.w),

                        // Appointment details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Check-up',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Dr. Joshua',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'SheyDoctor, Yaounde',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Time
                        Text(
                          '10:30 AM',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Online Help
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Online Help',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12.sp),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom White Section
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.r),
                    topRight: Radius.circular(30.r),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),

                        // Action buttons grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                context,
                                icon: Icons.medical_services,
                                title: 'Talk to a doctor',
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
                              child: _buildActionCard(
                                context,
                                icon: Icons.calendar_today,
                                title: 'Book Appointment',
                                color: const Color(0xFF87CEEB),
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
                              child: _buildActionCard(
                                context,
                                icon: Icons.show_chart,
                                title: 'Sessions',
                                color: const Color(0xFF87CEEB),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const PatientSessionsScreen()),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: _buildActionCard(
                                context,
                                icon: Icons.help_outline,
                                title: 'Health FAQs',
                                color: const Color(0xFF87CEEB),
                                onTap: () {
                                  // TODO: Navigate to FAQs
                                },
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 30.h),

                        // How are you feeling today section
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'How are you feeling today?',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Feeling buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildFeelingButton(
                              icon: Icons.sentiment_very_satisfied,
                              label: 'Happy',
                              color: AppColors.primaryBlue,
                            ),
                            _buildFeelingButton(
                              icon: Icons.self_improvement,
                              label: 'Calm',
                              color: AppColors.primaryBlue,
                            ),
                            _buildFeelingButton(
                              icon: Icons.spa,
                              label: 'Relax',
                              color: AppColors.primaryBlue,
                            ),
                            _buildFeelingButton(
                              icon: Icons.psychology,
                              label: 'Focus',
                              color: AppColors.primaryBlue,
                            ),
                          ],
                        ),

                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildActionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32.sp,
              color: Colors.white,
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeelingButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 60.w,
          height: 60.h,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80.h,
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.medical_services, 'Services', 1),
          _buildNavItem(Icons.article, 'Resources', 2),
          _buildNavItem(Icons.chat, 'Chats', 3),
          _buildNavItem(Icons.person, 'Profile', 4),
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
          Icon(
            icon,
            size: 24.sp,
            color: isSelected ? AppColors.primaryBlue : Colors.grey,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isSelected ? AppColors.primaryBlue : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sheydoc_app/core/constants/app_colors.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:sheydoc_app/features/auth/patients/home/patients_sessions_screen.dart';
// import 'doctors_list_screen.dart';
//
// class PatientHomeScreen extends StatefulWidget {
//   const PatientHomeScreen({super.key});
//
//   @override
//   State<PatientHomeScreen> createState() => _PatientHomeScreenState();
// }
//
// class _PatientHomeScreenState extends State<PatientHomeScreen> {
//   int _selectedNavIndex = 0;
//
//   void _onNavItemTapped(int index) {
//     setState(() {
//       _selectedNavIndex = index;
//     });
//
//     switch (index) {
//       case 0: // Home - stay here
//         break;
//       case 1: // Services - go to doctors list
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const DoctorsListScreen()),
//         );
//         break;
//       case 2: // Resources - coming soon
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Resources feature coming soon!'),
//             duration: Duration(seconds: 2),
//           ),
//         );
//         break;
//       case 3: // Chats
//         Navigator.pushNamed(context, '/patient/messages');
//         break;
//       case 4: // Profile - show logout option
//         _showProfileOptions();
//         break;
//     }
//   }
//
//   // ✅ NEW: Show profile options with logout
//   void _showProfileOptions() {
//     showModalBottomSheet(
//       context: context,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
//       ),
//       builder: (context) => Container(
//         padding: EdgeInsets.all(20.w),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 40.w,
//               height: 4.h,
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(2.r),
//               ),
//             ),
//             SizedBox(height: 20.h),
//             ListTile(
//               leading: Icon(Icons.person, color: AppColors.primaryBlue),
//               title: const Text('View Profile'),
//               onTap: () {
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Profile feature coming soon!')),
//                 );
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.settings, color: AppColors.primaryBlue),
//               title: const Text('Settings'),
//               onTap: () {
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Settings feature coming soon!')),
//                 );
//               },
//             ),
//             Divider(height: 20.h),
//             ListTile(
//               leading: const Icon(Icons.logout, color: Colors.red),
//               title: const Text('Logout', style: TextStyle(color: Colors.red)),
//               onTap: () {
//                 Navigator.pop(context);
//                 _handleLogout();
//               },
//             ),
//             SizedBox(height: 20.h),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ✅ NEW: Logout function
//   Future<void> _handleLogout() async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Logout'),
//         content: const Text('Are you sure you want to logout?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Logout'),
//           ),
//         ],
//       ),
//     );
//
//     if (confirm == true && mounted) {
//       try {
//         await FirebaseAuth.instance.signOut();
//         if (mounted) {
//           Navigator.pushNamedAndRemoveUntil(
//             context,
//             '/role-selection',
//                 (route) => false,
//           );
//         }
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Logout failed: $e'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;
//
//     return Scaffold(
//       backgroundColor: AppColors.primaryBlue,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Top Blue Section
//             Container(
//               padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
//               child: Column(
//                 children: [
//                   // Header with profile and notification
//                   Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 20.r,
//                         backgroundColor: Colors.white,
//                         child: Icon(Icons.person, color: Colors.grey, size: 20.sp),
//                       ),
//                       SizedBox(width: 12.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Hi, Welcome 🎉',
//                               style: TextStyle(
//                                 fontSize: 14.sp,
//                                 color: Colors.white.withOpacity(0.9),
//                                 fontWeight: FontWeight.w400,
//                               ),
//                             ),
//                             Text(
//                               user?.email ?? 'Patient',
//                               style: TextStyle(
//                                 fontSize: 18.sp,
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.notifications_outlined, color: Colors.white, size: 24.sp),
//                         onPressed: () {
//                           // TODO: Navigate to notifications
//                         },
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.logout, color: Colors.white, size: 24.sp),
//                         onPressed: _handleLogout,
//                         tooltip: 'Logout',
//                       ),
//                     ],
//                   ),
//
//                   SizedBox(height: 24.h),
//
//                   // Search Bar
//                   Container(
//                     height: 50.h,
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12.r),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 10,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: TextField(
//                       decoration: InputDecoration(
//                         hintText: 'Search a doctor or health issue...',
//                         hintStyle: TextStyle(
//                           fontSize: 14.sp,
//                           color: Colors.grey[500],
//                         ),
//                         prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20.sp),
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
//                       ),
//                     ),
//                   ),
//
//                   SizedBox(height: 24.h),
//
//                   // Upcoming visits section
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       'Upcoming visits',
//                       style: TextStyle(
//                         fontSize: 18.sp,
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//
//                   SizedBox(height: 16.h),
//
//                   // Appointment Card
//                   Container(
//                     padding: EdgeInsets.all(16.w),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12.r),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.05),
//                           blurRadius: 10,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         // Date section
//                         SizedBox(
//                           width: 50.w,
//                           child: Column(
//                             children: [
//                               Text(
//                                 '20',
//                                 style: TextStyle(
//                                   fontSize: 28.sp,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                               Text(
//                                 'Mar',
//                                 style: TextStyle(
//                                   fontSize: 14.sp,
//                                   color: Colors.grey[600],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         SizedBox(width: 16.w),
//
//                         // Appointment details
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Check-up',
//                                 style: TextStyle(
//                                   fontSize: 16.sp,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.black,
//                                 ),
//                               ),
//                               SizedBox(height: 2.h),
//                               Text(
//                                 'Dr. Joshua',
//                                 style: TextStyle(
//                                   fontSize: 14.sp,
//                                   color: Colors.grey[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               SizedBox(height: 2.h),
//                               Text(
//                                 'SheyDoctor, Yaounde',
//                                 style: TextStyle(
//                                   fontSize: 12.sp,
//                                   color: Colors.grey[500],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         // Time
//                         Text(
//                           '10:30 AM',
//                           style: TextStyle(
//                             fontSize: 14.sp,
//                             color: Colors.grey[600],
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   SizedBox(height: 16.h),
//
//                   // Online Help
//                   Row(
//                     children: [
//                       Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16.sp),
//                       SizedBox(width: 8.w),
//                       Text(
//                         'Online Help',
//                         style: TextStyle(
//                           fontSize: 14.sp,
//                           color: Colors.white,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       SizedBox(width: 8.w),
//                       Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12.sp),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//             // Bottom White Section
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(30.r),
//                     topRight: Radius.circular(30.r),
//                   ),
//                 ),
//                 child: SingleChildScrollView(
//                   child: Padding(
//                     padding: EdgeInsets.all(20.w),
//                     child: Column(
//                       children: [
//                         SizedBox(height: 20.h),
//
//                         // Action buttons grid
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildActionCard(
//                                 context,
//                                 icon: Icons.medical_services,
//                                 title: 'Talk to a doctor',
//                                 color: AppColors.primaryBlue,
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) => const DoctorsListScreen(),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                             SizedBox(width: 16.w),
//                             Expanded(
//                               child: _buildActionCard(
//                                 context,
//                                 icon: Icons.calendar_today,
//                                 title: 'Book Appointment',
//                                 color: const Color(0xFF87CEEB),
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) => const DoctorsListScreen(),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),
//
//                         SizedBox(height: 16.h),
//
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildActionCard(
//                                 context,
//                                 icon: Icons.show_chart,
//                                 title: 'Sessions',
//                                 color: const Color(0xFF87CEEB),
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(builder: (context) => const PatientSessionsScreen()),
//                                   );
//                                 },
//                               ),
//                             ),
//                             SizedBox(width: 16.w),
//                             Expanded(
//                               child: _buildActionCard(
//                                 context,
//                                 icon: Icons.help_outline,
//                                 title: 'Health FAQs',
//                                 color: const Color(0xFF87CEEB),
//                                 onTap: () {
//                                   // TODO: Navigate to FAQs
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),
//
//                         SizedBox(height: 30.h),
//
//                         // How are you feeling today section
//                         Align(
//                           alignment: Alignment.centerLeft,
//                           child: Text(
//                             'How are you feeling today?',
//                             style: TextStyle(
//                               fontSize: 18.sp,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//
//                         SizedBox(height: 16.h),
//
//                         // Feeling buttons
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             _buildFeelingButton(
//                               icon: Icons.sentiment_very_satisfied,
//                               label: 'Happy',
//                               color: AppColors.primaryBlue,
//                             ),
//                             _buildFeelingButton(
//                               icon: Icons.self_improvement,
//                               label: 'Calm',
//                               color: AppColors.primaryBlue,
//                             ),
//                             _buildFeelingButton(
//                               icon: Icons.spa,
//                               label: 'Relax',
//                               color: AppColors.primaryBlue,
//                             ),
//                             _buildFeelingButton(
//                               icon: Icons.psychology,
//                               label: 'Focus',
//                               color: AppColors.primaryBlue,
//                             ),
//                           ],
//                         ),
//
//                         SizedBox(height: 20.h),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: _buildBottomNavigationBar(),
//     );
//   }
//
//   Widget _buildActionCard(
//       BuildContext context, {
//         required IconData icon,
//         required String title,
//         required Color color,
//         required VoidCallback onTap,
//       }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(16.r),
//         ),
//         child: Column(
//           children: [
//             Icon(
//               icon,
//               size: 32.sp,
//               color: Colors.white,
//             ),
//             SizedBox(height: 8.h),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 14.sp,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.white,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFeelingButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//   }) {
//     return Column(
//       children: [
//         Container(
//           width: 60.w,
//           height: 60.h,
//           decoration: BoxDecoration(
//             color: color,
//             shape: BoxShape.circle,
//           ),
//           child: Icon(
//             icon,
//             color: Colors.white,
//             size: 28.sp,
//           ),
//         ),
//         SizedBox(height: 8.h),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12.sp,
//             color: Colors.black,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildBottomNavigationBar() {
//     return Container(
//       height: 80.h,
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
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _buildNavItem(Icons.home, 'Home', 0),
//           _buildNavItem(Icons.medical_services, 'Services', 1),
//           _buildNavItem(Icons.article, 'Resources', 2),
//           _buildNavItem(Icons.chat, 'Chats', 3),
//           _buildNavItem(Icons.person, 'Profile', 4),
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
//           Icon(
//             icon,
//             size: 24.sp,
//             color: isSelected ? AppColors.primaryBlue : Colors.grey,
//           ),
//           SizedBox(height: 4.h),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12.sp,
//               color: isSelected ? AppColors.primaryBlue : Colors.grey,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
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
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // import 'package:sheydoc_app/core/constants/app_colors.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:sheydoc_app/features/auth/patients/home/patients_sessions_screen.dart';
// // import 'doctors_list_screen.dart';
// //
// // class PatientHomeScreen extends StatefulWidget {
// //   const PatientHomeScreen({super.key});
// //
// //   @override
// //   State<PatientHomeScreen> createState() => _PatientHomeScreenState();
// // }
// //
// // class _PatientHomeScreenState extends State<PatientHomeScreen> {
// //   int _selectedNavIndex = 0;
// //
// //   void _onNavItemTapped(int index) {
// //     setState(() {
// //       _selectedNavIndex = index;
// //     });
// //
// //     switch (index) {
// //       case 0: // Home - stay here
// //         break;
// //       case 1: // Services - go to doctors list
// //         Navigator.push(
// //           context,
// //           MaterialPageRoute(builder: (context) => const DoctorsListScreen()),
// //         );
// //         break;
// //       case 2: // Resources - coming soon
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text('Resources feature coming soon!'),
// //             duration: Duration(seconds: 2),
// //           ),
// //         );
// //         break;
// //       case 3: // Chats - THIS IS THE KEY ONE BRO! 🔥
// //         Navigator.pushNamed(context, '/patient/messages');
// //         break;
// //       case 4: // Profile - coming soon
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text('Profile feature coming soon!'),
// //             duration: Duration(seconds: 2),
// //           ),
// //         );
// //         break;
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final user = FirebaseAuth.instance.currentUser;
// //
// //     return Scaffold(
// //       backgroundColor: AppColors.primaryBlue,
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             // Top Blue Section
// //             Container(
// //               padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
// //               child: Column(
// //                 children: [
// //                   // Header with profile and notification
// //                   Row(
// //                     children: [
// //                       CircleAvatar(
// //                         radius: 20.r,
// //                         backgroundColor: Colors.white,
// //                         child: Icon(Icons.person, color: Colors.grey, size: 20.sp),
// //                       ),
// //                       SizedBox(width: 12.w),
// //                       Expanded(
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             Text(
// //                               'Hi, Welcome 🎉',
// //                               style: TextStyle(
// //                                 fontSize: 14.sp,
// //                                 color: Colors.white.withOpacity(0.9),
// //                                 fontWeight: FontWeight.w400,
// //                               ),
// //                             ),
// //                             Text(
// //                               user?.email ?? 'Patient',
// //                               style: TextStyle(
// //                                 fontSize: 18.sp,
// //                                 color: Colors.white,
// //                                 fontWeight: FontWeight.w600,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                       IconButton(
// //                         icon: Icon(Icons.notifications_outlined, color: Colors.white, size: 24.sp),
// //                         onPressed: () {
// //                           // TODO: Navigate to notifications
// //                         },
// //                       ),
// //                     ],
// //                   ),
// //
// //                   SizedBox(height: 24.h),
// //
// //                   // Search Bar
// //                   Container(
// //                     height: 50.h,
// //                     decoration: BoxDecoration(
// //                       color: Colors.white,
// //                       borderRadius: BorderRadius.circular(12.r),
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: Colors.black.withOpacity(0.1),
// //                           blurRadius: 10,
// //                           offset: const Offset(0, 2),
// //                         ),
// //                       ],
// //                     ),
// //                     child: TextField(
// //                       decoration: InputDecoration(
// //                         hintText: 'Search a doctor or health issue...',
// //                         hintStyle: TextStyle(
// //                           fontSize: 14.sp,
// //                           color: Colors.grey[500],
// //                         ),
// //                         prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20.sp),
// //                         border: InputBorder.none,
// //                         contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
// //                       ),
// //                     ),
// //                   ),
// //
// //                   SizedBox(height: 24.h),
// //
// //                   // Upcoming visits section
// //                   Align(
// //                     alignment: Alignment.centerLeft,
// //                     child: Text(
// //                       'Upcoming visits',
// //                       style: TextStyle(
// //                         fontSize: 18.sp,
// //                         color: Colors.white,
// //                         fontWeight: FontWeight.w600,
// //                       ),
// //                     ),
// //                   ),
// //
// //                   SizedBox(height: 16.h),
// //
// //                   // Appointment Card
// //                   Container(
// //                     padding: EdgeInsets.all(16.w),
// //                     decoration: BoxDecoration(
// //                       color: Colors.white,
// //                       borderRadius: BorderRadius.circular(12.r),
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: Colors.black.withOpacity(0.05),
// //                           blurRadius: 10,
// //                           offset: const Offset(0, 2),
// //                         ),
// //                       ],
// //                     ),
// //                     child: Row(
// //                       children: [
// //                         // Date section
// //                         SizedBox(
// //                           width: 50.w,
// //                           child: Column(
// //                             children: [
// //                               Text(
// //                                 '20',
// //                                 style: TextStyle(
// //                                   fontSize: 28.sp,
// //                                   fontWeight: FontWeight.bold,
// //                                   color: Colors.grey[600],
// //                                 ),
// //                               ),
// //                               Text(
// //                                 'Mar',
// //                                 style: TextStyle(
// //                                   fontSize: 14.sp,
// //                                   color: Colors.grey[600],
// //                                   fontWeight: FontWeight.w500,
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //
// //                         SizedBox(width: 16.w),
// //
// //                         // Appointment details
// //                         Expanded(
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Text(
// //                                 'Check-up',
// //                                 style: TextStyle(
// //                                   fontSize: 16.sp,
// //                                   fontWeight: FontWeight.w600,
// //                                   color: Colors.black,
// //                                 ),
// //                               ),
// //                               SizedBox(height: 2.h),
// //                               Text(
// //                                 'Dr. Joshua',
// //                                 style: TextStyle(
// //                                   fontSize: 14.sp,
// //                                   color: Colors.grey[700],
// //                                   fontWeight: FontWeight.w500,
// //                                 ),
// //                               ),
// //                               SizedBox(height: 2.h),
// //                               Text(
// //                                 'SheyDoctor, Yaounde',
// //                                 style: TextStyle(
// //                                   fontSize: 12.sp,
// //                                   color: Colors.grey[500],
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //
// //                         // Time
// //                         Text(
// //                           '10:30 AM',
// //                           style: TextStyle(
// //                             fontSize: 14.sp,
// //                             color: Colors.grey[600],
// //                             fontWeight: FontWeight.w500,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //
// //                   SizedBox(height: 16.h),
// //
// //                   // Online Help
// //                   Row(
// //                     children: [
// //                       Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16.sp),
// //                       SizedBox(width: 8.w),
// //                       Text(
// //                         'Online Help',
// //                         style: TextStyle(
// //                           fontSize: 14.sp,
// //                           color: Colors.white,
// //                           fontWeight: FontWeight.w500,
// //                         ),
// //                       ),
// //                       SizedBox(width: 8.w),
// //                       Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12.sp),
// //                     ],
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             // Bottom White Section
// //             Expanded(
// //               child: Container(
// //                 width: double.infinity,
// //                 decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.only(
// //                     topLeft: Radius.circular(30.r),
// //                     topRight: Radius.circular(30.r),
// //                   ),
// //                 ),
// //                 child: SingleChildScrollView(
// //                   child: Padding(
// //                     padding: EdgeInsets.all(20.w),
// //                     child: Column(
// //                       children: [
// //                         SizedBox(height: 20.h),
// //
// //                         // Action buttons grid
// //                         Row(
// //                           children: [
// //                             Expanded(
// //                               child: _buildActionCard(
// //                                 context,
// //                                 icon: Icons.medical_services,
// //                                 title: 'Talk to a doctor',
// //                                 color: AppColors.primaryBlue,
// //                                 onTap: () {
// //                                   Navigator.push(
// //                                     context,
// //                                     MaterialPageRoute(
// //                                       builder: (context) => const DoctorsListScreen(),
// //                                     ),
// //                                   );
// //                                 },
// //                               ),
// //                             ),
// //                             SizedBox(width: 16.w),
// //                             Expanded(
// //                               child: _buildActionCard(
// //                                 context,
// //                                 icon: Icons.calendar_today,
// //                                 title: 'Book Appointment',
// //                                 color: const Color(0xFF87CEEB),
// //                                 onTap: () {
// //                                   Navigator.push(
// //                                     context,
// //                                     MaterialPageRoute(
// //                                       builder: (context) => const DoctorsListScreen(),
// //                                     ),
// //                                   );
// //                                 },
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //
// //                         SizedBox(height: 16.h),
// //
// //                         Row(
// //                           children: [
// //                             Expanded(
// //                               child: _buildActionCard(
// //                                 context,
// //                                 icon: Icons.show_chart,
// //                                 title: 'Sessions',
// //                                 color: const Color(0xFF87CEEB),
// //                                 onTap: () {
// //                                   Navigator.push(
// //                                     context,
// //                                     MaterialPageRoute(builder: (context) => const PatientSessionsScreen()),
// //                                   );
// //                                 },
// //                               ),
// //                             ),
// //                             SizedBox(width: 16.w),
// //                             Expanded(
// //                               child: _buildActionCard(
// //                                 context,
// //                                 icon: Icons.help_outline,
// //                                 title: 'Health FAQs',
// //                                 color: const Color(0xFF87CEEB),
// //                                 onTap: () {
// //                                   // TODO: Navigate to FAQs
// //                                 },
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //
// //                         SizedBox(height: 30.h),
// //
// //                         // How are you feeling today section
// //                         Align(
// //                           alignment: Alignment.centerLeft,
// //                           child: Text(
// //                             'How are you feeling today?',
// //                             style: TextStyle(
// //                               fontSize: 18.sp,
// //                               fontWeight: FontWeight.w600,
// //                               color: Colors.black,
// //                             ),
// //                           ),
// //                         ),
// //
// //                         SizedBox(height: 16.h),
// //
// //                         // Feeling buttons
// //                         Row(
// //                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                           children: [
// //                             _buildFeelingButton(
// //                               icon: Icons.sentiment_very_satisfied,
// //                               label: 'Happy',
// //                               color: AppColors.primaryBlue,
// //                             ),
// //                             _buildFeelingButton(
// //                               icon: Icons.self_improvement,
// //                               label: 'Calm',
// //                               color: AppColors.primaryBlue,
// //                             ),
// //                             _buildFeelingButton(
// //                               icon: Icons.spa,
// //                               label: 'Relax',
// //                               color: AppColors.primaryBlue,
// //                             ),
// //                             _buildFeelingButton(
// //                               icon: Icons.psychology,
// //                               label: 'Focus',
// //                               color: AppColors.primaryBlue,
// //                             ),
// //                           ],
// //                         ),
// //
// //                         SizedBox(height: 20.h),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //       bottomNavigationBar: _buildBottomNavigationBar(),
// //     );
// //   }
// //
// //   Widget _buildActionCard(
// //       BuildContext context, {
// //         required IconData icon,
// //         required String title,
// //         required Color color,
// //         required VoidCallback onTap,
// //       }) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
// //         decoration: BoxDecoration(
// //           color: color,
// //           borderRadius: BorderRadius.circular(16.r),
// //         ),
// //         child: Column(
// //           children: [
// //             Icon(
// //               icon,
// //               size: 32.sp,
// //               color: Colors.white,
// //             ),
// //             SizedBox(height: 8.h),
// //             Text(
// //               title,
// //               style: TextStyle(
// //                 fontSize: 14.sp,
// //                 fontWeight: FontWeight.w500,
// //                 color: Colors.white,
// //               ),
// //               textAlign: TextAlign.center,
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildFeelingButton({
// //     required IconData icon,
// //     required String label,
// //     required Color color,
// //   }) {
// //     return Column(
// //       children: [
// //         Container(
// //           width: 60.w,
// //           height: 60.h,
// //           decoration: BoxDecoration(
// //             color: color,
// //             shape: BoxShape.circle,
// //           ),
// //           child: Icon(
// //             icon,
// //             color: Colors.white,
// //             size: 28.sp,
// //           ),
// //         ),
// //         SizedBox(height: 8.h),
// //         Text(
// //           label,
// //           style: TextStyle(
// //             fontSize: 12.sp,
// //             color: Colors.black,
// //             fontWeight: FontWeight.w500,
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildBottomNavigationBar() {
// //     return Container(
// //       height: 80.h,
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
// //           _buildNavItem(Icons.home, 'Home', 0),
// //           _buildNavItem(Icons.medical_services, 'Services', 1),
// //           _buildNavItem(Icons.article, 'Resources', 2),
// //           _buildNavItem(Icons.chat, 'Chats', 3), // 🔥 THIS ONE OPENS MESSAGES!
// //           _buildNavItem(Icons.person, 'Profile', 4),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildNavItem(IconData icon, String label, int index) {
// //     final isSelected = _selectedNavIndex == index;
// //     return GestureDetector(
// //       onTap: () => _onNavItemTapped(index),
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(
// //             icon,
// //             size: 24.sp,
// //             color: isSelected ? AppColors.primaryBlue : Colors.grey,
// //           ),
// //           SizedBox(height: 4.h),
// //           Text(
// //             label,
// //             style: TextStyle(
// //               fontSize: 12.sp,
// //               color: isSelected ? AppColors.primaryBlue : Colors.grey,
// //               fontWeight: FontWeight.w500,
// //             ),
// //           ),
// //         ],
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
// //
// //
// //
// //
// //
