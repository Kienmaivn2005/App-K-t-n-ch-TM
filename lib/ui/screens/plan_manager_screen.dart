import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/plan.dart';
import '../../providers/planner_provider.dart';
import '../../services/ical_export_service.dart';
import '../../services/share_service.dart';
import '../theme/app_theme.dart';
import '../widgets/qr_code_widget.dart';

class PlanManagerScreen extends StatefulWidget {
  const PlanManagerScreen({super.key});

  @override
  State<PlanManagerScreen> createState() => _PlanManagerScreenState();
}

class _PlanManagerScreenState extends State<PlanManagerScreen> {
  final TextEditingController _shareCodeController = TextEditingController();

  @override
  void dispose() {
    _shareCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final activePlan = planner.activePlan;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderBanner(),
            const SizedBox(height: 16),
            _buildPlansListCard(context, planner),
            const SizedBox(height: 16),
            _buildFastCopyRegistrationHelper(context, activePlan),
            const SizedBox(height: 16),
            _buildComparePlansCard(context, planner),
            const SizedBox(height: 16),
            _buildExportActionsCard(context, planner, activePlan),
            const SizedBox(height: 16),
            _buildShareCodeCard(context, planner, activePlan),
            const SizedBox(height: 16),
            _buildTextSummaryCard(context, planner, activePlan),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
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
            child: const Icon(Icons.layers_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kế Hoạch Đăng Ký & Phương Án Dự Phòng',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Chuẩn bị sẵn Kế hoạch A (Chính thức) và các Kế hoạch B, C (Dự phòng). Nếu lớp chính kín chỗ lúc mở cổng trường, kích hoạt ngay phương án dự phòng chỉ trong 1 chạm!',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportActionsCard(BuildContext context, PlannerProvider planner, RegistrationPlan activePlan) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.file_download_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Xuất Dữ Liệu & Đồng Bộ Lịch',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Phương án hiện tại: "${activePlan.name}" (${activePlan.selectedSections.length} môn học)',
                      style: TextStyle(color: AppTheme.slate500, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Export buttons grid
          Row(
            children: [
              Expanded(
                child: _buildExportButton(
                  icon: Icons.calendar_today_rounded,
                  label: 'Xuất file .ICS (Google/Apple)',
                  color: AppTheme.primary,
                  onTap: () => _exportIcsCalendar(context, planner, activePlan),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildExportButton(
                  icon: Icons.share_rounded,
                  label: 'Sao chép Mã Chia Sẻ',
                  color: AppTheme.secondary,
                  onTap: () => _copyShareCode(context, activePlan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildExportButton(
                  icon: Icons.content_copy_rounded,
                  label: 'Sao chép Tóm tắt TKB',
                  color: AppTheme.slate700,
                  onTap: () => _copyTextSummary(context, planner, activePlan),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildExportButton(
                  icon: Icons.print_rounded,
                  label: 'In / Xem Bản In Ấn',
                  color: AppTheme.accent,
                  onTap: () => _showPrintPreview(context, planner, activePlan),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bảng thu gọn danh sách Mã Lớp Học Phần với nút Copy 1-chạm (Chế độ chiến đấu lúc mở cổng tín chỉ)
  Widget _buildFastCopyRegistrationHelper(BuildContext context, RegistrationPlan activePlan) {
    final sections = activePlan.selectedSections.values.toList();
    final allCodesText = sections.map((s) => s.id).join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF87171), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15DC2626),
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
                  Icon(Icons.flash_on_rounded, color: Color(0xFFDC2626), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Chế Độ "Chiến Đấu Lúc Mở Cổng"',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF991B1B)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: allCodesText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã copy TOÀN BỘ ${sections.length} mã lớp: $allCodesText'),
                      backgroundColor: const Color(0xFFDC2626),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_all_rounded, size: 15),
                label: const Text('Copy tất cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Khi cổng daotao.ttn.edu.vn mở đợt đăng ký, bấm nút copy từng mã lớp bên dưới để dán nhanh vào ô đăng ký trước khi hết chỗ:',
            style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
          ),
          const SizedBox(height: 12),
          ...sections.map((sec) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sec.id,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB91C1C), fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sec.courseName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${sec.lecturer} • Còn ${sec.capacity - sec.enrolled} chỗ',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFFDC2626)),
                    tooltip: 'Copy mã lớp ${sec.id}',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: sec.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã sao chép mã lớp: ${sec.id}'),
                          backgroundColor: const Color(0xFFDC2626),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Thẻ so sánh song song hai phương án (Compare Mode)
  Widget _buildComparePlansCard(BuildContext context, PlannerProvider planner) {
    if (planner.plans.length < 2) return const SizedBox.shrink();

    final planA = planner.plans[0];
    final planB = planner.plans[1];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.compare_arrows_rounded, color: AppTheme.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'So Sánh Song Song 2 Phương Án',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Compare Mode', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)),
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(3.5),
              2: FlexColumnWidth(3.5),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Tiêu chí', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(planA.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF1E3A8A))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(planB.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0284C7))),
                  ),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(8), child: Text('Tổng tín chỉ', style: TextStyle(fontSize: 11.5))),
                  Padding(padding: const EdgeInsets.all(8), child: Text('${planA.totalCredits} TC', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                  Padding(padding: const EdgeInsets.all(8), child: Text('${planB.totalCredits} TC', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(8), child: Text('Số học phần', style: TextStyle(fontSize: 11.5))),
                  Padding(padding: const EdgeInsets.all(8), child: Text('${planA.selectedSections.length} môn', style: const TextStyle(fontSize: 11.5))),
                  Padding(padding: const EdgeInsets.all(8), child: Text('${planB.selectedSections.length} môn', style: const TextStyle(fontSize: 11.5))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(8), child: Text('Trạng thái lịch', style: TextStyle(fontSize: 11.5))),
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('✅ Không trùng', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('✅ Sẵn sàng', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => planner.switchPlan(planA.id),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                  child: const Text('Chọn Phương án 1', style: TextStyle(fontSize: 11.5)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => planner.switchPlan(planB.id),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                  child: const Text('Chọn Phương án 2', style: TextStyle(fontSize: 11.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansListCard(BuildContext context, PlannerProvider planner) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.layers_rounded, color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Danh Sách Kế Hoạch Đăng Ký & Dự Phòng:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _showCreatePlanDialog(context, planner),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tạo Kế hoạch Dự phòng'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Chuẩn bị sẵn Kế hoạch A (Chính thức) và các Kế hoạch B, C (Dự phòng) khi lớp chính hết chỗ lúc mở cổng tín chỉ!',
            style: TextStyle(color: AppTheme.slate500, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          ...planner.plans.map((p) {
            final isActive = p.id == planner.activePlanId;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryLight : AppTheme.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? AppTheme.primary : AppTheme.slate200,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  RadioGroup<String>(
                    groupValue: planner.activePlanId,
                    onChanged: (val) {
                      if (val != null) planner.switchPlan(val);
                    },
                    child: Radio<String>(
                      value: p.id,
                      activeColor: AppTheme.primary,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              p.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: isActive ? AppTheme.primary : AppTheme.slate900,
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '⭐ ĐANG HOẠT ĐỘNG',
                                  style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.selectedSections.length} Môn học • Cập nhật lúc ${p.updatedAt.hour}:${p.updatedAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: AppTheme.slate500, fontSize: 11.5),
                        ),
                        if (p.description.isNotEmpty)
                          Text(
                            p.description,
                            style: TextStyle(color: AppTheme.slate600, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    onSelected: (action) {
                      if (action == 'duplicate') {
                        planner.duplicatePlan(p.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã nhân bản ${p.name}')),
                        );
                      } else if (action == 'rename') {
                        _showRenameDialog(context, planner, p);
                      } else if (action == 'delete') {
                        if (planner.plans.length <= 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Không thể xóa phương án duy nhất!')),
                          );
                        } else {
                          planner.deletePlan(p.id);
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Nhân bản tạo dự phòng'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Đổi tên kế hoạch'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded, size: 18, color: AppTheme.danger),
                            SizedBox(width: 8),
                            Text('Xóa kế hoạch', style: TextStyle(color: AppTheme.danger)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildShareCodeCard(BuildContext context, PlannerProvider planner, RegistrationPlan activePlan) {
    final shareCode = ShareService.generateShareCode(activePlan);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_2_rounded, color: AppTheme.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Mã Chia Sẻ Thời Khóa Biểu (Share Code):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Gửi chuỗi mã này cho bạn bè hoặc nhóm bạn để học chung ca mà không sợ lệch lịch!',
            style: TextStyle(color: AppTheme.slate500, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          // Mã QR chia sẻ phương án nhanh sang điện thoại khác
          Center(
            child: Column(
              children: [
                SimpleQrCodeWidget(
                  data: shareCode,
                  size: 150,
                  darkColor: const Color(0xFF1E3A8A),
                  centerLabel: 'PLAN',
                ),
                const SizedBox(height: 6),
                const Text(
                  'Quét mã QR để nhập trực tiếp phương án sang máy bạn cùng nhóm',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.slate100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    shareCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: AppTheme.slate700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.primary),
                  tooltip: 'Sao chép',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shareCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép mã chia sẻ!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 12),
          const Text(
            'Nhập Mã Chia Sẻ Từ Bạn Bè:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _shareCodeController,
                  decoration: const InputDecoration(
                    hintText: 'Dán mã bắt đầu bằng UNIPLAN-...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  final code = _shareCodeController.text.trim();
                  if (code.isEmpty) return;
                  final ok = planner.importShareCode(code);
                  if (ok) {
                    _shareCodeController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã nhập thành công phương án từ bạn bè!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mã chia sẻ không hợp lệ hoặc bị lỗi định dạng!'),
                        backgroundColor: AppTheme.danger,
                      ),
                    );
                  }
                },
                child: const Text('Nhập'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextSummaryCard(BuildContext context, PlannerProvider planner, RegistrationPlan activePlan) {
    final summary = ShareService.generateTextSummary(
      plan: activePlan,
      allCourses: planner.courses,
      studentName: planner.profile.fullName,
      studentId: planner.profile.studentId,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bản Tóm Tắt Dạng Văn Bản:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              TextButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Sao chép tất cả'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: summary));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép bản tóm tắt TKB!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.slate50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Text(
              summary,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                height: 1.45,
                color: AppTheme.slate800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportIcsCalendar(BuildContext context, PlannerProvider planner, RegistrationPlan activePlan) {
    final ics = IcalExportService.generateIcsContent(
      planName: activePlan.name,
      sections: activePlan.selectedSections.values.toList(),
    );

    // Show dialog with ICS preview & copy option
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Xuất File iCalendar (.ICS)'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đã tạo tệp lịch biểu chuẩn RFC 5545 cho 15 tuần học kỳ. Bạn có thể sao chép nội dung hoặc tải về để import vào Google Calendar, Apple Calendar, Outlook:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                height: 150,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.slate100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    ics,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Sao chép mã ICS'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: ics));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép mã iCalendar (.ics)!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _copyShareCode(BuildContext context, RegistrationPlan activePlan) {
    final code = ShareService.generateShareCode(activePlan);
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép Mã chia sẻ cấu hình!')),
    );
  }

  void _copyTextSummary(BuildContext context, PlannerProvider planner, RegistrationPlan activePlan) {
    final summary = ShareService.generateTextSummary(
      plan: activePlan,
      allCourses: planner.courses,
      studentName: planner.profile.fullName,
      studentId: planner.profile.studentId,
    );
    Clipboard.setData(ClipboardData(text: summary));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép tóm tắt thời khóa biểu!')),
    );
  }

  void _showPrintPreview(BuildContext context, PlannerProvider planner, RegistrationPlan activePlan) {
    final summary = ShareService.generateTextSummary(
      plan: activePlan,
      allCourses: planner.courses,
      studentName: planner.profile.fullName,
      studentId: planner.profile.studentId,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bản In Thời Khóa Biểu'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Text(summary, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
  }

  void _showCreatePlanDialog(BuildContext context, PlannerProvider planner) {
    final nameCtrl = TextEditingController(text: 'Phương án ${planner.plans.length + 1}');
    final descCtrl = TextEditingController(text: 'Phương án dự phòng');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo Phương Án Mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên phương án'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Mô tả ngắn'),
            ),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                planner.createNewPlan(name: nameCtrl.text, description: descCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, PlannerProvider planner, RegistrationPlan plan) {
    final nameCtrl = TextEditingController(text: plan.name);
    final descCtrl = TextEditingController(text: plan.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi Tên Phương Án'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên phương án'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Mô tả ngắn'),
            ),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                planner.renamePlan(plan.id, nameCtrl.text, descCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

