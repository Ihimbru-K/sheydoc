import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sheydoc_app/features/auth/doctors/payment_appointment_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/session_pricing.dart';
import 'dart:convert';

import '../patients/home/appointment_booking_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;
  const DoctorProfileScreen({super.key, required this.doctorId, required this.doctorData});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedDuration = 30;
  double _calculatedPrice = SessionPricing.calculatePrice(30);
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _calculatedPrice = SessionPricing.calculatePrice(_selectedDuration);
  }

  List<TimeOfDay> _getAvailableSlots(DateTime date, List? availability) {
    final day = date.weekday;
    List<TimeOfDay> slots = [];

    final availabilityList = availability as List<dynamic>?;
    if (availabilityList == null) return [];

    for (var entry in availabilityList) {
      final entryMap = entry as Map<String, dynamic>;
      if (entryMap['day'] == day) {
        final startHour = entryMap['startHour'] as int;
        final startMinute = entryMap['startMinute'] as int;
        final endHour = entryMap['endHour'] as int;
        final endMinute = entryMap['endMinute'] as int;

        TimeOfDay startTime = TimeOfDay(hour: startHour, minute: startMinute);
        TimeOfDay endTime = TimeOfDay(hour: endHour, minute: endMinute);

        DateTime start = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
        DateTime end = DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);

        while (start.isBefore(end)) {
          slots.add(TimeOfDay(hour: start.hour, minute: start.minute));
          start = start.add(const Duration(minutes: 30));
        }
      }
    }

    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doctorData;
    final name = data['name'] ?? '';
    final specialty = data['specialty'] ?? '';
    final years = data['yearsOfExperience'] ?? 0;
    final rating = data['rating'] ?? 5.0;
    final baseFee = data['baseFee'] ?? 3000.0;
    final about = data['about'] ?? 'I am Dr. Alissa, a licensed general practitioner dedicated to helping young women understand and care for their health with compassion, privacy, and respect.';
    final availability = data['availability'] as List?;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60.r,
              backgroundImage: data['photo'] != null ? MemoryImage(base64Decode(data['photo'])) : null,
              child: data['photo'] == null ? Icon(Icons.person, size: 60.sp) : null,
            ),
            SizedBox(height: 16.h),
            Text(
              name,
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              specialty,
              style: TextStyle(fontSize: 16.sp, color: AppColors.primaryBlue),
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 16.sp),
                SizedBox(width: 4.w),
                Text('${116} Patients', style: TextStyle(fontSize: 14.sp)),
                SizedBox(width: 16.w),
                Icon(Icons.calendar_today, size: 16.sp),
                SizedBox(width: 4.w),
                Text('${years}+ Years', style: TextStyle(fontSize: 14.sp)),
                SizedBox(width: 16.w),
                Icon(Icons.star, size: 16.sp),
                SizedBox(width: 4.w),
                Text('${90}+ Reviews', style: TextStyle(fontSize: 14.sp)),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              'About Me',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              about,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 16.h),
            //
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentBookingScreen(
                      doctorId: widget.doctorId,
                      doctorData: widget.doctorData,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: Size(double.infinity, 50.h),
              ),
              child: const Text('Book Appointment'),
            ),
          ],
        ),
      ),
    );
  }
}























