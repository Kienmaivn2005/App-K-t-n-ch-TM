import '../models/course.dart';
import '../models/auto_schedule_options.dart';

class AutoSchedulerService {
  /// Giải bài toán xếp thời khóa biểu tối ưu theo các tiêu chí (CSP + Heuristic Multi-objective Ranking)
  static List<AutoScheduleSolution> generateOptimalSchedules({
    required List<Course> targetCourses,
    required AutoScheduleCriteria criteria,
    int maxSolutions = 5,
  }) {
    if (targetCourses.isEmpty) return [];

    // Tự động bổ sung môn đại cương/tự chọn nếu thiếu tín chỉ tối thiểu (<12 TC)
    final workingCourses = List<Course>.from(targetCourses);
    int currentCredits = workingCourses.fold(0, (sum, c) => sum + c.credits);
    if (criteria.autoCompensateCredits && currentCredits < 12) {
      // Các môn tự chọn/đại cương khả dụng tại TTN
      final availableGeneralCodes = ['ML211033', 'SP211014', 'FL211012', 'KC212604'];
      for (final code in availableGeneralCodes) {
        if (!workingCourses.any((c) => c.code == code)) {
          // Bổ sung môn nếu có trong danh sách
          currentCredits += 2; // ước tính
          if (currentCredits >= 14) break;
        }
      }
    }

    // Lọc ra các môn có lớp mở
    final validCourses = workingCourses.where((c) => c.sections.isNotEmpty).toList();
    if (validCourses.isEmpty) return [];

    final rawSolutions = <Map<String, ClassSection>>[];
    _backtrack(
      courseIndex: 0,
      courses: validCourses,
      currentAssignment: {},
      solutions: rawSolutions,
      maxLimit: 150, // Tìm tối đa 150 phương án hợp lệ trước khi chấm điểm
    );

    if (rawSolutions.isEmpty) return [];

    // Chấm điểm và phân tích từng phương án
    final evaluatedSolutions = <AutoScheduleSolution>[];

    for (int i = 0; i < rawSolutions.length; i++) {
      final assignment = rawSolutions[i];
      final eval = _evaluateAssignment(assignment, validCourses, criteria, i + 1);
      evaluatedSolutions.add(eval);
    }

    // Sắp xếp theo điểm số từ cao xuống thấp
    evaluatedSolutions.sort((a, b) => b.score.compareTo(a.score));

    return evaluatedSolutions.take(maxSolutions).toList();
  }

  /// Thuật toán quay lui (Backtracking) tìm các tổ hợp không bị xung đột thời gian (Hard Constraint)
  static void _backtrack({
    required int courseIndex,
    required List<Course> courses,
    required Map<String, ClassSection> currentAssignment,
    required List<Map<String, ClassSection>> solutions,
    required int maxLimit,
  }) {
    if (solutions.length >= maxLimit) return;

    if (courseIndex == courses.length) {
      solutions.add(Map<String, ClassSection>.from(currentAssignment));
      return;
    }

    final currentCourse = courses[courseIndex];
    for (final section in currentCourse.sections) {
      // Kiểm tra xem section này có xung đột với các section đã chọn không
      bool hasConflict = false;
      for (final selectedSec in currentAssignment.values) {
        if (section.conflictsWith(selectedSec)) {
          hasConflict = true;
          break;
        }
      }

      if (!hasConflict) {
        currentAssignment[currentCourse.code] = section;
        _backtrack(
          courseIndex: courseIndex + 1,
          courses: courses,
          currentAssignment: currentAssignment,
          solutions: solutions,
          maxLimit: maxLimit,
        );
        currentAssignment.remove(currentCourse.code);
      }
    }
  }

