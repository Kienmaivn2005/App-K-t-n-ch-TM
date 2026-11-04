/// TTN SMART CREDIT PLANNER - DOMAIN MODELS
/// Feature-First Clean Architecture: lib/domain/models/timetable_models.dart
/// Đặc tả dữ liệu chuẩn Trường Đại học Tây Nguyên (TTN)
library;

/// 1. TimeSlot: Đại diện cho một buổi học cụ thể trong tuần
class TimeSlot {
  /// Thứ trong tuần: 2 (Thứ Hai) -> 7 (Thứ Bảy), 8 (Chủ Nhật)
  final int dayOfWeek;

  /// Tiết bắt đầu: 1 -> 10 (hoặc 12)
  /// Ca Sáng: Tiết 1 - 5 (07:00 - 11:30)
  /// Ca Chiều: Tiết 6 - 10 (13:00 - 17:30)
  final int startPeriod;

  /// Số tiết diễn ra liên tục (thường từ 2 đến 4 tiết)
  final int periodCount;

  /// Phòng học / Giảng đường (ví dụ: "G2-P102", "Lab 4.2", "G3-201")
  final String room;

  /// Giảng viên phụ trách
  final String lecturer;

  const TimeSlot({
    required this.dayOfWeek,
    required this.startPeriod,
    required this.periodCount,
    this.room = 'Chưa xếp phòng',
    this.lecturer = 'Chưa phân công',
  }) : assert(startPeriod >= 1 && startPeriod <= 12, 'Tiết bắt đầu phải từ 1 đến 12'),
       assert(periodCount >= 1 && periodCount <= 6, 'Số tiết phải từ 1 đến 6');

  /// Tiết kết thúc của ca học
  int get endPeriod => startPeriod + periodCount - 1;

  /// Kiểm tra có thuộc ca sáng không (Tiết 1 -> 5)
  bool get isMorning => startPeriod <= 5;

  /// Kiểm tra có thuộc ca chiều không (Tiết 6 -> 10)
  bool get isAfternoon => startPeriod >= 6 && startPeriod <= 10;

  /// Kiểm tra có dính tiết 1 buổi sáng (07:00) hay không
  bool get isEarlyMorning => dayOfWeek <= 7 && startPeriod == 1;

  /// Tên thứ hiển thị dạng chuỗi
  String get dayLabel {
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
      case 1:
        return 'Chủ Nhật';
      default:
        return 'Thứ $dayOfWeek';
    }
  }

  /// Khung giờ chuẩn tương ứng tại ĐH Tây Nguyên
  String get timeRangeString {
    final Map<int, String> startMap = {
      1: '07:00', 2: '07:50', 3: '08:50', 4: '09:40', 5: '10:30',
      6: '13:00', 7: '13:50', 8: '14:50', 9: '15:40', 10: '16:30',
      11: '17:30', 12: '18:20',
    };
    final Map<int, String> endMap = {
      1: '07:45', 2: '08:35', 3: '09:35', 4: '10:25', 5: '11:15',
      6: '13:45', 7: '14:35', 8: '15:35', 9: '16:25', 10: '17:15',
      11: '18:15', 12: '19:05',
    };

    final s = startMap[startPeriod] ?? 'Tiết $startPeriod';
    final e = endMap[endPeriod] ?? 'Tiết $endPeriod';
    return '$s - $e';
  }

  /// BIỂU DIỄN BITMASK (16 bits): Tiết 1 tương ứng bit 0, Tiết 10 bit 9...
  /// Phục vụ cắt tỉa nhánh cực nhanh trong Backtracking
  int get bitmask {
    int mask = 0;
    for (int p = startPeriod; p <= endPeriod; p++) {
      mask |= (1 << (p - 1));
    }
    return mask;
  }

  /// KIỂM TRA TRÙNG LỊCH (HARD CONSTRAINT):
  /// Cùng ngày và giao nhau về khoảng tiết học
  bool overlapsWith(TimeSlot other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    return startPeriod <= other.endPeriod && other.startPeriod <= endPeriod;
  }

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'startPeriod': startPeriod,
    'periodCount': periodCount,
    'room': room,
    'lecturer': lecturer,
  };

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
    dayOfWeek: json['dayOfWeek'] as int,
    startPeriod: json['startPeriod'] as int,
    periodCount: json['periodCount'] as int,
    room: json['room'] as String? ?? 'Chưa xếp phòng',
    lecturer: json['lecturer'] as String? ?? 'Chưa phân công',
  );

  @override
  String toString() => '$dayLabel: Tiết $startPeriod-$endPeriod ($room)';
}

/// 2. ClassSection: Lớp học phần mở trong kỳ (Lý thuyết hoặc Thực hành)
enum SectionType {
  theory,    // Lớp Lý Thuyết (LT)
  practice,  // Tổ Thực Hành / Thảo Luận (TH)
}

class ClassSection {
  /// Mã lớp học phần (ví dụ: "4110034_01", "7010212_02")
  final String classId;

  /// Tên lớp hiển thị (ví dụ: "Nhóm 01", "Tổ 02 TH")
  final String sectionName;

  /// Mã học phần mẹ (ví dụ: "4110034")
  final String courseCode;

  /// Tên môn học
  final String courseName;

  /// Phân loại LT hay TH
  final SectionType sectionType;

  /// Mã nhóm lý thuyết cha (đối với lớp TH đi kèm theo quy định đào tạo)
  final String? parentTheoryClassId;

  /// Danh sách các buổi học của lớp này
  final List<TimeSlot> timeSlots;

  /// Sức chứa tối đa của lớp
  final int capacity;

  /// Số lượng sinh viên đã đăng ký hiện tại
  final int enrolledCount;

