import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // 👇 Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isChecked = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (!_isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must accept the terms")),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    // ✅ Collect values
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    debugPrint("SIGNUP DATA => name:$fullName email:$email password:$password");

    // TODO: Call Firebase/AuthService here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F4F9),
      appBar: AppBar(
        backgroundColor: const Color(0xffF4F4F9),
        leading: GestureDetector(
          child: const Icon(Icons.arrow_back_ios),
          onTap: () => Navigator.pop(context),
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

              // 👇 New textfields
              CustomTextField(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                controller: _fullNameController,
              ),
              CustomTextField(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              CustomTextField(
                labelText: 'Password',
                hintText: 'Enter password',
                controller: _passwordController,
                obscureText: !_passwordVisible,
                onToggleVisibility: () {
                  setState(() => _passwordVisible = !_passwordVisible);
                },
              ),
              CustomTextField(
                labelText: 'Confirm Password',
                hintText: 'Re-enter password',
                controller: _confirmPasswordController,
                obscureText: !_confirmPasswordVisible,
                onToggleVisibility: () {
                  setState(() => _confirmPasswordVisible = !_confirmPasswordVisible);
                },
              ),

              SizedBox(height: 38.h),

              // ✅ Checkbox with state
              Row(
                children: [
                  Checkbox(
                    value: _isChecked,
                    onChanged: (value) => setState(() => _isChecked = value ?? false),
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
                onPressed: _handleSignUp,
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
                    onPressed: () {
                      // TODO: Navigate to sign in screen
                    },
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
