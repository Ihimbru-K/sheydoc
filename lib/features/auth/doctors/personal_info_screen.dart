import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sheydoc_app/features/auth/doctors/professional_info_screen.dart';
import 'package:sheydoc_app/features/auth/doctors/signin_screen.dart';
 // Import patient home
import 'package:sheydoc_app/features/doctor/home/home_screen.dart'; // Import doctor home

import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../patients/home/home_screen.dart';

class PersonalInfoDocScreen extends StatefulWidget {
  final String role;

  const PersonalInfoDocScreen({super.key, required this.role});

  @override
  State<PersonalInfoDocScreen> createState() => _PersonalInfoDocScreenState();
}

class _PersonalInfoDocScreenState extends State<PersonalInfoDocScreen> {
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _acceptedTerms = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _loading = false;

  Future<void> _onNext() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept the Terms & Privacy Policy")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await AuthService().signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: widget.role,
      );

      if (user != null) {
        // Save basic personal info with role-specific completion status
        await AuthService().saveUserProfile(
          uid: user.uid,
          data: {
            "name": _nameController.text.trim(),
            "phone": _phoneController.text.trim(),
            "role": widget.role,
            "personalInfoComplete": true,
            // For patients, mark profile as complete since they don't need additional steps
            "profileComplete": widget.role == "patient" ? true : false,
            // Patients are auto-approved, doctors need approval
            "approvalStatus": widget.role == "patient" ? "approved" : "pending",
          },
        );

        // Navigate based on role
        if (widget.role == "patient") {
          // Patient goes directly to their home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PatientHomeScreen(), // Navigate to patient home
            ),
          );
        } else {
          // Doctor continues to professional info
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProfessionalInfoScreenAdvanced(role: widget.role),
            ),
          );
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
          'Personal information',
          style: TextStyle(
            fontSize: 22.sp,
            color: AppColors.textBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 32.h),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20.h),

                  // Avatar + upload
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40.r,
                          backgroundColor: Colors.grey[200],
                          child: Icon(
                            Icons.person,
                            size: 60.sp,
                            color: Colors.grey[400],
                          ),
                        ),
                        Positioned(
                          bottom: 5.h,
                          right: 0,
                          child: CircleAvatar(
                            radius: 15.r,
                            backgroundColor: AppColors.primaryBlue,
                            child: Icon(
                              Icons.camera_alt,
                              size: 18.sp,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40.h),

                  CustomTextField(
                    controller: _nameController,
                    fillColor: AppColors.textfieldBlue,
                    labelText: 'Full Name',
                    validator: (val) => val!.isEmpty ? "Enter your name" : null,
                  ),
                  CustomTextField(
                    controller: _emailController,
                    fillColor: AppColors.textfieldBlue,
                    labelText: 'Email Address',
                    validator: (val) =>
                    val!.contains("@") ? null : "Enter a valid email",
                  ),
                  CustomTextField(
                    controller: _phoneController,
                    fillColor: AppColors.textfieldBlue,
                    labelText: 'Phone Number',
                    validator: (val) =>
                    val!.length < 7 ? "Enter valid phone number" : null,
                  ),
                  CustomTextField(
                    controller: _passwordController,
                    fillColor: AppColors.textfieldBlue,
                    labelText: 'Password',
                    obscureText: !_passwordVisible,
                    onToggleVisibility: () {
                      setState(() => _passwordVisible = !_passwordVisible);
                    },
                    validator: (val) =>
                    val!.length < 6 ? "Password too short" : null,
                  ),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    fillColor: AppColors.textfieldBlue,
                    labelText: 'Confirm Password',
                    obscureText: !_confirmPasswordVisible,
                    onToggleVisibility: () {
                      setState(() =>
                      _confirmPasswordVisible = !_confirmPasswordVisible);
                    },
                    validator: (val) => val != _passwordController.text
                        ? "Passwords do not match"
                        : null,
                  ),

                  // Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        onChanged: (value) {
                          setState(() => _acceptedTerms = value ?? false);
                        },
                        activeColor: AppColors.primaryBlue,
                      ),
                      Expanded(
                        child: Text(
                          'By Creating an Account, I accept SheyDoc Terms of Use and Privacy Policy',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textBlue,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),
                  CustomButton(
                    text: _loading
                        ? "Creating account..."
                        : (widget.role == "patient" ? "Complete Signup" : "Next"),
                    onPressed: _loading ? null : () => _onNext(),
                    isFilled: true,
                    backgroundColor: AppColors.primaryBlue,
                    textColor: AppColors.white,
                  ),

                  SizedBox(height: 16.h),

                  // Sign in redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Have an Account? ',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    SignInDocScreen(role: widget.role)),
                          );
                        },
                        child: Text(
                          'Sign in here',
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
        ),
      ),
    );
  }
}







// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sheydoc_app/features/auth/doctors/professional_info_screen.dart';
// import 'package:sheydoc_app/features/auth/doctors/signin_screen.dart';
//
// import '../../../core/constants/app_colors.dart';
// import '../../../services/auth_service.dart';
// import '../../../shared/widgets/custom_button.dart';
// import '../../../shared/widgets/custom_textfield.dart';
//
// class PersonalInfoDocScreen extends StatefulWidget {
//   final String role;
//
//   const PersonalInfoDocScreen({super.key, required this.role});
//
//   @override
//   State<PersonalInfoDocScreen> createState() => _PersonalInfoDocScreenState();
// }
//
// class _PersonalInfoDocScreenState extends State<PersonalInfoDocScreen> {
//   bool _passwordVisible = false;
//   bool _confirmPasswordVisible = false;
//   bool _acceptedTerms = false;
//
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
//
//   bool _loading = false;
//
//   Future<void> _onNext() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     if (!_acceptedTerms) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please accept the Terms & Privacy Policy")),
//       );
//       return;
//     }
//
//     setState(() => _loading = true);
//
//     try {
//       final user = await AuthService().signUpWithEmail(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//         role: widget.role,
//       );
//
//       if (user != null) {
//         // Save basic personal info
//         await AuthService().saveUserProfile(
//           uid: user.uid,
//           data: {
//             "name": _nameController.text.trim(),
//             "phone": _phoneController.text.trim(),
//             "personalInfoComplete": true, // Track completion stages
//           },
//         );
//
//         // ✅ FIXED: Go to Professional Info next (proper flow)
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => ProfessionalInfoScreenAdvanced(role: widget.role),
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
//           'Personal information (${widget.role})',
//           style: TextStyle(
//             fontSize: 22.sp,
//             color: AppColors.textBlue,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 32.h),
//           child: SingleChildScrollView(
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   SizedBox(height: 20.h),
//
//                   // Avatar + upload
//                   Center(
//                     child: Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         CircleAvatar(
//                           radius: 40.r,
//                           backgroundColor: Colors.grey[200],
//                           child: Icon(
//                             Icons.person,
//                             size: 60.sp,
//                             color: Colors.grey[400],
//                           ),
//                         ),
//                         Positioned(
//                           bottom: 5.h,
//                           right: 0,
//                           child: CircleAvatar(
//                             radius: 15.r,
//                             backgroundColor: AppColors.primaryBlue,
//                             child: Icon(
//                               Icons.camera_alt,
//                               size: 18.sp,
//                               color: AppColors.white,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   SizedBox(height: 40.h),
//
//                   CustomTextField(
//                     controller: _nameController,
//                     fillColor: AppColors.textfieldBlue,
//                     labelText: 'Full Name',
//                     validator: (val) => val!.isEmpty ? "Enter your name" : null,
//                   ),
//                   CustomTextField(
//                     controller: _emailController,
//                     fillColor: AppColors.textfieldBlue,
//                     labelText: 'Email Address',
//                     validator: (val) =>
//                     val!.contains("@") ? null : "Enter a valid email",
//                   ),
//                   CustomTextField(
//                     controller: _phoneController,
//                     fillColor: AppColors.textfieldBlue,
//                     labelText: 'Phone Number',
//                     validator: (val) =>
//                     val!.length < 7 ? "Enter valid phone number" : null,
//                   ),
//                   CustomTextField(
//                     controller: _passwordController,
//                     fillColor: AppColors.textfieldBlue,
//                     labelText: 'Password',
//                     obscureText: !_passwordVisible,
//                     onToggleVisibility: () {
//                       setState(() => _passwordVisible = !_passwordVisible);
//                     },
//                     validator: (val) =>
//                     val!.length < 6 ? "Password too short" : null,
//                   ),
//                   CustomTextField(
//                     controller: _confirmPasswordController,
//                     fillColor: AppColors.textfieldBlue,
//                     labelText: 'Confirm Password',
//                     obscureText: !_confirmPasswordVisible,
//                     onToggleVisibility: () {
//                       setState(() =>
//                       _confirmPasswordVisible = !_confirmPasswordVisible);
//                     },
//                     validator: (val) => val != _passwordController.text
//                         ? "Passwords do not match"
//                         : null,
//                   ),
//
//                   // Checkbox
//                   Row(
//                     children: [
//                       Checkbox(
//                         value: _acceptedTerms,
//                         onChanged: (value) {
//                           setState(() => _acceptedTerms = value ?? false);
//                         },
//                         activeColor: AppColors.primaryBlue,
//                       ),
//                       Expanded(
//                         child: Text(
//                           'By Creating an Account, I accept SheyDoc Terms of Use and Privacy Policy',
//                           style: TextStyle(
//                             fontSize: 12.sp,
//                             color: AppColors.textBlue,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   SizedBox(height: 24.h),
//                   CustomButton(
//                     text: _loading ? "Creating account..." : "Next",
//                     onPressed: _loading ? null : () => _onNext(),
//                     isFilled: true,
//                     backgroundColor: AppColors.primaryBlue,
//                     textColor: AppColors.white,
//                   ),
//
//                   SizedBox(height: 16.h),
//
//                   // ✅ FIXED: Sign in redirect goes to SignIn screen, not Approval
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Have an Account? ',
//                         style: TextStyle(
//                           fontSize: 14.sp,
//                           color: AppColors.textBlue,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) =>
//                                     SignInDocScreen(role: widget.role)),
//                           );
//                         },
//                         child: Text(
//                           'Sign in here',
//                           style: TextStyle(
//                             fontSize: 14.sp,
//                             color: AppColors.primaryBlue,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//

















// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sheydoc_app/features/auth/doctors/professional_info_screen.dart';
//
// import '../../../core/constants/app_colors.dart';
// import '../../../services/auth_service.dart';
// import '../../../shared/widgets/custom_button.dart';
// import '../../../shared/widgets/custom_textfield.dart';
// import 'approved_screen.dart';
// import 'doctor_availability_ui.dart';
//
// class PersonalInfoDocScreen extends StatefulWidget {
//   final String role; // <-- doctor or patient
//
//   const PersonalInfoDocScreen({super.key, required this.role});
//
//   @override
//   State<PersonalInfoDocScreen> createState() => _PersonalInfoDocScreenState();
// }
//
// class _PersonalInfoDocScreenState extends State<PersonalInfoDocScreen> {
//
//
//
//
//
//
//
//
//
//   bool _passwordVisible = false;
//   bool _confirmPasswordVisible = false;
//   bool _acceptedTerms = false;
//
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
//
//
//
//
// // inside _PersonalInfoDocScreenState
//
//   bool _loading = false;
//
//   Future<void> _onNext() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     if (!_acceptedTerms) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please accept the Terms & Privacy Policy")),
//       );
//       return;
//     }
//
//     setState(() => _loading = true);
//
//     try {
//       final user = await AuthService().signUpWithEmail(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//         role: widget.role,
//       );
//
//       if (user != null) {
//         // Save extra fields
//         await AuthService().saveUserProfile(
//           uid: user.uid,
//           data: {
//             "name": _nameController.text.trim(),
//             "phone": _phoneController.text.trim(),
//           },
//         );
//
//         // ✅ Proceed to next screen
//         // Navigator.pushReplacement(
//         //   context,
//         //   MaterialPageRoute(
//         //     builder: (_) => ProfessionalInfoScreenAdvanced(role: widget.role),
//         //   ),
//         // );
//         Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorAvailabilityScreen(role: widget.role)));
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
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//   // void _onNext() {
//   //   if (_formKey.currentState!.validate() && _acceptedTerms) {
//   //     Navigator.push(
//   //       context,
//   //       MaterialPageRoute(
//   //         builder: (context) => ProfessionalInfoScreenAdvanced(
//   //           role: widget.role, // pass role forward
//   //         ),
//   //       ),
//   //     );
//   //   } else if (!_acceptedTerms) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text("Please accept the Terms & Privacy Policy")),
//   //     );
//   //   }
//   // }
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
//           'Personal information (${widget.role})',
//           style: TextStyle(
//             fontSize: 22.sp,
//             color: AppColors.textBlue,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 32.h),
//           child: SingleChildScrollView(
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   SizedBox(height: 20.h),
//
//                   // Avatar + upload
//                   Center(
//                     child: Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         CircleAvatar(
//                           radius: 40.r,
//                           backgroundColor: Colors.grey[200],
//                           child: Icon(
//                             Icons.person,
//                             size: 60.sp,
//                             color: Colors.grey[400],
//                           ),
//                         ),
//                         Positioned(
//                           bottom: 5.h,
//                           right: 0,
//                           child: CircleAvatar(
//                             radius: 15.r,
//                             backgroundColor: AppColors.primaryBlue,
//                             child: Icon(
//                               Icons.camera_alt,
//                               size: 18.sp,
//                               color: AppColors.white,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   SizedBox(height: 40.h),
//
//                   CustomTextField(
//                     controller: _nameController,
//                     fillColor: AppColors.textfieldBlue,
//                     labelText: 'Full Name',
//                     validator: (val) => val!.isEmpty ? "Enter your name" : null,
//                   ),
//                   CustomTextField(
//                     controller: _emailController,
//                     fillColor: AppColors.textfieldBlue,
//                     labelText: 'Email Address',
//                     validator: (val) =>
//                     val!.contains("@") ? null : "Enter a valid email",
//                   ),
//                   CustomTextField(
//                     controller: _phoneController,
//                     fillColor: AppColors.textfieldBlue,
//                     labelText: 'Phone Number',
//                     validator: (val) =>
//                     val!.length < 7 ? "Enter valid phone number" : null,
//                   ),
//                   CustomTextField(
//                     controller: _passwordController,
//                     fillColor: AppColors.textfieldBlue,
//                     labelText: 'Password',
//                     obscureText: !_passwordVisible,
//                     onToggleVisibility: () {
//                       setState(() => _passwordVisible = !_passwordVisible);
//                     },
//                     validator: (val) =>
//                     val!.length < 6 ? "Password too short" : null,
//                   ),
//                   CustomTextField(
//                     controller: _confirmPasswordController,
//                     fillColor: AppColors.textfieldBlue,
//                     labelText: 'Confirm Password',
//                     obscureText: !_confirmPasswordVisible,
//                     onToggleVisibility: () {
//                       setState(() =>
//                       _confirmPasswordVisible = !_confirmPasswordVisible);
//                     },
//                     validator: (val) => val != _passwordController.text
//                         ? "Passwords do not match"
//                         : null,
//                   ),
//
//                   // Checkbox
//                   Row(
//                     children: [
//                       Checkbox(
//                         value: _acceptedTerms,
//                         onChanged: (value) {
//                           setState(() => _acceptedTerms = value ?? false);
//                         },
//                         activeColor: AppColors.primaryBlue,
//                       ),
//                       Expanded(
//                         child: Text(
//                           'By Creating an Account, I accept SheyDoc Terms of Use and Privacy Policy',
//                           style: TextStyle(
//                             fontSize: 12.sp,
//                             color: AppColors.textBlue,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   SizedBox(height: 24.h),
//                   CustomButton(
//                     text: _loading ? "Creating account..." : "Next",
//                     onPressed: _loading ? null : () => _onNext(),
//                     isFilled: true,
//                     backgroundColor: AppColors.primaryBlue,
//                     textColor: AppColors.white,
//                   ),
//
//
//
//                   // CustomButton(
//                   //   text: 'Next',
//                   //   onPressed: _onNext,
//                   //   isFilled: true,
//                   //   backgroundColor: AppColors.primaryBlue,
//                   //   textColor: AppColors.white,
//                   // ),
//
//                   SizedBox(height: 16.h),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Have an Account? ',
//                         style: TextStyle(
//                           fontSize: 14.sp,
//                           color: AppColors.textBlue,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) =>
//                                     ApprovalScreen(role: widget.role)),
//                           );
//                         },
//                         child: Text(
//                           'Sign in here',
//                           style: TextStyle(
//                             fontSize: 14.sp,
//                             color: AppColors.primaryBlue,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // import 'package:sheydoc_app/features/auth/doctors/professional_info_screen.dart';
// //
// // import '../../../core/constants/app_colors.dart';
// // import '../../../shared/widgets/custom_button.dart';
// // import '../../../shared/widgets/custom_textfield.dart';
// // import 'approved_screen.dart';
// //
// // class PersonalInfoDocScreen extends StatefulWidget {
// //   const PersonalInfoDocScreen({super.key});
// //
// //   @override
// //   State<PersonalInfoDocScreen> createState() => _PersonalInfoDocScreenState();
// // }
// //
// // class _PersonalInfoDocScreenState extends State<PersonalInfoDocScreen> {
// //   bool _passwordVisible = false;
// //   bool _confirmPasswordVisible = false;
// //   bool _acceptedTerms = false;
// //
// //   final _formKey = GlobalKey<FormState>();
// //   final _nameController = TextEditingController(text: "Ella bella");
// //   final _emailController = TextEditingController(text: "ellabella@gmail.com");
// //   final _phoneController = TextEditingController(text: "67*******");
// //   final _passwordController = TextEditingController();
// //   final _confirmPasswordController = TextEditingController();
// //
// //   @override
// //   void dispose() {
// //     _nameController.dispose();
// //     _emailController.dispose();
// //     _phoneController.dispose();
// //     _passwordController.dispose();
// //     _confirmPasswordController.dispose();
// //     super.dispose();
// //   }
// //
// //   void _onNext() {
// //     if (_formKey.currentState!.validate() && _acceptedTerms) {
// //       Navigator.push(
// //         context,
// //         MaterialPageRoute(
// //           builder: (context) => const ProfessionalInfoScreenAdvanced(),
// //         ),
// //       );
// //     } else if (!_acceptedTerms) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Please accept the Terms & Privacy Policy")),
// //       );
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: AppColors.backgroundColor,
// //       appBar: AppBar(
// //         backgroundColor: AppColors.backgroundColor,
// //         leading: GestureDetector(
// //           child: const Icon(Icons.arrow_back_ios),
// //           onTap: () => Navigator.pop(context),
// //         ),
// //         centerTitle: true,
// //         title: Text(
// //           'Personal information',
// //           style: TextStyle(
// //             fontSize: 24.sp,
// //             color: AppColors.textBlue,
// //             fontWeight: FontWeight.w700,
// //           ),
// //         ),
// //       ),
// //       body: SafeArea(
// //         child: Padding(
// //           padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 32.h),
// //           child: SingleChildScrollView(
// //             child: Form(
// //               key: _formKey,
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.center,
// //                 children: [
// //                   SizedBox(height: 20.h),
// //                   Center(
// //                     child: Stack(
// //                       alignment: Alignment.center,
// //                       children: [
// //                         CircleAvatar(
// //                           radius: 40.r,
// //                           backgroundColor: Colors.grey[200],
// //                           child: Icon(
// //                             Icons.person,
// //                             size: 60.sp,
// //                             color: Colors.grey[400],
// //                           ),
// //                         ),
// //                         Positioned(
// //                           bottom: 5.h,
// //                           right: 0,
// //                           child: CircleAvatar(
// //                             radius: 15.r,
// //                             backgroundColor: AppColors.primaryBlue,
// //                             child: Icon(
// //                               Icons.camera_alt,
// //                               size: 18.sp,
// //                               color: AppColors.white,
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                   SizedBox(height: 40.h),
// //
// //                   CustomTextField(
// //                     controller: _nameController,
// //                     fillColor: AppColors.textfieldBlue,
// //                     labelText: 'Full Name',
// //                     validator: (val) => val!.isEmpty ? "Enter your name" : null,
// //                   ),
// //                   CustomTextField(
// //                     controller: _emailController,
// //                     fillColor: AppColors.textfieldBlue,
// //                     labelText: 'Email Address',
// //                     validator: (val) =>
// //                     val!.contains("@") ? null : "Enter a valid email",
// //                   ),
// //                   CustomTextField(
// //                     controller: _phoneController,
// //                     fillColor: AppColors.textfieldBlue,
// //                     labelText: 'Phone Number',
// //                     validator: (val) =>
// //                     val!.length < 7 ? "Enter valid phone number" : null,
// //                   ),
// //                   CustomTextField(
// //                     controller: _passwordController,
// //                     fillColor: AppColors.textfieldBlue,
// //                     labelText: 'Password',
// //                     obscureText: !_passwordVisible,
// //                     onToggleVisibility: () {
// //                       setState(() => _passwordVisible = !_passwordVisible);
// //                     },
// //                     validator: (val) =>
// //                     val!.length < 6 ? "Password too short" : null,
// //                   ),
// //                   CustomTextField(
// //                     controller: _confirmPasswordController,
// //                     fillColor: AppColors.textfieldBlue,
// //                     labelText: 'Confirm Password',
// //                     obscureText: !_confirmPasswordVisible,
// //                     onToggleVisibility: () {
// //                       setState(() =>
// //                       _confirmPasswordVisible = !_confirmPasswordVisible);
// //                     },
// //                     validator: (val) => val != _passwordController.text
// //                         ? "Passwords do not match"
// //                         : null,
// //                   ),
// //
// //                   // Checkbox
// //                   Row(
// //                     children: [
// //                       Checkbox(
// //                         value: _acceptedTerms,
// //                         onChanged: (value) {
// //                           setState(() => _acceptedTerms = value ?? false);
// //                         },
// //                         activeColor: AppColors.primaryBlue,
// //                       ),
// //                       Expanded(
// //                         child: Text(
// //                           'By Creating an Account, I accept SheyDoc Terms of Use and Privacy Policy',
// //                           style: TextStyle(
// //                             fontSize: 12.sp,
// //                             color: AppColors.textBlue,
// //                             fontWeight: FontWeight.w400,
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //
// //                   SizedBox(height: 24.h),
// //                   CustomButton(
// //                     text: 'Next',
// //                     onPressed: _onNext,
// //                     isFilled: true,
// //                     backgroundColor: AppColors.primaryBlue,
// //                     textColor: AppColors.white,
// //                   ),
// //
// //                   SizedBox(height: 16.h),
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     children: [
// //                       Text(
// //                         'Have an Account? ',
// //                         style: TextStyle(
// //                           fontSize: 14.sp,
// //                           color: AppColors.textBlue,
// //                           fontWeight: FontWeight.w500,
// //                         ),
// //                       ),
// //                       TextButton(
// //                         onPressed: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(
// //                                 builder: (context) => const ApprovalScreen()),
// //                           );
// //                         },
// //                         child: Text(
// //                           'Sign in here',
// //                           style: TextStyle(
// //                             fontSize: 14.sp,
// //                             color: AppColors.primaryBlue,
// //                             fontWeight: FontWeight.w500,
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
