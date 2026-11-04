import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/timetable_models.dart';

/// ============================================================================
/// TTN SCHEDULE GENERATOR USE CASE (BITMASK CSP & ISOLATE WORKER)
/// Feature-First Clean Architecture: lib/domain/usecases/schedule_generator_usecase.dart
/// Áp dụng thuật toán Backtracking với Bitmasking để cắt tỉa nhánh cực nhanh
/// ============================================================================

class ScheduleConstraints {
  final int minCredits;
  final int maxCredits;
  final bool avoidMorning; // Tránh dính tiết 1 (07:00)
  final bool groupClasses; // Dồn lịch, giảm khoảng trống
  final bool freeSaturday; // Ưu tiên nghỉ Thứ 7
  final bool freeMonday; // Ưu tiên nghỉ Thứ 2
  final bool freeFriday; // Ưu tiên nghỉ Thứ 6

  const ScheduleConstraints({
    this.minCredits = 14,
    this.maxCredits = 24,
    this.avoidMorning = true,
    this.groupClasses = true,
    this.freeSaturday = true,
    this.freeMonday = false,
    this.freeFriday = true,
  });

  Map<String, dynamic> toJson() => {
    'minCredits': minCredits,
    'maxCredits': maxCredits,
    'avoidMorning': avoidMorning,
    'groupClasses': groupClasses,
    'freeSaturday': freeSaturday,
    'freeMonday': freeMonday,
    'freeFriday': freeFriday,
  };

  factory ScheduleConstraints.fromJson(Map<String, dynamic> json) => ScheduleConstraints(
    minCredits: json['minCredits'] as int? ?? 14,
    maxCredits: json['maxCredits'] as int? ?? 24,
    avoidMorning: json['avoidMorning'] as bool? ?? true,
    groupClasses: json['groupClasses'] as bool? ?? true,
    freeSaturday: json['freeSaturday'] as bool? ?? true,
    freeMonday: json['freeMonday'] as bool? ?? false,
    freeFriday: json['freeFriday'] as bool? ?? true,
  );
}

class GeneratorInputPayload {
  final List<Course> targetCourses;
  final ScheduleConstraints constraints;
  final int maxSolutions;

  GeneratorInputPayload({
    required this.targetCourses,
    required this.constraints,
    this.maxSolutions = 5,
  });
}

class ScheduleGeneratorUseCase {
  /// Entry point chạy trong Isolate thông qua compute()
  static Future<List<ScheduleOption>> executeAsync({
    required List<Course> targetCourses,
    required ScheduleConstraints constraints,
    int maxSolutions = 5,
  }) async {
    final payload = GeneratorInputPayload(
      targetCourses: targetCourses,
      constraints: constraints,
      maxSolutions: maxSolutions,
    );
    return await compute(_workerEntryPoint, payload);
  }

  static List<ScheduleOption> _workerEntryPoint(GeneratorInputPayload payload) {
    return _solveWithBitmaskBacktracking(
      courses: payload.targetCourses,
      constraints: payload.constraints,
      maxSolutions: payload.maxSolutions,
    );
  }

  /// THUẬT TOÁN CSP BACKTRACKING VỚI BITMASKING TỐC ĐỘ CAO:
  static List<ScheduleOption> _solveWithBitmaskBacktracking({
    required List<Course> courses,
    required ScheduleConstraints constraints,
    int maxSolutions = 5,
  }) {
    if (courses.isEmpty) return [];

    // 1. Nhóm theo cặp hợp lệ: 1 LT đi kèm 1 TH (nếu môn có thực hành)
    final List<List<List<ClassSection>>> courseBundles = [];

    for (final course in courses) {
      final bundles = <List<ClassSection>>[];
      final theoryList = course.theorySections;
      final practiceList = course.practiceSections;

      if (practiceList.isEmpty) {
        // Môn thuần lý thuyết
        for (final lt in theoryList) {
          bundles.add([lt]);
        }
      } else {
        // Môn bắt buộc 1 LT + 1 TH
        for (final lt in theoryList) {
          for (final th in practiceList) {
            // Ràng buộc nhóm cha nếu có
            if (th.parentTheoryClassId != null &&
                th.parentTheoryClassId != lt.classId) {
              continue;
            }
            // Kiểm tra LT và TH có tự trùng giờ không bằng Bitmask
            if (!_hasOverlap(lt.weeklyBitmask, th.weeklyBitmask)) {
              bundles.add([lt, th]);
            }
          }
        }
      }

      if (bundles.isEmpty) return []; // Không thể xếp môn này
      courseBundles.add(bundles);
    }

    // 2. Backtracking với mảng Bitmask 7 ngày để cắt tỉa cực nhanh
    final validSolutions = <List<ClassSection>>[];
    final currentSections = <ClassSection>[];
    // currentBitmask[dayIdx] lưu bitmask các tiết đã học của ngày đó
    final currentBitmask = List<int>.filled(7, 0);

    void backtrack(int courseIdx) {
      if (validSolutions.length >= 100) return; // Giới hạn 100 ứng viên để xếp hạng

      if (courseIdx == courseBundles.length) {
        validSolutions.add(List.from(currentSections));
        return;
      }

      final bundles = courseBundles[courseIdx];

      for (final bundle in bundles) {
        // Tính tổng bitmask của bundle này
        final bundleMask = List<int>.filled(7, 0);
        for (final sec in bundle) {
          final sMask = sec.weeklyBitmask;
          for (int d = 0; d < 7; d++) {
            bundleMask[d] |= sMask[d];
          }
        }

        // CẮT TỈA NHÁNH (BITMASK PRUNING): Kiểm tra phép AND bit
        bool conflict = false;
        for (int d = 0; d < 7; d++) {
          if ((currentBitmask[d] & bundleMask[d]) != 0) {
            conflict = true;
            break; // Trùng tiết, bỏ qua nhánh này ngay lập tức!
          }
        }

        if (!conflict) {
          // Ghi nhận trạng thái
          for (int d = 0; d < 7; d++) {
            currentBitmask[d] |= bundleMask[d];
          }
          currentSections.addAll(bundle);

          // Đệ quy
          backtrack(courseIdx + 1);

          // Quay lui (Backtrack)
          for (int d = 0; d < 7; d++) {
            currentBitmask[d] &= ~bundleMask[d];
          }
          currentSections.removeRange(
            currentSections.length - bundle.length,
            currentSections.length,
          );
        }
      }
    }

    backtrack(0);

    if (validSolutions.isEmpty) return [];

    // 3. Đánh giá chấm điểm (Fitness Scoring)
    final options = <ScheduleOption>[];
    for (int i = 0; i < validSolutions.length; i++) {
      options.add(_evaluateFitness(
        sections: validSolutions[i],
        courses: courses,
        constraints: constraints,
        index: i + 1,
      ));
    }

    options.sort((a, b) => b.fitnessScore.compareTo(a.fitnessScore));
    return options.take(maxSolutions).toList();
  }

