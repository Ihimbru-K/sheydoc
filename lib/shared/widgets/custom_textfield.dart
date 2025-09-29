import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final VoidCallback? onToggleVisibility;
  final Color? fillColor;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged; // ✅ NEW

  const CustomTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.controller,
    this.onToggleVisibility,
    this.fillColor,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged, // ✅ NEW
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textFieldTextColor,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged, // ✅ Pass it through
          style: TextStyle(fontSize: 16.sp, color: AppColors.black),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: fillColor ?? AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
            suffixIcon: onToggleVisibility != null
                ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: onToggleVisibility,
            )
                : null,
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}
















// import 'package:flutter/material.dart';
//
// class CustomTextField extends StatelessWidget {
//   final TextEditingController controller;
//   final String labelText;
//   final TextInputType keyboardType;
//   final Color? fillColor;
//   final ValueChanged<String>? onChanged; // 👈 add this
//   final bool obscureText;
//
//   const CustomTextField({
//     Key? key,
//     required this.controller,
//     required this.labelText,
//     this.keyboardType = TextInputType.text,
//     this.fillColor,
//     this.onChanged, // 👈 add this
//     this.obscureText = false,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       controller: controller,
//       keyboardType: keyboardType,
//       obscureText: obscureText,
//       onChanged: onChanged, // 👈 wire it up
//       decoration: InputDecoration(
//         labelText: labelText,
//         filled: true,
//         fillColor: fillColor,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
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
// // import 'package:flutter/material.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// //
// // import '../../core/constants/app_colors.dart';
// //
// // class CustomTextField extends StatelessWidget {
// //   final String labelText;
// //   final String? hintText;
// //   final bool obscureText;
// //   final TextEditingController? controller;
// //   final VoidCallback? onToggleVisibility;
// //   final Color? fillColor;
// //   final TextInputType keyboardType;
// //   final String? Function(String?)? validator;
// //
// //   const CustomTextField({
// //     super.key,
// //     required this.labelText,
// //     this.hintText,
// //     this.obscureText = false,
// //     this.controller,
// //     this.onToggleVisibility,
// //     this.fillColor,
// //     this.keyboardType = TextInputType.text,
// //     this.validator,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           labelText,
// //           style: TextStyle(
// //             fontSize: 14.sp,
// //             color: AppColors.textFieldTextColor,
// //             fontWeight: FontWeight.w400,
// //           ),
// //         ),
// //         SizedBox(height: 8.h),
// //         TextFormField(
// //           controller: controller,
// //           obscureText: obscureText,
// //           keyboardType: keyboardType,
// //           validator: validator,
// //           style: TextStyle(fontSize: 16.sp, color: AppColors.black),
// //           decoration: InputDecoration(
// //             hintText: hintText,
// //             hintStyle: TextStyle(color: Colors.grey[400]),
// //             filled: true,
// //             fillColor: fillColor ?? AppColors.white,
// //             border: OutlineInputBorder(
// //               borderRadius: BorderRadius.circular(8.r),
// //               borderSide: BorderSide.none,
// //             ),
// //             suffixIcon: onToggleVisibility != null
// //                 ? IconButton(
// //               icon: Icon(
// //                 obscureText ? Icons.visibility_off : Icons.visibility,
// //                 color: Colors.grey,
// //               ),
// //               onPressed: onToggleVisibility,
// //             )
// //                 : null,
// //           ),
// //         ),
// //         SizedBox(height: 16.h),
// //       ],
// //     );
// //   }
// // }
