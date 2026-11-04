import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../data/models/course_model.dart';
import '../../data/models/course_section_model.dart';
import 'schedule_evaluator.dart';

/// Tham số truyền vào Background Isolate để giải CSP
class _SolveParams {
  final List<Course> courses;
  final ScheduleFilterCriteria criteria;

  const _SolveParams({
    required this.courses,
    required this.criteria,
  });
}

/// Thuật toán giải bài toán xếp lịch tín chỉ (Constraint Satisfaction Problem - CSP)
/// Sử dụng Backtracking kết hợp Forward Checking và thực thi trên Dart Background Isolate
class ScheduleSolver {
  /// Giải thuật toán bất đồng bộ trên Isolate đa luồng (tránh giật lag UI)
  static Future<List<SchedulePlan>> solveAsync({
    required List<Course> selectedCourses,
    ScheduleFilterCriteria criteria = const ScheduleFilterCriteria(),
  }) async {
    if (selectedCourses.isEmpty) return [];

    // Lọc bỏ các môn không có lớp mở
    final validCourses = selectedCourses.where((c) => c.sections.isNotEmpty).toList();
    if (validCourses.isEmpty) return [];

    // Chạy trên Isolate nền
    return compute(
      _solveCspInternal,
      _SolveParams(courses: validCourses, criteria: criteria),
    );
  }

  /// Phương thức đồng bộ (hữu ích cho unit test & kiểm thử trực tiếp)
  static List<SchedulePlan> solveSync({
    required List<Course> selectedCourses,
    ScheduleFilterCriteria criteria = const ScheduleFilterCriteria(),
  }) {
    if (selectedCourses.isEmpty) return [];
    final validCourses = selectedCourses.where((c) => c.sections.isNotEmpty).toList();
    if (validCourses.isEmpty) return [];

    return _solveCspInternal(_SolveParams(courses: validCourses, criteria: criteria));
  }
}

/// Hàm cấp cao (top-level) thực thi bên trong Background Isolate
List<SchedulePlan> _solveCspInternal(_SolveParams params) {
  final courses = params.courses;
  final criteria = params.criteria;
  final List<SchedulePlan> validPlans = [];

  // Sắp xếp môn học theo MRV (Minimum Remaining Values heuristic):
  // Môn có ít lớp học phần hơn được duyệt trước để tỉa nhánh sớm nhất
  courses.sort((a, b) => a.sections.length.compareTo(b.sections.length));

  // Tập miền giá trị ban đầu cho từng môn
  final List<List<CourseSection>> domains =
      courses.map((c) => List<CourseSection>.from(c.sections)).toList();

  final List<CourseSection> currentAssignment = [];

  void backtrack(int courseIndex) {
    if (courseIndex == courses.length) {
      // Đã tìm thấy 1 phương án hợp lệ thỏa mãn 100% ràng buộc cứng
      final totalCredits = courses.fold(0, (sum, c) => sum + c.credits);
      final rawPlan = SchedulePlan(
        id: 'plan_${validPlans.length + 1}_${Random().nextInt(9999)}',
        selectedSections: List<CourseSection>.from(currentAssignment),
        totalCredits: totalCredits,
      );

      // Chấm điểm theo ràng buộc mềm (Soft constraints)
      final evaluatedPlan = ScheduleEvaluator.evaluatePlan(rawPlan, criteria);
      validPlans.add(evaluatedPlan);
      return;
    }

    // Giới hạn số lượng tìm kiếm để tối ưu hiệu năng (tối đa 500 lời giải hợp lệ để chọn ra top N)
    if (validPlans.length >= 500) return;

    final currentDomain = domains[courseIndex];

    for (final section in currentDomain) {
      // 1. Kiểm tra ràng buộc cứng: Có trùng tiết với bất kỳ môn nào đã chọn?
      bool hasConflict = false;
      for (final assigned in currentAssignment) {
        if (assigned.conflictsWith(section)) {
          hasConflict = true;
          break;
        }
      }

      if (hasConflict) continue;

      // 2. Forward Checking: Kiểm tra xem các môn còn lại có bị rỗng miền giá trị không
      bool forwardCheckPassed = true;
      final List<List<CourseSection>> savedFutureDomains = [];

      for (int futureIdx = courseIndex + 1; futureIdx < courses.length; futureIdx++) {
        final futureDomain = domains[futureIdx];
        final filteredDomain = futureDomain.where((fSec) => !fSec.conflictsWith(section)).toList();

        if (filteredDomain.isEmpty) {
          // Bế tắc (Deadlock): Gán lớp này sẽ khiến môn tương lai không còn lớp nào học được
          forwardCheckPassed = false;
          break;
        }
        savedFutureDomains.add(filteredDomain);
      }

      if (!forwardCheckPassed) {
        // Tỉa nhánh (Pruning)
        continue;
      }

      // 3. Tiến hành gán và cập nhật miền giá trị
      currentAssignment.add(section);
      final List<List<CourseSection>> originalDomains = [];
      for (int i = courseIndex + 1; i < courses.length; i++) {
        originalDomains.add(domains[i]);
        domains[i] = savedFutureDomains[i - (courseIndex + 1)];
      }

      // Đệ quy sang môn tiếp theo
      backtrack(courseIndex + 1);

      // Hoàn tác (Backtrack / Undo)
      currentAssignment.removeLast();
      for (int i = courseIndex + 1; i < courses.length; i++) {
        domains[i] = originalDomains[i - (courseIndex + 1)];
      }
    }
  }

  // Khởi động Backtracking
  backtrack(0);

  // Sắp xếp các phương án theo điểm số giảm dần (từ phương án tốt nhất xuống)
  validPlans.sort((a, b) => b.score.compareTo(a.score));

  // Trả về tối đa Top N phương án theo cấu hình criteria
  final topPlans = validPlans.take(criteria.maxPlans).toList();

  // Đánh lại ID có thứ tự từ 1 đến N
  return List.generate(topPlans.length, (i) {
    return topPlans[i].copyWith(id: 'plan_${i + 1}');
  });
}

