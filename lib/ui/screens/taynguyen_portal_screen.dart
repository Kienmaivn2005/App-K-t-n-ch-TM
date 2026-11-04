import '../../models/ttn_major.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../providers/planner_provider.dart';
import '../../services/mock_data.dart';
import '../../services/ttn_database.dart';
import '../../services/ttn_handbook_data.dart';
import '../widgets/prerequisite_dialog.dart';
import 'ai_advisor_screen.dart';
import 'auto_scheduler_screen.dart';
import 'gpa_simulator_screen.dart';
import 'modern_mobile_timetable_screen.dart';
import 'plan_manager_screen.dart';
import 'prerequisite_roadmap_screen.dart';
import 'ttn_web_timetable_screen.dart';

class TayNguyenPortalScreen extends StatefulWidget {
  const TayNguyenPortalScreen({super.key});

  @override
  State<TayNguyenPortalScreen> createState() => _TayNguyenPortalScreenState();
}

class _TayNguyenPortalScreenState extends State<TayNguyenPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCurriculumIndex = 0;
  ClassSection? _selectedAvailableSection;
  ClassSection? _selectedRegisteredSection;
  bool _isWebTimetableMode = true;
  String _reasonAddBlocked = '';
  String _reasonRemoveBlocked = '';
  final Set<String> _registeredRetakeCodes = {'KC212604'};
  String? _selectedRetakeCourseCode = 'KC212604';
  int _selectedHandbookSemester = 0;
  String _handbookSearch = '';
  final Set<String> _selectedSummerCourseCodes = {'KC212604', 'KC212102'};
  String _summerSearch = '';
  String _libraryCategory = 'Tất cả';
  String _librarySearch = '';

  late TextEditingController _studentIdController;
  late TextEditingController _birthDateController;
  late TextEditingController _passwordController;
  String _lastSyncedStudentId = '';
  String _verifiedPasswordStudentId = '';

  static final Map<String, Map<String, dynamic>> _officialRegisteredDetails = {
    'KC213613': {
      'classId': 'KC213613_74293',
      'name': 'An toàn thông tin (2.0/0.0)',
      'className': 'Công nghệ thông tin K23 (67/13)',
      'insertDate': '7/15/2026 7',
      'status': 'Mở',
      'cvhtApproved': true,
      'date': '20260717 0',
      'confirmed': 'Rồi',
    },
    'KC213668': {
      'classId': 'KC213668_74310',
      'name': 'Quản trị mạng trên môi trường W',
      'className': 'Công nghệ thông tin K23 (62/13)',
      'insertDate': '8/5/2026 8:3',
      'status': 'Mở',
      'cvhtApproved': true,
      'date': '20260805 1',
      'confirmed': 'Rồi',
    },
    'KC213678': {
      'classId': 'KC213678_74306',
      'name': 'Thương mại điện tử (2.0/0.0)',
      'className': 'Công nghệ thông tin K23 (63/13)',
      'insertDate': '7/15/2026 7',
      'status': 'Mở',
      'cvhtApproved': true,
      'date': '20260717 0',
      'confirmed': 'Rồi',
    },
    'KC213685': {
      'classId': 'KC213685_74292',
      'name': 'Những vấn đề hiện đại của CNTT',
      'className': 'Công nghệ thông tin K23 (63/13)',
      'insertDate': '7/15/2026 7',
      'status': 'Mở',
      'cvhtApproved': true,
      'date': '20260717 0',
      'confirmed': 'Rồi',
    },
    'KC215046': {
      'classId': 'KC215046_74297',
      'name': 'Lập trình di động (2.0/1.0)',
      'className': 'Công nghệ thông tin K23 (59/12)',
      'insertDate': '7/15/2026 7',
      'status': 'Mở',
      'cvhtApproved': true,
      'date': '20260717 0',
      'confirmed': 'Rồi',
    },
    'KC215050': {
      'classId': 'KC215050_74301',
      'name': 'Công nghệ lập trình đa nền tảng c',
      'className': 'Công nghệ thông tin K23 (59/12)',
      'insertDate': '7/15/2026 7',
      'status': 'Mở',
      'cvhtApproved': true,
      'date': '20260717 0',
      'confirmed': 'Rồi',
    },
    'ML211033': {
      'classId': 'ML211033_74291',
      'name': 'Lịch sử Đảng Cộng sản Việt Nam',
      'className': 'Công nghệ thông tin K23 (67/13)',
      'insertDate': '7/15/2026 7',
      'status': 'Mở',
      'cvhtApproved': true,
      'date': '20260717 0',
      'confirmed': 'Rồi',
    },
    'SP211014': {
      'classId': 'SP211014_74294',
      'name': 'Tâm lý học đại cương (2.0/0.0)',
      'className': 'Công nghệ thông tin K23 (64/13)',
      'insertDate': '8/26/2026 4',
      'status': 'Mở',
      'cvhtApproved': false,
      'date': '',
      'confirmed': 'Rồi',
    },
  };

  final List<String> _tabs = [
    'Đăng ký học phần',
    'Đăng ký học hè',
    'Kết quả học tập',
    'Học phí và lịch thi',
    'Thời khóa biểu',
    'Đăng ký thi lại',
    'Tốt nghiệp',
    'Hướng dẫn',
    'Đề cương học phần',
    'Thư viện',
    '⚡ Xếp lịch tự động',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _studentIdController = TextEditingController();
    _birthDateController = TextEditingController();
    _passwordController = TextEditingController();
    _studentIdController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _studentIdController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final profile = planner.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Column(
        children: [
          _buildSystemTitleBar(),
          _buildHeaderControlBar(profile, planner),
          _buildStudentInfoBar(profile, planner),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCourseRegistrationTab(planner),
                _buildSummerRegistrationTab(planner),
                _buildAcademicResultsTab(planner),
                _buildTuitionAndExamTab(planner),
                _buildTimetableTab(planner),
                _buildRetakeExamTab(planner),
                _buildGraduationEvaluationTab(planner),
                _buildUserGuideTab(),
                _buildCurriculumHandbookTab(),
                _buildDigitalLibraryTab(),
                const AutoSchedulerScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Windows/Application Title Bar
  Widget _buildSystemTitleBar() {
    return Container(
      height: 28,
      color: const Color(0xFFE6E6E6),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFB91C1C),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text('Tây', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Phần mềm Đăng ký học phần của Sinh viên Trường Đại học Tây Nguyên (15/07/2023)MAC:6CF6DA896461',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Text('—   □   ✕', style: TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  // 2. Control bar (Học kỳ, Năm học, Thời gian thực, Nút chức năng, Đăng nhập)
  Widget _buildHeaderControlBar(dynamic profile, PlannerProvider planner) {
    final now = DateTime.now();
    final timeStr = DateFormat('MM/dd/yyyy h:mm:ss a').format(now);

    return Container(
      color: const Color(0xFFE8EEF4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Học kỳ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: Colors.white,
                  child: Text(profile.semester, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                ),
                const SizedBox(width: 14),
                const Text('Năm học: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Text(profile.academicYear, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(width: 6),
                      const Text('◀  ▶', style: TextStyle(fontSize: 10, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const Text('Thời gian: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                Text(timeStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                const SizedBox(width: 24),
                // Quick action buttons from screenshot
                _buildTopLink('📁 Phiên bản mới', () => _showInfoDialog('Phiên bản mới', 'Cổng đào tạo phiên bản nâng cấp v2026.1 - Trường Đại học Tây Nguyên.')),
                _buildTopLink('🔖 Qui chế 1574', () => _showInfoDialog('Qui chế 1574', 'Qui chế đào tạo theo hệ thống tín chỉ số 1574/QĐ-ĐHTN (Tối thiểu 12 TC, tối đa 24 TC, hè tối đa 11 TC).')),
                _buildTopLink('📚 Hướng dẫn sử dụng', () => _tabController.animateTo(7)),
                _buildTopLink('🤖 Cố vấn AI', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAdvisorScreen()))),
                _buildTopLink('🗺️ Cây tiên quyết', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrerequisiteRoadmapScreen()))),
                _buildTopLink('📊 Giả lập GPA', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GpaSimulatorScreen()))),
                _buildTopLink('SHCD 2021', () => _showInfoDialog('SHCD 2021', 'Sinh hoạt công dân - sinh viên đầu khóa năm học 2021-2026.')),
                _buildTopLink('HD PM QLKH', () => _showInfoDialog('HD PM QLKH', 'Hướng dẫn sử dụng phần mềm Quản lý Khoa học Trường ĐH Tây Nguyên.')),
                _buildTopLink('Đề tài NCKH', () => _showInfoDialog('Đề tài NCKH', 'Cổng nộp và đăng ký đề tài Nghiên cứu khoa học Sinh viên.')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildInputField(
                  label: 'Mã SV:',
                  controller: _studentIdController,
                  width: 95,
                  hintText: 'Nhập MSSV...',
                  onSubmitted: (_) => _handleApplyStudent(planner),
                ),
                const SizedBox(width: 8),
                _buildInputField(
                  label: 'Ngày sinh:',
                  controller: _birthDateController,
                  width: 95,
                  hintText: 'dd/mm/yyyy',
                  onSubmitted: (_) => _handleApplyStudent(planner),
                ),
                const SizedBox(width: 8),
                _buildInputField(
                  label: 'Mật khẩu:',
                  controller: _passwordController,
                  width: 85,
                  isPassword: true,
                  onSubmitted: (_) => _handleApplyStudent(planner),
                ),
                const SizedBox(width: 8),
                _buildWinButton(
                  'Đồng ý',
                  Icons.check,
                  Colors.green,
                  onTap: () => _handleApplyStudent(planner),
                ),
                const SizedBox(width: 6),
                _buildWinButton(
                  'Chọn SV TTN',
                  Icons.people,
                  const Color(0xFF1E3A8A),
                  onTap: () => _showStudentListDialog(context, planner),
                ),
                const SizedBox(width: 6),
                _buildWinButton(
                  'Đổi mật khẩu',
                  Icons.key,
                  Colors.amber.shade800,
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const SizedBox(width: 6),
                _buildWinButton(
                  'Close',
                  Icons.exit_to_app,
                  Colors.blueGrey.shade700,
                  onTap: () => _handleLogoutStudent(planner),
                ),
                const SizedBox(width: 6),
                _buildWinButton(
                  '🤖 AI Cố vấn',
                  Icons.psychology,
                  const Color(0xFF7C3AED),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAdvisorScreen())),
                ),
                const SizedBox(width: 6),
                _buildWinButton(
                  '🗺️ Tiên quyết',
                  Icons.account_tree,
                  const Color(0xFF0D9488),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrerequisiteRoadmapScreen())),
                ),
                const SizedBox(width: 6),
                _buildWinButton(
                  '📊 Giả lập GPA',
                  Icons.calculate,
                  const Color(0xFFEA580C),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GpaSimulatorScreen())),
                ),
                const SizedBox(width: 6),
                _buildWinButton(
                  'Close',
                  Icons.exit_to_app,
                  Colors.blue,
                  onTap: () => _handleCloseOrReset(planner),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLink(String title, [VoidCallback? onTap]) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onTap,
        child: Text(
          title,
          style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), decoration: TextDecoration.underline),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    double width = 80,
    bool isPassword = false,
    String? hintText,
    ValueChanged<String>? onSubmitted,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B21A8), fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Container(
          width: width,
          height: 25,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) {
              if (label.contains('Mã SV')) {
                setState(() {});
              }
            },
            onSubmitted: onSubmitted,
          ),
        ),
      ],
    );
  }

  Widget _buildWinButton(String text, IconData icon, Color color, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Student details strip (Mai Đàm Thế Kiên, K23, TBCTL, CVHT)
  Widget _buildStudentInfoBar(dynamic profile, PlannerProvider planner) {
    if (_lastSyncedStudentId.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
        ),
        child: const Row(
          children: [
            Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
            SizedBox(width: 6),
            Text(
              'Chưa đăng nhập • Vui lòng nhập Mã SV và Ngày sinh ở trên rồi bấm [Đồng ý] để vào phần mềm',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }

    final currentMsv = _lastSyncedStudentId;
    final ttnStudent = TTNDatabase.getStudent(currentMsv);
    final displayedName = ttnStudent != null
        ? (ttnStudent['fullName'] as String? ?? profile.fullName)
        : (currentMsv == profile.studentId ? profile.fullName : 'Sinh viên $currentMsv');
    final displayedCohort = ttnStudent != null
        ? (ttnStudent['cohort'] as String? ?? profile.cohort)
        : profile.cohort;
    final displayedMajor = ttnStudent != null
        ? (ttnStudent['major'] as String? ?? profile.major)
        : profile.major;
    final majorInfo = TTNDatabase.findMajor(displayedMajor);
    final displayedBadge = displayedMajor.startsWith(majorInfo.code)
        ? displayedMajor
        : '${majorInfo.code} ${majorInfo.name}';
    final tbctl = TTNDatabase.calculateGpaForStudent(currentMsv, displayedMajor);
    final cvhtText = (ttnStudent != null && ttnStudent['advisor'] != null)
        ? 'CVHT: ${ttnStudent['advisor']}'
        : 'CVHT: ${majorInfo.defaultAdvisor}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              color: const Color(0xFFF1F5F9),
            ),
            child: Row(
              children: [
                const Icon(Icons.radio_button_checked, size: 12, color: Colors.black87),
                const SizedBox(width: 4),
                Text(displayedBadge, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '$displayedName - ${displayedCohort.contains("K23") ? displayedCohort : "$displayedMajor $displayedCohort"}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
          ),
          const SizedBox(width: 14),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              children: [
                const TextSpan(
                  text: 'Điểm TBCTL: ',
                  style: TextStyle(color: Color(0xFF1E3A8A)),
                ),
                TextSpan(
                  text: tbctl.toStringAsFixed(2),
                  style: const TextStyle(color: Color(0xFFDC2626)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              cvhtText,
              style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note, size: 16, color: Color(0xFF1E3A8A)),
            tooltip: 'Chỉnh sửa thông tin sinh viên',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showEditProfileDialog(context, planner),
          ),
        ],
      ),
    );
  }

  // --- Student ID Input, Dialogs & Actions ---
  void _handleApplyStudent(PlannerProvider planner) {
    final rawId = _studentIdController.text.trim();
    if (rawId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập Mã số sinh viên!'),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final inputBirthDate = _birthDateController.text.trim();
    if (inputBirthDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập Ngày sinh của sinh viên!'),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Kiểm tra ngày sinh đúng cho từng mã sinh viên (Tuyệt đối không cho phép nhập sai ngày sinh vẫn báo đúng)
    final isBirthDateValid = TTNDatabase.verifyBirthDate(rawId, inputBirthDate);
    if (!isBirthDateValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ngày sinh không chính xác cho sinh viên $rawId! Vui lòng kiểm tra lại ngày sinh.'),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Mật khẩu không bắt buộc khi vào xem thông tin/kết quả học tập, chỉ cần Mã SV và Ngày sinh là được
    final inputPassword = _passwordController.text.trim();
    if (inputPassword.isNotEmpty) {
      final bDateRaw = TTNDatabase.getBirthDateForStudent(rawId).replaceAll('/', '');
      if (inputPassword == bDateRaw) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Mật khẩu không phải là ngày sinh! Vui lòng nhập đúng mật khẩu đã tạo trên hệ thống cho SV $rawId.'),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      final isPasswordValid = TTNDatabase.verifyPassword(rawId, inputPassword);
      if (!isPasswordValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Mật khẩu không chính xác cho sinh viên $rawId! Vui lòng nhập đúng mật khẩu đã tạo trên hệ thống.'),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
      _verifiedPasswordStudentId = rawId;
    } else {
      _verifiedPasswordStudentId = '';
    }

    final autoBirthDate = TTNDatabase.getBirthDateForStudent(rawId);
    _birthDateController.text = autoBirthDate;
    final bDate = autoBirthDate;

    // Tra cứu trong database mọi sinh viên và mọi ngành thuộc ĐH Tây Nguyên
    final ttnStudent = TTNDatabase.getStudent(rawId);
    final targetMajor = ttnStudent != null ? (ttnStudent['major'] as String? ?? 'Công nghệ thông tin') : 'Công nghệ thông tin';
    final calculatedGpa = TTNDatabase.calculateGpaForStudent(rawId, targetMajor);

    final name = ttnStudent != null ? (ttnStudent['fullName'] as String? ?? 'Sinh viên $rawId') : 'Sinh viên $rawId';
    final major = ttnStudent != null ? (ttnStudent['major'] as String? ?? 'Công nghệ thông tin') : 'Công nghệ thông tin';
    final cohort = ttnStudent != null ? (ttnStudent['cohort'] as String? ?? 'K23') : 'K23';
    final faculty = ttnStudent != null ? (ttnStudent['faculty'] as String? ?? 'Khoa KHTN & Công nghệ') : 'Khoa KHTN & Công nghệ';
    final advisor = ttnStudent != null ? (ttnStudent['advisor'] as String? ?? 'Cố vấn học tập TTN') : 'Cố vấn học tập TTN';

    final updated = planner.profile.copyWith(
      studentId: rawId,
      fullName: name,
      major: major,
      cohort: cohort,
      faculty: faculty,
      advisor: advisor,
      birthDate: bDate,
      currentGpa: calculatedGpa,
    );
    _lastSyncedStudentId = rawId;
    planner.updateProfile(updated);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Đã tải hồ sơ sinh viên TTN: $name (MSSV: $rawId • Ngành: $major • TBCTL: ${calculatedGpa.toStringAsFixed(2)})'),
        backgroundColor: const Color(0xFF15803D),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Xác thực mật khẩu khi người dùng thực hiện thao tác Đăng ký tín chỉ (Thêm / Bớt học phần)
  /// Đăng nhập xem thông tin chỉ cần Mã SV + Ngày sinh, chỉ khi ĐKTC mới bắt buộc nhập mật khẩu
  Future<bool> _ensurePasswordVerifiedForRegistration(PlannerProvider planner) async {
    final currentMsv = _lastSyncedStudentId.isNotEmpty
        ? _lastSyncedStudentId
        : (_studentIdController.text.trim().isNotEmpty ? _studentIdController.text.trim() : planner.profile.studentId);

    if (currentMsv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng đăng nhập bằng Mã SV và Ngày sinh ở trên trước khi thực hiện đăng ký tín chỉ!'),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }

    // Nếu đã xác thực mật khẩu cho sinh viên này trong phiên làm việc, cho phép thực hiện ngay
    if (_verifiedPasswordStudentId == currentMsv) {
      return true;
    }

    // Nếu trên thanh điều khiển người dùng đã nhập mật khẩu và mật khẩu đó đúng:
    final topPassword = _passwordController.text.trim();
    if (topPassword.isNotEmpty && TTNDatabase.verifyPassword(currentMsv, topPassword)) {
      _verifiedPasswordStudentId = currentMsv;
      return true;
    }

    // Chưa có mật khẩu hoặc mật khẩu chưa xác thực: Hiển thị dialog yêu cầu nhập mật khẩu để đăng ký tín chỉ
    final passCtrl = TextEditingController();
    bool isObscured = true;
    String? errorMessage;

    final authenticated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final ttnStudent = TTNDatabase.getStudent(currentMsv);
          final studentName = ttnStudent != null
              ? (ttnStudent['fullName'] as String? ?? planner.profile.fullName)
              : planner.profile.fullName;

          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.lock_clock, color: Color(0xFF1E3A8A), size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Xác thực Mật khẩu Đăng ký Tín chỉ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sinh viên: $studentName (MSSV: $currentMsv)',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Theo quy chế TTN: Đăng nhập xem điểm/lịch thi chỉ cần Mã SV và Ngày sinh. Khi thực hiện Thêm/Bớt đăng ký tín chỉ, bạn cần nhập mật khẩu để xác nhận.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Mật khẩu đăng ký tín chỉ:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passCtrl,
                    obscureText: isObscured,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Nhập mật khẩu của SV $currentMsv...',
                      hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                      prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Color(0xFF1E3A8A)),
                      suffixIcon: IconButton(
                        icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, size: 18, color: Colors.grey),
                        onPressed: () => setDlgState(() => isObscured = !isObscured),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onSubmitted: (_) {
                      final input = passCtrl.text.trim();
                      if (input.isEmpty) {
                        setDlgState(() {
                          errorMessage = '⚠️ Vui lòng nhập mật khẩu của sinh viên!';
                        });
                        return;
                      }
                      final bDateRaw = TTNDatabase.getBirthDateForStudent(currentMsv).replaceAll('/', '');
                      if (input == bDateRaw) {
                        setDlgState(() {
                          errorMessage = '❌ Mật khẩu không phải là ngày sinh! Vui lòng nhập đúng mật khẩu đã tạo trên hệ thống.';
                        });
                        return;
                      }
                      if (TTNDatabase.verifyPassword(currentMsv, input)) {
                        _passwordController.text = input;
                        _verifiedPasswordStudentId = currentMsv;
                        Navigator.of(ctx).pop(true);
                      } else {
                        setDlgState(() {
                          errorMessage = '❌ Mật khẩu không chính xác cho sinh viên $currentMsv!';
                        });
                      }
                    },
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.error_outline, size: 14, color: Color(0xFFDC2626)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Xác nhận', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () {
                  final input = passCtrl.text.trim();
                  if (input.isEmpty) {
                    setDlgState(() {
                      errorMessage = '⚠️ Vui lòng nhập mật khẩu của sinh viên!';
                    });
                    return;
                  }
                  final bDateRaw = TTNDatabase.getBirthDateForStudent(currentMsv).replaceAll('/', '');
                  if (input == bDateRaw) {
                    setDlgState(() {
                      errorMessage = '❌ Mật khẩu không phải là ngày sinh! Vui lòng nhập đúng mật khẩu đã tạo trên hệ thống.';
                    });
                    return;
                  }
                  if (TTNDatabase.verifyPassword(currentMsv, input)) {
                    _passwordController.text = input;
                    _verifiedPasswordStudentId = currentMsv;
                    Navigator.of(ctx).pop(true);
                  } else {
                    setDlgState(() {
                      errorMessage = '❌ Mật khẩu không chính xác cho sinh viên $currentMsv!';
                    });
                  }
                },
              ),
            ],
          );
        },
      ),
    );

    return authenticated == true;
  }

  void _showStudentListDialog(BuildContext context, PlannerProvider planner) {
    final allStudents = TTNDatabase.getAllStudents();
    String filter = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final filtered = allStudents.where((s) {
            final id = (s['studentId'] as String).toLowerCase();
            final name = (s['fullName'] as String).toLowerCase();
            return id.contains(filter.toLowerCase()) || name.contains(filter.toLowerCase());
          }).toList();

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.school, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chọn Sinh viên ĐH Tây Nguyên (Tất cả các ngành & khoa)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên hoặc MSSV (VD: 23103003, Kiên, Anh...)',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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

                        return ListTile(
                          dense: true,
                          tileColor: isCurrent ? const Color(0xFFEFF6FF) : null,
                          title: Text(
                            '${s['studentId']} - ${s['fullName']}',
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? const Color(0xFF1D4ED8) : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            'Ngành: ${s['major']} ${s['cohort']} • Đã xếp: ${s['slotsCount']} tiết',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          trailing: isCurrent
                              ? const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 18)
                              : const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                          onTap: () {
                            _studentIdController.text = s['studentId'];
                            _birthDateController.text = TTNDatabase.getBirthDateForStudent(s['studentId']);
                            _passwordController.text = TTNDatabase.getPasswordForStudent(s['studentId']);
                            _handleApplyStudent(planner);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final currentMsv = _studentIdController.text.trim().isNotEmpty
        ? _studentIdController.text.trim()
        : '23103035';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('Đổi mật khẩu sinh viên', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đang đổi mật khẩu cho MSSV: $currentMsv', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            TextField(
              controller: oldPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu cũ', isDense: true, border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới (tối thiểu 6 ký tự)', isDense: true, border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () {
              final oldP = oldPassCtrl.text.trim();
              final newP = newPassCtrl.text.trim();

              final hasExisting = TTNDatabase.studentPasswords.containsKey(currentMsv) &&
                  TTNDatabase.studentPasswords[currentMsv]!.isNotEmpty;
              if (hasExisting && !TTNDatabase.verifyPassword(currentMsv, oldP)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Mật khẩu cũ không chính xác! Không thể thay đổi.'),
                    backgroundColor: Color(0xFFDC2626),
                  ),
                );
                return;
              }

              if (newP.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Mật khẩu mới phải có tối thiểu 6 ký tự!'),
                    backgroundColor: Color(0xFFDC2626),
                  ),
                );
                return;
              }

              final bDateRaw = TTNDatabase.getBirthDateForStudent(currentMsv).replaceAll('/', '');
              if (newP == bDateRaw) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Mật khẩu không được đặt trùng với ngày sinh!'),
                    backgroundColor: Color(0xFFDC2626),
                  ),
                );
                return;
              }

              TTNDatabase.studentPasswords[currentMsv] = newP;
              _passwordController.text = newP;
              _verifiedPasswordStudentId = currentMsv;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Đã cập nhật mật khẩu mới cho sinh viên $currentMsv thành công!'),
                  backgroundColor: const Color(0xFF15803D),
                ),
              );
            },
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }

  void _handleLogoutStudent(PlannerProvider planner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Color(0xFF1E3A8A)),
            SizedBox(width: 8),
            Text('Đóng phiên làm việc (Close)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Bạn có muốn đóng phiên làm việc và đăng xuất tài khoản sinh viên hiện tại không?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _studentIdController.clear();
                _birthDateController.clear();
                _passwordController.clear();
                _lastSyncedStudentId = '';
                _verifiedPasswordStudentId = '';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Đã đóng phiên làm việc và đăng xuất thành công!'),
                  backgroundColor: Color(0xFF475569),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Đồng ý đóng'),
          ),
        ],
      ),
    );
  }

  void _showPrintDocumentDialog({
    required BuildContext context,
    required String documentTitle,
    required String studentInfo,
    required Widget tableContent,
    String? note,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.print, color: Color(0xFF1E3A8A), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Xem trước bản in: $documentTitle',
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quốc hiệu tiêu ngữ & Tên trường
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('BỘ GIÁO DỤC VÀ ĐÀO TẠO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          const Text('TRƯỜNG ĐẠI HỌC TÂY NGUYÊN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                          Container(height: 1, width: 120, color: Colors.black87, margin: const EdgeInsets.only(top: 2)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          const Text('Độc lập - Tự do - Hạnh phúc', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          Container(height: 1, width: 140, color: Colors.black87, margin: const EdgeInsets.only(top: 2)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    documentTitle.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'HỌC KỲ 1 - NĂM HỌC 2026-2027',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      studentInfo,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  tableContent,
                  if (note != null) ...[
                    const SizedBox(height: 10),
                    Text(note, style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
                  ],
                  const SizedBox(height: 24),
                  // Ký tên
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        children: [
                          Text('CỐ VẤN HỌC TẬP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('(Ký và ghi rõ họ tên)', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                          SizedBox(height: 45),
                          Text('ThS. Nguyễn Thị Như', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Đắk Lắk, ngày ${DateTime.now().day} tháng ${DateTime.now().month} năm ${DateTime.now().year}', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 2),
                          const Text('SINH VIÊN ĐĂNG KÝ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const Text('(Ký và ghi rõ họ tên)', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 45),
                          const Text('Sinh viên đã xác nhận điện tử', style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ElevatedButton.icon(
            icon: const Icon(Icons.print, size: 16),
            label: const Text('In phiếu / Xuất PDF'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Đã chuẩn bị lệnh in và xuất văn bản PDF thành công!'),
                  backgroundColor: Color(0xFF15803D),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, PlannerProvider planner) {
    final nameCtrl = TextEditingController(text: planner.profile.fullName);
    final allMajors = TTNDatabase.allMajors;
    TTNMajor selectedMajor = TTNDatabase.findMajor(planner.profile.major);
    final cohortCtrl = TextEditingController(text: planner.profile.cohort);
    final gpaCtrl = TextEditingController(text: planner.profile.currentGpa.toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person, color: Color(0xFF1E3A8A)),
              SizedBox(width: 8),
              Text('Thông tin hồ sơ sinh viên TTN', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Họ và tên sinh viên', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ngành đào tạo (Đại học Tây Nguyên):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TTNMajor>(
                        value: selectedMajor,
                        isExpanded: true,
                        items: allMajors.map((m) {
                          return DropdownMenuItem<TTNMajor>(
                            value: m,
                            child: Text(
                              '${m.code} - ${m.name} (${m.faculty})',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (newMajor) {
                          if (newMajor != null) {
                            setDlgState(() {
                              selectedMajor = newMajor;
                              cohortCtrl.text = '${newMajor.name} K23';
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cohortCtrl,
                          decoration: const InputDecoration(labelText: 'Khóa / Lớp', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: gpaCtrl,
                          decoration: const InputDecoration(labelText: 'Điểm TBCTL', isDense: true),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Khoa trực thuộc: ${selectedMajor.faculty}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontStyle: FontStyle.italic),
                  ),
                  Text(
                    'Cố vấn học tập: ${selectedMajor.defaultAdvisor}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final newGpa = double.tryParse(gpaCtrl.text.trim()) ?? planner.profile.currentGpa;
                planner.updateProfile(planner.profile.copyWith(
                  fullName: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : planner.profile.fullName,
                  major: '${selectedMajor.code} ${selectedMajor.name}',
                  cohort: cohortCtrl.text.trim().isNotEmpty ? cohortCtrl.text.trim() : planner.profile.cohort,
                  faculty: selectedMajor.faculty,
                  advisor: selectedMajor.defaultAdvisor,
                  currentGpa: newGpa,
                ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Đã cập nhật ngành học: ${selectedMajor.code} - ${selectedMajor.name} thành công!'),
                    backgroundColor: const Color(0xFF15803D),
                  ),
                );
              },
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCloseOrReset(PlannerProvider planner) {
    _studentIdController.clear();
    _birthDateController.clear();
    _passwordController.clear();
    _lastSyncedStudentId = '';
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xóa thông tin phiên làm việc. Vui lòng nhập lại Mã SV, Ngày sinh và Mật khẩu.'),
        backgroundColor: Color(0xFF1E3A8A),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showEditGradeDialog({
    required PlannerProvider planner,
    required String courseCode,
    required String courseName,
    required String classId,
    required Map<String, dynamic> currentInfo,
  }) {
    final currentMsv = _studentIdController.text.trim().isNotEmpty
        ? _studentIdController.text.trim()
        : planner.profile.studentId;

    final bpController = TextEditingController(text: currentInfo['boPhan'] as String? ?? '');
    final th1Controller = TextEditingController(text: currentInfo['thi1'] as String? ?? '');
    final th2Controller = TextEditingController(text: currentInfo['thi2'] as String? ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final bp = bpController.text.trim();
          final th1 = th1Controller.text.trim();
          final calc = TTNDatabase.computeCourseGradeDetails(bp, th1);
          final diem1 = calc['diem1'] ?? '';
          final diemChu = calc['diemChu'] ?? '';
          final diemSo = calc['diemSo'] ?? '';

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit_note, color: Color(0xFF0284C7), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cập nhật điểm môn học: $courseName',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mã lớp HP: $classId • MSSV: $currentMsv\nNhập điểm mới lên web để tự động cập nhật toàn hệ thống.',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: bpController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Điểm Bộ phận (40%)',
                            hintText: 'VD: 9.3',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: th1Controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Điểm Thi 1 (60%)',
                            hintText: 'VD: 9.0',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: th2Controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Điểm Thi 2 (nếu có thi lại)',
                      hintText: 'Để trống nếu không thi lại',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 14),
                  // Live preview box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Điểm TK (Hệ 10)', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                            Text(diem1.isNotEmpty ? diem1 : 'Chưa có', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0284C7))),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Điểm chữ', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                            Text(diemChu, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: diemChu == 'X' ? Colors.grey : const Color(0xFF16A34A))),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Điểm hệ 4', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                            Text(diemSo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final newBp = bpController.text.trim();
                  final newTh1 = th1Controller.text.trim();
                  final newTh2 = th2Controller.text.trim();

                  TTNDatabase.updateSemesterCourseGrade(
                    msv: currentMsv,
                    courseCode: courseCode,
                    boPhan: newBp,
                    thi1: newTh1,
                    thi2: newTh2,
                  );

                  // Cập nhật lại toàn bộ ứng dụng (Profile, TBCTL, Lộ trình học tập)
                  final updatedGpa = TTNDatabase.calculateGpaForStudent(currentMsv, planner.profile.major);
                  final updatedPassed = TTNDatabase.getPassedCoursesForStudent(currentMsv, planner.profile.major);
                  planner.updateProfile(planner.profile.copyWith(
                    currentGpa: updatedGpa,
                    passedCourses: updatedPassed,
                  ));

                  setState(() {});
                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Đã cập nhật điểm môn $courseName! Điểm TBCTL & Chương trình đào tạo đã được đồng bộ.'),
                      backgroundColor: const Color(0xFF15803D),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Lưu & Đồng bộ ngay'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditExamScheduleDialog({
    required PlannerProvider planner,
    required String courseCode,
    required String courseName,
    required String classId,
  }) {
    final currentMsv = _lastSyncedStudentId.isNotEmpty
        ? _lastSyncedStudentId
        : (_studentIdController.text.trim().isNotEmpty
            ? _studentIdController.text.trim()
            : planner.profile.studentId);

    final currentExam = TTNDatabase.getExamScheduleForCourse(courseCode, currentMsv);
    final buoi1Ctrl = TextEditingController(text: currentExam['buoi1'] as String? ?? 'Sáng');
    final ngay1Ctrl = TextEditingController(text: currentExam['ngay1'] as String? ?? '');
    final phong1Ctrl = TextEditingController(text: currentExam['phong1'] as String? ?? '');
    final buoi2Ctrl = TextEditingController(text: currentExam['buoi2'] as String? ?? '');
    final ngay2Ctrl = TextEditingController(text: currentExam['ngay2'] as String? ?? '');
    final phong2Ctrl = TextEditingController(text: currentExam['phong2'] as String? ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit_calendar, color: Color(0xFF0284C7), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cập nhật lịch thi: $courseName',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF0284C7), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lớp HP: $classId • MSSV: $currentMsv\nNhập ngày, buổi và phòng thi thực tế trên thông báo trường.',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF0369A1)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('LỊCH THI ĐỢT 1 (CHÍNH THỨC):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: buoi1Ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Buổi thi 1',
                        hintText: 'Sáng / Chiều',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: ngay1Ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Ngày thi 1',
                        hintText: 'dd/MM/yyyy',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: phong1Ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Phòng thi 1',
                        hintText: 'P.6.11 / Lab...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('LỊCH THI ĐỢT 2 (NẾU THI LẠI):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: buoi2Ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Buổi thi 2',
                        hintText: 'Để trống nếu không thi lại',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: ngay2Ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Ngày thi 2',
                        hintText: 'dd/MM/yyyy',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: phong2Ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Phòng thi 2',
                        hintText: 'Phòng thi lại...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              TTNDatabase.updateExamScheduleForCourse(
                msv: currentMsv,
                courseCode: courseCode,
                buoi1: buoi1Ctrl.text.trim(),
                ngay1: ngay1Ctrl.text.trim(),
                phong1: phong1Ctrl.text.trim(),
                buoi2: buoi2Ctrl.text.trim(),
                ngay2: ngay2Ctrl.text.trim(),
                phong2: phong2Ctrl.text.trim(),
              );

              setState(() {});
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Đã cập nhật lịch thi môn $courseName ($courseCode) thành công!'),
                  backgroundColor: const Color(0xFF15803D),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Lưu lịch thi'),
          ),
        ],
      ),
    );
  }

  // 4. Tab bar
  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF2563EB),
        indicatorWeight: 3,
        labelColor: const Color(0xFF1E3A8A),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelColor: const Color(0xFF475569),
        tabs: _tabs.map((t) => Tab(text: t, height: 32)).toList(),
      ),
    );
  }

  // TAB 1: ĐĂNG KÝ HỌC PHẦN (SCREENSHOT 1)
  Widget _buildCourseRegistrationTab(PlannerProvider planner) {
    final currentMsv = _studentIdController.text.trim().isNotEmpty
        ? _studentIdController.text.trim()
        : planner.profile.studentId;
    final ttnStudent = TTNDatabase.getStudent(currentMsv);
    final displayedMajor = ttnStudent != null
        ? (ttnStudent['major'] as String? ?? planner.profile.major)
        : planner.profile.major;
    final curriculum = MockDataService.getCurriculumForMajor(displayedMajor);
    final studentScores = TTNDatabase.getStudentCourseScores(currentMsv);
    final safeIndex = _selectedCurriculumIndex.clamp(0, curriculum.length - 1);
    final selectedCurriculumItem = curriculum[safeIndex];
    final selectedCourseCode = selectedCurriculumItem['code'] as String;
    final course = planner.getCourseByCode(selectedCourseCode);
    final availableSections = course?.sections ?? [];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: CHƯƠNG TRÌNH ĐÀO TẠO
        RepaintBoundary(
          child: Container(
            width: 380,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFCBD5E1))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: const Color(0xFFE0E7FF),
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                child: const Text(
                  'CHƯƠNG TRÌNH ĐÀO TẠO',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF991B1B)),
                ),
              ),
              // Table Header
              Container(
                color: const Color(0xFF0284C7),
                child: const Row(
                  children: [
                    _TableHeaderCell('TT', width: 35),
                    _TableHeaderCell('Mã HP', width: 85),
                    Expanded(child: _TableHeaderCell('Tên HP (TC)')),
                    _TableHeaderCell('Điểm', width: 45),
                  ],
                ),
              ),
              // Curriculum List
              Expanded(
                child: ListView.builder(
                  itemExtent: 26.0,
                  physics: const ClampingScrollPhysics(),
                  itemCount: curriculum.length,
                  itemBuilder: (ctx, idx) {
                    final item = curriculum[idx];
                    final isSelected = idx == _selectedCurriculumIndex;
                    final tt = item['tt'] as int;
                    final courseCode = item['code'] as String;
                    // Lấy điểm chính xác của sinh viên hiện tại theo MSSV
                    final score = studentScores.containsKey(courseCode)
                        ? studentScores[courseCode]
                        : (item['score'] as double?);

                    Color rowBg;
                    if (isSelected) {
                      rowBg = const Color(0xFF0284C7);
                    } else if (tt >= 62 && tt <= 82) {
                      rowBg = const Color(0xFFFFFF00); // Màu vàng rực rỡ học phần mở ĐK khớp 100% Cổng TTN
                    } else if (tt >= 83 || tt == 60) {
                      rowBg = const Color(0xFF00FFFF).withValues(alpha: 0.35); // Cyan khớp Cổng TTN
                    } else if ((tt >= 56 && tt <= 59) || tt == 61) {
                      rowBg = const Color(0xFF94A3B8).withValues(alpha: 0.4); // Xám Quốc phòng & Quy trình
                    } else {
                      rowBg = Colors.white;
                    }

                    Color codeColor;
                    if (isSelected) {
                      codeColor = Colors.white;
                    } else if (tt >= 62 && tt <= 82) {
                      codeColor = const Color(0xFF0F172A);
                    } else {
                      codeColor = const Color(0xFF0369A1);
                    }

                    Color textColor;
                    if (isSelected) {
                      textColor = Colors.white;
                    } else {
                      textColor = Colors.black87;
                    }

                    String scoreText = '';
                    if (score != null) {
                      if (tt == 61 && score == 8.0) {
                        scoreText = '8';
                      } else {
                        scoreText = score.toStringAsFixed(1);
                      }
                    }

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCurriculumIndex = idx;
                          _selectedAvailableSection = null;
                        });
                      },
                      child: Container(
                        color: rowBg,
                        child: Row(
                          children: [
                            Container(
                              width: 35,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              alignment: Alignment.center,
                              child: Text(
                                '${item['tt']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Container(
                              width: 85,
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              child: Text(
                                '${item['code']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: codeColor,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                child: Text(
                                  '${item['name']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Container(
                              width: 45,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              alignment: Alignment.center,
                              child: Text(
                                scoreText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (score != null && score < 4.0 ? Colors.red : Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        ),

        // Right Column: DANH SÁCH HỌC PHẦN CÓ KẾ HOẠCH & ĐÃ ĐĂNG KÝ
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Notices from screenshot
                const Text(
                  'Đăng ký học phần Học kỳ: 1     Năm học: 2026-2027',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
                const Text(
                  'Đăng ký Sớm và Bình thường từ ngày: 06/07/2026  Đến ngày: 02/08/2026',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                ),
                const Text(
                  'Đăng ký Muộn từ ngày: 03/08/2026  Đến ngày: 16/08/2026 (Chỉ cho phép THÊM↓ hoặc BỚT↑ lớp học phần chưa học)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
                const SizedBox(height: 6),

                // Table 1: DANH SÁCH HỌC PHẦN CÓ KẾ HOẠCH GIẢNG DẠY
                Container(
                  color: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DANH SÁCH HỌC PHẦN CÓ KẾ HOẠCH GIẢNG DẠY: [${selectedCurriculumItem['name']}]',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                      ),
                      if (course != null)
                        InkWell(
                          onTap: () => showDialog(context: context, builder: (_) => PrerequisiteDialog(course: course)),
                          child: const Text('🔍 Xem môn tiên quyết', style: TextStyle(color: Colors.white, fontSize: 11, decoration: TextDecoration.underline)),
                        ),
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xFF059669),
                  child: const Row(
                    children: [
                      _TableHeaderCell('TT', width: 35),
                      _TableHeaderCell('Lớp HP', width: 130),
                      Expanded(child: _TableHeaderCell('Tên HP (TC)')),
                      _TableHeaderCell('SL', width: 50),
                      _TableHeaderCell('Lớp (Buổi dự kiến)', width: 140),
                      _TableHeaderCell('GV', width: 130),
                    ],
                  ),
                ),
                // Available sections list
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: availableSections.isEmpty
                      ? const Center(
                          child: Text('Không có lớp mở cho học phần này trong học kỳ hiện tại', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        )
                      : ListView.builder(
                          itemCount: availableSections.length,
                          itemBuilder: (ctx, idx) {
                            final sec = availableSections[idx];
                            final isSelected = _selectedAvailableSection?.id == sec.id;
                            final slotsText = sec.slots.map((s) => '${s.dayName} T${s.startPeriod}-${s.endPeriod}').join(', ');

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedAvailableSection = sec;
                                });
                              },
                              child: Container(
                                color: isSelected ? const Color(0xFF86EFAC) : (idx % 2 == 0 ? Colors.white : const Color(0xFFF0FDF4)),
                                child: Row(
                                  children: [
                                    Container(width: 35, padding: const EdgeInsets.symmetric(vertical: 4), alignment: Alignment.center, child: Text('${idx + 1}', style: const TextStyle(fontSize: 11))),
                                    Container(width: 130, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2), child: Text(sec.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                    Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4), child: Text(sec.courseName, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
                                    Container(width: 50, padding: const EdgeInsets.symmetric(vertical: 4), alignment: Alignment.center, child: Text('${sec.enrolled}/${sec.capacity}', style: const TextStyle(fontSize: 11))),
                                    Container(width: 140, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2), child: Text(slotsText, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                    Container(width: 130, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2), child: Text(sec.lecturer, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 6),
                // Action buttons: In, Thêm, Bớt, Lý do
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.print, size: 20, color: Color(0xFF1E3A8A)),
                      tooltip: 'In danh sách học phần đã đăng ký',
                      onPressed: () {
                        final studentId = _lastSyncedStudentId.isNotEmpty ? _lastSyncedStudentId : planner.profile.studentId;
                        final ttnStudent = TTNDatabase.getStudent(studentId);
                        final studentName = ttnStudent != null ? (ttnStudent['fullName'] as String? ?? planner.profile.fullName) : planner.profile.fullName;
                        final major = ttnStudent != null ? (ttnStudent['major'] as String? ?? planner.profile.major) : planner.profile.major;
                        final cohort = ttnStudent != null ? (ttnStudent['cohort'] as String? ?? planner.profile.cohort) : planner.profile.cohort;

                        final regSections = planner.activePlan.selectedSections.values.toList();
                        _showPrintDocumentDialog(
                          context: context,
                          documentTitle: 'Phiếu Đăng Ký Học Phần',
                          studentInfo: 'Họ và tên sinh viên: $studentName  •  MSSV: $studentId\nNgành đào tạo: $major  •  Khóa học: $cohort\nTổng số tín chỉ đăng ký: ${regSections.length * 2 + 2} TC  •  Học phí tạm tính: 12.908.571 VNĐ',
                          tableContent: Table(
                            border: TableBorder.all(color: Colors.grey.shade400),
                            columnWidths: const {
                              0: FixedColumnWidth(35),
                              1: FixedColumnWidth(130),
                              2: FlexColumnWidth(),
                              3: FixedColumnWidth(55),
                              4: FixedColumnWidth(80),
                            },
                            children: [
                              const TableRow(
                                decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                                children: [
                                  Padding(padding: EdgeInsets.all(6), child: Text('TT', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                  Padding(padding: EdgeInsets.all(6), child: Text('Mã Lớp HP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                  Padding(padding: EdgeInsets.all(6), child: Text('Tên học phần', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                  Padding(padding: EdgeInsets.all(6), child: Text('Số TC', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                  Padding(padding: EdgeInsets.all(6), child: Text('Trạng thái', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                ],
                              ),
                              ...regSections.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final sec = entry.value;
                                final credits = planner.getCourseByCode(sec.courseCode)?.credits ?? 2;
                                return TableRow(
                                  children: [
                                    Padding(padding: const EdgeInsets.all(6), child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                                    Padding(padding: const EdgeInsets.all(6), child: Text(sec.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                    Padding(padding: const EdgeInsets.all(6), child: Text(sec.courseName, style: const TextStyle(fontSize: 11))),
                                    Padding(padding: const EdgeInsets.all(6), child: Text('$credits', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                                    const Padding(padding: EdgeInsets.all(6), child: Text('Chính thức', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))),
                                  ],
                                );
                              }),
                            ],
                          ),
                          note: '* Ghi chú: Phiếu đăng ký này được trích xuất từ Cổng đăng ký tín chỉ ĐH Tây Nguyên. Sinh viên lưu giữ để đối chiếu khi cần thiết.',
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE2E8F0),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: _selectedAvailableSection == null
                          ? null
                          : () async {
                              final ok = await _ensurePasswordVerifiedForRegistration(planner);
                              if (!ok) return;

                              // Check conflict
                              planner.selectSection(_selectedAvailableSection!);
                              setState(() {
                                _reasonAddBlocked = planner.hasErrors
                                    ? planner.currentIssues.first.description
                                    : 'Thêm thành công vào thời khóa biểu!';
                              });
                            },
                      icon: const Icon(Icons.arrow_upward, size: 14, color: Colors.green),
                      label: const Text('Thêm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE2E8F0),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: _selectedRegisteredSection == null
                          ? null
                          : () async {
                              final ok = await _ensurePasswordVerifiedForRegistration(planner);
                              if (!ok) return;

                              planner.removeSection(_selectedRegisteredSection!.courseCode);
                              setState(() {
                                _selectedRegisteredSection = null;
                                _reasonRemoveBlocked = 'Đã hủy đăng ký thành công!';
                              });
                            },
                      icon: const Icon(Icons.arrow_downward, size: 14, color: Colors.red),
                      label: const Text('Bớt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFEFF),
                          border: Border.all(color: const Color(0xFF06B6D4)),
                        ),
                        child: Text(
                          _reasonAddBlocked.isEmpty ? 'Lý do Thêm không được (nếu có):' : 'Lý do Thêm: $_reasonAddBlocked',
                          style: TextStyle(fontSize: 11, color: _reasonAddBlocked.contains('lỗi') || _reasonAddBlocked.contains('Trùng') ? Colors.red : Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFEFF),
                          border: Border.all(color: const Color(0xFF06B6D4)),
                        ),
                        child: Text(
                          _reasonRemoveBlocked.isEmpty ? 'Lý do Bớt không được (nếu có):' : 'Lý do Bớt: $_reasonRemoveBlocked',
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Table 2: DANH SÁCH HỌC PHẦN ĐÃ ĐĂNG KÝ
                Container(
                  color: const Color(0xFF9333EA),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: const Row(
                    children: [
                      Text(
                        'DANH SÁCH HỌC PHẦN ĐÃ ĐĂNG KÝ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xFF0284C7),
                  child: const Row(
                    children: [
                      _TableHeaderCell('TT', width: 35),
                      _TableHeaderCell('Mã Lớp HP', width: 135),
                      Expanded(child: _TableHeaderCell('Tên lớp')),
                      _TableHeaderCell('Ngày Insert', width: 95),
                      _TableHeaderCell('Trạng thái', width: 65),
                      _TableHeaderCell('CVHT', width: 45),
                      _TableHeaderCell('Ngày', width: 75),
                      _TableHeaderCell('Chính thức', width: 70),
                    ],
                  ),
                ),
                // Registered list
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                    child: Builder(
                      builder: (ctx) {
                        final officialOrder = [
                          'KC213613',
                          'KC213668',
                          'KC213678',
                          'KC213685',
                          'KC215046',
                          'KC215050',
                          'ML211033',
                          'SP211014',
                        ];

                        // Đảm bảo có đủ 8 học phần chính thức trong phương án
                        final allCourses = planner.courses;
                        for (final code in officialOrder) {
                          if (!planner.activePlan.selectedSections.containsKey(code)) {
                            final match = allCourses.where((c) => c.code == code).firstOrNull;
                            if (match != null && match.sections.isNotEmpty) {
                              planner.activePlan.selectedSections[code] = match.sections.first;
                            }
                          }
                        }

                        final sections = planner.activePlan.selectedSections.values
                            .where((s) => officialOrder.contains(s.courseCode))
                            .toList();
                        // Sắp xếp đúng theo thứ tự trong Cổng TTN (1: KC213613 -> 8: SP211014)
                        sections.sort((a, b) {
                          final idxA = officialOrder.indexOf(a.courseCode);
                          final idxB = officialOrder.indexOf(b.courseCode);
                          if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
                          if (idxA != -1) return -1;
                          if (idxB != -1) return 1;
                          return a.courseCode.compareTo(b.courseCode);
                        });

                        return ListView.builder(
                          itemCount: sections.length,
                          itemBuilder: (ctx, idx) {
                            final sec = sections[idx];
                            final isSelected = _selectedRegisteredSection?.id == sec.id;
                            final meta = _officialRegisteredDetails[sec.courseCode];

                            final idDisplay = meta != null ? (meta['classId'] as String) : sec.id;
                            final classNameDisplay = meta != null ? (meta['className'] as String) : 'Công nghệ thông tin K23 (${sec.enrolled}/${sec.capacity})';
                            final insertDateDisplay = meta != null ? (meta['insertDate'] as String) : '7/15/2026 7';
                            final statusDisplay = meta != null ? (meta['status'] as String) : 'Mở';
                            final cvhtApproved = meta != null ? (meta['cvhtApproved'] as bool) : true;
                            final dateDisplay = meta != null ? (meta['date'] as String) : '20260717 0';
                            final confirmedDisplay = meta != null ? (meta['confirmed'] as String) : 'Rồi';

                            // Màu nền xen kẽ khớp ảnh chụp thực tế
                            Color rowBg;
                            if (isSelected) {
                              rowBg = const Color(0xFF38BDF8);
                            } else if (idx == 0) {
                              rowBg = const Color(0xFF00FFFF).withValues(alpha: 0.15);
                            } else if (idx % 2 == 1) {
                              rowBg = const Color(0xFFD4EDDA).withValues(alpha: 0.45);
                            } else {
                              rowBg = Colors.white;
                            }

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedRegisteredSection = sec;
                                });
                              },
                              child: Container(
                                color: rowBg,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 35,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (idx == 0 || isSelected)
                                            const Text('►', style: TextStyle(fontSize: 8, color: Colors.black87)),
                                          Text(' ${idx + 1}', style: const TextStyle(fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 135,
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                      child: Text(
                                        idDisplay,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                        child: Text(
                                          classNameDisplay,
                                          style: const TextStyle(fontSize: 10.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 95,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(insertDateDisplay, style: const TextStyle(fontSize: 11)),
                                    ),
                                    Container(
                                      width: 65,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      alignment: Alignment.center,
                                      child: Text(statusDisplay, style: const TextStyle(fontSize: 11)),
                                    ),
                                    Container(
                                      width: 45,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        cvhtApproved ? Icons.check_box : Icons.check_box_outline_blank,
                                        size: 14,
                                        color: cvhtApproved ? Colors.black87 : Colors.grey,
                                      ),
                                    ),
                                    Container(
                                      width: 75,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(dateDisplay, style: const TextStyle(fontSize: 11)),
                                    ),
                                    Container(
                                      width: 70,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(confirmedDisplay, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                // Footer: Tổng số tín chỉ đăng ký
                Container(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      const Text(
                        'Tổng số tín chỉ đăng ký: ',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                      Text(
                        '${planner.totalCredits}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                      ),
                      const SizedBox(width: 20),
                      if (planner.hasErrors)
                        Text(
                          '⚠️ Có ${planner.errorCount} lỗi cần xử lý',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                        )
                      else
                        const Text(
                          '✓ Hợp lệ theo quy chế',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // TAB 3: KẾT QUẢ HỌC TẬP (SCREENSHOT 2)
  Widget _buildAcademicResultsTab(PlannerProvider planner) {
    final currentMsv = _lastSyncedStudentId.isNotEmpty
        ? _lastSyncedStudentId
        : (_studentIdController.text.trim().isNotEmpty
            ? _studentIdController.text.trim()
            : planner.profile.studentId);
    final ttnStudent = TTNDatabase.getStudent(currentMsv);
    final displayedName = ttnStudent != null ? (ttnStudent['fullName'] as String? ?? planner.profile.fullName) : planner.profile.fullName;

    final registeredSecs = planner.activePlan.selectedSections.values.toList();
    final resultsList = TTNDatabase.getSemesterResultsTableForStudent(currentMsv, registeredSecs);
    final resultsMap = TTNDatabase.getSemesterResultsForStudent(currentMsv);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner tự động đồng bộ kết quả học tập từ hệ thống ĐH Tây Nguyên
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.fact_check_outlined, size: 16, color: Color(0xFF15803D)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✓ Tự động cập nhật điểm số & kết quả học tập từ hệ thống cho sinh viên: $displayedName ($currentMsv) • ${resultsList.length} học phần',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF14532D)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF15803D)),
                  tooltip: 'Đồng bộ điểm số từ hệ thống',
                  onPressed: () {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã cập nhật và đồng bộ điểm số từ hệ thống cho $displayedName ($currentMsv)'),
                        backgroundColor: const Color(0xFF15803D),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.print, size: 22, color: Color(0xFF1E3A8A)),
                tooltip: 'In bảng điểm kết quả học tập',
                onPressed: () {
                  final studentId = currentMsv;
                  final ttnStudent = TTNDatabase.getStudent(studentId);
                  final studentName = ttnStudent != null ? (ttnStudent['fullName'] as String? ?? planner.profile.fullName) : planner.profile.fullName;
                  final major = ttnStudent != null ? (ttnStudent['major'] as String? ?? planner.profile.major) : planner.profile.major;
                  final gpa = TTNDatabase.calculateGpaForStudent(studentId, major);

                  _showPrintDocumentDialog(
                    context: context,
                    documentTitle: 'Bảng Điểm Kết Quả Học Tập Học Kỳ',
                    studentInfo: 'Họ và tên sinh viên: $studentName  •  MSSV: $studentId\nNgành đào tạo: $major  •  Điểm TBCTL: ${gpa.toStringAsFixed(2)}\nXếp loại học lực: ${gpa >= 2.5 ? "Khá" : (gpa >= 2.0 ? "Trung bình" : "Cảnh báo")}',
                    tableContent: Table(
                      border: TableBorder.all(color: Colors.grey.shade400),
                      columnWidths: const {
                        0: FixedColumnWidth(35),
                        1: FixedColumnWidth(130),
                        2: FlexColumnWidth(),
                        3: FixedColumnWidth(65),
                        4: FixedColumnWidth(65),
                        5: FixedColumnWidth(65),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                          children: [
                            Padding(padding: EdgeInsets.all(6), child: Text('TT', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Lớp HP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Tên học phần', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Bộ phận', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Điểm chữ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Điểm số', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          ],
                        ),
                        ...resultsList.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          final code = item['code'] as String;
                          final info = resultsMap[code] ?? {};
                          final bp = info['boPhan']?.toString() ?? '';
                          return TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(6), child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text(item['classId'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                              Padding(padding: const EdgeInsets.all(6), child: Text(item['name'] as String, style: const TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text(bp.isEmpty ? '-' : bp, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                              Padding(padding: const EdgeInsets.all(6), child: Text(bp.isEmpty ? 'X' : 'B', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold))),
                              Padding(padding: const EdgeInsets.all(6), child: Text(bp.isEmpty ? '0' : '3.0', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                            ],
                          );
                        }),
                      ],
                    ),
                    note: '* Bảng điểm được trích xuất trực tiếp từ Cơ sở dữ liệu Quản lý Đào tạo Trường Đại học Tây Nguyên.',
                  );
                },
              ),
              const Text('KẾT QUẢ ĐĂNG KÝ VÀ ĐIỂM HỌC TẬP - HỌC KỲ 1 (2026-2027)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  final firstCourse = resultsList.isNotEmpty ? resultsList.first : null;
                  if (firstCourse != null) {
                    _showEditGradeDialog(
                      planner: planner,
                      courseCode: firstCourse['code'] as String,
                      courseName: firstCourse['name'] as String,
                      classId: firstCourse['classId'] as String,
                      currentInfo: resultsMap[firstCourse['code']] ?? {},
                    );
                  }
                },
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('Cập nhật điểm môn lên web', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final tableWidth = constraints.maxWidth < 950 ? 950.0 : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: const Color(0xFF0D9488),
                          child: const Row(
                            children: [
                              _TableHeaderCell('TT', width: 35),
                              _TableHeaderCell('Lớp HP', width: 140),
                              _TableHeaderCell('Tên lớp', width: 180),
                              Expanded(child: _TableHeaderCell('Tên HP (TC)')),
                              _TableHeaderCell('Bộ phận', width: 70),
                              _TableHeaderCell('Thi 1', width: 50),
                              _TableHeaderCell('Điểm 1', width: 55),
                              _TableHeaderCell('Thi 2', width: 50),
                              _TableHeaderCell('Điểm 2', width: 55),
                              _TableHeaderCell('Điểm max', width: 65),
                              _TableHeaderCell('Điểm chữ', width: 65),
                              _TableHeaderCell('Điểm số', width: 60),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: resultsList.length,
                            itemBuilder: (ctx, idx) {
                              final item = resultsList[idx];
                              final courseCode = item['code'] as String;
                              final idDisplay = item['classId'] as String;
                              final classNameDisplay = item['className'] as String;
                              final nameDisplay = item['name'] as String;
                              final boPhan = item['boPhan'] as String;
                              final thi1 = item['thi1'] as String;
                              final diem1 = item['diem1'] as String;
                              final thi2 = item['thi2'] as String;
                              final diem2 = item['diem2'] as String;
                              final diemMax = item['diemMax'] as String;
                              final diemChu = item['diemChu'] as String;
                              final diemSo = item['diemSo'] as String;

                              return InkWell(
                                onTap: () {
                                  _showEditGradeDialog(
                                    planner: planner,
                                    courseCode: courseCode,
                                    courseName: nameDisplay,
                                    classId: idDisplay,
                                    currentInfo: resultsMap[courseCode] ?? {},
                                  );
                                },
                                child: Container(
                                  color: idx % 2 == 0 ? Colors.white : const Color(0xFFF0FDFA),
                                  child: Row(
                                    children: [
                                      Container(width: 35, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text('${idx + 1}', style: const TextStyle(fontSize: 11))),
                                      Container(width: 140, padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(idDisplay, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)))),
                                      Container(width: 180, padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(classNameDisplay, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                      Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(nameDisplay, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
                                      Container(width: 70, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(boPhan, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                      Container(width: 50, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(thi1, style: const TextStyle(fontSize: 11))),
                                      Container(width: 55, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(diem1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                      Container(width: 50, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(thi2, style: const TextStyle(fontSize: 11))),
                                      Container(width: 55, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(diem2, style: const TextStyle(fontSize: 11))),
                                      Container(width: 65, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(diemMax, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                      Container(width: 65, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(diemChu, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: diemChu == 'X' ? const Color(0xFF0284C7) : ((diemChu == 'A' || diemChu == 'B+' || diemChu == 'B') ? const Color(0xFF0284C7) : Colors.black87)))),
                                      Container(width: 60, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(diemSo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // TAB 4: HỌC PHÍ VÀ LỊCH THI (SCREENSHOT 3)
  Widget _buildTuitionAndExamTab(PlannerProvider planner) {
    final currencyFmt = NumberFormat('#,###', 'vi_VN');
    final officialOrder = [
      'KC213613',
      'KC213668',
      'KC213678',
      'KC213685',
      'KC215046',
      'KC215050',
      'ML211033',
      'SP211014',
    ];

    // Lấy tất cả các học phần đã đăng ký (Ưu tiên sắp xếp theo thứ tự chuẩn)
    final sections = planner.activePlan.selectedSections.values.toList();
    sections.sort((a, b) {
      final idxA = officialOrder.indexOf(a.courseCode);
      final idxB = officialOrder.indexOf(b.courseCode);
      if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
      if (idxA != -1) return -1;
      if (idxB != -1) return 1;
      return a.courseCode.compareTo(b.courseCode);
    });

    final currentMsv = _lastSyncedStudentId.isNotEmpty
        ? _lastSyncedStudentId
        : (_studentIdController.text.trim().isNotEmpty
            ? _studentIdController.text.trim()
            : planner.profile.studentId);
    final ttnStudent = TTNDatabase.getStudent(currentMsv);
    final displayedName = ttnStudent != null ? (ttnStudent['fullName'] as String? ?? planner.profile.fullName) : planner.profile.fullName;

    int totalTuitionFee = 0;
    for (int i = 0; i < sections.length; i++) {
      final s = sections[i];
      final c = planner.getCourseByCode(s.courseCode);
      final cr = c?.credits ?? 2;
      final f = cr == 3 ? 1857000 : (i == 0 ? 1766571 : 1238000);
      totalTuitionFee += f;
    }

    final scheduledCount = sections.where((s) {
      final ex = TTNDatabase.getExamScheduleForCourse(s.courseCode, currentMsv);
      return (ex['ngay1'] as String? ?? '').isNotEmpty;
    }).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner trạng thái lịch thi và học phí
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheduledCount > 0 ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: scheduledCount > 0 ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(
                  scheduledCount > 0 ? Icons.verified : Icons.info_outline,
                  size: 16,
                  color: scheduledCount > 0 ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scheduledCount > 0
                        ? '✓ Đã cập nhật lịch thi & phòng thi cho $scheduledCount/${sections.length} môn • Sinh viên: $displayedName ($currentMsv)'
                        : 'ℹ️ Hiện tại nhà trường chưa xếp lịch thi cho các môn này • Khi có lịch thi & phòng thi thì hệ thống sẽ tự động cập nhật hoặc bấm [Cập nhật lịch thi]',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: scheduledCount > 0 ? const Color(0xFF1E40AF) : const Color(0xFF475569),
                    ),
                  ),
                ),
                if (scheduledCount > 0)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF1D4ED8)),
                    tooltip: 'Làm mới lịch thi',
                    onPressed: () {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã đồng bộ lịch thi và học phí cho $displayedName ($currentMsv)'),
                          backgroundColor: const Color(0xFF1D4ED8),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.print, size: 22, color: Color(0xFF1E3A8A)),
                    tooltip: 'In lịch thi và học phí',
                    onPressed: () {
                      final studentId = currentMsv;
                      final ttnStudent = TTNDatabase.getStudent(studentId);
                      final studentName = ttnStudent != null ? (ttnStudent['fullName'] as String? ?? planner.profile.fullName) : planner.profile.fullName;
                      final major = ttnStudent != null ? (ttnStudent['major'] as String? ?? planner.profile.major) : planner.profile.major;

                      _showPrintDocumentDialog(
                        context: context,
                        documentTitle: 'Phiếu Báo Lịch Thi Và Học Phí',
                        studentInfo: 'Họ và tên sinh viên: $studentName  •  MSSV: $studentId\nNgành: $major  •  Tổng học phí: ${currencyFmt.format(totalTuitionFee)} VNĐ  •  Tình trạng: Đã thanh toán 100%',
                        tableContent: Table(
                          border: TableBorder.all(color: Colors.grey.shade400),
                          columnWidths: const {
                            0: FixedColumnWidth(35),
                            1: FixedColumnWidth(130),
                            2: FlexColumnWidth(),
                            3: FixedColumnWidth(95),
                            4: FixedColumnWidth(110),
                          },
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                              children: [
                                Padding(padding: EdgeInsets.all(6), child: Text('TT', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                Padding(padding: EdgeInsets.all(6), child: Text('Lớp HP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                Padding(padding: EdgeInsets.all(6), child: Text('Tên học phần', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                Padding(padding: EdgeInsets.all(6), child: Text('Học phí', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                Padding(padding: EdgeInsets.all(6), child: Text('Lịch thi (Ngày/Phòng)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              ],
                            ),
                            ...sections.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final sec = entry.value;
                              final meta = _officialRegisteredDetails[sec.courseCode];
                              final idDisplay = meta != null ? (meta['classId'] as String) : sec.id;
                              final nameDisplay = meta != null ? (meta['name'] as String) : sec.courseName;
                              final course = planner.getCourseByCode(sec.courseCode);
                              final credits = course?.credits ?? 2;
                              final fee = credits == 3 ? 1857000 : (idx == 0 ? 1766571 : 1238000);
                              final examInfo = TTNDatabase.getExamScheduleForCourse(sec.courseCode, currentMsv);
                              final d1 = examInfo['ngay1'] as String? ?? '';
                              final p1 = examInfo['phong1'] as String? ?? '';

                              return TableRow(
                                children: [
                                  Padding(padding: const EdgeInsets.all(6), child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                                  Padding(padding: const EdgeInsets.all(6), child: Text(idDisplay, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Padding(padding: const EdgeInsets.all(6), child: Text(nameDisplay, style: const TextStyle(fontSize: 11))),
                                  Padding(padding: const EdgeInsets.all(6), child: Text(currencyFmt.format(fee), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                                  Padding(padding: const EdgeInsets.all(6), child: Text(d1.isNotEmpty ? '$d1 ($p1)' : 'Đang cập nhật', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5))),
                                ],
                              );
                            }),
                          ],
                        ),
                        note: '* Thí sinh có mặt tại phòng thi trước giờ thi 15 phút và mang theo Thẻ sinh viên / CCCD.',
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  const Text('HỌC PHÍ VÀ LỊCH THI KẾT THÚC HỌC PHẦN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Tổng học phí: ${currencyFmt.format(totalTuitionFee)} VNĐ',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showEditExamScheduleDialog(
                        planner: planner,
                        courseCode: 'KC213613',
                        courseName: 'An toàn thông tin',
                        classId: 'KC213613_74293',
                      );
                    },
                    icon: const Icon(Icons.edit_calendar, size: 15),
                    label: const Text('Cập nhật lịch thi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            color: const Color(0xFF0284C7),
            child: const Row(
              children: [
                _TableHeaderCell('TT', width: 35),
                _TableHeaderCell('Lớp HP', width: 140),
                _TableHeaderCell('Tên lớp', width: 170),
                Expanded(child: _TableHeaderCell('Tên HP (TC)')),
                _TableHeaderCell('Học phí', width: 100),
                _TableHeaderCell('Đã nộp', width: 60),
                _TableHeaderCell('Buổi 1', width: 65),
                _TableHeaderCell('Ngày 1', width: 90),
                _TableHeaderCell('Phòng thi 1', width: 90),
                _TableHeaderCell('Buổi 2', width: 65),
                _TableHeaderCell('Ngày 2', width: 90),
                _TableHeaderCell('Phòng thi 2', width: 90),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sections.length,
              itemBuilder: (ctx, idx) {
                final sec = sections[idx];
                final meta = _officialRegisteredDetails[sec.courseCode];
                final idDisplay = meta != null ? (meta['classId'] as String) : sec.id;
                final nameDisplay = meta != null ? (meta['name'] as String) : sec.courseName;
                final classNameDisplay = meta != null ? (meta['className'] as String) : 'Công nghệ thông tin K23 (${sec.enrolled}/${sec.capacity})';

                final course = planner.getCourseByCode(sec.courseCode);
                final credits = course?.credits ?? 2;
                final fee = credits == 3 ? 1857000 : (idx == 0 ? 1766571 : 1238000);

                final examInfo = TTNDatabase.getExamScheduleForCourse(sec.courseCode, currentMsv);
                final buoi1 = examInfo['buoi1'] as String? ?? 'Sáng';
                final ngay1 = examInfo['ngay1'] as String? ?? '';
                final phong1 = examInfo['phong1'] as String? ?? '';
                final buoi2 = examInfo['buoi2'] as String? ?? '';
                final ngay2 = examInfo['ngay2'] as String? ?? '';
                final phong2 = examInfo['phong2'] as String? ?? '';

                return InkWell(
                  onTap: () {
                    _showEditExamScheduleDialog(
                      planner: planner,
                      courseCode: sec.courseCode,
                      courseName: nameDisplay,
                      classId: idDisplay,
                    );
                  },
                  child: Container(
                    color: idx % 2 == 0 ? Colors.white : const Color(0xFFF0F9FF),
                    child: Row(
                      children: [
                        Container(width: 35, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text('${idx + 1}', style: const TextStyle(fontSize: 11))),
                        Container(width: 140, padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(idDisplay, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)))),
                        Container(width: 170, padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(classNameDisplay, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                        Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(nameDisplay, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
                        Container(width: 100, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.centerRight, child: Text(currencyFmt.format(fee), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        Container(width: 60, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: const Icon(Icons.check_circle_outline, size: 14, color: Colors.blue)),
                        Container(width: 65, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(buoi1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        Container(width: 90, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(ngay1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)))),
                        Container(width: 90, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(phong1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                        Container(width: 65, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(buoi2, style: const TextStyle(fontSize: 11))),
                        Container(width: 90, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(ngay2, style: const TextStyle(fontSize: 11))),
                        Container(width: 90, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(phong2, style: const TextStyle(fontSize: 11))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // TAB 5: THỜI KHÓA BIỂU
  Widget _buildTimetableTab(PlannerProvider planner) {
    final currentMsv = _studentIdController.text.trim().isNotEmpty
        ? _studentIdController.text.trim()
        : planner.profile.studentId;
    final ttnStudent = TTNDatabase.getStudent(currentMsv);
    final displayedName = ttnStudent != null ? ttnStudent['fullName'] as String : planner.profile.fullName;

    if (_isWebTimetableMode) {
      return Column(
        children: [
          Container(
            color: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.public, size: 16, color: Color(0xFF0284C7)),
                    const SizedBox(width: 6),
                    Text(
                      'Đang xem: Cổng Tra Cứu Thời Khóa Biểu Web TTN ($displayedName - $currentMsv)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    side: const BorderSide(color: Color(0xFF94A3B8)),
                  ),
                  icon: const Icon(Icons.table_chart, size: 14),
                  label: const Text('Đổi sang dạng Bảng Client', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _isWebTimetableMode = false;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(child: TtnWebTimetableScreen(studentId: currentMsv)),
        ],
      );
    }

    final registeredSecs = planner.activePlan.selectedSections.values.toList();
    final rows = TTNDatabase.getStudentTimetableRows(currentMsv, registeredSecs);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner thông báo tự động cập nhật thời khóa biểu từ Web TTN
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✓ Đã tự động cập nhật thời khóa biểu từ Web TTN cho sinh viên: $displayedName ($currentMsv) • Tổng số: ${rows.length} buổi học',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF059669)),
                  tooltip: 'Làm mới thời khóa biểu từ Web TTN',
                  onPressed: () {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã làm mới và đồng bộ thời khóa biểu từ Web TTN cho $displayedName ($currentMsv)'),
                        backgroundColor: const Color(0xFF059669),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Text('Tuần thứ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: Colors.white,
                child: const Text('Tuần 8', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
              ),
              const SizedBox(width: 8),
              const Text('Từ: 10/19/2026   Đến: 10/25/2026', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF1D4ED8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                ),
                icon: const Icon(Icons.public, size: 14),
                label: const Text('Xem dạng Web ttn.edu.vn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() {
                    _isWebTimetableMode = true;
                  });
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                icon: const Icon(Icons.phone_iphone, size: 14),
                label: const Text('📱 Xem dạng App Mobile Hiện Đại', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ModernMobileTimetableScreen(studentId: currentMsv),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            color: const Color(0xFF0284C7),
            child: const Row(
              children: [
                _TableHeaderCell('TT', width: 35),
                _TableHeaderCell('KHID', width: 75),
                Expanded(child: _TableHeaderCell('TÊN HP (SL)')),
                _TableHeaderCell('Thứ', width: 50),
                _TableHeaderCell('Buổi', width: 65),
                _TableHeaderCell('Ngày', width: 95),
                _TableHeaderCell('Tiết', width: 60),
                _TableHeaderCell('Phòng', width: 75),
                _TableHeaderCell('Giảng viên', width: 180),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (ctx, idx) {
                final r = rows[idx];
                return Container(
                  color: idx % 2 == 0 ? Colors.white : const Color(0xFFF0F9FF),
                  child: Row(
                    children: [
                      Container(width: 35, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text('${r['tt']}', style: const TextStyle(fontSize: 11))),
                      Container(width: 75, padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text('${r['khid']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)))),
                      Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text('${r['name']}', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
                      Container(width: 50, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text('${r['day']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      Container(width: 65, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text('${r['session']}', style: const TextStyle(fontSize: 11))),
                      Container(width: 95, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text('${r['date']}', style: const TextStyle(fontSize: 11))),
                      Container(width: 60, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text('${r['period']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      Container(width: 75, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text('${r['room']}', style: const TextStyle(fontSize: 11))),
                      Container(width: 180, padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(r['lecturer'] as String, style: const TextStyle(fontSize: 11))),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE2E8F0),
                  foregroundColor: const Color(0xFF065F46),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('TKB HP (Xem Lưới Tuần / Xuất Lịch Google)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlanManagerScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 6: ĐĂNG KÝ THI LẠI (CẢI THIỆN ĐIỂM D)
  Widget _buildRetakeExamTab(PlannerProvider planner) {
    final eligibleCourses = [
      {'code': 'KC212604', 'section': 'KC212604_76098', 'class': 'Học lại theo nhu cầu 3', 'name': 'Kỹ thuật lập trình (2.0/0.0)', 'credits': 2, 'score1': '3.8', 'score2': '', 'max': '3.8', 'letter': 'D', 'date': '15/03/2026', 'fee': 80000},
      {'code': 'KC211685', 'section': 'KC211685_74102', 'class': 'Công nghệ thông tin K23', 'name': 'Toán cho Công nghệ thông tin (3.0)', 'credits': 3, 'score1': '4.3', 'score2': '', 'max': '4.3', 'letter': 'D', 'date': '16/03/2026', 'fee': 120000},
      {'code': 'NL211702', 'section': 'NL211702_74088', 'class': 'Đại cương chung K23', 'name': 'Pháp luật Việt Nam đại cương (2.0)', 'credits': 2, 'score1': '4.1', 'score2': '', 'max': '4.1', 'letter': 'D', 'date': '17/03/2026', 'fee': 80000},
      {'code': 'KC212602', 'section': 'KC212602_74120', 'class': 'Công nghệ thông tin K23', 'name': 'Tổ chức máy tính (3.0/0.0)', 'credits': 3, 'score1': '4.2', 'score2': '', 'max': '4.2', 'letter': 'D', 'date': '18/03/2026', 'fee': 120000},
      {'code': 'FL211013', 'section': 'FL211013_74201', 'class': 'Ngoại ngữ K23', 'name': 'Tiếng Anh 3 (3.0/0.0)', 'credits': 3, 'score1': '4.0', 'score2': '', 'max': '4.0', 'letter': 'D', 'date': '19/03/2026', 'fee': 120000},
    ];

    int totalRetakeFee = 0;
    for (final c in eligibleCourses) {
      if (_registeredRetakeCodes.contains(c['code'])) {
        totalRetakeFee += c['fee'] as int;
      }
    }

    final currencyFmt = NumberFormat('#,###', 'vi_VN');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đăng ký thi cải thiện điểm D, Học kỳ: 1  Năm học: 2026-2027      (Lưu ý: Còn nợ Học phí và Lệ phí điểm D thì không được Đăng ký học phần và Đăng ký thi điểm D)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Đăng ký từ: 20/02/2024  Đến ngày: 02/03/2024  VÀ TRƯỚC NGÀY THI LẠI CỦA HỌC PHẦN 3 NGÀY',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lệ phí thi cải thiện điểm D: 40.000đ/1 TC; Nộp Lệ phí qua Agribank; Hạn cuối: Trước ngày thi lại 3 ngày',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
              ),
              Text(
                'Tổng lệ phí thi lại đã chọn: ${currencyFmt.format(totalRetakeFee)} VNĐ',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFF9333EA),
                      child: const Row(
                        children: [
                          _TableHeaderCell('TT', width: 35),
                          _TableHeaderCell('Lớp HP', width: 130),
                          _TableHeaderCell('Tên lớp', width: 160),
                          Expanded(child: _TableHeaderCell('Tên HP (TC)')),
                          _TableHeaderCell('Điểm 1', width: 55),
                          _TableHeaderCell('Điểm 2', width: 55),
                          _TableHeaderCell('Điểm max', width: 65),
                          _TableHeaderCell('Điểm chữ', width: 65),
                          _TableHeaderCell('Đăng ký / Thi lại', width: 110),
                          _TableHeaderCell('Ngày thi lại', width: 85),
                          _TableHeaderCell('Lệ phí thi', width: 85),
                          _TableHeaderCell('Đã nộp', width: 55),
                        ],
                      ),
                    ),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                      child: ListView.builder(
                        itemCount: eligibleCourses.length,
                        itemBuilder: (ctx, idx) {
                          final item = eligibleCourses[idx];
                          final code = item['code'] as String;
                          final isSelected = _selectedRetakeCourseCode == code;
                          final isRegistered = _registeredRetakeCodes.contains(code);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedRetakeCourseCode = code;
                              });
                            },
                            child: Container(
                              color: isSelected ? const Color(0xFFE9D5FF) : (idx % 2 == 0 ? Colors.white : const Color(0xFFFAF5FF)),
                              child: Row(
                                children: [
                                  Container(width: 35, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text('${idx + 1}', style: const TextStyle(fontSize: 11))),
                                  Container(width: 130, padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(item['section'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)))),
                                  Container(width: 160, padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(item['class'] as String, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                  Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(item['name'] as String, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
                                  Container(width: 55, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(item['score1'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red))),
                                  Container(width: 55, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: const Text('', style: TextStyle(fontSize: 11))),
                                  Container(width: 65, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(item['max'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Container(width: 65, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(item['letter'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red))),
                                  Container(
                                    width: 110,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isRegistered ? Icons.check_circle : Icons.radio_button_unchecked,
                                          size: 14,
                                          color: isRegistered ? Colors.green : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(isRegistered ? 'Đã đăng ký' : 'Chưa chọn', style: TextStyle(fontSize: 10.5, fontWeight: isRegistered ? FontWeight.bold : FontWeight.normal, color: isRegistered ? Colors.green : Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  Container(width: 85, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Text(item['date'] as String, style: const TextStyle(fontSize: 10.5))),
                                  Container(width: 85, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.centerRight, child: Text(currencyFmt.format(item['fee']), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Container(width: 55, padding: const EdgeInsets.symmetric(vertical: 6), alignment: Alignment.center, child: Icon(isRegistered ? Icons.check : Icons.close, size: 13, color: isRegistered ? Colors.blue : Colors.grey)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.check, size: 16, color: Colors.green),
                    label: const Text('Đăng ký', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      if (_selectedRetakeCourseCode != null) {
                        final ok = await _ensurePasswordVerifiedForRegistration(planner);
                        if (!ok || !mounted) return;
                        setState(() {
                          _registeredRetakeCodes.add(_selectedRetakeCourseCode!);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã ghi nhận đăng ký thi cải thiện môn $_selectedRetakeCourseCode!')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    label: const Text('Hủy đăng ký', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      if (_selectedRetakeCourseCode != null) {
                        final ok = await _ensurePasswordVerifiedForRegistration(planner);
                        if (!ok || !mounted) return;
                        setState(() {
                          _registeredRetakeCodes.remove(_selectedRetakeCourseCode!);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã hủy đăng ký thi cải thiện môn $_selectedRetakeCourseCode!')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. Xét Tốt Nghiệp Tab (Theo Quy chế 1574/QĐ-ĐHTN & Sổ tay sinh viên 2023)
  Widget _buildGraduationEvaluationTab(PlannerProvider planner) {
    final profile = planner.profile;
    const totalRequired = TTNHandbookDatabase.totalCredits;
    final passedCount = profile.passedCourses.length;
    final accumulatedCredits = passedCount * 2 + 30; // ~60-80 TC
    final progress = (accumulatedCredits / totalRequired).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Color(0xFFFDE047), size: 28),
                    SizedBox(width: 8),
                    Text(
                      'XÉT ĐIỀU KIỆN TỐT NGHIỆP CỬ NHÂN CNTT (KHOÁ 2023)',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Sinh viên: ${profile.fullName} • MSSV: ${profile.studentId} • Ngành: ${profile.major} (${profile.cohort})',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFDE047)),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã tích lũy: $accumulatedCredits / $totalRequired Tín chỉ',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tiến độ: ${(progress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: Color(0xFFFDE047), fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'BẢNG TIÊU CHUẨN XÉT TỐT NGHIỆP (QUY CHẾ 1574/QĐ-ĐHTN)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 8),
          _buildGraduationCriteriaCard(
            title: '1. Tích lũy đủ số tín chỉ quy định',
            description: 'Tích lũy tối thiểu 145 tín chỉ theo đúng chương trình đào tạo ngành CNTT Khóa 2023.',
            isPassed: accumulatedCredits >= totalRequired,
            statusText: accumulatedCredits >= totalRequired ? 'ĐẠT' : 'Đang hoàn thành ($accumulatedCredits/$totalRequired TC)',
          ),
          _buildGraduationCriteriaCard(
            title: '2. Điểm trung bình chung tích lũy (GPA)',
            description: 'Điểm TBCTL toàn khóa đạt từ 2.00 / 4.00 trở lên (không bị xếp loại học lực Kém).',
            isPassed: profile.currentGpa >= 2.0,
            statusText: profile.currentGpa >= 2.0
                ? 'ĐẠT (${profile.currentGpa.toStringAsFixed(2)} - Xếp loại ${profile.currentGpa >= 3.2 ? "Giỏi" : profile.currentGpa >= 2.5 ? "Khá" : "Trung bình"})'
                : 'Chưa đạt (< 2.00)',
          ),
          _buildGraduationCriteriaCard(
            title: '3. Chuẩn đầu ra Ngoại ngữ (Tiếng Anh B1 / Bậc 3)',
            description: 'Đạt chứng chỉ Bậc 3 theo Khung năng lực ngoại ngữ 6 bậc dùng cho Việt Nam (VSTEP B1, TOEIC 450+).',
            isPassed: true,
            statusText: 'ĐÃ NỘP CHỨNG CHỈ (VSTEP B1)',
          ),
          _buildGraduationCriteriaCard(
            title: '4. Chuẩn kỹ năng sử dụng Công nghệ thông tin',
            description: 'Đạt chuẩn kỹ năng sử dụng CNTT cơ bản theo quy định tại Thông tư số 03/2014/TT-BTTTT.',
            isPassed: true,
            statusText: 'ĐẠT (Đặc cách sinh viên ngành CNTT)',
          ),
          _buildGraduationCriteriaCard(
            title: '5. Chứng chỉ Giáo dục Quốc phòng - An ninh (GDQP-AN)',
            description: 'Hoàn thành 4 học phần: Công tác QP-AN, Đường lối QP-AN, Quân sự chung, Kỹ thuật chiến đấu.',
            isPassed: true,
            statusText: 'ĐÃ ĐẠT CHỨNG CHỈ GDQP-AN',
          ),
          _buildGraduationCriteriaCard(
            title: '6. Chứng chỉ Giáo dục Thể chất (GDTC)',
            description: 'Tích lũy đủ các học phần thể chất theo quy định của Trường Đại học Tây Nguyên.',
            isPassed: true,
            statusText: 'ĐÃ HOÀN THÀNH CÁC HỌC PHẦN GDTC',
          ),
          _buildGraduationCriteriaCard(
            title: '7. Khóa luận tốt nghiệp hoặc Chuyên đề + Học phần thay thế',
            description: 'Thực tập nghề nghiệp (5 TC) và Khóa luận tốt nghiệp (10 TC) hoặc Chuyên đề tốt nghiệp (4 TC) + 3 môn tự chọn (6 TC).',
            isPassed: false,
            statusText: 'Dự kiến thực hiện vào Học kỳ 8 (Năm 2027)',
          ),
        ],
      ),
    );
  }

  Widget _buildGraduationCriteriaCard({
    required String title,
    required String description,
    required bool isPassed,
    required String statusText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isPassed ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.pending,
            color: isPassed ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isPassed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isPassed ? const Color(0xFF15803D) : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 8. Đề Cương Chi Tiết Học Phần (Sổ tay sinh viên 2023 - Ngành CNTT ĐH Tây Nguyên)
  Widget _buildCurriculumHandbookTab() {
    final courses = TTNHandbookDatabase.allCourses.where((c) {
      if (_selectedHandbookSemester != 0 && c.semester != _selectedHandbookSemester) {
        return false;
      }
      if (_handbookSearch.isNotEmpty) {
        final q = _handbookSearch.toLowerCase();
        final matchCode = c.code.toLowerCase().contains(q);
        final matchName = c.name.toLowerCase().contains(q);
        return matchCode || matchName;
      }
      return true;
    }).toList();

    final totalFilteredCredits = courses.fold<int>(0, (sum, c) => sum + c.credits);

    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header info banner from Sổ tay sinh viên 2023
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.menu_book, color: Color(0xFF1E3A8A), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHƯƠNG TRÌNH ĐÀO TẠO (ĐẦY ĐỦ 90 HỌC PHẦN CHUẨN ĐH TÂY NGUYÊN)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hiển thị: ${courses.length}/90 học phần • Tổng số: 90 học phần (145 tín chỉ) • QĐ 1574/QĐ-ĐHTN',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                      ),
                      const Text(
                        TTNHandbookDatabase.decision,
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Search & Filter Bar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên môn hoặc mã học phần (VD: KC21, Lập trình, Cơ sở dữ liệu...)...',
                      hintStyle: const TextStyle(fontSize: 11),
                      prefixIcon: const Icon(Icons.search, size: 16),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (val) => setState(() => _handbookSearch = val),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${courses.length} học phần ($totalFilteredCredits TC)',
                  style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Semester Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSemesterChip(0, 'Tất cả (86 môn)'),
                ...List.generate(8, (i) => _buildSemesterChip(i + 1, 'Học kỳ ${i + 1}')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Course Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: ListView.separated(
                itemCount: courses.length + 1,
                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                itemBuilder: (ctx, idx) {
                  if (idx == 0) {
                    // Header row
                    return Container(
                      color: const Color(0xFFE2E8F0),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: const Row(
                        children: [
                          SizedBox(width: 32, child: Text('STT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          SizedBox(width: 80, child: Text('Mã HP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)))),
                          Expanded(child: Text('Tên học phần (Sổ tay sinh viên 2023)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          SizedBox(width: 55, child: Text('Kỳ', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          SizedBox(width: 55, child: Text('Tổng TC', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red))),
                          SizedBox(width: 45, child: Text('LT', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          SizedBox(width: 45, child: Text('TH', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          SizedBox(width: 80, child: Text('Tính chất', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    );
                  }
                  final c = courses[idx - 1];
                  return Container(
                    color: idx % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(width: 32, child: Text('${c.stt}', style: const TextStyle(fontSize: 11, color: Colors.black54))),
                        SizedBox(width: 80, child: Text(c.code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)))),
                        Expanded(child: Text(c.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                        SizedBox(width: 55, child: Text('Kỳ ${c.semester}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF0F766E)))),
                        SizedBox(width: 55, child: Text('${c.credits}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.red))),
                        SizedBox(width: 45, child: Text('${c.theoryCredits}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black54))),
                        SizedBox(width: 45, child: Text('${c.practiceCredits}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black54))),
                        SizedBox(
                          width: 80,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: c.isMandatory ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                c.isMandatory ? 'Bắt buộc' : 'Tự chọn',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: c.isMandatory ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterChip(int sem, String label) {
    final isSelected = _selectedHandbookSemester == sem;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: const Color(0xFF1E3A8A),
        labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1E293B)),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        visualDensity: VisualDensity.compact,
        onSelected: (_) => setState(() => _selectedHandbookSemester = sem),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB: ĐĂNG KÝ HỌC HÈ (QĐ 1574/QĐ-ĐHTN Tối đa 11 Tín chỉ)
  // -------------------------------------------------------------
  Widget _buildSummerRegistrationTab(PlannerProvider planner) {
    const summerCatalog = [
      (
        code: 'KC212604',
        name: 'Cơ sở dữ liệu',
        credits: 3,
        lecturer: 'ThS. Trương Thị Hương Giang',
        room: 'P.7.3.18',
        schedule: 'T2,4,6 (Tiết 1-3)',
        note: 'Lớp học lại & cải thiện điểm',
      ),
      (
        code: 'KC212102',
        name: 'Lập trình C căn bản',
        credits: 3,
        lecturer: 'ThS. Lê Tô Đỗ Quyên',
        room: 'P.7.3.15',
        schedule: 'T3,5,7 (Tiết 1-3)',
        note: 'Lớp bổ sung kiến thức lập trình',
      ),
      (
        code: 'KC212001',
        name: 'Toán cao cấp 1',
        credits: 3,
        lecturer: 'TS. Nguyễn Văn Minh',
        room: 'P.5.2.04',
        schedule: 'T2,4 (Tiết 7-9)',
        note: 'Môn đại cương tiên quyết',
      ),
      (
        code: 'KC212002',
        name: 'Toán cao cấp 2',
        credits: 3,
        lecturer: 'TS. Nguyễn Văn Minh',
        room: 'P.5.2.04',
        schedule: 'T3,5 (Tiết 7-9)',
        note: 'Môn đại cương tiên quyết',
      ),
      (
        code: 'KC212003',
        name: 'Đại số tuyến tính',
        credits: 2,
        lecturer: 'ThS. Trần Thị Lan',
        room: 'P.5.2.06',
        schedule: 'T6,7 (Tiết 7-8)',
        note: 'Đại cương nền tảng khoa học máy tính',
      ),
      (
        code: 'KC212201',
        name: 'Cấu trúc dữ liệu và giải thuật',
        credits: 3,
        lecturer: 'ThS. Trương Thị Hương Giang',
        room: 'P.7.3.18',
        schedule: 'T2,4 (Tiết 4-6)',
        note: 'Môn cơ sở cốt lõi chuyên ngành',
      ),
      (
        code: 'KC212205',
        name: 'Lập trình hướng đối tượng',
        credits: 3,
        lecturer: 'ThS. Lê Tô Đỗ Quyên',
        room: 'P.7.3.15',
        schedule: 'T3,5 (Tiết 4-6)',
        note: 'Học phần tiên quyết Lập trình di động',
      ),
      (
        code: 'KC212301',
        name: 'Mạng máy tính',
        credits: 3,
        lecturer: 'ThS. Nguyễn Thị Như',
        room: 'P.7.2.10',
        schedule: 'T2,4,6 (Tiết 7-9)',
        note: 'Kiến trúc hạ tầng mạng',
      ),
      (
        code: 'KC211001',
        name: 'Triết học Mác - Lênin',
        credits: 3,
        lecturer: 'TS. Đinh Quang Tuyến',
        room: 'Giảng đường 1',
        schedule: 'T7, CN (Tiết 1-4)',
        note: 'Khối kiến thức lý luận chính trị',
      ),
      (
        code: 'KC211005',
        name: 'Tiếng Anh B1-1',
        credits: 3,
        lecturer: 'ThS. Phạm Hoàng Mai',
        room: 'P.A2.04',
        schedule: 'T2,4,6 (Tiết 1-3)',
        note: 'Chuẩn đầu ra ngoại ngữ cử nhân',
      ),
      (
        code: 'KC211006',
        name: 'Tiếng Anh B1-2',
        credits: 3,
        lecturer: 'ThS. Phạm Hoàng Mai',
        room: 'P.A2.04',
        schedule: 'T3,5,7 (Tiết 1-3)',
        note: 'Chuẩn đầu ra ngoại ngữ bậc 3/6',
      ),
      (
        code: 'KC211007',
        name: 'Pháp luật đại cương',
        credits: 2,
        lecturer: 'ThS. Võ Minh Trí',
        room: 'P.5.2.10',
        schedule: 'T4,6 (Tiết 9-10)',
        note: 'Kiến thức pháp lý chung',
      ),
    ];

    final filtered = summerCatalog.where((c) {
      if (_summerSearch.isEmpty) return true;
      final q = _summerSearch.toLowerCase();
      return c.code.toLowerCase().contains(q) || c.name.toLowerCase().contains(q) || c.lecturer.toLowerCase().contains(q);
    }).toList();

    int totalCredits = 0;
    for (final c in summerCatalog) {
      if (_selectedSummerCourseCodes.contains(c.code)) {
        totalCredits += c.credits;
      }
    }
    final feeEstimate = totalCredits * 380000;
    final isExceeded = totalCredits > 11;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner quy chế hè
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isExceeded ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
              border: Border.all(color: isExceeded ? const Color(0xFFEF4444) : const Color(0xFF86EFAC)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  isExceeded ? Icons.warning_amber_rounded : Icons.wb_sunny_rounded,
                  color: isExceeded ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ĐĂNG KÝ HỌC KỲ HÈ 2025 - 2026 (HỌC KỲ PHỤ)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isExceeded ? const Color(0xFFB91C1C) : const Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Theo Quyết định số 1574/QĐ-ĐHTN: Mỗi sinh viên được đăng ký tối đa 11 TÍN CHỈ trong kỳ hè để học lại, học cải thiện điểm hoặc học vượt. Đơn giá: 380.000 đ/tín chỉ.',
                        style: TextStyle(fontSize: 11, color: isExceeded ? const Color(0xFF991B1B) : const Color(0xFF14532D)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isExceeded ? const Color(0xFFDC2626) : const Color(0xFF166534),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Đã chọn: $totalCredits / 11 TC',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Thanh tìm kiếm và bộ đếm
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm mã môn, tên môn học hè, giảng viên...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                    onChanged: (v) => setState(() => _summerSearch = v),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Mặc định', style: TextStyle(fontSize: 12)),
                onPressed: () => setState(() {
                  _selectedSummerCourseCodes.clear();
                  _selectedSummerCourseCodes.addAll(['KC212604', 'KC212102']);
                  _summerSearch = '';
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bảng danh sách học phần hè
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFF1E3A8A),
                    child: const Row(
                      children: [
                        _TableHeaderCell('Chọn', width: 50),
                        _TableHeaderCell('Mã HP', width: 90),
                        Expanded(child: _TableHeaderCell('Tên học phần học hè')),
                        _TableHeaderCell('Số TC', width: 60),
                        _TableHeaderCell('Học phí hè', width: 100),
                        _TableHeaderCell('Thời khóa biểu hè', width: 140),
                        _TableHeaderCell('Phòng', width: 70),
                        _TableHeaderCell('Giảng viên', width: 140),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final c = filtered[idx];
                        final isSelected = _selectedSummerCourseCodes.contains(c.code);
                        final courseFee = c.credits * 380000;
                        final feeFormatted = NumberFormat('#,###').format(courseFee);

                        return Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : (idx.isEven ? Colors.white : const Color(0xFFF8FAFC)),
                            border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedSummerCourseCodes.remove(c.code);
                                } else {
                                  _selectedSummerCourseCodes.add(c.code);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    child: Checkbox(
                                      value: isSelected,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedSummerCourseCodes.add(c.code);
                                          } else {
                                            _selectedSummerCourseCodes.remove(c.code);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      c.code,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A)),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                                        Text(c.note, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Text('${c.credits} TC', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text('$feeFormatted đ', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 140,
                                    child: Text(c.schedule, style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                                  ),
                                  SizedBox(
                                    width: 70,
                                    child: Text(c.room, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                  SizedBox(
                                    width: 140,
                                    child: Text(c.lecturer, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Thanh điều khiển dưới cùng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              border: Border.all(color: const Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Số môn đăng ký: ${_selectedSummerCourseCodes.length} môn | Tổng tín chỉ hè: $totalCredits / 11 TC',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isExceeded ? Colors.red : const Color(0xFF1E3A8A))),
                    Text('Tạm tính học phí hè: ${NumberFormat('#,###').format(feeEstimate)} VNĐ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF047857))),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('In phiếu đăng ký hè', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã xuất phiếu đăng ký học hè của SV ${planner.profile.studentId} thành công!')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Xác nhận đăng ký học hè', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExceeded ? Colors.grey : const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isExceeded
                      ? null
                      : () async {
                          final ok = await _ensurePasswordVerifiedForRegistration(planner);
                          if (!ok || !mounted) return;
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                                  SizedBox(width: 8),
                                  Text('Xác nhận Đăng ký Học hè'),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Sinh viên: ${planner.profile.fullName} (${planner.profile.studentId})'),
                                  const SizedBox(height: 6),
                                  Text('Học kỳ hè: 2025 - 2026'),
                                  Text('Số môn đã chọn: ${_selectedSummerCourseCodes.length} môn'),
                                  Text('Tổng số tín chỉ: $totalCredits tín chỉ (Đạt chuẩn <= 11 TC)'),
                                  Text('Tổng học phí: ${NumberFormat('#,###').format(feeEstimate)} đ'),
                                  const SizedBox(height: 10),
                                  const Text('Dữ liệu đã được lưu vào hệ thống Quản lý Đào tạo ĐH Tây Nguyên.',
                                      style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
                              ],
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB: THƯ VIỆN SỐ & HỌC LIỆU CNTT TTN
  // -------------------------------------------------------------
  Widget _buildDigitalLibraryTab() {
    const libraryResources = [
      (
        title: 'Giáo trình Cơ sở Dữ liệu & Hệ quản trị CSDL Quan hệ',
        category: 'Giáo trình & Sách',
        author: 'ThS. Trương Thị Hương Giang - Bộ môn CNTT',
        size: '18.5 MB',
        format: 'PDF',
        date: '10/2023',
        description: 'Tài liệu chuẩn giảng dạy CSDL bậc đại học: Đại số quan hệ, Thiết kế lược đồ ERD, Chuẩn hóa 1NF-3NF-BCNF, SQL nâng cao và Trigger trong SQL Server.',
        contents: ['Chương 1: Tổng quan hệ CSDL', 'Chương 2: Mô hình thực thể kết hợp', 'Chương 3: Đại số quan hệ', 'Chương 4: Ngôn ngữ SQL', 'Chương 5: Chuẩn hóa dữ liệu'],
      ),
      (
        title: 'Giáo trình Cấu trúc Dữ liệu và Giải thuật với C/C++',
        category: 'Giáo trình & Sách',
        author: 'Khoa KHTN & Công nghệ - ĐH Tây Nguyên',
        size: '12.8 MB',
        format: 'PDF',
        date: '08/2023',
        description: 'Giải thuật phân tích độ phức tạp O(n), Danh sách liên kết đơn/kép, Ngăn xếp, Hàng đợi, Cây nhị phân tìm kiếm, Đồ thị và các thuật toán quy hoạch động.',
        contents: ['Phần 1: Cấu trúc dữ liệu tuyến tính', 'Phần 2: Cấu trúc phi tuyến & Cây', 'Phần 3: Lý thuyết đồ thị cơ bản', 'Phần 4: Thuật toán sắp xếp & tìm kiếm'],
      ),
      (
        title: 'Slide Bài giảng: Lập trình Thiết bị Di động với Flutter',
        category: 'Slide bài giảng',
        author: 'ThS. Lê Tô Đỗ Quyên - Bộ môn CNTT',
        size: '26.4 MB',
        format: 'PPTX / PDF',
        date: '01/2026',
        description: 'Bộ slide 15 tuần bài giảng: Kiến trúc Flutter, Widget Tree, State Management (Provider, Bloc), Gọi API RESTful, Lưu trữ SQLite/Hive và Clean Architecture.',
        contents: ['Tuần 1-3: Dart căn bản & Widget', 'Tuần 4-6: State Management Provider', 'Tuần 7-9: Tương tác RESTful API', 'Tuần 10-12: Xử lý CSDL cục bộ', 'Tuần 13-15: Đồ án ứng dụng'],
      ),
      (
        title: 'Bộ đề thi & Đáp án: Mạng Máy tính và Truyền số liệu (2021-2025)',
        category: 'Đề thi & Đáp án',
        author: 'ThS. Nguyễn Thị Như - Bộ môn CNTT',
        size: '8.3 MB',
        format: 'PDF',
        date: '12/2025',
        description: 'Tổng hợp đề thi kết thúc học phần Mạng máy tính qua các học kỳ: Chia mạng con IPv4 VLSM, Định tuyến RIP/OSPF, Giao thức TCP/UDP, Bắt gói tin Wireshark.',
        contents: ['Đề thi HK1 2022-2023 & Đáp án', 'Đề thi HK2 2023-2024 & Đáp án', 'Đề thi HK1 2024-2025 & Đáp án', 'Hướng dẫn giải chi tiết bài tập chia subnet'],
      ),
      (
        title: 'Giáo trình Nhập môn Trí tuệ Nhân tạo & Machine Learning',
        category: 'Giáo trình & Sách',
        author: 'TS. Đặng Tiến Hòa - Trường ĐH Tây Nguyên',
        size: '15.1 MB',
        format: 'PDF',
        date: '11/2024',
        description: 'Khái niệm tác tử thông minh, Thuật toán tìm kiếm A*, Minimax, Học máy có giám sát (Regression, Classification, Decision Tree), Mạng nơ-ron cơ bản.',
        contents: ['Chương 1: Tổng quan AI', 'Chương 2: Tìm kiếm không gian trạng thái', 'Chương 3: Lý thuyết trò chơi & Alpha-Beta', 'Chương 4: Cơ bản về Học máy'],
      ),
      (
        title: 'Source code & Đồ án mẫu: Web Quản lý Đào tạo Sinh viên TTN',
        category: 'Source code & Đồ án',
        author: 'Nhóm Sinh viên Nghiên cứu Khoa học K23 CNTT',
        size: '42.0 MB',
        format: 'ZIP',
        date: '03/2026',
        description: 'Toàn bộ mã nguồn dự án Flutter + Dart + Web Engine: Thuật toán xếp lịch tự động, tích hợp bảng quy chế 1574, mô phỏng Cổng đào tạo TTN hoàn chỉnh.',
        contents: ['lib/models: Lớp dữ liệu học phần', 'lib/providers: State management', 'lib/services: Thuật toán Xếp lịch tự động', 'test: Bộ 6 unit tests hoàn chỉnh'],
      ),
      (
        title: 'Sổ tay Hướng dẫn Thực tập Doanh nghiệp & Khóa luận Tốt nghiệp',
        category: 'Giáo trình & Sách',
        author: 'Hội đồng Khoa học Khoa KHTN & CN',
        size: '4.6 MB',
        format: 'PDF',
        date: '09/2023',
        description: 'Quy trình đăng ký đề tài tốt nghiệp, viết báo cáo luận văn cử nhân, quy định trích dẫn tài liệu tham khảo IEEE và tiêu chí chấm điểm hội đồng tốt nghiệp.',
        contents: ['Quy định thực tập tại doanh nghiệp', 'Mẫu đề cương khóa luận tốt nghiệp', 'Format trình bày luận văn chuẩn', 'Biểu mẫu đánh giá của cán bộ hướng dẫn'],
      ),
    ];

    final categories = ['Tất cả', 'Giáo trình & Sách', 'Slide bài giảng', 'Đề thi & Đáp án', 'Source code & Đồ án'];

    final filtered = libraryResources.where((r) {
      if (_libraryCategory != 'Tất cả' && r.category != _libraryCategory) return false;
      if (_librarySearch.isEmpty) return true;
      final q = _librarySearch.toLowerCase();
      return r.title.toLowerCase().contains(q) || r.author.toLowerCase().contains(q) || r.description.toLowerCase().contains(q);
    }).toList();

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_library_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THƯ VIỆN SỐ & TÀI NGUYÊN HỌC TẬP - NGÀNH CNTT ĐẠI HỌC TÂY NGUYÊN',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Kho giáo trình điện tử, slide bài giảng giảng viên, bộ đề thi các năm và đồ án mẫu phục vụ sinh viên.',
                        style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Bộ lọc thể loại & tìm kiếm
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm tài liệu, giáo trình, bài giảng, đề thi...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                    onChanged: (v) => setState(() => _librarySearch = v),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSel = _libraryCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ChoiceChip(
                        label: Text(cat, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                        selected: isSel,
                        selectedColor: const Color(0xFF1E3A8A),
                        labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF1E293B)),
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => setState(() => _libraryCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Danh sách tài liệu
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, idx) {
                final item = filtered[idx];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: item.format == 'PDF' ? const Color(0xFFFEE2E2) : (item.format == 'ZIP' ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                item.format == 'PDF' ? Icons.picture_as_pdf : (item.format == 'ZIP' ? Icons.folder_zip : Icons.slideshow),
                                color: item.format == 'PDF' ? const Color(0xFFDC2626) : (item.format == 'ZIP' ? const Color(0xFFD97706) : const Color(0xFF2563EB)),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(3)),
                                        child: Text(item.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${item.format} • ${item.size} • Cập nhật: ${item.date}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                  const SizedBox(height: 2),
                                  Text(item.author, style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(item.description, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.remove_red_eye, size: 14),
                                  label: const Text('Xem mục lục', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Row(
                                          children: [
                                            const Icon(Icons.menu_book, color: Color(0xFF1E3A8A)),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(item.title, style: const TextStyle(fontSize: 14))),
                                          ],
                                        ),
                                        content: SizedBox(
                                          width: 480,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Tác giả: ${item.author}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              const SizedBox(height: 8),
                                              const Text('Mục lục chi tiết tài liệu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
                                              const SizedBox(height: 6),
                                              ...item.contents.map((c) => Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                                                        const SizedBox(width: 6),
                                                        Expanded(child: Text(c, style: const TextStyle(fontSize: 12))),
                                                      ],
                                                    ),
                                                  )),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 6),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.download, size: 14),
                                  label: const Text('Tải tài liệu', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Đang tải tài liệu "${item.title}" (${item.size})... Hoàn tất!'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB: HƯỚNG DẪN SỬ DỤNG HỆ THỐNG
  // -------------------------------------------------------------
  Widget _buildUserGuideTab() {
    const guides = [
      (
        title: '1. Quy trình Đăng ký Học phần (Tín chỉ) Trực tuyến',
        icon: Icons.app_registration,
        color: Color(0xFF1E3A8A),
        points: [
          'Bước 1: Chọn tab "Đăng ký học phần". Danh sách môn học theo chương trình đào tạo sẽ hiển thị tại bảng trên.',
          'Bước 2: Click vào môn cần đăng ký (ví dụ: KC212604 - Cơ sở dữ liệu) để xem danh sách các Lớp học phần mở trong kỳ.',
          'Bước 3: Chọn lớp học phần phù hợp với thời gian cá nhân và bấm nút "Đăng ký môn học".',
          'Bước 4: Hệ thống sẽ tự động kiểm tra xem có bị trùng lịch học hay vi phạm điều kiện tiên quyết (theo QĐ 1574) hay không.',
          'Bước 5: Sau khi thêm thành công, môn học sẽ hiển thị tại bảng "Các học phần đã đăng ký" ở phía dưới.',
        ],
        tip: 'Mẹo: Bạn có thể chọn lớp và bấm "Hủy môn học" nếu muốn đổi sang lớp học phần khác trước khi hết hạn đăng ký.',
      ),
      (
        title: '2. Quy chế Đào tạo Tín chỉ theo QĐ 1574/QĐ-ĐHTN',
        icon: Icons.rule,
        color: Color(0xFFDC2626),
        points: [
          'Số tín chỉ tối thiểu mỗi học kỳ chính: 12 tín chỉ (trừ học kỳ cuối khóa xét tốt nghiệp).',
          'Số tín chỉ tối đa mỗi học kỳ chính: 24 tín chỉ đối với sinh viên xếp loại học lực Khá trở lên (14 tín chỉ với sinh viên bị cảnh báo).',
          'Số tín chỉ tối đa trong học kỳ hè: 11 tín chỉ.',
          'Điều kiện môn tiên quyết: Sinh viên phải hoàn thành môn học trước (điểm từ D trở lên) mới được phép đăng ký môn học sau.',
          'Cảnh báo học vụ: Sinh viên có điểm GPA tích lũy dưới 1.20 (năm 1), dưới 1.40 (năm 2), dưới 1.60 (năm 3), dưới 1.80 (năm 4) sẽ bị cảnh báo học vụ.',
        ],
        tip: 'Lưu ý: Bị cảnh báo học vụ 2 lần liên tiếp sẽ chuyển sang diện buộc thôi học!',
      ),
      (
        title: '3. Hướng dẫn sử dụng Trợ lý Tự động Xếp lịch AI (UniPlan)',
        icon: Icons.auto_awesome,
        color: Color(0xFF7C3AED),
        points: [
          'Chuyển sang tab "⚡ Xếp lịch tự động" trên thanh điều hướng.',
          'Tích chọn các môn học bạn muốn đăng ký trong học kỳ.',
          'Thiết lập các tiêu chí ưu tiên: Né buổi sáng sớm, né buổi chiều, tránh học Thứ 7, hoặc dồn lịch để có trọn ngày nghỉ.',
          'Bấm "🚀 Khởi chạy Thuật toán Xếp lịch": Hệ thống sẽ duyệt toàn bộ không gian tổ hợp và đề xuất các phương án tối ưu nhất không xung đột.',
          'Bấm "Áp dụng phương án này" để tự động ghi nhận vào thời khóa biểu cá nhân.',
        ],
        tip: 'Hệ thống xếp lịch tự động giúp bạn tiết kiệm 95% thời gian so với việc tự ghép thủ công từng tiết học.',
      ),
      (
        title: '4. Cố vấn Học tập AI & Sơ đồ Tiên quyết 8 Học kỳ',
        icon: Icons.psychology,
        color: Color(0xFF0D9488),
        points: [
          'Bấm nút "🤖 AI Cố vấn" trên thanh công cụ để trò chuyện trực tiếp với Trợ lý Ảo được huấn luyện trên Sổ tay Sinh viên 2023.',
          'Hỏi AI về: Lộ trình môn học CNTT, quy chế học bổng, giảng viên phụ trách, hướng đi nghề nghiệp (Lập trình Web, Mobile, AI/Data, Mạng).',
          'Bấm nút "🗺️ Tiên quyết" để xem đồ thị tương tác phân nhánh 5 chuyên ngành: Chuỗi Lập trình C -> OOP -> Di động -> Đồ án; Chuỗi CSDL -> Khai phá -> AI...',
        ],
        tip: 'Bạn có thể hỏi AI bất kỳ câu hỏi nào bằng ngôn ngữ tự nhiên tiếng Việt!',
      ),
      (
        title: '5. Giả lập GPA & Dự báo Cảnh báo Học vụ',
        icon: Icons.calculate,
        color: Color(0xFFEA580C),
        points: [
          'Bấm nút "📊 Giả lập GPA" trên thanh công cụ.',
          'Thử thay đổi điểm chữ (A, B+, B, C+, C, D+, D, F) cho từng môn học trong kỳ.',
          'Hệ thống sẽ tính toán ngay lập tức điểm GPA học kỳ thang 4, thang 10, GPA tích lũy toàn khóa và dự báo mức cảnh báo học vụ theo QĐ 1574.',
          'Xem điều kiện nhận học bổng Khuyến khích học tập: GPA >= 3.20 (Học bổng Giỏi) hoặc GPA >= 3.60 (Học bổng Xuất sắc).',
        ],
        tip: 'Công cụ giúp bạn lên chiến lược điểm số để đạt bằng Khá, Giỏi hoặc tốt nghiệp đúng tiến độ.',
      ),
      (
        title: '6. Đồng bộ Lịch học và Tra cứu Thời khóa biểu',
        icon: Icons.calendar_month,
        color: Color(0xFF2563EB),
        points: [
          'Vào tab "Thời khóa biểu" hoặc chuyển sang giao diện "Trang Web Trường".',
          'Chọn tuần học từ Tuần 1 (19/10/2026) đến các tuần tiếp theo.',
          'Bấm nút "Xuất file Lịch iCal" để tải file lịch chuẩn .ics, có thể import trực tiếp vào Google Calendar, iPhone, Outlook.',
        ],
        tip: 'Mọi thay đổi lớp học phần đều được đồng bộ tức thời trên cả hai giao diện Portal và Web.',
      ),
      (
        title: '7. Kênh Hỗ trợ & Thông tin Liên hệ',
        icon: Icons.contact_support,
        color: Color(0xFF059669),
        points: [
          'Phòng Đào tạo Đại học: Tầng 1, Nhà Điều hành, Trường ĐH Tây Nguyên (567 Lê Duẩn, TP. Buôn Ma Thuột).',
          'Khoa Khoa học Tự nhiên và Công nghệ - Bộ môn Công nghệ Thông tin: Nhà học 7 tầng.',
          'Email hỗ trợ kỹ thuật cổng đào tạo: daotao@ttn.edu.vn | Website: https://www.ttn.edu.vn',
          'Điện thoại tư vấn sinh viên: 0262.3825.185 (Phòng Đào tạo) - 0262.3853.279 (Khoa KHTN&CN)',
        ],
        tip: 'Thời gian tiếp sinh viên: Sáng từ 7h30 - 11h00, Chiều từ 13h30 - 16h30 từ Thứ 2 đến Thứ 6.',
      ),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              border: Border.all(color: const Color(0xFFBFDBFE)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.help_center_rounded, color: Color(0xFF1D4ED8), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CẨM NANG HƯỚNG DẪN SỬ DỤNG HỆ THỐNG ĐÀO TẠO ĐẠI HỌC TÂY NGUYÊN',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                      ),
                      Text(
                        'Tài liệu hướng dẫn thao tác đăng ký tín chỉ, tra cứu thời khóa biểu, dùng AI tối ưu và các quy định học vụ.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: guides.length,
              itemBuilder: (context, idx) {
                final g = guides[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: g.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(g.icon, color: g.color, size: 22),
                    ),
                    title: Text(g.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                    childrenPadding: const EdgeInsets.all(12),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...g.points.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A))),
                                Expanded(child: Text(p, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4))),
                              ],
                            ),
                          )),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb, size: 16, color: Color(0xFFB45309)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(g.tip, style: const TextStyle(fontSize: 11, color: Color(0xFF78350F), fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  final double? width;

  const _TableHeaderCell(this.text, {this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
