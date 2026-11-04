import '../models/course.dart';
import '../models/student_profile.dart';
import '../models/conflict_issue.dart';

class ConflictCheckerService {
  static const int minCreditsAllowed = 12;
  static const int maxCreditsAllowed = 24;

  /// Kiểm tra toàn diện xung đột & ràng buộc của 1 kế hoạch
  static List<ConflictIssue> checkConflicts({
    required Map<String, ClassSection> selectedSections,
    required List<Course> allCourses,
    required StudentProfile student,
  }) {
    final issues = <ConflictIssue>[];
    final sections = selectedSections.values.toList();
    final courseMap = {for (var c in allCourses) c.code: c};

    // 1. Kiểm tra Trùng thời gian (Time Overlap) giữa các lớp học phần
    for (int i = 0; i < sections.length; i++) {
      for (int j = i + 1; j < sections.length; j++) {
        final s1 = sections[i];
        final s2 = sections[j];

        for (final slot1 in s1.slots) {
          for (final slot2 in s2.slots) {
            if (slot1.conflictsWith(slot2)) {
              issues.add(
                ConflictIssue(
                  id: 'overlap_${s1.id}_${s2.id}_${slot1.dayOfWeek}_${slot1.startPeriod}',
                  type: ConflictType.timeOverlap,
                  severity: ConflictSeverity.error,
                  title: 'Trùng lịch học: ${s1.courseCode} và ${s2.courseCode}',
                  description:
                      'Lớp [${s1.id}] (${s1.courseName}) và lớp [${s2.id}] (${s2.courseName}) bị trùng nhau vào ${slot1.dayName}: Tiết ${slot1.startPeriod}-${slot1.endPeriod} vs Tiết ${slot2.startPeriod}-${slot2.endPeriod}.',
                  relatedCourseCodes: [s1.courseCode, s2.courseCode],
                  relatedSectionIds: [s1.id, s2.id],
                ),
              );
            }
          }
        }
      }
    }

    // 2. Kiểm tra Môn tiên quyết (Prerequisite Check)
    for (final sec in sections) {
      final course = courseMap[sec.courseCode];
      if (course != null && course.prerequisites.isNotEmpty) {
        for (final prereqCode in course.prerequisites) {
          final hasPassed = student.hasPassed(prereqCode);
          if (!hasPassed) {
            final prereqCourse = courseMap[prereqCode];
            final prereqName = prereqCourse != null ? prereqCourse.name : prereqCode;
            issues.add(
              ConflictIssue(
                id: 'prereq_${course.code}_$prereqCode',
                type: ConflictType.missingPrerequisite,
                severity: ConflictSeverity.error,
                title: 'Chưa thỏa điều kiện tiên quyết môn ${course.code}',
                description:
                    'Môn "${course.name}" (${course.code}) bắt buộc bạn phải đạt môn tiên quyết "$prereqName" ($prereqCode) trước khi đăng ký.',
                relatedCourseCodes: [course.code, prereqCode],
                relatedSectionIds: [sec.id],
              ),
            );
          }
        }
      }
    }

    // 3. Kiểm tra Giới hạn Tín chỉ (Credit boundary check: 12 - 24 TC hoặc theo Cảnh báo học vụ)
    int totalCredits = 0;
    for (final sec in sections) {
      final course = courseMap[sec.courseCode];
      if (course != null) {
        totalCredits += course.credits;
      }
    }

    final allowedMax = student.maxAllowedCredits;

    if (totalCredits > 0 && totalCredits < minCreditsAllowed) {
      issues.add(
        ConflictIssue(
          id: 'under_credit_$totalCredits',
          type: ConflictType.creditUnderload,
          severity: ConflictSeverity.warning,
          title: 'Chưa đủ số tín chỉ tối thiểu theo quy chế ($totalCredits / $minCreditsAllowed TC)',
          description:
              'Theo quy chế đào tạo tín chỉ TTN, sinh viên cần đăng ký tối thiểu $minCreditsAllowed tín chỉ mỗi học kỳ chính (trừ kỳ thực tập/tốt nghiệp). Bạn đang thiếu ${minCreditsAllowed - totalCredits} tín chỉ.',
        ),
      );
    } else if (totalCredits > allowedMax) {
      final isWarning = student.academicWarning != AcademicWarning.none;
      issues.add(
        ConflictIssue(
          id: 'over_credit_$totalCredits',
          type: ConflictType.creditOverload,
          severity: ConflictSeverity.warning,
          title: isWarning
              ? 'Vượt hạn mức do Cảnh báo học vụ ($totalCredits / $allowedMax TC)'
              : 'Vượt quá hạn mức tín chỉ tối đa ($totalCredits / $allowedMax TC)',
          description: isWarning
              ? 'Bạn đang trong diện "${student.academicWarning.label}". Quy chế đào tạo TTN quy định sinh viên bị cảnh báo học vụ chỉ được phép đăng ký tối đa $allowedMax tín chỉ.'
              : 'Bạn đã chọn $totalCredits tín chỉ, vượt mức trần $allowedMax tín chỉ cho phép. Nếu muốn học thêm, sinh viên cần nộp đơn xin mở rộng hạn mức và có GPA >= 3.2.',
        ),
      );
    }

    // 4. Kiểm tra Di chuyển giữa các cơ sở sát giờ (Campus switch)
    for (int i = 0; i < sections.length; i++) {
      for (int j = 0; j < sections.length; j++) {
        if (i == j) continue;
        final s1 = sections[i];
        final s2 = sections[j];
        if (s1.campus != s2.campus) {
          for (final slot1 in s1.slots) {
            for (final slot2 in s2.slots) {
              if (slot1.dayOfWeek == slot2.dayOfWeek) {
                // S1 ca sáng kết thúc tiết 5, S2 ca chiều bắt đầu tiết 6 khác cơ sở
                if (slot1.endPeriod == 5 && slot2.startPeriod == 6) {
                  issues.add(
                    ConflictIssue(
                      id: 'campus_${s1.id}_${s2.id}',
                      type: ConflictType.campusSwitch,
                      severity: ConflictSeverity.warning,
                      title: 'Khoảng cách cơ sở sát giờ vào ${slot1.dayName}',
                      description:
                          'Lớp [${s1.id}] học tại ${s1.campus} (kết thúc 11:00) và lớp [${s2.id}] học tại ${s2.campus} (bắt đầu 12:30). Bạn chỉ có 1h30 phút để ăn trưa và di chuyển giữa hai cơ sở.',
                      relatedCourseCodes: [s1.courseCode, s2.courseCode],
                      relatedSectionIds: [s1.id, s2.id],
                    ),
                  );
                }
              }
            }
          }
        }
      }
    }

    return issues;
  }
}

