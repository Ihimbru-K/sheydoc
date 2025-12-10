import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sheydoc_app/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sheydoc_app/features/auth/patients/home/home_screen.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;

  const AppointmentBookingScreen({
    super.key,
    required this.doctorId,
    required this.doctorData,
  });

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  String _appointmentType = 'video'; // 'video' or 'audio'
  bool _isBooking = false;

  List<DateTime> _getWeekDays() {
    final now = DateTime.now();
    return List.generate(7, (index) => now.add(Duration(days: index)));
  }

  List<TimeOfDay> _getAvailableSlots() {
    final availability = widget.doctorData['availability'] as List?;

    if (availability == null || availability.isEmpty) {
      return [
        const TimeOfDay(hour: 9, minute: 0),
        const TimeOfDay(hour: 10, minute: 0),
        const TimeOfDay(hour: 11, minute: 0),
        const TimeOfDay(hour: 14, minute: 0),
        const TimeOfDay(hour: 15, minute: 0),
        const TimeOfDay(hour: 16, minute: 0),
      ];
    }

    // Extract slots from availability data
    final slots = <TimeOfDay>[];
    for (var slot in availability) {
      if (slot is Map<String, dynamic>) {
        final startHour = slot['startHour'] ?? 9;
        final startMinute = slot['startMinute'] ?? 0;
        slots.add(TimeOfDay(hour: startHour, minute: startMinute));
      }
    }

    return slots.isNotEmpty ? slots : [const TimeOfDay(hour: 10, minute: 0)];
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.doctorData['name'] ?? '';
    final specialty = widget.doctorData['specialty'] ?? 'Gynecologist';
    final baseFee = widget.doctorData['baseFee'] ?? 3000.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              name,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18.sp,
              ),
            ),
            Text(
              specialty,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fee Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Text(
                    'Consultation Fee: ',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '${baseFee.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30.h),

            // Appointment Type Selection
            Text(
              'Appointment Type',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 16.h),

            Row(
              children: [
                Expanded(
                  child: _buildTypeOption('video', Icons.videocam, 'Video Call'),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildTypeOption('audio', Icons.phone, 'Audio Call'),
                ),
              ],
            ),

            SizedBox(height: 30.h),

            // Date Selection
            Text(
              'Select Date',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 16.h),

            // Week Calendar
            SizedBox(
              height: 80.h,
              child: Row(
                children: _getWeekDays().map((date) {
                  final isSelected = date.day == _selectedDate.day &&
                      date.month == _selectedDate.month &&
                      date.year == _selectedDate.year;
                  final isToday = date.day == DateTime.now().day &&
                      date.month == DateTime.now().month &&
                      date.year == DateTime.now().year;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                          _selectedTime = null;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(12.r),
                          border: isToday && !isSelected
                              ? Border.all(color: AppColors.primaryBlue, width: 1)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getDayName(date),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: isSelected ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              date.day.toString(),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 30.h),

            // Time Selection
            Text(
              'Available Time Slots',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 16.h),

            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: _getAvailableSlots().map((slot) {
                final isSelected = _selectedTime == slot;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTime = slot;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryBlue : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20.r),
                      border: isSelected
                          ? Border.all(color: AppColors.primaryBlue, width: 2)
                          : null,
                    ),
                    child: Text(
                      _formatTimeOfDay(slot),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 40.h),

            // Book Appointment Button
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _selectedTime == null || _isBooking ? null : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedTime == null
                      ? Colors.grey[300]
                      : AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: _isBooking
                    ? SizedBox(
                  height: 20.h,
                  width: 20.w,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Book Appointment',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: _selectedTime == null ? Colors.grey[600] : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String type, IconData icon, String label) {
    final isSelected = _appointmentType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _appointmentType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32.sp,
              color: isSelected ? AppColors.primaryBlue : Colors.grey,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primaryBlue : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bookAppointment() async {
    if (_selectedTime == null) return;

    setState(() {
      _isBooking = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get patient info
      final patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final patientData = patientDoc.data();
      final patientName = patientData?['name'] ?? user.email ?? 'Unknown Patient';

      // Combine date and time
      final fullDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Create appointment DIRECTLY (no pending status)
      await FirebaseFirestore.instance.collection('appointments').add({
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorData['name'],
        'patientId': user.uid,
        'patientName': patientName,
        'patientEmail': user.email,
        'appointmentDate': Timestamp.fromDate(fullDateTime),
        'appointmentTime': _formatTimeOfDay(_selectedTime!),
        'appointmentType': _appointmentType,
        'fee': widget.doctorData['baseFee'] ?? 3000.0,
        'status': 'booked',
        'createdAt': FieldValue.serverTimestamp(),
        'location': patientData?['location'] ?? 'Douala',
      });

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64.sp,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Booking Successful! 🎉',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your appointment has been booked with ${widget.doctorData['name']}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=> PatientHomeScreen()));
                    //  Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }
}





















// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:sheydoc_app/core/constants/app_colors.dart';
// import 'package:uuid/uuid.dart';
//
// class AppointmentBookingScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;
//   const AppointmentBookingScreen({
//     super.key,
//     required this.doctorId,
//     required this.doctorData,
//   });
//
//   @override
//   State<AppointmentBookingScreen> createState() =>
//       _AppointmentBookingScreenState();
// }
//
// class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
//   DateTime _selectedDate = DateTime.now();
//   TimeOfDay? _selectedTime;
//   String _appointmentType = 'Video call';
//   bool _isBooking = false;
//
//   List<DateTime> _getWeekDays() {
//     final now = DateTime.now();
//     final startDay = now.subtract(Duration(days: now.weekday - 1));
//     return List.generate(7, (index) => startDay.add(Duration(days: index)));
//   }
//
//   List<TimeOfDay> _getAvailableSlots() {
//     final availability = widget.doctorData['availability'] as List?;
//
//     if (availability == null || availability.isEmpty) {
//       return [
//         const TimeOfDay(hour: 9, minute: 0),
//         const TimeOfDay(hour: 9, minute: 30),
//         const TimeOfDay(hour: 10, minute: 30),
//         const TimeOfDay(hour: 11, minute: 0),
//         const TimeOfDay(hour: 14, minute: 0),
//         const TimeOfDay(hour: 15, minute: 0),
//       ];
//     }
//
//     // Generate slots based on doctor's availability for selected day
//     final selectedDayOfWeek = _selectedDate.weekday;
//     final daySlots = availability
//         .where((slot) => slot['day'] == selectedDayOfWeek)
//         .toList();
//
//     if (daySlots.isEmpty) {
//       return [];
//     }
//
//     List<TimeOfDay> slots = [];
//     for (var slot in daySlots) {
//       final startHour = slot['startHour'] as int;
//       final startMinute = slot['startMinute'] as int;
//       final endHour = slot['endHour'] as int;
//
//       // Generate 30-minute slots
//       var currentHour = startHour;
//       var currentMinute = startMinute;
//
//       while (currentHour < endHour ||
//           (currentHour == endHour && currentMinute < slot['endMinute'])) {
//         slots.add(TimeOfDay(hour: currentHour, minute: currentMinute));
//         currentMinute += 30;
//         if (currentMinute >= 60) {
//           currentMinute = 0;
//           currentHour++;
//         }
//       }
//     }
//
//     return slots;
//   }
//
//   String _getDayName(DateTime date) {
//     const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
//     return days[date.weekday - 1];
//   }
//
//   Future<void> _bookAppointment() async {
//     if (_selectedTime == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a time slot')),
//       );
//       return;
//     }
//
//     setState(() => _isBooking = true);
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         throw Exception('User not logged in');
//       }
//
//       // Create appointment date with selected time
//       final appointmentDateTime = DateTime(
//         _selectedDate.year,
//         _selectedDate.month,
//         _selectedDate.day,
//         _selectedTime!.hour,
//         _selectedTime!.minute,
//       );
//
//       // Generate a unique call ID for the video session
//       final callId = const Uuid().v4();
//
//       // Create appointment document
//       final appointmentData = {
//         'patientId': user.uid,
//         'doctorId': widget.doctorId,
//         'doctorName': widget.doctorData['name'] ?? 'Doctor',
//         'appointmentDate': Timestamp.fromDate(appointmentDateTime),
//         'appointmentType': _appointmentType,
//         'status': 'pending', // pending, confirmed, completed, cancelled
//         'fee': widget.doctorData['baseFee'] ?? 3000.0,
//         'callId': callId,
//         'createdAt': FieldValue.serverTimestamp(),
//         'reminderSent': false,
//       };
//
//       final docRef = await FirebaseFirestore.instance
//           .collection('appointments')
//           .add(appointmentData);
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Appointment request sent successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//
//         // Navigate back to home
//         Navigator.of(context).popUntil((route) => route.isFirst);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error booking appointment: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isBooking = false);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final name = widget.doctorData['name'] ?? '';
//     final specialty = widget.doctorData['specialty'] ?? 'Gynecologist';
//     final baseFee = widget.doctorData['baseFee'] ?? 3000.0;
//     final availableSlots = _getAvailableSlots();
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Column(
//           children: [
//             Text(
//               name,
//               style: TextStyle(
//                 color: Colors.black,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 18.sp,
//               ),
//             ),
//             Text(
//               specialty,
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14.sp,
//                 fontWeight: FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(20.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Fee Section
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(16.w),
//               decoration: BoxDecoration(
//                 color: AppColors.primaryBlue.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12.r),
//               ),
//               child: Row(
//                 children: [
//                   Text(
//                     'Fee: ',
//                     style: TextStyle(
//                       fontSize: 18.sp,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                   ),
//                   Text(
//                     '${baseFee.toStringAsFixed(0)}frs',
//                     style: TextStyle(
//                       fontSize: 18.sp,
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.primaryBlue,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             SizedBox(height: 30.h),
//
//             // Appointment Type Selection
//             Text(
//               'Appointment Type',
//               style: TextStyle(
//                 fontSize: 18.sp,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             SizedBox(height: 12.h),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildTypeSelector('Audio call', Icons.phone),
//                 ),
//                 SizedBox(width: 12.w),
//                 Expanded(
//                   child: _buildTypeSelector('Video call', Icons.videocam),
//                 ),
//               ],
//             ),
//
//             SizedBox(height: 30.h),
//
//             // Date Selection
//             Text(
//               'Select Date',
//               style: TextStyle(
//                 fontSize: 18.sp,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//
//             SizedBox(height: 16.h),
//
//             // Week Calendar
//             SizedBox(
//               height: 80.h,
//               child: ListView(
//                 scrollDirection: Axis.horizontal,
//                 children: _getWeekDays().map((date) {
//                   final isSelected = date.day == _selectedDate.day &&
//                       date.month == _selectedDate.month &&
//                       date.year == _selectedDate.year;
//                   final isToday = date.day == DateTime.now().day &&
//                       date.month == DateTime.now().month &&
//                       date.year == DateTime.now().year;
//
//                   return GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         _selectedDate = date;
//                         _selectedTime = null;
//                       });
//                     },
//                     child: Container(
//                       width: 50.w,
//                       margin: EdgeInsets.only(right: 8.w),
//                       decoration: BoxDecoration(
//                         color: isSelected
//                             ? AppColors.primaryBlue
//                             : Colors.transparent,
//                         borderRadius: BorderRadius.circular(12.r),
//                         border: isToday && !isSelected
//                             ? Border.all(color: AppColors.primaryBlue, width: 1)
//                             : null,
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             _getDayName(date),
//                             style: TextStyle(
//                               fontSize: 12.sp,
//                               color: isSelected ? Colors.white : Colors.grey[600],
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           SizedBox(height: 4.h),
//                           Text(
//                             date.day.toString(),
//                             style: TextStyle(
//                               fontSize: 16.sp,
//                               fontWeight: FontWeight.bold,
//                               color: isSelected ? Colors.white : Colors.black,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//
//             SizedBox(height: 30.h),
//
//             // Available Time Section
//             Text(
//               'Available Time',
//               style: TextStyle(
//                 fontSize: 16.sp,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//
//             SizedBox(height: 16.h),
//
//             // Time Slots
//             availableSlots.isEmpty
//                 ? Center(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(vertical: 20.h),
//                 child: Text(
//                   'No available slots for this day',
//                   style: TextStyle(fontSize: 14.sp, color: Colors.grey),
//                 ),
//               ),
//             )
//                 : Wrap(
//               spacing: 12.w,
//               runSpacing: 12.h,
//               children: availableSlots.map((slot) {
//                 final isSelected = _selectedTime == slot;
//
//                 return GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _selectedTime = slot;
//                     });
//                   },
//                   child: Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: 20.w,
//                       vertical: 12.h,
//                     ),
//                     decoration: BoxDecoration(
//                       color: isSelected
//                           ? AppColors.primaryBlue
//                           : Colors.grey[100],
//                       borderRadius: BorderRadius.circular(20.r),
//                     ),
//                     child: Text(
//                       slot.format(context),
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         fontWeight: FontWeight.w500,
//                         color: isSelected ? Colors.white : Colors.black,
//                       ),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//
//             SizedBox(height: 40.h),
//
//             // Book Appointment Button
//             SizedBox(
//               width: double.infinity,
//               height: 50.h,
//               child: ElevatedButton(
//                 onPressed: _isBooking || _selectedTime == null
//                     ? null
//                     : _bookAppointment,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: _selectedTime == null
//                       ? Colors.grey[300]
//                       : AppColors.primaryBlue,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12.r),
//                   ),
//                   elevation: 0,
//                 ),
//                 child: _isBooking
//                     ? CircularProgressIndicator(color: Colors.white)
//                     : Text(
//                   'Book Appointment',
//                   style: TextStyle(
//                     fontSize: 16.sp,
//                     fontWeight: FontWeight.w600,
//                     color: _selectedTime == null
//                         ? Colors.grey[600]
//                         : Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTypeSelector(String type, IconData icon) {
//     final isSelected = _appointmentType == type;
//     return GestureDetector(
//       onTap: () => setState(() => _appointmentType = type),
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: 16.h),
//         decoration: BoxDecoration(
//           color: isSelected ? AppColors.primaryBlue : Colors.grey[100],
//           borderRadius: BorderRadius.circular(12.r),
//           border: Border.all(
//             color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               icon,
//               color: isSelected ? Colors.white : Colors.grey[700],
//               size: 20.sp,
//             ),
//             SizedBox(width: 8.w),
//             Text(
//               type,
//               style: TextStyle(
//                 fontSize: 14.sp,
//                 fontWeight: FontWeight.w500,
//                 color: isSelected ? Colors.white : Colors.black,
//               ),
//             ),
//           ],
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
// // import 'package:flutter/material.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // import 'package:sheydoc_app/core/constants/app_colors.dart';
// // import 'package:sheydoc_app/features/auth/doctors/payment_appointment_screen.dart';
// //
// //
// //
// //
// // class AppointmentBookingScreen extends StatefulWidget {
// //   final String doctorId;
// //   final Map<String, dynamic> doctorData;
// //   const AppointmentBookingScreen({super.key, required this.doctorId, required this.doctorData});
// //
// //   @override
// //   State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
// // }
// //
// // class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
// //   DateTime _selectedDate = DateTime.now();
// //   TimeOfDay? _selectedTime;
// //   final PageController _pageController = PageController();
// //   int _currentWeekIndex = 0;
// //
// //   List<DateTime> _getWeekDays(int weekOffset) {
// //     final now = DateTime.now();
// //     final startOfWeek = now.add(Duration(days: weekOffset * 7));
// //     final startDay = startOfWeek.subtract(Duration(days: startOfWeek.weekday - 1));
// //
// //     return List.generate(7, (index) => startDay.add(Duration(days: index)));
// //   }
// //
// //   List<TimeOfDay> _getAvailableSlots() {
// //     // This should be based on doctor's availability from doctorData
// //     final availability = widget.doctorData['availability'] as List?;
// //
// //     // For now, return some default slots - you can enhance this based on your data structure
// //     return [
// //       const TimeOfDay(hour: 9, minute: 0),
// //       const TimeOfDay(hour: 9, minute: 30),
// //       const TimeOfDay(hour: 10, minute: 30),
// //       const TimeOfDay(hour: 11, minute: 0),
// //     ];
// //   }
// //
// //   String _getDayName(DateTime date) {
// //     const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
// //     return days[date.weekday - 1];
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final name = widget.doctorData['name'] ?? '';
// //     final specialty = widget.doctorData['specialty'] ?? 'Gynecologist';
// //     final baseFee = widget.doctorData['baseFee'] ?? 3000.0;
// //
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: AppBar(
// //         title: Column(
// //           children: [
// //             Text(
// //               name,
// //               style: TextStyle(
// //                 color: Colors.black,
// //                 fontWeight: FontWeight.w600,
// //                 fontSize: 18.sp,
// //               ),
// //             ),
// //             Text(
// //               specialty,
// //               style: TextStyle(
// //                 color: Colors.grey[600],
// //                 fontSize: 14.sp,
// //                 fontWeight: FontWeight.normal,
// //               ),
// //             ),
// //           ],
// //         ),
// //         backgroundColor: Colors.white,
// //         elevation: 0,
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back, color: Colors.black),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //       ),
// //       body: SingleChildScrollView(
// //         padding: EdgeInsets.all(20.w),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // Fee Section
// //             Container(
// //               width: double.infinity,
// //               padding: EdgeInsets.all(16.w),
// //               decoration: BoxDecoration(
// //                 color: AppColors.primaryBlue.withOpacity(0.1),
// //                 borderRadius: BorderRadius.circular(12.r),
// //               ),
// //               child: Row(
// //                 children: [
// //                   Text(
// //                     'Fee: ',
// //                     style: TextStyle(
// //                       fontSize: 18.sp,
// //                       fontWeight: FontWeight.w600,
// //                       color: Colors.black,
// //                     ),
// //                   ),
// //                   Text(
// //                     '${baseFee.toStringAsFixed(0)}frs',
// //                     style: TextStyle(
// //                       fontSize: 18.sp,
// //                       fontWeight: FontWeight.bold,
// //                       color: AppColors.primaryBlue,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             SizedBox(height: 30.h),
// //
// //             // Appointment Section
// //             Text(
// //               'Appointment',
// //               style: TextStyle(
// //                 fontSize: 20.sp,
// //                 fontWeight: FontWeight.bold,
// //                 color: Colors.black,
// //               ),
// //             ),
// //
// //             SizedBox(height: 20.h),
// //
// //             // Week Calendar
// //             SizedBox(
// //               height: 80.h,
// //               child: Row(
// //                 children: _getWeekDays(_currentWeekIndex).map((date) {
// //                   final isSelected = date.day == _selectedDate.day &&
// //                       date.month == _selectedDate.month &&
// //                       date.year == _selectedDate.year;
// //                   final isToday = date.day == DateTime.now().day &&
// //                       date.month == DateTime.now().month &&
// //                       date.year == DateTime.now().year;
// //
// //                   return Expanded(
// //                     child: GestureDetector(
// //                       onTap: () {
// //                         setState(() {
// //                           _selectedDate = date;
// //                           _selectedTime = null; // Reset selected time when date changes
// //                         });
// //                       },
// //                       child: Container(
// //                         margin: EdgeInsets.symmetric(horizontal: 2.w),
// //                         decoration: BoxDecoration(
// //                           color: isSelected ? AppColors.primaryBlue : Colors.transparent,
// //                           borderRadius: BorderRadius.circular(12.r),
// //                           border: isToday && !isSelected
// //                               ? Border.all(color: AppColors.primaryBlue, width: 1)
// //                               : null,
// //                         ),
// //                         child: Column(
// //                           mainAxisAlignment: MainAxisAlignment.center,
// //                           children: [
// //                             Text(
// //                               _getDayName(date),
// //                               style: TextStyle(
// //                                 fontSize: 12.sp,
// //                                 color: isSelected ? Colors.white : Colors.grey[600],
// //                                 fontWeight: FontWeight.w500,
// //                               ),
// //                             ),
// //                             SizedBox(height: 4.h),
// //                             Text(
// //                               date.day.toString(),
// //                               style: TextStyle(
// //                                 fontSize: 16.sp,
// //                                 fontWeight: FontWeight.bold,
// //                                 color: isSelected ? Colors.white : Colors.black,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                   );
// //                 }).toList(),
// //               ),
// //             ),
// //
// //             SizedBox(height: 30.h),
// //
// //             // Available Time Section
// //             Text(
// //               'Available Time',
// //               style: TextStyle(
// //                 fontSize: 16.sp,
// //                 fontWeight: FontWeight.bold,
// //                 color: Colors.black,
// //               ),
// //             ),
// //
// //             SizedBox(height: 16.h),
// //
// //             // Time Slots
// //             Wrap(
// //               spacing: 12.w,
// //               runSpacing: 12.h,
// //               children: _getAvailableSlots().map((slot) {
// //                 final isSelected = _selectedTime == slot;
// //
// //                 return GestureDetector(
// //                   onTap: () {
// //                     setState(() {
// //                       _selectedTime = slot;
// //                     });
// //                   },
// //                   child: Container(
// //                     padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
// //                     decoration: BoxDecoration(
// //                       color: isSelected ? AppColors.primaryBlue : Colors.grey[100],
// //                       borderRadius: BorderRadius.circular(20.r),
// //                     ),
// //                     child: Text(
// //                       slot.format(context),
// //                       style: TextStyle(
// //                         fontSize: 14.sp,
// //                         fontWeight: FontWeight.w500,
// //                         color: isSelected ? Colors.white : Colors.black,
// //                       ),
// //                     ),
// //                   ),
// //                 );
// //               }).toList(),
// //             ),
// //
// //             SizedBox(height: 40.h),
// //
// //             // Confirm and Pay Button
// //             SizedBox(
// //               width: double.infinity,
// //               height: 50.h,
// //               child: ElevatedButton(
// //                 // onPressed: _selectedTime == null
// //                 //     ? null
// //                 //     : () {
// //                 //   Navigator.push(
// //                 //     context,
// //                 //     MaterialPageRoute(
// //                 //       builder: (context) => PaymentMethodScreen(
// //                 //         appointmentData: {
// //                 //           'doctorId': widget.doctorId,
// //                 //           'doctorName': widget.doctorData['name'],
// //                 //           'date': _selectedDate,
// //                 //           'time': _selectedTime,
// //                 //           'price': baseFee,
// //                 //         },
// //                 //       ),
// //                 //     ),
// //                 //   );
// //                 // },
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: _selectedTime == null
// //                       ? Colors.grey[300]
// //                       : AppColors.primaryBlue,
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(12.r),
// //                   ),
// //                   elevation: 0,
// //                 ),
// //                 onPressed: () {  },
// //                 child: Text(
// //                   'Confirm and Pay',
// //                   style: TextStyle(
// //                     fontSize: 16.sp,
// //                     fontWeight: FontWeight.w600,
// //                     color: _selectedTime == null ? Colors.grey[600] : Colors.white,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // // import 'package:sheydoc_app/core/constants/app_colors.dart';
// // // import 'package:sheydoc_app/features/auth/doctors/payment_appointment_screen.dart';
// // // import 'package:table_calendar/table_calendar.dart';
// // //
// // // class AppointmentBookingScreen extends StatefulWidget {
// // //   final String doctorId;
// // //   final Map<String, dynamic> doctorData;
// // //   const AppointmentBookingScreen({super.key, required this.doctorId, required this.doctorData});
// // //
// // //   @override
// // //   State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
// // // }
// // //
// // // class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
// // //   DateTime _selectedDate = DateTime.now();
// // //   TimeOfDay? _selectedTime;
// // //
// // //   List<TimeOfDay> getAvailableSlots() {
// // //     // Placeholder logic based on availability
// // //     return [
// // //       const TimeOfDay(hour: 9, minute: 0),
// // //       const TimeOfDay(hour: 9, minute: 30),
// // //       const TimeOfDay(hour: 10, minute: 0),
// // //       const TimeOfDay(hour: 10, minute: 30),
// // //     ];
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final name = widget.doctorData['name'] ?? '';
// // //     final baseFee = widget.doctorData['baseFee'] ?? 3000.0;
// // //
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: Text('$name - Gynecologist'),
// // //         backgroundColor: AppColors.backgroundColor,
// // //         elevation: 0,
// // //       ),
// // //       body: SingleChildScrollView(
// // //         padding: EdgeInsets.all(16.w),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             Text(
// // //               'Fee: ${baseFee.toStringAsFixed(0)} FCFA',
// // //               style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
// // //             ),
// // //             SizedBox(height: 16.h),
// // //             TableCalendar(
// // //               firstDay: DateTime.now(),
// // //               lastDay: DateTime.now().add(const Duration(days: 7)),
// // //               focusedDay: _selectedDate,
// // //               selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
// // //               onDaySelected: (selected, focused) => setState(() => _selectedDate = selected),
// // //             ),
// // //             SizedBox(height: 16.h),
// // //             Text(
// // //               'Available Time',
// // //               style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
// // //             ),
// // //             Wrap(
// // //               spacing: 8.w,
// // //               runSpacing: 8.h,
// // //               children: getAvailableSlots().map((slot) {
// // //                 return ElevatedButton(
// // //                   onPressed: () => setState(() => _selectedTime = slot),
// // //                   style: ElevatedButton.styleFrom(
// // //                     backgroundColor: _selectedTime == slot ? AppColors.primaryBlue : Colors.grey[200],
// // //                     foregroundColor: _selectedTime == slot ? Colors.white : Colors.black,
// // //                   ),
// // //                   child: Text(slot.format(context)),
// // //                 );
// // //               }).toList(),
// // //             ),
// // //             SizedBox(height: 20.h),
// // //             ElevatedButton(
// // //               onPressed: _selectedTime == null
// // //                   ? null
// // //                   : () {
// // //                 Navigator.push(
// // //                   context,
// // //                   MaterialPageRoute(
// // //                     builder: (context) => PaymentMethodScreen(
// // //                       appointmentData: {
// // //                         'doctorId': widget.doctorId,
// // //                         'doctorName': widget.doctorData['name'],
// // //                         'date': _selectedDate,
// // //                         'time': _selectedTime,
// // //                         'price': baseFee,
// // //                       },
// // //                     ),
// // //                   ),
// // //                 );
// // //               },
// // //               style: ElevatedButton.styleFrom(
// // //                 backgroundColor: AppColors.primaryBlue,
// // //                 minimumSize: Size(double.infinity, 50.h),
// // //               ),
// // //               child: const Text('Confirm and Pay'),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }