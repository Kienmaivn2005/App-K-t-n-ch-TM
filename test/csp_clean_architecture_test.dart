import 'package:flutter_test/flutter_test.dart';
import 'package:uniplan_ai/core/algorithm/schedule_evaluator.dart';
import 'package:uniplan_ai/core/algorithm/schedule_solver.dart';
import 'package:uniplan_ai/core/utils/ics_exporter.dart';
import 'package:uniplan_ai/data/models/course_model.dart';
import 'package:uniplan_ai/data/models/course_section_model.dart';
import 'package:uniplan_ai/data/models/time_slot_model.dart';
import 'package:uniplan_ai/data/repositories/mock_course_repository.dart';

void main() {
  group('Module 1: Data Modeling & Conflict Detection', () {
    test('TimeSlot conflictsWith returns true for overlapping periods on same day', () {
      const slot1 = TimeSlot(dayOfWeek: 2, startPeriod: 1, length: 3, room: '7.3.18'); // Periods 1,2,3
      const slot2 = TimeSlot(dayOfWeek: 2, startPeriod: 3, length: 2, room: '7.3.16'); // Periods 3,4
      const slot3 = TimeSlot(dayOfWeek: 2, startPeriod: 4, length: 2, room: '7.3.18'); // Periods 4,5
      const slot4 = TimeSlot(dayOfWeek: 3, startPeriod: 1, length: 3, room: '7.3.18'); // Different day

      expect(slot1.conflictsWith(slot2), isTrue); // Trùng tiết 3
      expect(slot1.conflictsWith(slot3), isFalse); // Tiết 1-3 và Tiết 4-5 không trùng
      expect(slot1.conflictsWith(slot4), isFalse); // Khác ngày không trùng
    });

    test('CourseSection conflictsWith checks any slot overlaps', () {
      const secA = CourseSection(
        classId: 'KC215046_01',
        courseId: 'KC215046',
        courseName: 'Lập trình di động',
        lecturer: 'GV A',
        slots: [
          TimeSlot(dayOfWeek: 2, startPeriod: 1, length: 4, room: '7.3.18'),
          TimeSlot(dayOfWeek: 4, startPeriod: 7, length: 3, room: 'Lab 7.3.18'),
        ],
      );

      const secB = CourseSection(
        classId: 'KC215047_01',
        courseId: 'KC215047',
        courseName: 'An toàn thông tin',
        lecturer: 'GV B',
        slots: [
          TimeSlot(dayOfWeek: 2, startPeriod: 4, length: 3, room: '6.12'), // Trùng tiết 4 vào Thứ 2
        ],
      );

      const secC = CourseSection(
        classId: 'KC215048_01',
        courseId: 'KC215048',
        courseName: 'Thương mại điện tử',
        lecturer: 'GV C',
        slots: [
          TimeSlot(dayOfWeek: 3, startPeriod: 7, length: 4, room: '3.2.04'),
        ],
      );

      expect(secA.conflictsWith(secB), isTrue);
      expect(secA.conflictsWith(secC), isFalse);
    });
  });

  group('Module 2: CSP Solver & Schedule Evaluator', () {
    test('ScheduleSolver finds valid non-conflicting plans', () {
      final courses = [
        const Course(
          id: 'M1',
          name: 'Môn 1',
          credits: 3,
          sections: [
            CourseSection(
              classId: 'M1_01',
              courseId: 'M1',
              courseName: 'Môn 1',
              lecturer: 'GV 1',
              slots: [TimeSlot(dayOfWeek: 2, startPeriod: 1, length: 3, room: 'P1')],
            ),
            CourseSection(
              classId: 'M1_02',
              courseId: 'M1',
              courseName: 'Môn 1',
              lecturer: 'GV 1',
              slots: [TimeSlot(dayOfWeek: 3, startPeriod: 1, length: 3, room: 'P1')],
            ),
          ],
        ),
        const Course(
          id: 'M2',
          name: 'Môn 2',
          credits: 3,
          sections: [
            CourseSection(
              classId: 'M2_01',
              courseId: 'M2',
              courseName: 'Môn 2',
              lecturer: 'GV 2',
              slots: [TimeSlot(dayOfWeek: 2, startPeriod: 2, length: 3, room: 'P2')], // Xung đột với M1_01 (tiết 2,3)
            ),
            CourseSection(
              classId: 'M2_02',
              courseId: 'M2',
              courseName: 'Môn 2',
              lecturer: 'GV 2',
              slots: [TimeSlot(dayOfWeek: 4, startPeriod: 1, length: 3, room: 'P2')], // Hợp lệ với mọi lớp
            ),
          ],
        ),
      ];

      final plans = ScheduleSolver.solveSync(selectedCourses: courses);
      expect(plans, isNotEmpty);

      // Mọi phương án tạo ra phải không có bất kỳ xung đột nào giữa các lớp
      for (final plan in plans) {
        expect(plan.selectedSections.length, equals(2));
        final s1 = plan.selectedSections[0];
        final s2 = plan.selectedSections[1];
        expect(s1.conflictsWith(s2), isFalse);
      }
    });

    test('ScheduleEvaluator applies soft constraints correctly', () {
      const planMorning = SchedulePlan(
        id: 'p1',
        totalCredits: 6,
        selectedSections: [
          CourseSection(
            classId: 'SEC_M',
            courseId: 'M1',
            courseName: 'Môn Sáng',
            lecturer: 'GV',
            slots: [TimeSlot(dayOfWeek: 2, startPeriod: 1, length: 4, room: '101')],
          ),
        ],
      );

      const criteria = ScheduleFilterCriteria(
        preferMorning: true,
        avoidFriday: true,
      );

      final evaluated = ScheduleEvaluator.evaluatePlan(planMorning, criteria);
      expect(evaluated.score, greaterThan(0));
      expect(evaluated.tags, contains('Nghỉ Thứ 6'));
      expect(evaluated.tags, contains('100% Học Sáng'));
    });
  });

  group('Module 5: iCalendar Exporter', () {
    test('generateIcsContent generates valid RFC 5545 format', () {
      const plan = SchedulePlan(
        id: 'test_plan',
        totalCredits: 3,
        selectedSections: [
          CourseSection(
            classId: 'KC215046_01',
            courseId: 'KC215046',
            courseName: 'Lập trình di động',
            lecturer: 'ThS. Trương Thị Hương Giang',
            slots: [
              TimeSlot(dayOfWeek: 4, startPeriod: 1, length: 4, room: '7.3.18'),
            ],
          ),
        ],
      );

      final ics = IcsExporter.generateIcsContent(plan);
      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('VERSION:2.0'));
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('SUMMARY:Lập trình di động (KC215046_01)'));
      expect(ics, contains('LOCATION:Phòng 7.3.18'));
      expect(ics, contains('RRULE:FREQ=WEEKLY'));
      expect(ics, contains('END:VEVENT'));
      expect(ics, contains('END:VCALENDAR'));
    });
  });

  group('Repository & Mock Data', () {
    test('MockCourseRepository search returns courses and faculties', () async {
      final courses = await MockCourseRepository.searchCourses(query: 'di động');
      expect(courses, isNotEmpty);
      expect(courses.first.name, contains('di động'));

      final faculties = MockCourseRepository.getFaculties();
      expect(faculties, contains('Tất cả'));
      expect(faculties, contains('Khoa KHTN&CN'));
    });
  });
}
