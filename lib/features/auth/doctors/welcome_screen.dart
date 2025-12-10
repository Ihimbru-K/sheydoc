import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sheydoc_app/features/auth/doctors/signin_screen.dart';
import 'package:sheydoc_app/features/auth/doctors/personal_info_screen.dart';
import 'package:sheydoc_app/features/auth/doctors/signin_with_phone_number_screen.dart';

import '../../../core/constants/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  final String role;

  const WelcomeScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 80.h),


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
                height: 200.h,
                width: 200.w,
              ),

              // Sign up with phone number
              _buildSignUpButton(
                icon: Icons.phone_android_outlined,
                text: '    Sign up with phone number',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PhoneSignInDocScreen(role: role),
                    ),
                  );
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

              // Sign up with email - goes to REGISTRATION
              _buildSignUpButton(
                icon: Icons.email_outlined,
                text: 'Sign up with email',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonalInfoDocScreen(role: role),
                    ),
                  );
                },
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
                onPressed: () {
                  // TODO: integrate Firebase Google sign-in
                },
              ),

              SizedBox(height: 60.h),

              // "Already have account" goes to SIGN IN
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignInDocScreen(role: role),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                    ),
                    Text(
                      "Log in",
                      style: TextStyle(
                        color: AppColors.textBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              )
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
          side: const BorderSide(color: Colors.grey, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Row(
          children: [
            if (iconWidget != null)
              iconWidget
            else if (icon != null)
              Icon(icon, size: 20.sp, color: Colors.black87),
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
          ],
        ),
      ),
    );
  }
}







// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sheydoc_app/features/auth/doctors/signin_screen.dart';
// import 'package:sheydoc_app/features/auth/doctors/personal_info_screen.dart'; // ADD THIS
// import 'package:sheydoc_app/features/auth/doctors/signin_with_phone_number_screen.dart';
//
// import '../../../core/constants/app_colors.dart';
//
// class WelcomeDocScreen extends StatelessWidget {
//   final String role;
//
//   const WelcomeDocScreen({super.key, required this.role});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 24.w),
//           child: Column(
//             children: [
//               SizedBox(height: 80.h),
//
//               // Welcome text
//               Text(
//                 'Welcome to',
//                 style: TextStyle(
//                   fontSize: 24.sp,
//                   color: AppColors.textBlue,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//
//               SizedBox(height: 22.h),
//
//               // Logo
//               Image.asset(
//                 'assets/images/logos/logo.png',
//                 height: 200.h,
//                 width: 200.w,
//               ),
//
//               // Sign up with phone number
//               _buildSignUpButton(
//                 icon: Icons.phone_android_outlined,
//                 text: '    Sign up with phone number',
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) =>
//                           PhoneSignInDocScreen(role: role),
//                     ),
//                   );
//                 },
//               ),
//
//               SizedBox(height: 16.h),
//
//               // Separator
//               Row(
//                 children: [
//                   const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 16.w),
//                     child: Text(
//                       'or',
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                         fontSize: 14.sp,
//                       ),
//                     ),
//                   ),
//                   const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
//                 ],
//               ),
//
//               SizedBox(height: 16.h),
//
//               // ✅ FIXED: Sign up with email goes to REGISTRATION (PersonalInfoDocScreen)
//               _buildSignUpButton(
//                 icon: Icons.email_outlined,
//                 text: 'Sign up with email',
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => PersonalInfoDocScreen(role: role), // REGISTRATION
//                     ),
//                   );
//                 },
//               ),
//
//               SizedBox(height: 32.h),
//
//               // Sign up with Google
//               _buildSignUpButton(
//                 iconWidget: Image.asset(
//                   'assets/images/icons/google.png',
//                   width: 24.w,
//                   height: 24.h,
//                   fit: BoxFit.contain,
//                 ),
//                 text: 'Sign up with Google',
//                 onPressed: () {
//                   // later integrate Firebase Google sign-in
//                 },
//               ),
//
//               SizedBox(height: 60.h),
//
//               // ✅ "Already have account" goes to SIGN IN
//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => SignInDocScreen(role: role), // SIGN IN
//                     ),
//                   );
//                 },
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       "Already have an account? ",
//                       style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
//                     ),
//                     Text(
//                       "Log in",
//                       style: TextStyle(
//                         color: AppColors.textBlue,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSignUpButton({
//     IconData? icon,
//     Widget? iconWidget,
//     required String text,
//     required VoidCallback onPressed,
//   }) {
//     return SizedBox(
//       width: double.infinity,
//       height: 52.h,
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.textfieldBlue,
//           foregroundColor: Colors.black87,
//           elevation: 0,
//           side: const BorderSide(color: Colors.grey, width: 1),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8.r),
//           ),
//         ),
//         child: Row(
//           children: [
//             if (iconWidget != null)
//               iconWidget
//             else if (icon != null)
//               Icon(icon, size: 20.sp, color: Colors.black87),
//             Expanded(
//               child: Text(
//                 text,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.black87,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }






































// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sheydoc_app/features/auth/doctors/signin_screen.dart';
// import 'package:sheydoc_app/features/auth/doctors/signin_with_phone_number_screen.dart';
//
// import '../../../core/constants/app_colors.dart';
//
// class WelcomeDocScreen extends StatelessWidget {
//   final String role; // 👈 Add role (doctor)
//
//   const WelcomeDocScreen({super.key, required this.role});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 24.w),
//           child: Column(
//             children: [
//               SizedBox(height: 80.h),
//
//               // Welcome text
//               Text(
//                 'Welcome to',
//                 style: TextStyle(
//                   fontSize: 24.sp,
//                   color: AppColors.textBlue,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//
//               SizedBox(height: 22.h),
//
//               // Logo
//               Image.asset(
//                 'assets/images/logos/logo.png',
//                 height: 200.h,
//                 width: 200.w,
//               ),
//
//               // Sign up with phone number
//               _buildSignUpButton(
//                 icon: Icons.phone_android_outlined,
//                 text: '    Sign up with phone number',
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) =>
//                           PhoneSignInDocScreen(role: role), // 👈 pass role
//                     ),
//                   );
//                 },
//               ),
//
//               SizedBox(height: 16.h),
//
//               // Separator
//               Row(
//                 children: [
//                   const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 16.w),
//                     child: Text(
//                       'or',
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                         fontSize: 14.sp,
//                       ),
//                     ),
//                   ),
//                   const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
//                 ],
//               ),
//
//               SizedBox(height: 16.h),
//
//               // Sign up with email
//               _buildSignUpButton(
//                 icon: Icons.email_outlined,
//                 text: 'Sign up with email',
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => SignInDocScreen(role: role), // 👈 pass role
//                     ),
//                   );
//                 },
//               ),
//
//               SizedBox(height: 32.h),
//
//               // Sign up with Google
//               _buildSignUpButton(
//                 iconWidget: Image.asset(
//                   'assets/images/icons/google.png',
//                   width: 24.w,
//                   height: 24.h,
//                   fit: BoxFit.contain,
//                 ),
//                 text: 'Sign up with Google',
//                 onPressed: () {
//                   // later integrate Firebase Google sign-in
//                 },
//               ),
//
//               SizedBox(height: 60.h),
//
//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => SignInDocScreen(role: role),
//                     ),
//                   );
//                 },
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       "Already have an account? ",
//                       style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
//                     ),
//                     Text(
//                       "Log in",
//                       style: TextStyle(
//                         color: AppColors.textBlue,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSignUpButton({
//     IconData? icon,
//     Widget? iconWidget,
//     required String text,
//     required VoidCallback onPressed,
//   }) {
//     return SizedBox(
//       width: double.infinity,
//       height: 52.h,
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.textfieldBlue,
//           foregroundColor: Colors.black87,
//           elevation: 0,
//           side: const BorderSide(color: Colors.grey, width: 1),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8.r),
//           ),
//         ),
//         child: Row(
//           children: [
//             if (iconWidget != null)
//               iconWidget
//             else if (icon != null)
//               Icon(icon, size: 20.sp, color: Colors.black87),
//             Expanded(
//               child: Text(
//                 text,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.black87,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
