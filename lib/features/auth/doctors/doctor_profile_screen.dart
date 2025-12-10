import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sheydoc_app/features/auth/patients/home/appointment_booking_screen.dart';
import '../../../core/constants/app_colors.dart';
import 'dart:convert';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;
  const DoctorProfileScreen({super.key, required this.doctorId, required this.doctorData});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  bool isFavorited = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.doctorData;
    final name = data['name'] ?? '';
    final specialty = data['specialty'] ?? '';
    final years = data['yearsOfExperience'] ?? 0;
    final rating = data['rating'] ?? 5.0;
    final baseFee = data['baseFee'] ?? 3000.0;
    final about = data['about'] ?? 'I am Dr. $name, a licensed $specialty dedicated to helping young women understand and care for their health with compassion, privacy, and respect.';

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Doctor',
          style: TextStyle(
            fontSize: 24,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited ? Colors.red : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                isFavorited = !isFavorited;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Image
            Container(
              margin: EdgeInsets.only(left: 18, right: 18),
              //width: double.infinity,
              height: 300.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                image: data['photo'] != null
                    ? DecorationImage(
                  image: MemoryImage(base64Decode(data['photo'])),
                  fit: BoxFit.cover,
                )
                    : null,
                color: data['photo'] == null ? Colors.grey[200] : null,
              ),
              child: data['photo'] == null
                  ? Icon(Icons.person, size: 100.sp, color: Colors.grey)
                  : null,
            ),

            // Doctor Info Section
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    specialty,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Stats Row
                  Row(
                    children: [
                      // Patients
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.people, size: 24.sp, color: AppColors.primaryBlue),
                            SizedBox(height: 8.h),
                            Text(
                              '116+',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Patients',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Years
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.work_history, size: 24.sp, color: AppColors.primaryBlue),
                            SizedBox(height: 8.h),
                            Text(
                              '${years}+',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Years',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Rating
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.star, size: 24.sp, color: AppColors.primaryBlue),
                            SizedBox(height: 8.h),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Rating',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Reviews
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.chat_bubble, size: 24.sp, color: AppColors.primaryBlue),
                            SizedBox(height: 8.h),
                            Text(
                              '90+',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Reviews',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Blog Posts
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.article, size: 24.sp, color: AppColors.primaryBlue),
                            SizedBox(height: 8.h),
                            Text(
                              '12',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Blog Posts',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30.h),

                  // About Me Section
                  Text(
                    'About Me',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    about,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Book Appointment Button
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentBookingScreen(
                              doctorId: widget.doctorId,
                              doctorData: widget.doctorData,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Book Appointment',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


