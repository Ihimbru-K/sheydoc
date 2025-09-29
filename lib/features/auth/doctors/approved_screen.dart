import 'dart:async';
import 'package:flutter/material.dart';
import '../../doctor/home/home_screen.dart';

class ApprovalScreen extends StatefulWidget {
  final String role;
  const ApprovalScreen({super.key, required this.role});

  @override
  ApprovalScreenState createState() => ApprovalScreenState();
}

class ApprovalScreenState extends State<ApprovalScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorHomeScreen() // Pass role
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),

      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 148, color: Colors.green),
            const SizedBox(height: 20),
            const Text('Congratulations', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Your profile has been approved', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}





// import 'dart:async';
// import 'package:flutter/material.dart';
//
// import '../../doctor/home/home_screen.dart';
//
// class ApprovalScreen extends StatefulWidget {
//   final String role; // 👈 Add role
//
//   const ApprovalScreen({super.key, required this.role});
//
//   @override
//   _ApprovalScreenState createState() => _ApprovalScreenState();
// }
//
// class _ApprovalScreenState extends State<ApprovalScreen> {
//   @override
//   void initState() {
//     super.initState();
//
//     Timer(const Duration(seconds: 4), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           // 👇 pass role to HomeScreen if it needs it
//           builder: (context) => HomeScreen(),
//         ),
//       );
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.wifi),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.battery_full),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Image.asset(
//               'assets/images/icons/approved.png',
//               width: 148,
//               height: 148,
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Congratulations',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text( 'Your profile has been approved', style: TextStyle( fontSize: 16, color: Colors.grey[600], ), ),
//           ],
//         ),
//       ),
//     );
//   }
// }
