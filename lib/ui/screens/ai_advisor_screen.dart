import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/planner_provider.dart';
import '../../services/ttn_handbook_data.dart';
import '../../services/ttn_database.dart';
import 'prerequisite_roadmap_screen.dart';
import 'gpa_simulator_screen.dart';

class MessageItem {
  final bool isUser;
  final String text;
  final DateTime time;
  final List<String>? actionSuggestions;

  MessageItem({
    required this.isUser,
    required this.text,
    required this.time,
    this.actionSuggestions,
  });
}

class AiAdvisorScreen extends StatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isTyping = false;

  final List<MessageItem> _messages = [
    MessageItem(
      isUser: false,
      text: 'Xin chào! Tôi là Trợ Lý AI Cố Vấn Học Tập UniPlan của Trường Đại học Tây Nguyên.\n\nTôi được huấn luyện với toàn bộ dữ liệu Sổ tay sinh viên 2023, Quy chế đào tạo tín chỉ số 1574/QĐ-ĐHTN và cơ sở dữ liệu học phần CNTT.\n\nBạn có thể hỏi tôi bất kỳ điều gì về: môn học, tiên quyết, đăng ký tín chỉ, học bổng, giảng viên hoặc thời khóa biểu!',
      time: DateTime.now(),
      actionSuggestions: [
        'Kỳ này tôi nên đăng ký môn gì?',
        'Điều kiện nhận học bổng khuyến khích?',
        'Xem cây môn tiên quyết toàn khóa',
        'Giảng viên dạy môn Lập trình di động?',
        'Học phí tín chỉ tính thế nào?',
      ],
    ),
  ];

  void _sendMessage(String query, PlannerProvider planner) async {
    final text = query.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();
    setState(() {
      _messages.add(MessageItem(isUser: true, text: text, time: DateTime.now()));
      _isTyping = true;
    });

    _scrollToBottom();

    // AI Response generation based on TTN Knowledge Base
    await Future.delayed(const Duration(milliseconds: 600));

    final reply = _generateAiAnswer(text, planner);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(reply);
      });
      _scrollToBottom();
    }
  }

  MessageItem _generateAiAnswer(String prompt, PlannerProvider planner) {
    final pLower = prompt.toLowerCase();
    final profile = planner.profile;

    // 1. Gợi ý môn học / Học kỳ
    if (pLower.contains('nên đăng ký') || pLower.contains('gợi ý') || pLower.contains('kỳ này') || pLower.contains('môn gì')) {
      final sem = profile.semester;
      final semInt = int.tryParse(sem) ?? 1;
      final courses = TTNHandbookDatabase.getCoursesBySemester(semInt);
      final courseNames = courses.take(6).map((c) => '• [${c.code}] ${c.name} (${c.credits} TC - ${c.isMandatory ? "Bắt buộc" : "Tự chọn"})').join('\n');

      return MessageItem(
        isUser: false,
        text: 'Dựa trên Sổ tay sinh viên 2023 và hồ sơ hiện tại của bạn ($semInt - ${profile.major}), đây là các học phần được Nhà trường gợi ý cho Học kỳ $semInt:\n\n$courseNames\n\n💡 Lời khuyên của Cố vấn: Bạn nên duy trì số tín chỉ từ 16 - 20 TC để đảm bảo khối lượng học tập cân bằng, không vượt quá giới hạn tối đa 24 TC.',
        time: DateTime.now(),
        actionSuggestions: [
          'Chạy AI tự động xếp lịch ngay',
          'Kiểm tra xung đột thời khóa biểu',
          'Xem lộ trình môn tiên quyết',
        ],
      );
    }

    // 2. Học bổng / Điểm GPA
    if (pLower.contains('học bổng') || pLower.contains('điểm') || pLower.contains('gpa') || pLower.contains('học lực')) {
      return MessageItem(
        isUser: false,
        text: 'Theo Quy chế đào tạo tín chỉ Trường Đại học Tây Nguyên (QĐ 1574):\n\n'
            '🏆 Tiêu chuẩn xét Học bổng Khuyến khích học tập:\n'
            '• Loại Xuất sắc (Miễn 100% học phí): GPA >= 3.60 và Điểm rèn luyện >= 90.\n'
            '• Loại Giỏi (Miễn 50% học phí): GPA 3.20 - 3.59 và Điểm rèn luyện >= 80.\n'
            '• Loại Khá (Miễn 20% học phí): GPA 2.50 - 3.19 và Điểm rèn luyện >= 70.\n\n'
            '📌 Điểm TBCTL hiện tại của bạn là: ${profile.currentGpa.toStringAsFixed(2)} / 4.00.\n'
            'Bạn có thể dùng công cụ Mô phỏng GPA để tính điểm mục tiêu cần đạt kỳ này!',
        time: DateTime.now(),
        actionSuggestions: [
          'Mở công cụ Mô phỏng GPA',
          'Kiểm tra điều kiện tốt nghiệp',
        ],
      );
    }

    // 3. Tiên quyết / Cây môn học
    if (pLower.contains('tiên quyết') || pLower.contains('cây') || pLower.contains('lộ trình') || pLower.contains('học trước')) {
      return MessageItem(
        isUser: false,
        text: 'Trong chương trình đào tạo CNTT Khóa 2023, các chuỗi môn tiên quyết quan trọng gồm có:\n\n'
            '🔗 Chuỗi Lập trình:\n'
            'Tin học đại cương (KC211027) ➔ Kỹ thuật lập trình (KC212604) ➔ Cấu trúc dữ liệu & giải thuật (KC215037) ➔ Lập trình hướng đối tượng (KC213611) ➔ Lập trình di động (KC215046) & Web (KC215047).\n\n'
            '🔗 Chuỗi Mạng & Hệ thống:\n'
            'Cấu trúc rời rạc (KC212601) ➔ Tổ chức máy tính (KC212602) ➔ Nhập môn mạng (KC215039) ➔ An toàn thông tin (KC213613).\n\n'
            'Bạn có thể mở giao diện Sơ đồ Cây Tiên Quyết tương tác trực quan ngay!',
        time: DateTime.now(),
        actionSuggestions: [
          'Mở Sơ đồ Cây Tiên Quyết 8 kỳ',
          'Kiểm tra môn bị thiếu',
        ],
      );
    }

    // 4. Giảng viên
    if (pLower.contains('giảng viên') || pLower.contains('thầy') || pLower.contains('cô') || pLower.contains('giang') || pLower.contains('hải')) {
      final gvList = TTNDatabase.lecturerCourses.entries.map((e) => '• ${e.key}: Phụ trách ${e.value.join(", ")}').join('\n');
      return MessageItem(
        isUser: false,
        text: 'Thông tin một số giảng viên Bộ môn Công nghệ thông tin - Trường Đại học Tây Nguyên:\n\n$gvList\n\nCố vấn học tập (CVHT) của bạn: ${profile.advisor}.',
        time: DateTime.now(),
        actionSuggestions: [
          'Xem thời khóa biểu các lớp của GV',
          'Đổi lớp học phần',
        ],
      );
    }

    // 5. Học phí
    if (pLower.contains('học phí') || pLower.contains('tiền') || pLower.contains('đơn giá') || pLower.contains('miễn giảm')) {
      final tuition = planner.finalPayableTuition;
      final credits = planner.activePlan.totalCredits;
      return MessageItem(
        isUser: false,
        text: '💰 Quy định học phí tín chỉ Trường ĐH Tây Nguyên:\n\n'
            '• Đơn giá chuẩn: ~619.000 đ / Tín chỉ lý thuyết.\n'
            '• Tín chỉ thực hành / phòng máy: Phụ phí nhân hệ số 1.2 (~742.800 đ / TC).\n'
            '• Kế hoạch hiện tại của bạn: $credits tín chỉ.\n'
            '• Tổng học phí dự toán sau khi áp dụng chính sách miễn giảm & học bổng: ${NumberFormat('#,###').format(tuition)} đ.\n\n'
            'Hệ thống tự động áp dụng chế độ con thương binh, hộ nghèo và học bổng khuyến khích!',
        time: DateTime.now(),
        actionSuggestions: [
          'Xem chi tiết Ước tính học phí',
          'Đổi chính sách miễn giảm',
        ],
      );
    }

    // 6. Xếp lịch / Trùng tiết
    if (pLower.contains('xếp lịch') || pLower.contains('trùng') || pLower.contains('auto') || pLower.contains('ai') || pLower.contains('thứ')) {
      return MessageItem(
        isUser: false,
        text: 'UniPlan AI trang bị thuật toán CSP Backtracking thông minh giải bài toán xếp lịch:\n\n'
            '✨ Tránh tiết 1-2 (sáng sớm).\n'
            '✨ Tối đa hóa ngày nghỉ trọn vẹn (không phải đến trường).\n'
            '✨ Tránh lịch học cuối tuần (Thứ 7, CN).\n'
            '✨ Gom lịch học liên tục, giảm thiểu tiết trống (tiết cửa sổ).\n\n'
            'Hệ thống sẽ thử hàng nghìn tổ hợp và xếp hạng điểm tối ưu từ cao xuống thấp cho bạn lựa chọn!',
        time: DateTime.now(),
        actionSuggestions: [
          'Chạy AI tự động xếp lịch ngay',
          'Xem Thời khóa biểu tuần',
        ],
      );
    }

    // Fallback general response
    return MessageItem(
      isUser: false,
      text: 'Tôi đã tiếp nhận câu hỏi của bạn về: "$prompt".\n\n'
          'Theo dữ liệu Sổ tay sinh viên 2023 và Quy chế đào tạo tín chỉ 1574:\n'
          '• Sinh viên ngành CNTT K23 cần hoàn thành tối thiểu 145 tín chỉ để xét tốt nghiệp.\n'
          '• Mỗi học kỳ chính đăng ký tối thiểu 14 TC (hoặc 12 TC) và tối đa 24 TC.\n'
          '• Điểm TBCTL (GPA) cần đạt từ 2.00 trở lên để không bị cảnh báo học vụ.\n\n'
          'Bạn cần tôi hỗ trợ cụ thể phần nào tiếp theo?',
      time: DateTime.now(),
      actionSuggestions: [
        'Kỳ này tôi nên đăng ký môn gì?',
        'Mở Sơ đồ Cây Tiên Quyết 8 kỳ',
        'Mở công cụ Mô phỏng GPA',
        'Xem chi tiết Ước tính học phí',
      ],
    );
  }

  void _handleSuggestionTap(String suggestion, PlannerProvider planner) {
    if (suggestion == 'Mở Sơ đồ Cây Tiên Quyết 8 kỳ' || suggestion == 'Xem lộ trình môn tiên quyết') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrerequisiteRoadmapScreen()));
      return;
    }
    if (suggestion == 'Mở công cụ Mô phỏng GPA') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const GpaSimulatorScreen()));
      return;
    }
    _sendMessage(suggestion, planner);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 1,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFFDE047), size: 20),
            SizedBox(width: 8),
            Text('Trợ Lý Cố Vấn Học Tập AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sơ đồ Tiên quyết',
            icon: const Icon(Icons.account_tree),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrerequisiteRoadmapScreen())),
          ),
          IconButton(
            tooltip: 'Mô phỏng GPA',
            icon: const Icon(Icons.calculate),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GpaSimulatorScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Advisor Status Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFEFF6FF),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Cố vấn AI trực tuyến • Dữ liệu Sổ tay SV 2023 & QĐ 1574/ĐHTN',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, idx) {
                final msg = _messages[idx];
                return _buildMessageBubble(msg, planner);
              },
            ),
          ),
          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              alignment: Alignment.centerLeft,
              child: const Row(
                children: [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Trợ lý AI đang suy nghĩ câu trả lời...', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
                ],
              ),
            ),
          // Input Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      decoration: InputDecoration(
                        hintText: 'Hỏi về môn học, tiên quyết, học bổng, GPA, thời khóa biểu...',
                        hintStyle: const TextStyle(fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onSubmitted: (val) => _sendMessage(val, planner),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1E3A8A),
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 16),
                      onPressed: () => _sendMessage(_textCtrl.text, planner),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageItem msg, PlannerProvider planner) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 580),
        child: Column(
          crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: msg.isUser ? const Color(0xFF1E3A8A) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(msg.isUser ? 14 : 2),
                  bottomRight: Radius.circular(msg.isUser ? 2 : 14),
                ),
                border: msg.isUser ? null : Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: SelectableText(
                msg.text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: msg.isUser ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            if (msg.actionSuggestions != null && msg.actionSuggestions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: msg.actionSuggestions!.map((s) {
                  return ActionChip(
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFF93C5FD)),
                    label: Text(s, style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
                    onPressed: () => _handleSuggestionTap(s, planner),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
