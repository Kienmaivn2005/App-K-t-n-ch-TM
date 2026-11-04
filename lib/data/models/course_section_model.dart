import 'time_slot_model.dart';

/// Mô hình hóa lớp học phần (CourseSection)
/// Đại diện cho 1 nhóm lớp mở gồm toàn bộ các khung giờ học lý thuyết và thực hành
class CourseSection {
  final String classId; // Mã lớp học phần (VD: KC215046_74297)
  final String courseId; // Mã học phần (VD: KC215046)
  final String courseName; // Tên học phần (VD: Lập trình di động)
  final String lecturer; // Giảng viên
  final List<TimeSlot> slots; // Danh sách khung giờ (bao gồm cả LT và TH)
  final int capacity; // Sĩ số tối đa
  final int enrolled; // Đã đăng ký

  const CourseSection({
    required this.classId,
    required this.courseId,
    required this.courseName,
    required this.lecturer,
    required this.slots,
    this.capacity = 70,
    this.enrolled = 0,
  });

  /// Kiểm tra xung đột lịch học với một lớp học phần khác
  /// Trùng nhau khi có ít nhất một cặp TimeSlot giữa 2 lớp xung đột
  bool conflictsWith(CourseSection other) {
    for (final slotA in slots) {
      for (final slotB in other.slots) {
        if (slotA.conflictsWith(slotB)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Tổng số tiết học trong tuần
  int get totalPeriods => slots.fold(0, (sum, s) => sum + s.length);

  /// Lớp đã đầy sĩ số
  bool get isFull => capacity > 0 && enrolled >= capacity;

  Map<String, dynamic> toJson() => {
        'classId': classId,
        'courseId': courseId,
        'courseName': courseName,
        'lecturer': lecturer,
        'slots': slots.map((s) => s.toJson()).toList(),
        'capacity': capacity,
        'enrolled': enrolled,
      };

  factory CourseSection.fromJson(Map<String, dynamic> json) => CourseSection(
        classId: json['classId'] as String,
        courseId: json['courseId'] as String,
        courseName: json['courseName'] as String,
        lecturer: json['lecturer'] as String? ?? 'Chưa phân công',
        slots: (json['slots'] as List<dynamic>?)
                ?.map((s) => TimeSlot.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        capacity: json['capacity'] as int? ?? 70,
        enrolled: json['enrolled'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseSection &&
          runtimeType == other.runtimeType &&
          classId == other.classId;

  @override
  int get hashCode => classId.hashCode;
}
