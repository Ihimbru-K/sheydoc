import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required String role});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isChecked = false; // 👈 Add this

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F4F9),
      appBar: AppBar(
        backgroundColor: const Color(0xffF4F4F9),
        leading: GestureDetector(
          child: const Icon(Icons.arrow_back_ios),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Text(
          'Sign Up',
          style: TextStyle(
            fontSize: 24.sp,
            color: AppColors.textBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 88.h),
              const CustomTextField(
                labelText: 'Full Name',
               // initialValue: 'Ayuk Kelly Ebai',
              ),
              const CustomTextField(
                labelText: 'Email Address',
                //initialValue: 'ayukkelly@gmail.com',
              ),
              CustomTextField(
                labelText: 'Password',
                obscureText: !_passwordVisible,
             //   initialValue: '******',
                onToggleVisibility: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
              CustomTextField(
                labelText: 'Confirm Password',
                obscureText: !_confirmPasswordVisible,
               // initialValue: '******',
                onToggleVisibility: () {
                  setState(() {
                    _confirmPasswordVisible = !_confirmPasswordVisible;
                  });
                },
              ),
              SizedBox(height: 38.h),

              // ✅ Checkbox with state
              Row(
                children: [
                  Checkbox(
                    value: _isChecked,
                    onChanged: (value) {
                      setState(() {
                        _isChecked = value ?? false;
                      });
                    },
                    activeColor: AppColors.primaryBlue,
                  ),
                  Expanded(
                    child: Text(
                      'By Creating an Account, I accept Hiring Hub terms of Use and Privacy Policy',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textBlue,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              CustomButton(
                text: 'Sign up',
                onPressed: () {
                  if (_isChecked) {
                    // ✅ Only allow signup if checkbox is ticked
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpScreen(role: '',)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You must accept the terms")),
                    );
                  }
                },
                isFilled: true,
                backgroundColor: AppColors.primaryBlue,
                textColor: AppColors.white,
              ),

              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
