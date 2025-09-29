// features/doctor/home/home_screen.dart
import 'package:flutter/material.dart';
class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
      ),
      body: Center(
        child: Text('Welcome Doctor!'),
      ),
    );
  }
}























// import 'package:flutter/material.dart';
// import 'package:sheydoc_app/features/onboarding/role_selection_screen.dart';
// import '../../auth/doctors/talk_to_doctor_screen.dart';
//
//
// class HomeScreen extends StatefulWidget {
//   final String? role;
//   const HomeScreen({super.key, this.role});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//           leading: GestureDetector(
//             child: Icon(Icons.back_hand),
//             onTap: () {
//               Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => RoleSelectionScreen())
//               );
//             },
//           )
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Home Screen",
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 10),
//               Text("Role: ${widget.role ?? 'Unknown'}"),
//               SizedBox(height: 30),
//
//               // Test button for Talk to Doctor UI
//               Container(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => TalkToDoctorScreen())
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     padding: EdgeInsets.symmetric(vertical: 15),
//                   ),
//                   child: Text(
//                     "Test Talk to Doctor UI",
//                     style: TextStyle(fontSize: 16),
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: 20),
//               Text(
//                 "Other features coming soon...",
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
//







// import 'package:flutter/material.dart';
// import 'package:sheydoc_app/features/onboarding/role_selection_screen.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar:AppBar(
//         leading: GestureDetector(child: Icon(Icons.back_hand, ), onTap: (){Navigator.push(context, MaterialPageRoute(builder: (context)=>RoleSelectionScreen()));},)
//
//
//       ),
//       body: SingleChildScrollView(
//         child: Column(children: [
//           Text("ddkd")
//         ],),
//
//
//       ),
//
//     );
//   }
// }