  /// Mã màu đại diện hiển thị trên Grid
  final int colorHex;

  const ClassSection({
    required this.classId,
    required this.sectionName,
    required this.courseCode,
    required this.courseName,
    required this.sectionType,
    this.parentTheoryClassId,
    required this.timeSlots,
    this.capacity = 50,
    this.enrolledCount = 0,
    this.colorHex = 0xFF1E88E5,
  });

  bool get isPractice => sectionType == SectionType.practice;
  bool get isTheory => sectionType == SectionType.theory;
  int get remainingSlots => (capacity - enrolledCount).clamp(0, 9999);
  bool get isFull => enrolledCount >= capacity;

  /// Chuyển toàn bộ lịch học của lớp thành mảng Bitmask theo 7 ngày trong tuần
  /// Index 0: Thứ 2, ..., Index 5: Thứ 7, Index 6: CN
  List<int> get weeklyBitmask {
    final mask = List<int>.filled(7, 0);
    for (final slot in timeSlots) {
      final dayIdx = (slot.dayOfWeek >= 2 && slot.dayOfWeek <= 8)
          ? (slot.dayOfWeek - 2)
          : 0;
      if (dayIdx >= 0 && dayIdx < 7) {
        mask[dayIdx] |= slot.bitmask;
      }
    }
    return mask;
  }

  /// Kiểm tra xem lớp này có xung đột thời gian với một lớp khác không
  bool overlapsWith(ClassSection other) {
    if (classId == other.classId) return false;
    final m1 = weeklyBitmask;
    final m2 = other.weeklyBitmask;
    for (int i = 0; i < 7; i++) {
      if ((m1[i] & m2[i]) != 0) {
        return true; // Trùng ít nhất 1 tiết trong ngày i
      }
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
    'classId': classId,
    'sectionName': sectionName,
    'courseCode': courseCode,
    'courseName': courseName,
    'sectionType': sectionType.name,
    'parentTheoryClassId': parentTheoryClassId,
    'timeSlots': timeSlots.map((s) => s.toJson()).toList(),
    'capacity': capacity,
    'enrolledCount': enrolledCount,
    'colorHex': colorHex,
  };

  factory ClassSection.fromJson(Map<String, dynamic> json) => ClassSection(
    classId: json['classId'] as String,
    sectionName: json['sectionName'] as String,
    courseCode: json['courseCode'] as String,
    courseName: json['courseName'] as String,
    sectionType: json['sectionType'] == 'practice'
        ? SectionType.practice
        : SectionType.theory,
    parentTheoryClassId: json['parentTheoryClassId'] as String?,
    timeSlots: (json['timeSlots'] as List<dynamic>?)
            ?.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    capacity: json['capacity'] as int? ?? 50,
    enrolledCount: json['enrolledCount'] as int? ?? 0,
    colorHex: json['colorHex'] as int? ?? 0xFF1E88E5,
  );
}

/// 3. Course: Môn học trong khung chương trình CNTT TTN
class Course {
  final String courseCode;
  final String courseName;
  final int credits;
  final int theoryCredits;
  final int practiceCredits;
  final List<String> prerequisiteCodes;
  final List<String> corequisiteCodes;
  final List<ClassSection> sections;

  const Course({
    required this.courseCode,
    required this.courseName,
    required this.credits,
    this.theoryCredits = 3,
    this.practiceCredits = 0,
    this.prerequisiteCodes = const [],
    this.corequisiteCodes = const [],
    this.sections = const [],
  });

  List<ClassSection> get theorySections =>
      sections.where((s) => s.isTheory).toList();

  List<ClassSection> get practiceSections =>
      sections.where((s) => s.isPractice).toList();

  bool get hasPractice => practiceCredits > 0 || practiceSections.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'courseCode': courseCode,
    'courseName': courseName,
    'credits': credits,
    'theoryCredits': theoryCredits,
    'practiceCredits': practiceCredits,
    'prerequisiteCodes': prerequisiteCodes,
    'corequisiteCodes': corequisiteCodes,
    'sections': sections.map((s) => s.toJson()).toList(),
  };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    courseCode: json['courseCode'] as String,
    courseName: json['courseName'] as String,
    credits: json['credits'] as int,
    theoryCredits: json['theoryCredits'] as int? ?? (json['credits'] as int),
    practiceCredits: json['practiceCredits'] as int? ?? 0,
    prerequisiteCodes: List<String>.from(json['prerequisiteCodes'] ?? []),
    corequisiteCodes: List<String>.from(json['corequisiteCodes'] ?? []),
    sections: (json['sections'] as List<dynamic>?)
            ?.map((e) => ClassSection.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

/// 4. ScheduleOption: Một phương án TKB tối ưu sinh ra từ AI
class ScheduleOption {
  final String id;
  final String title;
  final List<ClassSection> selectedSections;
  final int totalCredits;
  final double fitnessScore;
  final int totalStudyDays;
  final int totalGapPeriods;
  final int earlyMorningCount;
  final List<String> freeDays;
  final List<String> highlights;

  const ScheduleOption({
    required this.id,
    required this.title,
    required this.selectedSections,
    required this.totalCredits,
    required this.fitnessScore,
    required this.totalStudyDays,
    required this.totalGapPeriods,
    required this.earlyMorningCount,
    required this.freeDays,
    this.highlights = const [],
  });

  /// Chuỗi mảng mã lớp để paste vào cổng tín chỉ TTN: "[4110034_01, 7010212_02]"
  String get oneClickRegistrationCodes {
    final codes = selectedSections.map((s) => s.classId).toList();
    return '[${codes.join(', ')}]';
  }
}
