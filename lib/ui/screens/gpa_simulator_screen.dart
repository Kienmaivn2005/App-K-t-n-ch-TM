import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/planner_provider.dart';

class GpaSimulatorScreen extends StatefulWidget {
  const GpaSimulatorScreen({super.key});

  @override
  State<GpaSimulatorScreen> createState() => _GpaSimulatorScreenState();
}

class _GpaSimulatorScreenState extends State<GpaSimulatorScreen> {
  final Map<String, String> _simulatedGrades = {};

  static const Map<String, double> gradeToPoints = {
    'A': 4.0,
    'B+': 3.5,
    'B': 3.0,
    'C+': 2.5,
    'C': 2.0,
    'D+': 1.5,
    'D': 1.0,
    'F': 0.0,
  };

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final profile = planner.profile;
    final activeSections = planner.activePlan.selectedSections.values.toList();

    // Initialize default expected grades if not set
    for (final sec in activeSections) {
      _simulatedGrades.putIfAbsent(sec.courseCode, () => 'B+');
    }

    // Calculate simulated semester GPA
    int currentPlanCredits = 0;
    double totalQualityPointsSemester = 0.0;

    for (final sec in activeSections) {
      final grade = _simulatedGrades[sec.courseCode] ?? 'B+';
      final pts = gradeToPoints[grade] ?? 3.0;
      final cr = planner.getCourseByCode(sec.courseCode)?.credits ?? 3;
      currentPlanCredits += cr;
      totalQualityPointsSemester += pts * cr;
    }

    final simulatedSemesterGpa = currentPlanCredits > 0
        ? totalQualityPointsSemester / currentPlanCredits
        : 0.0;

    // Estimate cumulative GPA
    // Assume prior completed credits: ~45 TC at current GPA
    const priorCredits = 45;
    final priorPoints = profile.currentGpa * priorCredits;
    final totalCreditsNew = priorCredits + currentPlanCredits;
    final newCumulativeGpa = totalCreditsNew > 0
        ? (priorPoints + totalQualityPointsSemester) / totalCreditsNew
        : profile.currentGpa;

    // Academic Standing evaluation (QĐ 1574)
    String ranking;
    Color rankingColor;
    String scholarshipStatus;
    Color scholarshipColor;

    if (newCumulativeGpa >= 3.60) {
      ranking = 'Xuất sắc';
      rankingColor = const Color(0xFF16A34A);
      scholarshipStatus = 'Đạt tiêu chuẩn Học bổng Xuất sắc (Miễn 100% học phí)';
      scholarshipColor = const Color(0xFF16A34A);
    } else if (newCumulativeGpa >= 3.20) {
      ranking = 'Giỏi';
      rankingColor = const Color(0xFF2563EB);
      scholarshipStatus = 'Đạt tiêu chuẩn Học bổng Giỏi (Miễn 50% học phí)';
      scholarshipColor = const Color(0xFF2563EB);
    } else if (newCumulativeGpa >= 2.50) {
      ranking = 'Khá';
      rankingColor = const Color(0xFF0D9488);
      scholarshipStatus = 'Đạt tiêu chuẩn Học bổng Khá (Miễn 20% học phí)';
      scholarshipColor = const Color(0xFF0D9488);
    } else if (newCumulativeGpa >= 2.00) {
      ranking = 'Trung bình';
      rankingColor = const Color(0xFFD97706);
      scholarshipStatus = 'Đạt chuẩn tốt nghiệp (Không xét học bổng)';
      scholarshipColor = const Color(0xFFD97706);
    } else {
      ranking = 'Yếu (Cảnh báo)';
      rankingColor = const Color(0xFFDC2626);
      scholarshipStatus = '⚠️ Cảnh báo học vụ mức 1 (Cần cải thiện GPA >= 2.0)';
      scholarshipColor = const Color(0xFFDC2626);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.calculate, size: 20),
            SizedBox(width: 8),
            Text('Dự Báo Điểm GPA & Cảnh Báo Học Vụ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Simulation Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricColumn(
                        label: 'GPA Hiện tại',
                        value: profile.currentGpa.toStringAsFixed(2),
                        color: Colors.white70,
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildMetricColumn(
                        label: 'GPA Kỳ Này (Dự kiến)',
                        value: simulatedSemesterGpa.toStringAsFixed(2),
                        color: const Color(0xFFFDE047),
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildMetricColumn(
                        label: 'TBCTL Mới',
                        value: newCumulativeGpa.toStringAsFixed(2),
                        color: Colors.white,
                        isBold: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars, color: Color(0xFFFDE047), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Xếp loại học lực dự kiến: $ranking',
                          style: TextStyle(color: rankingColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scholarshipStatus,
                    style: TextStyle(color: scholarshipColor, fontSize: 11.5, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Courses Grade Simulator List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CÁC HỌC PHẦN TRONG KẾ HOẠCH HIỆN TẠI',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
                Text(
                  '${activeSections.length} môn • $currentPlanCredits TC',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (activeSections.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Text(
                    'Kế hoạch hiện tại chưa có học phần nào.\nVui lòng vào tab "Đăng ký học phần" để chọn môn trước khi dự báo điểm!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              ...activeSections.map((sec) {
                final currentGrade = _simulatedGrades[sec.courseCode] ?? 'B+';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sec.courseName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Mã HP: ${sec.courseCode} • ${planner.getCourseByCode(sec.courseCode)?.credits ?? 3} Tín chỉ • GV: ${sec.lecturer}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                        ),
                        child: DropdownButton<String>(
                          value: currentGrade,
                          underline: const SizedBox(),
                          isDense: true,
                          items: gradeToPoints.keys.map((g) {
                            return DropdownMenuItem<String>(
                              value: g,
                              child: Text(
                                '$g (${gradeToPoints[g]})',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _simulatedGrades[sec.courseCode] = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 16),
            // Academic Rules Callout
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Quy chế cảnh báo học vụ số 1574/QĐ-ĐHTN:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Điểm TBCTL < 1.20 (Năm 1), < 1.40 (Năm 2), < 1.60 (Năm 3) hoặc tổng số tín chỉ nợ vượt quá 24 TC sẽ bị Nhà trường cảnh báo học vụ mức 1 hoặc mức 2.\n'
                    '• Bị cảnh báo 3 lần liên tiếp sẽ bị xử lý buộc thôi học.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn({
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.white70)),
      ],
    );
  }
}
