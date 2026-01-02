import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sheydoc_app/core/constants/app_colors.dart';

import '../admin/services/admin_services.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _codeController = TextEditingController();
  final _adminAuthService = AdminAuthService();
  bool _isLoading = false;
  bool _obscureCode = true;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter admin code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final adminUser = await _adminAuthService.signInAsAdmin(code);

      if (adminUser != null && mounted) {
        // Navigate to admin dashboard
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Admin icon
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 80.sp,
                    color: AppColors.primaryBlue,
                  ),
                ),

                SizedBox(height: 32.h),

                // Title
                Text(
                  'Admin Access',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: 8.h),

                Text(
                  'Enter your admin code to continue',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                ),

                SizedBox(height: 48.h),

                // Code input field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _codeController,
                    obscureText: _obscureCode,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Enter Admin Code',
                      hintStyle: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[400],
                        letterSpacing: 1,
                      ),
                      prefixIcon: Icon(
                        Icons.lock,
                        color: AppColors.primaryBlue,
                        size: 24.sp,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCode ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[600],
                          size: 24.sp,
                        ),
                        onPressed: () {
                          setState(() => _obscureCode = !_obscureCode);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 20.h,
                      ),
                    ),
                    onSubmitted: (_) => _handleAdminLogin(),
                  ),
                ),

                SizedBox(height: 32.h),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAdminLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? SizedBox(
                      height: 24.h,
                      width: 24.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login, color: Colors.white),
                        SizedBox(width: 12.w),
                        Text(
                          'Access Dashboard',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Back button
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Role Selection'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),

                SizedBox(height: 32.h),

                // Security notice
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber[700],
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'This area is restricted to authorized administrators only',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sheydoc_app/core/constants/app_colors.dart';
// import 'package:sheydoc_app/features/admin/dashboard/admin_dashboard_screen.dart';
//
// class AdminLoginScreen extends StatefulWidget {
//   const AdminLoginScreen({super.key});
//
//   @override
//   State<AdminLoginScreen> createState() => _AdminLoginScreenState();
// }
//
// class _AdminLoginScreenState extends State<AdminLoginScreen> {
//   final _codeController = TextEditingController();
//   bool _obscureCode = true;
//   bool _loading = false;
//
//   // Secret admin code - In production, store this securely (e.g., Firebase Remote Config)
//   static const String _adminCode = "SHEYDOC2026";
//
//   @override
//   void dispose() {
//     _codeController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _handleAdminLogin() async {
//     final enteredCode = _codeController.text.trim();
//
//     if (enteredCode.isEmpty) {
//       _showError("Please enter admin code");
//       return;
//     }
//
//     setState(() => _loading = true);
//
//     // Simulate network delay
//     await Future.delayed(const Duration(seconds: 1));
//
//     if (enteredCode == _adminCode) {
//       // Success - Navigate to Admin Dashboard
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const AdminDashboardScreen(),
//           ),
//         );
//       }
//     } else {
//       // Failed - Show error
//       if (mounted) {
//         _showError("Invalid admin code");
//         setState(() => _loading = false);
//       }
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       appBar: AppBar(
//         backgroundColor: AppColors.backgroundColor,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 30.w),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               // Lock icon
//               Container(
//                 padding: EdgeInsets.all(24.w),
//                 decoration: BoxDecoration(
//                   color: AppColors.primaryBlue.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.admin_panel_settings,
//                   size: 80.sp,
//                   color: AppColors.primaryBlue,
//                 ),
//               ),
//
//               SizedBox(height: 40.h),
//
//               Text(
//                 'Admin Access',
//                 style: TextStyle(
//                   fontSize: 28.sp,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.textBlue,
//                 ),
//               ),
//
//               SizedBox(height: 8.h),
//
//               Text(
//                 'Enter your admin code to continue',
//                 style: TextStyle(
//                   fontSize: 14.sp,
//                   color: Colors.grey[600],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//
//               SizedBox(height: 48.h),
//
//               // Admin Code Input
//               TextField(
//                 controller: _codeController,
//                 obscureText: _obscureCode,
//                 style: TextStyle(
//                   fontSize: 18.sp,
//                   fontWeight: FontWeight.w600,
//                   letterSpacing: 4,
//                 ),
//                 textAlign: TextAlign.center,
//                 decoration: InputDecoration(
//                   hintText: 'Enter Code',
//                   filled: true,
//                   fillColor: AppColors.textfieldBlue,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.r),
//                     borderSide: BorderSide.none,
//                   ),
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _obscureCode ? Icons.visibility_off : Icons.visibility,
//                       color: Colors.grey,
//                     ),
//                     onPressed: () {
//                       setState(() => _obscureCode = !_obscureCode);
//                     },
//                   ),
//                 ),
//                 onSubmitted: (_) => _handleAdminLogin(),
//               ),
//
//               SizedBox(height: 32.h),
//
//               // Login Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 50.h,
//                 child: ElevatedButton(
//                   onPressed: _loading ? null : _handleAdminLogin,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primaryBlue,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12.r),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: _loading
//                       ? SizedBox(
//                     height: 20.h,
//                     width: 20.w,
//                     child: const CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   )
//                       : Text(
//                     'Access Dashboard',
//                     style: TextStyle(
//                       fontSize: 16.sp,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: 24.h),
//
//               // Security notice
//               Container(
//                 padding: EdgeInsets.all(12.w),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8.r),
//                   border: Border.all(
//                     color: Colors.orange.withOpacity(0.3),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.security,
//                       size: 20.sp,
//                       color: Colors.orange[700],
//                     ),
//                     SizedBox(width: 12.w),
//                     Expanded(
//                       child: Text(
//                         'This area is restricted to authorized administrators only',
//                         style: TextStyle(
//                           fontSize: 11.sp,
//                           color: Colors.orange[700],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }