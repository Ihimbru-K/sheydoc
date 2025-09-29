import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/file_upload_field.dart';
import '../../../services/auth_service.dart';
import 'doctor_availability_ui.dart'; // Import the next screen

class ProfessionalInfoScreenAdvanced extends StatefulWidget {
  final String role;

  const ProfessionalInfoScreenAdvanced({
    super.key,
    required this.role,
  });

  @override
  State<ProfessionalInfoScreenAdvanced> createState() =>
      _ProfessionalInfoScreenAdvancedState();
}

class _ProfessionalInfoScreenAdvancedState
    extends State<ProfessionalInfoScreenAdvanced> {
  String? _specialty;
  String? _country;
  DateTime? _careerStartDate;

  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _licensingController = TextEditingController();

  String? educationCertificate;
  String? authorizationFile;
  String? affiliateHospitalFile;
  String? idCardFile;

  bool _loading = false;

  Future<void> _submitProfessionalInfo() async {
    if (_specialty == null ||
        _country == null ||
        _cityController.text.trim().isEmpty ||
        _careerStartDate == null ||
        _licensingController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("No logged-in user");

      final authService = AuthService();

      // Upload files as base64 strings
      await authService.uploadFileAsBase64(
        uid: uid,
        fieldName: "educationCertificate",
        filePath: educationCertificate,
      );

      await authService.uploadFileAsBase64(
        uid: uid,
        fieldName: "authorizationFile",
        filePath: authorizationFile,
      );

      await authService.uploadFileAsBase64(
        uid: uid,
        fieldName: "affiliateHospitalFile",
        filePath: affiliateHospitalFile,
      );

      await authService.uploadFileAsBase64(
        uid: uid,
        fieldName: "idCardFile",
        filePath: idCardFile,
      );

      // Save other professional info
      await authService.saveUserProfile(
        uid: uid,
        data: {
          "specialty": _specialty,
          "country": _country,
          "city": _cityController.text.trim(),
          "careerStartDate": _careerStartDate?.toIso8601String(),
          "licensingNumber": _licensingController.text.trim(),
          "professionalInfoComplete": true, // Track completion
        },
      );

      // ✅ FIXED: Go to Doctor Availability next (not directly to Approval)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorAvailabilityScreen(role: widget.role),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
    );
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
          onTap: () => Navigator.pop(context),
        ),
        title: Text(
          "Professional information",
          style: TextStyle(
            fontSize: 18.sp,
            color: AppColors.textBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Specialty
                Row(
                  children: [
                    Checkbox(
                      value: _specialty == "Generalist",
                      activeColor: AppColors.primaryBlue,
                      onChanged: (val) {
                        setState(() => _specialty = "Generalist");
                      },
                    ),
                    const Text("Generalist"),
                    SizedBox(width: 20.w),
                    Checkbox(
                      value: _specialty == "Specialist",
                      activeColor: AppColors.primaryBlue,
                      onChanged: (val) {
                        setState(() => _specialty = "Specialist");
                      },
                    ),
                    const Text("Specialist"),
                  ],
                ),
                SizedBox(height: 10.h),

                // Country
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration(
                      "Country you are legally authorized to practice"),
                  value: _country,
                  items: ["Cameroon", "Nigeria", "Ghana"]
                      .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _country = val),
                ),
                SizedBox(height: 15.h),

                // City
                TextFormField(
                  controller: _cityController,
                  decoration: _inputDecoration("City/Town"),
                ),
                SizedBox(height: 15.h),

                // Career Start Date
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2015),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _careerStartDate = picked);
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _inputDecoration(
                        "Career Start Date (YYYY-MM-DD)",
                      ).copyWith(
                        hintText: _careerStartDate == null
                            ? "Select date"
                            : _careerStartDate!
                            .toIso8601String()
                            .split("T")
                            .first,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15.h),

                // Licensing Number
                TextFormField(
                  controller: _licensingController,
                  decoration: _inputDecoration("Licensing Number"),
                ),
                SizedBox(height: 15.h),

                // File uploads
                FileUploadField(
                  label: "Education Certificate",
                  onFileSelected: (file) =>
                      setState(() => educationCertificate = file),
                ),
                FileUploadField(
                  label: "Authorisation for private practice (optional)",
                  onFileSelected: (file) =>
                      setState(() => authorizationFile = file),
                ),
                FileUploadField(
                  label: "Affiliate Hospital (Optional)",
                  onFileSelected: (file) =>
                      setState(() => affiliateHospitalFile = file),
                ),
                FileUploadField(
                  label: "Identification card/Passport",
                  onFileSelected: (file) =>
                      setState(() => idCardFile = file),
                ),

                SizedBox(height: 20.h),
                CustomButton(
                  text: _loading ? "Submitting..." : "Next",
                  onPressed: _loading ? null : _submitProfessionalInfo,
                  isFilled: true,
                  backgroundColor: AppColors.primaryBlue,
                  textColor: AppColors.white,
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
// import 'package:firebase_auth/firebase_auth.dart';
//
// import '../../../core/constants/app_colors.dart';
// import '../../../shared/widgets/custom_button.dart';
// import '../../../shared/widgets/file_upload_field.dart';
// import '../../../services/auth_service.dart';
// import 'approved_screen.dart';
//
// class ProfessionalInfoScreenAdvanced extends StatefulWidget {
//   final String role;
//
//   const ProfessionalInfoScreenAdvanced({
//     super.key,
//     required this.role,
//   });
//
//   @override
//   State<ProfessionalInfoScreenAdvanced> createState() =>
//       _ProfessionalInfoScreenAdvancedState();
// }
//
// class _ProfessionalInfoScreenAdvancedState
//     extends State<ProfessionalInfoScreenAdvanced> {
//   String? _specialty;
//   String? _country;
//   DateTime? _careerStartDate;
//
//   final TextEditingController _cityController = TextEditingController();
//   final TextEditingController _licensingController = TextEditingController();
//
//   String? educationCertificate;
//   String? authorizationFile;
//   String? affiliateHospitalFile;
//   String? idCardFile;
//
//   bool _loading = false;
//
//   Future<void> _submitProfessionalInfo() async {
//     if (_specialty == null ||
//         _country == null ||
//         _cityController.text.trim().isEmpty ||
//         _careerStartDate == null ||
//         _licensingController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please fill all required fields")),
//       );
//       return;
//     }
//
//     setState(() => _loading = true);
//
//     try {
//       final uid = FirebaseAuth.instance.currentUser?.uid;
//       if (uid == null) throw Exception("No logged-in user");
//
//       final authService = AuthService();
//
//       // Upload files as base64 strings
//       await authService.uploadFileAsBase64(
//         uid: uid,
//         fieldName: "educationCertificate",
//         filePath: educationCertificate,
//       );
//
//       await authService.uploadFileAsBase64(
//         uid: uid,
//         fieldName: "authorizationFile",
//         filePath: authorizationFile,
//       );
//
//       await authService.uploadFileAsBase64(
//         uid: uid,
//         fieldName: "affiliateHospitalFile",
//         filePath: affiliateHospitalFile,
//       );
//
//       await authService.uploadFileAsBase64(
//         uid: uid,
//         fieldName: "idCardFile",
//         filePath: idCardFile,
//       );
//
//       // Save other professional info
//       await authService.saveUserProfile(
//         uid: uid,
//         data: {
//           "specialty": _specialty,
//           "country": _country,
//           "city": _cityController.text.trim(),
//           "careerStartDate": _careerStartDate?.toIso8601String(),
//           "licensingNumber": _licensingController.text.trim(),
//         },
//       );
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ApprovalScreen(role: widget.role),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to save: $e")),
//       );
//     } finally {
//       setState(() => _loading = false);
//     }
//   }
//
//   InputDecoration _inputDecoration(String label) {
//     return InputDecoration(
//       labelText: label,
//       filled: true,
//       fillColor: AppColors.white,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
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
//         leading: GestureDetector(
//           child: const Icon(Icons.arrow_back_ios),
//           onTap: () => Navigator.pop(context),
//         ),
//         title: Text(
//           "Professional information",
//           style: TextStyle(
//             fontSize: 18.sp,
//             color: AppColors.textBlue,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 // Specialty
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: _specialty == "Generalist",
//                       activeColor: AppColors.primaryBlue,
//                       onChanged: (val) {
//                         setState(() => _specialty = "Generalist");
//                       },
//                     ),
//                     const Text("Generalist"),
//                     SizedBox(width: 20.w),
//                     Checkbox(
//                       value: _specialty == "Specialist",
//                       activeColor: AppColors.primaryBlue,
//                       onChanged: (val) {
//                         setState(() => _specialty = "Specialist");
//                       },
//                     ),
//                     const Text("Specialist"),
//                   ],
//                 ),
//                 SizedBox(height: 10.h),
//
//                 // Country
//                 DropdownButtonFormField<String>(
//                   decoration: _inputDecoration(
//                       "Country you are legally authorized to practice"),
//                   value: _country,
//                   items: ["Cameroon", "Nigeria", "Ghana"]
//                       .map((e) =>
//                       DropdownMenuItem(value: e, child: Text(e)))
//                       .toList(),
//                   onChanged: (val) => setState(() => _country = val),
//                 ),
//                 SizedBox(height: 15.h),
//
//                 // City
//                 TextFormField(
//                   controller: _cityController,
//                   decoration: _inputDecoration("City/Town"),
//                 ),
//                 SizedBox(height: 15.h),
//
//                 // Career Start Date
//                 GestureDetector(
//                   onTap: () async {
//                     final picked = await showDatePicker(
//                       context: context,
//                       initialDate: DateTime(2015),
//                       firstDate: DateTime(1950),
//                       lastDate: DateTime.now(),
//                     );
//                     if (picked != null) {
//                       setState(() => _careerStartDate = picked);
//                     }
//                   },
//                   child: AbsorbPointer(
//                     child: TextFormField(
//                       decoration: _inputDecoration(
//                         "Career Start Date (YYYY-MM-DD)",
//                       ).copyWith(
//                         hintText: _careerStartDate == null
//                             ? "Select date"
//                             : _careerStartDate!
//                             .toIso8601String()
//                             .split("T")
//                             .first,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 15.h),
//
//                 // Licensing Number
//                 TextFormField(
//                   controller: _licensingController,
//                   decoration: _inputDecoration("Licensing Number"),
//                 ),
//                 SizedBox(height: 15.h),
//
//                 // File uploads
//                 FileUploadField(
//                   label: "Education Certificate",
//                   onFileSelected: (file) =>
//                       setState(() => educationCertificate = file),
//                 ),
//                 FileUploadField(
//                   label: "Authorisation for private practice (optional)",
//                   onFileSelected: (file) =>
//                       setState(() => authorizationFile = file),
//                 ),
//                 FileUploadField(
//                   label: "Affiliate Hospital (Optional)",
//                   onFileSelected: (file) =>
//                       setState(() => affiliateHospitalFile = file),
//                 ),
//                 FileUploadField(
//                   label: "Identification card/Passport",
//                   onFileSelected: (file) =>
//                       setState(() => idCardFile = file),
//                 ),
//
//                 SizedBox(height: 20.h),
//                 CustomButton(
//                   text: _loading ? "Submitting..." : "Submit",
//                   onPressed: _loading ? null : _submitProfessionalInfo,
//                   isFilled: true,
//                   backgroundColor: AppColors.primaryBlue,
//                   textColor: AppColors.white,
//                 ),
//               ],
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
// // import 'package:flutter/material.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// //
// // import '../../../core/constants/app_colors.dart';
// // import '../../../shared/widgets/custom_button.dart';
// // import '../../../shared/widgets/file_upload_field.dart';
// // import '../../../services/auth_service.dart';
// // import 'approved_screen.dart';
// //
// // class ProfessionalInfoScreenAdvanced extends StatefulWidget {
// //   final String role;
// //
// //   const ProfessionalInfoScreenAdvanced({
// //     super.key,
// //     required this.role,
// //   });
// //
// //   @override
// //   State<ProfessionalInfoScreenAdvanced> createState() =>
// //       _ProfessionalInfoScreenAdvancedState();
// // }
// //
// // class _ProfessionalInfoScreenAdvancedState
// //     extends State<ProfessionalInfoScreenAdvanced> {
// //   String? _specialty;
// //   String? _country;
// //   DateTime? _careerStartDate;
// //
// //   final TextEditingController _cityController = TextEditingController();
// //   final TextEditingController _licensingController = TextEditingController();
// //
// //   String? educationCertificate;
// //   String? authorizationFile;
// //   String? affiliateHospitalFile;
// //   String? idCardFile;
// //
// //   bool _loading = false;
// //
// //   Future<void> _submitProfessionalInfo() async {
// //     if (_specialty == null ||
// //         _country == null ||
// //         _cityController.text.trim().isEmpty ||
// //         _careerStartDate == null ||
// //         _licensingController.text.trim().isEmpty) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Please fill all required fields")),
// //       );
// //       return;
// //     }
// //
// //     setState(() => _loading = true);
// //
// //     try {
// //       final uid = FirebaseAuth.instance.currentUser?.uid;
// //       if (uid == null) throw Exception("No logged-in user");
// //
// //       final authService = AuthService();
// //
// //       // Upload files (if provided) and get URLs
// //       final eduUrl = await authService.uploadFile(
// //         uid: uid,
// //         fieldName: "educationCertificate",
// //         filePath: educationCertificate,
// //       );
// //
// //       final authFileUrl = await authService.uploadFile(
// //         uid: uid,
// //         fieldName: "authorizationFile",
// //         filePath: authorizationFile,
// //       );
// //
// //       final hospitalUrl = await authService.uploadFile(
// //         uid: uid,
// //         fieldName: "affiliateHospitalFile",
// //         filePath: affiliateHospitalFile,
// //       );
// //
// //       final idUrl = await authService.uploadFile(
// //         uid: uid,
// //         fieldName: "idCardFile",
// //         filePath: idCardFile,
// //       );
// //
// //       // Save to Firestore
// //       await authService.saveUserProfile(
// //         uid: uid,
// //         data: {
// //           "specialty": _specialty,
// //           "country": _country,
// //           "city": _cityController.text.trim(),
// //           "careerStartDate": _careerStartDate?.toIso8601String(),
// //           "licensingNumber": _licensingController.text.trim(),
// //           "educationCertificate": eduUrl,
// //           "authorizationFile": authFileUrl,
// //           "affiliateHospitalFile": hospitalUrl,
// //           "idCardFile": idUrl,
// //         },
// //       );
// //
// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(
// //           builder: (_) => ApprovalScreen(role: widget.role),
// //         ),
// //       );
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("Failed to save: $e")),
// //       );
// //     } finally {
// //       setState(() => _loading = false);
// //     }
// //   }
// //
// //   InputDecoration _inputDecoration(String label) {
// //     return InputDecoration(
// //       labelText: label,
// //       filled: true,
// //       fillColor: AppColors.white,
// //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: AppColors.backgroundColor,
// //       appBar: AppBar(
// //         backgroundColor: AppColors.backgroundColor,
// //         elevation: 0,
// //         leading: GestureDetector(
// //           child: const Icon(Icons.arrow_back_ios),
// //           onTap: () => Navigator.pop(context),
// //         ),
// //         title: Text(
// //           "Professional information",
// //           style: TextStyle(
// //             fontSize: 18.sp,
// //             color: AppColors.textBlue,
// //             fontWeight: FontWeight.w700,
// //           ),
// //         ),
// //       ),
// //       body: SafeArea(
// //         child: Padding(
// //           padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
// //           child: SingleChildScrollView(
// //             child: Column(
// //               children: [
// //                 // Specialty
// //                 Row(
// //                   children: [
// //                     Checkbox(
// //                       value: _specialty == "Generalist",
// //                       activeColor: AppColors.primaryBlue,
// //                       onChanged: (val) {
// //                         setState(() => _specialty = "Generalist");
// //                       },
// //                     ),
// //                     const Text("Generalist"),
// //                     SizedBox(width: 20.w),
// //                     Checkbox(
// //                       value: _specialty == "Specialist",
// //                       activeColor: AppColors.primaryBlue,
// //                       onChanged: (val) {
// //                         setState(() => _specialty = "Specialist");
// //                       },
// //                     ),
// //                     const Text("Specialist"),
// //                   ],
// //                 ),
// //                 SizedBox(height: 10.h),
// //
// //                 // Country
// //                 DropdownButtonFormField<String>(
// //                   decoration: _inputDecoration(
// //                       "Country you are legally authorized to practice"),
// //                   value: _country,
// //                   items: ["Cameroon", "Nigeria", "Ghana"]
// //                       .map((e) =>
// //                       DropdownMenuItem(value: e, child: Text(e)))
// //                       .toList(),
// //                   onChanged: (val) => setState(() => _country = val),
// //                 ),
// //                 SizedBox(height: 15.h),
// //
// //                 // City
// //                 TextFormField(
// //                   controller: _cityController,
// //                   decoration: _inputDecoration("City/Town"),
// //                 ),
// //                 SizedBox(height: 15.h),
// //
// //                 // Career Start Date
// //                 GestureDetector(
// //                   onTap: () async {
// //                     final picked = await showDatePicker(
// //                       context: context,
// //                       initialDate: DateTime(2015),
// //                       firstDate: DateTime(1950),
// //                       lastDate: DateTime.now(),
// //                     );
// //                     if (picked != null) {
// //                       setState(() => _careerStartDate = picked);
// //                     }
// //                   },
// //                   child: AbsorbPointer(
// //                     child: TextFormField(
// //                       decoration: _inputDecoration(
// //                         "Career Start Date (YYYY-MM-DD)",
// //                       ).copyWith(
// //                         hintText: _careerStartDate == null
// //                             ? "Select date"
// //                             : _careerStartDate!
// //                             .toIso8601String()
// //                             .split("T")
// //                             .first,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //                 SizedBox(height: 15.h),
// //
// //                 // Licensing Number
// //                 TextFormField(
// //                   controller: _licensingController,
// //                   decoration: _inputDecoration("Licensing Number"),
// //                 ),
// //                 SizedBox(height: 15.h),
// //
// //                 // File uploads
// //                 FileUploadField(
// //                   label: "Education Certificate",
// //                   onFileSelected: (file) =>
// //                       setState(() => educationCertificate = file),
// //                 ),
// //                 FileUploadField(
// //                   label: "Authorisation for private practice (optional)",
// //                   onFileSelected: (file) =>
// //                       setState(() => authorizationFile = file),
// //                 ),
// //                 FileUploadField(
// //                   label: "Affiliate Hospital (Optional)",
// //                   onFileSelected: (file) =>
// //                       setState(() => affiliateHospitalFile = file),
// //                 ),
// //                 FileUploadField(
// //                   label: "Identification card/Passport",
// //                   onFileSelected: (file) =>
// //                       setState(() => idCardFile = file),
// //                 ),
// //
// //                 SizedBox(height: 20.h),
// //                 CustomButton(
// //                   text: _loading ? "Submitting..." : "Submit",
// //                   onPressed: _loading ? null : _submitProfessionalInfo,
// //                   isFilled: true,
// //                   backgroundColor: AppColors.primaryBlue,
// //                   textColor: AppColors.white,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
