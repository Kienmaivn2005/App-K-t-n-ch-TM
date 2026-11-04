import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/mock_course_repository.dart';
import '../providers/course_selection_provider.dart';
import '../providers/schedule_planner_provider.dart';
import '../widgets/course_card_widget.dart';
import 'saved_plans_screen.dart';
import 'schedule_result_screen.dart';

/// Màn hình 1: CHỌN MÔN HỌC & GIỎ TÍN CHỈ (CourseSelectionScreen)
/// Thiết kế Bento Grid, Modern Minimalist, Soft Glassmorphism & Floating Action Button
class CourseSelectionScreen extends ConsumerWidget {
  const CourseSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(courseSelectionProvider);
    final selectionNotifier = ref.read(courseSelectionProvider.notifier);
    final faculties = MockCourseRepository.getFaculties();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lập Kế Hoạch Tín Chỉ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Học kỳ 1 (2026 - 2027) • Hệ Tín Chỉ',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              tooltip: 'Các phương án đã lưu',
              icon: const Icon(Icons.bookmark_rounded, color: Color(0xFF2563EB), size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedPlansScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. Bento Card Thống kê Tín chỉ (Ghim cố định)
              _buildBentoProgressCard(selectionState),

              // 2. Thanh tìm kiếm bo tròn tích hợp Filter icon & Chip phân loại Khoa
              _buildSearchAndFilterBar(context, ref, selectionState, selectionNotifier, faculties),

              // 3. Cảnh báo tiên quyết (nếu có)
              if (selectionState.prerequisiteWarnings.isNotEmpty)
                _buildPrerequisiteAlert(selectionState.prerequisiteWarnings),

              // 4. Danh sách các môn học mở
              Expanded(
                child: selectionState.filteredCourses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Không tìm thấy học phần phù hợp',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hãy thử thay đổi từ khóa hoặc bộ lọc khoa',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 6, bottom: 100),
                        itemCount: selectionState.filteredCourses.length,
                        itemBuilder: (context, index) {
                          final course = selectionState.filteredCourses[index];
                          final isSelected =
                              selectionState.selectedCourseIds.contains(course.id);
                          final hasWarning = selectionState.prerequisiteWarnings
                              .any((w) => w.contains(course.id));

                          return CourseCardWidget(
                            course: course,
                            isSelected: isSelected,
                            hasPrereqWarning: hasWarning,
                            onToggle: () => selectionNotifier.toggleCourse(course.id),
                          );
                        },
                      ),
              ),
            ],
          ),

          // 5. Bottom Floating Action Button (Gradient phát sáng nhẹ)
          _buildFloatingBottomActionButton(context, ref, selectionState),
        ],
      ),
    );
  }

  /// 1. Bento Card Thống kê Tín chỉ ghim cố định phía trên
  Widget _buildBentoProgressCard(CourseSelectionState state) {
    final credits = state.totalCredits;
    final selectedCount = state.selectedCourses.length;
    const minTC = 12;
    const maxTC = 24;

    Color badgeColor;
    Color badgeTextColor;
    String statusLabel;
    IconData statusIcon;

    if (credits == 0) {
      badgeColor = const Color(0xFFF1F5F9);
      badgeTextColor = const Color(0xFF64748B);
      statusLabel = 'Chưa chọn môn';
      statusIcon = Icons.radio_button_unchecked;
    } else if (credits < minTC) {
      badgeColor = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFFB45309);
      statusLabel = 'Thiếu ${minTC - credits} TC (Tối thiểu 12)';
      statusIcon = Icons.hourglass_top_rounded;
    } else if (credits <= maxTC) {
      badgeColor = const Color(0xFFECFDF5);
      badgeTextColor = const Color(0xFF047857);
      statusLabel = 'Hợp lệ ($credits/$maxTC TC)';
      statusIcon = Icons.check_circle_rounded;
    } else {
      badgeColor = const Color(0xFFFEE2E2);
      badgeTextColor = const Color(0xFFB91C1C);
      statusLabel = 'Vượt mức (+${credits - maxTC} TC)';
      statusIcon = Icons.error_outline_rounded;
    }

    final double progress = (credits / maxTC).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bento: Chỉ số lớn
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Giỏ Tín Chỉ Đăng Ký',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$credits',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            ' / 24 TC',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($selectedCount môn)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Badge trạng thái
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: badgeTextColor),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: badgeTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Thanh đo tiến độ (LinearProgressIndicator) bo góc
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                credits > maxTC
                    ? const Color(0xFFEF4444)
                    : (credits >= minTC
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B)),
              ),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 6),

          // Thước đo dải an toàn
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: 12 TC',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
              Text(
                'Tiêu chuẩn: 16 - 20 TC',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
              Text(
                'Max: 24 TC',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Thanh tìm kiếm bo tròn tích hợp Filter icon & Chip phân loại Khoa
  Widget _buildSearchAndFilterBar(
    BuildContext context,
    WidgetRef ref,
    CourseSelectionState state,
    CourseSelectionNotifier notifier,
    List<String> faculties,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: notifier.setSearchQuery,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                    decoration: const InputDecoration(
                      hintText: 'Tìm theo tên học phần hoặc mã (vd: KC215046)...',
                      hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 19),
                  tooltip: 'Chọn tất cả / Bỏ chọn',
                  onPressed: () {
                    if (state.selectedCourseIds.isEmpty) {
                      notifier.selectAllFiltered();
                    } else {
                      notifier.clearSelection();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Chips phân loại khoa
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: faculties.map((faculty) {
                final isSelected = state.selectedFaculty == faculty;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(faculty),
                    selected: isSelected,
                    onSelected: (_) => notifier.setSelectedFaculty(faculty),
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Cảnh báo tiên quyết
  Widget _buildPrerequisiteAlert(List<String> warnings) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cảnh báo điều kiện tiên quyết:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 2),
                ...warnings.map(
                  (w) => Text(
                    '• $w',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.25),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Bottom Floating Action Button (Gradient phát sáng nhẹ)
  Widget _buildFloatingBottomActionButton(
    BuildContext context,
    WidgetRef ref,
    CourseSelectionState state,
  ) {
    final count = state.selectedCourses.length;
    final credits = state.totalCredits;
    final isValid = count > 0;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: SafeArea(
        child: AnimatedOpacity(
          opacity: isValid ? 1.0 : 0.65,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: !isValid
                    ? null
                    : () async {
                        final plannerNotifier =
                            ref.read(schedulePlannerProvider.notifier);
                        await plannerNotifier.generateSchedules(state.selectedCourses);

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ScheduleResultScreen(),
                            ),
                          );
                        }
                      },
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            count > 0
                                ? 'Xếp lịch ($count môn - $credits TC)'
                                : 'Chọn ít nhất 1 môn',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
