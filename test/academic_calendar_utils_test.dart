import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniplan_ai/domain/models/schedule_section_item.dart';
import 'package:uniplan_ai/domain/models/school_week_schedule.dart';
import 'package:uniplan_ai/services/academic_calendar_utils.dart';
import 'package:uniplan_ai/services/academic_date_engine.dart';
import 'package:uniplan_ai/services/period_time_config.dart';
import 'package:uniplan_ai/services/ttn_database.dart';

void main() {
  group('PeriodTimeConfig - Bảng quy chuẩn khung giờ 12 tiết học', () {
    test('1. Kiểm tra chính xác giờ bắt đầu & kết thúc từng phút theo đặc tả', () {
      // Tiết 1: 07:00 - 07:45
      expect(PeriodTimeConfig.getStartTime(1), equals(const TimeOfDay(hour: 7, minute: 0)));
      expect(PeriodTimeConfig.getEndTime(1), equals(const TimeOfDay(hour: 7, minute: 45)));

      // Tiết 3: 08:45 - 09:30
      expect(PeriodTimeConfig.getStartTime(3), equals(const TimeOfDay(hour: 8, minute: 45)));
      expect(PeriodTimeConfig.getEndTime(3), equals(const TimeOfDay(hour: 9, minute: 30)));

      // Tiết 6: 13:00 - 13:45
      expect(PeriodTimeConfig.getStartTime(6), equals(const TimeOfDay(hour: 13, minute: 0)));
      expect(PeriodTimeConfig.getEndTime(6), equals(const TimeOfDay(hour: 13, minute: 45)));

      // Tiết 8: 14:45 - 15:30
      expect(PeriodTimeConfig.getStartTime(8), equals(const TimeOfDay(hour: 14, minute: 45)));
      expect(PeriodTimeConfig.getEndTime(8), equals(const TimeOfDay(hour: 15, minute: 30)));

      // Tiết 12: 18:20 - 19:05
      expect(PeriodTimeConfig.getStartTime(12), equals(const TimeOfDay(hour: 18, minute: 20)));
      expect(PeriodTimeConfig.getEndTime(12), equals(const TimeOfDay(hour: 19, minute: 5)));
    });

    test('2. formatPeriodTimeRange(1, 4) trả về "07:00 - 10:25 (Tiết 1-4)"', () {
      final rangeStr = PeriodTimeConfig.formatPeriodTimeRange(1, 4);
      expect(rangeStr, equals('07:00 - 10:25 (Tiết 1-4)'));

      final rangeNoLabel = PeriodTimeConfig.formatPeriodTimeRange(1, 4, includePeriodLabel: false);
      expect(rangeNoLabel, equals('07:00 - 10:25'));
    });
  });

  group('AcademicDateEngine - Thuật toán tuần, chuẩn hóa weekday & tuần nghỉ', () {
    final engine = AcademicDateEngine(
      semesterStartDate: DateTime(2026, 8, 3), // Thứ 2 Tuần 1
      breakWeeks: {8, 16}, // Nghỉ giữa kỳ tuần 8 và tuần 16
    );

    test('3. Chuẩn hóa Weekday hai chiều giữa Dart và Hệ thống trường TTN', () {
      // Thứ 2: Dart = 1, Trường = 2
      final mon = DateTime(2026, 10, 19); // Thứ 2
      expect(AcademicDateEngine.toSchoolWeekday(mon), equals(2));
      expect(AcademicDateEngine.toDartWeekday(2), equals(1));
      expect(AcademicDateEngine.getSchoolWeekdayLabel(2), equals('Thứ 2'));

      // Thứ 7: Dart = 6, Trường = 7
      final sat = DateTime(2026, 10, 24); // Thứ 7
      expect(AcademicDateEngine.toSchoolWeekday(sat), equals(7));
      expect(AcademicDateEngine.toDartWeekday(7), equals(6));
      expect(AcademicDateEngine.getSchoolWeekdayLabel(7), equals('Thứ 7'));

      // Chủ Nhật: Dart = 7, Trường = 8
      final sun = DateTime(2026, 10, 25); // Chủ Nhật
      expect(AcademicDateEngine.toSchoolWeekday(sun), equals(8));
      expect(AcademicDateEngine.toDartWeekday(8), equals(7));
      expect(AcademicDateEngine.getSchoolWeekdayLabel(8), equals('Chủ Nhật'));
    });

    test('4. Chuẩn hóa 00:00:00: Mở app giữa tuần hoặc cuối tuần không bị lệch tuần', () {
      // Tuần 12: 19/10/2026 (Thứ 2) -> 25/10/2026 (Chủ Nhật)
      final monday = DateTime(2026, 10, 19, 0, 0, 0);
      final wednesdayNoon = DateTime(2026, 10, 21, 14, 30, 0);
      final sundayNight = DateTime(2026, 10, 25, 23, 59, 59);

      expect(engine.getCurrentWeek(monday), equals(12));
      expect(engine.getCurrentWeek(wednesdayNoon), equals(12));
      expect(engine.getCurrentWeek(sundayNight), equals(12));
    });

    test('5. Hỗ trợ tuần nghỉ học (breakWeeks)', () {
      expect(engine.isBreakWeek(8), isTrue);
      expect(engine.isBreakWeek(12), isFalse);
      expect(engine.isBreakWeek(16), isTrue);
    });

    test('6. getLessonStatus: Trả về StudyStatus (ongoing, upcoming, completed)', () {
      final lessonDate = DateTime(2026, 10, 19);

      // Sắp diễn ra: 06:45 sáng
      final earlyTime = DateTime(2026, 10, 19, 6, 45);
      expect(engine.getLessonStatus(lessonDate, 1, 4, earlyTime), equals(StudyStatus.upcoming));

      // Đang diễn ra: 08:30 sáng
      final duringTime = DateTime(2026, 10, 19, 8, 30);
      expect(engine.getLessonStatus(lessonDate, 1, 4, duringTime), equals(StudyStatus.ongoing));

      // Đã kết thúc: 10:30 sáng
      final afterTime = DateTime(2026, 10, 19, 10, 30);
      expect(engine.getLessonStatus(lessonDate, 1, 4, afterTime), equals(StudyStatus.completed));
    });

    test('7. Tách biệt Ca học (TimeSlot Separation): Lý thuyết tuần 1-10, Thực hành tuần 5-15', () {
      const complexCourse = ScheduleSectionItem(
        courseCode: 'LT_TH_01',
        courseName: 'Mạng máy tính nâng cao',
        dayOfWeek: 2,
        startPeriod: 1,
        length: 4,
        room: 'P.7.3.18',
        lecturer: 'ThS. Nguyễn Văn A',
        activeWeeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], // Lý thuyết tuần 1-10
        meetingSlots: [
          SectionMeetingSlot(
            dayOfWeek: 5,
            startPeriod: 7,
            length: 4,
            room: 'Lab Mạng 2',
            lecturer: 'ThS. Lê Hoàng Long',
            activeWeeks: [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], // Thực hành tuần 5-15
            isPractice: true,
          ),
        ],
      );

      // Tuần 3: Có học Lý thuyết, chưa học Thực hành
      expect(complexCourse.isStudyingInWeek(3), isTrue);
      expect(complexCourse.meetingSlots.first.isStudyingInWeek(3), isFalse);

      // Tuần 12: Hết Lý thuyết, đang học Thực hành
      expect(complexCourse.meetingSlots.first.isStudyingInWeek(12), isTrue);
      expect(complexCourse.activeWeeks.contains(12), isFalse);

      // Tuần 18: Đã hoàn thành cả LT và TH
      expect(complexCourse.isStudyingInWeek(18), isFalse);
    });
  });

  group('AcademicCalendarUtils - Tích hợp toàn diện & Lọc cho mọi MSSV', () {
    test('8. Mốc bắt đầu kỳ học chính xác Thứ 2, 03/08/2026 là Tuần 1', () {
      expect(AcademicCalendarUtils.semesterStartDate, equals(DateTime(2026, 8, 3)));
      final week1 = AcademicCalendarUtils.getCurrentWeek(DateTime(2026, 8, 3));
      expect(week1, equals(1));
    });

    test('9. Chuỗi dải ngày tuần 12 hiển thị đúng "19/10 - 25/10/2026"', () {
      final rangeFull = AcademicCalendarUtils.getWeekRangeFullText(12);
      expect(rangeFull, equals('19/10 - 25/10/2026'));
    });

    test('10. Đổi MSSV trên Dropdown tự động cập nhật thời khóa biểu theo đúng sinh viên', () {
      final kienRows = TTNDatabase.getStudentTimetableRows('23103035', null, null, 12);
      expect(kienRows.length, equals(9));

      final emptyRows = TTNDatabase.getStudentTimetableRows('23103005', null, null, 12);
      expect(emptyRows, isEmpty);

      final yKhoaRows = TTNDatabase.getStudentTimetableRows('23772001', null, null, 12);
      expect(yKhoaRows.any((r) => r['name'].toString().contains('Giải phẫu')), isTrue);
    });

    test('11. TTNDatabase.getStudentScheduleItems trả về ScheduleSectionItem chuẩn hóa', () {
      final items = TTNDatabase.getStudentScheduleItems('23103035', 12);
      expect(items.length, equals(9));
      expect(items.first, isA<ScheduleSectionItem>());
    });
  });

  group('SchoolWeekSchedule - Đồng bộ 100% Cổng Đào Tạo TTN (ttn.edu.vn)', () {
    test('12. Khối tuần riêng biệt có tiêu đề "Từ ngày dd/MM/yyyy đến ngày dd/MM/yyyy"', () {
      final week12 = TTNDatabase.getStudentSchoolWeekSchedule('23103035', 12);
      expect(week12.weekTitle, equals('Từ ngày 19/10/2026 đến ngày 25/10/2026'));
      expect(week12.isEmptyWeek, isFalse);
      expect(week12.totalLessonsCount, equals(9));
    });

    test('13. Phân chia 3 hàng (Sáng, Chiều, Tối) và 7 cột (T2 -> CN)', () {
      final week12 = TTNDatabase.getStudentSchoolWeekSchedule('23103035', 12);

      // Thứ 2: Sáng có LS Đảng, Chiều trống, Tối trống
      final t2Sang = week12.getLessons('Sáng', 2);
      expect(t2Sang.length, equals(1));
      expect(t2Sang.first.courseName, contains('LS Đảng'));
      expect(week12.getLessons('Chiều', 2), isEmpty);
      expect(week12.getLessons('Tối', 2), isEmpty);

      // Thứ 4: Sáng có Lập trình di động, Chiều có QTM trên MT Windows
      final t4Sang = week12.getLessons('Sáng', 4);
      final t4Chieu = week12.getLessons('Chiều', 4);
      expect(t4Sang.first.courseName, contains('Lập trình di động'));
      expect(t4Chieu.first.courseName, contains('QTM'));

      // Chủ Nhật: Không có tiết học
      expect(week12.getLessons('Sáng', 8), isEmpty);
      expect(week12.getLessons('Chiều', 8), isEmpty);
    });

    test('14. Nhận diện tuần trống (Hết môn / Nghỉ thi) hiển thị ô trống chuẩn web trường', () {
      final emptyWeek = SchoolWeekSchedule.empty(
        weekNumber: 15,
        startDate: DateTime(2026, 11, 9),
        endDate: DateTime(2026, 11, 15),
      );
      expect(emptyWeek.isEmptyWeek, isTrue);
      expect(emptyWeek.totalLessonsCount, equals(0));
      expect(emptyWeek.getLessons('Sáng', 2), isEmpty);
      expect(emptyWeek.weekTitle, equals('Từ ngày 09/11/2026 đến ngày 15/11/2026'));
    });
  });
}
