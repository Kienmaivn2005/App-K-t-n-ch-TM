import '../../data/models/course_model.dart';

/// Tiện ích xuất file lịch chuẩn RFC 5545 iCalendar (.ics)
class IcsExporter {
  /// Sinh nội dung chuỗi file .ics từ một phương án SchedulePlan (phiên bản ngắn gọn)
  static String generateIcsContent(SchedulePlan plan) => generateIcsString(plan: plan);

  /// Sinh nội dung chuỗi file .ics từ một phương án SchedulePlan
  static String generateIcsString({
    required SchedulePlan plan,
    String calendarName = 'UniPlan - Kế Hoạch Tín Chỉ ĐH Tây Nguyên',
    DateTime? semesterStartDate,
    int numberOfWeeks = 15,
  }) {
    // Mặc định kỳ học bắt đầu vào Thứ Hai gần nhất
    final baseStart = semesterStartDate ?? _getNextMonday(DateTime.now());
    final semesterEnd = baseStart.add(Duration(days: numberOfWeeks * 7));

    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//UniPlan AI//Smart Timetable Scheduler//VI');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:$calendarName');
    buffer.writeln('X-WR-TIMEZONE:Asia/Ho_Chi_Minh');

    for (final section in plan.selectedSections) {
      for (final slot in section.slots) {
        final eventDate = _getDateForDayOfWeek(baseStart, slot.dayOfWeek);
        final startDateTime = _getDateTimeForPeriod(eventDate, slot.startPeriod);
        final endDateTime = _getDateTimeForPeriodEnd(eventDate, slot.endPeriod);

        final uid = '${section.classId}_slot_${slot.dayOfWeek}_${slot.startPeriod}@uniplan.edu.vn';
        final nowFormatted = _formatIcsDateTime(DateTime.now().toUtc());
        final startFormatted = _formatIcsDateTime(startDateTime);
        final endFormatted = _formatIcsDateTime(endDateTime);
        final untilFormatted = _formatIcsDateOnly(semesterEnd);

        buffer.writeln('BEGIN:VEVENT');
        buffer.writeln('UID:$uid');
        buffer.writeln('DTSTAMP:$nowFormatted');
        buffer.writeln('DTSTART:$startFormatted');
        buffer.writeln('DTEND:$endFormatted');
        buffer.writeln('RRULE:FREQ=WEEKLY;UNTIL=${untilFormatted}T235959Z');
        buffer.writeln('SUMMARY:${section.courseName} (${section.classId})');
        buffer.writeln('LOCATION:Phòng ${slot.room}');
        buffer.writeln(
            'DESCRIPTION:Học phần: ${section.courseName}\\nMã lớp: ${section.classId}\\nGiảng viên: ${section.lecturer}\\nKhung giờ: ${slot.periodString} (${slot.estimatedTimeString})');
        buffer.writeln('STATUS:CONFIRMED');
        buffer.writeln('END:VEVENT');
      }
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  static DateTime _getNextMonday(DateTime date) {
    int daysUntilMonday = (DateTime.monday - date.weekday + 7) % 7;
    if (daysUntilMonday == 0) daysUntilMonday = 7;
    return DateTime(date.year, date.month, date.day).add(Duration(days: daysUntilMonday));
  }

  static DateTime _getDateForDayOfWeek(DateTime baseMonday, int dayOfWeek) {
    // dayOfWeek: 2 (Thứ 2) -> 7 (Thứ 7), 8: CN
    final offset = (dayOfWeek == 8 ? 6 : dayOfWeek - 2);
    return baseMonday.add(Duration(days: offset));
  }

  static DateTime _getDateTimeForPeriod(DateTime date, int period) {
    int hour = 7;
    int minute = 0;
    switch (period) {
      case 1:
        hour = 7;
        minute = 0;
        break;
      case 2:
        hour = 7;
        minute = 50;
        break;
      case 3:
        hour = 8;
        minute = 50;
        break;
      case 4:
        hour = 9;
        minute = 40;
        break;
      case 5:
        hour = 10;
        minute = 30;
        break;
      case 6:
        hour = 13;
        minute = 0;
        break;
      case 7:
        hour = 13;
        minute = 50;
        break;
      case 8:
        hour = 14;
        minute = 50;
        break;
      case 9:
        hour = 15;
        minute = 40;
        break;
      case 10:
        hour = 16;
        minute = 30;
        break;
      case 11:
        hour = 17;
        minute = 30;
        break;
      case 12:
        hour = 18;
        minute = 20;
        break;
    }
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static DateTime _getDateTimeForPeriodEnd(DateTime date, int endPeriod) {
    int hour = 7;
    int minute = 45;
    switch (endPeriod) {
      case 1:
        hour = 7;
        minute = 45;
        break;
      case 2:
        hour = 8;
        minute = 35;
        break;
      case 3:
        hour = 9;
        minute = 35;
        break;
      case 4:
        hour = 10;
        minute = 25;
        break;
      case 5:
        hour = 11;
        minute = 15;
        break;
      case 6:
        hour = 13;
        minute = 45;
        break;
      case 7:
        hour = 14;
        minute = 35;
        break;
      case 8:
        hour = 15;
        minute = 35;
        break;
      case 9:
        hour = 16;
        minute = 25;
        break;
      case 10:
        hour = 17;
        minute = 15;
        break;
      case 11:
        hour = 18;
        minute = 15;
        break;
      case 12:
        hour = 19;
        minute = 5;
        break;
    }
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static String _formatIcsDateTime(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}T'
        '${dt.hour.toString().padLeft(2, '0')}'
        '${dt.minute.toString().padLeft(2, '0')}'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  static String _formatIcsDateOnly(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}
