// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sheydoc_app/core/constants/app_colors.dart';
// import 'package:sheydoc_app/services/payment_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class PaymentMethodScreen extends StatefulWidget {
//   final Map<String, dynamic> appointmentData;
//   const PaymentMethodScreen({super.key, required this.appointmentData});
//
//   @override
//   State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
// }
//
// class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
//   String _selectedService = 'MTN'; // Default to MTN
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _amountController = TextEditingController();
//   bool _isProcessing = false;
//   String _countryCode = '+237'; // Cameroon
//
//   @override
//   void initState() {
//     super.initState();
//     // Pre-fill amount from appointment data
//     final price = widget.appointmentData['price'] ?? 0;
//     _amountController.text = price.toStringAsFixed(0);
//   }
//
//   @override
//   void dispose() {
//     _phoneController.dispose();
//     _amountController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _processPayment() async {
//     // Validation
//     if (_phoneController.text.trim().isEmpty) {
//       _showError('Please enter your phone number');
//       return;
//     }
//
//     String phone = _phoneController.text.trim().replaceAll(' ', '');
//
//     // Remove country code if present
//     if (phone.startsWith('+237')) {
//       phone = phone.substring(4);
//     } else if (phone.startsWith('237')) {
//       phone = phone.substring(3);
//     } else if (phone.startsWith('0')) {
//       phone = phone.substring(1);
//     }
//
//     // Validate phone number length
//     if (phone.length != 9) {
//       _showError('Please enter a valid 9-digit phone number');
//       return;
//     }
//
//     // Validate amount
//     final amount = double.tryParse(_amountController.text);
//     if (amount == null || amount <= 0) {
//       _showError('Invalid amount');
//       return;
//     }
//
//     setState(() => _isProcessing = true);
//
//     try {
//       final paymentService = PaymentService();
//
//       print('📱 Processing payment for: $phone');
//       print('💰 Amount: $amount XAF');
//       print('🏦 Service: $_selectedService');
//
//       // Make payment using the correct API
//       final response = await paymentService.collectPayment(
//         amount: amount,
//         service: _selectedService,
//         payer: phone, country:"CM", fees: true,
//       );
//
//       if (response.isTransactionSuccess()) {
//         // Payment successful, create appointment
//         await _createAppointment(response.toJson());
//
//         if (mounted) {
//           _showSuccessDialog();
//         }
//       } else {
//         _showError('Payment failed. Please check your account and try again.');
//       }
//     } catch (e) {
//       print('❌ Payment error: $e');
//       String errorMessage = 'Payment failed: ${e.toString()}';
//
//       // Handle common errors
//       if (e.toString().contains('insufficient')) {
//         errorMessage = 'Insufficient balance. Please check your account.';
//       } else if (e.toString().contains('timeout')) {
//         errorMessage = 'Request timeout. Please check your connection.';
//       } else if (e.toString().contains('invalid')) {
//         errorMessage = 'Invalid phone number or service.';
//       }
//
//       _showError(errorMessage);
//     } finally {
//       if (mounted) {
//         setState(() => _isProcessing = false);
//       }
//     }
//   }
//
//   Future<void> _createAppointment(Map<String, dynamic> paymentData) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       throw Exception('User not authenticated');
//     }
//
//     final firestore = FirebaseFirestore.instance;
//
//     // Create appointment document
//     await firestore.collection('appointments').add({
//       'patientId': user.uid,
//       'doctorId': widget.appointmentData['doctorId'],
//       'doctorName': widget.appointmentData['doctorName'],
//       'date': Timestamp.fromDate(widget.appointmentData['date']),
//       'time': {
//         'hour': widget.appointmentData['time'].hour,
//         'minute': widget.appointmentData['time'].minute,
//       },
//       'price': widget.appointmentData['price'],
//       'status': 'confirmed', // pending, confirmed, completed, cancelled
//       'paymentStatus': 'paid',
//       'paymentMethod': _selectedService,
//       'paymentData': paymentData,
//       'createdAt': FieldValue.serverTimestamp(),
//     });
//
//     print('✅ Appointment created successfully');
//   }
//
//   void _showError(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 4),
//       ),
//     );
//   }
//
//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.check_circle, color: Colors.green, size: 64.sp),
//             SizedBox(height: 16.h),
//             Text(
//               'Payment Successful!',
//               style: TextStyle(
//                 fontSize: 20.sp,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 8.h),
//             Text(
//               'Your appointment has been confirmed.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14.sp,
//                 color: Colors.grey[600],
//               ),
//             ),
//             SizedBox(height: 24.h),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   // Navigate back to home or appointments screen
//                   Navigator.of(context).popUntil((route) => route.isFirst);
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primaryBlue,
//                   padding: EdgeInsets.symmetric(vertical: 12.h),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8.r),
//                   ),
//                 ),
//                 child: Text(
//                   'Done',
//                   style: TextStyle(
//                     fontSize: 16.sp,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
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
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Text(
//           'Payment Method',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.w600,
//             fontSize: 18.sp,
//           ),
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
//             // Payment Method Selection
//             Text(
//               'Select Your Payment Method',
//               style: TextStyle(
//                 fontSize: 16.sp,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black,
//               ),
//             ),
//             SizedBox(height: 16.h),
//
//             // MTN Mobile Money
//             _buildPaymentOption(
//               service: 'MTN',
//               logo: 'MTN',
//               color: Colors.yellow[700]!,
//               title: 'MTN Mobile Money',
//             ),
//
//             SizedBox(height: 12.h),
//
//             // Orange Money
//             _buildPaymentOption(
//               service: 'ORANGE',
//               logo: '🟠',
//               color: Colors.orange[600]!,
//               title: 'Orange Money',
//             ),
//
//             SizedBox(height: 32.h),
//
//             // Form Section
//             Text(
//               'Fill the form and make payment',
//               style: TextStyle(
//                 fontSize: 16.sp,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black,
//               ),
//             ),
//
//             SizedBox(height: 20.h),
//
//             // Phone Number Field
//             Text(
//               'Enter Phone Number',
//               style: TextStyle(
//                 fontSize: 14.sp,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[700],
//               ),
//             ),
//             SizedBox(height: 8.h),
//             Row(
//               children: [
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey[300]!),
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(8.r),
//                       bottomLeft: Radius.circular(8.r),
//                     ),
//                     color: Colors.grey[100],
//                   ),
//                   child: Row(
//                     children: [
//                       Text(
//                         _countryCode,
//                         style: TextStyle(
//                           fontSize: 16.sp,
//                           color: Colors.black,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       Icon(Icons.arrow_drop_down, size: 20.sp),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: TextField(
//                     controller: _phoneController,
//                     keyboardType: TextInputType.phone,
//                     maxLength: 9,
//                     decoration: InputDecoration(
//                       hintText: '678549090',
//                       hintStyle: TextStyle(color: Colors.grey[400]),
//                       counterText: '',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.only(
//                           topRight: Radius.circular(8.r),
//                           bottomRight: Radius.circular(8.r),
//                         ),
//                         borderSide: BorderSide(color: Colors.grey[300]!),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.only(
//                           topRight: Radius.circular(8.r),
//                           bottomRight: Radius.circular(8.r),
//                         ),
//                         borderSide: BorderSide(color: Colors.grey[300]!),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.only(
//                           topRight: Radius.circular(8.r),
//                           bottomRight: Radius.circular(8.r),
//                         ),
//                         borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
//                       ),
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 16.w,
//                         vertical: 16.h,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             SizedBox(height: 20.h),
//
//             // Amount Field
//             Text(
//               'Enter Amount',
//               style: TextStyle(
//                 fontSize: 14.sp,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[700],
//               ),
//             ),
//             SizedBox(height: 8.h),
//             TextField(
//               controller: _amountController,
//               keyboardType: TextInputType.number,
//               readOnly: true,
//               decoration: InputDecoration(
//                 hintText: '3000',
//                 hintStyle: TextStyle(color: Colors.grey[400]),
//                 suffixText: 'XAF',
//                 suffixStyle: TextStyle(
//                   color: Colors.grey[600],
//                   fontWeight: FontWeight.w500,
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.r),
//                   borderSide: BorderSide(color: Colors.grey[300]!),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.r),
//                   borderSide: BorderSide(color: Colors.grey[300]!),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.r),
//                   borderSide: BorderSide(color: AppColors.primaryBlue),
//                 ),
//                 contentPadding: EdgeInsets.symmetric(
//                   horizontal: 16.w,
//                   vertical: 16.h,
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[100],
//               ),
//             ),
//
//             SizedBox(height: 32.h),
//
//             // Info Box
//             Container(
//               padding: EdgeInsets.all(12.w),
//               decoration: BoxDecoration(
//                 color: Colors.blue[50],
//                 borderRadius: BorderRadius.circular(8.r),
//                 border: Border.all(color: Colors.blue[200]!),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.info_outline, color: Colors.blue[700], size: 20.sp),
//                   SizedBox(width: 8.w),
//                   Expanded(
//                     child: Text(
//                       'You will receive a prompt on your phone to confirm the payment',
//                       style: TextStyle(
//                         fontSize: 12.sp,
//                         color: Colors.blue[900],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             SizedBox(height: 32.h),
//
//             // Pay Button
//             SizedBox(
//               width: double.infinity,
//               height: 50.h,
//               child: ElevatedButton(
//                 onPressed: _isProcessing ? null : _processPayment,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primaryBlue,
//                   disabledBackgroundColor: Colors.grey[300],
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12.r),
//                   ),
//                   elevation: 0,
//                 ),
//                 child: _isProcessing
//                     ? Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     SizedBox(
//                       height: 20.h,
//                       width: 20.w,
//                       child: const CircularProgressIndicator(
//                         color: Colors.white,
//                         strokeWidth: 2,
//                       ),
//                     ),
//                     SizedBox(width: 12.w),
//                     Text(
//                       'Processing...',
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 )
//                     : Text(
//                   'Pay now',
//                   style: TextStyle(
//                     fontSize: 16.sp,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
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
//   Widget _buildPaymentOption({
//     required String service,
//     required String logo,
//     required Color color,
//     required String title,
//   }) {
//     final isSelected = _selectedService == service;
//
//     return GestureDetector(
//       onTap: () => setState(() => _selectedService = service),
//       child: Container(
//         padding: EdgeInsets.all(16.w),
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
//             width: isSelected ? 2 : 1,
//           ),
//           borderRadius: BorderRadius.circular(12.r),
//           color: isSelected
//               ? AppColors.primaryBlue.withOpacity(0.05)
//               : Colors.white,
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 40.w,
//               height: 40.w,
//               decoration: BoxDecoration(
//                 color: color,
//                 borderRadius: BorderRadius.circular(8.r),
//               ),
//               child: Center(
//                 child: Text(
//                   logo,
//                   style: TextStyle(
//                     color: service == 'MTN' ? Colors.black : Colors.white,
//                     fontSize: service == 'MTN' ? 12.sp : 20.sp,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(width: 12.w),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 16.sp,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black,
//               ),
//             ),
//             const Spacer(),
//             Icon(
//               isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
//               color: isSelected ? AppColors.primaryBlue : Colors.grey[400],
//               size: 24.sp,
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
// // import 'package:sheydoc_app/services/payment_service.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// //
// // class PaymentMethodScreen extends StatefulWidget {
// //   final Map<String, dynamic> appointmentData;
// //   const PaymentMethodScreen({super.key, required this.appointmentData});
// //
// //   @override
// //   State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
// // }
// //
// // class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
// //   String _selectedService = 'MTN'; // Default to MTN
// //   final TextEditingController _phoneController = TextEditingController();
// //   final TextEditingController _amountController = TextEditingController();
// //   bool _isProcessing = false;
// //   String _countryCode = '+237'; // Cameroon
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     // Pre-fill amount from appointment data
// //     final price = widget.appointmentData['price'] ?? 0;
// //     _amountController.text = price.toStringAsFixed(0);
// //   }
// //
// //   @override
// //   void dispose() {
// //     _phoneController.dispose();
// //     _amountController.dispose();
// //     super.dispose();
// //   }
// //
// //   Future<void> _processPayment() async {
// //     // Validation
// //     if (_phoneController.text.trim().isEmpty) {
// //       _showError('Please enter your phone number');
// //       return;
// //     }
// //
// //     String phone = _phoneController.text.trim().replaceAll(' ', '');
// //
// //     // Remove country code if present
// //     if (phone.startsWith('+237')) {
// //       phone = phone.substring(4);
// //     } else if (phone.startsWith('237')) {
// //       phone = phone.substring(3);
// //     } else if (phone.startsWith('0')) {
// //       phone = phone.substring(1);
// //     }
// //
// //     // Validate phone number length
// //     if (phone.length != 9) {
// //       _showError('Please enter a valid 9-digit phone number');
// //       return;
// //     }
// //
// //     // Validate amount
// //     final amount = double.tryParse(_amountController.text);
// //     if (amount == null || amount <= 0) {
// //       _showError('Invalid amount');
// //       return;
// //     }
// //
// //     setState(() => _isProcessing = true);
// //
// //     try {
// //       final paymentService = PaymentService();
// //
// //       print('📱 Processing payment for: $phone');
// //       print('💰 Amount: $amount XAF');
// //       print('🏦 Service: $_selectedService');
// //
// //       // Make payment using the correct API
// //       final response = await paymentService.collectPayment(
// //         amount: amount,
// //         service: _selectedService,
// //         payer: phone,
// //       );
// //
// //       if (response.isTransactionSuccess()) {
// //         // Payment successful, create appointment
// //         await _createAppointment(response.toJson());
// //
// //         if (mounted) {
// //           _showSuccessDialog();
// //         }
// //       } else {
// //         _showError('Payment failed. Please check your account and try again.');
// //       }
// //     } catch (e) {
// //       print('❌ Payment error: $e');
// //       String errorMessage = 'Payment failed: ${e.toString()}';
// //
// //       // Handle common errors
// //       if (e.toString().contains('insufficient')) {
// //         errorMessage = 'Insufficient balance. Please check your account.';
// //       } else if (e.toString().contains('timeout')) {
// //         errorMessage = 'Request timeout. Please check your connection.';
// //       } else if (e.toString().contains('invalid')) {
// //         errorMessage = 'Invalid phone number or service.';
// //       }
// //
// //       _showError(errorMessage);
// //     } finally {
// //       if (mounted) {
// //         setState(() => _isProcessing = false);
// //       }
// //     }
// //   }
// //
// //   Future<void> _createAppointment(Map<String, dynamic> paymentData) async {
// //     final user = FirebaseAuth.instance.currentUser;
// //     if (user == null) {
// //       throw Exception('User not authenticated');
// //     }
// //
// //     final firestore = FirebaseFirestore.instance;
// //
// //     // Create appointment document
// //     await firestore.collection('appointments').add({
// //       'patientId': user.uid,
// //       'doctorId': widget.appointmentData['doctorId'],
// //       'doctorName': widget.appointmentData['doctorName'],
// //       'date': Timestamp.fromDate(widget.appointmentData['date']),
// //       'time': {
// //         'hour': widget.appointmentData['time'].hour,
// //         'minute': widget.appointmentData['time'].minute,
// //       },
// //       'price': widget.appointmentData['price'],
// //       'status': 'confirmed', // pending, confirmed, completed, cancelled
// //       'paymentStatus': 'paid',
// //       'paymentMethod': _selectedService,
// //       'paymentData': paymentData,
// //       'createdAt': FieldValue.serverTimestamp(),
// //     });
// //
// //     print('✅ Appointment created successfully');
// //   }
// //
// //   void _showError(String message) {
// //     if (!mounted) return;
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: Colors.red,
// //         behavior: SnackBarBehavior.floating,
// //         duration: const Duration(seconds: 4),
// //       ),
// //     );
// //   }
// //
// //   void _showSuccessDialog() {
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (context) => AlertDialog(
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(Icons.check_circle, color: Colors.green, size: 64.sp),
// //             SizedBox(height: 16.h),
// //             Text(
// //               'Payment Successful!',
// //               style: TextStyle(
// //                 fontSize: 20.sp,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             SizedBox(height: 8.h),
// //             Text(
// //               'Your appointment has been confirmed.',
// //               textAlign: TextAlign.center,
// //               style: TextStyle(
// //                 fontSize: 14.sp,
// //                 color: Colors.grey[600],
// //               ),
// //             ),
// //             SizedBox(height: 24.h),
// //             SizedBox(
// //               width: double.infinity,
// //               child: ElevatedButton(
// //                 onPressed: () {
// //                   // Navigate back to home or appointments screen
// //                   Navigator.of(context).popUntil((route) => route.isFirst);
// //                 },
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: AppColors.primaryBlue,
// //                   padding: EdgeInsets.symmetric(vertical: 12.h),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(8.r),
// //                   ),
// //                 ),
// //                 child: Text(
// //                   'Done',
// //                   style: TextStyle(
// //                     fontSize: 16.sp,
// //                     fontWeight: FontWeight.w600,
// //                     color: Colors.white,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: AppBar(
// //         title: Text(
// //           'Payment Method',
// //           style: TextStyle(
// //             color: Colors.black,
// //             fontWeight: FontWeight.w600,
// //             fontSize: 18.sp,
// //           ),
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
// //             // Payment Method Selection
// //             Text(
// //               'Select Your Payment Method',
// //               style: TextStyle(
// //                 fontSize: 16.sp,
// //                 fontWeight: FontWeight.w600,
// //                 color: Colors.black,
// //               ),
// //             ),
// //             SizedBox(height: 16.h),
// //
// //             // MTN Mobile Money
// //             _buildPaymentOption(
// //               service: 'MTN',
// //               logo: 'MTN',
// //               color: Colors.yellow[700]!,
// //               title: 'MTN Mobile Money',
// //             ),
// //
// //             SizedBox(height: 12.h),
// //
// //             // Orange Money
// //             _buildPaymentOption(
// //               service: 'ORANGE',
// //               logo: '🟠',
// //               color: Colors.orange[600]!,
// //               title: 'Orange Money',
// //             ),
// //
// //             SizedBox(height: 32.h),
// //
// //             // Form Section
// //             Text(
// //               'Fill the form and make payment',
// //               style: TextStyle(
// //                 fontSize: 16.sp,
// //                 fontWeight: FontWeight.w600,
// //                 color: Colors.black,
// //               ),
// //             ),
// //
// //             SizedBox(height: 20.h),
// //
// //             // Phone Number Field
// //             Text(
// //               'Enter Phone Number',
// //               style: TextStyle(
// //                 fontSize: 14.sp,
// //                 fontWeight: FontWeight.w500,
// //                 color: Colors.grey[700],
// //               ),
// //             ),
// //             SizedBox(height: 8.h),
// //             Row(
// //               children: [
// //                 Container(
// //                   padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
// //                   decoration: BoxDecoration(
// //                     border: Border.all(color: Colors.grey[300]!),
// //                     borderRadius: BorderRadius.only(
// //                       topLeft: Radius.circular(8.r),
// //                       bottomLeft: Radius.circular(8.r),
// //                     ),
// //                     color: Colors.grey[100],
// //                   ),
// //                   child: Row(
// //                     children: [
// //                       Text(
// //                         _countryCode,
// //                         style: TextStyle(
// //                           fontSize: 16.sp,
// //                           color: Colors.black,
// //                           fontWeight: FontWeight.w500,
// //                         ),
// //                       ),
// //                       Icon(Icons.arrow_drop_down, size: 20.sp),
// //                     ],
// //                   ),
// //                 ),
// //                 Expanded(
// //                   child: TextField(
// //                     controller: _phoneController,
// //                     keyboardType: TextInputType.phone,
// //                     maxLength: 9,
// //                     decoration: InputDecoration(
// //                       hintText: '678549090',
// //                       hintStyle: TextStyle(color: Colors.grey[400]),
// //                       counterText: '',
// //                       border: OutlineInputBorder(
// //                         borderRadius: BorderRadius.only(
// //                           topRight: Radius.circular(8.r),
// //                           bottomRight: Radius.circular(8.r),
// //                         ),
// //                         borderSide: BorderSide(color: Colors.grey[300]!),
// //                       ),
// //                       enabledBorder: OutlineInputBorder(
// //                         borderRadius: BorderRadius.only(
// //                           topRight: Radius.circular(8.r),
// //                           bottomRight: Radius.circular(8.r),
// //                         ),
// //                         borderSide: BorderSide(color: Colors.grey[300]!),
// //                       ),
// //                       focusedBorder: OutlineInputBorder(
// //                         borderRadius: BorderRadius.only(
// //                           topRight: Radius.circular(8.r),
// //                           bottomRight: Radius.circular(8.r),
// //                         ),
// //                         borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
// //                       ),
// //                       contentPadding: EdgeInsets.symmetric(
// //                         horizontal: 16.w,
// //                         vertical: 16.h,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //
// //             SizedBox(height: 20.h),
// //
// //             // Amount Field
// //             Text(
// //               'Enter Amount',
// //               style: TextStyle(
// //                 fontSize: 14.sp,
// //                 fontWeight: FontWeight.w500,
// //                 color: Colors.grey[700],
// //               ),
// //             ),
// //             SizedBox(height: 8.h),
// //             TextField(
// //               controller: _amountController,
// //               keyboardType: TextInputType.number,
// //               readOnly: true,
// //               decoration: InputDecoration(
// //                 hintText: '3000',
// //                 hintStyle: TextStyle(color: Colors.grey[400]),
// //                 suffixText: 'XAF',
// //                 suffixStyle: TextStyle(
// //                   color: Colors.grey[600],
// //                   fontWeight: FontWeight.w500,
// //                 ),
// //                 border: OutlineInputBorder(
// //                   borderRadius: BorderRadius.circular(8.r),
// //                   borderSide: BorderSide(color: Colors.grey[300]!),
// //                 ),
// //                 enabledBorder: OutlineInputBorder(
// //                   borderRadius: BorderRadius.circular(8.r),
// //                   borderSide: BorderSide(color: Colors.grey[300]!),
// //                 ),
// //                 focusedBorder: OutlineInputBorder(
// //                   borderRadius: BorderRadius.circular(8.r),
// //                   borderSide: BorderSide(color: AppColors.primaryBlue),
// //                 ),
// //                 contentPadding: EdgeInsets.symmetric(
// //                   horizontal: 16.w,
// //                   vertical: 16.h,
// //                 ),
// //                 filled: true,
// //                 fillColor: Colors.grey[100],
// //               ),
// //             ),
// //
// //             SizedBox(height: 32.h),
// //
// //             // Info Box
// //             Container(
// //               padding: EdgeInsets.all(12.w),
// //               decoration: BoxDecoration(
// //                 color: Colors.blue[50],
// //                 borderRadius: BorderRadius.circular(8.r),
// //                 border: Border.all(color: Colors.blue[200]!),
// //               ),
// //               child: Row(
// //                 children: [
// //                   Icon(Icons.info_outline, color: Colors.blue[700], size: 20.sp),
// //                   SizedBox(width: 8.w),
// //                   Expanded(
// //                     child: Text(
// //                       'You will receive a prompt on your phone to confirm the payment',
// //                       style: TextStyle(
// //                         fontSize: 12.sp,
// //                         color: Colors.blue[900],
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             SizedBox(height: 32.h),
// //
// //             // Pay Button
// //             SizedBox(
// //               width: double.infinity,
// //               height: 50.h,
// //               child: ElevatedButton(
// //                 onPressed: _isProcessing ? null : _processPayment,
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: AppColors.primaryBlue,
// //                   disabledBackgroundColor: Colors.grey[300],
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(12.r),
// //                   ),
// //                   elevation: 0,
// //                 ),
// //                 child: _isProcessing
// //                     ? Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     SizedBox(
// //                       height: 20.h,
// //                       width: 20.w,
// //                       child: const CircularProgressIndicator(
// //                         color: Colors.white,
// //                         strokeWidth: 2,
// //                       ),
// //                     ),
// //                     SizedBox(width: 12.w),
// //                     Text(
// //                       'Processing...',
// //                       style: TextStyle(
// //                         fontSize: 16.sp,
// //                         fontWeight: FontWeight.w600,
// //                         color: Colors.white,
// //                       ),
// //                     ),
// //                   ],
// //                 )
// //                     : Text(
// //                   'Pay now',
// //                   style: TextStyle(
// //                     fontSize: 16.sp,
// //                     fontWeight: FontWeight.w600,
// //                     color: Colors.white,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildPaymentOption({
// //     required String service,
// //     required String logo,
// //     required Color color,
// //     required String title,
// //   }) {
// //     final isSelected = _selectedService == service;
// //
// //     return GestureDetector(
// //       onTap: () => setState(() => _selectedService = service),
// //       child: Container(
// //         padding: EdgeInsets.all(16.w),
// //         decoration: BoxDecoration(
// //           border: Border.all(
// //             color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
// //             width: isSelected ? 2 : 1,
// //           ),
// //           borderRadius: BorderRadius.circular(12.r),
// //           color: isSelected
// //               ? AppColors.primaryBlue.withOpacity(0.05)
// //               : Colors.white,
// //         ),
// //         child: Row(
// //           children: [
// //             Container(
// //               width: 40.w,
// //               height: 40.w,
// //               decoration: BoxDecoration(
// //                 color: color,
// //                 borderRadius: BorderRadius.circular(8.r),
// //               ),
// //               child: Center(
// //                 child: Text(
// //                   logo,
// //                   style: TextStyle(
// //                     color: service == 'MTN' ? Colors.black : Colors.white,
// //                     fontSize: service == 'MTN' ? 12.sp : 20.sp,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //             SizedBox(width: 12.w),
// //             Text(
// //               title,
// //               style: TextStyle(
// //                 fontSize: 16.sp,
// //                 fontWeight: FontWeight.w500,
// //                 color: Colors.black,
// //               ),
// //             ),
// //             const Spacer(),
// //             Icon(
// //               isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
// //               color: isSelected ? AppColors.primaryBlue : Colors.grey[400],
// //               size: 24.sp,
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }