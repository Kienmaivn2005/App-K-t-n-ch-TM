import 'package:flutter/material.dart';

/// TTN SMART CREDIT PLANNER - SCHOOL WEEK SCHEDULE & LESSON ITEM
/// Feature-First Clean Architecture: lib/domain/models/school_week_schedule.dart
/// Mô hình hóa chính xác 100% cấu trúc DOM Table của Cổng đào tạo trường ĐH Tây Nguyên (ttn.edu.vn)

/// 1. ScheduleLessonItem: Một môn học/ca học cụ thể trong ô của bảng
class ScheduleLessonItem {
  final String courseName;
  final String room;
  final String? lecturer;
  final String periodString; // Ví dụ: "1-4", "7-10"
  final Color badgeColor;
  final String? classGroup;
  final String? rawTitle;

  ScheduleLessonItem({
    required this.courseName,
    required this.room,
    this.lecturer,
    required this.periodString,
    required this.badgeColor,
    this.classGroup,
    this.rawTitle,
  });

  /// Parse startPeriod và length từ periodString
  int get startPeriod {
    if (periodString.contains('-')) {
      return int.tryParse(periodString.split('-').first) ?? 1;
    }
    return int.tryParse(periodString) ?? 1;
  }

  int get length {
    if (periodString.contains('-')) {
      final parts = periodString.split('-');
      final start = int.tryParse(parts[0]) ?? 1;
      final end = int.tryParse(parts[1]) ?? 4;
      return (end - start + 1).clamp(1, 6);
    }
    return 1;
  }
}

/// 2. SchoolWeekSchedule: Khối bảng thời khóa biểu của một tuần học (Khớp 100% Table Cổng TTN)
class SchoolWeekSchedule {
  final int weekNumber;
  final DateTime startDate; // Ngày bắt đầu tuần (Thứ 2)
  final DateTime endDate;   // Ngày kết thúc tuần (CN)
  final Map<String, Map<int, List<ScheduleLessonItem>>> grid;
  // Key 1: Buổi ('Sáng', 'Chiều', 'Tối')
  // Key 2: Thứ trong tuần (2: T2, 3: T3, ..., 8: CN)
  // Value: Danh sách môn học trong buổi đó (nếu rỗng -> ô trống)

  SchoolWeekSchedule({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.grid,
  });

  /// Tiêu đề tuần chuẩn Cổng Đào Tạo: "Từ ngày dd/MM/yyyy đến ngày dd/MM/yyyy"
  String get weekTitle {
    final startStr = _formatDate(startDate);
    final endStr = _formatDate(endDate);
    return 'Từ ngày $startStr đến ngày $endStr';
  }

  /// Tiêu đề tuần ngắn (VD: "19/10 - 25/10/2026")
  String get dateRangeText {
    final sD = startDate.day.toString().padLeft(2, '0');
    final sM = startDate.month.toString().padLeft(2, '0');
    final eD = endDate.day.toString().padLeft(2, '0');
    final eM = endDate.month.toString().padLeft(2, '0');
    return '$sD/$sM - $eD/$eM/${endDate.year}';
  }

  static String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  /// Kiểm tra xem tuần này có trống hoàn toàn không (Hết môn / Nghỉ thi / Tuần trống)
  bool get isEmptyWeek {
    for (var session in grid.values) {
      for (var lessons in session.values) {
        if (lessons.isNotEmpty) return false;
      }
    }
    return true;
  }

  /// Tổng số buổi học trong tuần
  int get totalLessonsCount {
    int count = 0;
    for (var session in grid.values) {
      for (var lessons in session.values) {
        count += lessons.length;
      }
    }
    return count;
  }

  /// Lấy danh sách môn học tại một buổi và thứ cụ thể
  List<ScheduleLessonItem> getLessons(String session, int schoolWeekday) {
    return grid[session]?[schoolWeekday] ?? const [];
  }

  /// Khởi tạo bảng tuần trống với đầy đủ 3 buổi (Sáng, Chiều, Tối) và 7 ngày (T2..CN)
  factory SchoolWeekSchedule.empty({
    required int weekNumber,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final Map<String, Map<int, List<ScheduleLessonItem>>> emptyGrid = {
      'Sáng': {for (int d = 2; d <= 8; d++) d: []},
      'Chiều': {for (int d = 2; d <= 8; d++) d: []},
      'Tối': {for (int d = 2; d <= 8; d++) d: []},
    };
    return SchoolWeekSchedule(
      weekNumber: weekNumber,
      startDate: startDate,
      endDate: endDate,
      grid: emptyGrid,
    );
  }

  /// Khởi tạo bảng tuần từ danh sách dòng thời khóa biểu đã phân giải
  factory SchoolWeekSchedule.fromRows({
    required int weekNumber,
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> rows,
  }) {
    final Map<String, Map<int, List<ScheduleLessonItem>>> grid = {
      'Sáng': {for (int d = 2; d <= 8; d++) d: []},
      'Chiều': {for (int d = 2; d <= 8; d++) d: []},
      'Tối': {for (int d = 2; d <= 8; d++) d: []},
    };

    final colors = [
      const Color(0xFFF3E8FF), // Tím
      const Color(0xFFFFEDD5), // Cam
      const Color(0xFFE0F2FE), // Xanh lam
      const Color(0xFFE0F7FA), // Cyan
      const Color(0xFFFFE4E6), // Hồng
      const Color(0xFFDCFCE7), // Xanh lá
      const Color(0xFFEDE9FE), // Indigo
    ];

    for (final r in rows) {
      final day = r['day'] as int? ?? 2;
      String session = r['session'] as String? ?? 'Sáng';
      final period = r['period'] as String? ?? '1-4';

      // Chuẩn hóa ca học nếu chưa có
      if (session != 'Sáng' && session != 'Chiều' && session != 'Tối') {
        final startP = int.tryParse(period.split('-').first) ?? 1;
        if (startP <= 5) {
          session = 'Sáng';
        } else if (startP <= 10) {
          session = 'Chiều';
        } else {
          session = 'Tối';
        }
      }

      final courseName = r['rawTitle'] ?? r['name'] ?? 'Môn học';
      final room = r['room'] as String? ?? '';
      final lecturer = r['lecturer'] as String?;
      final color = colors[courseName.hashCode.abs() % colors.length];

      final lesson = ScheduleLessonItem(
        courseName: courseName,
        room: room,
        lecturer: lecturer,
        periodString: period,
        badgeColor: color,
        rawTitle: r['rawTitle'],
      );

      if (grid.containsKey(session) && grid[session]!.containsKey(day)) {
        grid[session]![day]!.add(lesson);
      }
    }

    return SchoolWeekSchedule(
      weekNumber: weekNumber,
      startDate: startDate,
      endDate: endDate,
      grid: grid,
    );
  }
}

