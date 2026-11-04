import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniplan_ai/services/ttn_portal_service.dart';
import 'package:uniplan_ai/services/ttn_database.dart';

void main() {
  group('TTNPortalService Tests', () {
    test('Phân giải HTML sinh viên 24103035 chính xác từ cổng TTN', () {
      final sampleFile = File(r'C:\Users\PC\.gemini\antigravity\brain\896937ad-2ec1-4b82-a220-73684cf36574\scratch\timetable_24103035.html');
      if (!sampleFile.existsSync()) return;

      final html = sampleFile.readAsStringSync();
      final result = TTNPortalService.parsePortalHtml('24103035', html);

      expect(result.success, isTrue);
      expect(result.msv, equals('24103035'));
      expect(result.fullName, equals('Trần Thị Thu Hiền'));
      expect(result.weekSchedules.isNotEmpty, isTrue);
      expect(result.totalLessons, greaterThan(0));

      // Kiểm tra tuần 14 (từ ngày 02/11/2026)
      final week14 = result.weekSchedules[14];
      expect(week14, isNotNull);
      expect(week14!.isEmptyWeek, isFalse);

      // Kiểm tra các môn học trong tuần 14:
      // Thứ 3: Khởi nghiệp
      final t3Lessons = week14.getLessons('Sáng', 3);
      expect(t3Lessons.any((l) => l.courseName.contains('Khởi nghiệp')), isTrue);

      // Thứ 4: Chủ nghĩa XH KH
      final t4Lessons = week14.getLessons('Sáng', 4);
      expect(t4Lessons.any((l) => l.courseName.contains('Chủ nghĩa XH KH')), isTrue);
    });

    test('Phân giải HTML sinh viên 23103035 (tuần trống) từ cổng TTN', () {
      final sampleFile = File(r'C:\Users\PC\.gemini\antigravity\brain\896937ad-2ec1-4b82-a220-73684cf36574\scratch\timetable_23103035.html');
      if (!sampleFile.existsSync()) return;

      final html = sampleFile.readAsStringSync();
      final result = TTNPortalService.parsePortalHtml('23103035', html);

      expect(result.success, isTrue);
      expect(result.msv, equals('23103035'));
      expect(result.fullName, equals('Mai Đàm Thế Kiên'));
      expect(result.totalLessons, equals(0));
    });

    test('Đồng bộ vào TTNDatabase và lấy lại SchoolWeekSchedule', () {
      final sampleFile = File(r'C:\Users\PC\.gemini\antigravity\brain\896937ad-2ec1-4b82-a220-73684cf36574\scratch\timetable_24103035.html');
      if (!sampleFile.existsSync()) return;

      final html = sampleFile.readAsStringSync();
      final result = TTNPortalService.parsePortalHtml('24103035', html);

      TTNDatabase.registerOrUpdateStudentFromWeb(
        msv: result.msv,
        fullName: result.fullName,
        slots: result.slots,
        weekSchedules: result.weekSchedules,
      );

      final student = TTNDatabase.getStudent('24103035');
      expect(student, isNotNull);
      expect(student!['fullName'], equals('Trần Thị Thu Hiền'));

      final week14Schedule = TTNDatabase.getStudentSchoolWeekSchedule('24103035', 14);
      expect(week14Schedule.isEmptyWeek, isFalse);
    });
  });
}
