import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/planner_provider.dart';
import '../../services/ical_export_service.dart';
import '../../services/ttn_database.dart';
import 'ai_advisor_screen.dart';
import 'exam_schedule_screen.dart';
import 'profile_screen.dart';
import 'tuition_screen.dart';

/// Màn hình Thời khóa biểu Giao diện Ứng dụng Di động Hiện đại
/// Khớp 100% hình ảnh thực tế trên điện thoại thông minh:
/// Header xanh đậm, chọn tuần pill dropdown, nút 'Hôm nay', các thẻ môn học
/// (Đang diễn ra viền cam, thẻ xanh dương pastel, thẻ cam pastel),
/// nút Đồng bộ Google Calendar, nút Lịch thi và Bottom Navigation Bar 5 tabs.
class ModernMobileTimetableScreen extends StatefulWidget {
  final String? studentId;
  final bool forcePhoneFrame;

  const ModernMobileTimetableScreen({
    super.key,
    this.studentId,
    this.forcePhoneFrame = false,
  });

  @override
  State<ModernMobileTimetableScreen> createState() => _ModernMobileTimetableScreenState();
}

class _ModernMobileTimetableScreenState extends State<ModernMobileTimetableScreen> {
  int _currentNavIndex = 1; // Tab 1: 'Lịch học' đang được chọn theo ảnh
  int _selectedWeekIndex = 11; // Mặc định Tuần 12 (02/11 - 08/11) theo ảnh mẫu
  int _selectedDayIndex = 2; // Thứ Hai (ngày 02/11) theo ảnh mẫu
  bool _usePhoneMockup = true; // Chế độ khung điện thoại iPhone trên màn hình lớn

  // Danh sách các tuần học kỳ 1 (Năm học 2026-2027)
  static const List<Map<String, dynamic>> _kWeeksList = [
    {'title': 'Tuần 1 (19/10 - 25/10)', 'start': '19/10', 'end': '25/10'},
    {'title': 'Tuần 2 (26/10 - 01/11)', 'start': '26/10', 'end': '01/11'},
    {'title': 'Tuần 3 (02/11 - 08/11)', 'start': '02/11', 'end': '08/11'},
    {'title': 'Tuần 4 (09/11 - 15/11)', 'start': '09/11', 'end': '15/11'},
    {'title': 'Tuần 5 (16/11 - 22/11)', 'start': '16/11', 'end': '22/11'},
    {'title': 'Tuần 6 (23/11 - 29/11)', 'start': '23/11', 'end': '29/11'},
    {'title': 'Tuần 7 (30/11 - 06/12)', 'start': '30/11', 'end': '06/12'},
    {'title': 'Tuần 8 (07/12 - 13/12)', 'start': '07/12', 'end': '13/12'},
    {'title': 'Tuần 9 (14/12 - 20/12)', 'start': '14/12', 'end': '20/12'},
    {'title': 'Tuần 10 (21/12 - 27/12)', 'start': '21/12', 'end': '27/12'},
    {'title': 'Tuần 11 (28/12 - 03/01)', 'start': '28/12', 'end': '03/01'},
    {'title': 'Tuần 12 (02/11 - 08/11)', 'start': '02/11', 'end': '08/11'}, // Tuần mẫu trong ảnh
    {'title': 'Tuần 13 (09/11 - 15/11)', 'start': '09/11', 'end': '15/11'},
    {'title': 'Tuần 14 (16/11 - 22/11)', 'start': '16/11', 'end': '22/11'},
    {'title': 'Tuần 15 (23/11 - 29/11)', 'start': '23/11', 'end': '29/11'},
  ];

