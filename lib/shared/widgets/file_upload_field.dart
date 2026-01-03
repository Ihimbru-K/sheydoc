import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path; // For basename

class FileUploadField extends StatefulWidget {
  final String label;
  final bool isRequired;
  final void Function(String? filePath) onFileSelected;
  final String? currentFilePath; // To restore/display selected file on rebuild

  const FileUploadField({
    super.key,
    required this.label,
    required this.onFileSelected,
    this.isRequired = true,
    this.currentFilePath,
  });

  @override
  State<FileUploadField> createState() => _FileUploadFieldState();
}

class _FileUploadFieldState extends State<FileUploadField> {
  String? _fileName;

  @override
  void initState() {
    super.initState();
    // If a file was already selected (e.g., on rebuild), show its name
    if (widget.currentFilePath != null) {
      _fileName = path.basename(widget.currentFilePath!);
    }
  }

  @override
  void didUpdateWidget(covariant FileUploadField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update displayed name if the path changed externally
    if (widget.currentFilePath != oldWidget.currentFilePath) {
      setState(() {
        _fileName = widget.currentFilePath != null
            ? path.basename(widget.currentFilePath!)
            : null;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        // Optional: restrict to common document/image types
        type: FileType.any,
        // allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path;
        final fileName = result.files.single.name;

        if (filePath != null) {
          setState(() => _fileName = fileName);
          widget.onFileSelected(filePath);
        } else {
          // Web platform might not have path
          setState(() => _fileName = fileName);
          widget.onFileSelected(null);
        }
      } else {
        // User canceled
        if (_fileName == null) {
          widget.onFileSelected(null);
        }
      }
    } catch (e) {
      debugPrint("File picker error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to pick file")),
      );
      widget.onFileSelected(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFile = _fileName != null;

    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasFile ? Colors.green : Colors.grey.shade400,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12.r),
            color: hasFile ? Colors.green.withOpacity(0.05) : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.upload_file_outlined,
                color: hasFile ? Colors.green : Colors.blueGrey,
                size: 24.sp,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  hasFile
                      ? _fileName!
                      : "${widget.label}${widget.isRequired ? ' *' : ''}",
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    color: hasFile ? Colors.black87 : Colors.grey.shade600,
                    fontWeight: hasFile ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              if (hasFile)
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 22.sp,
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16.sp,
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
// import 'package:file_picker/file_picker.dart';
//
// class FileUploadField extends StatefulWidget {
//   final String label;
//   final bool isRequired;
//   final void Function(String? filePath) onFileSelected;
//
//   const FileUploadField({
//     super.key,
//     required this.label,
//     required this.onFileSelected,
//     this.isRequired = true,
//   });
//
//   @override
//   State<FileUploadField> createState() => _FileUploadFieldState();
// }
//
// class _FileUploadFieldState extends State<FileUploadField> {
//   String? _fileName;
//
//   Future<void> _pickFile() async {
//     try {
//       final result = await FilePicker.platform.pickFiles();
//       if (result != null && result.files.isNotEmpty) {
//         final path = result.files.single.path;
//         final name = result.files.single.name;
//
//         setState(() => _fileName = name);
//         widget.onFileSelected(path);
//       } else {
//         widget.onFileSelected(null);
//       }
//     } catch (e) {
//       debugPrint("File picker error: $e");
//       widget.onFileSelected(null);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 15.h),
//       child: InkWell(
//         onTap: _pickFile,
//         borderRadius: BorderRadius.circular(12.r),
//         child: Container(
//           padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
//           decoration: BoxDecoration(
//             border: Border.all(
//               color: _fileName != null
//                   ? Colors.green
//                   : Colors.grey.shade400,
//             ),
//             borderRadius: BorderRadius.circular(12.r),
//           ),
//           child: Row(
//             children: [
//               Icon(Icons.upload_file,
//                   color: _fileName != null ? Colors.green : Colors.blueGrey,
//                   size: 22.sp),
//               SizedBox(width: 12.w),
//               Expanded(
//                 child: Text(
//                   _fileName ?? "${widget.label}${widget.isRequired ? '*' : ''}",
//                   style: TextStyle(
//                     fontSize: 14.sp,
//                     color: _fileName == null ? Colors.grey : Colors.black87,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               if (_fileName != null)
//                 Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
