import 'package:flutter/material.dart';
import 'period_time_config.dart';

/// Trạng thái học tập của tiết học trong ngày
enum StudyStatus {
  ongoing,   // Đang diễn ra
  upcoming,  // Sắp diễn ra
  completed, // Đã kết thúc
}

/// TTN SMART CREDIT PLANNER - REAL-TIME ACADEMIC DATE ENGINE
/// Thuật toán tính toán ngày tháng, tuần học, phân tách ca học và trạng thái theo thời gian thực
class AcademicDateEngine {
  /// Thứ 2 đầu tiên của tuần 1 học kỳ (00:00:00)
  final DateTime semesterStartMonday;

  /// Danh sách các tuần nghỉ (ví dụ: tuần 8 nghỉ thi giữa kỳ, tuần Tết)
  final Set<int> breakWeeks;

  AcademicDateEngine({
    required DateTime semesterStartDate,
    this.breakWeeks = const {},
  }) : semesterStartMonday = _getMondayOfDate(semesterStartDate);

  /// 1. Chuẩn hóa về 00:00:00 và tìm ngày Thứ 2 của một ngày bất kỳ
  static DateTime _getMondayOfDate(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    // date.weekday: 1 (Thứ 2) -> 7 (Chủ Nhật)
    return cleanDate.subtract(Duration(days: date.weekday - 1));
  }

  /// 2. Chuyển đổi hai chiều giữa Dart weekday và Hệ thống trường TTN
  /// Dart: 1 (Thứ 2) ... 7 (Chủ Nhật)
  /// Trường: 2 (Thứ 2) ... 7 (Thứ 7), 8 (Chủ Nhật)
  static int toSchoolWeekday(DateTime date) {
    return date.weekday == 7 ? 8 : (date.weekday + 1);
  }

  static int toDartWeekday(int schoolWeekday) {
    return schoolWeekday == 8 ? 7 : (schoolWeekday - 1).clamp(1, 7);
  }

  static String getSchoolWeekdayLabel(int schoolWeekday) {
    switch (schoolWeekday) {
      case 2:
        return 'Thứ 2';
      case 3:
        return 'Thứ 3';
      case 4:
        return 'Thứ 4';
      case 5:
        return 'Thứ 5';
      case 6:
        return 'Thứ 6';
      case 7:
        return 'Thứ 7';
      case 8:
        return 'Chủ Nhật';
      default:
        return 'Thứ $schoolWeekday';
    }
  }

  /// 3. Tính số thứ tự tuần học hiện tại dựa trên DateTime.now()
  /// Chuẩn hóa mốc 00:00:00 giữa Thứ 2 đầu kỳ và Thứ 2 tuần hiện tại
  int getCurrentWeek([DateTime? targetDate]) {
    final now = targetDate ?? DateTime.now();
    final currentMonday = _getMondayOfDate(now);
    final diffDays = currentMonday.difference(semesterStartMonday).inDays;
    final calendarWeek = (diffDays / 7).floor() + 1;
    return calendarWeek.clamp(1, 25);
  }

  /// 4. Lấy ngày Thứ 2 của tuần thứ W
  DateTime getMondayOfWeek(int weekNumber) {
    final clampedWeek = weekNumber.clamp(1, 25);
    return semesterStartMonday.add(Duration(days: (clampedWeek - 1) * 7));
  }

  /// 5. Lấy danh sách 7 ngày (Thứ 2 -> Chủ Nhật) của Tuần thứ W
  List<DateTime> getDaysOfWeek(int weekNumber) {
    final weekMonday = getMondayOfWeek(weekNumber);
    return List.generate(7, (index) => weekMonday.add(Duration(days: index)));
  }

  /// 6. Lấy ngày cụ thể cho một thứ trong tuần [schoolWeekday] (2: Thứ 2 ... 8: CN)
  DateTime getDateOfSchoolWeekday(int weekNumber, int schoolWeekday) {
    final weekMonday = getMondayOfWeek(weekNumber);
    final offset = schoolWeekday == 8 ? 6 : (schoolWeekday - 2).clamp(0, 6);
    return weekMonday.add(Duration(days: offset));
  }

