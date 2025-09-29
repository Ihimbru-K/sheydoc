import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';

class FileUploadField extends StatefulWidget {
  final String label;
  final bool isRequired;
  final void Function(String? filePath) onFileSelected;

  const FileUploadField({
    super.key,
    required this.label,
    required this.onFileSelected,
    this.isRequired = true,
  });

  @override
  State<FileUploadField> createState() => _FileUploadFieldState();
}

class _FileUploadFieldState extends State<FileUploadField> {
  String? _fileName;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        final name = result.files.single.name;

        setState(() => _fileName = name);
        widget.onFileSelected(path);
      } else {
        widget.onFileSelected(null);
      }
    } catch (e) {
      debugPrint("File picker error: $e");
      widget.onFileSelected(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
          decoration: BoxDecoration(
            border: Border.all(
              color: _fileName != null
                  ? Colors.green
                  : Colors.grey.shade400,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(Icons.upload_file,
                  color: _fileName != null ? Colors.green : Colors.blueGrey,
                  size: 22.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  _fileName ?? "${widget.label}${widget.isRequired ? '*' : ''}",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: _fileName == null ? Colors.grey : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_fileName != null)
                Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }
}
