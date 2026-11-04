
/// Khung giờ tương ứng với từng tiết học tiêu chuẩn đại học
class PeriodTimeInfo {
  final int period;
  final String start;
  final String end;

  const PeriodTimeInfo({
    required this.period,
    required this.start,
    required this.end,
  });

  static const List<PeriodTimeInfo> standardPeriods = [
    PeriodTimeInfo(period: 1, start: '06:45', end: '07:30'),
    PeriodTimeInfo(period: 2, start: '07:35', end: '08:20'),
    PeriodTimeInfo(period: 3, start: '08:30', end: '09:15'),
    PeriodTimeInfo(period: 4, start: '09:25', end: '10:10'),
    PeriodTimeInfo(period: 5, start: '10:15', end: '11:00'),
    PeriodTimeInfo(period: 6, start: '12:30', end: '13:15'),
    PeriodTimeInfo(period: 7, start: '13:20', end: '14:05'),
    PeriodTimeInfo(period: 8, start: '14:15', end: '15:00'),
    PeriodTimeInfo(period: 9, start: '15:10', end: '15:55'),
    PeriodTimeInfo(period: 10, start: '16:00', end: '16:45'),
    PeriodTimeInfo(period: 11, start: '17:15', end: '18:00'),
    PeriodTimeInfo(period: 12, start: '18:05', end: '18:50'),
  ];

  static String getTimeRange(int startPeriod, int endPeriod) {
    if (startPeriod < 1 || startPeriod > 12 || endPeriod < 1 || endPeriod > 12) {
      return 'Tiết $startPeriod - $endPeriod';
    }
    final s = standardPeriods[startPeriod - 1].start;
    final e = standardPeriods[endPeriod - 1].end;
    return '$s - $e';
  }
}

/// Khung giờ học cho 1 buổi
class ScheduleSlot {
  final int dayOfWeek; // 2: Thứ 2 ... 8: Chủ Nhật
  final int startPeriod; // 1 -> 12
  final int endPeriod; // 1 -> 12
  final String room; // Ví dụ: "A1-302", "Lab 4.2"
  final String? building;

  const ScheduleSlot({
    required this.dayOfWeek,
    required this.startPeriod,
    required this.endPeriod,
    required this.room,
    this.building,
  });

  int get periodCount => endPeriod - startPeriod + 1;

  String get dayName {
    switch (dayOfWeek) {
      case 2:
        return 'Thứ 2';
      case 3:
        return 'Thứ 3';
      case 4:
        return 'Thứ 4';
      case 5:
        return 'Thứ 5';
      case 6:
        return 'Thứ 6';
      case 7:
        return 'Thứ 7';
      case 8:
        return 'Chủ Nhật';
      default:
        return 'Thứ $dayOfWeek';
    }
  }

  String get timeFormatted => PeriodTimeInfo.getTimeRange(startPeriod, endPeriod);

  /// Kiểm tra xem 2 slot có bị xung đột trùng thời gian không
  bool conflictsWith(ScheduleSlot other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    // Overlapping condition: start1 <= end2 AND start2 <= end1
    return startPeriod <= other.endPeriod && other.startPeriod <= endPeriod;
  }

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startPeriod': startPeriod,
        'endPeriod': endPeriod,
        'room': room,
        'building': building,
      };

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) => ScheduleSlot(
        dayOfWeek: json['dayOfWeek'] as int,
        startPeriod: json['startPeriod'] as int,
        endPeriod: json['endPeriod'] as int,
        room: json['room'] as String? ?? 'Chưa rõ',
        building: json['building'] as String?,
      );
}

/// Lớp học phần cụ thể
class ClassSection {
  final String id; // Ví dụ: "IT001.CLC.01"
  final String courseCode; // Ví dụ: "IT001"
  final String courseName;
  final String lecturer;
  final double lecturerRating; // Điểm đánh giá GV (1.0 -> 5.0)
  final List<ScheduleSlot> slots;
  final int capacity;
  final int enrolled;
  final String campus; // "Cơ sở chính", "Cơ sở 2"
  final int colorHex; // Màu hiển thị trên TKB

