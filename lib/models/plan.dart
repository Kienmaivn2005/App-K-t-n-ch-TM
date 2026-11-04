import 'course.dart';

class RegistrationPlan {
  final String id;
  String name;
  String description;
  final Map<String, ClassSection> selectedSections; // courseCode -> ClassSection
  final DateTime createdAt;
  DateTime updatedAt;

  RegistrationPlan({
    required this.id,
    required this.name,
    this.description = '',
    Map<String, ClassSection>? selectedSections,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : selectedSections = selectedSections ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get totalCredits {
    // Need external lookup or we can calculate if course is known,
    // or sections can be linked with courses
    return 0; // will be calculated through planner provider
  }

  int get courseCount => selectedSections.length;

  RegistrationPlan copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, ClassSection>? selectedSections,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RegistrationPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      selectedSections: selectedSections != null
          ? Map<String, ClassSection>.from(selectedSections)
          : Map<String, ClassSection>.from(this.selectedSections),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'selectedSections': selectedSections.map((k, v) => MapEntry(k, v.toJson())),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RegistrationPlan.fromJson(Map<String, dynamic> json) {
    final rawSections = json['selectedSections'] as Map<String, dynamic>? ?? {};
    final mappedSections = <String, ClassSection>{};
    rawSections.forEach((key, val) {
      if (val is Map<String, dynamic>) {
        mappedSections[key] = ClassSection.fromJson(val);
      }
    });

    return RegistrationPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      selectedSections: mappedSections,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : DateTime.now(),
    );
  }
}

