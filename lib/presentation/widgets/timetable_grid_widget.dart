import 'package:flutter/material.dart';
import '../../data/models/course_section_model.dart';
import '../../data/models/time_slot_model.dart';

/// Widget Thời khóa biểu dạng lưới tương tác (Timetable Interactive Grid)
/// Chuẩn Modern Minimalist: Cột tiết cố định, highlight ngày hiện tại, khối Pastel với viền trái đậm màu
class TimetableGridWidget extends StatelessWidget {
  final List<CourseSection> sections;
  final Function(CourseSection section, TimeSlot slot)? onSectionTap;

  const TimetableGridWidget({
    super.key,
    required this.sections,
    this.onSectionTap,
  });

  // Bảng màu pastel dịu nhẹ theo yêu cầu Design System
  static const List<Map<String, Color>> _palette = [
    {
      'bg': Color(0xFFEFF6FF), // Pastel Blue
      'border': Color(0xFF2563EB), // Dark Accent Left
      'text': Color(0xFF1D4ED8),
    },
    {
      'bg': Color(0xFFECFDF5), // Pastel Mint
      'border': Color(0xFF10B981),
      'text': Color(0xFF047857),
    },
    {
      'bg': Color(0xFFF5F3FF), // Pastel Purple
      'border': Color(0xFF8B5CF6),
      'text': Color(0xFF6D28D9),
    },
    {
      'bg': Color(0xFFFFF7ED), // Pastel Coral / Orange
      'border': Color(0xFFF97316),
      'text': Color(0xFFC2410C),
    },
    {
      'bg': Color(0xFFFEFCE8), // Pastel Amber / Yellow
      'border': Color(0xFFF59E0B),
      'text': Color(0xFFB45309),
    },
    {
      'bg': Color(0xFFF0FDFA), // Pastel Cyan / Teal
      'border': Color(0xFF0D9488),
      'text': Color(0xFF0F766E),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Chuyển thứ trong Dart (1 = Thứ 2, 7 = CN) sang thứ chuẩn TTN (2 = T2, 8 = CN)
    final currentDayTTN = now.weekday == 7 ? 8 : now.weekday + 1;

    final days = [
      {'val': 2, 'label': 'Thứ 2'},
      {'val': 3, 'label': 'Thứ 3'},
      {'val': 4, 'label': 'Thứ 4'},
      {'val': 5, 'label': 'Thứ 5'},
      {'val': 6, 'label': 'Thứ 6'},
      {'val': 7, 'label': 'Thứ 7'},
    ];

    // Gán bảng màu cố định theo môn học
    final courseColors = <String, Map<String, Color>>{};
    int colorIdx = 0;
    for (final s in sections) {
      if (!courseColors.containsKey(s.courseId)) {
        courseColors[s.courseId] = _palette[colorIdx % _palette.length];
        colorIdx++;
      }
    }

    // Các khung tiết hiển thị (Sáng: 1-5, Chiều: 6-10)
    final periods = [
      {'period': 1, 'time': '07:00 - 07:45'},
      {'period': 2, 'time': '07:50 - 08:35'},
      {'period': 3, 'time': '08:50 - 09:35'},
      {'period': 4, 'time': '09:40 - 10:25'},
      {'period': 5, 'time': '10:30 - 11:15'},
      {'period': 6, 'time': '13:00 - 13:45'},
      {'period': 7, 'time': '13:50 - 14:35'},
      {'period': 8, 'time': '14:50 - 15:35'},
      {'period': 9, 'time': '15:40 - 16:25'},
      {'period': 10, 'time': '16:30 - 17:15'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 720,
            child: Column(
              children: [
                // 1. Hàng Header các ngày trong tuần (T2 - T7)
                _buildDaysHeader(days, currentDayTTN),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // 2. Danh sách các hàng Tiết
                ...periods.map((pMap) {
                  final p = pMap['period'] as int;
                  final time = pMap['time'] as String;
                  final isSessionDivider = p == 5; // Ngăn cách giữa sáng và chiều

                  return Column(
                    children: [
                      _buildPeriodRow(
                        period: p,
                        timeRange: time,
                        days: days,
                        courseColors: courseColors,
                        context: context,
                      ),
                      if (isSessionDivider)
                        Container(
                          color: const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                          child: const Row(
                            children: [
                              Icon(Icons.wb_twilight_rounded, size: 14, color: Color(0xFF64748B)),
                              SizedBox(width: 6),
                              Text(
                                'Nghỉ trưa • Ca chiều bắt đầu lúc 13:00',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header hàng ngày với highlight ngày hiện tại
  Widget _buildDaysHeader(List<Map<String, dynamic>> days, int currentDayTTN) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Cột Tiết & Giờ cố định
          const SizedBox(
            width: 85,
            child: Center(
              child: Text(
                'Tiết / Giờ',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),

          // Các cột ngày
          ...days.map((dayMap) {
            final val = dayMap['val'] as int;
            final label = dayMap['label'] as String;
            final isToday = val == currentDayTTN;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF2563EB) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: isToday ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    if (isToday)
                      const Text(
                        'Hôm nay',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFBFDBFE),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Hàng cho từng Tiết học kèm các khối môn học
  Widget _buildPeriodRow({
    required int period,
    required String timeRange,
    required List<Map<String, dynamic>> days,
    required Map<String, Map<String, Color>> courseColors,
    required BuildContext context,
  }) {
    return SizedBox(
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cột tiết cố định bên trái kèm khung giờ thực tế
          Container(
            width: 85,
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tiết $period',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeRange,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Các ô theo ngày
          ...days.map((dayMap) {
            final day = dayMap['val'] as int;

            // Tìm lớp học phần nào đang diễn ra ở tiết này
            CourseSection? matchedSection;
            TimeSlot? matchedSlot;
            bool isFirstPeriodOfSlot = false;

            for (final section in sections) {
              for (final slot in section.slots) {
                if (slot.dayOfWeek == day) {
                  if (period >= slot.startPeriod && period <= slot.endPeriod) {
                    matchedSection = section;
                    matchedSlot = slot;
                    if (period == slot.startPeriod) {
                      isFirstPeriodOfSlot = true;
                    }
                    break;
                  }
                }
              }
              if (matchedSection != null) break;
            }

            if (matchedSection == null || matchedSlot == null) {
              return Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                  ),
                ),
              );
            }

            final colors = courseColors[matchedSection.courseId] ?? _palette[0];

            return Expanded(
              child: Container(
                margin: const EdgeInsets.all(2),
                child: _buildClassBlock(
                  section: matchedSection,
                  slot: matchedSlot,
                  colors: colors,
                  isHeader: isFirstPeriodOfSlot,
                  context: context,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Khối lớp học phần: Bo góc 10px, màu pastel tinh tế, viền trái đậm màu tạo điểm nhấn
  Widget _buildClassBlock({
    required CourseSection section,
    required TimeSlot slot,
    required Map<String, Color> colors,
    required bool isHeader,
    required BuildContext context,
  }) {
    return InkWell(
      onTap: () {
        if (onSectionTap != null) {
          onSectionTap!(section, slot);
        } else {
          _showSectionModal(context, section, slot, colors);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: colors['bg'],
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: colors['border']!, width: 3.5), // Viền trái đậm màu
            top: BorderSide(color: colors['border']!.withValues(alpha: 0.2)),
            right: BorderSide(color: colors['border']!.withValues(alpha: 0.2)),
            bottom: BorderSide(color: colors['border']!.withValues(alpha: 0.2)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tên môn học
            Text(
              section.courseName,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: colors['text'],
                height: 1.15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Mã lớp & Phòng học có icon location_on
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 11, color: colors['border']),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    'P.${slot.room}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors['text'],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Tên giảng viên
            Text(
              section.lecturer,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: colors['text']!.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showSectionModal(
    BuildContext context,
    CourseSection section,
    TimeSlot slot,
    Map<String, Color> colors,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors['border'],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      section.courseName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Mã lớp học phần: ${section.classId}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildModalRow(Icons.person_outline_rounded, 'Giảng viên', section.lecturer),
              _buildModalRow(
                Icons.access_time_rounded,
                'Khung giờ',
                '${slot.dayName}, Tiết ${slot.startPeriod}-${slot.endPeriod} (${slot.estimatedTimeString})',
              ),
              _buildModalRow(Icons.location_on_outlined, 'Phòng học', 'Phòng ${slot.room}'),
              _buildModalRow(
                Icons.groups_outlined,
                'Sĩ số',
                '${section.enrolled} / ${section.capacity} SV (${section.capacity - section.enrolled} chỗ còn trống)',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Đóng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
