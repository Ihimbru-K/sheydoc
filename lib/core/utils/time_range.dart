import 'package:flutter/material.dart';

class TimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  TimeRange({required this.start, required this.end});

  Map<String, String> toMap() {
    return {
      "start": "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}",
      "end": "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}",
    };
  }

  factory TimeRange.fromMap(Map<String, dynamic> map) {
    final startParts = (map["start"] as String).split(":");
    final endParts = (map["end"] as String).split(":");

    return TimeRange(
      start: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      end: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
    );
  }
}



// class TimeRange {
//   final TimeOfDay start;
//   final TimeOfDay end;
//
//   TimeRange({required this.start, required this.end});
// }