  // Danh sách các ngày trong tuần
  static const List<Map<String, dynamic>> _kDaysList = [
    {'dayNumber': 2, 'label': 'Thứ Hai, 02/11', 'shortLabel': 'Thứ 2', 'date': '02/11'},
    {'dayNumber': 3, 'label': 'Thứ Ba, 03/11', 'shortLabel': 'Thứ 3', 'date': '03/11'},
    {'dayNumber': 4, 'label': 'Thứ Tư, 04/11', 'shortLabel': 'Thứ 4', 'date': '04/11'},
    {'dayNumber': 5, 'label': 'Thứ Năm, 05/11', 'shortLabel': 'Thứ 5', 'date': '05/11'},
    {'dayNumber': 6, 'label': 'Thứ Sáu, 06/11', 'shortLabel': 'Thứ 6', 'date': '06/11'},
    {'dayNumber': 7, 'label': 'Thứ Bảy, 07/11', 'shortLabel': 'Thứ 7', 'date': '07/11'},
    {'dayNumber': 8, 'label': 'Chủ Nhật, 08/11', 'shortLabel': 'CN', 'date': '08/11'},
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= 600;

        if (isLargeScreen && _usePhoneMockup) {
          // Hiển thị khung iPhone sang trọng giống ảnh chụp người dùng đang cầm điện thoại
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: Stack(
              children: [
                // Hình nền mờ phong cảnh khuôn viên trường (Campus background)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0F172A).withValues(alpha: 0.94),
                          const Color(0xFF1E293B).withValues(alpha: 0.88),
                          const Color(0xFF0F172A).withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Thanh điều khiển chuyển chế độ trên cùng
                Positioned(
                  top: 14,
                  left: 20,
                  right: 20,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.phone_iphone, color: Colors.cyanAccent, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Giao diện Ứng dụng Di động Hiện đại (Ảnh chụp thực tế)',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: const Icon(Icons.fullscreen, size: 16),
                          label: const Text('Toàn màn hình', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              _usePhoneMockup = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Khung mô phỏng điện thoại iPhone
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 50, bottom: 20),
                    width: 390,
                    height: 800,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: const Color(0xFF334155), width: 10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 36,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Stack(
                        children: [
                          _buildMobileAppScaffold(context),
                          // Dynamic Island Notch
                          Positioned(
                            top: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 110,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Chế độ toàn màn hình (Mobile tự nhiên hoặc người dùng bấm Toàn màn hình)
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: isLargeScreen
              ? AppBar(
                  backgroundColor: const Color(0xFF1A56DB),
                  elevation: 0,
                  title: const Text('Giao diện Mobile App Hiện Đại', style: TextStyle(fontSize: 15)),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.phone_iphone),
                      tooltip: 'Chuyển sang Khung điện thoại',
                      onPressed: () => setState(() => _usePhoneMockup = true),
                    ),
                  ],
                )
              : null,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _buildMobileAppScaffold(context),
            ),
          ),
        );
      },
    );
  }

  // --- Khung Giao diện Ứng dụng Di động Chuẩn ---
  Widget _buildMobileAppScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header màu xanh dương nổi bật chuẩn ảnh
            _buildModernHeader(),

            // Danh sách các thẻ môn học
            Expanded(
              child: _buildBodyTabContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  // --- Header xanh đậm với Tiêu đề, Học kỳ, Pill Tuần & Nút Hôm nay ---
  Widget _buildModernHeader() {
    final currentWeek = _kWeeksList[_selectedWeekIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 44, left: 18, right: 18, bottom: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A56DB), // Màu xanh dương chuẩn trong ảnh người dùng
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề THỜI KHÓA BIỂU
          const Text(
            'THỜI KHÓA BIỂU',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),

          // Subtitle: Học kỳ I - Năm học 2026-2027
          const Text(
            'Học kỳ I - Năm học 2026-2027',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFFBFDBFE),
            ),
          ),
          const SizedBox(height: 12),

          // Hàng điều khiển: Dropdown Tuần & Nút Hôm nay
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pill chọn Tuần (Dropdown)
                InkWell(
                  onTap: _showWeekPickerBottomSheet,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentWeek['title'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Nút Hôm nay
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedWeekIndex = 11; // Về Tuần 12 (02/11 - 08/11) theo ảnh
                      _selectedDayIndex = 2; // Về Thứ Hai
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã chuyển về lịch học Hôm nay (Thứ Hai, 02/11)'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Color(0xFF1A56DB),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white38, width: 1),
                    ),
                    child: const Text(
                      'Hôm nay',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  // --- Nội dung chính theo tab được chọn ---
  Widget _buildBodyTabContent() {
    if (_currentNavIndex == 1) {
      // Tab 1: Lịch học (Khớp 100% ảnh chụp)
      return _buildTimetableScheduleList();
    } else if (_currentNavIndex == 0) {
      // Tab 0: Trang chủ
      return _buildHomeTab();
    } else if (_currentNavIndex == 2) {
      // Tab 2: Điểm số
      return _buildGradesTab();
    } else if (_currentNavIndex == 3) {
      // Tab 3: Tin nhắn / Cố vấn AI
      return const AiAdvisorScreen();
    } else {
      // Tab 4: Cá nhân
      return const ProfileScreen();
    }
  }

  // --- Danh sách Lịch học với Thứ Hai, 02/11 và 3 Thẻ Môn học ---
  Widget _buildTimetableScheduleList() {
    final activeDay = _kDaysList.firstWhere(
      (d) => d['dayNumber'] == _selectedDayIndex,
      orElse: () => _kDaysList.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề ngày: Thứ Hai, 02/11
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                activeDay['label'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              // Nút đổi ngày nhanh
              PopupMenuButton<int>(
                icon: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                tooltip: 'Chọn ngày khác trong tuần',
                onSelected: (val) {
                  setState(() {
                    _selectedDayIndex = val;
                  });
                },
                itemBuilder: (ctx) => _kDaysList.map((d) {
                  return PopupMenuItem<int>(
                    value: d['dayNumber'] as int,
                    child: Text(d['label'] as String, style: const TextStyle(fontSize: 12.5)),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // NẾU LÀ THỨ HAI (Khớp 100% 3 thẻ môn học trong ảnh của bạn)
          if (_selectedDayIndex == 2) ...[
            // THẺ 1: Kỹ thuật phần mềm (Đang diễn ra - Viền cam)
            _buildActiveOngoingCard(
              title: 'Kỹ thuật phần mềm',
              time: '07:30 - 09:15',
              room: 'Phòng 402 - Tòa B',
              lecturer: 'GV: TS. Nguyễn Văn A',
              badgeText: 'Đang diễn ra',
            ),
            const SizedBox(height: 12),

            // THẺ 2: Trí tuệ nhân tạo (Màu xanh dương pastel)
            _buildPastelClassCard(
              title: 'Trí tuệ nhân tạo',
              time: '09:30 - 11:15',
              room: 'Phòng 501 - Tòa C',
              lecturer: 'GV: ThS. Trần Thị B',
              bgColor: const Color(0xFFE0F2FE), // Xanh pastel chuẩn ảnh
              borderColor: const Color(0xFFBAE6FD),
            ),
            const SizedBox(height: 12),

            // THẺ 3: Thể dục (Bóng rổ) (Màu cam pastel)
            _buildPastelClassCard(
              title: 'Thể dục (Bóng rổ)',
              time: '13:30 - 15:15',
              room: 'Sân thể chất',
              lecturer: 'GV: Thầy Lê Văn C',
              bgColor: const Color(0xFFFFEDD5), // Cam/be pastel chuẩn ảnh
              borderColor: const Color(0xFFFED7AA),
            ),
          ] else ...[
            // Các ngày khác trong tuần
            _buildOtherDayCards(_selectedDayIndex),
          ],

          const SizedBox(height: 20),

          // 2 NÚT HÀNH ĐỘNG DƯỚI CÙNG (Khớp 100% ảnh)
          Row(
            children: [
              // Nút 1: Đồng bộ Google Calendar (Màu xanh dương)
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text(
                    'Đồng bộ Google Calendar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    final planner = context.read<PlannerProvider>();
                    final ics = IcalExportService.generateIcsContent(
                      planName: planner.activePlan.name,
                      sections: planner.activePlan.selectedSections.values.toList(),
                    );
                    Clipboard.setData(ClipboardData(text: ics));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Đã tạo & sao chép nội dung iCal (RFC 5545) để đồng bộ Google Calendar!'),
                        backgroundColor: Color(0xFF1D4ED8),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 10),

              // Nút 2: Lịch thi (Màu cam)
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.event_note, size: 16),
                  label: const Text(
                    'Lịch thi',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExamScheduleScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- THẺ 1: Môn học đang diễn ra (Viền cam, badge Đang diễn ra, Icon sách xanh) ---
  Widget _buildActiveOngoingCard({
    required String title,
    required String time,
    required String room,
    required String lecturer,
    required String badgeText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFB923C), width: 1.5), // Viền cam chuẩn ảnh
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFB923C).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Đang diễn ra & Icon môn học
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                badgeText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF97316), // Màu cam chuẩn
                ),
              ),
              // Icon vuông xanh dương bên phải
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Tên môn học
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),

          // Giờ học
          Text(
            time,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),

          // Phòng học
          Text(
            room,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 2),

          // Giảng viên
          Text(
            lecturer,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // --- THẺ PASTEL: Dành cho Trí tuệ nhân tạo (Xanh pastel) & Thể dục (Cam pastel) ---
  Widget _buildPastelClassCard({
    required String title,
    required String time,
    required String room,
    required String lecturer,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên môn học
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),

          // Giờ học
          Text(
            time,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),

          // Phòng học
          Text(
            room,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 2),

          // Giảng viên
          Text(
            lecturer,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // --- Thẻ cho các ngày khác ---
  Widget _buildOtherDayCards(int dayIndex) {
    if (dayIndex == 3) {
      return Column(
        children: [
          _buildPastelClassCard(
            title: 'Tâm lý học đại cương',
            time: '07:30 - 11:15',
            room: 'Phòng 2.4 - Nhà 2',
            lecturer: 'GV: TS. Lê Tô Đỗ Quyên',
            bgColor: const Color(0xFFE0F2FE),
            borderColor: const Color(0xFFBAE6FD),
          ),
          const SizedBox(height: 12),
          _buildPastelClassCard(
            title: 'An toàn thông tin',
            time: '13:30 - 16:30',
            room: 'Phòng 6.12 - Nhà 6',
            lecturer: 'GV: ThS. Trần Đình Hưng',
            bgColor: const Color(0xFFFFEDD5),
            borderColor: const Color(0xFFFED7AA),
          ),
        ],
      );
    } else if (dayIndex == 4) {
      return Column(
        children: [
          _buildPastelClassCard(
            title: 'Lập trình di động',
            time: '07:30 - 11:15',
            room: 'Lab 7.3.18 - Nhà 7',
            lecturer: 'GV: ThS. Trương Thị Hương Giang',
            bgColor: const Color(0xFFE0F2FE),
            borderColor: const Color(0xFFBAE6FD),
          ),
        ],
      );
    } else if (dayIndex == 5) {
      return Column(
        children: [
          _buildPastelClassCard(
            title: 'Tâm lý học đại cương',
            time: '07:30 - 09:15',
            room: 'Phòng 2.4 - Nhà 2',
            lecturer: 'GV: TS. Lê Tô Đỗ Quyên',
            bgColor: const Color(0xFFFFEDD5),
            borderColor: const Color(0xFFFED7AA),
          ),
        ],
      );
    } else if (dayIndex == 6) {
      return Column(
        children: [
          _buildPastelClassCard(
            title: 'Những VĐ HĐ của CNTT',
            time: '07:30 - 10:15',
            room: 'Phòng 7.3.18 - Nhà 7',
            lecturer: 'GV: ThS. Trương Thị Hương Giang',
            bgColor: const Color(0xFFE0F2FE),
            borderColor: const Color(0xFFBAE6FD),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.weekend_outlined, size: 40, color: Color(0xFF94A3B8)),
          SizedBox(height: 8),
          Text(
            'Hôm nay không có lịch học',
            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --- Bottom Navigation Bar 5 Tabs Chuẩn Ảnh ---
  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (idx) {
          setState(() {
            _currentNavIndex = idx;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1A56DB), // Màu xanh dương chuẩn tab active
        unselectedItemColor: const Color(0xFF64748B),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Lịch học',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            activeIcon: Icon(Icons.fact_check),
            label: 'Điểm số',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Tin nhắn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  // --- BottomSheet chọn Tuần học ---
  void _showWeekPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn Tuần Học Kỳ 1 (2026-2027)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _kWeeksList.length,
                  itemBuilder: (ctx, idx) {
                    final item = _kWeeksList[idx];
                    final isSel = idx == _selectedWeekIndex;
                    return ListTile(
                      dense: true,
                      title: Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? const Color(0xFF1A56DB) : const Color(0xFF1E293B),
                        ),
                      ),
                      trailing: isSel ? const Icon(Icons.check, color: Color(0xFF1A56DB), size: 18) : null,
                      onTap: () {
                        setState(() {
                          _selectedWeekIndex = idx;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Nội dung mẫu cho các tab còn lại ---
  Widget _buildHomeTab() {
    final planner = context.watch<PlannerProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Xin chào sinh viên,', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text(planner.profile.fullName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('MSSV: ${planner.profile.studentId} • ${planner.profile.major}', style: const TextStyle(color: Color(0xFFDBEAFE), fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Truy cập nhanh', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.calendar_month,
                title: 'Xem Lịch học',
                color: const Color(0xFF1A56DB),
                onTap: () => setState(() => _currentNavIndex = 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.event_note,
                title: 'Xem Lịch thi',
                color: const Color(0xFFF97316),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamScheduleScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.payments_outlined,
                title: 'Học phí',
                color: const Color(0xFF059669),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TuitionScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.smart_toy_outlined,
                title: 'Cố vấn AI',
                color: const Color(0xFF7C3AED),
                onTap: () => setState(() => _currentNavIndex = 3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildGradesTab() {
    final planner = context.watch<PlannerProvider>();
    final results = TTNDatabase.getSemesterResultsTableForStudent(planner.profile.studentId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Kết quả học tập kỳ này', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
              child: Text('TBCTL: ${planner.profile.currentGpa.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8), fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...results.map((r) {
          final bp = r['boPhan'] as String? ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(r['classId'] as String, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    ],
                  ),
                ),
                Text(bp.isNotEmpty ? 'BP: $bp' : 'Chưa có điểm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: bp.isNotEmpty ? const Color(0xFF059669) : Colors.grey)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
