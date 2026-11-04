import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/planner_provider.dart';
import '../../services/ttn_database.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegisterMode = false; // Chuyển đổi giữa Đăng nhập & Đăng ký tài khoản mới

  // Controllers cho Đăng nhập
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controllers cho Đăng ký
  final _regMsvController = TextEditingController();
  final _regFullNameController = TextEditingController();
  final _regMajorController = TextEditingController(text: 'Công nghệ thông tin');
  final _regCohortController = TextEditingController(text: 'K23');
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureRegPassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  String? _errorMessage;

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    _regMsvController.dispose();
    _regFullNameController.dispose();
    _regMajorController.dispose();
    _regCohortController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister(PlannerProvider planner) async {
    final msv = _regMsvController.text.trim();
    final name = _regFullNameController.text.trim();
    final major = _regMajorController.text.trim().isNotEmpty ? _regMajorController.text.trim() : 'Công nghệ thông tin';
    final cohort = _regCohortController.text.trim().isNotEmpty ? _regCohortController.text.trim() : 'K23';
    final pwd = _regPasswordController.text.trim();
    final confirmPwd = _regConfirmPasswordController.text.trim();

    if (msv.isEmpty || name.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập đầy đủ Mã số sinh viên (MSSV) và Họ và tên!');
      return;
    }

    if (pwd.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu phải có độ dài tối thiểu từ 6 ký tự!');
      return;
    }

    if (pwd != confirmPwd) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không khớp! Vui lòng kiểm tra lại.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    // Lưu mật khẩu và thông tin sinh viên vào cơ sở dữ liệu
    TTNDatabase.studentPasswords[msv] = pwd;
    TTNDatabase.students[msv] = {
      'studentId': msv,
      'fullName': name,
      'major': major,
      'cohort': cohort,
      'slotsCount': 4,
      'slots': [],
    };

    if (mounted) {
      planner.login(
        studentId: msv,
        password: pwd,
        fullName: name,
        major: major,
        cohort: cohort,
      );
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('🎉 Đăng ký thành công! Chào mừng sinh viên $name ($msv)'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleLogin(PlannerProvider planner) async {
    final msv = _studentIdController.text.trim();
    final pwd = _passwordController.text.trim();

    if (msv.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập Mã số sinh viên (MSSV)!');
      return;
    }

    if (pwd.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mật khẩu tài khoản!');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    // Xác thực mật khẩu bắt buộc phải đúng từng mã sinh viên (mật khẩu riêng hoặc ngày sinh ddMMyyyy)
    final isPasswordValid = TTNDatabase.verifyPassword(msv, pwd);

    if (!isPasswordValid) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Mật khẩu không chính xác cho sinh viên $msv! Vui lòng nhập đúng mật khẩu đã tạo trên hệ thống.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Đăng nhập thất bại: Mật khẩu không chính xác cho sinh viên $msv!'),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final ttnStudent = TTNDatabase.getStudent(msv);
    final fullName = ttnStudent != null ? ttnStudent['fullName'] as String : (msv == '23103023' ? 'Nguyễn Huy Hoàng' : 'Sinh viên TTN');
    final major = ttnStudent != null && ttnStudent['major'] != null ? ttnStudent['major'] as String : 'Công nghệ thông tin';
    final cohort = ttnStudent != null && ttnStudent['cohort'] != null ? ttnStudent['cohort'] as String : 'K23';

    if (mounted) {
      planner.login(
        studentId: msv,
        password: pwd,
        fullName: fullName,
        major: major,
        cohort: cohort,
      );
      setState(() => _isLoading = false);
    }
  }

  void _loginQuickAccount(PlannerProvider planner, String msv, String name) {
    _studentIdController.text = msv;
    final pwd = TTNDatabase.getPasswordForStudent(msv);
    _passwordController.text = pwd;
    final ttnStudent = TTNDatabase.getStudent(msv);
    final effMajor = ttnStudent != null && ttnStudent['major'] != null ? ttnStudent['major'] as String : 'Công nghệ thông tin';
    final effCohort = ttnStudent != null && ttnStudent['cohort'] != null ? ttnStudent['cohort'] as String : 'K23';
    planner.login(
      studentId: msv,
      password: pwd,
      fullName: name,
      major: effMajor,
      cohort: effCohort,
    );
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate aesthetic
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Header
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          'Đăng Ký Tín Chỉ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Smart Credit Planner • ĐH Tây Nguyên',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mode Switcher Tabs (Đăng nhập / Đăng ký)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (_isRegisterMode) {
                                setState(() {
                                  _isRegisterMode = false;
                                  _errorMessage = null;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isRegisterMode ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !_isRegisterMode
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.login_rounded,
                                    size: 18,
                                    color: !_isRegisterMode ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Đăng Nhập',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: !_isRegisterMode ? FontWeight.bold : FontWeight.w500,
                                      color: !_isRegisterMode ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (!_isRegisterMode) {
                                setState(() {
                                  _isRegisterMode = true;
                                  _errorMessage = null;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isRegisterMode ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isRegisterMode
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_add_rounded,
                                    size: 18,
                                    color: _isRegisterMode ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Đăng Ký Mới',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: _isRegisterMode ? FontWeight.bold : FontWeight.w500,
                                      color: _isRegisterMode ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sub-header title
                  Center(
                    child: Text(
                      _isRegisterMode ? 'Đăng Ký Tài Khoản Sinh Viên' : 'Xác Thực Tài Khoản Mô Phỏng',
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      _isRegisterMode
                          ? 'Tạo tài khoản đăng ký tín chỉ mới tại Đại học Tây Nguyên'
                          : 'Cổng Đăng Ký Học Phần • Đại học Tây Nguyên (TTN)',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // FORM CONTENT
                  if (!_isRegisterMode)
                    _buildLoginForm(planner)
                  else
                    _buildRegisterForm(planner),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGIN FORM WIDGET ---
  Widget _buildLoginForm(PlannerProvider planner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Student ID input
        TextField(
          controller: _studentIdController,
          decoration: InputDecoration(
            labelText: 'Mã số sinh viên (MSSV)',
            hintText: 'VD: 23103035',
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 16),

        // Password input
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
          onSubmitted: (_) => _handleLogin(planner),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          _buildErrorBanner(_errorMessage!),
        ],
        const SizedBox(height: 12),

        // Remember me & Forgot Password
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  activeColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) => setState(() => _rememberMe = val ?? true),
                ),
                const Text('Ghi nhớ đăng nhập', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
              ],
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hệ thống gợi ý: Mật khẩu mặc định của sinh viên là ngày sinh dạng ddmmyyyy (VD: 21112005)!')),
                );
              },
              child: const Text('Quên mật khẩu?', style: TextStyle(fontSize: 12.5)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Login Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          onPressed: _isLoading ? null : () => _handleLogin(planner),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Đăng Nhập Vào Hệ Thống', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
        ),
        const SizedBox(height: 16),

        // Link to switch to Register
        InkWell(
          onTap: () => setState(() {
            _isRegisterMode = true;
            _errorMessage = null;
          }),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_alt_1_rounded, size: 16, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Text(
                  'Chưa có tài khoản? Đăng ký tài khoản mới ngay',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Quick Demo Accounts Divider
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Tài Khoản Mô Phỏng TTN (1-Click)',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 14),

        // Demo accounts list across all TTN faculties
        _buildQuickAccountTile(
          planner: planner,
          msv: '23103035',
          name: 'Mai Đàm Thế Kiên',
          desc: 'K23 Công nghệ thông tin • Khoa KHTN & Công nghệ',
          isPrimary: true,
        ),
        const SizedBox(height: 8),
        _buildQuickAccountTile(
          planner: planner,
          msv: '23772018',
          name: 'Nguyễn Hoàng Nam',
          desc: 'K23 Bác sĩ Y khoa • Khoa Y Dược ĐH Tây Nguyên',
        ),
        const SizedBox(height: 8),
        _buildQuickAccountTile(
          planner: planner,
          msv: '23101015',
          name: 'Trần Đình Trọng',
          desc: 'K23 Sư phạm Toán học • Khoa Sư phạm',
        ),
        const SizedBox(height: 8),
        _buildQuickAccountTile(
          planner: planner,
          msv: '23734026',
          name: 'Lê Phương Thảo',
          desc: 'K23 Quản trị kinh doanh • Khoa Kinh tế',
        ),
        const SizedBox(height: 8),
        _buildQuickAccountTile(
          planner: planner,
          msv: '23764015',
          name: 'Phạm Quốc Bảo',
          desc: 'K23 Bác sĩ Thú y • Khoa Chăn nuôi Thú y',
        ),
        const SizedBox(height: 8),
        _buildQuickAccountTile(
          planner: planner,
          msv: '23103023',
          name: 'Nguyễn Huy Hoàng',
          desc: 'K23 CNTT (22 HP tích lũy • GPA 2.63 chuẩn xác)',
        ),
        const SizedBox(height: 8),
        _buildQuickAccountTile(
          planner: planner,
          msv: 'GV_NNHU',
          name: 'ThS. Nguyễn Thị Như',
          desc: 'Cố vấn học tập (CVHT) ĐH Tây Nguyên',
          isAdvisor: true,
        ),
      ],
    );
  }

  // --- REGISTER FORM WIDGET ---
  Widget _buildRegisterForm(PlannerProvider planner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // MSSV
        TextField(
          controller: _regMsvController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Mã số sinh viên (MSSV) *',
            hintText: 'VD: 23103099',
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 14),

        // Họ và tên
        TextField(
          controller: _regFullNameController,
          decoration: InputDecoration(
            labelText: 'Họ và tên sinh viên *',
            hintText: 'VD: Nguyễn Văn An',
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 14),

        // Ngành học & Khóa (2 cột)
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _regMajorController,
                decoration: InputDecoration(
                  labelText: 'Ngành học',
                  hintText: 'Công nghệ thông tin',
                  prefixIcon: const Icon(Icons.school_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _regCohortController,
                decoration: InputDecoration(
                  labelText: 'Khóa',
                  hintText: 'K23',
                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Mật khẩu
        TextField(
          controller: _regPasswordController,
          obscureText: _obscureRegPassword,
          decoration: InputDecoration(
            labelText: 'Mật khẩu (tối thiểu 6 ký tự) *',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscureRegPassword = !_obscureRegPassword);
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 14),

        // Xác nhận mật khẩu
        TextField(
          controller: _regConfirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Xác nhận lại mật khẩu *',
            prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
          onSubmitted: (_) => _handleRegister(planner),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildErrorBanner(_errorMessage!),
        ],
        const SizedBox(height: 20),

        // Register Submit Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          onPressed: _isLoading ? null : () => _handleRegister(planner),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 19),
                    SizedBox(width: 8),
                    Text('Tạo Tài Khoản & Vào Hệ Thống', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                  ],
                ),
        ),
        const SizedBox(height: 16),

        // Back to login button
        TextButton(
          onPressed: () => setState(() {
            _isRegisterMode = false;
            _errorMessage = null;
          }),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text(
                'Đã có tài khoản? Quay lại đăng nhập',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccountTile({
    required PlannerProvider planner,
    required String msv,
    required String name,
    required String desc,
    bool isPrimary = false,
    bool isAdvisor = false,
  }) {
    return InkWell(
      onTap: () => _loginQuickAccount(planner, msv, name),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFFEFF6FF)
              : (isAdvisor ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFF93C5FD)
                : (isAdvisor ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: isAdvisor ? const Color(0xFFD97706) : const Color(0xFF2563EB),
              child: Text(
                isAdvisor ? 'GV' : 'SV',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const SizedBox(width: 6),
                      Text('($msv)', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                  Text(desc, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
