import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sheydoc_app/features/onboarding/role_selection_screen.dart';


class OnboardingScreen4 extends StatelessWidget {
  const OnboardingScreen4({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF007AFF), // Blue background
      body: Stack(
        children: [
          // Background with header and full image
          Column(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // Status bar area with blue background
                    //SizedBox(height: 30.h),

                    // Header text at the top
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 50.h),
                      child: Text(
                        "Your Privacy Is Always Protected",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    //  SizedBox(height: 29.h),
                  ],
                ),
              ),

              // ===== FULL IMAGE SECTION =====
              Container(
                height: 700.h,
                // width: double.infinity,
                // padding: EdgeInsets.symmetric(horizontal: 18.w),
                margin: EdgeInsets.symmetric(horizontal: 14.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  image: const DecorationImage(
                    image: AssetImage("assets/images/onboarding/onboarding4.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            ],
          ),

          // ===== OVERLAPPING WHITE SECTION =====
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24.w, 30.h, 24.w, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16.sp,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                      children: [
                        const TextSpan(text: "Every"),
                        TextSpan(
                          text: "conversation",

                        ),
                        const TextSpan(text: ", "),
                        TextSpan(
                          text: "appointment",

                        ),
                        const TextSpan(text: ", "),
                        TextSpan(
                          text: "and health",

                        ),
                        const TextSpan(
                          text: "healthcare provider are safe, secure and confidential",
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(false),
                      _buildDot(false),
                      _buildDot(true),
                    ],
                  ),

                  SizedBox(height: 32.h),

                  // Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> RoleSelectionScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Let's Begin",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  //
                  // SizedBox(height: 16.h),
                  //
                  // // Skip button
                  // TextButton(
                  //   onPressed: () {
                  //
                  //   },
                  //   child: Text(
                  //     "Skip",
                  //     style: TextStyle(
                  //       fontSize: 16.sp,
                  //       fontWeight: FontWeight.w500,
                  //       color: Colors.grey[600],
                  //     ),
                  //   ),
                  // ),

                  // Home indicator (iPhone style) - at very bottom
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Container(
                      width: 134.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      width: isActive ? 8.w : 6.w,
      height: isActive ? 8.w : 6.w,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF007AFF) : Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}