  int get availableSeats => capacity - enrolled;

  const ClassSection({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.lecturer,
    this.lecturerRating = 4.5,
    required this.slots,
    this.capacity = 50,
    this.enrolled = 35,
    this.campus = 'Cơ sở chính',
    this.colorHex = 0xFF3B82F6,
  });

  bool get isFull => enrolled >= capacity;
  int get remainingSlots => (capacity - enrolled).clamp(0, 999);

  /// Kiểm tra xung đột với 1 lớp học phần khác
  bool conflictsWith(ClassSection other) {
    if (id == other.id) return false;
    for (final s1 in slots) {
      for (final s2 in other.slots) {
        if (s1.conflictsWith(s2)) {
          return true;
        }
      }
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseCode': courseCode,
        'courseName': courseName,
        'lecturer': lecturer,
        'lecturerRating': lecturerRating,
        'slots': slots.map((s) => s.toJson()).toList(),
        'capacity': capacity,
        'enrolled': enrolled,
        'campus': campus,
        'colorHex': colorHex,
      };

  factory ClassSection.fromJson(Map<String, dynamic> json) => ClassSection(
        id: json['id'] as String,
        courseCode: json['courseCode'] as String,
        courseName: json['courseName'] as String,
        lecturer: json['lecturer'] as String? ?? 'Chưa phân công',
        lecturerRating: (json['lecturerRating'] as num?)?.toDouble() ?? 4.5,
        slots: (json['slots'] as List<dynamic>?)
                ?.map((e) => ScheduleSlot.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        capacity: json['capacity'] as int? ?? 50,
        enrolled: json['enrolled'] as int? ?? 0,
        campus: json['campus'] as String? ?? 'Cơ sở chính',
        colorHex: json['colorHex'] as int? ?? 0xFF3B82F6,
      );
}

enum CourseCategory {
  general('Đại cương'),
  foundation('Cơ sở ngành'),
  specializedMandatory('Chuyên ngành bắt buộc'),
  specializedElective('Chuyên ngành tự chọn');

  final String label;
  const CourseCategory(this.label);
}

/// Định nghĩa Môn học
class Course {
  final String code; // Mã môn: CS101, IT001...
  final String name; // Tên môn
  final int credits; // Tổng số tín chỉ
  final int theoryCredits; // Tín chỉ lý thuyết
  final int practiceCredits; // Tín chỉ thực hành / thí nghiệm
  final String department; // Khoa / Bộ môn
  final int recommendedSemester; // Học kỳ gợi ý (1 - 8)
  final CourseCategory category;
  final List<String> prerequisites; // Danh sách mã môn tiên quyết bắt buộc
  final List<String> corequisites; // Danh sách môn học song hành
  final String description;
  final List<ClassSection> sections;

  const Course({
    required this.code,
    required this.name,
    required this.credits,
    required this.theoryCredits,
    required this.practiceCredits,
    required this.department,
    required this.recommendedSemester,
    required this.category,
    this.prerequisites = const [],
    this.corequisites = const [],
    this.description = '',
    this.sections = const [],
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'credits': credits,
        'theoryCredits': theoryCredits,
        'practiceCredits': practiceCredits,
        'department': department,
        'recommendedSemester': recommendedSemester,
        'category': category.name,
        'prerequisites': prerequisites,
        'corequisites': corequisites,
        'description': description,
        'sections': sections.map((s) => s.toJson()).toList(),
      };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        code: json['code'] as String,
        name: json['name'] as String,
        credits: json['credits'] as int,
        theoryCredits: json['theoryCredits'] as int? ?? (json['credits'] as int),
        practiceCredits: json['practiceCredits'] as int? ?? 0,
        department: json['department'] as String? ?? 'CNTT',
        recommendedSemester: json['recommendedSemester'] as int? ?? 1,
        category: CourseCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => CourseCategory.general,
        ),
        prerequisites: List<String>.from(json['prerequisites'] ?? []),
        corequisites: List<String>.from(json['corequisites'] ?? []),
        description: json['description'] as String? ?? '',
        sections: (json['sections'] as List<dynamic>?)
                ?.map((s) => ClassSection.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