// // Updated DoctorProfileScreen with corrected availability type, fixed _getAvailableSlots, and updated navigation
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sheydoc_app/features/auth/doctors/payment_appointment_screen.dart';
// import 'package:table_calendar/table_calendar.dart';
// import '../../../core/constants/app_colors.dart';
// import '../../../core/utils/session_pricing.dart';
// import 'dart:convert';
//
// class DoctorProfileScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;
//   const DoctorProfileScreen({super.key, required this.doctorId, required this.doctorData});
//
//   @override
//   State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
// }
//
// class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
//   DateTime _selectedDate = DateTime.now();
//   int _selectedDuration = 30;
//   double _calculatedPrice = SessionPricing.calculatePrice(30);
//   TimeOfDay? _selectedTime; // From slots
//
//   @override
//   void initState() {
//     super.initState();
//     _calculatedPrice = SessionPricing.calculatePrice(_selectedDuration);
//   }
//
//   List<TimeOfDay> _getAvailableSlots(DateTime date, List? availability) {
//     final day = date.weekday; // 1 = Monday, etc.
//     List<TimeOfDay> slots = [];
//
//     // Availability is stored as a list of maps from saveDoctorAvailability
//     final availabilityList = availability as List<dynamic>?;
//
//     if (availabilityList == null) return [];
//
//     for (var entry in availabilityList) {
//       final entryMap = entry as Map<String, dynamic>;
//       if (entryMap['day'] == day) {
//         final startHour = entryMap['startHour'] as int;
//         final startMinute = entryMap['startMinute'] as int;
//         final endHour = entryMap['endHour'] as int;
//         final endMinute = entryMap['endMinute'] as int;
//
//         TimeOfDay startTime = TimeOfDay(hour: startHour, minute: startMinute);
//         TimeOfDay endTime = TimeOfDay(hour: endHour, minute: endMinute);
//
//         // Generate slots in 30-minute increments
//         DateTime start = DateTime(
//           date.year,
//           date.month,
//           date.day,
//           startTime.hour,
//           startTime.minute,
//         );
//         DateTime end = DateTime(
//           date.year,
//           date.month,
//           date.day,
//           endTime.hour,
//           endTime.minute,
//         );
//
//         while (start.isBefore(end)) {
//           slots.add(TimeOfDay(hour: start.hour, minute: start.minute));
//           start = start.add(const Duration(minutes: 30));
//         }
//       }
//     }
//
//     return slots;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final data = widget.doctorData;
//     final name = data['name'] ?? '';
//     final specialty = data['specialty'] ?? '';
//     final years = data['yearsOfExperience'] ?? 0;
//     final rating = data['rating'] ?? 5.0;
//     final baseFee = data['baseFee'] ?? 3000.0;
//     final about = data['about'] ?? 'About me placeholder'; // Add to data later
//     final availability = data['availability'] as List?; // Corrected to List?
//
//     return Scaffold(
//       appBar: AppBar(title: Text(name), backgroundColor: AppColors.backgroundColor),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16.w),
//         child: Column(
//           children: [
//             // Photo & Stats
//             Center(child: CircleAvatar(radius: 60.r, backgroundImage: data['photo'] != null ? MemoryImage(base64Decode(data['photo'])) : null)),
//             SizedBox(height: 16.h),
//             Text(name, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
//             Text(specialty, style: TextStyle(fontSize: 16.sp, color: AppColors.primaryBlue)),
//             Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//               ...List.generate(5, (i) => Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber)),
//               SizedBox(width: 8.w),
//               Text('$years years exp • ${baseFee.toStringAsFixed(0)} FCFA base'),
//             ]),
//             SizedBox(height: 16.h),
//
//             // About
//             Text('About Me', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
//             Text(about, textAlign: TextAlign.justify),
//
//             // Availability Calendar (1-week window)
//             TableCalendar(
//               firstDay: DateTime.now(),
//               lastDay: DateTime.now().add(const Duration(days: 7)),
//               focusedDay: _selectedDate,
//               selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
//               onDaySelected: (selected, focused) => setState(() => _selectedDate = selected),
//             ),
//             SizedBox(height: 16.h),
//
//             // Slots for Selected Date
//             Text('Available Times', style: TextStyle(fontSize: 16.sp)),
//             ..._getAvailableSlots(_selectedDate, availability).map((slot) => ListTile(
//               title: Text(slot.format(context)),
//               onTap: () => setState(() => _selectedTime = slot),
//             )),
//
//             // Duration & Price
//             DropdownButtonFormField<int>(
//               decoration: const InputDecoration(labelText: 'Session Duration'),
//               value: _selectedDuration,
//               items: [15, 30, 45, 60, 90, 120].map((d) => DropdownMenuItem(value: d, child: Text('$d mins'))).toList(),
//               onChanged: (val) {
//                 setState(() {
//                   _selectedDuration = val!;
//                   _calculatedPrice = SessionPricing.calculatePrice(val);
//                 });
//               },
//             ),
//             SizedBox(height: 8.h),
//             Text('Total: ${_calculatedPrice.toStringAsFixed(0)} FCFA', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
//
//             SizedBox(height: 20.h),
//             ElevatedButton(
//               onPressed: _selectedTime == null
//                   ? null
//                   : () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => PaymentMethodScreen(
//                       appointmentData: {
//                         'doctorId': widget.doctorId,
//                         'doctorName': widget.doctorData['name'],
//                         'date': _selectedDate,
//                         'time': _selectedTime,
//                         'duration': _selectedDuration,
//                         'price': _calculatedPrice,
//                       },
//                     ),
//                   ),
//                 );
//               },
//               child: const Text('Book Appointment'),
//               style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, minimumSize: Size(double.infinity, 50.h)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//}













// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sheydoc_app/features/auth/doctors/payment_appointment_screen.dart';
// import 'package:table_calendar/table_calendar.dart';
//  // Add pubspec: table_calendar
// import '../../../core/constants/app_colors.dart';
// import '../../../core/utils/session_pricing.dart';
// import 'dart:convert';
//
//
// class DoctorProfileScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;
//   const DoctorProfileScreen({super.key, required this.doctorId, required this.doctorData});
//
//   @override
//   State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
// }
//
// class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
//   DateTime _selectedDate = DateTime.now();
//   int _selectedDuration = 30;
//   double _calculatedPrice = SessionPricing.calculatePrice(30);
//   TimeOfDay? _selectedTime; // From slots
//
//   @override
//   void initState() {
//     super.initState();
//     _calculatedPrice = SessionPricing.calculatePrice(_selectedDuration);
//   }
//
//   List<TimeOfDay> _getAvailableSlots(DateTime date, Map? availability) {
//     // Logic: Match date.weekday to avail keys, generate slots from ranges (e.g., 9-10AM → 9:00,9:30 if 30min)
//     final day = date.weekday; // 1=Mon
//     final dayRanges = availability?[day] as List?;
//     if (dayRanges == null) return [];
//     // Implement slot generation (e.g., for each range, add increments)
//     return []; // Placeholder: return list of TimeOfDay
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final data = widget.doctorData;
//     final name = data['name'] ?? '';
//     final specialty = data['specialty'] ?? '';
//     final years = data['yearsOfExperience'] ?? 0;
//     final rating = data['rating'] ?? 5.0;
//     final baseFee = data['baseFee'] ?? 3000.0;
//     final about = data['about'] ?? 'About me placeholder'; // Add to data later
//     final availability = data['availability'] as Map?;
//
//     return Scaffold(
//       appBar: AppBar(title: Text(name), backgroundColor: AppColors.backgroundColor),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16.w),
//        child: Column(
//          children: [
//
//              // Photo & Stats
//              Center(child: CircleAvatar(radius: 60.r, backgroundImage: data['photo'] != null ? MemoryImage(base64Decode(data['photo'])) : null)),
//              SizedBox(height: 16.h),
//              Text(name, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
//              Text(specialty, style: TextStyle(fontSize: 16.sp, color: AppColors.primaryBlue)),
//              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//                ...List.generate(5, (i) => Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber)),
//                SizedBox(width: 8.w),
//                Text('$years years exp • ${baseFee.toStringAsFixed(0)} FCFA base'),
//              ]),
//              SizedBox(height: 16.h),
//
//              // About
//              Text('About Me', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
//              Text(about, textAlign: TextAlign.justify),
//
//              // Availability Calendar (1-week window)
//              TableCalendar(
//                firstDay: DateTime.now(),
//                lastDay: DateTime.now().add(Duration(days: 7)),
//                focusedDay: _selectedDate,
//                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
//                onDaySelected: (selected, focused) => setState(() => _selectedDate = selected),
//              ),
//              SizedBox(height: 16.h),
//
//              // Slots for Selected Date
//              Text('Available Times', style: TextStyle(fontSize: 16.sp)),
//              ..._getAvailableSlots(_selectedDate, availability).map((slot) => ListTile(
//                title: Text(slot.format(context)),
//                onTap: () => setState(() => _selectedTime = slot),
//              )),
//
//              // Duration & Price
//              DropdownButtonFormField<int>(
//                decoration: InputDecoration(labelText: 'Session Duration'),
//                value: _selectedDuration,
//                items: [15, 30, 45, 60, 90, 120].map((d) => DropdownMenuItem(value: d, child: Text('$d mins'))).toList(),
//                onChanged: (val) {
//                  setState(() {
//                    _selectedDuration = val!;
//                    _calculatedPrice = SessionPricing.calculatePrice(val);
//                  });
//                },
//              ),
//              SizedBox(height: 8.h),
//              Text('Total: ${_calculatedPrice.toStringAsFixed(0)} FCFA', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
//
//              SizedBox(height: 20.h),
//              ElevatedButton(
//                onPressed: _selectedTime == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentMethodScreen(appointmentData: {/* date, time, duration, price */}))),
//                child: Text('Book Appointment'),
//                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, minimumSize: Size(double.infinity, 50.h)),
//              ),
//            ],
//        ),
//       ),
//     );
//   }
// }