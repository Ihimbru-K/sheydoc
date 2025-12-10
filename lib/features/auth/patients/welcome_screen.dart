import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sheydoc_app/features/auth/patients/signin_screen.dart';
import 'package:sheydoc_app/features/auth/patients/signin_with_phone_number_screen.dart';

import '../../../core/constants/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required String role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              // Top spacing
              SizedBox(height: 80.h),

              // Welcome text
              Text(
                'Welcome to',
                style: TextStyle(
                  fontSize: 24.sp,
                  color: AppColors.textBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 22.h),

                  Image.asset(
                    'assets/images/logos/logo.png',
                    height: 200,
                    width: 200,),





              _buildSignUpButton(
                icon: Icons.phone_android_outlined,
                text: '    Sign up with phone number',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>PhoneSignInScreen()));
                },
              ),

              SizedBox(height: 16.h),

              // Separator
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                ],
              ),

              SizedBox(height: 16.h),

              // Sign up with email
              _buildSignUpButton(
                icon: Icons.email_outlined,
                text: 'Sign up with email',
                onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context)=>SignInScreen()));},
              ),

              SizedBox(height: 32.h),

              // Sign up with Google
              _buildSignUpButton(
                iconWidget: Image.asset(
                  'assets/images/icons/google.png',
                  width: 24.w,
                  height: 24.h,
                  fit: BoxFit.contain,
                ),
                text: 'Sign up with Google',
                onPressed: () {},
              ),

              SizedBox(height: 32.h),

              // Sign up with Apple
              _buildSignUpButton(
                icon: Icons.apple,
                text: 'Sign up with Apple',
                onPressed: () {},
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpButton({
    IconData? icon,
    Widget? iconWidget,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textfieldBlue,
          foregroundColor: Colors.black87,
          elevation: 0,
          side: BorderSide(color: Colors.grey, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 0.w),
            if (iconWidget != null)
              iconWidget
            else if (icon != null)
              Icon(
                icon,
                size: 20.sp,
                color: Colors.black87,
              ),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
           // SizedBox(width: 36.w), // Balance the left padding + icon space
          ],
        ),
      ),
    );
  }
}