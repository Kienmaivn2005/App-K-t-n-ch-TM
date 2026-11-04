/// Mô hình Deadline / Nhiệm vụ học tập của sinh viên
class StudentDeadlineTask {
  final String id;
  final String studentId;
  String title;
  String courseName;
  DateTime dueDate;
  String priority; // 'Cao', 'Trung bình', 'Thấp'
  bool isCompleted;
  String notes;

  StudentDeadlineTask({
    required this.id,
    required this.studentId,
    required this.title,
    required this.courseName,
    required this.dueDate,
    this.priority = 'Trung bình',
    this.isCompleted = false,
    this.notes = '',
  });

  /// Tính số ngày còn lại đến hạn nộp
  int get remainingDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  /// Chuỗi hiển thị trạng thái hạn chót
  String get dueLabel {
    if (isCompleted) return 'Đã hoàn thành';
    final rem = remainingDays;
    if (rem < 0) return 'Quá hạn ${rem.abs()} ngày';
    if (rem == 0) return 'Hạn chót hôm nay!';
    if (rem == 1) return 'Hạn chót ngày mai';
    return 'Còn $rem ngày';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'title': title,
    'courseName': courseName,
    'dueDate': dueDate.toIso8601String(),
    'priority': priority,
    'isCompleted': isCompleted,
    'notes': notes,
  };

  factory StudentDeadlineTask.fromMap(Map<String, dynamic> map) => StudentDeadlineTask(
    id: map['id'] ?? '',
    studentId: map['studentId'] ?? '',
    title: map['title'] ?? '',
    courseName: map['courseName'] ?? '',
    dueDate: DateTime.tryParse(map['dueDate'] ?? '') ?? DateTime.now().add(const Duration(days: 3)),
    priority: map['priority'] ?? 'Trung bình',
    isCompleted: map['isCompleted'] ?? false,
    notes: map['notes'] ?? '',
  );
}

