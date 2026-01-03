import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/file_upload_field.dart';
import '../../../services/auth_service.dart';
import 'doctor_availability_ui.dart';

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

  // Helper: Compress file if it's an image, otherwise use original
  Future<String?> _compressFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return null;

    final file = File(filePath);
    if (!file.existsSync()) return null;

    final extension = path.extension(filePath).toLowerCase();
    final compressibleExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

    if (!compressibleExtensions.contains(extension)) {
      print("Non-image file, skipping compression: $extension");
      return filePath;
    }

    try {
      final targetPath = path.join(
        file.parent.path,
        "compressed_${path.basename(file.path)}",
      );

      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 1200,
        minHeight: 1200,
        format: CompressFormat.jpeg,
      );

      if (compressedXFile == null) {
        print("Compression failed, falling back to original");
        return filePath;
      }

      final sizeInKB = (await compressedXFile.length()) ~/ 1024;
      print("Compressed: ${path.basename(file.path)} → ${sizeInKB}KB");

      return compressedXFile.path;
    } catch (e) {
      print("Compression error: $e → using original");
      return filePath;
    }
  }
  // Future<String?> _compressFile(String? filePath) async {
  //   if (filePath == null || filePath.isEmpty) return null;
  //
  //   final file = File(filePath);
  //   if (!file.existsSync()) return null;
  //
  //   final extension = path.extension(filePath).toLowerCase();
  //
  //   // Only compress image types (jpeg, jpg, png, webp)
  //   final compressibleExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
  //   if (!compressibleExtensions.contains(extension)) {
  //     print("Non-image file (e.g., PDF), skipping compression: $extension");
  //     return filePath; // Return original for PDFs
  //   }
  //
  //   try {
  //     final targetPath = path.join(
  //       file.parent.path,
  //       "compressed_${path.basename(file.path)}",
  //     );
  //
  //     final compressedFile = await FlutterImageCompress.compressAndGetFile(
  //       file.absolute.path,
  //       targetPath,
  //       quality: 85, // 85% quality → great balance of size & clarity
  //       minWidth: 1200,
  //       minHeight: 1200,
  //       format: CompressFormat.jpeg, // Force JPEG for smaller size
  //     );
  //
  //     if (compressedFile == null) {
  //       print("Compression failed, using original");
  //       return filePath;
  //     }
  //
  //     final sizeInKB = compressedFile.lengthSync() ~/ 1024;
  //     print("Compressed image: ${path.basename(file.path)} → ${sizeInKB}KB");
  //
  //     return compressedFile.path;
  //   } catch (e) {
  //     print("Compression error: $e, using original file");
  //     return filePath;
  //   }
  // }

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

      // Compress and upload files one by one
      final compressedEducation = await _compressFile(educationCertificate);
      final compressedAuth = await _compressFile(authorizationFile);
      final compressedHospital = await _compressFile(affiliateHospitalFile);
      final compressedId = await _compressFile(idCardFile);

      await authService.uploadFileAsBase64(
        uid: uid,
        fieldName: "educationCertificate",
        filePath: compressedEducation,
      );

      await authService.uploadFileAsBase64(
        uid: uid,
        fieldName: "authorizationFile",
        filePath: compressedAuth,
      );

      await authService.uploadFileAsBase64(
        uid: uid,
        fieldName: "affiliateHospitalFile",
        filePath: compressedHospital,
      );

      await authService.uploadFileAsBase64(
        uid: uid,
        fieldName: "idCardFile",
        filePath: compressedId,
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
          "professionalInfoComplete": true,
        },
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorAvailabilityScreen(role: widget.role),
        ),
      );
    } catch (e) {
      if (!mounted) return;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Specialty
                const Text("Specialty", style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Checkbox(
                      value: _specialty == "Generalist",
                      activeColor: AppColors.primaryBlue,
                      onChanged: (val) => setState(() => _specialty = "Generalist"),
                    ),
                    const Text("Generalist"),
                    SizedBox(width: 20.w),
                    Checkbox(
                      value: _specialty == "Specialist",
                      activeColor: AppColors.primaryBlue,
                      onChanged: (val) => setState(() => _specialty = "Specialist"),
                    ),
                    const Text("Specialist"),
                  ],
                ),
                SizedBox(height: 15.h),

                // Country
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Country you are legally authorized to practice *"),
                  value: _country,
                  items: ["Cameroon", "Nigeria", "Ghana"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _country = val),
                  validator: (val) => val == null ? "Required" : null,
                ),
                SizedBox(height: 15.h),

                // City
                TextFormField(
                  controller: _cityController,
                  decoration: _inputDecoration("City/Town *"),
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
                      decoration: _inputDecoration("Career Start Date *").copyWith(
                        hintText: _careerStartDate == null
                            ? "Select date"
                            : _careerStartDate!.toIso8601String().split("T").first,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15.h),

                // Licensing Number
                TextFormField(
                  controller: _licensingController,
                  decoration: _inputDecoration("Licensing Number *"),
                ),
                SizedBox(height: 20.h),

                // File Uploads
                FileUploadField(
                  label: "Education Certificate *",
                  onFileSelected: (file) => setState(() => educationCertificate = file),
                  currentFilePath: educationCertificate,
                ),
                SizedBox(height: 12.h),

                FileUploadField(
                  label: "Authorisation for private practice (optional)",
                  onFileSelected: (file) => setState(() => authorizationFile = file),
                  currentFilePath: authorizationFile,
                ),
                SizedBox(height: 12.h),

                FileUploadField(
                  label: "Affiliate Hospital Document (optional)",
                  onFileSelected: (file) => setState(() => affiliateHospitalFile = file),
                  currentFilePath: affiliateHospitalFile,
                ),
                SizedBox(height: 12.h),

                FileUploadField(
                  label: "ID Card / Passport *",
                  onFileSelected: (file) => setState(() => idCardFile = file),
                  currentFilePath: idCardFile,
                ),
                SizedBox(height: 30.h),

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

  @override
  void dispose() {
    _cityController.dispose();
    _licensingController.dispose();
    super.dispose();
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
// import 'doctor_availability_ui.dart';
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
//           "professionalInfoComplete": true, // Track completion
//         },
//       );
//
//       // ✅ FIXED: Go to Doctor Availability next (not directly to Approval)
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => DoctorAvailabilityScreen(role: widget.role),
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
//                   text: _loading ? "Submitting..." : "Next",
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
