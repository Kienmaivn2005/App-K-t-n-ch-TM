enum TuitionPolicy {
  none('Không áp dụng', 0.0),
  poorFamily('Hộ nghèo / Cận nghèo', 1.0),
  martyrChild('Con thương binh / Liệt sĩ', 1.0),
  remoteArea('Vùng sâu vùng xa / Hải đảo', 0.5);

  final String label;
  final double discountRate;
  const TuitionPolicy(this.label, this.discountRate);
}

enum AcademicProgram {
  standard('Chương trình Chuẩn', 619000), // ~1.238.000 / 2 TC = 619k/TC
  highQuality('Chương trình Chất lượng cao', 850000),
  international('Chương trình Tiên tiến / Quốc tế', 1250000);

  final String label;
  final int basePricePerCredit;
  const AcademicProgram(this.label, this.basePricePerCredit);
}

enum AcademicWarning {
  none('Bình thường (Đủ điều kiện đăng ký 14-24 TC)', 24),
  warningLevel1('Cảnh báo học vụ Mức 1 (Giới hạn tối đa 14 TC)', 14),
  warningLevel2('Cảnh báo học vụ Mức 2 (Giới hạn tối đa 12 TC)', 12),
  expelled('Buộc thôi học / Đình chỉ', 0);

  final String label;
  final int maxCredits;
  const AcademicWarning(this.label, this.maxCredits);
}

class StudentProfile {
  final String studentId;
  final String fullName;
  final String birthDate;
  final String faculty; // Khoa (Kỹ thuật Công nghệ, Sư phạm, Nông Lâm...)
  final String major;
  final String cohort;
  final double currentGpa;
  final double targetGpa;
  final int trainingPoints; // Điểm rèn luyện (0 - 100)
  final AcademicWarning academicWarning;
  final String advisor; // CVHT
  final String semester;
  final String academicYear;
  final List<String> passedCourses;
  final AcademicProgram program;
  final TuitionPolicy tuitionPolicy;

  const StudentProfile({
    required this.studentId,
    required this.fullName,
    this.birthDate = '15/08/2005',
    this.faculty = 'Khoa Kỹ thuật - Công nghệ',
    required this.major,
    required this.cohort,
    required this.currentGpa,
    required this.targetGpa,
    this.trainingPoints = 85,
    this.academicWarning = AcademicWarning.none,
    this.advisor = 'GV2. Nguyễn Thị Như (Tel: 0906200625; mail:nhubmt@dng.vnn.vndc)',
    this.semester = '1',
    this.academicYear = '2026-2027',
    required this.passedCourses,
    this.program = AcademicProgram.standard,
    this.tuitionPolicy = TuitionPolicy.none,
  });

  StudentProfile copyWith({
    String? studentId,
    String? fullName,
    String? birthDate,
    String? faculty,
    String? major,
    String? cohort,
    double? currentGpa,
    double? targetGpa,
    int? trainingPoints,
    AcademicWarning? academicWarning,
    String? advisor,
    String? semester,
    String? academicYear,
    List<String>? passedCourses,
    AcademicProgram? program,
    TuitionPolicy? tuitionPolicy,
  }) {
    return StudentProfile(
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      faculty: faculty ?? this.faculty,
      major: major ?? this.major,
      cohort: cohort ?? this.cohort,
      currentGpa: currentGpa ?? this.currentGpa,
      targetGpa: targetGpa ?? this.targetGpa,
      trainingPoints: trainingPoints ?? this.trainingPoints,
      academicWarning: academicWarning ?? this.academicWarning,
      advisor: advisor ?? this.advisor,
      semester: semester ?? this.semester,
      academicYear: academicYear ?? this.academicYear,
      passedCourses: passedCourses ?? this.passedCourses,
      program: program ?? this.program,
      tuitionPolicy: tuitionPolicy ?? this.tuitionPolicy,
    );
  }

  bool hasPassed(String courseCode) {
    return passedCourses.contains(courseCode);
  }

  /// Lấy danh hiệu học bổng dựa trên GPA và Điểm rèn luyện
  String get scholarshipRank {
    if (academicWarning != AcademicWarning.none) return 'Không đủ điều kiện (Có cảnh báo)';
    if (currentGpa >= 3.6 && trainingPoints >= 90) return 'Học bổng Xuất Sắc (100% học phí)';
    if (currentGpa >= 3.2 && trainingPoints >= 80) return 'Học bổng Giỏi (75% học phí)';
    if (currentGpa >= 2.5 && trainingPoints >= 70) return 'Học bổng Khá (50% học phí)';
    return 'Không đạt học bổng khuyến khích';
  }

