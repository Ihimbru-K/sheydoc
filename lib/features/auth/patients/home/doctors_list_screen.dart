import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheydoc_app/core/constants/app_colors.dart';
import 'package:sheydoc_app/features/auth/doctors/doctor_profile_screen.dart';
import 'dart:convert';

class DoctorsListScreen extends StatelessWidget {
  const DoctorsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Talk to a Doctor',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 24.sp
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'doctor')
           //s .where('profileComplete', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No doctors found'));
          }

          final doctors = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctorData = doctors[index].data() as Map<String, dynamic>;
              final doctorId = doctors[index].id;
              final name = doctorData['name'] ?? 'Dr. Unknown';
              final specialty = doctorData['specialty'] ?? 'General Practitioner';
              final rating = doctorData['rating'] ?? 5.0;
              final baseFee = doctorData['baseFee'] ?? 3000.0;
              final availability = doctorData['availability'] as List?;

              // Extract availability time range
              String availabilityText = '10:30 AM-3:30';
              if (availability != null && availability.isNotEmpty) {
                final firstSlot = availability.first as Map<String, dynamic>;
                final startHour = firstSlot['startHour'] ?? 10;
                final startMinute = firstSlot['startMinute'] ?? 30;
                final endHour = firstSlot['endHour'] ?? 15;
                final endMinute = firstSlot['endMinute'] ?? 30;

                String formatTime(int hour, int minute) {
                  final period = hour >= 12 ? 'PM' : 'AM';
                  final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                  final displayMinute = minute.toString().padLeft(2, '0');
                  return '$displayHour:$displayMinute $period';
                }

                final startTime = formatTime(startHour, startMinute);
                final endTime = formatTime(endHour, endMinute);
                availabilityText = '$startTime-${endTime.split(' ')[0]}';
              }

              return Container(
                margin: EdgeInsets.only(bottom: 16.h),
                padding: EdgeInsets.all(20.w),

                decoration: BoxDecoration(

                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Doctor Photo
                    Container(
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        image: doctorData['photo'] != null
                            ? DecorationImage(
                          image: MemoryImage(base64Decode(doctorData['photo'])),
                          fit: BoxFit.cover,
                        )
                            : null,
                        color: doctorData['photo'] == null ? Colors.grey[200] : null,
                      ),
                      child: doctorData['photo'] == null
                          ? Icon(Icons.person, size: 30.sp, color: Colors.grey)
                          : null,
                    ),
                    SizedBox(width: 12.w),

                    // Doctor Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textBlue,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.star, color: Color(0xffFFD33C), size: 16.sp),
                                  SizedBox(width: 4.w),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            specialty,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Color(0xff9C9C9C),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14.sp, color: Colors.grey[600]),
                              SizedBox(width: 4.w),
                              Text(
                                availabilityText,
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13.sp,
                                  color: Colors.black,
                                ),
                              ),

                            ],
                          ),
                          SizedBox(width: 16.w),
                          Text(
                            'Fee: ${baseFee.toStringAsFixed(0)}frs',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 15.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DoctorProfileScreen(
                              doctorId: doctorId,
                              doctorData: doctorData,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:sheydoc_app/core/constants/app_colors.dart';
// import 'package:sheydoc_app/features/auth/doctors/doctor_profile_screen.dart';
// import 'dart:convert';
//
// class DoctorsListScreen extends StatelessWidget {
//   const DoctorsListScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Talk to a Doctor'),
//         backgroundColor: AppColors.primaryBlue,
//         elevation: 0,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('users')
//             .where('role', isEqualTo: 'doctor')
//             .where('profileComplete', isEqualTo: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No doctors found'));
//           }
//
//           final doctors = snapshot.data!.docs;
//
//           return ListView.builder(
//             padding: EdgeInsets.all(16.w),
//             itemCount: doctors.length,
//             itemBuilder: (context, index) {
//               final doctorData = doctors[index].data() as Map<String, dynamic>;
//               final doctorId = doctors[index].id;
//               final name = doctorData['name'] ?? 'Dr. Unknown';
//               final specialty = doctorData['specialty'] ?? '';
//               final rating = doctorData['rating'] ?? 5.0;
//               final baseFee = doctorData['baseFee'] ?? 3000.0;
//               final availability = doctorData['availability'] as List?;
//
//               // Extract first available slot for display (simplified)
//               String availabilityText = 'N/A';
//               if (availability != null && availability.isNotEmpty) {
//                 final firstSlot = availability.first as Map<String, dynamic>;
//                 final startHour = firstSlot['startHour'];
//                 final startMinute = firstSlot['startMinute'];
//                 availabilityText = '10:00 AM - 3:00 PM'; // Placeholder, refine logic
//               }
//
//               return Card(
//                 elevation: 2,
//                 margin: EdgeInsets.symmetric(vertical: 8.h),
//                 child: ListTile(
//                   leading: CircleAvatar(
//                     radius: 24.r,
//                     backgroundImage: doctorData['photo'] != null
//                         ? MemoryImage(base64Decode(doctorData['photo']))
//                         : null,
//                     child: doctorData['photo'] == null
//                         ? Icon(Icons.person, size: 24.sp)
//                         : null,
//                   ),
//                   title: Text(
//                     name,
//                     style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         specialty,
//                         style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
//                       ),
//                       Text(
//                         'Fee: ${baseFee.toStringAsFixed(0)} FCFA',
//                         style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
//                       ),
//                       Text(
//                         availabilityText,
//                         style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
//                       ),
//                     ],
//                   ),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         rating.toStringAsFixed(1),
//                         style: TextStyle(fontSize: 14.sp),
//                       ),
//                       Icon(Icons.star, size: 16.sp, color: Colors.amber),
//                       Icon(Icons.arrow_forward_ios, size: 16.sp),
//                     ],
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => DoctorProfileScreen(
//                           doctorId: doctorId,
//                           doctorData: doctorData,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
//
//










// // New DoctorsListScreen
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:sheydoc_app/core/constants/app_colors.dart';
// import 'package:sheydoc_app/features/auth/doctors/doctor_profile_screen.dart'; // Adjust path if needed
// import 'dart:convert';
//
// class DoctorsListScreen extends StatelessWidget {
//   const DoctorsListScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Doctors'),
//         backgroundColor: AppColors.primaryBlue,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('users')
//             .where('role', isEqualTo: 'doctor')
//             .where('profileComplete', isEqualTo: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No doctors found'));
//           }
//
//           final doctors = snapshot.data!.docs;
//
//           return ListView.builder(
//             padding: EdgeInsets.all(16.w),
//             itemCount: doctors.length,
//             itemBuilder: (context, index) {
//               final doctorData = doctors[index].data() as Map<String, dynamic>;
//               final doctorId = doctors[index].id;
//
//               return Card(
//                 elevation: 2,
//                 margin: EdgeInsets.symmetric(vertical: 8.h),
//                 child: ListTile(
//                   leading: doctorData['photo'] != null
//                       ? CircleAvatar(
//                     radius: 24.r,
//                     backgroundImage: MemoryImage(
//                         base64Decode(doctorData['photo'])),
//                   )
//                       : CircleAvatar(
//                     radius: 24.r,
//                     child: Icon(Icons.person, size: 24.sp),
//                   ),
//                   title: Text(
//                     doctorData['name'] ?? 'Dr. Unknown',
//                     style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
//                   ),
//                   subtitle: Text(
//                     doctorData['specialty'] ?? 'Specialty',
//                     style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
//                   ),
//                   trailing: const Icon(Icons.arrow_forward_ios),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => DoctorProfileScreen(
//                           doctorId: doctorId,
//                           doctorData: doctorData,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }