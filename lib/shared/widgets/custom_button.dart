import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isFilled;


  final double? width;
  final double? height;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed, // <-- nullable now
    this.isFilled = true,
    this.width,
    this.height,
    this.radius = 10,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultWidth = 0.8.sw;
    final defaultHeight = 48.h;

    return SizedBox(
      width: width ?? defaultWidth,
      height: height ?? defaultHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isFilled
              ? (backgroundColor ?? AppColors.primaryBlue)
              : (backgroundColor ?? AppColors.white),
          foregroundColor: textColor ??
              (isFilled ? AppColors.white : AppColors.primaryBlue),
          side: BorderSide(
            color: borderColor ??
                (isFilled ? Colors.transparent : AppColors.primaryBlue),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.r),
          ),
          elevation: 0,
        ),
        onPressed: onPressed, // ✅ works for null + sync
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}







// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import '../../core/constants/app_colors.dart';
//
// class CustomButton extends StatelessWidget {
//   final String text;
//   final VoidCallback onPressed;
//   final bool isFilled;
//
//   // Customizable properties
//   final double? width;
//   final double? height;
//   final double radius;
//   final Color? backgroundColor;
//   final Color? textColor;
//   final Color? borderColor;
//
//   const CustomButton({
//     super.key,
//     required this.text,
//     required this.onPressed,
//     this.isFilled = true,
//     this.width,
//     this.height,
//     this.radius = 10,
//     this.backgroundColor,
//     this.textColor,
//     this.borderColor,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final defaultWidth = 0.8.sw; // 80% of screen width
//     final defaultHeight = 48.h;  // responsive height
//
//     return SizedBox(
//       width: width ?? defaultWidth,
//       height: height ?? defaultHeight,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: isFilled
//               ? (backgroundColor ?? AppColors.primaryBlue)
//               : (backgroundColor ?? AppColors.white),
//           foregroundColor: textColor ??
//               (isFilled ? AppColors.white : AppColors.primaryBlue),
//           side: BorderSide(
//             color: borderColor ??
//                 (isFilled ? Colors.transparent : AppColors.primaryBlue),
//             width: 1.5,
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(radius.r),
//           ),
//           elevation: 0,
//         ),
//         onPressed: onPressed,
//         child: Text(
//           text,
//           style: TextStyle(
//             fontSize: 16.sp,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }
// }
