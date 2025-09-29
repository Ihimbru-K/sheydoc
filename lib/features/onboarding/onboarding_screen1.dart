import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/custom_button.dart';
import 'onboarding_screen2.dart';

class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Top collage image
          Expanded(
            flex: 5,
            child: Container(
              //width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/onboarding/onboarding1.png"),
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
          ),

          // Bottom section
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: Column(
                children: [
                  // Scrollable content (title + description)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome to SheyDoc",
                            style: TextStyle(

                              fontSize: 32.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            "SheyDoc is a digital platform that provides discreet "
                                "access to affordable sexual, reproductive, and mental "
                                "health services for young people.",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,

                              fontSize: 16,
                              height: 1.5,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Buttons section pinned at bottom
                  Column(
                    children: [
                      CustomButton(
                        width: double.infinity,
                        text: "Get Started",
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>OnboardingScreen2()));

                        },
                        isFilled: true,
                        radius: 8.r,
                      ),
                      SizedBox(height: 14.h),
                      CustomButton(
                        width: double.infinity,
                        text: "skip",
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>OnboardingScreen2()));
                        },
                        isFilled: false,
                        radius: 8.r,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
