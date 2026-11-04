import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/planner_provider.dart';
import '../theme/app_theme.dart';

class StatCardsHeader extends StatelessWidget {
  const StatCardsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    final credits = planner.totalCredits;
    final maxCredits = 24;
    final creditRatio = (credits / maxCredits).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        final cards = [
          _StatCardItem(
            title: 'Tín chỉ',
            value: '$credits / $maxCredits TC',
            subtitle: credits < 12
                ? 'Thiếu ${12 - credits} TC'
                : (credits > 24 ? 'Vượt hạn mức' : 'Đạt chuẩn'),
            icon: Icons.school_rounded,
            color: credits >= 12 && credits <= 24 ? AppTheme.primary : AppTheme.warning,
            progress: creditRatio,
          ),
          _StatCardItem(
            title: 'Học phí',
            value: '${currencyFormat.format(planner.finalPayableTuition)} đ',
            subtitle: planner.scholarshipRate > 0
                ? planner.scholarshipTitle
                : planner.profile.program.label,
            icon: Icons.payments_rounded,
            color: AppTheme.secondary,
          ),
          _StatCardItem(
            title: 'Đã chọn',
            value: '${planner.activePlan.selectedSections.length} Môn',
            subtitle: 'LT: ${planner.totalTheoryCredits} • TH: ${planner.totalPracticeCredits} TC',
            icon: Icons.auto_stories_rounded,
            color: AppTheme.accent,
          ),
          _StatCardItem(
            title: 'Trạng thái',
            value: planner.hasErrors
                ? '${planner.errorCount} Lỗi trùng'
                : (planner.hasWarnings ? '${planner.warningCount} Cảnh báo' : 'Hợp lệ'),
            subtitle: planner.hasErrors ? 'Cần chỉnh lịch' : 'Sẵn sàng đăng ký',
            icon: planner.hasErrors ? Icons.cancel_rounded : Icons.verified_rounded,
            color: planner.hasErrors ? AppTheme.danger : AppTheme.success,
          ),
        ];

        if (isCompact) {
          return SizedBox(
            height: 110,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(width: 210, child: cards[i]),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
          ),
        );
      },
    );
  }
}

class _StatCardItem extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double? progress;

  const _StatCardItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.slate500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.slate900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          if (progress != null) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.slate100,
                color: color,
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.slate400,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