  static bool _hasOverlap(List<int> m1, List<int> m2) {
    for (int i = 0; i < 7; i++) {
      if ((m1[i] & m2[i]) != 0) return true;
    }
    return false;
  }

  /// HÀM CHẤM ĐIỂM (FITNESS FUNCTION):
  static ScheduleOption _evaluateFitness({
    required List<ClassSection> sections,
    required List<Course> courses,
    required ScheduleConstraints constraints,
    required int index,
  }) {
    final allSlots = <TimeSlot>[];
    for (final s in sections) {
      allSlots.addAll(s.timeSlots);
    }

    final Map<int, List<TimeSlot>> daysMap = {};
    for (final slot in allSlots) {
      daysMap.putIfAbsent(slot.dayOfWeek, () => []).add(slot);
    }

    int earlyMorningCount = 0;
    int totalGaps = 0;
    final studyDays = daysMap.keys.length;

    daysMap.forEach((_, slots) {
      slots.sort((a, b) => a.startPeriod.compareTo(b.startPeriod));
      if (slots.any((s) => s.startPeriod == 1)) {
        earlyMorningCount++;
      }
      for (int i = 0; i < slots.length - 1; i++) {
        final gap = slots[i + 1].startPeriod - slots[i].endPeriod - 1;
        if (gap > 0) totalGaps += gap;
      }
    });

    final freeDays = <String>[];
    final dayLabels = {2: 'Thứ 2', 3: 'Thứ 3', 4: 'Thứ 4', 5: 'Thứ 5', 6: 'Thứ 6', 7: 'Thứ 7'};
    dayLabels.forEach((d, name) {
      if (!daysMap.containsKey(d)) freeDays.add(name);
    });

    double score = 80.0;
    final highlights = <String>[];

    // Tránh tiết 1
    if (constraints.avoidMorning) {
      if (earlyMorningCount == 0) {
        score += 10.0;
        highlights.add('Không học Tiết 1 sáng sớm (07:00)');
      } else {
        score -= (earlyMorningCount * 4.0);
      }
    }

    // Dồn lịch, tránh tiết trống
    if (constraints.groupClasses) {
      if (totalGaps == 0) {
        score += 8.0;
        highlights.add('Lịch học liền mạch, 0 tiết trống');
      } else {
        score -= min(14.0, totalGaps * 2.0);
      }
    }

    // Nghỉ Thứ 7
    if (constraints.freeSaturday && !daysMap.containsKey(7)) {
      score += 6.0;
      highlights.add('Nghỉ trọn vẹn Thứ 7');
    }

    // Nghỉ Thứ 6
    if (constraints.freeFriday && !daysMap.containsKey(6)) {
      score += 6.0;
      highlights.add('Nghỉ Thứ 6 (Cuối tuần dài)');
    }

    // Gom ngày học
    if (studyDays <= 4) {
      score += 5.0;
      highlights.add('Chỉ đi học $studyDays ngày/tuần');
    }

    int totalCredits = 0;
    final seen = <String>{};
    for (final sec in sections) {
      if (!seen.contains(sec.courseCode)) {
        final c = courses.firstWhere((e) => e.courseCode == sec.courseCode);
        totalCredits += c.credits;
        seen.add(sec.courseCode);
      }
    }

    final finalScore = score.clamp(10.0, 100.0);

    return ScheduleOption(
      id: 'plan_opt_$index',
      title: 'Plan ${String.fromCharCode(64 + index)} (${finalScore.toStringAsFixed(1)} điểm)',
      selectedSections: sections,
      totalCredits: totalCredits,
      fitnessScore: finalScore,
      totalStudyDays: studyDays,
      totalGapPeriods: totalGaps,
      earlyMorningCount: earlyMorningCount,
      freeDays: freeDays,
      highlights: highlights,
    );
  }
}
