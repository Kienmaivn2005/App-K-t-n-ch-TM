import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/auto_schedule_options.dart';
import '../../providers/planner_provider.dart';
import '../../services/auto_scheduler.dart';
import '../theme/app_theme.dart';
import '../widgets/conflict_banner.dart';

class AutoSchedulerScreen extends StatefulWidget {
  const AutoSchedulerScreen({super.key});

  @override
  State<AutoSchedulerScreen> createState() => _AutoSchedulerScreenState();
}

class _AutoSchedulerScreenState extends State<AutoSchedulerScreen> {
  final AutoScheduleCriteria _criteria = AutoScheduleCriteria();
  final Set<String> _selectedCourseCodes = {};
  List<AutoScheduleSolution> _solutions = [];
  bool _hasSearched = false;
  int _selectedSolutionTab = 0; // 0: Phương án tối ưu nhất, 1: Dự phòng 1, 2: Dự phòng 2

  @override
  void initState() {
    super.initState();
    // Default selected courses from active plan or first 4 courses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final planner = context.read<PlannerProvider>();
      final currentCodes = planner.activePlan.selectedSections.keys.toSet();
      if (currentCodes.isNotEmpty) {
        setState(() {
          _selectedCourseCodes.addAll(currentCodes);
        });
      } else {
        setState(() {
          _selectedCourseCodes.addAll(
            planner.courses.take(4).map((c) => c.code),
          );
        });
      }
    });
  }

  void _runAutoScheduler() {
    final planner = context.read<PlannerProvider>();
    final targetCourses = planner.courses
        .where((c) => _selectedCourseCodes.contains(c.code))
        .toList();

    final results = AutoSchedulerService.generateOptimalSchedules(
      targetCourses: targetCourses,
      criteria: _criteria,
      maxSolutions: 6,
    );

    setState(() {
      _solutions = results;
      _hasSearched = true;
      _selectedSolutionTab = 0;
    });

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm được phương án thỏa mãn do các lớp học phần bị trùng hoàn toàn!'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const ConflictBanner(),
                _buildIntroBanner(),
                _buildCriteriaCard(),
                _buildTargetCoursesSelector(planner),
                _buildRunButton(),
                const SizedBox(height: 12),
              ],
            ),
          ),
          if (_hasSearched)
            _solutions.isEmpty
                ? SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.rule_folder_rounded, size: 54, color: AppTheme.slate400),
                          const SizedBox(height: 12),
                          const Text(
                            'Không có phương án nào ghép nối hoàn hảo',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Các môn bạn chọn có số lượng lớp mở ít hoặc bị trùng tiết cố định. Hãy nới lỏng các tiêu chí (ví dụ: cho phép học sáng sớm) và thử lại.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.slate600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 3 Tab so sánh trực quan
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                _buildTabButton(0, '🏆 Tối ưu nhất', Icons.workspace_premium_rounded),
                                if (_solutions.length > 1)
                                  _buildTabButton(1, '🛡️ Kế hoạch Dự phòng 1', Icons.shield_outlined),
                                if (_solutions.length > 2)
                                  _buildTabButton(2, '📋 Kế hoạch Dự phòng 2', Icons.view_agenda_outlined),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Hiển thị Card của phương án được chọn trong tab
                          if (_selectedSolutionTab < _solutions.length)
                            _buildSolutionCard(
                              _solutions[_selectedSolutionTab],
                              _selectedSolutionTab + 1,
                              planner,
                            )
                          else if (_solutions.isNotEmpty)
                            _buildSolutionCard(_solutions.first, 1, planner),
                        ],
                      ),
                    ),
                  ),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.alt_route_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hệ Thống Xếp Lịch Tự Động Thông Minh',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tự động phân bổ và ghép nối các lớp học phần: Triệt tiêu trùng lịch, giảm tối đa tiết trống, né sáng sớm và chuẩn bị sẵn phương án dự phòng.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Thiết lập Tiêu chí Tối ưu hóa Thực tế:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            title: 'Không học sáng sớm (Tiết 1 - 2)',
            subtitle: 'Chỉ chọn các lớp bắt đầu từ tiết 3 (08:30) trở đi, tránh dậy sớm.',
            value: _criteria.avoidEarlyMorning,
            onChanged: (val) => setState(() => _criteria.avoidEarlyMorning = val),
          ),
          const Divider(height: 12),
          _buildToggleOption(
            title: 'Nghỉ trọn vẹn cuối tuần',
            subtitle: 'Loại bỏ hoàn toàn các lớp học có tiết vào Thứ 7 và Chủ Nhật.',
            value: _criteria.noWeekend,
            onChanged: (val) => setState(() => _criteria.noWeekend = val),
          ),
          const Divider(height: 12),
          _buildToggleOption(
            title: 'Nghỉ ngày Thứ 6',
            subtitle: 'Ưu tiên không xếp lớp vào Thứ 6 để sinh viên nghỉ cuối tuần kéo dài.',
            value: _criteria.freeFriday,
            onChanged: (val) => setState(() => _criteria.freeFriday = val),
          ),
          const Divider(height: 12),
          _buildToggleOption(
            title: 'Ưu tiên dồn lịch vào buổi Sáng',
            subtitle: 'Tập trung học các ca sáng (tiết 1-5), giải phóng buổi chiều để tự học/làm thêm.',
            value: _criteria.preferMorning,
            onChanged: (val) => setState(() {
              _criteria.preferMorning = val;
              if (val) _criteria.preferAfternoon = false;
            }),
          ),
          const Divider(height: 12),
          _buildToggleOption(
            title: 'Ưu tiên dồn lịch vào buổi Chiều',
            subtitle: 'Tập trung học các ca chiều (tiết 6-10), giải phóng buổi sáng nghỉ ngơi.',
            value: _criteria.preferAfternoon,
            onChanged: (val) => setState(() {
              _criteria.preferAfternoon = val;
              if (val) _criteria.preferMorning = false;
            }),
          ),
          const Divider(height: 12),
          _buildToggleOption(
            title: 'Gom lịch học (Tối thiểu ngày đến trường)',
            subtitle: 'Dồn các môn vào 3 - 4 ngày để có nhiều ngày trống tự học hoặc đi làm thêm.',
            value: _criteria.minimizeDays,
            onChanged: (val) => setState(() => _criteria.minimizeDays = val),
          ),
          const Divider(height: 12),
          _buildToggleOption(
            title: 'Tránh tiết trống (cửa sổ)',
            subtitle: 'Ưu tiên các ca học liền mạch, không phải ngồi chờ 2 - 3 tiếng ở trường.',
            value: _criteria.avoidWindowPeriods,
            onChanged: (val) => setState(() => _criteria.avoidWindowPeriods = val),
          ),
          const Divider(height: 12),
          _buildToggleOption(
            title: 'Ưu tiên giảng viên đánh giá cao (Tránh GV quá khắt khe)',
            subtitle: 'Xếp các thầy cô có điểm khảo sát cao nhất (4.7★+) từ cộng đồng sinh viên.',
            value: _criteria.preferHighRatingLecturers,
            onChanged: (val) => setState(() => _criteria.preferHighRatingLecturers = val),
          ),
          _buildToggleOption(
            title: 'Hạn chế di chuyển toà nhà (Nhà 6, Nhà 2, Nhà 7)',
            subtitle: 'Tránh trường hợp tiết trước học ở Nhà 6, tiết sau chạy sang khu khác trong 10 phút nghỉ.',
            value: _criteria.avoidMovingBuildings,
            onChanged: (val) => setState(() => _criteria.avoidMovingBuildings = val),
          ),
          _buildToggleOption(
            title: 'Tự động chọn bù tín chỉ nếu thiếu tối thiểu (<12 TC)',
            subtitle: 'AI tự động đề xuất thêm môn đại cương/tự chọn còn trống lịch để đảm bảo điều kiện đào tạo.',
            value: _criteria.autoCompensateCredits,
            onChanged: (val) => setState(() => _criteria.autoCompensateCredits = val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
      subtitle: Text(subtitle, style: TextStyle(color: AppTheme.slate500, fontSize: 12)),
      value: value,
      activeThumbColor: AppTheme.primary,
      onChanged: onChanged,
    );
  }

  Widget _buildTargetCoursesSelector(PlannerProvider planner) {
    int totalSelectedCredits = 0;
    for (final code in _selectedCourseCodes) {
      final c = planner.getCourseByCode(code);
      if (c != null) totalSelectedCredits += c.credits;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chọn các Môn cần Xếp lịch:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_selectedCourseCodes.length} môn ($totalSelectedCredits TC)',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.flash_on_rounded, size: 14, color: AppTheme.primary),
                  label: const Text('Chọn 8 môn chuẩn HK1', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  backgroundColor: AppTheme.primaryLight,
                  onPressed: () {
                    setState(() {
                      _selectedCourseCodes.clear();
                      _selectedCourseCodes.addAll([
                        'KC213613', 'KC213668', 'KC213678', 'KC213685',
                        'KC215046', 'KC215050', 'ML211033', 'SP211014',
                      ]);
                    });
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Chọn tất cả', style: TextStyle(fontSize: 11.5)),
                  onPressed: () {
                    setState(() {
                      _selectedCourseCodes.addAll(planner.courses.map((c) => c.code));
                    });
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Bỏ chọn', style: TextStyle(fontSize: 11.5)),
                  onPressed: () {
                    setState(() {
                      _selectedCourseCodes.clear();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: planner.courses.map((c) {
              final isChecked = _selectedCourseCodes.contains(c.code);
              return FilterChip(
                label: Text('${c.code} (${c.credits}TC)'),
                selected: isChecked,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedCourseCodes.add(c.code);
                    } else {
                      _selectedCourseCodes.remove(c.code);
                    }
                  });
                },
                selectedColor: AppTheme.primaryLight,
                checkmarkColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: isChecked ? AppTheme.primary : AppTheme.slate800,
                  fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12.5,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _selectedCourseCodes.isEmpty ? null : _runAutoScheduler,
          icon: const Icon(Icons.bolt_rounded, size: 24),
          label: const Text(
            'Bắt Đầu Xếp Lịch Tự Động',
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedSolutionTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedSolutionTab = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSolutionCard(AutoScheduleSolution sol, int rank, PlannerProvider planner) {
    final scoreColor = sol.score >= 90
        ? AppTheme.success
        : (sol.score >= 75 ? AppTheme.primary : AppTheme.warning);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rank == 1 ? AppTheme.primary : AppTheme.slate200, width: rank == 1 ? 2 : 1),
        boxShadow: rank == 1
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Hạng #$rank • ${sol.score.toStringAsFixed(0)}% Điểm',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (rank == 1) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(
                          'TỐI ƯU NHẤT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${sol.totalDays} ngày học/tuần',
                  style: TextStyle(color: AppTheme.slate600, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Highlights tags
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: sol.highlights.map((h) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.successLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 12, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Text(
                        h,
                        style: const TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (sol.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: sol.notes.map((n) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.warningLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '• $n',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 11.5,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const Divider(height: 20),
            // Section items in this solution
            const Text(
              'Các Lớp Học Phần Được Phân Phối:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            ...sol.sections.values.map((sec) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(sec.colorHex),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${sec.courseCode} (${sec.id}): ${sec.lecturer}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      sec.slots.map((s) => '${s.dayName} T${s.startPeriod}-${s.endPeriod}').join(', '),
                      style: TextStyle(color: AppTheme.slate500, fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
            if (sol.backupSections.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 15, color: Colors.indigo),
                        SizedBox(width: 6),
                        Text(
                          'Lớp Học Phần Dự Phòng (Tự động thay thế nếu lớp chính kín chỗ):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.indigo),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...sol.backupSections.entries.map((entry) {
                      final backupList = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${entry.key}: Có ${backupList.length} lớp thay thế khả thi -> [${backupList.map((b) => '${b.id} (${b.lecturer})').join(', ')}]',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            // One-click Copy Section Code for Course Hunting ("Săn tín chỉ")
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.content_copy_rounded, size: 16),
                label: Text(
                  'Copy Nhanh ${sol.sections.length} Mã Lớp Để "Săn" Tín Chỉ [${sol.sections.values.map((s) => s.id).join(', ')}]',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  final codes = sol.sections.values.map((s) => s.id).join(' ');
                  Clipboard.setData(ClipboardData(text: codes));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã copy danh sách mã lớp vào bộ nhớ: $codes'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      planner.applyAutoScheduleSolution(sol, createNewPlanOption: true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã lưu thành "${sol.title}" trong mục Kế hoạch dự phòng!')),
                      );
                    },
                    child: const Text('Lưu vào Kế hoạch Dự phòng'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      planner.applyAutoScheduleSolution(sol, createNewPlanOption: false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã áp dụng phương án vào Thời khóa biểu chính!')),
                      );
                    },
                    child: const Text('Áp dụng ngay'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
