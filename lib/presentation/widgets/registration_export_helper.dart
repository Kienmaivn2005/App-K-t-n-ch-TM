import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/timetable_models.dart';

/// ============================================================================
/// EXPORT MODULE: One-Click Registration Code Generator & Dialog
/// ============================================================================
class RegistrationExportHelper {
  /// Sinh chuỗi mảng mã lớp chuẩn để paste vào cổng tín chỉ TTN
  /// Ví dụ: "4110034_01, 4110034_01_TH02, 4110055_03, 4110088_01"
  static String formatPlainList(List<ClassSection> sections) {
    return sections.map((s) => s.classId).join(', ');
  }

  /// Sinh mảng JSON: ["4110034_01", "4110034_01_TH02"]
  static String formatJsonArray(List<ClassSection> sections) {
    final list = sections.map((s) => '"${s.classId}"').join(', ');
    return '[$list]';
  }

  /// Hiển thị Modal Sheet / Dialog hỗ trợ "Săn Tín Chỉ Nhanh"
  static void showExportSheet(BuildContext context, ScheduleOption option) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ExportModalContent(option: option),
    );
  }
}

class _ExportModalContent extends StatefulWidget {
  final ScheduleOption option;
  const _ExportModalContent({required this.option});

  @override
  State<_ExportModalContent> createState() => _ExportModalContentState();
}

class _ExportModalContentState extends State<_ExportModalContent> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final rawText = RegistrationExportHelper.formatPlainList(widget.option.selectedSections);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flash_on, color: Color(0xFF1E3A8A), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'One-Click Copy Đăng Ký Tín Chỉ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      '${widget.option.selectedSections.length} mã lớp • ${widget.option.totalCredits} tín chỉ',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hướng dẫn
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF0284C7)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sao chép chuỗi mã lớp bên dưới và dán trực tiếp vào ô đăng ký nhanh trên cổng daotao.ttn.edu.vn khi mở cổng.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Hộp hiển thị mã lớp
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              rawText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFF38BDF8),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nút bấm Copy Toàn Bộ
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: rawText));
                if (!context.mounted) return;
                setState(() => _copied = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép toàn bộ mã lớp vào Clipboard!'),
                    backgroundColor: Color(0xFF059669),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(_copied ? Icons.check_circle : Icons.copy_all, size: 20),
              label: Text(
                _copied ? 'ĐÃ COPY MÃ LỚP' : 'COPY TẤT CẢ MÃ LỚP',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _copied ? const Color(0xFF059669) : const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
