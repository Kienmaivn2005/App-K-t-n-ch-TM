import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../providers/planner_provider.dart';
import '../theme/app_theme.dart';

class PrerequisiteDialog extends StatelessWidget {
  final Course course;

  const PrerequisiteDialog({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final passedCourses = planner.profile.passedCourses;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 550),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_tree_rounded, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cây Tiên Quyết: ${course.code}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        course.name,
                        style: TextStyle(color: AppTheme.slate600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.slate100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppTheme.slate600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      course.prerequisites.isEmpty
                          ? 'Môn này không yêu cầu môn học tiên quyết. Bạn có thể tự do đăng ký!'
                          : 'Cần hoàn thành tất cả môn tiên quyết bên dưới để đủ điều kiện mở lớp.',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.slate700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (course.prerequisites.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.verified_rounded, size: 48, color: AppTheme.success.withValues(alpha: 0.8)),
                      const SizedBox(height: 10),
                      const Text(
                        'Đã đủ điều kiện đăng ký',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Không có ràng buộc môn tiên quyết',
                        style: TextStyle(color: AppTheme.slate500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              const Text(
                'Danh sách Môn Tiên Quyết bắt buộc:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 10),
              ...course.prerequisites.map((prereqCode) {
                final prereqCourse = planner.getCourseByCode(prereqCode);
                final isPassed = passedCourses.contains(prereqCode);
                final isSelectedInPlan = planner.activePlan.selectedSections.containsKey(prereqCode);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isPassed
                        ? AppTheme.successLight
                        : (isSelectedInPlan ? AppTheme.primaryLight : AppTheme.dangerLight),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPassed
                          ? AppTheme.success.withValues(alpha: 0.3)
                          : (isSelectedInPlan
                              ? AppTheme.primary.withValues(alpha: 0.3)
                              : AppTheme.danger.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPassed
                            ? Icons.check_circle_rounded
                            : (isSelectedInPlan ? Icons.timelapse_rounded : Icons.cancel_rounded),
                        color: isPassed
                            ? AppTheme.success
                            : (isSelectedInPlan ? AppTheme.primary : AppTheme.danger),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$prereqCode - ${prereqCourse?.name ?? 'Môn đại cương'}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            Text(
                              isPassed
                                  ? 'Trạng thái: Đã tích lũy (Đạt yêu cầu)'
                                  : (isSelectedInPlan
                                      ? 'Trạng thái: Đang xếp trong kế hoạch hiện tại'
                                      : 'Trạng thái: CHƯA ĐẠT (Chặn đăng ký)'),
                              style: TextStyle(
                                fontSize: 12,
                                color: isPassed
                                    ? const Color(0xFF065F46)
                                    : (isSelectedInPlan
                                        ? const Color(0xFF1E40AF)
                                        : const Color(0xFF991B1B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          planner.togglePassedCourse(prereqCode);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          isPassed ? 'Bỏ tick đạt' : 'Đánh dấu đã học',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isPassed ? AppTheme.slate600 : AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

