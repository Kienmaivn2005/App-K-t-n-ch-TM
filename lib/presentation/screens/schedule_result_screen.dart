import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/ics_exporter.dart';
import '../providers/course_selection_provider.dart';
import '../providers/schedule_planner_provider.dart';
import '../widgets/schedule_filter_sheet.dart';
import '../widgets/timetable_grid_widget.dart';

/// MÀN HÌNH 2: XEM VÀ LỰA CHỌN PHƯƠNG ÁN THỜI KHÓA BIỂU (ScheduleResultScreen / TimetableScreen)
/// Thiết kế Bento Grid, Plan Navigator, Modern Interactive Timetable & Soft Glassmorphism
class ScheduleResultScreen extends ConsumerWidget {
  const ScheduleResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannerState = ref.watch(schedulePlannerProvider);
    final plannerNotifier = ref.read(schedulePlannerProvider.notifier);
    final selectionState = ref.watch(courseSelectionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Phương Án Thời Khóa Biểu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        actions: [
          // Nút Filter icon xem bộ lọc ưu tiên
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              tooltip: 'Bộ lọc ưu tiên',
              icon: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 20),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ScheduleFilterSheet(
                    initialCriteria: plannerState.criteria,
                    onApply: (newCriteria) {
                      plannerNotifier.updateCriteria(
                        newCriteria,
                        selectionState.selectedCourses,
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Nút Bookmark / Heart icon "Lưu lịch này"
          Container(
            margin: const EdgeInsets.fromLTRB(4, 8, 12, 8),
            decoration: BoxDecoration(
              color: plannerState.isCurrentPlanSaved
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              tooltip: plannerState.isCurrentPlanSaved ? 'Đã lưu lịch này' : 'Lưu lịch này',
              icon: Icon(
                plannerState.isCurrentPlanSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: plannerState.isCurrentPlanSaved
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF475569),
                size: 20,
              ),
              onPressed: () async {
                await plannerNotifier.toggleFavoriteCurrentPlan();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            plannerState.isCurrentPlanSaved
                                ? Icons.delete_outline_rounded
                                : Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            plannerState.isCurrentPlanSaved
                                ? 'Đã xóa phương án khỏi mục Đã lưu'
                                : 'Đã lưu phương án thời khóa biểu thành công!',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: plannerState.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF2563EB),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Đang giải thuật toán CSP & Forward Checking...',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Đang chạy trên Dart Background Isolate để giữ UI mượt mà 60 FPS',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          : plannerState.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.event_busy_rounded,
                            size: 54,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Không Tìm Thấy Phương Án Hợp Lệ',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          plannerState.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Quay lại điều chỉnh môn', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildMainContent(context, ref, plannerState, plannerNotifier),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    WidgetRef ref,
    SchedulePlannerState state,
    SchedulePlannerNotifier notifier,
  ) {
    final currentPlan = state.currentPlan;
    if (currentPlan == null) return const SizedBox.shrink();

    final currentIndexFormatted = (state.currentPlanIndex + 1).toString().padLeft(2, '0');
    final totalPlansFormatted = state.totalPlans.toString().padLeft(2, '0');

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Plan Navigator: < Phương án 01 / 12 >
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nút Previous
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: state.totalPlans > 1 ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: state.totalPlans > 1 ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  onPressed: state.totalPlans > 1 ? notifier.previousPlan : null,
                ),

                // Indicator trung tâm
                Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Phương Án $currentIndexFormatted',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          ' / $totalPlansFormatted',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          '${currentPlan.score.toInt()} điểm tối ưu',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${currentPlan.totalCredits} TC',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),

                // Nút Next
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: state.totalPlans > 1 ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: state.totalPlans > 1 ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  onPressed: state.totalPlans > 1 ? notifier.nextPlan : null,
                ),
              ],
            ),
          ),

          // 2. Bento Card Thống kê & Tags đặc trưng của phương án
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ĐÁNH GIÁ PHƯƠNG ÁN NÀY:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '100% Không Xung Đột',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: currentPlan.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded, size: 13, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // 3. Khu vực Thời khóa biểu dạng lưới (Timetable Interactive Grid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TimetableGridWidget(
              sections: currentPlan.selectedSections,
            ),
          ),

          const SizedBox(height: 16),

          // 4. Các nút tác vụ nhanh (Quick Actions)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyAllClassIds(context, currentPlan.classCodesJoined),
                    icon: const Icon(Icons.copy_rounded, size: 17),
                    label: const Text(
                      'Sao Chép Mã Lớp',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      foregroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportIcs(context, currentPlan),
                    icon: const Icon(Icons.calendar_month_rounded, size: 17),
                    label: const Text(
                      'Xuất Lịch (.ics)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 5. Danh sách chi tiết các môn học & mã lớp trong phương án
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CÁC LỚP HỌC PHẦN ĐƯỢC CHỌN TRONG PHƯƠNG ÁN:',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                ...currentPlan.selectedSections.map((sec) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sec.courseName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Mã lớp: ${sec.classId} • GV: ${sec.lecturer}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF2563EB)),
                          tooltip: 'Sao chép mã lớp này',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: sec.classId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã chép mã lớp: ${sec.classId}'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyAllClassIds(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép danh sách mã lớp:\n$text'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _exportIcs(BuildContext context, dynamic currentPlan) async {
    try {
      final icsContent = IcsExporter.generateIcsContent(currentPlan);
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text('Xuất Lịch iCalendar (.ics)'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Định dạng chuẩn RFC 5545 tương thích 100% với Google Calendar, Apple Calendar và Microsoft Outlook.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Đã tạo ${currentPlan.selectedSections.length} sự kiện học tập lặp lại hàng tuần trong suốt học kỳ.',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: icsContent));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép dữ liệu iCal (.ics) vào bộ nhớ tạm!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Sao Chép Nội Dung .ics'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tạo file iCalendar: $e')),
      );
    }
  }
}