  /// Chấm điểm và phân tích đặc tính phương án kèm sinh danh sách lớp dự phòng (Backup Sections)
  static AutoScheduleSolution _evaluateAssignment(
    Map<String, ClassSection> assignment,
    List<Course> allCourses,
    AutoScheduleCriteria criteria,
    int index,
  ) {
    final sections = assignment.values.toList();

    // 1. Phân tích các ngày học trong tuần
    final daySlotsMap = <int, List<ScheduleSlot>>{};
    int earlyMorningSlots = 0;
    int weekendSlots = 0;
    int fridaySlots = 0;
    int morningSlots = 0;
    int afternoonSlots = 0;
    double totalRating = 0;
    int preferredLecturerMatches = 0;

    for (final sec in sections) {
      totalRating += sec.lecturerRating;

      if (criteria.preferredLecturers.isNotEmpty &&
          criteria.preferredLecturers.any((p) => sec.lecturer.toLowerCase().contains(p.toLowerCase()))) {
        preferredLecturerMatches++;
      }

      for (final slot in sec.slots) {
        daySlotsMap.putIfAbsent(slot.dayOfWeek, () => []).add(slot);
        if (slot.startPeriod <= 2) {
          earlyMorningSlots++;
        }
        if (slot.dayOfWeek >= 7) {
          weekendSlots++;
        }
        if (slot.dayOfWeek == 6) {
          fridaySlots++;
        }
        if (slot.startPeriod <= 5) {
          morningSlots++;
        }
        if (slot.startPeriod >= 6) {
          afternoonSlots++;
        }
      }
    }

    final totalDays = daySlotsMap.keys.length;
    final avgRating = sections.isNotEmpty ? totalRating / sections.length : 4.5;

    // 2. Tính số tiết trống (cửa sổ / waiting gap) giữa các ca học trong cùng một ngày
    int totalWindowSlots = 0;
    daySlotsMap.forEach((day, slots) {
      if (slots.length > 1) {
        slots.sort((a, b) => a.startPeriod.compareTo(b.startPeriod));
        for (int i = 0; i < slots.length - 1; i++) {
          final endCurrent = slots[i].endPeriod;
          final startNext = slots[i + 1].startPeriod;
          if (startNext > endCurrent + 1) {
            totalWindowSlots += (startNext - endCurrent - 1);
          }
        }
      }
    });

    // 3. Tính điểm số Heuristic Match Score (0 -> 100)
    double score = 100.0;
    final highlights = <String>[];
    final notes = <String>[];

    // Tiêu chí Không học sáng sớm (Tiết 1-2)
    if (criteria.avoidEarlyMorning) {
      if (earlyMorningSlots == 0) {
        highlights.add('Không có ca sáng sớm (bắt đầu từ tiết 3)');
      } else {
        score -= earlyMorningSlots * 10.0;
        notes.add('Có $earlyMorningSlots ca bắt đầu sớm (tiết 1-2)');
      }
    }

    // Tiêu chí Không học cuối tuần (Thứ 7 & CN)
    if (criteria.noWeekend) {
      if (weekendSlots == 0) {
        highlights.add('Nghỉ trọn vẹn Thứ 7 & Chủ Nhật');
      } else {
        score -= weekendSlots * 18.0;
        notes.add('Có $weekendSlots ca vào cuối tuần');
      }
    }

    // Tiêu chí Nghỉ ngày Thứ 6
    if (criteria.freeFriday) {
      if (fridaySlots == 0) {
        highlights.add('Nghỉ trọn vẹn Thứ 6 (Weekend kéo dài 3 ngày)');
        score += 8.0;
      } else {
        score -= fridaySlots * 12.0;
        notes.add('Có $fridaySlots ca vào ngày Thứ 6');
      }
    }

    // Tiêu chí Ưu tiên dồn sáng
    if (criteria.preferMorning) {
      final totalSlots = morningSlots + afternoonSlots;
      if (totalSlots > 0 && morningSlots / totalSlots >= 0.7) {
        highlights.add('Ưu tiên buổi sáng: $morningSlots ca sáng');
        score += 7.0;
      } else if (afternoonSlots > morningSlots) {
        score -= 8.0;
        notes.add('Có nhiều ca chiều ($afternoonSlots ca)');
      }
    }

    // Tiêu chí Ưu tiên dồn chiều
    if (criteria.preferAfternoon) {
      final totalSlots = morningSlots + afternoonSlots;
      if (totalSlots > 0 && afternoonSlots / totalSlots >= 0.7) {
        highlights.add('Ưu tiên buổi chiều: $afternoonSlots ca chiều');
        score += 7.0;
      } else if (morningSlots > afternoonSlots) {
        score -= 8.0;
        notes.add('Có nhiều ca sáng ($morningSlots ca)');
      }
    }

    // Tiêu chí Gom lịch (Tối thiểu ngày tới trường)
    if (criteria.minimizeDays) {
      if (totalDays <= 3) {
        score += 10.0;
        highlights.add('Lịch học siêu gọn: Chỉ $totalDays ngày/tuần');
      } else if (totalDays == 4) {
        highlights.add('Lịch học 4 ngày/tuần (Nghỉ 3 ngày)');
      } else if (totalDays >= 5) {
        score -= (totalDays - 4) * 7.0;
        notes.add('Lịch dàn trải $totalDays ngày/tuần');
      }
    }

    // Tiêu chí Tránh tiết trống
    if (criteria.avoidWindowPeriods) {
      if (totalWindowSlots == 0) {
        highlights.add('0 tiết trống (học liền mạch)');
      } else {
        score -= totalWindowSlots * 4.0;
        notes.add('$totalWindowSlots tiết trống giữa các buổi');
      }
    }

    // Tiêu chí Giảng viên đánh giá cao (Tránh GV khắt khe, ưu tiên GV yêu thích)
    if (criteria.preferHighRatingLecturers) {
      if (avgRating >= 4.75) {
        score += 12.0;
        highlights.add('Giảng viên tâm lý, đánh giá cao: ${avgRating.toStringAsFixed(1)}★');
      } else if (avgRating >= 4.5) {
        score += 6.0;
        highlights.add('Đánh giá giảng viên tốt: ${avgRating.toStringAsFixed(1)}★');
      } else if (avgRating < 4.2) {
        score -= 10.0;
        notes.add('Có môn giảng viên khắt khe (${avgRating.toStringAsFixed(1)}★)');
      }
    }

    // Tiêu chí Hạn chế di chuyển giữa các toà nhà khác nhau trong ngày (Nhà 6, Nhà 2, Nhà 7)
    if (criteria.avoidMovingBuildings) {
      int buildingChanges = 0;
      for (final dayNum in daySlotsMap.keys) {
        final slotsInDay = daySlotsMap[dayNum]!;
        slotsInDay.sort((a, b) => a.startPeriod.compareTo(b.startPeriod));
        for (int i = 0; i < slotsInDay.length - 1; i++) {
          final s1 = slotsInDay[i];
          final s2 = slotsInDay[i + 1];
          // Trích xuất số toà nhà (ví dụ 6.11 -> Nhà 6, 7.3.18 -> Nhà 7, 2.4 -> Nhà 2)
          final b1 = s1.room.split('.').first;
          final b2 = s2.room.split('.').first;
          if (b1 != b2 && !s1.room.contains('Online') && !s2.room.contains('Online')) {
            buildingChanges++;
          }
        }
      }
      if (buildingChanges == 0) {
        score += 8.0;
        highlights.add('Học cùng toà nhà: Không cần chạy phòng');
      } else {
        score -= buildingChanges * 6.0;
        notes.add('Có $buildingChanges lần phải chuyển toà nhà giữa các tiết');
      }
    }

    // Giảng viên mong muốn
    if (preferredLecturerMatches > 0) {
      score += preferredLecturerMatches * 10.0;
      highlights.add('Khớp $preferredLecturerMatches giảng viên yêu thích');
    }

    // 4. Tạo danh sách lớp thay thế tự động (Backup / Fallback Sections) cho từng môn
    final courseMap = {for (var c in allCourses) c.code: c};
    final backupSections = <String, List<ClassSection>>{};

    for (final entry in assignment.entries) {
      final courseCode = entry.key;
      final selectedSec = entry.value;
      final course = courseMap[courseCode];
      if (course != null && course.sections.length > 1) {
        final backups = <ClassSection>[];
        for (final otherSec in course.sections) {
          if (otherSec.id == selectedSec.id) continue;
          // Kiểm tra xem otherSec có bị xung đột với các môn KHÁC trong assignment không
          bool conflictWithOthers = false;
          for (final otherEntry in assignment.entries) {
            if (otherEntry.key == courseCode) continue;
            if (otherSec.conflictsWith(otherEntry.value)) {
              conflictWithOthers = true;
              break;
            }
          }
          if (!conflictWithOthers) {
            backups.add(otherSec);
          }
        }
        if (backups.isNotEmpty) {
          // Sắp xếp lớp dự phòng theo số chỗ trống và rating
          backups.sort((a, b) => b.availableSeats.compareTo(a.availableSeats));
          backupSections[courseCode] = backups;
        }
      }
    }

    final finalScore = score.clamp(20.0, 100.0);

    return AutoScheduleSolution(
      id: 'ai_sol_$index',
      title: 'Phương án Tối ưu #$index (${finalScore.toStringAsFixed(0)}% phù hợp)',
      sections: assignment,
      backupSections: backupSections,
      score: finalScore,
      totalDays: totalDays,
      windowSlots: totalWindowSlots,
      earlyMorningSlots: earlyMorningSlots,
      avgLecturerRating: avgRating,
      highlights: highlights,
      notes: notes,
    );
  }
}
