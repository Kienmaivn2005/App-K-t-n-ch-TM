import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../providers/planner_provider.dart';
import '../../services/ical_export_service.dart';
import '../../services/ttn_database.dart';
import '../theme/app_theme.dart';
import '../widgets/conflict_banner.dart';
import '../widgets/stat_cards.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SingleTickerProviderStateMixin {
  bool _isGridView = true;
  bool _useTtnOfficialSchedule = true; // Mặc định hiển thị đúng 100% thời khóa biểu thực tế trên portal TTN
  final GlobalKey _timetableRepaintKey = GlobalKey();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _exportTimetableToImage() async {
    try {
      final boundary = _timetableRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.image_rounded, color: AppTheme.primary, size: 24),
              SizedBox(width: 8),
              Text('Ảnh Thời Khóa Biểu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (bytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(bytes, height: 260, fit: BoxFit.contain),
                ),
              const SizedBox(height: 12),
              const Text(
                'Ảnh thời khóa biểu đã được kết xuất độ phân giải cao (2.5x HD), sẵn sàng chia sẻ story hoặc đặt làm hình nền điện thoại!',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                textAlign: TextAlign.center,
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
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xuất ảnh thời khóa biểu thành công!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Lưu ảnh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xuất ảnh: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final activePlan = planner.activePlan;

    // Lấy lịch học: Ưu tiên dữ liệu thực tế từ cổng ttn.edu.vn của sinh viên (chỉ có các ca học thật, không tự bịa thêm ca chiều)
    final List<ClassSection> sections;
    if (_useTtnOfficialSchedule) {
      sections = _getOfficialTtnSections(planner.profile.studentId);
    } else {
      sections = activePlan.selectedSections.values.toList();
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSectionDialog(context, planner),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Thêm Môn Vào TKB', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppTheme.primary,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          const StatCardsHeader(),
          const ConflictBanner(),
          // Plan Switcher & View Toggle Toolbar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: planner.activePlanId,
                      isExpanded: true,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.slate900,
                        fontSize: 14,
                      ),
                      items: planner.plans.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.name} (${p.selectedSections.length} môn)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) planner.switchPlan(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Toggle Grid / List
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.grid_view_rounded, size: 16),
                      tooltip: 'Lưới tuần',
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.view_agenda_rounded, size: 16),
                      tooltip: 'Danh sách ngày',
                    ),
                  ],
                  selected: {_isGridView},
                  onSelectionChanged: (val) {
                    setState(() {
                      _isGridView = val.first;
                    });
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          // Quick Switch Plan Pills & Course Hunting Actions
          Container(
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Tab chuyển đổi: Lịch TTN Thực Tế vs Kịch bản Giả Lập
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(
                      Icons.verified_user_rounded,
                      size: 15,
                      color: _useTtnOfficialSchedule ? Colors.white : const Color(0xFF0284C7),
                    ),
                    label: Text(
                      'Lịch TTN Thực Tế (${planner.profile.fullName})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _useTtnOfficialSchedule ? FontWeight.bold : FontWeight.w600,
                        color: _useTtnOfficialSchedule ? Colors.white : const Color(0xFF0284C7),
                      ),
                    ),
                    selected: _useTtnOfficialSchedule,
                    selectedColor: const Color(0xFF1E3A8A),
                    backgroundColor: const Color(0xFFE0F2FE),
                    onSelected: (_) => setState(() => _useTtnOfficialSchedule = true),
                  ),
                ),
                ...planner.plans.map((p) {
                  final isSelected = !_useTtnOfficialSchedule && p.id == planner.activePlanId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${p.name} (${p.selectedSections.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppTheme.slate700,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      backgroundColor: Colors.white,
                      onSelected: (_) {
                        setState(() => _useTtnOfficialSchedule = false);
                        planner.switchPlan(p.id);
                      },
                    ),
                  );
                }),
                if (sections.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  ActionChip(
                    avatar: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF0F172A)),
                    label: const Text(
                      'Copy mã lớp',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    backgroundColor: const Color(0xFFE2E8F0),
                    onPressed: () {
                      final codes = sections.map((s) => s.id).join(' ');
                      Clipboard.setData(ClipboardData(text: codes));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã copy ${sections.length} mã lớp: $codes'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.camera_alt_rounded, size: 14, color: Color(0xFF7C3AED)),
                    label: const Text(
                      'Tải ảnh TKB',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                    ),
                    backgroundColor: const Color(0xFFF3E8FF),
                    onPressed: _exportTimetableToImage,
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.event_available_rounded, size: 14, color: Colors.blue),
                    label: const Text(
                      'Xuất .ics',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    backgroundColor: const Color(0xFFEFF6FF),
                    onPressed: () {
                      final ics = IcalExportService.generateIcsContent(
                        planName: activePlan.name,
                        sections: sections,
                      );
                      Clipboard.setData(ClipboardData(text: ics));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã xuất file .ics!'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Timetable content
          Expanded(
            child: sections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note_rounded, size: 64, color: AppTheme.slate300),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa có học phần nào trong kế hoạch này',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hãy vào tab "Tra cứu Môn học" hoặc dùng "AI Tự động Xếp lịch"',
                          style: TextStyle(color: AppTheme.slate500, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : RepaintBoundary(
                    key: _timetableRepaintKey,
                    child: Container(
                      color: Colors.white,
                      child: _isGridView
                          ? _buildGridTimetable(context, planner, sections)
                          : _buildListTimetable(context, planner, sections),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridTimetable(BuildContext context, PlannerProvider planner, List<ClassSection> sections) {
    // 7 days: Thứ 2 (2) -> Chủ Nhật (8)
    const days = [
      (2, 'Thứ 2'),
      (3, 'Thứ 3'),
      (4, 'Thứ 4'),
      (5, 'Thứ 5'),
      (6, 'Thứ 6'),
      (7, 'Thứ 7'),
      (8, 'Chủ Nhật'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - 60) / 7;
        final clampedCellWidth = cellWidth < 120 ? 120.0 : cellWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Days of week
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppTheme.slate100,
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(14)),
                        ),
                        child: const Text(
                          'Tiết',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.slate600),
                        ),
                      ),
                      ...days.map((d) {
                        return Container(
                          width: clampedCellWidth,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: d.$1 >= 7 ? AppTheme.slate100.withValues(alpha: 0.5) : AppTheme.slate100,
                            border: const Border(left: BorderSide(color: AppTheme.slate200)),
                          ),
                          child: Text(
                            d.$2,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: d.$1 >= 7 ? AppTheme.slate500 : AppTheme.slate800,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  // 12 Periods Rows
                  ...List.generate(12, (periodIndex) {
                    final period = periodIndex + 1;
                    final periodInfo = PeriodTimeInfo.standardPeriods[periodIndex];
                    final isMorningEnd = period == 5;
                    final isAfternoonEnd = period == 10;

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: const BorderSide(color: AppTheme.slate200),
                          bottom: (isMorningEnd || isAfternoonEnd)
                              ? const BorderSide(color: AppTheme.slate300, width: 2)
                              : BorderSide.none,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Period number & time column
                          Container(
                            width: 60,
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppTheme.slate50,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'T$period',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.slate700),
                                ),
                                Text(
                                  periodInfo.start,
                                  style: const TextStyle(fontSize: 9.5, color: AppTheme.slate400),
                                ),
                              ],
                            ),
                          ),
                          // 7 days columns for this period
                          ...days.map((d) {
                            final dayNum = d.$1;
                            // Find all sections that occupy this day and period
                            final matchingSections = <(ClassSection, ScheduleSlot)>[];
                            for (final sec in sections) {
                              for (final slot in sec.slots) {
                                if (slot.dayOfWeek == dayNum && period >= slot.startPeriod && period <= slot.endPeriod) {
                                  matchingSections.add((sec, slot));
                                }
                              }
                            }

                            final hasConflict = matchingSections.length > 1;

                            if (matchingSections.isEmpty) {
                              return Container(
                                width: clampedCellWidth,
                                height: 52,
                                decoration: BoxDecoration(
                                  border: const Border(left: BorderSide(color: AppTheme.slate200)),
                                  color: dayNum >= 7 ? AppTheme.slate50.withValues(alpha: 0.4) : Colors.white,
                                ),
                              );
                            }

                            // Render occupied cell: Hợp nhất (Span) khối môn học liền mạch, chỉ hiển thị thông tin ở tiết bắt đầu
                            return Container(
                              width: clampedCellWidth,
                              height: 52,
                              decoration: BoxDecoration(
                                border: const Border(left: BorderSide(color: AppTheme.slate200)),
                                color: hasConflict ? AppTheme.dangerLight : Colors.white,
                              ),
                              child: Stack(
                                children: matchingSections.map((item) {
                                  final sec = item.$1;
                                  final slot = item.$2;
                                  final isStart = period == slot.startPeriod;
                                  final isEnd = period == slot.endPeriod;
                                  final baseColor = hasConflict ? AppTheme.danger : Color(sec.colorHex);

                                  return Positioned.fill(
                                    child: InkWell(
                                      onTap: () => _showSectionActionDialog(context, planner, sec),
                                      child: AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Container(
                                            margin: EdgeInsets.only(
                                              left: 3,
                                              right: 3,
                                              top: isStart ? 3 : 0,
                                              bottom: isEnd ? 3 : 0,
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: hasConflict
                                                  ? AppTheme.danger.withValues(alpha: _pulseAnimation.value)
                                                  : baseColor.withValues(alpha: 0.92),
                                              borderRadius: BorderRadius.vertical(
                                                top: isStart ? const Radius.circular(8) : Radius.zero,
                                                bottom: isEnd ? const Radius.circular(8) : Radius.zero,
                                              ),
                                              border: Border.all(
                                                color: hasConflict ? Colors.yellowAccent : baseColor,
                                                width: hasConflict ? 2.0 : 1.5,
                                              ),
                                              boxShadow: hasConflict
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.red.withValues(alpha: 0.5),
                                                        blurRadius: 6,
                                                        spreadRadius: 1,
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: isStart
                                                ? Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          if (hasConflict) ...[
                                                            const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.yellowAccent),
                                                            const SizedBox(width: 3),
                                                          ],
                                                          Expanded(
                                                            child: Text(
                                                              sec.courseName,
                                                              style: TextStyle(
                                                                color: hasConflict ? Colors.yellowAccent : Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 11,
                                                                height: 1.15,
                                                              ),
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        hasConflict
                                                            ? '⚠️ TRÙNG LỊCH: ${sec.id}'
                                                            : '${slot.room} • ${sec.lecturer}',
                                                        style: TextStyle(
                                                          color: hasConflict ? Colors.white : Colors.white70,
                                                          fontSize: 9.5,
                                                          fontWeight: hasConflict ? FontWeight.bold : FontWeight.normal,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  )
                                                : (period == slot.startPeriod + 1 && slot.periodCount > 2
                                                    ? Text(
                                                        hasConflict ? '⚠️ ĐÈ LỊCH' : '(${sec.courseCode})',
                                                        style: TextStyle(
                                                          color: hasConflict ? Colors.yellowAccent : Colors.white60,
                                                          fontSize: 9,
                                                          fontWeight: hasConflict ? FontWeight.bold : FontWeight.normal,
                                                        ),
                                                      )
                                                    : const SizedBox.shrink()),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListTimetable(BuildContext context, PlannerProvider planner, List<ClassSection> sections) {
    const days = [
      (2, 'Thứ 2'),
      (3, 'Thứ 3'),
      (4, 'Thứ 4'),
      (5, 'Thứ 5'),
      (6, 'Thứ 6'),
      (7, 'Thứ 7'),
      (8, 'Chủ Nhật'),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: days.map((d) {
        final dayNum = d.$1;
        final dayName = d.$2;

        final daySlots = <(ClassSection, ScheduleSlot)>[];
        for (final sec in sections) {
          for (final slot in sec.slots) {
            if (slot.dayOfWeek == dayNum) {
              daySlots.add((sec, slot));
            }
          }
        }

        // Sort by start period
        daySlots.sort((a, b) => a.$2.startPeriod.compareTo(b.$2.startPeriod));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: daySlots.isEmpty ? AppTheme.slate50 : AppTheme.primaryLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: daySlots.isEmpty ? AppTheme.slate500 : AppTheme.primary,
                      ),
                    ),
                    Text(
                      daySlots.isEmpty ? 'Nghỉ học' : '${daySlots.length} ca học',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: daySlots.isEmpty ? AppTheme.slate400 : AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (daySlots.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Không có lịch học trong ngày này', style: TextStyle(color: AppTheme.slate400, fontSize: 13)),
                )
              else
                ...daySlots.map((item) {
                  final sec = item.$1;
                  final slot = item.$2;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppTheme.slate200)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(sec.colorHex),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${sec.courseCode} - ${sec.courseName} (${sec.id})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Tiết ${slot.startPeriod}-${slot.endPeriod} (${slot.timeFormatted}) • Phòng: ${slot.room} • ${sec.campus}',
                                style: TextStyle(color: AppTheme.slate600, fontSize: 12),
                              ),
                              Text(
                                'Giảng viên: ${sec.lecturer} (${sec.lecturerRating}★)',
                                style: TextStyle(color: AppTheme.slate500, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert_rounded, size: 20),
                          onPressed: () => _showSectionActionDialog(context, planner, sec),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showSectionActionDialog(BuildContext context, PlannerProvider planner, ClassSection sec) {
    final course = planner.getCourseByCode(sec.courseCode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${sec.courseCode} - ${sec.courseName}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Lớp học phần: ${sec.id} • ${course?.credits ?? 3} Tín chỉ',
                          style: TextStyle(color: AppTheme.slate600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(height: 24),
              // Thông tin giảng viên & sĩ số lớp học phần
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_rounded, size: 14, color: AppTheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Giảng viên: ${sec.lecturer}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Đánh giá SV: ${sec.lecturerRating} ★ (${sec.lecturerRating >= 4.8 ? "Rất yêu thích" : "Tận tâm"})',
                            style: const TextStyle(color: Color(0xFFD97706), fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (sec.capacity - sec.enrolled) <= 5
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Còn ${sec.capacity - sec.enrolled} chỗ',
                            style: TextStyle(
                              color: (sec.capacity - sec.enrolled) <= 5
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${sec.enrolled}/${sec.capacity} SV',
                            style: TextStyle(
                              color: (sec.capacity - sec.enrolled) <= 5
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Schedule summary
              const Text('Khung giờ & Phòng học:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              ...sec.slots.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.meeting_room_rounded, size: 16, color: Color(0xFF0284C7)),
                      const SizedBox(width: 8),
                      Text(
                        '${s.dayName}: Tiết ${s.startPeriod}-${s.endPeriod} (${s.timeFormatted}) tại ${s.room}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 14),
              // Option to switch to another section of the same course
              if (course != null && course.sections.length > 1) ...[
                const Text('Đổi sang lớp học phần khác của môn này:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: course.sections.map((otherSec) {
                    final isCurrent = otherSec.id == sec.id;
                    return ActionChip(
                      avatar: isCurrent ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      backgroundColor: isCurrent ? AppTheme.primary : AppTheme.slate100,
                      label: Text(
                        '${otherSec.id} (${otherSec.lecturer})',
                        style: TextStyle(
                          color: isCurrent ? Colors.white : AppTheme.slate800,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () {
                        planner.selectSection(otherSec);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã đổi sang lớp ${otherSec.id}')),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              // Edit details button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                  label: const Text('Sửa Thông Tin / Phòng Học Của Lớp Này'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showEditSectionDetailsDialog(context, planner, sec);
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Remove button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.delete_rounded, size: 18),
                  label: const Text('Hủy / Xóa môn này khỏi Thời khóa biểu'),
                  onPressed: () {
                    _confirmDeleteSection(context, planner, sec);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteSection(BuildContext context, PlannerProvider planner, ClassSection sec) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hủy Môn Khỏi TKB?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn hủy môn "${sec.courseName}" (${sec.courseCode}) khỏi thời khóa biểu hiện tại?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy bỏ')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              planner.removeSection(sec.courseCode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã gỡ môn ${sec.courseName} khỏi thời khóa biểu'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }

  void _showEditSectionDetailsDialog(BuildContext context, PlannerProvider planner, ClassSection sec) {
    final formKey = GlobalKey<FormState>();
    final lecturerCtrl = TextEditingController(text: sec.lecturer);
    final roomCtrl = TextEditingController(text: sec.slots.firstOrNull?.room ?? '6.11');
    final dayOfWeekCtrl = TextEditingController(text: (sec.slots.firstOrNull?.dayOfWeek ?? 2).toString());
    final startPeriodCtrl = TextEditingController(text: (sec.slots.firstOrNull?.startPeriod ?? 1).toString());
    final endPeriodCtrl = TextEditingController(text: (sec.slots.firstOrNull?.endPeriod ?? 4).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit_calendar_rounded, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text('Sửa Ca Học: ${sec.courseCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Học phần: ${sec.courseName} (${sec.id})',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.slate700),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: lecturerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Giảng viên phụ trách *',
                    prefixIcon: Icon(Icons.person_outline, size: 18),
                    isDense: true,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên giảng viên' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phòng học (Ví dụ: 6.11, 2.4, 7.3.18) *',
                    prefixIcon: Icon(Icons.meeting_room_outlined, size: 18),
                    isDense: true,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nhập phòng học' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: dayOfWeekCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Thứ (2 -> 7) *',
                          prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                          isDense: true,
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 2 || n > 8) return '2-8';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: startPeriodCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tiết bắt đầu *',
                          isDense: true,
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1 || n > 12) return '1-12';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: endPeriodCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tiết kết thúc *',
                          isDense: true,
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1 || n > 12) return '1-12';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final dayOfWeek = int.parse(dayOfWeekCtrl.text.trim());
              final startP = int.parse(startPeriodCtrl.text.trim());
              final endP = int.parse(endPeriodCtrl.text.trim());

              final updatedSection = ClassSection(
                id: sec.id,
                courseCode: sec.courseCode,
                courseName: sec.courseName,
                lecturer: lecturerCtrl.text.trim(),
                lecturerRating: sec.lecturerRating,
                capacity: sec.capacity,
                enrolled: sec.enrolled,
                slots: [
                  ScheduleSlot(
                    dayOfWeek: dayOfWeek,
                    startPeriod: startP,
                    endPeriod: endP,
                    room: roomCtrl.text.trim(),
                  ),
                ],
                campus: sec.campus,
                colorHex: sec.colorHex,
              );

              // Cập nhật vào phương án
              planner.selectSection(updatedSection);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã cập nhật ca học: ${sec.courseName} (Thứ $dayOfWeek, Tiết $startP-$endP)'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            child: const Text('Lưu Thay Đổi'),
          ),
        ],
      ),
    );
  }

  void _showAddSectionDialog(BuildContext context, PlannerProvider planner) {
    final availableCourses = planner.courses;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_task_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Thêm Môn Vào Thời Khóa Biểu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 520,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn một học phần từ danh mục để xếp vào thời khóa biểu hiện tại:',
                style: TextStyle(fontSize: 12.5, color: AppTheme.slate600),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: availableCourses.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = availableCourses[index];
                    final isEnrolled = planner.isCourseSelected(c.code);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: isEnrolled ? AppTheme.successLight : AppTheme.primaryLight,
                        child: Text('${c.credits}T', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isEnrolled ? AppTheme.success : AppTheme.primary)),
                      ),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      subtitle: Text(
                        '${c.code} • ${c.department} • ${c.sections.length} lớp học phần',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.slate500),
                      ),
                      trailing: isEnrolled
                          ? const Chip(
                              label: Text('Đang chọn', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                              backgroundColor: AppTheme.success,
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                textStyle: const TextStyle(fontSize: 11.5),
                              ),
                              onPressed: () {
                                if (c.sections.isNotEmpty) {
                                  planner.selectSection(c.sections.first);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã thêm môn ${c.name} vào Thời khóa biểu!'),
                                      backgroundColor: AppTheme.success,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Thêm vào TKB'),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  /// Trích xuất danh sách lớp học phần chuẩn 100% từ dữ liệu thực tế máy chủ TTN
  List<ClassSection> _getOfficialTtnSections(String studentId) {
    final ttnStudent = TTNDatabase.getStudent(studentId);
    if (ttnStudent == null) return [];

    final rawSlots = ttnStudent['slots'] as List<dynamic>? ?? [];
    final Map<String, ClassSection> sectionMap = {};

    const palette = [
      0xFF0284C7, 0xFF0D9488, 0xFF8B5CF6, 0xFFEA580C,
      0xFF059669, 0xFFD97706, 0xFFE11D48, 0xFF4F46E5,
    ];

    for (final raw in rawSlots) {
      final slot = raw as Map<String, dynamic>;
      final courseName = slot['courseName'] as String? ?? 'Học phần';
      final lecturer = slot['lecturer'] as String? ?? 'Chưa rõ';
      final room = slot['room'] as String? ?? 'Chưa rõ';
      final dayIndex = slot['dayIndex'] as int? ?? 2;
      final periodStr = slot['period'] as String? ?? '1-4';

      int startP = 1;
      int endP = 4;
      if (periodStr.contains('-')) {
        final p = periodStr.split('-');
        startP = int.tryParse(p[0]) ?? 1;
        endP = int.tryParse(p[1]) ?? 4;
      }

      final scheduleSlot = ScheduleSlot(
        dayOfWeek: dayIndex,
        startPeriod: startP,
        endPeriod: endP,
        room: room,
      );

      if (sectionMap.containsKey(courseName)) {
        final existing = sectionMap[courseName]!;
        sectionMap[courseName] = ClassSection(
          id: existing.id,
          courseCode: existing.courseCode,
          courseName: existing.courseName,
          lecturer: existing.lecturer,
          slots: [...existing.slots, scheduleSlot],
          colorHex: existing.colorHex,
        );
      } else {
        final color = palette[courseName.hashCode.abs() % palette.length];
        sectionMap[courseName] = ClassSection(
          id: courseName,
          courseCode: courseName,
          courseName: courseName,
          lecturer: lecturer,
          slots: [scheduleSlot],
          colorHex: color,
        );
      }
    }

    return sectionMap.values.toList();
  }
}