  /// 7. Trả về dải ngày hiển thị cho header tuần (VD: "19/10 - 25/10/2026")
  String getWeekDateRangeString(int weekNumber) {
    final days = getDaysOfWeek(weekNumber);
    final start = days.first;
    final end = days.last;
    return '${_formatDayMonth(start)} - ${_formatDayMonth(end)}/${end.year}';
  }

  /// Dải ngày ngắn (VD: "19/10 - 25/10")
  String getWeekDateRangeShortString(int weekNumber) {
    final days = getDaysOfWeek(weekNumber);
    return '${_formatDayMonth(days.first)} - ${_formatDayMonth(days.last)}';
  }

  static String _formatDayMonth(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  /// 8. Kiểm tra xem tuần này có phải tuần nghỉ không
  bool isBreakWeek(int weekNumber) => breakWeeks.contains(weekNumber);

  /// 9. Kiểm tra trạng thái môn học trong ngày hôm nay
  /// Trả về: StudyStatus.ongoing ("Đang diễn ra"), upcoming ("Sắp diễn ra"), completed ("Đã kết thúc")
  StudyStatus getLessonStatus(
    DateTime lessonDate,
    int startPeriod,
    int length, [
    DateTime? currentDateTime,
  ]) {
    final now = currentDateTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(lessonDate.year, lessonDate.month, lessonDate.day);

    if (targetDay.isBefore(today)) return StudyStatus.completed;
    if (targetDay.isAfter(today)) return StudyStatus.upcoming;

    // Cùng ngày hôm nay -> So sánh giờ:phút
    final startTime = PeriodTimeConfig.getStartTime(startPeriod);
    final endTime = PeriodTimeConfig.getEndTime(startPeriod + length - 1);

    final startDateTime = DateTime(today.year, today.month, today.day, startTime.hour, startTime.minute);
    final endDateTime = DateTime(today.year, today.month, today.day, endTime.hour, endTime.minute);

    if (now.isBefore(startDateTime)) return StudyStatus.upcoming;
    if (now.isAfter(endDateTime)) return StudyStatus.completed;
    return StudyStatus.ongoing;
  }

  /// Nhãn hiển thị tiếng Việt của trạng thái
  static String getStatusLabel(StudyStatus status) {
    switch (status) {
      case StudyStatus.ongoing:
        return 'Đang diễn ra';
      case StudyStatus.upcoming:
        return 'Sắp diễn ra';
      case StudyStatus.completed:
        return 'Đã kết thúc';
    }
  }

  /// Màu sắc chữ của trạng thái
  static Color getStatusColor(StudyStatus status) {
    switch (status) {
      case StudyStatus.ongoing:
        return const Color(0xFFEA580C); // Cam rực rỡ
      case StudyStatus.upcoming:
        return const Color(0xFF2563EB); // Xanh dương
      case StudyStatus.completed:
        return const Color(0xFF64748B); // Xám
    }
  }

  /// Màu nền badge của trạng thái
  static Color getStatusBgColor(StudyStatus status) {
    switch (status) {
      case StudyStatus.ongoing:
        return const Color(0xFFFFF7ED);
      case StudyStatus.upcoming:
        return const Color(0xFFEFF6FF);
      case StudyStatus.completed:
        return const Color(0xFFF1F5F9);
    }
  }

  /// Màu viền badge của trạng thái
  static Color getStatusBorderColor(StudyStatus status) {
    switch (status) {
      case StudyStatus.ongoing:
        return const Color(0xFFFDBA74);
      case StudyStatus.upcoming:
        return const Color(0xFFBFDBFE);
      case StudyStatus.completed:
        return const Color(0xFFCBD5E1);
    }
  }

  /// Instance mặc định cho học kỳ 1 năm học 2026-2027 (Khởi đầu Thứ Hai, 03/08/2026)
  static final AcademicDateEngine defaultInstance = AcademicDateEngine(
    semesterStartDate: DateTime(2026, 8, 3),
    breakWeeks: const {},
  );
}

