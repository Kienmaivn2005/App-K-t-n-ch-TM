import 'package:flutter/material.dart';

/// Cấu hình mốc thời gian giờ và phút cho 12 tiết học chuẩn ĐH Tây Nguyên
class PeriodTimeConfig {
  static const Map<int, TimeOfDay> startTimes = {
    1: TimeOfDay(hour: 7, minute: 0),
    2: TimeOfDay(hour: 7, minute: 50),
    3: TimeOfDay(hour: 8, minute: 45),
    4: TimeOfDay(hour: 9, minute: 40),
    5: TimeOfDay(hour: 10, minute: 30),
    6: TimeOfDay(hour: 13, minute: 0),
    7: TimeOfDay(hour: 13, minute: 50),
    8: TimeOfDay(hour: 14, minute: 45),
    9: TimeOfDay(hour: 15, minute: 40),
    10: TimeOfDay(hour: 16, minute: 30),
    11: TimeOfDay(hour: 17, minute: 30),
    12: TimeOfDay(hour: 18, minute: 20),
  };

  static const Map<int, TimeOfDay> endTimes = {
    1: TimeOfDay(hour: 7, minute: 45),
    2: TimeOfDay(hour: 8, minute: 35),
    3: TimeOfDay(hour: 9, minute: 30),
    4: TimeOfDay(hour: 10, minute: 25),
    5: TimeOfDay(hour: 11, minute: 15),
    6: TimeOfDay(hour: 13, minute: 45),
    7: TimeOfDay(hour: 14, minute: 35),
    8: TimeOfDay(hour: 15, minute: 30),
    9: TimeOfDay(hour: 16, minute: 25),
    10: TimeOfDay(hour: 17, minute: 15),
    11: TimeOfDay(hour: 18, minute: 15),
    12: TimeOfDay(hour: 19, minute: 5),
  };

  /// Lấy giờ bắt đầu của tiết học
  static TimeOfDay getStartTime(int period) {
    return startTimes[period.clamp(1, 12)] ?? const TimeOfDay(hour: 7, minute: 0);
  }

  /// Lấy giờ kết thúc của tiết học
  static TimeOfDay getEndTime(int period) {
    return endTimes[period.clamp(1, 12)] ?? const TimeOfDay(hour: 11, minute: 15);
  }

  /// Format chuỗi thời gian thực tế: "[Giờ bắt đầu tiết startPeriod] - [Giờ kết thúc tiết (startPeriod + length - 1)]"
  /// Ví dụ: startPeriod: 1, length: 4 -> "07:00 - 10:25 (Tiết 1-4)"
  static String formatPeriodTimeRange(int startPeriod, int length, {bool includePeriodLabel = true}) {
    final startClamped = startPeriod.clamp(1, 12);
    final endClamped = (startPeriod + length - 1).clamp(1, 12);

    final start = getStartTime(startClamped);
    final end = getEndTime(endClamped);

    final sH = start.hour.toString().padLeft(2, '0');
    final sM = start.minute.toString().padLeft(2, '0');
    final eH = end.hour.toString().padLeft(2, '0');
    final eM = end.minute.toString().padLeft(2, '0');

    final timeStr = '$sH:$sM - $eH:$eM';
    if (!includePeriodLabel) return timeStr;
    return '$timeStr (Tiết $startClamped-$endClamped)';
  }
}

