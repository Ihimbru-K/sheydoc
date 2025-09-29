import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../patients/sign_in_with_phone_verification_screen.dart';

class PhoneSignInDocScreen extends StatefulWidget {
  final String role; // 👈 add this

  const PhoneSignInDocScreen({super.key, required this.role});

  @override
  State<PhoneSignInDocScreen> createState() => _PhoneSignInDocScreenState();
}

class _PhoneSignInDocScreenState extends State<PhoneSignInDocScreen> {
  final TextEditingController _phoneController =
  TextEditingController(text: '678549000');

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: GestureDetector(
          child: const Icon(Icons.arrow_back_ios),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Text(
          'Sign In',
          style: TextStyle(
            fontSize: 24.sp,
            color: AppColors.textBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40.h),

              Text(
                'Phone number',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),

              // Phone number input
              Container(
                width: double.infinity,
                height: 50.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Text(
                        '+237',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppColors.textBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(width: 1, height: 30.h, color: Colors.grey[300]),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppColors.textBlue,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                          hintText: 'Enter phone number',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // Sign in button
              CustomButton(
                text: 'Sign in',
                onPressed: () {
                  // Here you’d call Firebase Auth with `widget.role`
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhoneVerificationScreen(
                        role: widget.role, // 👈 pass role to next step
                        phoneNumber: _phoneController.text,
                      ),
                    ),
                  );
                },
                isFilled: true,
                backgroundColor: AppColors.primaryBlue,
                textColor: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
