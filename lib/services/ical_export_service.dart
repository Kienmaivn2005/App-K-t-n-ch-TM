import '../models/course.dart';

class IcalExportService {
  /// Sinh nội dung file iCalendar (.ics) chuẩn RFC 5545
  static String generateIcsContent({
    required String planName,
    required List<ClassSection> sections,
    DateTime? semesterStartDate,
  }) {
    // Ngày bắt đầu học kỳ giả định: Thứ 2 của tuần hiện tại hoặc tương lai gần
    final now = DateTime.now();
    // Tìm Thứ 2 gần nhất
    int daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    if (daysUntilMonday == 0) daysUntilMonday = 7; // Thứ 2 tuần sau
    final startOfTerm = semesterStartDate ??
        DateTime(now.year, now.month, now.day).add(Duration(days: daysUntilMonday));

    final sb = StringBuffer();
    sb.writeln('BEGIN:VCALENDAR');
    sb.writeln('VERSION:2.0');
    sb.writeln('PRODID:-//UniPlan AI//Course Registration Planner//VI');
    sb.writeln('CALSCALE:GREGORIAN');
    sb.writeln('METHOD:PUBLISH');
    sb.writeln('X-WR-CALNAME:UniPlan AI - $planName');
    sb.writeln('X-WR-TIMEZONE:Asia/Ho_Chi_Minh');

    for (final sec in sections) {
      for (final slot in sec.slots) {
        // Tính ngày đầu tiên học slot này trong tuần học kỳ
        // dayOfWeek: 2 (Thứ 2) -> offset 0 ngày từ startOfTerm (là Thứ 2)
        final dayOffset = (slot.dayOfWeek - 2) % 7;
        final slotDate = startOfTerm.add(Duration(days: dayOffset));

        // Khung giờ tiết học
        final startTime = _getPeriodStartTime(slot.startPeriod);
        final endTime = _getPeriodEndTime(slot.endPeriod);

        final dtStartStr = _formatIcsDateTime(slotDate, startTime.$1, startTime.$2);
        final dtEndStr = _formatIcsDateTime(slotDate, endTime.$1, endTime.$2);

        final uid = '${sec.id}_${slot.dayOfWeek}_${slot.startPeriod}_${slotDate.millisecondsSinceEpoch}@uniplan.edu.vn';

        sb.writeln('BEGIN:VEVENT');
        sb.writeln('UID:$uid');
        sb.writeln('DTSTAMP:${_formatIcsDateTime(DateTime.now(), 0, 0)}');
        sb.writeln('DTSTART:$dtStartStr');
        sb.writeln('DTEND:$dtEndStr');
        sb.writeln('RRULE:FREQ=WEEKLY;COUNT=15'); // 15 tuần học kỳ
        sb.writeln('SUMMARY:${_escapeIcs(sec.courseCode)} - ${_escapeIcs(sec.courseName)} (${sec.id})');
        sb.writeln('DESCRIPTION:Giảng viên: ${_escapeIcs(sec.lecturer)}\\nPhòng học: ${_escapeIcs(slot.room)}\\nCơ sở: ${_escapeIcs(sec.campus)}\\nTiết: ${slot.startPeriod}-${slot.endPeriod}');
        sb.writeln('LOCATION:${_escapeIcs(slot.room)}, ${_escapeIcs(sec.campus)}');
        sb.writeln('STATUS:CONFIRMED');
        sb.writeln('END:VEVENT');
      }
    }

    sb.writeln('END:VCALENDAR');
    return sb.toString();
  }

  static (int, int) _getPeriodStartTime(int period) {
    switch (period) {
      case 1:
        return (6, 45);
      case 2:
        return (7, 35);
      case 3:
        return (8, 30);
      case 4:
        return (9, 25);
      case 5:
        return (10, 15);
      case 6:
        return (12, 30);
      case 7:
        return (13, 20);
      case 8:
        return (14, 15);
      case 9:
        return (15, 10);
      case 10:
        return (16, 0);
      case 11:
        return (17, 15);
      case 12:
        return (18, 5);
      default:
        return (7, 0);
    }
  }

  static (int, int) _getPeriodEndTime(int period) {
    switch (period) {
      case 1:
        return (7, 30);
      case 2:
        return (8, 20);
      case 3:
        return (9, 15);
      case 4:
        return (10, 10);
      case 5:
        return (11, 0);
      case 6:
        return (13, 15);
      case 7:
        return (14, 5);
      case 8:
        return (15, 0);
      case 9:
        return (15, 55);
      case 10:
        return (16, 45);
      case 11:
        return (18, 0);
      case 12:
        return (18, 50);
      default:
        return (11, 0);
    }
  }

  static String _formatIcsDateTime(DateTime date, int hour, int minute) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = hour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');
    return '$y$m${d}T$h${min}00';
  }

  static String _escapeIcs(String text) {
    return text.replaceAll(',', '\\,').replaceAll(';', '\\;');
  }
}
