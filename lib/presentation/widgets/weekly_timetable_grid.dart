import 'package:flutter/material.dart';
import '../../domain/models/timetable_models.dart';

/// ============================================================================
/// WEEKLY TIMETABLE GRID WIDGET
/// Feature-First Clean Architecture: lib/presentation/widgets/weekly_timetable_grid.dart
/// Lưới 6 cột (Thứ 2 -> Thứ 7) x 10 hàng (Tiết 1 -> Tiết 10) chuẩn ĐH Tây Nguyên
/// Tự động tính tọa độ top/height, phân định Ca Sáng (1-5) & Chiều (6-10)
/// ============================================================================

class WeeklyTimetableGrid extends StatelessWidget {
  final List<ClassSection> sections;
  final void Function(ClassSection section, TimeSlot slot)? onSectionTap;

  const WeeklyTimetableGrid({
    super.key,
    required this.sections,
    this.onSectionTap,
  });

  static const double _timeColWidth = 54.0;
  static const double _headerHeight = 40.0;
  static const double _rowHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    const int totalPeriods = 10; // Tiết 1 đến Tiết 10
    final List<int> days = [2, 3, 4, 5, 6, 7]; // Thứ 2 -> Thứ 7

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double dayWidth = ((availableWidth - _timeColWidth) / days.length).clamp(72.0, 160.0);
        final double totalWidth = _timeColWidth + (dayWidth * days.length);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: totalWidth,
            child: Column(
              children: [
                // 1. Header hàng Thứ 2 -> Thứ 7
                _buildHeader(days, dayWidth),

                // 2. Body Lưới 10 tiết
                SizedBox(
                  height: totalPeriods * _rowHeight,
                  child: Stack(
                    children: [
                      // Lớp lưới nền (Background Grid)
                      _buildBackgroundGrid(days, dayWidth, totalPeriods),

                      // Lớp các khối môn học (Course Blocks)
                      ..._buildCourseBlocks(context, days, dayWidth),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(List<int> days, double colWidth) {
    final names = {2: 'T2', 3: 'T3', 4: 'T4', 5: 'T5', 6: 'T6', 7: 'T7'};

    return Container(
      height: _headerHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A), // TTN Blue
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Container(
            width: _timeColWidth,
            alignment: Alignment.center,
            child: const Text(
              'Tiết',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          ...days.map(
            (d) => Container(
              width: colWidth,
              alignment: Alignment.center,
              child: Text(
                names[d] ?? 'T$d',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGrid(List<int> days, double colWidth, int periods) {
    final startTimes = {
      1: '07:00', 2: '07:50', 3: '08:50', 4: '09:40', 5: '10:30',
      6: '13:00', 7: '13:50', 8: '14:50', 9: '15:40', 10: '16:30',
    };

    return Column(
      children: List.generate(periods, (idx) {
        final p = idx + 1;
        final isAfternoon = p == 6; // Ranh giới ca chiều

        return Container(
          height: _rowHeight,
          decoration: BoxDecoration(
            color: isAfternoon
                ? const Color(0xFFF1F5F9)
                : (p % 2 == 0 ? const Color(0xFFFAFAFA) : Colors.white),
            border: Border(
              bottom: BorderSide(
                color: isAfternoon ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0),
                width: isAfternoon ? 1.5 : 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: _timeColWidth,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Color(0xFFCBD5E1))),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'T$p',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isAfternoon ? FontWeight.bold : FontWeight.w600,
                        color: isAfternoon ? const Color(0xFF1E3A8A) : const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      startTimes[p] ?? '',
                      style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              ...days.map(
                (_) => Container(
                  width: colWidth,
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  List<Widget> _buildCourseBlocks(BuildContext context, List<int> days, double colWidth) {
    final widgets = <Widget>[];

    for (final sec in sections) {
      for (final slot in sec.timeSlots) {
        final dayIdx = days.indexOf(slot.dayOfWeek);
        if (dayIdx == -1) continue;

        final left = _timeColWidth + (dayIdx * colWidth);
        final top = (slot.startPeriod - 1) * _rowHeight;
        final height = (slot.periodCount * _rowHeight) - 2.0;
        final width = colWidth - 2.0;

        widgets.add(
          Positioned(
            left: left + 1.0,
            top: top + 1.0,
            width: width,
            height: height,
            child: _buildBlock(context, sec, slot),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildBlock(BuildContext context, ClassSection sec, TimeSlot slot) {
    final color = Color(sec.colorHex);
    final isTH = sec.isPractice;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (onSectionTap != null) {
            onSectionTap!(sec, slot);
          } else {
            _showDetailBottomSheet(context, sec, slot);
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color, width: isTH ? 1.5 : 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                        decoration: BoxDecoration(
                          color: isTH ? const Color(0xFFEA580C) : color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          isTH ? 'TH' : 'LT',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          sec.classId,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sec.courseName,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, height: 1.1),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Text(
                slot.room,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hiển thị Modal Bottom Sheet chi tiết môn học khi nhấn vào block
  void _showDetailBottomSheet(BuildContext context, ClassSection sec, TimeSlot slot) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sec.isPractice ? const Color(0xFFEA580C) : const Color(0xFF1E88E5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sec.isPractice ? 'THỰC HÀNH' : 'LÝ THUYẾT',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sec.classId,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(sec.courseName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const Divider(height: 24),
            _infoRow(Icons.schedule_rounded, 'Thời gian', '${slot.dayLabel} • ${slot.timeRangeString} (Tiết ${slot.startPeriod}-${slot.endPeriod})'),
            const SizedBox(height: 8),
            _infoRow(Icons.meeting_room_rounded, 'Phòng học', slot.room),
            const SizedBox(height: 8),
            _infoRow(Icons.person_rounded, 'Giảng viên', slot.lecturer),
            const SizedBox(height: 8),
            _infoRow(Icons.people_alt_rounded, 'Sĩ số', '${sec.enrolledCount}/${sec.capacity} (Còn ${sec.remainingSlots} chỗ)'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text('$title: ', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }
}
