import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:sheydoc_app/features/auth/doctors/personal_info_screen.dart';
import 'package:sheydoc_app/features/doctor/home/home_screen.dart';


import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../patients/home/home_screen.dart';
import 'approved_screen.dart';
import 'forgot_password_input_email_screen.dart';

class SignInDocScreen extends StatefulWidget {
  final String role;

  const SignInDocScreen({super.key, required this.role});

  @override
  State<SignInDocScreen> createState() => _SignInDocScreenState();
}

class _SignInDocScreenState extends State<SignInDocScreen> {
  bool _passwordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _handleSignIn() async {
    setState(() => _loading = true);

    try {
      final user = await AuthService().signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user != null) {
        // Check if user has completed registration
        final userProfile = await AuthService().getUserProfile(user.uid);

        if (userProfile != null) {
          final userRole = userProfile['role'] ?? widget.role;
          final profileComplete = userProfile['profileComplete'] == true;
          final approvalStatus = userProfile['approvalStatus'];

          // Handle Patient Sign In
          if (userRole == "patient") {
            if (profileComplete && approvalStatus == 'approved') {
              // Patient is fully registered - go to Patient Home
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => PatientHomeScreen()),
              );
            } else {
              // Patient registration incomplete - continue registration
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please complete your registration")),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PersonalInfoDocScreen(role: userRole),
                ),
              );
            }
          }
          // Handle Doctor Sign In
          else if (userRole == "doctor") {
            if (profileComplete && approvalStatus == 'approved') {
              // Doctor is fully registered and approved - go to Doctor Home
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => DoctorHomeScreen()),
              );
            } else if (profileComplete) {
              // Doctor registered but awaiting approval
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => ApprovalScreen(role: userRole)),
              );
            } else {
              // Doctor registration incomplete - continue registration
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please complete your registration")),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PersonalInfoDocScreen(role: userRole),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        leading: GestureDetector(
          child: const Icon(Icons.arrow_back_ios),
          onTap: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Sign In',
          style: TextStyle(
            fontSize: 24.sp,
            color: AppColors.textBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 72.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),

                // Email field
                CustomTextField(
                  controller: _emailController,
                  fillColor: AppColors.textfieldBlue,
                  labelText: 'Email',
                  hintText: 'abc@gmail.com',
                ),

                // Password field
                CustomTextField(
                  controller: _passwordController,
                  fillColor: AppColors.textfieldBlue,
                  labelText: 'Password',
                  obscureText: !_passwordVisible,
                  hintText: '•••••••',
                  onToggleVisibility: () {
                    setState(() => _passwordVisible = !_passwordVisible);
                  },
                ),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordDocScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Sign in button
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      _loading ? "Signing in..." : "Sign in",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Register here - goes to registration
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Go directly to registration (PersonalInfoDocScreen)
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PersonalInfoDocScreen(role: widget.role),
                          ),
                        );
                      },
                      child: Text(
                        "Register here",
                        style: TextStyle(
                          color: AppColors.textBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // OR divider
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

                SizedBox(height: 56.h),

                // Alternative sign-in buttons
                _buildAltButton(
                  icon: Icons.email_outlined,
                  text: 'Sign up with email',
                  onPressed: () {}, // TODO
                ),
                SizedBox(height: 32.h),
                _buildAltButton(
                  iconWidget: Image.asset(
                    'assets/images/icons/google.png',
                    width: 24.w,
                    height: 24.h,
                    fit: BoxFit.contain,
                  ),
                  text: 'Sign up with Google',
                  onPressed: () {}, // TODO Google Auth
                ),
                SizedBox(height: 32.h),
                _buildAltButton(
                  icon: Icons.apple,
                  text: 'Sign up with Apple',
                  onPressed: () {}, // TODO Apple Auth
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAltButton({
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
          backgroundColor: AppColors.lightSkyBlue,
          foregroundColor: Colors.black87,
          elevation: 0,
          side: const BorderSide(color: Colors.black12, width: 1),
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
//
// import 'package:sheydoc_app/features/auth/doctors/personal_info_screen.dart';
// import 'package:sheydoc_app/features/doctor/home/home_screen.dart';
//
// import '../../../core/constants/app_colors.dart';
// import '../../../services/auth_service.dart';
// import '../../../shared/widgets/custom_button.dart';
// import '../../../shared/widgets/custom_textfield.dart';
// import 'approved_screen.dart';
// import 'forgot_password_input_email_screen.dart';
//
// class SignInDocScreen extends StatefulWidget {
//   final String role;
//
//   const SignInDocScreen({super.key, required this.role});
//
//   @override
//   State<SignInDocScreen> createState() => _SignInDocScreenState();
// }
//
// class _SignInDocScreenState extends State<SignInDocScreen> {
//   bool _passwordVisible = false;
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _loading = false;
//
//   Future<void> _handleSignIn() async {
//     setState(() => _loading = true);
//
//     try {
//       final user = await AuthService().signInWithEmail(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );
//
//       if (user != null) {
//         // Check if user has completed registration
//         final userProfile = await AuthService().getUserProfile(user.uid);
//
//         if (userProfile != null &&
//             userProfile['profileComplete'] == true &&
//             userProfile['approvalStatus'] == 'approved') {
//           // User is fully registered and approved - go to Home
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => HomeScreen()),
//           );
//         } else if (userProfile != null && userProfile['profileComplete'] == true) {
//           // User registered but awaiting approval
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => ApprovalScreen(role: widget.role)),
//           );
//         } else {
//           // User exists but registration incomplete - continue registration
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Please complete your registration")),
//           );
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (_) => PersonalInfoDocScreen(role: widget.role),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(e.toString())),
//       );
//     } finally {
//       setState(() => _loading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       appBar: AppBar(
//         backgroundColor: AppColors.backgroundColor,
//         leading: GestureDetector(
//           child: const Icon(Icons.arrow_back_ios),
//           onTap: () => Navigator.pop(context),
//         ),
//         centerTitle: true,
//         title: Text(
//           'Sign In',
//           style: TextStyle(
//             fontSize: 24.sp,
//             color: AppColors.textBlue,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 72.h),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: 40.h),
//
//                 // Email field
//                 CustomTextField(
//                   controller: _emailController,
//                   fillColor: AppColors.textfieldBlue,
//                   labelText: 'Email',
//                   hintText: 'abc@gmail.com',
//                 ),
//
//                 // Password field
//                 CustomTextField(
//                   controller: _passwordController,
//                   fillColor: AppColors.textfieldBlue,
//                   labelText: 'Password',
//                   obscureText: !_passwordVisible,
//                   hintText: '•••••••',
//                   onToggleVisibility: () {
//                     setState(() => _passwordVisible = !_passwordVisible);
//                   },
//                 ),
//
//                 // Forgot Password
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => ForgotPasswordDocScreen(),
//                         ),
//                       );
//                     },
//                     child: Text(
//                       'Forgot Password?',
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         color: AppColors.primaryBlue,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(height: 24.h),
//
//                 // Sign in button
//                 SizedBox(
//                   width: double.infinity,
//                   height: 48.h,
//                   child: ElevatedButton(
//                     onPressed: _loading ? null : _handleSignIn,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.primaryBlue,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10.r),
//                       ),
//                     ),
//                     child: Text(
//                       _loading ? "Signing in..." : "Sign in",
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(height: 16.h),
//
//                 // ✅ FIXED: Register here goes directly to PersonalInfoDocScreen
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       "Don't have an account? ",
//                       style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         // Go directly to registration (PersonalInfoDocScreen)
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => PersonalInfoDocScreen(role: widget.role),
//                           ),
//                         );
//                       },
//                       child: Text(
//                         "Register here",
//                         style: TextStyle(
//                           color: AppColors.textBlue,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w400,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 SizedBox(height: 24.h),
//
//                 // OR divider
//                 Row(
//                   children: [
//                     const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
//                     Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 16.w),
//                       child: Text(
//                         'or',
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 14.sp,
//                         ),
//                       ),
//                     ),
//                     const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
//                   ],
//                 ),
//
//                 SizedBox(height: 56.h),
//
//                 // Alternative sign-in buttons
//                 _buildAltButton(
//                   icon: Icons.email_outlined,
//                   text: 'Sign up with email',
//                   onPressed: () {}, // TODO
//                 ),
//                 SizedBox(height: 32.h),
//                 _buildAltButton(
//                   iconWidget: Image.asset(
//                     'assets/images/icons/google.png',
//                     width: 24.w,
//                     height: 24.h,
//                     fit: BoxFit.contain,
//                   ),
//                   text: 'Sign up with Google',
//                   onPressed: () {}, // TODO Google Auth
//                 ),
//                 SizedBox(height: 32.h),
//                 _buildAltButton(
//                   icon: Icons.apple,
//                   text: 'Sign up with Apple',
//                   onPressed: () {}, // TODO Apple Auth
//                 ),
//                 SizedBox(height: 20.h),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAltButton({
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
//           backgroundColor: AppColors.lightSkyBlue,
//           foregroundColor: Colors.black87,
//           elevation: 0,
//           side: const BorderSide(color: Colors.black12, width: 1),
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
//
// import 'package:sheydoc_app/features/auth/doctors/personal_info_screen.dart';
// import 'package:sheydoc_app/features/auth/doctors/welcome_screen.dart';
// import 'package:sheydoc_app/features/doctor/home/home_screen.dart'; // Add this import
//
// import '../../../core/constants/app_colors.dart';
// import '../../../services/auth_service.dart';
// import '../../../shared/widgets/custom_button.dart';
// import '../../../shared/widgets/custom_textfield.dart';
// import 'approved_screen.dart';
// import 'forgot_password_input_email_screen.dart';
//
// class SignInDocScreen extends StatefulWidget {
//   final String role;
//
//   const SignInDocScreen({super.key, required this.role});
//
//   @override
//   State<SignInDocScreen> createState() => _SignInDocScreenState();
// }
//
// class _SignInDocScreenState extends State<SignInDocScreen> {
//   bool _passwordVisible = false;
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _loading = false;
//
//   Future<void> _handleSignIn() async {
//     setState(() => _loading = true);
//
//     try {
//       final user = await AuthService().signInWithEmail(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );
//
//       if (user != null) {
//         // ✅ FIXED: Check if user has completed registration
//         final userProfile = await AuthService().getUserProfile(user.uid);
//
//         if (userProfile != null &&
//             userProfile['profileComplete'] == true &&
//             userProfile['approvalStatus'] == 'approved') {
//           // User is fully registered and approved - go to Home
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => HomeScreen()),
//           );
//         } else if (userProfile != null && userProfile['profileComplete'] == true) {
//           // User registered but awaiting approval
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => ApprovalScreen(role: widget.role)),
//           );
//         } else {
//           // User exists but registration incomplete - continue registration
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Please complete your registration")),
//           );
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (_) => PersonalInfoDocScreen(role: widget.role),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(e.toString())),
//       );
//     } finally {
//       setState(() => _loading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       appBar: AppBar(
//         backgroundColor: AppColors.backgroundColor,
//         leading: GestureDetector(
//           child: const Icon(Icons.arrow_back_ios),
//           onTap: () => Navigator.pop(context),
//         ),
//         centerTitle: true,
//         title: Text(
//           'Sign In',
//           style: TextStyle(
//             fontSize: 24.sp,
//             color: AppColors.textBlue,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 72.h),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: 40.h),
//
//                 // Email field
//                 CustomTextField(
//                   controller: _emailController,
//                   fillColor: AppColors.textfieldBlue,
//                   labelText: 'Email',
//                   hintText: 'abc@gmail.com',
//                 ),
//
//                 // Password field
//                 CustomTextField(
//                   controller: _passwordController,
//                   fillColor: AppColors.textfieldBlue,
//                   labelText: 'Password',
//                   obscureText: !_passwordVisible,
//                   hintText: '•••••••',
//                   onToggleVisibility: () {
//                     setState(() => _passwordVisible = !_passwordVisible);
//                   },
//                 ),
//
//                 // Forgot Password
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => ForgotPasswordDocScreen(),
//                         ),
//                       );
//                     },
//                     child: Text(
//                       'Forgot Password?',
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         color: AppColors.primaryBlue,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(height: 24.h),
//
//                 // Sign in button
//                 SizedBox(
//                   width: double.infinity,
//                   height: 48.h,
//                   child: ElevatedButton(
//                     onPressed: _loading ? null : _handleSignIn,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.primaryBlue,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10.r),
//                       ),
//                     ),
//                     child: Text(
//                       _loading ? "Signing in..." : "Sign in",
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(height: 16.h),
//
//                 // ✅ FIXED: Sign up redirect goes back to Welcome screen
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       "Don't have an account? ",
//                       style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         // Go back to Welcome screen to start fresh registration
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => WelcomeDocScreen(role: widget.role),
//                           ),
//                         );
//                       },
//                       child: Text(
//                         "Register here",
//                         style: TextStyle(
//                           color: AppColors.textBlue,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w400,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 SizedBox(height: 24.h),
//
//                 // OR divider
//                 Row(
//                   children: [
//                     const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
//                     Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 16.w),
//                       child: Text(
//                         'or',
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 14.sp,
//                         ),
//                       ),
//                     ),
//                     const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
//                   ],
//                 ),
//
//                 SizedBox(height: 56.h),
//
//                 // Alternative sign-in buttons
//                 _buildAltButton(
//                   icon: Icons.email_outlined,
//                   text: 'Sign up with email',
//                   onPressed: () {}, // TODO
//                 ),
//                 SizedBox(height: 32.h),
//                 _buildAltButton(
//                   iconWidget: Image.asset(
//                     'assets/images/icons/google.png',
//                     width: 24.w,
//                     height: 24.h,
//                     fit: BoxFit.contain,
//                   ),
//                   text: 'Sign up with Google',
//                   onPressed: () {}, // TODO Google Auth
//                 ),
//                 SizedBox(height: 32.h),
//                 _buildAltButton(
//                   icon: Icons.apple,
//                   text: 'Sign up with Apple',
//                   onPressed: () {}, // TODO Apple Auth
//                 ),
//                 SizedBox(height: 20.h),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAltButton({
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
//           backgroundColor: AppColors.lightSkyBlue,
//           foregroundColor: Colors.black87,
//           elevation: 0,
//           side: const BorderSide(color: Colors.black12, width: 1),
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
//
// import 'package:sheydoc_app/features/auth/doctors/personal_info_screen.dart';
//
// import '../../../core/constants/app_colors.dart';
// import '../../../services/auth_service.dart';
// import '../../../shared/widgets/custom_button.dart';
// import '../../../shared/widgets/custom_textfield.dart';
// import 'forgot_password_input_email_screen.dart';
//
// class SignInDocScreen extends StatefulWidget {
//   final String role; // 👈 doctor/patient
//
//   const SignInDocScreen({super.key, required this.role});
//
//   @override
//   State<SignInDocScreen> createState() => _SignInDocScreenState();
// }
//
// class _SignInDocScreenState extends State<SignInDocScreen> {
//   bool _passwordVisible = false;
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _loading = false;
//
//   Future<void> _handleSignIn() async {
//     setState(() => _loading = true);
//
//     try {
//       final user = await AuthService().signInWithEmail(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );
//
//       if (user != null) {
//         // ✅ Go to Personal Info after login
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => PersonalInfoDocScreen(role: widget.role),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(e.toString())),
//       );
//     } finally {
//       setState(() => _loading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       appBar: AppBar(
//         backgroundColor: AppColors.backgroundColor,
//         leading: GestureDetector(
//           child: const Icon(Icons.arrow_back_ios),
//           onTap: () => Navigator.pop(context),
//         ),
//         centerTitle: true,
//         title: Text(
//           'Sign In',
//           style: TextStyle(
//             fontSize: 24.sp,
//             color: AppColors.textBlue,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 72.h),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: 40.h),
//
//                 // Email field
//                 CustomTextField(
//                   controller: _emailController,
//                   fillColor: AppColors.textfieldBlue,
//                   labelText: 'Email',
//                   hintText: 'abc@gmail.com',
//                 ),
//
//                 // Password field
//                 CustomTextField(
//                   controller: _passwordController,
//                   fillColor: AppColors.textfieldBlue,
//                   labelText: 'Password',
//                   obscureText: !_passwordVisible,
//                   hintText: '•••••••',
//                   onToggleVisibility: () {
//                     setState(() => _passwordVisible = !_passwordVisible);
//                   },
//                 ),
//
//                 // Forgot Password
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => ForgotPasswordDocScreen(),
//                         ),
//                       );
//                     },
//                     child: Text(
//                       'Forgot Password?',
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         color: AppColors.primaryBlue,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(height: 24.h),
//
//                 // Sign in button (no custom button, just works)
//                 SizedBox(
//                   width: double.infinity,
//                   height: 48.h,
//                   child: ElevatedButton(
//                     onPressed: _loading ? null : _handleSignIn,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.primaryBlue,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10.r),
//                       ),
//                     ),
//                     child: Text(
//                       _loading ? "Signing in..." : "Sign in",
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//
//
//
//                 SizedBox(height: 16.h),
//
//                 // Sign up redirect
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       "Don't have an account? ",
//                       style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         // 📝 Go to registration (Personal Info first step)
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) =>
//                                 PersonalInfoDocScreen(role: widget.role),
//                           ),
//                         );
//                       },
//                       child: Text(
//                         "Register here",
//                         style: TextStyle(
//                           color: AppColors.textBlue,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w400,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 SizedBox(height: 24.h),
//
//                 // OR divider
//                 Row(
//                   children: [
//                     const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
//                     Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 16.w),
//                       child: Text(
//                         'or',
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 14.sp,
//                         ),
//                       ),
//                     ),
//                     const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
//                   ],
//                 ),
//
//                 SizedBox(height: 56.h),
//
//                 // Alternative sign-in buttons
//                 _buildAltButton(
//                   icon: Icons.email_outlined,
//                   text: 'Sign up with email',
//                   onPressed: () {}, // TODO
//                 ),
//                 SizedBox(height: 32.h),
//                 _buildAltButton(
//                   iconWidget: Image.asset(
//                     'assets/images/icons/google.png',
//                     width: 24.w,
//                     height: 24.h,
//                     fit: BoxFit.contain,
//                   ),
//                   text: 'Sign up with Google',
//                   onPressed: () {}, // TODO Google Auth
//                 ),
//                 SizedBox(height: 32.h),
//                 _buildAltButton(
//                   icon: Icons.apple,
//                   text: 'Sign up with Apple',
//                   onPressed: () {}, // TODO Apple Auth
//                 ),
//                 SizedBox(height: 20.h),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAltButton({
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
//           backgroundColor: AppColors.lightSkyBlue,
//           foregroundColor: Colors.black87,
//           elevation: 0,
//           side: const BorderSide(color: Colors.black12, width: 1),
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
