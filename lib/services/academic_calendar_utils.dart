import 'package:flutter/material.dart';
import 'academic_date_engine.dart';
import 'period_time_config.dart';

/// Trạng thái học tập của tiết học trong ngày (Tương thích với StudyStatus)
typedef ClassSessionStatus = StudyStatus;

/// TTN SMART CREDIT PLANNER - REAL-TIME ACADEMIC CALENDAR UTILS
/// Cung cấp các hàm tiện ích gọi nhanh từ AcademicDateEngine và PeriodTimeConfig
class AcademicCalendarUtils {
  /// 1. Mốc bắt đầu kỳ học: Thứ 2 của Tuần 1 Học kỳ 1 Năm học 2026-2027
  static final DateTime semesterStartDate = DateTime(2026, 8, 3);

  /// 2. Tính tuần học hiện tại dựa trên mốc kỳ học
  static int getCurrentWeek([DateTime? referenceDate]) {
    return AcademicDateEngine.defaultInstance.getCurrentWeek(referenceDate);
  }

  /// Tính ngày Thứ 2 của tuần [weekNumber]
  static DateTime getMondayOfWeek(int weekNumber) {
    return AcademicDateEngine.defaultInstance.getMondayOfWeek(weekNumber);
  }

  /// 3. Tính dải 7 ngày (Thứ 2 -> Chủ Nhật) của tuần [weekNumber]
  static List<DateTime> getDaysOfWeek(int weekNumber) {
    return AcademicDateEngine.defaultInstance.getDaysOfWeek(weekNumber);
  }

  /// Lấy ngày cụ thể cho một thứ trong tuần [weekNumber]
  /// [dayOfWeek]: 2 (Thứ 2) -> 7 (Thứ 7), 8 (Chủ Nhật)
  static DateTime getDateOfDay(int weekNumber, int dayOfWeek) {
    return AcademicDateEngine.defaultInstance.getDateOfSchoolWeekday(weekNumber, dayOfWeek);
  }

  /// Định dạng chuỗi ngày DD/MM (Ví dụ: "19/10")
  static String formatDayMonth(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  /// Định dạng chuỗi ngày DD/MM/YYYY (Ví dụ: "19/10/2026")
  static String formatFullDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  /// Chuỗi hiển thị dải ngày của Tuần W: Ví dụ Tuần 12 trả về "19/10 - 25/10/2026"
  static String getWeekRangeFullText(int weekNumber) {
    return AcademicDateEngine.defaultInstance.getWeekDateRangeString(weekNumber);
  }

  /// Chuỗi hiển thị ngắn dải ngày của Tuần W: Ví dụ "19/10 - 25/10"
  static String getWeekRangeShortText(int weekNumber) {
    return AcademicDateEngine.defaultInstance.getWeekDateRangeShortString(weekNumber);
  }

  /// Đổi DateTime sang thứ theo quy chuẩn TTN: 2 (Thứ 2) -> 7 (Thứ 7), 8 (Chủ Nhật)
  static int getDayOfWeekTTN([DateTime? date]) {
    return AcademicDateEngine.toSchoolWeekday(date ?? DateTime.now());
  }

  /// Đổi thứ theo quy chuẩn TTN sang Dart weekday: 2 -> 1, ..., 8 -> 7
  static int toDartWeekday(int schoolWeekday) {
    return AcademicDateEngine.toDartWeekday(schoolWeekday);
  }

  /// Lấy chuỗi khung giờ học chuẩn (Ví dụ: "07:00 - 10:25" hoặc kèm label "07:00 - 10:25 (Tiết 1-4)")
  static String getTimeRangeString(int startPeriod, int length, {bool includeLabel = false}) {
    return PeriodTimeConfig.formatPeriodTimeRange(startPeriod, length, includePeriodLabel: includeLabel);
  }

  /// Parse chuỗi tiết như "1-4" hoặc "7-9" thành (startPeriod, length)
  static (int startPeriod, int length) parsePeriodString(String periodStr) {
    if (periodStr.contains('-')) {
      final parts = periodStr.split('-');
      final start = int.tryParse(parts[0]) ?? 1;
      final end = int.tryParse(parts[1]) ?? 4;
      return (start, (end - start + 1).clamp(1, 6));
    }
    final p = int.tryParse(periodStr) ?? 1;
    return (p, 1);
  }

  /// Xác định trạng thái của tiết học: Sắp diễn ra, Đang diễn ra, Đã kết thúc
  static StudyStatus getSessionStatus({
    required int weekNumber,
    required int dayOfWeek,
    required int startPeriod,
    required int length,
    DateTime? referenceDateTime,
  }) {
    final sessionDate = getDateOfDay(weekNumber, dayOfWeek);
    return AcademicDateEngine.defaultInstance.getLessonStatus(
      sessionDate,
      startPeriod,
      length,
      referenceDateTime,
    );
  }

  /// Trả về nhãn tiếng Việt tương ứng
  static String getStatusLabel(StudyStatus status) {
    return AcademicDateEngine.getStatusLabel(status);
  }

  /// Màu sắc đại diện cho trạng thái
  static Color getStatusColor(StudyStatus status) {
    return AcademicDateEngine.getStatusColor(status);
  }

  /// Màu nền badge cho trạng thái
  static Color getStatusBgColor(StudyStatus status) {
    return AcademicDateEngine.getStatusBgColor(status);
  }

  /// Màu viền badge
  static Color getStatusBorderColor(StudyStatus status) {
    return AcademicDateEngine.getStatusBorderColor(status);
  }
}
