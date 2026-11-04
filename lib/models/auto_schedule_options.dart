import 'course.dart';

class AutoScheduleCriteria {
  bool avoidEarlyMorning; // Tránh tiết 1 - 2
  bool noWeekend; // Nghỉ Thứ 7 và Chủ Nhật
  bool freeFriday; // Nghỉ ngày Thứ 6
  bool preferMorning; // Ưu tiên dồn lịch vào buổi sáng
  bool preferAfternoon; // Ưu tiên dồn lịch vào buổi chiều
  bool minimizeDays; // Gom lịch, giảm số ngày tới trường
  bool avoidWindowPeriods; // Tránh tiết trống giữa ngày (minimize gaps)
  bool preferHighRatingLecturers; // Ưu tiên giảng viên đánh giá cao (tránh GV khắt khe)
  bool avoidMovingBuildings; // Hạn chế di chuyển giữa các toà nhà khác nhau trong ngày (Nhà 6 -> Nhà 7)
  bool autoCompensateCredits; // Tự động chọn bù môn đại cương/tự chọn nếu thiếu tín chỉ tối thiểu (<12 TC)
  List<String> preferredLecturers; // Giảng viên ưu tiên mong muốn
  List<String> targetCourseCodes; // Danh sách mã môn muốn xếp lịch
  int maxCredits; // Hạn mức tín chỉ tối đa

  AutoScheduleCriteria({
    this.avoidEarlyMorning = true,
    this.noWeekend = true,
    this.freeFriday = false,
    this.preferMorning = false,
    this.preferAfternoon = false,
    this.minimizeDays = true,
    this.avoidWindowPeriods = true,
    this.preferHighRatingLecturers = true,
    this.avoidMovingBuildings = true,
    this.autoCompensateCredits = true,
    List<String>? preferredLecturers,
    List<String>? targetCourseCodes,
    this.maxCredits = 24,
  })  : preferredLecturers = preferredLecturers ?? [],
        targetCourseCodes = targetCourseCodes ?? [];

  AutoScheduleCriteria copyWith({
    bool? avoidEarlyMorning,
    bool? noWeekend,
    bool? freeFriday,
    bool? preferMorning,
    bool? preferAfternoon,
    bool? minimizeDays,
    bool? avoidWindowPeriods,
    bool? preferHighRatingLecturers,
    bool? avoidMovingBuildings,
    bool? autoCompensateCredits,
    List<String>? preferredLecturers,
    List<String>? targetCourseCodes,
    int? maxCredits,
  }) {
    return AutoScheduleCriteria(
      avoidEarlyMorning: avoidEarlyMorning ?? this.avoidEarlyMorning,
      noWeekend: noWeekend ?? this.noWeekend,
      freeFriday: freeFriday ?? this.freeFriday,
      preferMorning: preferMorning ?? this.preferMorning,
      preferAfternoon: preferAfternoon ?? this.preferAfternoon,
      minimizeDays: minimizeDays ?? this.minimizeDays,
      avoidWindowPeriods: avoidWindowPeriods ?? this.avoidWindowPeriods,
      preferHighRatingLecturers:
          preferHighRatingLecturers ?? this.preferHighRatingLecturers,
      avoidMovingBuildings: avoidMovingBuildings ?? this.avoidMovingBuildings,
      autoCompensateCredits: autoCompensateCredits ?? this.autoCompensateCredits,
      preferredLecturers: preferredLecturers != null
          ? List.from(preferredLecturers)
          : List.from(this.preferredLecturers),
      targetCourseCodes: targetCourseCodes != null
          ? List.from(targetCourseCodes)
          : List.from(this.targetCourseCodes),
      maxCredits: maxCredits ?? this.maxCredits,
    );
  }
}

class AutoScheduleSolution {
  final String id;
  final String title;
  final Map<String, ClassSection> sections; // courseCode -> ClassSection
  final Map<String, List<ClassSection>> backupSections; // courseCode -> Danh sách lớp dự phòng
  final double score; // 0 -> 100%
  final int totalDays;
  final int windowSlots; // Tổng số tiết trống
  final int earlyMorningSlots; // Số tiết 1-2
  final double avgLecturerRating;
  final List<String> highlights;
  final List<String> notes;

  AutoScheduleSolution({
    required this.id,
    required this.title,
    required this.sections,
    this.backupSections = const {},
    required this.score,
    required this.totalDays,
    required this.windowSlots,
    required this.earlyMorningSlots,
    required this.avgLecturerRating,
    required this.highlights,
    required this.notes,
  });
}
