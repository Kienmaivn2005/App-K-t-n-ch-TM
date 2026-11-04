enum ConflictSeverity {
  error, // Trùng tiết, thiếu môn tiên quyết (Cấm đăng ký)
  warning, // Số tín chỉ quá ít (<12) hoặc quá nhiều (>24), chuyển cơ sở sát giờ
  info, // Gợi ý tối ưu
}

enum ConflictType {
  timeOverlap,
  missingPrerequisite,
  creditUnderload,
  creditOverload,
  campusSwitch,
}

class ConflictIssue {
  final String id;
  final ConflictType type;
  final ConflictSeverity severity;
  final String title;
  final String description;
  final List<String> relatedCourseCodes;
  final List<String> relatedSectionIds;

  const ConflictIssue({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    this.relatedCourseCodes = const [],
    this.relatedSectionIds = const [],
  });

  bool get isError => severity == ConflictSeverity.error;
  bool get isWarning => severity == ConflictSeverity.warning;
}

