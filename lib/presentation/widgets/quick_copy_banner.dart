import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/timetable_models.dart';

/// ============================================================================
/// QUICK COPY BANNER WIDGET
/// Feature-First Clean Architecture: lib/presentation/widgets/quick_copy_banner.dart
/// Nút sao chép 1 chạm toàn bộ mã lớp học phần vào Clipboard dạng [Mã1, Mã2]
/// Phục vụ sinh viên dán tức thì lúc cổng daotao.ttn.edu.vn mở đăng ký
/// ============================================================================

class QuickCopyBanner extends StatefulWidget {
  final List<ClassSection> sections;
  final int totalCredits;

  const QuickCopyBanner({
    super.key,
    required this.sections,
    required this.totalCredits,
  });

  @override
  State<QuickCopyBanner> createState() => _QuickCopyBannerState();
}

class _QuickCopyBannerState extends State<QuickCopyBanner> {
  bool _isCopied = false;

  String get _formattedCodes {
    final list = widget.sections.map((s) => s.classId).join(', ');
    return '[$list]';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sections.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Slate 900
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.sections.length} mã lớp • ${widget.totalCredits} TC',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  _formattedCodes,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    color: Color(0xFF38BDF8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: _formattedCodes));
              if (!mounted) return;
              setState(() => _isCopied = true);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Đã sao chép: $_formattedCodes'),
                  backgroundColor: const Color(0xFF059669),
                  duration: const Duration(seconds: 2),
                ),
              );
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) setState(() => _isCopied = false);
              });
            },
            icon: Icon(_isCopied ? Icons.check : Icons.copy_rounded, size: 14),
            label: Text(_isCopied ? 'ĐÃ COPY' : 'COPY MÃ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCopied ? const Color(0xFF059669) : const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}
