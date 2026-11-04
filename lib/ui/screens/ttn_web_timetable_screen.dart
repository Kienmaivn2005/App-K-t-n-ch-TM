import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../providers/planner_provider.dart';
import '../../services/ical_export_service.dart';
import '../../services/ttn_database.dart';
import 'ai_advisor_screen.dart';
import 'auto_scheduler_screen.dart';
import 'course_catalog_screen.dart';
import 'gpa_simulator_screen.dart';
import 'modern_mobile_timetable_screen.dart';
import 'plan_manager_screen.dart';
import 'prerequisite_roadmap_screen.dart';
import 'taynguyen_portal_screen.dart';
import 'tuition_screen.dart';

class TtnWebTimetableScreen extends StatefulWidget {
  final String? studentId;
  const TtnWebTimetableScreen({super.key, this.studentId});

  @override
  State<TtnWebTimetableScreen> createState() => _TtnWebTimetableScreenState();
}

class _TtnWebTimetableScreenState extends State<TtnWebTimetableScreen> {
  late TextEditingController _studentIdController;
  final ScrollController _scrollController = ScrollController();
  bool _isModernView = false; // Mặc định hiển thị Lưới Web Trường chuẩn ttn.edu.vn
  int _selectedWeekIndex = 0; // Tuần 1 đang chọn mặc định

