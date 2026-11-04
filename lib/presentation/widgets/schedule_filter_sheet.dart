import 'package:flutter/material.dart';
import '../../core/algorithm/schedule_evaluator.dart';

/// Bộ lọc tiêu chí mềm (Filter BottomSheet) chuẩn Modern Minimalist & Soft Glassmorphism
class ScheduleFilterSheet extends StatefulWidget {
  final ScheduleFilterCriteria initialCriteria;
  final ValueChanged<ScheduleFilterCriteria> onApply;

  const ScheduleFilterSheet({
    super.key,
    required this.initialCriteria,
    required this.onApply,
  });

  @override
  State<ScheduleFilterSheet> createState() => _ScheduleFilterSheetState();
}

class _ScheduleFilterSheetState extends State<ScheduleFilterSheet> {
  late bool _preferMorning;
  late bool _preferAfternoon;
  late bool _avoidFriday;
  late bool _avoidSaturday;
  late bool _avoidPeriod1;
  late bool _minimizeGaps;

  @override
  void initState() {
    super.initState();
    _preferMorning = widget.initialCriteria.preferMorning;
    _preferAfternoon = widget.initialCriteria.preferAfternoon;
    _avoidFriday = widget.initialCriteria.avoidFriday;
    _avoidSaturday = widget.initialCriteria.avoidSaturday;
    _avoidPeriod1 = widget.initialCriteria.avoidPeriod1;
    _minimizeGaps = widget.initialCriteria.minimizeGaps;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle thanh lịch
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Bộ Lọc & Tiêu Chí Ưu Tiên',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _preferMorning = true;
                    _preferAfternoon = false;
                    _avoidFriday = false;
                    _avoidSaturday = true;
                    _avoidPeriod1 = false;
                    _minimizeGaps = true;
                  });
                },
                child: const Text(
                  'Mặc định',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tối ưu hóa các ràng buộc mềm dựa trên nguyện vọng thời gian biểu của bạn.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // 1. Ưu tiên học buổi sáng (Tránh ca chiều)
          _buildModernSwitchTile(
            title: 'Ưu tiên học buổi sáng (Tránh ca chiều)',
            subtitle: 'Xếp lịch vào các Tiết 1 - 5 (07:00 - 11:15)',
            icon: Icons.wb_sunny_rounded,
            activeColor: const Color(0xFF0284C7),
            value: _preferMorning,
            onChanged: (val) {
              setState(() {
                _preferMorning = val;
                if (val) _preferAfternoon = false;
              });
            },
          ),

          // 2. Nghỉ trọn vẹn ngày Thứ 6
          _buildModernSwitchTile(
            title: 'Nghỉ trọn vẹn ngày Thứ 6',
            subtitle: 'Dành toàn bộ ngày Thứ 6 làm ngày nghỉ cuối tuần dài',
            icon: Icons.weekend_rounded,
            activeColor: const Color(0xFF10B981),
            value: _avoidFriday,
            onChanged: (val) => setState(() => _avoidFriday = val),
          ),

          // 3. Hạn chế thời gian trống giữa các ca
          _buildModernSwitchTile(
            title: 'Hạn chế thời gian trống giữa các ca',
            subtitle: 'Giảm thiểu các tiết chờ đợi lãng phí giữa 2 môn cùng ngày',
            icon: Icons.hourglass_disabled_rounded,
            activeColor: const Color(0xFF2563EB),
            value: _minimizeGaps,
            onChanged: (val) => setState(() => _minimizeGaps = val),
          ),

          // 4. Tránh học ngày Thứ 7
          _buildModernSwitchTile(
            title: 'Tránh học ngày Thứ 7',
            subtitle: 'Không xếp bất kỳ lớp nào vào ngày Thứ 7',
            icon: Icons.event_busy_rounded,
            activeColor: const Color(0xFF8B5CF6),
            value: _avoidSaturday,
            onChanged: (val) => setState(() => _avoidSaturday = val),
          ),

          // 5. Tránh Tiết 1 (07:00 sáng)
          _buildModernSwitchTile(
            title: 'Tránh Tiết 1 (07:00 sáng)',
            subtitle: 'Ưu tiên các môn bắt đầu từ Tiết 2 trở đi',
            icon: Icons.alarm_off_rounded,
            activeColor: const Color(0xFFEA580C),
            value: _avoidPeriod1,
            onChanged: (val) => setState(() => _avoidPeriod1 = val),
          ),

          const SizedBox(height: 20),

          // Nút "Áp dụng và tối ưu lại" Full-width
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final newCriteria = ScheduleFilterCriteria(
                  preferMorning: _preferMorning,
                  preferAfternoon: _preferAfternoon,
                  avoidFriday: _avoidFriday,
                  avoidSaturday: _avoidSaturday,
                  avoidPeriod1: _avoidPeriod1,
                  minimizeGaps: _minimizeGaps,
                );
                widget.onApply(newCriteria);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Áp Dụng Và Tối Ưu Lại',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color activeColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: value ? activeColor.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? activeColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: value ? activeColor.withValues(alpha: 0.15) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: value ? activeColor : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: value ? const Color(0xFF0F172A) : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: activeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
