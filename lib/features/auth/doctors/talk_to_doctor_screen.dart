import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';

class TalkToDoctorScreen extends StatefulWidget {
  @override
  State<TalkToDoctorScreen> createState() => _TalkToDoctorScreenState();
}

class _TalkToDoctorScreenState extends State<TalkToDoctorScreen> {
  final _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _doctors = [];
  List<QueryDocumentSnapshot> _allDoctors = [];
  bool _loading = true;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _loadDoctorsDebug();
  }

  Future<void> _loadDoctorsDebug() async {
    try {
      // First, get ALL doctors to see what's in the database
      print("🔍 Fetching ALL doctors from database...");
      final allSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      print("📊 Found ${allSnapshot.docs.length} total doctors");

      // Debug: Print all doctor data
      for (int i = 0; i < allSnapshot.docs.length; i++) {
        final doc = allSnapshot.docs[i];
        final data = doc.data() as Map<String, dynamic>;
        print("👨‍⚕️ Doctor $i: ${doc.id}");
        print("   - approvalStatus: ${data['approvalStatus']}");
        print("   - profileComplete: ${data['profileComplete']}");
        print("   - availabilityComplete: ${data['availabilityComplete']}");
        print("   - firstName: ${data['firstName']}");
        print("   - lastName: ${data['lastName']}");
        print("   - specialty: ${data['specialty']}");
        print("   - yearsOfExperience: ${data['yearsOfExperience']}");
        print("   - baseFee: ${data['baseFee']}");
        print("   - availability length: ${data['availability'] is List ? (data['availability'] as List).length : 'Not a list or null'}");
        print("   ---");
      }

      // Try different queries to see what works
      print("🔍 Trying to fetch approved doctors...");
      final approvedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('approvalStatus', isEqualTo: 'approved')
          .get();

      print("✅ Found ${approvedSnapshot.docs.length} approved doctors");

      // Try without approval filter
      print("🔍 Fetching doctors without approval filter...");
      final doctorsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      setState(() {
        _allDoctors = allSnapshot.docs;
        _doctors = approvedSnapshot.docs.isNotEmpty ? approvedSnapshot.docs : doctorsSnapshot.docs;
        _loading = false;
        _debugInfo = '''
Total doctors in DB: ${allSnapshot.docs.length}
Approved doctors: ${approvedSnapshot.docs.length}
Showing: ${_doctors.length} doctors
        ''';
      });

    } catch (e) {
      print("❌ Error loading doctors: $e");
      setState(() {
        _loading = false;
        _debugInfo = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Talk to a Doctor (Debug)'),
        backgroundColor: AppColors.backgroundColor,
      ),
      body: Column(
        children: [
          // Debug info panel
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            color: Colors.yellow.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DEBUG INFO:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_debugInfo),
                ElevatedButton(
                  onPressed: _loadDoctorsDebug,
                  child: Text('Reload Data'),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search a doctor or health issue',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                fillColor: AppColors.textfieldBlue,
                filled: true,
              ),
              onChanged: (val) => setState(() {}),
            ),
          ),

          if (_loading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_doctors.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_hospital, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No doctors found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    Text(
                      'Check debug info above',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Show all doctors regardless of approval status
                        setState(() {
                          _doctors = _allDoctors;
                        });
                      },
                      child: Text('Show All Doctors (Ignore Approval)'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _doctors.length,
                itemBuilder: (context, index) {
                  final doc = _doctors[index].data() as Map<String, dynamic>;
                  final firstName = doc['firstName'] ?? '';
                  final lastName = doc['lastName'] ?? '';
                  final name = doc['name'] ?? '$firstName $lastName'.trim();
                  final specialty = doc['specialty'] ?? 'General Medicine';
                  final years = doc['yearsOfExperience'] ?? 0;
                  final rating = (doc['rating'] ?? 5.0).toDouble();
                  final baseFee = (doc['baseFee'] ?? 3000.0).toDouble();
                  final photo = doc['photo'];
                  final availability = doc['availability'];
                  final approvalStatus = doc['approvalStatus'] ?? 'unknown';

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(12.w),
                      leading: CircleAvatar(
                        radius: 30.r,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: photo != null && photo.toString().isNotEmpty
                            ? MemoryImage(base64Decode(photo))
                            : null,
                        child: photo == null || photo.toString().isEmpty
                            ? Icon(Icons.person, size: 30.sp)
                            : null,
                      ),
                      title: Text(
                        name.trim().isEmpty ? 'Doctor ${index + 1}' : name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4.h),
                          Text('Specialty: $specialty'),
                          Text('Experience: $years years'),
                          Text('Status: $approvalStatus'),
                          Text('Available: ${_getDaysPreview(availability)}'),
                        ],
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              5,
                                  (i) => Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16.sp,
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${baseFee.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Doctor Selected'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Name: ${name.trim().isEmpty ? 'Doctor ${index + 1}' : name}'),
                                Text('Status: $approvalStatus'),
                                Text('ID: ${doc.keys.join(', ')}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _getDaysPreview(dynamic avail) {
    if (avail == null) return 'N/A';

    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Handle new flat structure: List<Map<String, dynamic>>
    if (avail is List) {
      final uniqueDays = <int>{};
      for (final slot in avail) {
        if (slot is Map && slot['day'] != null) {
          final day = slot['day'];
          if (day is int) {
            uniqueDays.add(day);
          }
        }
      }

      final days = uniqueDays
          .where((day) => day >= 0 && day < weekDays.length)
          .map((day) => weekDays[day])
          .join(', ');

      return days.isEmpty ? 'No slots' : days;
    }

    // Handle old nested structure: Map<String, List>
    if (avail is Map) {
      final days = avail.keys
          .where((k) {
        final list = avail[k];
        return list is List && list.isNotEmpty;
      })
          .map((k) {
        final index = int.tryParse(k.toString()) ?? -1;
        return (index >= 0 && index < weekDays.length)
            ? weekDays[index]
            : 'Invalid';
      })
          .where((d) => d != 'Invalid')
          .join(', ');

      return days.isEmpty ? 'No slots' : days;
    }

    return 'N/A';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

















// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// import '../../../core/constants/app_colors.dart';
// import '../../../services/auth_service.dart';
// // import 'doctor_profile_screen.dart'; // Comment out for now if it doesn't exist
//
// class TalkToDoctorScreen extends StatefulWidget {
//   @override
//   State<TalkToDoctorScreen> createState() => _TalkToDoctorScreenState();
// }
//
// class _TalkToDoctorScreenState extends State<TalkToDoctorScreen> {
//   final _searchController = TextEditingController();
//   List<QueryDocumentSnapshot> _doctors = [];
//   bool _loading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadDoctors();
//   }
//
//   Future<void> _loadDoctors() async {
//     try {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .where('role', isEqualTo: 'doctor')
//           .where('approvalStatus', isEqualTo: 'approved') // Changed from verificationStatus
//           .get();
//
//       setState(() {
//         _doctors = snapshot.docs;
//         _loading = false;
//       });
//
//       print("Loaded ${_doctors.length} doctors");
//     } catch (e) {
//       print("Error loading doctors: $e");
//       setState(() => _loading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Talk to a Doctor'),
//         backgroundColor: AppColors.backgroundColor,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: EdgeInsets.all(16.w),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 labelText: 'Search a doctor or health issue',
//                 prefixIcon: Icon(Icons.search),
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
//                 fillColor: AppColors.textfieldBlue,
//                 filled: true,
//               ),
//               onChanged: (val) => setState(() {}),
//             ),
//           ),
//
//           if (_loading)
//             Expanded(
//               child: Center(
//                 child: CircularProgressIndicator(),
//               ),
//             )
//           else if (_doctors.isEmpty)
//             Expanded(
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.local_hospital, size: 80, color: Colors.grey),
//                     SizedBox(height: 16),
//                     Text(
//                       'No approved doctors found',
//                       style: TextStyle(fontSize: 18, color: Colors.grey),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Complete a doctor registration to test this feature',
//                       style: TextStyle(fontSize: 14, color: Colors.grey),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             )
//           else
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _doctors.length,
//                 itemBuilder: (context, index) {
//                   final doc = _doctors[index].data() as Map<String, dynamic>;
//                   final name = doc['name'] ?? 'Dr. ${doc['firstName'] ?? ''} ${doc['lastName'] ?? ''}';
//                   final specialty = doc['specialty'] ?? 'General Medicine';
//                   final years = doc['yearsOfExperience'] ?? 0;
//                   final rating = (doc['rating'] ?? 5.0).toDouble();
//                   final baseFee = (doc['baseFee'] ?? 3000.0).toDouble();
//                   final photo = doc['photo'];
//                   final availability = doc['availability'];
//
//                   return Card(
//                     margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//                     elevation: 2,
//                     child: ListTile(
//                       contentPadding: EdgeInsets.all(12.w),
//                       leading: CircleAvatar(
//                         radius: 30.r,
//                         backgroundColor: Colors.grey[200],
//                         backgroundImage: photo != null
//                             ? MemoryImage(base64Decode(photo))
//                             : null,
//                         child: photo == null
//                             ? Icon(Icons.person, size: 30.sp)
//                             : null,
//                       ),
//                       title: Text(
//                         name.trim().isEmpty ? 'Doctor ${index + 1}' : name,
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           SizedBox(height: 4.h),
//                           Text(specialty),
//                           Text('$years years experience'),
//                           Text('Available: ${_getDaysPreview(availability)}'),
//                         ],
//                       ),
//                       trailing: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: List.generate(
//                               5,
//                                   (i) => Icon(
//                                 i < rating ? Icons.star : Icons.star_border,
//                                 color: Colors.amber,
//                                 size: 16.sp,
//                               ),
//                             ),
//                           ),
//                           SizedBox(height: 4.h),
//                           Text(
//                             '${baseFee.toStringAsFixed(0)} FCFA',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: AppColors.primaryBlue,
//                             ),
//                           ),
//                         ],
//                       ),
//                       onTap: () {
//                         // For testing, show a simple dialog instead of navigating
//                         showDialog(
//                           context: context,
//                           builder: (context) => AlertDialog(
//                             title: Text('Doctor Selected'),
//                             content: Text('You selected: ${name.trim().isEmpty ? 'Doctor ${index + 1}' : name}'),
//                             actions: [
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context),
//                                 child: Text('OK'),
//                               ),
//                             ],
//                           ),
//                         );
//
//                         // TODO: Uncomment when DoctorProfileScreen exists
//                         // Navigator.push(
//                         //   context,
//                         //   MaterialPageRoute(
//                         //     builder: (_) => DoctorProfileScreen(
//                         //       doctorId: _doctors[index].id,
//                         //       doctorData: doc
//                         //     )
//                         //   )
//                         // );
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   String _getDaysPreview(dynamic avail) {
//     if (avail == null) return 'N/A';
//
//     const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
//
//     // Handle new flat structure: List<Map<String, dynamic>>
//     if (avail is List) {
//       final uniqueDays = <int>{};
//       for (final slot in avail) {
//         if (slot is Map && slot['day'] != null) {
//           final day = slot['day'];
//           if (day is int) {
//             uniqueDays.add(day);
//           }
//         }
//       }
//
//       final days = uniqueDays
//           .where((day) => day >= 0 && day < weekDays.length)
//           .map((day) => weekDays[day])
//           .join(', ');
//
//       return days.isEmpty ? 'No slots' : days;
//     }
//
//     // Handle old nested structure: Map<String, List>
//     if (avail is Map) {
//       final days = avail.keys
//           .where((k) {
//         final list = avail[k];
//         return list is List && list.isNotEmpty;
//       })
//           .map((k) {
//         final index = int.tryParse(k.toString()) ?? -1;
//         return (index >= 0 && index < weekDays.length)
//             ? weekDays[index]
//             : 'Invalid';
//       })
//           .where((d) => d != 'Invalid')
//           .join(', ');
//
//       return days.isEmpty ? 'No slots' : days;
//     }
//
//     return 'N/A';
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
// }












// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// import '../../../core/constants/app_colors.dart';
// import '../../../services/auth_service.dart'; // For fetching
// import 'doctor_profile_screen.dart'; // See below
//
// class TalkToDoctorScreen extends StatefulWidget {
//   @override
//   State<TalkToDoctorScreen> createState() => _TalkToDoctorScreenState();
// }
//
// class _TalkToDoctorScreenState extends State<TalkToDoctorScreen> {
//   final _searchController = TextEditingController();
//   List<QueryDocumentSnapshot> _doctors = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadDoctors();
//   }
//
//   Future<void> _loadDoctors() async {
//     final snapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .where('role', isEqualTo: 'doctor')
//         .where('verificationStatus', isEqualTo: 'approved')
//         .get();
//     setState(() => _doctors = snapshot.docs);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Talk to a Doctor'), backgroundColor: AppColors.backgroundColor),
//       body: Column(
//         children: [
//           Padding(
//             padding: EdgeInsets.all(16.w),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 labelText: 'Search a doctor or health issue',
//                 prefixIcon: Icon(Icons.search),
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
//                 fillColor: AppColors.textfieldBlue,
//               ),
//               onChanged: (val) => setState(() {}), // Filter logic here
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: _doctors.length,
//               itemBuilder: (context, index) {
//                 final doc = _doctors[index].data() as Map<String, dynamic>;
//                 final name = doc['name'] ?? '';
//                 final specialty = doc['specialty'] ?? '';
//                 final years = doc['yearsOfExperience'] ?? 0;
//                 final rating = doc['rating'] ?? 5.0;
//                 final baseFee = doc['baseFee'] ?? 3000.0;
//                 final photo = doc['photo']; // Base64 to Image if needed
//                 final availability = doc['availability'] as Map?; // Preview days
//
//                 return Card(
//                   margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//                   child: ListTile(
//                     leading: CircleAvatar(backgroundImage: photo != null ? MemoryImage(base64Decode(photo)) : null, child: photo == null ? Icon(Icons.person) : null),
//                     title: Text(name),
//                     subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(specialty), Text('$years years exp'), Text('Available: ${_getDaysPreview(availability)}')]),
//                     trailing: Column(mainAxisSize: MainAxisSize.min, children: [
//                       Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 16.sp))),
//                       Text('${baseFee.toStringAsFixed(0)} FCFA'),
//                     ]),
//                     onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctorId: _doctors[index].id, doctorData: doc))),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // String _getDaysPreview(Map? avail) {
//   //   if (avail == null) return 'N/A';
//   //   final days = avail.keys.where((k) => (avail[k] as List).isNotEmpty).map((k) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][k as int - 1]).join(', ');
//   //   return days.isEmpty ? 'No slots' : days;
//   // }
//
//
//   String _getDaysPreview(Map? avail) {
//     if (avail == null) return 'N/A';
//
//     const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
//
//     final days = avail.keys
//         .where((k) {
//       final list = avail[k];
//       return list is List && list.isNotEmpty;
//     })
//         .map((k) {
//       // Firestore returns keys as string, so parse safely
//       final index = int.tryParse(k.toString()) ?? -1;
//       return (index >= 0 && index < weekDays.length)
//           ? weekDays[index]
//           : 'Invalid';
//     })
//         .where((d) => d != 'Invalid')
//         .join(', ');
//
//     return days.isEmpty ? 'No slots' : days;
//   }
//
// }