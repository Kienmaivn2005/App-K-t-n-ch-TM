import 'package:flutter/material.dart';
import '../../services/academic_date_engine.dart';
import '../../services/period_time_config.dart';

/// 1. SectionMeetingSlot: Đại diện cho một ca học cụ thể (Tách biệt Lý thuyết và Thực hành)
/// Hỗ trợ tuần học riêng biệt (Ví dụ: Lý thuyết Thứ 2 phòng A tuần 1-10; Thực hành Thứ 5 phòng Lab tuần 5-15)
class SectionMeetingSlot {
  final int dayOfWeek; // 2: Thứ 2 ... 7: Thứ 7, 8: CN
  final int startPeriod; // Tiết bắt đầu (1-12)
  final int length; // Số tiết
  final String room;
  final String lecturer;
  final List<int> activeWeeks; // Danh sách các tuần diễn ra ca học này
  final bool isPractice; // Phân biệt Lý thuyết vs Thực hành

  const SectionMeetingSlot({
    required this.dayOfWeek,
    required this.startPeriod,
    required this.length,
    required this.room,
    required this.lecturer,
    required this.activeWeeks,
    this.isPractice = false,
  });

  /// Kiểm tra xem ca học này có diễn ra ở tuần [weekNumber] không
  bool isStudyingInWeek(int weekNumber) => activeWeeks.contains(weekNumber);

  int get endPeriod => startPeriod + length - 1;
  String get periodString => '$startPeriod-$endPeriod';

  String get session {
    if (startPeriod <= 5) return 'Sáng';
    if (startPeriod <= 10) return 'Chiều';
    return 'Tối';
  }

  String get timeRangeString => PeriodTimeConfig.formatPeriodTimeRange(startPeriod, length);

  String get dayLabel => AcademicDateEngine.getSchoolWeekdayLabel(dayOfWeek);
}

/// 2. ScheduleSectionItem: Model lớp học phần đầy đủ
class ScheduleSectionItem {
  final String courseCode;
  final String courseName;
  final String classGroup;
  final int dayOfWeek; // 2: Thứ 2 ... 7: Thứ 7, 8: CN
  final int startPeriod; // Tiết bắt đầu (1-12)
  final int length; // Số tiết (ví dụ: 4 tiết)
  final String room;
  final String lecturer;
  final List<int> activeWeeks; // Danh sách các tuần môn này có học
  final Color color;
  final List<SectionMeetingSlot> meetingSlots; // Danh sách các ca học con tách biệt (LT, TH)

  const ScheduleSectionItem({
    required this.courseCode,
    required this.courseName,
    this.classGroup = 'Nhóm 01',
    required this.dayOfWeek,
    required this.startPeriod,
    required this.length,
    required this.room,
    required this.lecturer,
    required this.activeWeeks,
    this.color = const Color(0xFF2563EB),
    this.meetingSlots = const [],
  });

  /// Kiểm tra xem môn này có học ở tuần [weekNumber] không
  bool isStudyingInWeek(int weekNumber) {
    if (activeWeeks.contains(weekNumber)) return true;
    return meetingSlots.any((slot) => slot.isStudyingInWeek(weekNumber));
  }

  /// Tiết kết thúc
  int get endPeriod => startPeriod + length - 1;

  /// Chuỗi hiển thị tiết (Ví dụ: "1-4", "7-9")
  String get periodString => '$startPeriod-$endPeriod';

  /// Khung giờ chuẩn theo bảng cấu hình 12 tiết
  String get timeRangeString => PeriodTimeConfig.formatPeriodTimeRange(startPeriod, length);

  /// Ca học: Sáng (tiết 1-5), Chiều (tiết 6-10), Tối (tiết 11-12)
  String get session {
    if (startPeriod <= 5) return 'Sáng';
    if (startPeriod <= 10) return 'Chiều';
    return 'Tối';
  }

  /// Nhãn hiển thị thứ trong tuần
  String get dayLabel => AcademicDateEngine.getSchoolWeekdayLabel(dayOfWeek);

  /// Chuyển sang Map định dạng dòng thời khóa biểu dùng trong UI và Web TTN
  Map<String, dynamic> toTimetableRow(String dateStr) {
    return {
      'khid': courseCode,
      'name': '$courseName ($length)',
      'rawTitle': courseName,
      'day': dayOfWeek,
      'session': session,
      'date': dateStr,
      'period': periodString,
      'room': room,
      'lecturer': lecturer,
      'classGroup': classGroup,
      'activeWeeks': activeWeeks,
      'color': color.toARGB32(),
    };
  }

  /// Khởi tạo từ Map thời khóa biểu
  factory ScheduleSectionItem.fromMap(Map<String, dynamic> map) {
    final periodStr = map['period'] as String? ?? '1-4';
    int start = 1;
    int len = 4;
    if (periodStr.contains('-')) {
      final parts = periodStr.split('-');
      start = int.tryParse(parts[0]) ?? 1;
      final end = int.tryParse(parts[1]) ?? 4;
      len = (end - start + 1).clamp(1, 6);
    }

    final rawWeeks = map['activeWeeks'];
    List<int> weeks = const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
    if (rawWeeks is List) {
      weeks = rawWeeks.map((e) => (e as num).toInt()).toList();
    }

    final colorVal = map['color'];
    Color c = const Color(0xFF2563EB);
    if (colorVal is int) {
      c = Color(colorVal);
    }

    return ScheduleSectionItem(
      courseCode: map['khid'] as String? ?? '',
      courseName: map['rawTitle'] as String? ?? map['name'] as String? ?? '',
      classGroup: map['classGroup'] as String? ?? 'Nhóm 01',
      dayOfWeek: map['day'] as int? ?? 2,
      startPeriod: start,
      length: len,
      room: map['room'] as String? ?? '',
      lecturer: map['lecturer'] as String? ?? '',
      activeWeeks: weeks,
      color: c,
    );
  }
}