  int get maxAllowedCredits {
    if (academicWarning == AcademicWarning.warningLevel1) return 14;
    if (academicWarning == AcademicWarning.warningLevel2) return 12;
    if (academicWarning == AcademicWarning.expelled) return 0;
    return 24;
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'fullName': fullName,
        'birthDate': birthDate,
        'faculty': faculty,
        'major': major,
        'cohort': cohort,
        'currentGpa': currentGpa,
        'targetGpa': targetGpa,
        'trainingPoints': trainingPoints,
        'academicWarning': academicWarning.name,
        'advisor': advisor,
        'semester': semester,
        'academicYear': academicYear,
        'passedCourses': passedCourses,
        'program': program.name,
        'tuitionPolicy': tuitionPolicy.name,
      };

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        studentId: json['studentId'] as String? ?? '23103035',
        fullName: json['fullName'] as String? ?? 'Mai Đàm Thế Kiên',
        birthDate: json['birthDate'] as String? ?? '15/08/2005',
        faculty: json['faculty'] as String? ?? 'Khoa Kỹ thuật - Công nghệ',
        major: json['major'] as String? ?? '103 Công nghệ thông tin',
        cohort: json['cohort'] as String? ?? 'Công nghệ thông tin K23',
        currentGpa: (json['currentGpa'] as num?)?.toDouble() ?? 3.52,
        targetGpa: (json['targetGpa'] as num?)?.toDouble() ?? 3.60,
        trainingPoints: (json['trainingPoints'] as num?)?.toInt() ?? 85,
        academicWarning: AcademicWarning.values.firstWhere(
          (w) => w.name == json['academicWarning'],
          orElse: () => AcademicWarning.none,
        ),
        advisor: json['advisor'] as String? ??
            'GV2. Nguyễn Thị Như (Tel: 0906200625; mail:nhubmt@dng.vnn.vndc)',
        semester: json['semester'] as String? ?? '1',
        academicYear: json['academicYear'] as String? ?? '2026-2027',
        passedCourses: List<String>.from(json['passedCourses'] ?? [
          'KC211027',
          'FL211011',
          'KC211685',
          'KC212604',
          'KC212681',
          'KC212682',
          'KT212202',
          'SP211032',
          'FL211012',
          'KC211604',
          'KC212601',
          'KC212602',
          'KC215037',
          'NL211702',
          'SP211035',
          'FL211013',
          'KC212605',
          'KC212686',
          'KC215039',
          'ML211030',
          'KC213611',
          'SP211038',
          'FL211014',
          'KC211006',
          'KC213608',
          'KC215036',
          'KC215038',
          'KC215042',
          'ML211031',
          'KC211615',
          'KC211682',
          'KC213607',
          'KC213682',
          'KC215044',
          'KT213007',
          'ML211032',
          'KC213609',
          'KC213667',
          'KC215041',
          'KC215043',
          'ML211002',
          'QP211006',
          'QP211011',
          'QP211012',
          'QP211013',
          'KC213633',

          'FL211012',
          'KC211604',
          'KC212601',
          'KC215037',

          'KC212686',
          'KC215039',
          'KC213611',

          'ML211030',
        ]),
        program: AcademicProgram.values.firstWhere(
          (p) => p.name == json['program'],
          orElse: () => AcademicProgram.standard,
        ),
        tuitionPolicy: TuitionPolicy.values.firstWhere(
          (p) => p.name == json['tuitionPolicy'],
          orElse: () => TuitionPolicy.none,
        ),
      );

  static StudentProfile defaultProfile() => const StudentProfile(
        studentId: '23103035',
        fullName: 'Mai Đàm Thế Kiên',
        birthDate: '15/08/2005',
        faculty: 'Khoa Kỹ thuật - Công nghệ',
        major: '103 Công nghệ thông tin',
        cohort: 'Công nghệ thông tin K23',
        currentGpa: 2.17,
        targetGpa: 3.00,
        trainingPoints: 85,
        academicWarning: AcademicWarning.none,
        advisor: 'GV2. Nguyễn Thị Như (Tel: 0906200625; mail:nhubmt@dng.vnn.vndc)',
        semester: '1',
        academicYear: '2026-2027',
        passedCourses: [
          'KC211027',
          'FL211011',
          'KC211685',
          'KC212604',
          'KC212681',
          'KC212682',
          'KT212202',
          'SP211032',
          'FL211012',
          'KC211604',
          'KC212601',
          'KC212602',
          'KC215037',
          'NL211702',
          'SP211035',
          'FL211013',
          'KC212605',
          'KC212686',
          'KC215039',
          'ML211030',
          'KC213611',
          'SP211038',
          'FL211014',
          'KC211006',
          'KC213608',
          'KC215036',
          'KC215038',
          'KC215042',
          'ML211031',
          'KC211615',
          'KC211682',
          'KC213607',
          'KC213682',
          'KC215044',
          'KT213007',
          'ML211032',
          'KC213609',
          'KC213667',
          'KC215041',
          'KC215043',
          'ML211002',
          'QP211006',
          'QP211011',
          'QP211012',
          'QP211013',
          'KC213633',

          'FL211012',
          'KC211604',
          'KC212601',
          'KC215037',

          'KC212686',
          'KC215039',
          'KC213611',

          'ML211030', // Đã tích lũy Triết học Mác - Lênin (Thỏa điều kiện môn ML211033 - Lịch sử Đảng)
        ],
        program: AcademicProgram.standard,
        tuitionPolicy: TuitionPolicy.none,
      );
}