  static const List<(String, List<(String, String)>)> _kAllWeeks = [
    (
      'Từ ngày 19/10/2026 đến ngày 25/10/2026',
      [
        ('Thứ 2', '19/10'),
        ('Thứ 3', '20/10'),
        ('Thứ 4', '21/10'),
        ('Thứ 5', '22/10'),
        ('Thứ 6', '23/10'),
        ('Thứ 7', '24/10'),
        ('CN', '25/10'),
      ],
    ),
    (
      'Từ ngày 26/10/2026 đến ngày 01/11/2026',
      [
        ('Thứ 2', '26/10'),
        ('Thứ 3', '27/10'),
        ('Thứ 4', '28/10'),
        ('Thứ 5', '29/10'),
        ('Thứ 6', '30/10'),
        ('Thứ 7', '31/10'),
        ('CN', '01/11'),
      ],
    ),
    (
      'Từ ngày 02/11/2026 đến ngày 08/11/2026',
      [
        ('Thứ 2', '02/11'),
        ('Thứ 3', '03/11'),
        ('Thứ 4', '04/11'),
        ('Thứ 5', '05/11'),
        ('Thứ 6', '06/11'),
        ('Thứ 7', '07/11'),
        ('CN', '08/11'),
      ],
    ),
    (
      'Từ ngày 09/11/2026 đến ngày 15/11/2026',
      [
        ('Thứ 2', '09/11'),
        ('Thứ 3', '10/11'),
        ('Thứ 4', '11/11'),
        ('Thứ 5', '12/11'),
        ('Thứ 6', '13/11'),
        ('Thứ 7', '14/11'),
        ('CN', '15/11'),
      ],
    ),
    (
      'Từ ngày 16/11/2026 đến ngày 22/11/2026',
      [
        ('Thứ 2', '16/11'),
        ('Thứ 3', '17/11'),
        ('Thứ 4', '18/11'),
        ('Thứ 5', '19/11'),
        ('Thứ 6', '20/11'),
        ('Thứ 7', '21/11'),
        ('CN', '22/11'),
      ],
    ),
    (
      'Từ ngày 23/11/2026 đến ngày 29/11/2026',
      [
        ('Thứ 2', '23/11'),
        ('Thứ 3', '24/11'),
        ('Thứ 4', '25/11'),
        ('Thứ 5', '26/11'),
        ('Thứ 6', '27/11'),
        ('Thứ 7', '28/11'),
        ('CN', '29/11'),
      ],
    ),
    (
      'Từ ngày 30/11/2026 đến ngày 06/12/2026',
      [
        ('Thứ 2', '30/11'),
        ('Thứ 3', '01/12'),
        ('Thứ 4', '02/12'),
        ('Thứ 5', '03/12'),
        ('Thứ 6', '04/12'),
        ('Thứ 7', '05/12'),
        ('CN', '06/12'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    final profile = context.read<PlannerProvider>().profile;
    final initialId = (widget.studentId != null && widget.studentId!.trim().isNotEmpty)
        ? widget.studentId!.trim()
        : profile.studentId;
    _studentIdController = TextEditingController(text: initialId);
  }

  @override
  void didUpdateWidget(covariant TtnWebTimetableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.studentId != null &&
        widget.studentId!.trim().isNotEmpty &&
        widget.studentId != oldWidget.studentId) {
      _studentIdController.text = widget.studentId!.trim();
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch(PlannerProvider planner) {
    final query = _studentIdController.text.trim();
    if (query.isNotEmpty) {
      final ttnStudent = TTNDatabase.getStudent(query);
      if (ttnStudent != null) {
        planner.updateProfile(planner.profile.copyWith(
          studentId: query,
          fullName: ttnStudent['fullName'] as String,
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tìm thấy sinh viên: ${ttnStudent['fullName']} (MSSV: $query)'),
            backgroundColor: const Color(0xFF1E3A8A),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        planner.updateProfile(planner.profile.copyWith(studentId: query));
      }
    }
  }

  void _showStudentListDialog(BuildContext context, PlannerProvider planner) {
    String filter = '';
    int statusFilter = 1; // 1: Đang học (31 SV), 0: Đã nghỉ học (13 SV), -1: Tất cả (44 SV)

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final activeStudents = TTNDatabase.getActiveStudents();
          final inactiveStudents = TTNDatabase.getInactiveStudents();
          final allStudents = TTNDatabase.getAllStudents();

          final sourceList = statusFilter == 1
              ? activeStudents
              : (statusFilter == 0 ? inactiveStudents : allStudents);

          final filtered = sourceList.where((s) {
            final id = (s['studentId'] as String).toLowerCase();
            final name = (s['fullName'] as String).toLowerCase();
            return id.contains(filter.toLowerCase()) || name.contains(filter.toLowerCase());
          }).toList();

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.school, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusFilter == 1
                        ? 'Danh sách Sinh viên CNTT K23 (Đang học: ${activeStudents.length})'
                        : (statusFilter == 0
                            ? 'Danh sách Sinh viên đã nghỉ học (${inactiveStudents.length})'
                            : 'Toàn bộ sinh viên K23 (${allStudents.length})'),
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              height: 460,
              child: Column(
                children: [
                  // Filter Status Tabs
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text('Đang học (${activeStudents.length})', style: const TextStyle(fontSize: 11.5)),
                        selected: statusFilter == 1,
                        selectedColor: const Color(0xFFDBEAFE),
                        onSelected: (_) => setDlgState(() => statusFilter = 1),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: Text('Đã nghỉ (${inactiveStudents.length})', style: const TextStyle(fontSize: 11.5)),
                        selected: statusFilter == 0,
                        selectedColor: const Color(0xFFFEE2E2),
                        onSelected: (_) => setDlgState(() => statusFilter = 0),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: Text('Tất cả (${allStudents.length})', style: const TextStyle(fontSize: 11.5)),
                        selected: statusFilter == -1,
                        selectedColor: const Color(0xFFE2E8F0),
                        onSelected: (_) => setDlgState(() => statusFilter = -1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên hoặc MSSV...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) {
                      setDlgState(() {
                        filter = val;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final s = filtered[idx];
                        final isCurrent = s['studentId'] == planner.profile.studentId;
                        final slotsCount = (s['slotsCount'] as int? ?? 0);
                        final isActive = slotsCount > 0;

                        return ListTile(
                          dense: true,
                          tileColor: isCurrent ? const Color(0xFFEFF6FF) : null,
                          title: Row(
                            children: [
                              Text(
                                '${s['studentId']} - ${s['fullName']}',
                                style: TextStyle(
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                  color: isCurrent ? const Color(0xFF1D4ED8) : Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isActive ? 'Đang học ($slotsCount ca)' : 'Đã nghỉ học',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Ngành: ${s['major']} ${s['cohort']}',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          trailing: isCurrent
                              ? const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 18)
                              : const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                          onTap: () {
                            _studentIdController.text = s['studentId'];
                            planner.updateProfile(planner.profile.copyWith(
                              studentId: s['studentId'],
                              fullName: s['fullName'],
                            ));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã chọn sinh viên: ${s['fullName']} (${s['studentId']})'),
                                backgroundColor: const Color(0xFF1E3A8A),
                              ),
                            );
                          },
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final profile = planner.profile;
    final activeSections = planner.activePlan.selectedSections.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildUniversityBanner(planner),
                _buildWebsiteNavBar(planner),
                const SizedBox(height: 12),
                _buildMainContent(planner, profile, activeSections),
                const SizedBox(height: 120),
              ],
            ),
          ),
          // Scroll to top floating button (matches bottom right ^ button in screenshot)
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.small(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              tooltip: 'Cuộn lên đầu trang',
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
              child: const Icon(Icons.keyboard_arrow_up, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  // Modern University Header Banner
  Widget _buildUniversityBanner(PlannerProvider planner) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 780;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Logo and title
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF59E0B), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.school, size: 22, color: Color(0xFFD97706)),
                          const Text('1977', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                          const Text('TNU', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'BỘ GIÁO DỤC VÀ ĐÀO TẠO',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF93C5FD), letterSpacing: 0.8),
                      ),
                      const Text(
                        'TRƯỜNG ĐẠI HỌC TÂY NGUYÊN',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Text(
                          'TÂM HUYẾT - TRÁCH NHIỆM - SÁNG TẠO - HỘI NHẬP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFDE047),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Right: System Badge
              if (!isNarrow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFFFDE047), size: 15),
                          SizedBox(width: 6),
                          Text('UniPlan AI 2026', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('Hệ thống Lập Kế Hoạch Tín Chỉ Thông Minh', style: TextStyle(color: Colors.blue.shade100, fontSize: 10.5)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Website Navbar Menu exactly matching the official TTN website (ttn.edu.vn)
  Widget _buildWebsiteNavBar(PlannerProvider planner) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. HOME
            _buildDirectNavButton(
              title: 'HOME',
              icon: Icons.home,
              onTap: () {
                _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đang ở Trang chủ Tra cứu Thời khóa biểu ĐH Tây Nguyên'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            // 2. GIỚI THIỆU ▾
            _buildDropdownNavButton(
              title: 'GIỚI THIỆU ▾',
              items: const [
                ('gt_overview', Icons.school, 'Tổng quan Trường ĐH Tây Nguyên'),
                ('gt_mission', Icons.flag, 'Sứ mạng - Tầm nhìn - Triết lý GD'),
                ('gt_leaders', Icons.groups, 'Ban Giám hiệu & Lãnh đạo Trường'),
              ],
              onSelected: (val) => _handleNavSelection(context, planner, val),
            ),
            // 3. ĐƠN VỊ ▾
            _buildDropdownNavButton(
              title: 'ĐƠN VỊ ▾',
              items: const [
                ('dv_cntt', Icons.computer, 'Khoa KHTN & Công nghệ (Bộ môn CNTT)'),
                ('dv_daotao', Icons.account_balance, 'Phòng Đào tạo Đại học'),
                ('dv_ctsv', Icons.person_pin, 'Phòng Công tác Sinh viên'),
              ],
              onSelected: (val) => _handleNavSelection(context, planner, val),
            ),
            // 4. VĂN BẢN ▾
            _buildDropdownNavButton(
              title: 'VĂN BẢN ▾',
              items: const [
                ('vb_regulations', Icons.description, 'Quy chế Đào tạo Tín chỉ (12 - 24 TC)'),
                ('vb_scholarship', Icons.card_giftcard, 'Quy định Học bổng & Miễn giảm học phí'),
              ],
              onSelected: (val) => _handleNavSelection(context, planner, val),
            ),
            // 5. SINH VIÊN ▾ (Active / Highlighted in Blue)
            _buildDropdownNavButton(
              title: 'SINH VIÊN ▾',
              isBlue: true,
              items: const [
                ('sv_tkb', Icons.calendar_today, '🗓 Tra cứu Thời khóa biểu (Hiện tại)'),
                ('sv_mobile', Icons.phone_iphone, '📱 App Mobile Thời khóa biểu Hiện đại (Mẫu)'),
                ('sv_portal', Icons.web, '🖥 Cổng Đăng ký Tín chỉ & Học tập'),
                ('sv_advisor', Icons.psychology, '🤖 Trợ lý AI Cố vấn Học tập TTN'),
                ('sv_roadmap', Icons.alt_route, '🗺️ Sơ đồ Lộ trình 8 Học kỳ & Tiên quyết'),
                ('sv_gpa', Icons.calculate, '📊 Giả lập GPA & Cảnh báo Học vụ'),
                ('sv_ai', Icons.auto_awesome, '⚡ Thuật toán Xếp lịch Tối ưu UniPlan'),
                ('sv_catalog', Icons.menu_book, '📚 Tra cứu Danh mục Học phần'),
                ('sv_tuition', Icons.payments, '💰 Ước tính Học phí & Thống kê Tín chỉ'),
                ('sv_students', Icons.people, '👥 44 Sinh viên CNTT K23 TTN'),
              ],
              onSelected: (val) => _handleNavSelection(context, planner, val),
            ),
            // 6. TUYỂN SINH
            _buildDirectNavButton(
              title: 'TUYỂN SINH',
              onTap: () => _handleNavSelection(context, planner, 'tuyen_sinh'),
            ),
            // 7. ĐÀO TẠO ▾
            _buildDropdownNavButton(
              title: 'ĐÀO TẠO ▾',
              items: const [
                ('dt_curriculum', Icons.school, 'Chương trình Cử nhân CNTT (145 TC)'),
                ('dt_prerequisite', Icons.account_tree, 'Sơ đồ Cây môn tiên quyết'),
                ('dt_calendar', Icons.calendar_month, 'Kế hoạch năm học 2026 - 2027'),
              ],
              onSelected: (val) => _handleNavSelection(context, planner, val),
            ),
            // 8. KHCN ▾
            _buildDropdownNavButton(
              title: 'KHCN ▾',
              items: const [
                ('khcn_research', Icons.science, 'Nghiên cứu khoa học SV năm 2026'),
                ('khcn_club', Icons.code, 'Câu lạc bộ Tin học & Lập trình TNU'),
              ],
              onSelected: (val) => _handleNavSelection(context, planner, val),
            ),
            // 9. THÔNG BÁO ▾
            _buildDropdownNavButton(
              title: 'THÔNG BÁO ▾',
              items: const [
                ('tb_registration', Icons.notifications_active, 'Thông báo mở cổng Đăng ký tín chỉ'),
                ('tb_tuition', Icons.payments, 'Thông báo nộp học phí qua Ngân hàng'),
              ],
              onSelected: (val) => _handleNavSelection(context, planner, val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownNavButton({
    required String title,
    required List<(String, IconData, String)> items,
    required void Function(String) onSelected,
    bool isBlue = false,
  }) {
    return PopupMenuButton<String>(
      tooltip: 'Bấm để xem danh mục $title',
      offset: const Offset(0, 36),
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      onSelected: onSelected,
      itemBuilder: (context) {
        return items.map((it) {
          return PopupMenuItem<String>(
            value: it.$1,
            height: 38,
            child: Row(
              children: [
                Icon(it.$2, size: 16, color: const Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Text(
                  it.$3,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            color: isBlue ? const Color(0xFF2563EB) : const Color(0xFF1E3A8A),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectNavButton({
    required String title,
    required VoidCallback onTap,
    IconData? icon,
    bool isBlue = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isBlue ? const Color(0xFF2563EB) : const Color(0xFF1E3A8A)),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                color: isBlue ? const Color(0xFF2563EB) : const Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Main Content: Classic Web Timetable (Default) or Modern Card View
  Widget _buildMainContent(PlannerProvider planner, dynamic profile, List<ClassSection> sections) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isModernView) ...[
            // Giao diện Lưới Web Trường chuẩn ttn.edu.vn:
            _buildClassicWebSearchAndHeader(planner, profile, sections),
            const SizedBox(height: 10),
            // Toàn bộ 7 tuần thời khóa biểu theo đúng giao diện Web trường Đại học Tây Nguyên
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(_kAllWeeks.length, (idx) {
                final weekInfo = _kAllWeeks[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildWeeklyTimetableGrid(
                    weekIndex: idx + 1,
                    dateRangeText: weekInfo.$1,
                    daysHeader: weekInfo.$2,
                    sections: sections,
                    planner: planner,
                  ),
                );
              }),
            ),
          ] else ...[
            // Giao diện Thẻ Hiện Đại
            _buildStudentProfileCard(planner, profile, sections),
            const SizedBox(height: 14),
            _buildModernToolbar(planner),
            const SizedBox(height: 16),
            _buildModernTimetableCards(planner, profile, sections),
          ],
        ],
      ),
    );
  }

  Widget _buildClassicWebSearchAndHeader(PlannerProvider planner, dynamic profile, List<ClassSection> sections) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // 1. Khung tra cứu chính xác theo web ĐH Tây Nguyên (ttn.edu.vn)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Mã SV : ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  width: 175,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5FF),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: const Color(0xFF93C5FD), width: 1),
                  ),
                  child: TextField(
                    controller: _studentIdController,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    ),
                    onSubmitted: (_) => _onSearch(planner),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                        side: const BorderSide(color: Color(0xFF94A3B8), width: 1),
                      ),
                    ),
                    onPressed: () => _onSearch(planner),
                    child: const Text('Tra cứu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 28,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      side: const BorderSide(color: Color(0xFF93C5FD)),
                      backgroundColor: const Color(0xFFEFF6FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    ),
                    icon: const Icon(Icons.people, size: 14, color: Color(0xFF1E3A8A)),
                    label: const Text('44 SV CNTT K23', style: TextStyle(fontSize: 11.5, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                    onPressed: () => _showStudentListDialog(context, planner),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Dòng thông tin sinh viên & Các công cụ nhanh (Responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final studentInfo = RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                  children: [
                    const TextSpan(text: 'Mã SV: '),
                    TextSpan(
                      text: profile.studentId,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                    const TextSpan(text: ' - Họ tên: '),
                    TextSpan(
                      text: profile.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
              );

              final tools = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      icon: const Icon(Icons.calendar_month, size: 13),
                      label: const Text('Xuất file iCal', style: TextStyle(fontSize: 11)),
                      onPressed: () => _exportIcs(context, planner),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      icon: const Icon(Icons.print, size: 13),
                      label: const Text('In TKB', style: TextStyle(fontSize: 11)),
                      onPressed: () => _showPrintPreview(context, planner),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      icon: const Icon(Icons.dashboard_customize, size: 13),
                      label: const Text('Giao diện Thẻ', style: TextStyle(fontSize: 11)),
                      onPressed: () => setState(() => _isModernView = true),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      icon: const Icon(Icons.phone_iphone, size: 13),
                      label: const Text('📱 App Mobile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        final activeMsv = _studentIdController.text.trim().isNotEmpty
                            ? _studentIdController.text.trim()
                            : (widget.studentId ?? profile.studentId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ModernMobileTimetableScreen(studentId: activeMsv),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    studentInfo,
                    const SizedBox(height: 8),
                    tools,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: studentInfo),
                  tools,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernToolbar(PlannerProvider planner) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildViewModeToggle(
                    icon: Icons.table_chart_outlined,
                    label: 'Lưới Web Trường',
                    isSelected: !_isModernView,
                    onTap: () => setState(() => _isModernView = false),
                  ),
                  _buildViewModeToggle(
                    icon: Icons.auto_awesome,
                    label: 'Giao diện Hiện đại',
                    isSelected: _isModernView,
                    onTap: () => setState(() => _isModernView = true),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                      SizedBox(width: 6),
                      Text(
                        'Học kỳ 1 • 2026 - 2027',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.file_download_outlined, size: 15),
                  label: const Text('Xuất file Lịch (.ics)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  onPressed: () => _exportIcs(context, planner),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.print, size: 15),
                  label: const Text('In Thời Khóa Biểu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _showPrintPreview(context, planner),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentProfileCard(PlannerProvider planner, dynamic profile, List<ClassSection> sections) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 760;

          final studentInfo = Row(
            children: [
              // Avatar with initials
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'TK',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile.fullName,
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                          ),
                          child: Text(
                            'MSSV: ${profile.studentId}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildMiniChip(Icons.school_outlined, '${profile.major} • ${profile.cohort}'),
                        _buildMiniChip(Icons.verified_user_outlined, 'CVHT: ThS. Nguyễn Thị Như'),
                        _buildMiniChip(Icons.stars_outlined, 'GPA: 3.42 (Giỏi)', color: const Color(0xFF059669), bg: const Color(0xFFECFDF5)),
                        _buildMiniChip(Icons.check_circle_outline, '${planner.totalCredits} TC đã xếp', color: const Color(0xFF2563EB), bg: const Color(0xFFEFF6FF)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final searchSection = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: TextField(
                  controller: _studentIdController,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Nhập Mã SV...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  ),
                  onSubmitted: (_) => _onSearch(planner),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(60, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _onSearch(planner),
                child: const Text('Tra cứu', style: TextStyle(fontSize: 11.5)),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  minimumSize: const Size(60, 32),
                  side: const BorderSide(color: Color(0xFF94A3B8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showStudentListDialog(context, planner),
                child: const Text('44 SV K23', style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A))),
              ),
            ],
          );

          if (isDesktop) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: studentInfo),
                const SizedBox(width: 14),
                searchSection,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              studentInfo,
              const SizedBox(height: 10),
              searchSection,
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniChip(IconData icon, String text, {Color color = const Color(0xFF475569), Color bg = const Color(0xFFF1F5F9)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildModernTimetableCards(PlannerProvider planner, dynamic profile, List<ClassSection> sections) {
    final activeMsv = (_studentIdController.text.trim().isNotEmpty)
        ? _studentIdController.text.trim()
        : (widget.studentId ?? planner.profile.studentId);
    final ttnStudent = TTNDatabase.getStudent(activeMsv);
    final rawSlots = ttnStudent != null ? (ttnStudent['slots'] as List<dynamic>? ?? []) : [];

    final currentWeekRange = _kAllWeeks[_selectedWeekIndex].$1;

    // Chỉ lọc các slot thực tế có lịch ở tuần đang chọn
    final weekSlots = rawSlots.where((raw) {
      final slot = raw as Map<String, dynamic>;
      final w = slot['week'] as String?;
      return w == null || w.isEmpty || w == currentWeekRange;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Week Pill Selector Carousel
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_kAllWeeks.length, (idx) {
              final isSel = _selectedWeekIndex == idx;
              final weekInfo = _kAllWeeks[idx];
              final wSlots = rawSlots.where((raw) {
                final s = raw as Map<String, dynamic>;
                final w = s['week'] as String?;
                return w == null || w.isEmpty || w == weekInfo.$1;
              }).toList();
              final hasSlots = wSlots.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedWeekIndex = idx),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF1E3A8A) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSel ? const Color(0xFF1E3A8A) : const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasSlots ? Icons.calendar_month : Icons.calendar_today_outlined,
                          size: 14,
                          color: isSel ? Colors.white : (hasSlots ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tuần ${idx + 1} (${weekInfo.$2.first.$2} - ${weekInfo.$2.last.$2})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        if (hasSlots) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSel ? Colors.white24 : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${wSlots.length} môn',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSel ? Colors.white : const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // Display Schedule for Selected Week
        if (weekSlots.isNotEmpty) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final colorsList = [
                (const Color(0xFF2563EB), const Color(0xFFEFF6FF), const Color(0xFFBFDBFE)),
                (const Color(0xFF7C3AED), const Color(0xFFF5F3FF), const Color(0xFFDDD6FE)),
                (const Color(0xFF059669), const Color(0xFFECFDF5), const Color(0xFFA7F3D0)),
                (const Color(0xFFD97706), const Color(0xFFFFFBEB), const Color(0xFFFDE68A)),
                (const Color(0xFFDC2626), const Color(0xFFFEF2F2), const Color(0xFFFECACA)),
                (const Color(0xFF0D9488), const Color(0xFFF0FDFA), const Color(0xFF99F6E4)),
              ];

              final dayCards = <Widget>[];
              for (int i = 0; i < weekSlots.length; i++) {
                final s = weekSlots[i];
                final dHeader = s['dayHeader'] as String? ?? 'Thứ ?';
                final rawName = s['rawTitle'] as String? ?? (s['courseName'] as String);
                final period = s['period'] as String? ?? '1-4';
                final session = s['session'] as String? ?? 'Sáng';
                final lecturer = s['lecturer'] as String? ?? '';
                final room = s['room'] as String? ?? '';
                final platform = s['platform'] as String? ?? '';
                final colorTuple = colorsList[i % colorsList.length];

                dayCards.add(
                  _buildDayCard(
                    dayTitle: dHeader,
                    dateText: currentWeekRange,
                    subjectName: rawName,
                    code: s['courseName'] as String? ?? '',
                    period: 'Tiết $period',
                    session: 'Buổi $session',
                    lecturer: lecturer,
                    room: platform.isNotEmpty ? 'Phòng $room ($platform)' : 'Phòng $room',
                    credits: 'Học phần TTN',
                    accentColor: colorTuple.$1,
                    bgColor: colorTuple.$2,
                    borderColor: colorTuple.$3,
                  ),
                );
              }

              if (isWide) {
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: dayCards.map((card) {
                    return SizedBox(
                      width: (constraints.maxWidth - 28) / 3,
                      child: card,
                    );
                  }).toList(),
                );
              }

              return Column(
                children: dayCards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
              );
            },
          ),
        ] else ...[
          // Empty Week Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Icon(Icons.event_available, size: 30, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tuần ${_selectedWeekIndex + 1} (${_kAllWeeks[_selectedWeekIndex].$1})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Không có lịch học theo thời khóa biểu chính thức của Trường Đại học Tây Nguyên.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Quay lại Tuần 1'),
                    onPressed: () => setState(() => _selectedWeekIndex = 0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDayCard({
    required String dayTitle,
    required String dateText,
    required String subjectName,
    required String code,
    required String period,
    required String session,
    required String lecturer,
    required String room,
    required String credits,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Day
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dayTitle,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(dateText, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(session, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                ),
              ],
            ),
          ),
          // Subject Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          subjectName,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          credits,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.schedule, period, accentColor),
                  const SizedBox(height: 4),
                  _buildDetailRow(Icons.person_outline, 'GV: $lecturer', const Color(0xFF475569)),
                  const SizedBox(height: 4),
                  _buildDetailRow(Icons.location_on_outlined, room, const Color(0xFF475569)),
                ],
              ),
            ),
          ),
          // Afternoon & Evening notice
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text('Chiều: Nghỉ', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text('Tối: Nghỉ', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildViewModeToggle({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dynamic Weekly Grid Table (Generated directly from registered sections in active plan & Web TTN!)
  Widget _buildWeeklyTimetableGrid({
    required int weekIndex,
    required String dateRangeText,
    required List<(String, String)> daysHeader,
    required List<ClassSection> sections,
    required PlannerProvider planner,
  }) {
    // Map registered classes into Day (2 -> 8) and Session (Sáng: 1-5, Chiều: 6-10, Tối: 11-12)
    final morningSlots = <int, List<Map<String, dynamic>>>{};
    final afternoonSlots = <int, List<Map<String, dynamic>>>{};
    final eveningSlots = <int, List<Map<String, dynamic>>>{};

    final activeMsv = (_studentIdController.text.trim().isNotEmpty)
        ? _studentIdController.text.trim()
        : (widget.studentId ?? planner.profile.studentId);
    final ttnStudent = TTNDatabase.getStudent(activeMsv);
    final hasTtnSlots = ttnStudent != null && (ttnStudent['slots'] as List).isNotEmpty;

    if (hasTtnSlots) {
      final ttnSlots = ttnStudent['slots'] as List<dynamic>;
      for (final raw in ttnSlots) {
        final tSlot = raw as Map<String, dynamic>;
        final slotWeek = tSlot['week'] as String?;
        // CHỈ hiển thị đúng ở tuần có lịch học trên web trường!
        // Nếu tuần đó không có lịch học (ví dụ Tuần 2: 26/10 - 01/11), để trống chuẩn 100% web TTN
        if (slotWeek != null && slotWeek.isNotEmpty && slotWeek != dateRangeText) {
          continue;
        }

        final dayIndex = tSlot['dayIndex'] as int;
        final session = tSlot['session'] as String;
        final rawTitle = tSlot['rawTitle'] as String;
        final courseName = tSlot['courseName'] as String;
        final period = tSlot['period'] as String;
        final lecturer = tSlot['lecturer'] as String;
        final room = tSlot['room'] as String;

        int startP = 1;
        int endP = 4;
        if (period.contains('-')) {
          final parts = period.split('-');
          startP = int.tryParse(parts[0]) ?? 1;
          endP = int.tryParse(parts[1]) ?? 4;
        }

        final fakeSec = ClassSection(
          id: '${courseName}_${dayIndex}_$startP',
          courseCode: courseName,
          courseName: rawTitle,
          lecturer: lecturer,
          lecturerRating: 4.8,
          capacity: 80,
          enrolled: 65,
          campus: 'Cơ sở chính',
          colorHex: 0xFF0284C7,
          slots: [
            ScheduleSlot(dayOfWeek: dayIndex, startPeriod: startP, endPeriod: endP, room: room),
          ],
        );

        final slotData = {
          'courseCode': courseName,
          'courseName': rawTitle,
          'sectionId': '${courseName}_$startP',
          'lecturer': lecturer,
          'room': room,
          'platform': tSlot['platform'] as String? ?? '',
          'startPeriod': startP,
          'endPeriod': endP,
          'dayOfWeek': dayIndex,
          'rawSection': fakeSec,
        };

        if (session == 'Sáng') {
          morningSlots.putIfAbsent(dayIndex, () => []).add(slotData);
        } else if (session == 'Chiều') {
          afternoonSlots.putIfAbsent(dayIndex, () => []).add(slotData);
        } else {
          eveningSlots.putIfAbsent(dayIndex, () => []).add(slotData);
        }
      }
    } else {
      // Đối với sinh viên chưa có slot sẵn trên web: chỉ hiển thị ở Tuần 1 nếu có môn đăng ký, các tuần sau để trống
      if (weekIndex == 1) {
        for (final sec in sections) {
          for (final slot in sec.slots) {
            final slotData = {
              'courseCode': sec.courseCode,
              'courseName': sec.courseName,
              'sectionId': sec.id,
              'lecturer': sec.lecturer,
              'room': slot.room,
              'startPeriod': slot.startPeriod,
              'endPeriod': slot.endPeriod,
              'dayOfWeek': slot.dayOfWeek,
              'rawSection': sec,
            };

            if (slot.startPeriod <= 5) {
              morningSlots.putIfAbsent(slot.dayOfWeek, () => []).add(slotData);
            } else if (slot.startPeriod <= 10) {
              afternoonSlots.putIfAbsent(slot.dayOfWeek, () => []).add(slotData);
            } else {
              eveningSlots.putIfAbsent(slot.dayOfWeek, () => []).add(slotData);
            }
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Red date range text right-aligned
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            dateRangeText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Grid Table
        LayoutBuilder(
          builder: (context, constraints) {
            const firstColWidth = 55.0;

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0284C7), width: 1),
              ),
              child: Column(
                children: [
                  // Header Row: Thứ / Buổi + 7 Days
                  Container(
                    color: const Color(0xFF003E6B), // Exact TTN Deep Navy Header
                    child: Row(
                      children: [
                        DiagonalHeaderCell(
                          width: firstColWidth,
                          height: 48,
                          borderColor: const Color(0xFF0284C7),
                        ),
                        ...daysHeader.map((d) {
                          return Expanded(
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                border: Border(right: BorderSide(color: Color(0xFF0284C7))),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(d.$1, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(d.$2, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Row: Sáng (Tuần 2 có nền hồng tím #F7D1EA chuẩn web TTN)
                  _buildDynamicSessionRow(
                    sessionName: 'Sáng',
                    firstColWidth: firstColWidth,
                    daySlotsMap: morningSlots,
                    minHeight: morningSlots.isEmpty ? 34 : 115,
                    customBgColor: weekIndex == 2 ? const Color(0xFFF7D1EA) : null,
                  ),

                  // Row: Chiều
                  _buildDynamicSessionRow(
                    sessionName: 'Chiều',
                    firstColWidth: firstColWidth,
                    daySlotsMap: afternoonSlots,
                    minHeight: afternoonSlots.isEmpty ? 34 : 115,
                    isWhite: true,
                  ),

                  // Row: Tối
                  _buildDynamicSessionRow(
                    sessionName: 'Tối',
                    firstColWidth: firstColWidth,
                    daySlotsMap: eveningSlots,
                    minHeight: 34,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDynamicSessionRow({
    required String sessionName,
    required double firstColWidth,
    required Map<int, List<Map<String, dynamic>>> daySlotsMap,
    required double minHeight,
    bool isWhite = false,
    Color? customBgColor,
  }) {
    final bgColor = customBgColor ?? (isWhite ? Colors.white : const Color(0xFFDEF3F6)); // Exact TTN Light cyan

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF0284C7))),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session Name column (Sáng, Chiều, Tối)
            Container(
              width: firstColWidth,
              constraints: BoxConstraints(minHeight: minHeight),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bgColor,
                border: const Border(right: BorderSide(color: Color(0xFF0284C7))),
              ),
              child: Text(
                sessionName,
                style: const TextStyle(fontSize: 11.5, color: Colors.black87),
              ),
            ),
            // 7 Days columns (2 -> 8)
            ...List.generate(7, (index) {
              final dayIndex = index + 2; // 2 (Thứ 2) -> 8 (Chủ Nhật)
              final items = daySlotsMap[dayIndex] ?? [];

              return Expanded(
                child: Container(
                  constraints: BoxConstraints(minHeight: minHeight),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: const Border(right: BorderSide(color: Color(0xFF0284C7))),
                  ),
                  child: items.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: items.map((item) {
                            final rawName = item['courseName'] as String;
                            final lecturer = item['lecturer'] as String;
                            final room = item['room'] as String;
                            final rawSec = item['rawSection'] as ClassSection;

                            final platform = item['platform'] as String? ?? '';
                            final displayTitle = rawName.startsWith('HP:') ? rawName : 'HP: $rawName';

                            return InkWell(
                              onTap: () => _showSlotDetailsDialog(context, rawSec, item),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 2),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: items.length > 1 ? const Color(0xFFFEE2E2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayTitle,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xFF0F172A),
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'GV: $lecturer',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF334155), height: 1.2),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Phòng: $room',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF334155), height: 1.2),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (platform.isNotEmpty)
                                      Text(
                                        platform,
                                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF334155), height: 1.2),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Interactive popup when student clicks on a class in the TTN timetable
  void _showSlotDetailsDialog(BuildContext context, ClassSection sec, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.school, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Chi Tiết Học Phần: ${sec.courseCode}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tên học phần: ${sec.courseName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            const SizedBox(height: 6),
            Text('Mã lớp học phần: ${sec.id}'),
            Text('Giảng viên phụ trách: ${sec.lecturer} (${sec.lecturerRating}★)'),
            Text('Phòng học: ${item['room']} • Cơ sở: ${sec.campus}'),
            Text('Khung giờ: Thứ ${item['dayOfWeek']} (Tiết ${item['startPeriod']}-${item['endPeriod']})'),
            Text('Sĩ số: ${sec.enrolled}/${sec.capacity} sinh viên'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanManagerScreen()));
            },
            child: const Text('Kế hoạch dự phòng / Đổi lớp'),
          ),
        ],
      ),
    );
  }

  void _exportIcs(BuildContext context, PlannerProvider planner) {
    final ics = IcalExportService.generateIcsContent(
      planName: planner.activePlan.name,
      sections: planner.activePlan.selectedSections.values.toList(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xuất Lịch Google (.ics)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Đã tạo tệp đồng bộ Google Calendar cho toàn bộ thời khóa biểu đã đăng ký của bạn. Bạn có thể sao chép mã và import vào Google Calendar:'),
            const SizedBox(height: 10),
            Container(
              height: 100,
              padding: const EdgeInsets.all(8),
              color: const Color(0xFFF1F5F9),
              child: SingleChildScrollView(child: Text(ics, style: const TextStyle(fontFamily: 'monospace', fontSize: 10))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: ics));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép mã iCalendar (.ics)!')),
              );
            },
            child: const Text('Sao chép mã ICS'),
          ),
        ],
      ),
    );
  }

  void _handleNavSelection(BuildContext context, PlannerProvider planner, String value) {
    switch (value) {
      // 1. SINH VIÊN
      case 'sv_tkb':
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        break;
      case 'sv_mobile':
        final activeMsv = _studentIdController.text.trim().isNotEmpty
            ? _studentIdController.text.trim()
            : (widget.studentId ?? planner.profile.studentId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ModernMobileTimetableScreen(studentId: activeMsv),
          ),
        );
        break;
      case 'sv_portal':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TayNguyenPortalScreen()));
        break;
      case 'sv_advisor':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAdvisorScreen()));
        break;
      case 'sv_roadmap':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PrerequisiteRoadmapScreen()));
        break;
      case 'sv_gpa':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const GpaSimulatorScreen()));
        break;
      case 'sv_ai':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AutoSchedulerScreen()));
        break;
      case 'sv_catalog':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseCatalogScreen()));
        break;
      case 'sv_tuition':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TuitionScreen()));
        break;
      case 'sv_students':
        _showStudentListDialog(context, planner);
        break;

      // 2. GIỚI THIỆU
      case 'gt_overview':
        _showInfoDialog(
          context,
          title: 'Tổng quan Trường Đại học Tây Nguyên',
          icon: Icons.school,
          content: const [
            ('Thành lập', 'Thành lập ngày 27/03/1977 theo Quyết định số 426/TTg của Thủ tướng Chính phủ.'),
            ('Địa chỉ', 'Số 567 Lê Duẩn, Phường Ea Tam, TP. Buôn Ma Thuột, Tỉnh Đắk Lắk.'),
            ('Quy mô', 'Hơn 12.000 sinh viên, 800 cán bộ giảng viên (trong đó có hàng chục GS, PGS, Tiến sĩ).'),
            ('Sứ mạng', 'Đào tạo nguồn nhân lực chất lượng cao, nghiên cứu khoa học và chuyển giao công nghệ phục vụ phát triển kinh tế - xã hội vùng Tây Nguyên và cả nước.'),
          ],
        );
        break;
      case 'gt_mission':
        _showInfoDialog(
          context,
          title: 'Sứ mạng - Tầm nhìn - Triết lý Giáo dục',
          icon: Icons.flag,
          content: const [
            ('Tầm nhìn 2030', 'Trở thành trường đại học nghiên cứu đa ngành, đa lĩnh vực định hướng ứng dụng có uy tín cao trong khu vực và cả nước.'),
            ('Triết lý GD', 'TÂM HUYẾT - TRÁCH NHIỆM - SÁNG TẠO - HỘI NHẬP.'),
            ('Mục tiêu', 'Đào tạo sinh viên vững chuyên môn, giỏi kỹ năng thực hành, thích ứng nhanh với kỷ nguyên chuyển đổi số và AI.'),
          ],
        );
        break;
      case 'gt_leaders':
        _showInfoDialog(
          context,
          title: 'Ban Giám hiệu Trường Đại học Tây Nguyên',
          icon: Icons.groups,
          content: const [
            ('Hiệu trưởng', 'GS. TS. Nguyễn Văn Nam'),
            ('Phó Hiệu trưởng', 'PGS. TS. Trần Trung Dũng'),
            ('Phó Hiệu trưởng', 'PGS. TS. Lê Đức Niêm'),
            ('Cơ quan chủ quản', 'Bộ Giáo dục và Đào tạo'),
          ],
        );
        break;

      // 3. ĐƠN VỊ
      case 'dv_cntt':
        _showInfoDialog(
          context,
          title: 'Khoa KHTN & Công nghệ - Bộ môn CNTT',
          icon: Icons.computer,
          content: const [
            ('Bộ môn CNTT', 'Phụ trách đào tạo ngành Công nghệ Thông tin, Kỹ thuật Phần mềm.'),
            ('Trụ sở', 'Nhà học 7 tầng, Phòng thực hành 7.3.18, Cơ sở 567 Lê Duẩn.'),
            ('Đội ngũ GV', '8 giảng viên cơ hữu: ThS. Trương Thị Hương Giang, ThS. Lê Tô Đỗ Quyên, ThS. Nguyễn Thị Như...'),
            ('Sinh viên K23', '44 sinh viên chính quy ngành CNTT Khóa 2023 - 2027.'),
          ],
        );
        break;
      case 'dv_daotao':
        _showInfoDialog(
          context,
          title: 'Phòng Đào tạo Đại học',
          icon: Icons.account_balance,
          content: const [
            ('Chức năng', 'Quản lý đào tạo tín chỉ, đăng ký học phần, thời khóa biểu, cấp bảng điểm và văn bằng.'),
            ('Địa chỉ', 'Tầng 1 Nhà điều hành, Trường Đại học Tây Nguyên.'),
            ('Hotline học vụ', '0262.3825.220 / Email: phongdaotao@ttn.edu.vn'),
          ],
        );
        break;
      case 'dv_ctsv':
        _showInfoDialog(
          context,
          title: 'Phòng Công tác Sinh viên',
          icon: Icons.person_pin,
          content: const [
            ('Chức năng', 'Giải quyết chế độ học bổng, miễn giảm học phí, rèn luyện và bảo hiểm y tế SV.'),
            ('Cấp giấy tờ', 'Xác nhận sinh viên vay vốn ngân hàng, tạm hoãn nghĩa vụ quân sự.'),
          ],
        );
        break;

      // 4. VĂN BẢN
      case 'vb_regulations':
        _showInfoDialog(
          context,
          title: 'Quy chế Đào tạo Tín chỉ Đại học',
          icon: Icons.description,
          content: const [
            ('Giới hạn tín chỉ', 'Tối thiểu 12 TC và tối đa 24 TC cho mỗi học kỳ chính.'),
            ('Điều kiện tiên quyết', 'Sinh viên bắt buộc tích lũy học phần tiên quyết trước khi đăng ký học phần tiếp theo.'),
            ('Xếp loại học lực', 'Xuất sắc (>=3.6), Giỏi (3.2 - 3.59), Khá (2.5 - 3.19), TB (2.0 - 2.49).'),
          ],
        );
        break;
      case 'vb_scholarship':
        _showInfoDialog(
          context,
          title: 'Quy định Học bổng & Miễn giảm học phí',
          icon: Icons.card_giftcard,
          content: const [
            ('Học bổng Xuất sắc', '100% học phí học kỳ + khen thưởng khi ĐRL Xuất sắc và GPA >= 3.6.'),
            ('Học bổng Giỏi', '100% học phí học kỳ khi ĐRL Tốt và GPA >= 3.2.'),
            ('Miễn giảm chính sách', 'Giảm 50% - 100% cho con hộ nghèo, dân tộc thiểu số vùng khó khăn.'),
          ],
        );
        break;

      // 5. TUYỂN SINH
      case 'tuyen_sinh':
        _showInfoDialog(
          context,
          title: 'Thông tin Tuyển sinh Đại học Chính quy năm 2026',
          icon: Icons.how_to_reg,
          content: const [
            ('Ngành CNTT', 'Mã ngành: 7480201 - Chỉ tiêu: 120 sinh viên.'),
            ('Phương thức xét tuyển', '1. Điểm thi tốt nghiệp THPT; 2. Xét học bạ THPT; 3. Điểm thi ĐGNL ĐHQG TP.HCM.'),
            ('Tổ hợp môn xét tuyển', 'A00 (Toán, Lý, Hóa), A01 (Toán, Lý, Anh), D01 (Toán, Văn, Anh), D07 (Toán, Hóa, Anh).'),
            ('Cơ hội nghề nghiệp', 'Kỹ sư phần mềm, lập trình viên di động/web, kỹ sư dữ liệu & AI.'),
          ],
        );
        break;

      // 6. ĐÀO TẠO
      case 'dt_curriculum':
        _showInfoDialog(
          context,
          title: 'Chương trình Đào tạo Cử nhân CNTT (145 Tín chỉ)',
          icon: Icons.menu_book,
          content: const [
            ('Khối kiến thức chung', 'Triết học Mác-Lênin, LS Đảng CS VN, Tin học đại cương, Ngoại ngữ (30 TC).'),
            ('Khối cơ sở ngành', 'Cấu trúc dữ liệu & Giải thuật, Cơ sở dữ liệu, Mạng máy tính, OOP (45 TC).'),
            ('Khối chuyên ngành', 'Lập trình di động, Phát triển Web, Trí tuệ nhân tạo, Điện toán đám mây (50 TC).'),
            ('Khóa luận tốt nghiệp', 'Thực tập doanh nghiệp & Khóa luận tốt nghiệp CNTT (20 TC).'),
          ],
        );
        break;
      case 'dt_prerequisite':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PrerequisiteRoadmapScreen()));
        break;
      case 'dt_calendar':
        _showInfoDialog(
          context,
          title: 'Kế hoạch Năm học 2026 - 2027',
          icon: Icons.calendar_month,
          content: const [
            ('Học kỳ 1', 'Bắt đầu từ 19/10/2026 đến 15/01/2027 (15 tuần học chính khóa).'),
            ('Đăng ký tín chỉ', 'Đợt 1 từ 01/10 - 15/10/2026; Đợt bổ sung từ 19/10 - 25/10/2026.'),
            ('Thi kết thúc môn', 'Từ ngày 18/01/2027 đến ngày 31/01/2027.'),
          ],
        );
        break;

      // 7. KHCN
      case 'khcn_research':
        _showInfoDialog(
          context,
          title: 'Hoạt động Nghiên cứu Khoa học Sinh viên 2026',
          icon: Icons.science,
          content: const [
            ('Chủ đề trọng tâm', 'Trí tuệ nhân tạo trong Giáo dục & Nông nghiệp thông minh Tây Nguyên.'),
            ('Giải thưởng', 'Giải thưởng NCKH Sinh viên cấp Trường và Euréka 2026.'),
            ('Kinh phí hỗ trợ', 'Tối đa 15.000.000 đ cho đề tài NCKH sinh viên được phê duyệt.'),
          ],
        );
        break;
      case 'khcn_club':
        _showInfoDialog(
          context,
          title: 'Câu lạc bộ Tin học TNU (IT Club)',
          icon: Icons.code,
          content: const [
            ('Hoạt động', 'Sinh hoạt hàng tuần vào sáng Thứ 7 tại phòng máy Lab 7.3.18.'),
            ('Nội dung', 'Lập trình Flutter/Dart, Python AI, Web ReactJS & Luyện thi Olympic Tin học.'),
          ],
        );
        break;

      // 8. THÔNG BÁO
      case 'tb_registration':
        _showInfoDialog(
          context,
          title: 'Thông báo: Mở đợt Đăng ký Tín chỉ Học kỳ mới',
          icon: Icons.notifications_active,
          content: const [
            ('Thời gian', 'Từ 08h00 ngày 19/10/2026 đến 17h00 ngày 25/10/2026.'),
            ('Đối tượng', 'Toàn thể sinh viên K23 ngành CNTT và các ngành thuộc Trường ĐH Tây Nguyên.'),
            ('Lưu ý', 'Sinh viên kiểm tra kỹ trùng tiết và môn tiên quyết trước khi xác nhận lưu.'),
          ],
        );
        break;
      case 'tb_tuition':
        _showInfoDialog(
          context,
          title: 'Thông báo: Lịch Nộp Học phí Học kỳ 1 (2026 - 2027)',
          icon: Icons.payments,
          content: const [
            ('Hạn cuối nộp', 'Ngày 15/11/2026.'),
            ('Hình thức nộp', 'Chuyển khoản trực tuyến qua cổng VietinBank / Agribank tích hợp MSSV.'),
            ('Đơn giá', '420.000 đ/tín chỉ Lý thuyết; 530.000 đ/tín chỉ Thực hành.'),
          ],
        );
        break;
    }
  }

  void _showInfoDialog(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<(String, String)> content,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: const Color(0xFF1E3A8A), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5, right: 8),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                          children: [
                            TextSpan(
                              text: '${item.$1}: ',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            TextSpan(text: item.$2),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showPrintPreview(BuildContext context, PlannerProvider planner) {
    final profile = planner.profile;
    final activeSections = planner.activePlan.selectedSections.values.toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        title: Row(
          children: [
            const Icon(Icons.print, color: Color(0xFF1E3A8A), size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Bản In Thời Khóa Biểu - Đại học Tây Nguyên',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'BỘ GIÁO DỤC VÀ ĐÀO TẠO • TRƯỜNG ĐẠI HỌC TÂY NGUYÊN\nTHỜI KHÓA BIỂU HỌC KỲ 1 (2026 - 2027)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                      ),
                      const Divider(height: 16),
                      Text('Mã SV: ${profile.studentId}   |   Họ tên: ${profile.fullName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Ngành: ${profile.major}   |   Khóa: ${profile.cohort}   |   Tổng số: ${planner.totalCredits} TC', style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Table(
                  border: TableBorder.all(color: const Color(0xFF94A3B8), width: 0.8),
                  columnWidths: const {
                    0: FlexColumnWidth(2.8),
                    1: FlexColumnWidth(1.2),
                    2: FlexColumnWidth(1.2),
                    3: FlexColumnWidth(2.2),
                    4: FlexColumnWidth(1.4),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0xFF003E6B)),
                      children: [
                        Padding(padding: EdgeInsets.all(6), child: Text('Tên môn học', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Thứ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Tiết', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Giảng viên', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Phòng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                    ),
                    ...activeSections.map((sec) {
                      final slot = sec.slots.isNotEmpty ? sec.slots.first : null;
                      return TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(6), child: Text(sec.courseName, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(slot != null ? 'Thứ ${slot.dayOfWeek}' : 'T2', style: const TextStyle(fontSize: 10.5))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(slot != null ? '${slot.startPeriod}-${slot.endPeriod}' : '1-4', style: const TextStyle(fontSize: 10.5))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(sec.lecturer, style: const TextStyle(fontSize: 10))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(slot != null ? slot.room : '7.3.18', style: const TextStyle(fontSize: 10))),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            icon: const Icon(Icons.print, size: 16),
            label: const Text('In Ngay (Print)'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Đã kết nối máy in và xuất bản in Thời khóa biểu thành công!'),
                  backgroundColor: Color(0xFF15803D),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DiagonalHeaderCell extends StatelessWidget {
  final double width;
  final double height;
  final Color borderColor;

  const DiagonalHeaderCell({
    super.key,
    required this.width,
    required this.height,
    this.borderColor = const Color(0xFF0284C7),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: CustomPaint(
        painter: _DiagonalLinePainter(borderColor),
        child: const Stack(
          children: [
            Positioned(
              top: 5,
              right: 6,
              child: Text(
                'Thứ',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            Positioned(
              bottom: 5,
              left: 6,
              child: Text(
                'Buổi',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagonalLinePainter extends CustomPainter {
  final Color color;
  _DiagonalLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
