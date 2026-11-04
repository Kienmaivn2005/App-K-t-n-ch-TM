import 'package:flutter_test/flutter_test.dart';
import 'package:uniplan_ai/models/auto_schedule_options.dart';
import 'package:uniplan_ai/models/conflict_issue.dart';
import 'package:uniplan_ai/models/student_profile.dart';
import 'package:uniplan_ai/models/course.dart';
import 'package:uniplan_ai/services/mock_data.dart';
import 'package:uniplan_ai/services/conflict_checker.dart';
import 'package:uniplan_ai/services/auto_scheduler.dart';

void main() {
  group('Giai đoạn 5: Performance Benchmark & Boundary Testing', () {
    test('Boundary: Missing prerequisite raises ConflictType.missingPrerequisite', () {
      final courses = MockDataService.getSampleCourses();
      // Student has NOT passed anything
      const studentNoPassed = StudentProfile(
        studentId: '23100000',
        fullName: 'Sinh Viên Mới',
        major: 'CNTT',
        cohort: 'K23',
        currentGpa: 3.0,
        targetGpa: 3.5,
        passedCourses: [], // Không có môn tiên quyết nào
      );

      // KC213613 (An toàn thông tin) requires KC215039 (Nhập môn mạng máy tính)
      final secCourse = courses.firstWhere((c) => c.code == 'KC213613');
      final issues = ConflictCheckerService.checkConflicts(
        selectedSections: {secCourse.code: secCourse.sections.first},
        allCourses: courses,
        student: studentNoPassed,
      );

      expect(
        issues.any((i) => i.type == ConflictType.missingPrerequisite && i.severity == ConflictSeverity.error),
        isTrue,
      );
    });

    test('Boundary: Academic Warning Level 1 restricts credits to max 14 TC', () {
      final courses = MockDataService.getSampleCourses();
      const studentWarning = StudentProfile(
        studentId: '23101111',
        fullName: 'Sinh Viên Cảnh Báo',
        major: 'CNTT',
        cohort: 'K23',
        currentGpa: 1.8,
        targetGpa: 2.5,
        academicWarning: AcademicWarning.warningLevel1, // Giới hạn 14 TC
        passedCourses: ['KC211027', 'FL211011'],
      );

      // Select 6 courses totaling ~16-18 TC
      final selectedMap = <String, ClassSection>{};
      int totalCr = 0;
      for (final c in courses) {
        if (c.sections.isNotEmpty && totalCr < 16) {
          selectedMap[c.code] = c.sections.first;
          totalCr += c.credits;
        }
      }

      final issues = ConflictCheckerService.checkConflicts(
        selectedSections: selectedMap,
        allCourses: courses,
        student: studentWarning,
      );

      expect(
        issues.any((i) => i.type == ConflictType.creditOverload && i.title.contains('Cảnh báo học vụ')),
        isTrue,
      );
    });

    test('Boundary: Deadlock / All sections conflicting returns empty solutions without throwing', () {
      // 2 courses that only have 1 section each at the exact same time
      const sec1 = ClassSection(
        id: 'CLASH_01',
        courseCode: 'M1',
        courseName: 'Môn 1',
        lecturer: 'GV 1',
        lecturerRating: 4.0,
        capacity: 40,
        enrolled: 10,
        campus: 'Cơ sở chính',
        colorHex: 0xFF112233,
        slots: [ScheduleSlot(dayOfWeek: 2, startPeriod: 1, endPeriod: 4, room: '1.1')],
      );

      const sec2 = ClassSection(
        id: 'CLASH_02',
        courseCode: 'M2',
        courseName: 'Môn 2',
        lecturer: 'GV 2',
        lecturerRating: 4.0,
        capacity: 40,
        enrolled: 10,
        campus: 'Cơ sở chính',
        colorHex: 0xFF445566,
        slots: [ScheduleSlot(dayOfWeek: 2, startPeriod: 1, endPeriod: 4, room: '1.2')], // Same time!
      );

      const c1 = Course(
        code: 'M1',
        name: 'Môn 1',
        credits: 3,
        theoryCredits: 3,
        practiceCredits: 0,
        department: 'CNTT',
        recommendedSemester: 1,
        category: CourseCategory.general,
        sections: [sec1],
      );
      const c2 = Course(
        code: 'M2',
        name: 'Môn 2',
        credits: 3,
        theoryCredits: 3,
        practiceCredits: 0,
        department: 'CNTT',
        recommendedSemester: 1,
        category: CourseCategory.general,
        sections: [sec2],
      );

      final solutions = AutoSchedulerService.generateOptimalSchedules(
        targetCourses: [c1, c2],
        criteria: AutoScheduleCriteria(),
      );

      expect(solutions, isEmpty);
    });

    test('Performance Benchmark: Schedule generation for 8 to 10 courses runs in < 2.0 seconds', () {
      final courses = MockDataService.getSampleCourses();
      // Take 9 courses with opened sections
      final targetCourses = courses.where((c) => c.sections.isNotEmpty).take(9).toList();
      expect(targetCourses.length, greaterThanOrEqualTo(8));

      final stopwatch = Stopwatch()..start();

      final solutions = AutoSchedulerService.generateOptimalSchedules(
        targetCourses: targetCourses,
        criteria: AutoScheduleCriteria(
          avoidEarlyMorning: false,
          noWeekend: false,
          freeFriday: false,
          minimizeDays: false,
          avoidWindowPeriods: false,
          preferHighRatingLecturers: false,
        ),
        maxSolutions: 5,
      );

      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;

      // Performance Benchmark: Solving 8-10 courses must complete in under 2.0s
      expect(elapsedMs, lessThan(2000));
      // Also verify solver runs correctly
      expect(solutions, isA<List<AutoScheduleSolution>>());
    });
  });
}
