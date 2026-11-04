import '../../data/models/course_model.dart';
import '../../data/models/time_slot_model.dart';

/// Tiêu chí lọc và tối ưu hóa thời khóa biểu (Soft Constraints)
class ScheduleFilterCriteria {
  final bool preferMorning; // Ưu tiên học buổi sáng
  final bool preferAfternoon; // Ưu tiên học buổi chiều
  final bool freeFriday; // Tránh học Thứ 6 (nghỉ Thứ 6)
  final bool freeSaturday; // Tránh học Thứ 7 (nghỉ Thứ 7)
  final bool avoidPeriodOne; // Tránh tiết 1 (không học 7h sáng)
  final bool minimizeGaps; // Giảm thiểu giờ trống / thời gian chết
  final int maxPlans; // Số phương án tối đa trả về

  const ScheduleFilterCriteria({
    this.preferMorning = true,
    this.preferAfternoon = false,
    bool freeFriday = false,
    bool freeSaturday = true,
    bool avoidPeriodOne = false,
    this.minimizeGaps = true,
    this.maxPlans = 50,
    bool? avoidFriday,
    bool? avoidSaturday,
    bool? avoidPeriod1,
  })  : freeFriday = avoidFriday ?? freeFriday,
        freeSaturday = avoidSaturday ?? freeSaturday,
        avoidPeriodOne = avoidPeriod1 ?? avoidPeriodOne;

  bool get avoidFriday => freeFriday;
  bool get avoidSaturday => freeSaturday;
  bool get avoidPeriod1 => avoidPeriodOne;

  ScheduleFilterCriteria copyWith({
    bool? preferMorning,
    bool? preferAfternoon,
    bool? freeFriday,
    bool? freeSaturday,
    bool? avoidPeriodOne,
    bool? minimizeGaps,
    int? maxPlans,
  }) {
    return ScheduleFilterCriteria(
      preferMorning: preferMorning ?? this.preferMorning,
      preferAfternoon: preferAfternoon ?? this.preferAfternoon,
      freeFriday: freeFriday ?? this.freeFriday,
      freeSaturday: freeSaturday ?? this.freeSaturday,
      avoidPeriodOne: avoidPeriodOne ?? this.avoidPeriodOne,
      minimizeGaps: minimizeGaps ?? this.minimizeGaps,
      maxPlans: maxPlans ?? this.maxPlans,
    );
  }

  Map<String, dynamic> toJson() => {
        'preferMorning': preferMorning,
        'preferAfternoon': preferAfternoon,
        'freeFriday': freeFriday,
        'freeSaturday': freeSaturday,
        'avoidPeriodOne': avoidPeriodOne,
        'minimizeGaps': minimizeGaps,
        'maxPlans': maxPlans,
      };

  factory ScheduleFilterCriteria.fromJson(Map<String, dynamic> json) =>
      ScheduleFilterCriteria(
        preferMorning: json['preferMorning'] as bool? ?? true,
        preferAfternoon: json['preferAfternoon'] as bool? ?? false,
        freeFriday: json['freeFriday'] as bool? ?? false,
        freeSaturday: json['freeSaturday'] as bool? ?? true,
        avoidPeriodOne: json['avoidPeriodOne'] as bool? ?? false,
        minimizeGaps: json['minimizeGaps'] as bool? ?? true,
        maxPlans: json['maxPlans'] as int? ?? 50,
      );
}

/// Bộ đánh giá và chấm điểm phương án thời khóa biểu (Schedule Evaluator)
class ScheduleEvaluator {
  /// Đánh giá và trả về SchedulePlan mới có điểm số (score) và các nhãn (tags)
  static SchedulePlan evaluatePlan(
    SchedulePlan plan,
    ScheduleFilterCriteria criteria,
  ) {
    double score = 100.0;
    final List<String> tags = [];
    final allSlots = plan.getAllSlots();

    if (allSlots.isEmpty) {
      return plan.copyWith(score: 0, tags: ['Trống']);
    }

    // 1. Đánh giá ca học: Sáng / Chiều
    int morningSlots = 0;
    int afternoonSlots = 0;
    for (final s in allSlots) {
      if (s.isMorning) {
        morningSlots++;
      } else {
        afternoonSlots++;
      }
    }

    if (criteria.preferMorning) {
      score += morningSlots * 12.0;
      score -= afternoonSlots * 6.0;
      if (afternoonSlots == 0) {
        score += 30.0;
        tags.add('100% Học Sáng');
      } else if (morningSlots > afternoonSlots) {
        tags.add('Ưu tiên sáng');
      }
    } else if (criteria.preferAfternoon) {
      score += afternoonSlots * 12.0;
      score -= morningSlots * 6.0;
      if (morningSlots == 0) {
        score += 30.0;
        tags.add('100% Học Chiều');
      } else if (afternoonSlots > morningSlots) {
        tags.add('Ưu tiên chiều');
      }
    }

    // 2. Đánh giá ngày nghỉ (Thứ 6, Thứ 7, Chủ Nhật)
    final daysWithClasses = allSlots.map((s) => s.dayOfWeek).toSet();

    final hasFriday = daysWithClasses.contains(6);
    if (criteria.freeFriday) {
      if (!hasFriday) {
        score += 45.0;
        tags.add('Nghỉ Thứ 6');
      } else {
        score -= 35.0;
      }
    } else if (!hasFriday) {
      tags.add('Nghỉ Thứ 6');
    }

    final hasSaturday = daysWithClasses.contains(7);
    if (criteria.freeSaturday) {
      if (!hasSaturday) {
        score += 45.0;
        tags.add('Nghỉ Thứ 7');
      } else {
        score -= 35.0;
      }
    } else if (!hasSaturday) {
      tags.add('Nghỉ Thứ 7');
    }

    // Nếu nghỉ cả Thứ 6 & Thứ 7
    if (!hasFriday && !hasSaturday) {
      score += 25.0;
    }

    // 3. Tránh tiết 1 (Tránh học 7:00 sáng)
    final hasPeriodOne = allSlots.any((s) => s.startPeriod == 1);
    if (criteria.avoidPeriodOne) {
      if (!hasPeriodOne) {
        score += 30.0;
        tags.add('Không học tiết 1');
      } else {
        score -= 25.0;
      }
    }

    // 4. Giảm thiểu thời gian chết (tiết trống giữa các môn trong cùng ngày)
    if (criteria.minimizeGaps) {
      int totalGapPeriods = 0;
      // Nhóm slot theo ngày
      final Map<int, List<TimeSlot>> daySlots = {};
      for (final s in allSlots) {
        daySlots.putIfAbsent(s.dayOfWeek, () => []).add(s);
      }

      for (final slotsInDay in daySlots.values) {
        slotsInDay.sort((a, b) => a.startPeriod.compareTo(b.startPeriod));
        for (int i = 0; i < slotsInDay.length - 1; i++) {
          final currentEnd = slotsInDay[i].endPeriod;
          final nextStart = slotsInDay[i + 1].startPeriod;
          if (nextStart > currentEnd + 1) {
            final gap = nextStart - currentEnd - 1;
            totalGapPeriods += gap;
          }
        }
      }

      if (totalGapPeriods == 0) {
        score += 40.0;
        tags.add('0 giờ trống');
      } else {
        score -= totalGapPeriods * 8.0;
      }
    }

    // Chuẩn hóa điểm số >= 10.0
    final finalScore = score.clamp(10.0, 999.0);

    return plan.copyWith(
      score: double.parse(finalScore.toStringAsFixed(1)),
      tags: tags,
    );
  }
}
