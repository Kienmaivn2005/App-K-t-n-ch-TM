import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/student_profile.dart';
import '../../providers/planner_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/conflict_banner.dart';
import '../widgets/qr_code_widget.dart';

class TuitionScreen extends StatelessWidget {
  const TuitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    final totalCredits = planner.totalCredits;
    final theoryCredits = planner.totalTheoryCredits;
    final practiceCredits = planner.totalPracticeCredits;
    final baseCost = planner.baseTuitionCost;
    final policyDiscount = planner.policyDiscountAmount;
    final scholarshipDiscount = planner.scholarshipDiscountAmount;
    final finalCost = planner.finalPayableTuition;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ConflictBanner(),
            _buildIntroBanner(),
            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          planner.profile.program.label,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        'Học kỳ 1 (2026 - 2027)',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'TỔNG HỌC PHÍ THỰC NỘP (ƯỚC TÍNH)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${currencyFormat.format(finalCost)} VNĐ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryStat('Tổng số tín chỉ', '$totalCredits TC'),
                      _buildSummaryStat('Lý thuyết', '$theoryCredits TC'),
                      _buildSummaryStat('Thực hành', '$practiceCredits TC'),
                      _buildSummaryStat('Số học phần', '${planner.activePlan.selectedSections.length} Môn'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Payment Deadline & VietQR Quick Pay Card
            _buildPaymentScheduleAndQrCard(context, currencyFormat, finalCost, planner),
            const SizedBox(height: 16),
            // Configuration & Policy Card
            _buildConfigurationCard(context, planner),
            const SizedBox(height: 16),
            // Detailed breakdown
            _buildCostBreakdownCard(
              currencyFormat,
              baseCost,
              policyDiscount,
              scholarshipDiscount,
              finalCost,
              planner,
            ),
            const SizedBox(height: 16),
            // Registered courses fee list
            _buildCourseFeeList(planner, currencyFormat),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ước Tính Học Phí Học Kỳ 1 (2026 - 2027)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Bảng ước tính học phí tự động căn cứ theo số tín chỉ đăng ký, biểu phí chuẩn ĐH Tây Nguyên, chính sách miễn giảm và mục tiêu học bổng khuyến khích.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentScheduleAndQrCard(BuildContext context, NumberFormat fmt, int finalCost, PlannerProvider planner) {
    final studentId = planner.profile.studentId;
    final fullName = planner.profile.fullName;
    final paymentSyntax = 'HP HK1 $studentId $fullName';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.event_busy_rounded, color: Color(0xFFDC2626), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Kế Hoạch & Hạn Nộp Học Phí',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Còn 18 ngày',
                  style: TextStyle(color: Color(0xFFDC2626), fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mở đợt thu học phí:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text('01/12/2026', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Hạn chót đóng tiền (Kỳ 1):', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                    Text('31/12/2026 (23:59)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Số tài khoản trường ĐH Tây Nguyên:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text('5200201004567 (Agribank)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SimpleQrCodeWidget(
                data: 'https://img.vietqr.io/image/agribank-5200201004567-compact2.png?amount=$finalCost&addInfo=${Uri.encodeComponent(paymentSyntax)}',
                size: 110,
                darkColor: const Color(0xFF1E3A8A),
                centerLabel: 'TTN',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quét VietQR Đóng Học Phí',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cú pháp chuẩn:\n"$paymentSyntax"',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: 'STK: 5200201004567 (Agribank - Truong DH Tay Nguyen)\nSố tiền: $finalCost VND\nNội dung: $paymentSyntax',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép cú pháp chuyển khoản học phí TTN!'),
                            backgroundColor: Color(0xFF1E3A8A),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Sao chép cú pháp', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
      ],
    );
  }

  Widget _buildConfigurationCard(BuildContext context, PlannerProvider planner) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Tùy Chỉnh Biểu Phí & Chính Sách:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Program type
          Row(
            children: [
              const Expanded(
                child: Text('Chương trình đào tạo:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              DropdownButton<AcademicProgram>(
                value: planner.profile.program,
                underline: const SizedBox(),
                items: AcademicProgram.values.map((p) {
                  return DropdownMenuItem(value: p, child: Text(p.label));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    planner.updateProfile(planner.profile.copyWith(program: val));
                  }
                },
              ),
            ],
          ),
          const Divider(height: 16),
          // Tuition policy
          Row(
            children: [
              const Expanded(
                child: Text('Chính sách miễn giảm học phí:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              DropdownButton<TuitionPolicy>(
                value: planner.profile.tuitionPolicy,
                underline: const SizedBox(),
                items: TuitionPolicy.values.map((pol) {
                  return DropdownMenuItem(
                    value: pol,
                    child: Text(
                      pol.discountRate > 0 ? '${pol.label} (Giảm ${(pol.discountRate * 100).toInt()}%)' : pol.label,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    planner.updateProfile(planner.profile.copyWith(tuitionPolicy: val));
                  }
                },
              ),
            ],
          ),
          const Divider(height: 16),
          // Target GPA for scholarship
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mục tiêu điểm GPA kỳ này (Học bổng):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(
                      'Hiện tại: ${planner.profile.targetGpa.toStringAsFixed(2)} / 4.0 (${planner.scholarshipTitle})',
                      style: TextStyle(color: AppTheme.slate500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 140,
                child: Slider(
                  value: planner.profile.targetGpa,
                  min: 2.0,
                  max: 4.0,
                  divisions: 20,
                  label: planner.profile.targetGpa.toStringAsFixed(2),
                  onChanged: (val) {
                    planner.updateProfile(planner.profile.copyWith(targetGpa: val));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdownCard(
    NumberFormat fmt,
    int baseCost,
    int policyDiscount,
    int scholarshipDiscount,
    int finalCost,
    PlannerProvider planner,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bảng Ước Tính Chi Phí Học Kỳ:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 14),
          _buildCostRow(
            'Học phí gốc (Lý thuyết + Thực hành hệ số 1.2x)',
            '+ ${fmt.format(baseCost)} đ',
            Colors.black87,
          ),
          const SizedBox(height: 8),
          _buildCostRow(
            'Miễn giảm theo diện chính sách (${planner.profile.tuitionPolicy.label})',
            '- ${fmt.format(policyDiscount)} đ',
            AppTheme.success,
          ),
          const SizedBox(height: 8),
          _buildCostRow(
            'Học bổng Khuyến khích Học tập (${planner.scholarshipTitle})',
            '- ${fmt.format(scholarshipDiscount)} đ',
            AppTheme.secondary,
          ),
          const Divider(height: 24),
          _buildCostRow(
            'Tổng học phí ước tính thực nộp:',
            '${fmt.format(finalCost)} đ',
            AppTheme.primary,
            isBold: true,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String title, String amount, Color color, {bool isBold = false, double fontSize = 13}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.slate700,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseFeeList(PlannerProvider planner, NumberFormat fmt) {
    final sections = planner.activePlan.selectedSections.values.toList();
    final pricePerCredit = planner.profile.program.basePricePerCredit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi Tiết Học Phí Từng Học Phần Đã Đăng Ký:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          if (sections.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text('Chưa có học phần nào được chọn trong phương án này.', style: TextStyle(color: AppTheme.slate400)),
              ),
            )
          else
            ...sections.map((sec) {
              final course = planner.getCourseByCode(sec.courseCode);
              final credits = course?.credits ?? 3;
              final fee = credits * pricePerCredit;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.slate50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(sec.colorHex),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${sec.courseCode} - ${sec.courseName}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Lớp: ${sec.id} • $credits Tín chỉ (LT: ${course?.theoryCredits ?? credits}, TH: ${course?.practiceCredits ?? 0})',
                            style: TextStyle(color: AppTheme.slate500, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${fmt.format(fee)} đ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.slate800),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

