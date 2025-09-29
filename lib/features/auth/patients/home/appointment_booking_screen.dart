import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sheydoc_app/core/constants/app_colors.dart';
import 'package:sheydoc_app/features/auth/doctors/payment_appointment_screen.dart';
import 'package:table_calendar/table_calendar.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;
  const AppointmentBookingScreen({super.key, required this.doctorId, required this.doctorData});

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;

  List<TimeOfDay> getAvailableSlots() {
    // Placeholder logic based on availability
    return [
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 9, minute: 30),
      const TimeOfDay(hour: 10, minute: 0),
      const TimeOfDay(hour: 10, minute: 30),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.doctorData['name'] ?? '';
    final baseFee = widget.doctorData['baseFee'] ?? 3000.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('$name - Gynecologist'),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fee: ${baseFee.toStringAsFixed(0)} FCFA',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 7)),
              focusedDay: _selectedDate,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: (selected, focused) => setState(() => _selectedDate = selected),
            ),
            SizedBox(height: 16.h),
            Text(
              'Available Time',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: getAvailableSlots().map((slot) {
                return ElevatedButton(
                  onPressed: () => setState(() => _selectedTime = slot),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTime == slot ? AppColors.primaryBlue : Colors.grey[200],
                    foregroundColor: _selectedTime == slot ? Colors.white : Colors.black,
                  ),
                  child: Text(slot.format(context)),
                );
              }).toList(),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: _selectedTime == null
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentMethodScreen(
                      appointmentData: {
                        'doctorId': widget.doctorId,
                        'doctorName': widget.doctorData['name'],
                        'date': _selectedDate,
                        'time': _selectedTime,
                        'price': baseFee,
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: Size(double.infinity, 50.h),
              ),
              child: const Text('Confirm and Pay'),
            ),
          ],
        ),
      ),
    );
  }
}