import 'package:flutter/material.dart';

class PaymentMethodScreen extends StatelessWidget {
  final Map<String, dynamic> appointmentData;
  const PaymentMethodScreen({super.key, required this.appointmentData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Payment Method")),
      body: Center(
        child: Text("Payment options go here…\n$appointmentData"),
      ),
    );
  }
}
