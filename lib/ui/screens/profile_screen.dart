import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student_profile.dart';
import '../../providers/planner_provider.dart';
import '../../services/mock_data.dart';
import '../../services/ttn_database.dart';
import '../theme/app_theme.dart';
import 'prerequisite_roadmap_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _majorController;
  late TextEditingController _cohortController;
  late String _faculty;
  late AcademicWarning _academicWarning;
  late int _trainingPoints;

  static const List<String> faculties = [
    'Khoa Kỹ thuật - Công nghệ',
    'Khoa Sư phạm',
    'Khoa Kinh tế',
    'Khoa Nông Lâm nghiệp',
    'Khoa Y Dược',
  ];

  @override
  void initState() {
    super.initState();
    final profile = context.read<PlannerProvider>().profile;
    _nameController = TextEditingController(text: profile.fullName);
    _idController = TextEditingController(text: profile.studentId);
    _majorController = TextEditingController(text: profile.major);
    _cohortController = TextEditingController(text: profile.cohort);
    _faculty = profile.faculty;
    _academicWarning = profile.academicWarning;
    _trainingPoints = profile.trainingPoints;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _majorController.dispose();
    _cohortController.dispose();
    super.dispose();
  }

  void _saveProfile(PlannerProvider planner) {
    final updated = planner.profile.copyWith(
      fullName: _nameController.text.trim(),
      studentId: _idController.text.trim(),
      major: _majorController.text.trim(),
      cohort: _cohortController.text.trim(),
      faculty: _faculty,
      academicWarning: _academicWarning,
      trainingPoints: _trainingPoints,
    );
    planner.updateProfile(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật lộ trình học tập & Quy chế đào tạo TTN!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final profile = planner.profile;
    final completedCourseMap = MockDataService.getCompletedCoursesDetails();

    const totalDegreeCredits = 140;
    int passedCredits = 0;
    for (final code in profile.passedCourses) {
      if (!code.startsWith('QP') && !code.startsWith('SP21103') && !code.startsWith('SP21104')) {
        final cr = TTNDatabase.curriculumCourseCredits[code] ?? planner.getCourseByCode(code)?.credits.toDouble() ?? 2.0;
        passedCredits += cr.toInt();
      }
    }
    final progressValue = (passedCredits / totalDegreeCredits).clamp(0.0, 1.0);
    final progressPercent = (progressValue * 100).round();
    final remainingCredits = (totalDegreeCredits - passedCredits).clamp(0, totalDegreeCredits);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Degree Progress Card & Tree Graph Action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1E1E3A8A),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.school_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Lộ Trình Học Tập & Tiến Độ Tích Lũy',
                            style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('$progressPercent% chặng đường', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đã tích lũy: $passedCredits / $totalDegreeCredits Tín chỉ',
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Còn lại: $remainingCredits TC (Dự kiến tốt nghiệp: 2027)',
                        style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrerequisiteRoadmapScreen()),
                        );
                      },
                      icon: const Icon(Icons.account_tree_rounded, size: 18),
                      label: const Text('Xem Sơ Đồ Cây Môn Học Tiên Quyết'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E3A8A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Student Card Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.slate200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppTheme.primaryLight,
                        child: Text(
                          profile.fullName.isNotEmpty ? profile.fullName[0] : 'S',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'MSSV: ${profile.studentId} • ${profile.cohort}',
                              style: const TextStyle(color: AppTheme.slate500, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${profile.faculty} - ${profile.major}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('GPA Tích lũy', '${profile.currentGpa.toStringAsFixed(2)} / 4.0', AppTheme.primary),
                      _buildStatColumn('Điểm Rèn luyện', '$_trainingPoints / 100', AppTheme.success),
                      _buildStatColumn('Hạn mức Tín chỉ', '${profile.maxAllowedCredits} TC', Colors.indigo),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Scholarship & Academic Warning Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: profile.academicWarning == AcademicWarning.none ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: profile.academicWarning == AcademicWarning.none ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    profile.academicWarning == AcademicWarning.none ? Icons.school_rounded : Icons.warning_amber_rounded,
                    color: profile.academicWarning == AcademicWarning.none ? AppTheme.success : AppTheme.danger,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xét Học Bổng & Tình Trạng Học Vụ (Quy chế TTN)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: profile.academicWarning == AcademicWarning.none ? const Color(0xFF166534) : const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '• ${profile.scholarshipRank}\n• Tình trạng: ${_academicWarning.label}',
                          style: TextStyle(
                            fontSize: 12,
                            color: profile.academicWarning == AcademicWarning.none ? const Color(0xFF14532D) : const Color(0xFF7F1D1D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Edit Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông Tin Hồ Sơ & Học Tập:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _idController,
                          decoration: const InputDecoration(labelText: 'Mã số sinh viên (MSSV)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _cohortController,
                          decoration: const InputDecoration(labelText: 'Khóa học'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Faculty Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: faculties.contains(_faculty) ? _faculty : faculties.first,
                    decoration: const InputDecoration(labelText: 'Khoa đào tạo tại TTN'),
                    items: faculties.map((f) {
                      return DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _faculty = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _majorController,
                    decoration: const InputDecoration(labelText: 'Chuyên ngành đào tạo'),
                  ),
                  const SizedBox(height: 12),
                  // Academic Warning Dropdown
                  DropdownButtonFormField<AcademicWarning>(
                    initialValue: _academicWarning,
                    decoration: const InputDecoration(labelText: 'Tình trạng cảnh báo học vụ'),
                    items: AcademicWarning.values.map((w) {
                      return DropdownMenuItem(
                        value: w,
                        child: Text(w.label, style: const TextStyle(fontSize: 12.5)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _academicWarning = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Training Points Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Điểm Rèn Luyện (ĐRL):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text('$_trainingPoints điểm', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ],
                      ),
                      Slider(
                        value: _trainingPoints.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        label: '$_trainingPoints',
                        activeColor: AppTheme.primary,
                        onChanged: (val) => setState(() => _trainingPoints = val.round()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Lưu Thông Tin'),
                      onPressed: () => _saveProfile(planner),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Passed courses checklist
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bảng Điểm Môn Đã Tích Lũy (Tiên Quyết):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${profile.passedCourses.length} Môn đã đạt',
                          style: const TextStyle(
                            color: Color(0xFF065F46),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đánh dấu các môn bạn đã thi qua. Hệ thống AI sẽ dựa vào bảng điểm này để kiểm tra xem bạn có đủ điều kiện đăng ký các môn tiên quyết hay không.',
                    style: TextStyle(color: AppTheme.slate500, fontSize: 12.5),
                  ),
                  const SizedBox(height: 12),
                  ...completedCourseMap.entries.map((entry) {
                    final isPassed = profile.passedCourses.contains(entry.key);

                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isPassed,
                      activeColor: AppTheme.success,
                      title: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isPassed ? FontWeight.w600 : FontWeight.normal,
                          decoration: isPassed ? TextDecoration.none : null,
                        ),
                      ),
                      subtitle: Text(
                        'Mã HP: ${entry.key}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.slate500),
                      ),
                      onChanged: (bool? val) {
                        final currentList = List<String>.from(profile.passedCourses);
                        if (val == true) {
                          if (!currentList.contains(entry.key)) {
                            currentList.add(entry.key);
                          }
                        } else {
                          currentList.remove(entry.key);
                        }
                        planner.updateProfile(profile.copyWith(passedCourses: currentList));
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.slate500)),
      ],
    );
  }
}
