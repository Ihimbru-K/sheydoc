import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/time_range.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../shared/widgets/file_upload_field.dart';
import '../../../services/auth_service.dart';
import 'approved_screen.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  final String role;
  const DoctorAvailabilityScreen({super.key, required this.role});

  @override
  State<DoctorAvailabilityScreen> createState() =>
      _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  Map<int, List<TimeRange>> _schedule = {}; // 0–6 → list of ranges
  int _defaultDuration = 30; // minutes
  double _baseFee = 3000.0;
  int _yearsOfExperience = 5;
  double _rating = 5.0;
  String? _photoPath;
  bool _loading = false;

  late TextEditingController _yearsController;
  late TextEditingController _feeController;

  @override
  void initState() {
    super.initState();
    _yearsController =
        TextEditingController(text: _yearsOfExperience.toString());
    _feeController = TextEditingController(text: _baseFee.toString());
  }

  @override
  void dispose() {
    _yearsController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _addTimeRange(int day) async {
    final start =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (start == null) return;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: start.hour,
          minute: (start.minute + 30) % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );

    if (end == null ||
        end.hour < start.hour ||
        (end.hour == start.hour && end.minute <= start.minute)) return;

    setState(() {
      _schedule[day] ??= [];
      _schedule[day]!.add(TimeRange(start: start, end: end));
    });
  }

  Future<void> _submitAll() async {
    if (_schedule.isEmpty || _yearsOfExperience == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add availability and experience")),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("No user");

      final authService = AuthService();

      String? photoBase64;
      if (_photoPath != null) {
        final file = File(_photoPath!);
        final bytes = await file.readAsBytes();
        photoBase64 = base64Encode(bytes);

        await authService.uploadFileAsBase64(
          uid: uid,
          fieldName: "photo",
          filePath: _photoPath,
        );
      }

      // Save doctor details
      await authService.saveDoctorDetails(
        uid: uid,
        photoBase64: photoBase64,
        yearsOfExperience: _yearsOfExperience,
        rating: _rating,
      );

      // ✅ Save availability (this will mark profile as complete if all steps done)
      await authService.saveDoctorAvailability(
        uid: uid,
        schedule: _schedule,
        defaultDuration: _defaultDuration,
        baseFee: _baseFee,
      );

      // ✅ Profile is now complete - go to approval screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ApprovalScreen(role: widget.role)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Doctor Details & Availability',
          style: TextStyle(
            fontSize: 18.sp,
            color: AppColors.textBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              // Photo
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50.r,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                      _photoPath != null ? FileImage(File(_photoPath!)) : null,
                      child: _photoPath == null
                          ? Icon(Icons.person,
                          size: 60.sp, color: Colors.grey[400])
                          : null,
                    ),
                    Positioned(
                      bottom: 5.h,
                      right: 0,
                      child: CircleAvatar(
                        radius: 15.r,
                        backgroundColor: AppColors.primaryBlue,
                        child: Icon(Icons.camera_alt,
                            size: 18.sp, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
              FileUploadField(
                label: "Profile Photo",
                onFileSelected: (path) => setState(() => _photoPath = path),
              ),
              SizedBox(height: 20.h),

              // Years
              CustomTextField(
                controller: _yearsController,
                fillColor: AppColors.textfieldBlue,
                labelText: 'Years of Experience',
                keyboardType: TextInputType.number,
                onChanged: (val) =>
                _yearsOfExperience = int.tryParse(val) ?? _yearsOfExperience,
              ),
              SizedBox(height: 10.h),

              // Rating
              ListTile(
                title: Text('Initial Rating', style: TextStyle(fontSize: 16.sp)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                        (i) => Icon(i < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber),
                  ),
                ),
                subtitle: Text('$_rating Stars (Auto-set)'),
              ),
              SizedBox(height: 20.h),

              // Fee
              CustomTextField(
                controller: _feeController,
                fillColor: AppColors.textfieldBlue,
                labelText: 'Base Fee (FCFA for ≤30min)',
                keyboardType: TextInputType.number,
                onChanged: (val) =>
                _baseFee = double.tryParse(val) ?? _baseFee,
              ),
              SizedBox(height: 10.h),

              // Duration
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Default Session Duration',
                  fillColor: AppColors.textfieldBlue,
                ),
                value: _defaultDuration,
                items: [15, 30, 45, 60, 90, 120]
                    .map((d) =>
                    DropdownMenuItem(value: d, child: Text('$d minutes')))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _defaultDuration = val ?? _defaultDuration),
              ),
              SizedBox(height: 20.h),

              // Availability
              ..._days.asMap().entries.map((entry) {
                int dayIndex = entry.key; // 0–6
                return ExpansionTile(
                  leading: Checkbox(
                    value: _schedule.containsKey(dayIndex),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _schedule[dayIndex] ??= [];
                        } else {
                          _schedule.remove(dayIndex);
                        }
                      });
                    },
                    activeColor: AppColors.primaryBlue,
                  ),
                  title: Text(entry.value),
                  children: [
                    if (_schedule[dayIndex] != null)
                      ..._schedule[dayIndex]!.map(
                            (range) => ListTile(
                          title: Text(
                              '${range.start.format(context)} - ${range.end.format(context)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => setState(() =>
                                _schedule[dayIndex]!.remove(range)),
                          ),
                        ),
                      ),
                    ListTile(
                      title: const Text('Add Time Range'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _addTimeRange(dayIndex),
                      ),
                    ),
                  ],
                );
              }).toList(),
              SizedBox(height: 20.h),

              CustomButton(
                text: _loading ? 'Saving...' : 'Complete Registration',
                onPressed: _loading ? null : _submitAll,
                isFilled: true,
                backgroundColor: AppColors.primaryBlue,
                textColor: AppColors.white,
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
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:convert';
// import 'dart:io';
//
// import '../../../core/constants/app_colors.dart';
// import '../../../core/utils/time_range.dart';
// import '../../../shared/widgets/custom_button.dart';
// import '../../../shared/widgets/custom_textfield.dart';
// import '../../../shared/widgets/file_upload_field.dart';
// import '../../../services/auth_service.dart';
// import 'approved_screen.dart';
//
// class DoctorAvailabilityScreen extends StatefulWidget {
//   final String role;
//   const DoctorAvailabilityScreen({super.key, required this.role});
//
//   @override
//   State<DoctorAvailabilityScreen> createState() =>
//       _DoctorAvailabilityScreenState();
// }
//
// class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
//   final List<String> _days = [
//     'Monday',
//     'Tuesday',
//     'Wednesday',
//     'Thursday',
//     'Friday',
//     'Saturday',
//     'Sunday'
//   ];
//
//   Map<int, List<TimeRange>> _schedule = {}; // 0–6 → list of ranges
//   int _defaultDuration = 30; // minutes
//   double _baseFee = 3000.0;
//   int _yearsOfExperience = 5;
//   double _rating = 5.0;
//   String? _photoPath;
//   bool _loading = false;
//
//   late TextEditingController _yearsController;
//   late TextEditingController _feeController;
//
//   @override
//   void initState() {
//     super.initState();
//     _yearsController =
//         TextEditingController(text: _yearsOfExperience.toString());
//     _feeController = TextEditingController(text: _baseFee.toString());
//   }
//
//   @override
//   void dispose() {
//     _yearsController.dispose();
//     _feeController.dispose();
//     super.dispose();
//   }
//
//   void _addTimeRange(int day) async {
//     final start =
//     await showTimePicker(context: context, initialTime: TimeOfDay.now());
//     if (start == null) return;
//
//     final end = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay(
//           hour: start.hour,
//           minute: (start.minute + 30) % 60), // at least +30 minutes
//       builder: (context, child) => MediaQuery(
//         data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
//         child: child!,
//       ),
//     );
//
//     if (end == null ||
//         end.hour < start.hour ||
//         (end.hour == start.hour && end.minute <= start.minute)) return;
//
//     setState(() {
//       _schedule[day] ??= [];
//       _schedule[day]!.add(TimeRange(start: start, end: end));
//     });
//   }
//
//   Future<void> _submitAll() async {
//     if (_schedule.isEmpty || _yearsOfExperience == 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Add availability and experience")),
//       );
//       return;
//     }
//     setState(() => _loading = true);
//
//     try {
//       final uid = FirebaseAuth.instance.currentUser?.uid;
//       if (uid == null) throw Exception("No user");
//
//       final authService = AuthService();
//
//       String? photoBase64;
//       if (_photoPath != null) {
//         final file = File(_photoPath!);
//         final bytes = await file.readAsBytes();
//         photoBase64 = base64Encode(bytes);
//
//         await authService.uploadFileAsBase64(
//           uid: uid,
//           fieldName: "photo",
//           filePath: _photoPath,
//         );
//       }
//
//       await authService.saveDoctorDetails(
//         uid: uid,
//         photoBase64: photoBase64,
//         yearsOfExperience: _yearsOfExperience,
//         rating: _rating,
//       );
//
//       await authService.saveDoctorAvailability(
//         uid: uid,
//         schedule: _schedule,
//         defaultDuration: _defaultDuration,
//         baseFee: _baseFee,
//       );
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => ApprovalScreen(role: widget.role)),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed: $e")),
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
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           'Doctor Details & Availability',
//           style: TextStyle(
//             fontSize: 18.sp,
//             color: AppColors.textBlue,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(20.w),
//           child: Column(
//             children: [
//               // Photo
//               Center(
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     CircleAvatar(
//                       radius: 50.r,
//                       backgroundColor: Colors.grey[200],
//                       backgroundImage:
//                       _photoPath != null ? FileImage(File(_photoPath!)) : null,
//                       child: _photoPath == null
//                           ? Icon(Icons.person,
//                           size: 60.sp, color: Colors.grey[400])
//                           : null,
//                     ),
//                     Positioned(
//                       bottom: 5.h,
//                       right: 0,
//                       child: CircleAvatar(
//                         radius: 15.r,
//                         backgroundColor: AppColors.primaryBlue,
//                         child: Icon(Icons.camera_alt,
//                             size: 18.sp, color: AppColors.white),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               FileUploadField(
//                 label: "Profile Photo",
//                 onFileSelected: (path) => setState(() => _photoPath = path),
//               ),
//               SizedBox(height: 20.h),
//
//               // Years
//               CustomTextField(
//                 controller: _yearsController,
//                 fillColor: AppColors.textfieldBlue,
//                 labelText: 'Years of Experience',
//                 keyboardType: TextInputType.number,
//                 onChanged: (val) =>
//                 _yearsOfExperience = int.tryParse(val) ?? _yearsOfExperience,
//               ),
//               SizedBox(height: 10.h),
//
//               // Rating
//               ListTile(
//                 title: Text('Initial Rating', style: TextStyle(fontSize: 16.sp)),
//                 trailing: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: List.generate(
//                     5,
//                         (i) => Icon(i < _rating ? Icons.star : Icons.star_border,
//                         color: Colors.amber),
//                   ),
//                 ),
//                 subtitle: Text('$_rating Stars (Auto-set)'),
//               ),
//               SizedBox(height: 20.h),
//
//               // Fee
//               CustomTextField(
//                 controller: _feeController,
//                 fillColor: AppColors.textfieldBlue,
//                 labelText: 'Base Fee (FCFA for ≤30min)',
//                 keyboardType: TextInputType.number,
//                 onChanged: (val) =>
//                 _baseFee = double.tryParse(val) ?? _baseFee,
//               ),
//               SizedBox(height: 10.h),
//
//               // Duration
//               DropdownButtonFormField<int>(
//                 decoration: InputDecoration(
//                   labelText: 'Default Session Duration',
//                   fillColor: AppColors.textfieldBlue,
//                 ),
//                 value: _defaultDuration,
//                 items: [15, 30, 45, 60, 90, 120]
//                     .map((d) =>
//                     DropdownMenuItem(value: d, child: Text('$d minutes')))
//                     .toList(),
//                 onChanged: (val) =>
//                     setState(() => _defaultDuration = val ?? _defaultDuration),
//               ),
//               SizedBox(height: 20.h),
//
//               // Availability
//               ..._days.asMap().entries.map((entry) {
//                 int dayIndex = entry.key; // 0–6
//                 return ExpansionTile(
//                   leading: Checkbox(
//                     value: _schedule.containsKey(dayIndex),
//                     onChanged: (val) {
//                       setState(() {
//                         if (val == true) {
//                           _schedule[dayIndex] ??= [];
//                         } else {
//                           _schedule.remove(dayIndex);
//                         }
//                       });
//                     },
//                     activeColor: AppColors.primaryBlue,
//                   ),
//                   title: Text(entry.value),
//                   children: [
//                     if (_schedule[dayIndex] != null)
//                       ..._schedule[dayIndex]!.map(
//                             (range) => ListTile(
//                           title: Text(
//                               '${range.start.format(context)} - ${range.end.format(context)}'),
//                           trailing: IconButton(
//                             icon: const Icon(Icons.delete),
//                             onPressed: () => setState(() =>
//                                 _schedule[dayIndex]!.remove(range)),
//                           ),
//                         ),
//                       ),
//                     ListTile(
//                       title: const Text('Add Time Range'),
//                       trailing: IconButton(
//                         icon: const Icon(Icons.add),
//                         onPressed: () => _addTimeRange(dayIndex),
//                       ),
//                     ),
//                   ],
//                 );
//               }).toList(),
//               SizedBox(height: 20.h),
//
//               CustomButton(
//                 text: _loading ? 'Saving...' : 'Submit & Complete Signup',
//                 onPressed: _loading ? null : _submitAll,
//                 isFilled: true,
//                 backgroundColor: AppColors.primaryBlue,
//                 textColor: AppColors.white,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class TimeRange {
//   final TimeOfDay start;
//   final TimeOfDay end;
//   TimeRange({required this.start, required this.end});
// }








// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:convert';
// import 'dart:io';
//
// import '../../../core/constants/app_colors.dart';
// import '../../../shared/widgets/custom_button.dart';
// import '../../../shared/widgets/custom_textfield.dart'; // Assuming for years input
// import '../../../shared/widgets/file_upload_field.dart'; // For photo
// import '../../../services/auth_service.dart';
// import 'approved_screen.dart';
//
// class DoctorAvailabilityScreen extends StatefulWidget {
//   final String role;
//   const DoctorAvailabilityScreen({super.key, required this.role});
//
//   @override
//   State<DoctorAvailabilityScreen> createState() => _DoctorAvailabilityScreenState();
// }
//
// class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
//   final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
//   Map<int, List<TimeRange>> _schedule = {}; // Day 1-7 → list of ranges
//   int _defaultDuration = 30; // Mins: 15,30,45,60,90,120
//   double _baseFee = 3000.0; // FCFA
//   int _yearsOfExperience = 5; // Default, editable
//   double _rating = 5.0; // Auto-set
//   String? _photoPath; // For upload
//   bool _loading = false;
//
//   void _addTimeRange(int day) async {
//     final start = await showTimePicker(context: context, initialTime: TimeOfDay.now());
//     if (start == null) return;
//     final end = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay(hour: start.hour, minute: start.minute + 30),
//       builder: (context, child) => MediaQuery(
//         data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
//         child: child!,
//       ),
//     );
//     if (end == null || end.hour < start.hour || (end.hour == start.hour && end.minute <= start.minute)) return;
//
//     setState(() {
//       _schedule[day] ??= [];
//       _schedule[day]!.add(TimeRange(start: start, end: end));
//     });
//   }
//
//   Future<void> _submitAll() async {
//     if (_schedule.isEmpty || _yearsOfExperience == 0) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add availability and experience")));
//       return;
//     }
//     setState(() => _loading = true);
//
//     try {
//       final uid = FirebaseAuth.instance.currentUser?.uid;
//       if (uid == null) throw Exception("No user");
//
//       final authService = AuthService();
//
//       // Upload photo as Base64
//       String? photoBase64;
//       if (_photoPath != null) {
//         final file = File(_photoPath!);
//         final bytes = await file.readAsBytes();
//         photoBase64 = base64Encode(bytes);
//         await authService.uploadFileAsBase64(uid: uid, fieldName: "photo", filePath: _photoPath);
//       }
//
//       // Save details
//       await authService.saveDoctorDetails(
//         uid: uid,
//         photoBase64: photoBase64,
//         yearsOfExperience: _yearsOfExperience,
//         rating: _rating,
//       );
//
//       // Save availability
//       await authService.saveDoctorAvailability(
//         uid: uid,
//         schedule: _schedule,
//         defaultDuration: _defaultDuration,
//         baseFee: _baseFee,
//       );
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => ApprovalScreen(role: widget.role)),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
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
//         leading: IconButton(icon: Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
//         title: Text('Doctor Details & Availability', style: TextStyle(fontSize: 18.sp, color: AppColors.textBlue, fontWeight: FontWeight.w700)),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(20.w),
//           child: Column(
//             children: [
//               // Photo Upload
//               Center(
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     CircleAvatar(
//                       radius: 50.r,
//                       backgroundColor: Colors.grey[200],
//                       backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
//                       child: _photoPath == null ? Icon(Icons.person, size: 60.sp, color: Colors.grey[400]) : null,
//                     ),
//                     Positioned(
//                       bottom: 5.h,
//                       right: 0,
//                       child: CircleAvatar(
//                         radius: 15.r,
//                         backgroundColor: AppColors.primaryBlue,
//                         child: Icon(Icons.camera_alt, size: 18.sp, color: AppColors.white),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               FileUploadField(
//                 label: "Profile Photo",
//                 onFileSelected: (path) => setState(() => _photoPath = path),
//               ),
//               SizedBox(height: 20.h),
//
//               // Years of Experience
//               CustomTextField(
//                 controller: TextEditingController(text: _yearsOfExperience.toString()),
//                 fillColor: AppColors.textfieldBlue,
//                 labelText: 'Years of Experience',
//                 keyboardType: TextInputType.number,
//                 onChanged: (val) => _yearsOfExperience = int.tryParse(val) ?? 5,
//               ),
//               SizedBox(height: 10.h),
//
//               // Rating (Auto-set, display only)
//               ListTile(
//                 title: Text('Initial Rating', style: TextStyle(fontSize: 16.sp)),
//                 trailing: Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(i < _rating ? Icons.star : Icons.star_border, color: Colors.amber))),
//                 subtitle: Text('$_rating Stars (Auto-set)'),
//               ),
//               SizedBox(height: 20.h),
//
//               // Base Fee & Default Duration
//               CustomTextField(
//                 controller: TextEditingController(text: _baseFee.toString()),
//                 fillColor: AppColors.textfieldBlue,
//                 labelText: 'Base Fee (FCFA for ≤30min)',
//                 keyboardType: TextInputType.number,
//                 onChanged: (val) => _baseFee = double.tryParse(val) ?? 3000.0,
//               ),
//               SizedBox(height: 10.h),
//               DropdownButtonFormField<int>(
//                 decoration: InputDecoration(labelText: 'Default Session Duration', fillColor: AppColors.textfieldBlue),
//                 value: _defaultDuration,
//                 items: [15, 30, 45, 60, 90, 120]
//                     .map((d) => DropdownMenuItem(value: d, child: Text('$d minutes')))
//                     .toList(),
//                 onChanged: (val) => setState(() => _defaultDuration = val!),
//               ),
//               SizedBox(height: 20.h),
//
//               // Availability Days
//               ..._days.asMap().entries.map((entry) {
//                 int dayIndex = entry.key + 1;
//                 return ExpansionTile(
//                   leading: Checkbox(
//                     value: _schedule.containsKey(dayIndex),
//                     onChanged: (val) => _addTimeRange(dayIndex),
//                     activeColor: AppColors.primaryBlue,
//                   ),
//                   title: Text(entry.value),
//                   children: [
//                     if (_schedule[dayIndex] != null)
//                       ..._schedule[dayIndex]!.map((range) => ListTile(
//                         title: Text('${range.start.format(context)} - ${range.end.format(context)}'),
//                         trailing: IconButton(icon: Icon(Icons.delete), onPressed: () => setState(() => _schedule[dayIndex]!.remove(range))),
//                       )),
//                     ListTile(
//                       title: Text('Add Time Range'),
//                       trailing: IconButton(icon: Icon(Icons.add), onPressed: () => _addTimeRange(dayIndex)),
//                     ),
//                   ],
//                 );
//               }).toList(),
//               SizedBox(height: 20.h),
//
//               CustomButton(
//                 text: _loading ? 'Saving...' : 'Submit & Complete Signup',
//                 onPressed: _loading ? null : _submitAll,
//                 isFilled: true,
//                 backgroundColor: AppColors.primaryBlue,
//                 textColor: AppColors.white,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class TimeRange {
//   final TimeOfDay start;
//   final TimeOfDay end;
//   TimeRange({required this.start, required this.end});
// }