import 'course_section_model.dart';
import 'time_slot_model.dart';

/// Mô hình hóa môn học / học phần (Course)
class Course {
  final String id; // Mã môn học (VD: KC215046)
  final String name; // Tên môn học (VD: Lập trình di động)
  final int credits; // Số tín chỉ
  final List<String> prerequisites; // Mã các môn tiên quyết (VD: ['KC212604'])
  final List<CourseSection> sections; // Tập các lớp học phần mở
  final String faculty; // Khoa phụ trách
  final int semester; // Học kỳ đề xuất (1, 2, 3...)
  final int theoryCredits;
  final int practiceCredits;

  const Course({
    required this.id,
    required this.name,
    required this.credits,
    this.prerequisites = const [],
    this.sections = const [],
    this.faculty = 'Khoa Khoa học Tự nhiên & Công nghệ',
    this.semester = 1,
    this.theoryCredits = 2,
    this.practiceCredits = 1,
  });

  Course copyWith({
    String? id,
    String? name,
    int? credits,
    List<String>? prerequisites,
    List<CourseSection>? sections,
    String? faculty,
    int? semester,
    int? theoryCredits,
    int? practiceCredits,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      prerequisites: prerequisites ?? this.prerequisites,
      sections: sections ?? this.sections,
      faculty: faculty ?? this.faculty,
      semester: semester ?? this.semester,
      theoryCredits: theoryCredits ?? this.theoryCredits,
      practiceCredits: practiceCredits ?? this.practiceCredits,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'credits': credits,
        'prerequisites': prerequisites,
        'sections': sections.map((s) => s.toJson()).toList(),
        'faculty': faculty,
        'semester': semester,
        'theoryCredits': theoryCredits,
        'practiceCredits': practiceCredits,
      };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as String,
        name: json['name'] as String,
        credits: json['credits'] as int? ?? 3,
        prerequisites: (json['prerequisites'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        sections: (json['sections'] as List<dynamic>?)
                ?.map((e) => CourseSection.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        faculty: json['faculty'] as String? ?? 'Khoa KHTN&CN',
        semester: json['semester'] as int? ?? 1,
        theoryCredits: json['theoryCredits'] as int? ?? 2,
        practiceCredits: json['practiceCredits'] as int? ?? 1,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Course && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Mô hình hóa phương án thời khóa biểu (SchedulePlan)
class SchedulePlan {
  final String id;
  final List<CourseSection> selectedSections;
  final int totalCredits;
  final double score;
  final bool isFavorite;
  final List<String> tags;

  const SchedulePlan({
    required this.id,
    required this.selectedSections,
    required this.totalCredits,
    this.score = 0.0,
    this.isFavorite = false,
    this.tags = const [],
  });

  SchedulePlan copyWith({
    String? id,
    List<CourseSection>? selectedSections,
    int? totalCredits,
    double? score,
    bool? isFavorite,
    List<String>? tags,
  }) {
    return SchedulePlan(
      id: id ?? this.id,
      selectedSections: selectedSections ?? this.selectedSections,
      totalCredits: totalCredits ?? this.totalCredits,
      score: score ?? this.score,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
    );
  }

  /// Lấy toàn bộ các khung giờ học trong phương án
  List<TimeSlot> getAllSlots() {
    final List<TimeSlot> list = [];
    for (final sec in selectedSections) {
      list.addAll(sec.slots);
    }
    list.sort((a, b) {
      final dayCmp = a.dayOfWeek.compareTo(b.dayOfWeek);
      if (dayCmp != 0) return dayCmp;
      return a.startPeriod.compareTo(b.startPeriod);
    });
    return list;
  }

  /// Danh sách mã lớp đăng ký nhanh (để copy vào cổng trường)
  String get registrationCodesString =>
      selectedSections.map((s) => s.classId).join(', ');

  String get classCodesJoined => registrationCodesString;

  Map<String, dynamic> toJson() => {
        'id': id,
        'selectedSections': selectedSections.map((s) => s.toJson()).toList(),
        'totalCredits': totalCredits,
        'score': score,
        'isFavorite': isFavorite,
        'tags': tags,
      };

  factory SchedulePlan.fromJson(Map<String, dynamic> json) => SchedulePlan(
        id: json['id'] as String,
        selectedSections: (json['selectedSections'] as List<dynamic>)
            .map((s) => CourseSection.fromJson(s as Map<String, dynamic>))
            .toList(),
        totalCredits: json['totalCredits'] as int? ?? 0,
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        isFavorite: json['isFavorite'] as bool? ?? false,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((t) => t.toString())
                .toList() ??
            const [],
      );
}
