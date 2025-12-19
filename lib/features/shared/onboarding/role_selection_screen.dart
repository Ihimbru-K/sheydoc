import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sheydoc_app/core/constants/app_colors.dart';
import 'package:sheydoc_app/features/auth/doctors/welcome_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAED8E6),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Who are you",
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 40.h),

              // Patient button
              SizedBox(
                width: 207.w,
                height: 45.h,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WelcomeScreen(role: "patient"),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077B6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22.5.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Client",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Doctor button
              SizedBox(
                width: 207.w,
                height: 45.h,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WelcomeScreen(role: "doctor"),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    side: BorderSide(color: AppColors.white, width: 1.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22.5.r),
                    ),
                  ),
                  child: Text(
                    "Doctor",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0077B6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}









// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sheydoc_app/core/constants/app_colors.dart';
// import 'package:sheydoc_app/features/auth/doctors/welcome_screen.dart';
// import 'package:sheydoc_app/features/auth/patients/welcome_screen.dart';
//
// class RoleSelectionScreen extends StatelessWidget {
//   const RoleSelectionScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFAED8E6),
//       body: SafeArea(
//         child: Center( // ✅ Centralizes horizontally + vertically
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 "Who are you",
//                 style: TextStyle(
//                   fontSize: 24.sp, // ✅ Responsive text
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//               SizedBox(height: 40.h), // ✅ Responsive spacing
//
//               // Patient button
//               SizedBox(
//                 width: 207.w,
//                 height: 45.h,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const WelcomeScreen(role: "patient"),
//                       ),
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF0077B6),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(22.5.r), // ✅ Responsive radius
//                     ),
//                     elevation: 0,
//                   ),
//                   child: Text(
//                     "Client",
//                     style: TextStyle(
//                       fontSize: 20.sp, // ✅ Responsive text
//                       fontWeight: FontWeight.w500,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20.h),
//
//               // Doctor button
//               SizedBox(
//                 width: 207.w,
//                 height: 45.h,
//                 child: OutlinedButton(
//                   onPressed: () {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const WelcomeDocScreen(role: "doctor"),
//                       ),
//                     );
//                   },
//                   style: OutlinedButton.styleFrom(
//                     backgroundColor: AppColors.white,
//                     side: BorderSide(color: AppColors.white, width: 1.w), // ✅ Responsive border
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(22.5.r), // ✅ Responsive radius
//                     ),
//                   ),
//                   child: Text(
//                     "Doctor",
//                     style: TextStyle(
//                       fontSize: 20.sp, // ✅ Responsive text
//                       fontWeight: FontWeight.w500,
//                       color: const Color(0xFF0077B6),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
