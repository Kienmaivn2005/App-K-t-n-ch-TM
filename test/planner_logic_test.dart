import 'package:flutter_test/flutter_test.dart';
import 'package:uniplan_ai/models/auto_schedule_options.dart';
import 'package:uniplan_ai/models/conflict_issue.dart';
import 'package:uniplan_ai/models/student_profile.dart';
import 'package:uniplan_ai/models/course.dart';
import 'package:uniplan_ai/models/plan.dart';
import 'package:uniplan_ai/services/mock_data.dart';
import 'package:uniplan_ai/services/conflict_checker.dart';
import 'package:uniplan_ai/services/auto_scheduler.dart';
import 'package:uniplan_ai/services/share_service.dart';
import 'package:uniplan_ai/services/ical_export_service.dart';

void main() {
  group('UniPlan AI Core Logic & Algorithm Tests', () {
    test('ConflictChecker - Detects credit bounds (12 - 24 TC)', () {
      final courses = MockDataService.getSampleCourses();
      final student = StudentProfile.defaultProfile();

      // 1 course with 2 credits should warn below 12 credits (creditUnderload)
      final oneCourse = courses.first;
      final underIssues = ConflictCheckerService.checkConflicts(
        selectedSections: {oneCourse.code: oneCourse.sections.first},
        allCourses: courses,
        student: student,
      );
      expect(
        underIssues.any((i) => i.type == ConflictType.creditUnderload),
        isTrue,
      );

      // Select normal load (e.g. 8 courses with ~18 TC)
      final selectedMap = <String, ClassSection>{};
      for (final c in courses.take(8)) {
        if (c.sections.isNotEmpty) {
          selectedMap[c.code] = c.sections.first;
        }
      }

      final normalIssues = ConflictCheckerService.checkConflicts(
        selectedSections: selectedMap,
        allCourses: courses,
        student: student,
      );

      expect(
        normalIssues.any((i) => i.type == ConflictType.creditUnderload),
        isFalse,
      );
    });

    test('ConflictChecker - Time Overlap Detection between conflicting sections', () {
      final courses = MockDataService.getSampleCourses();
      final student = StudentProfile.defaultProfile();

      // Create two sections with forced overlapping time slot (e.g. Thứ 2, tiết 1-3)
      const sec1 = ClassSection(
        id: 'SEC_TEST_1',
        courseCode: 'TEST01',
        courseName: 'Môn A',
        lecturer: 'GV A',
        lecturerRating: 4.5,
        capacity: 50,
        enrolled: 20,
        campus: 'Cơ sở chính',
        colorHex: 0xFF2563EB,
        slots: [
          ScheduleSlot(dayOfWeek: 2, startPeriod: 1, endPeriod: 3, room: 'A101'),
        ],
      );

      const sec2 = ClassSection(
        id: 'SEC_TEST_2',
        courseCode: 'TEST02',
        courseName: 'Môn B',
        lecturer: 'GV B',
        lecturerRating: 4.8,
        capacity: 50,
        enrolled: 20,
        campus: 'Cơ sở chính',
        colorHex: 0xFFDC2626,
        slots: [
          ScheduleSlot(dayOfWeek: 2, startPeriod: 2, endPeriod: 4, room: 'A102'), // Overlaps on period 2, 3
        ],
      );

      final issues = ConflictCheckerService.checkConflicts(
        selectedSections: {
          'TEST01': sec1,
          'TEST02': sec2,
        },
        allCourses: courses,
        student: student,
      );

      expect(
        issues.any((i) => i.type == ConflictType.timeOverlap && i.severity == ConflictSeverity.error),
        isTrue,
      );
    });

    test('AutoScheduler - CSP Engine produces ranked valid solutions', () {
      final courses = MockDataService.getSampleCourses();
      final targetCourses = courses.take(4).toList();

      final solutions = AutoSchedulerService.generateOptimalSchedules(
        targetCourses: targetCourses,
        criteria: AutoScheduleCriteria(
          avoidEarlyMorning: true,
          noWeekend: true,
          minimizeDays: true,
          avoidWindowPeriods: true,
          preferHighRatingLecturers: true,
        ),
        maxSolutions: 3,
      );

      expect(solutions, isNotEmpty);
      expect(solutions.first.score, greaterThanOrEqualTo(50));
      expect(solutions.first.sections.length, equals(4));
    });

    test('ShareService - Encodes & Decodes plan into Base64 share code', () {
      final plan = RegistrationPlan(
        id: 'plan_test',
        name: 'Phương án A',
        description: 'Test plan',
        selectedSections: {
          'KC212604': const ClassSection(
            id: 'KC212604_76098',
            courseCode: 'KC212604',
            courseName: 'Kỹ thuật lập trình',
            lecturer: 'ThS. Nguyễn Văn Hải',
            lecturerRating: 4.6,
            capacity: 130,
            enrolled: 7,
            campus: 'Cơ sở chính',
            colorHex: 0xFF2563EB,
            slots: [],
          ),
        },
      );

      final shareCode = ShareService.generateShareCode(plan);
      expect(shareCode, startsWith('UNIPLAN-'));

      final decoded = ShareService.decodeShareCode(shareCode);
      expect(decoded, isNotNull);
      expect(decoded!['planName'], equals('Phương án A'));
      final sectionIds = List<String>.from(decoded['sectionIds']);
      expect(sectionIds, contains('KC212604_76098'));
    });

    test('IcalExportService - Generates valid RFC 5545 iCalendar content', () {
      final courses = MockDataService.getSampleCourses();
      final sec = courses.first.sections.first;

      final icsContent = IcalExportService.generateIcsContent(
        planName: 'Test Plan',
        sections: [sec],
        semesterStartDate: DateTime(2026, 10, 19),
      );

      expect(icsContent, contains('BEGIN:VCALENDAR'));
      expect(icsContent, contains('PRODID:-//UniPlan AI//Course Registration Planner//VI'));
      expect(icsContent, contains('BEGIN:VEVENT'));
      expect(icsContent, contains(sec.courseName));
      expect(icsContent, contains('END:VCALENDAR'));
    });
  });
}
