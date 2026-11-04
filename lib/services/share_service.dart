import 'dart:convert';
import '../models/course.dart';
import '../models/plan.dart';

class ShareService {
  /// Sinh mã chia sẻ cấu hình Base64 (Share Code)
  static String generateShareCode(RegistrationPlan plan) {
    final payload = {
      'app': 'UniPlanAI',
      'v': 1,
      'planName': plan.name,
      'sectionIds': plan.selectedSections.values.map((s) => s.id).toList(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final jsonStr = jsonEncode(payload);
    final bytes = utf8.encode(jsonStr);
    final base64Str = base64.encode(bytes);
    return 'UNIPLAN-$base64Str';
  }

  /// Giải mã mã chia sẻ cấu hình
  static Map<String, dynamic>? decodeShareCode(String code) {
    try {
      var raw = code.trim();
      if (raw.startsWith('UNIPLAN-')) {
        raw = raw.substring('UNIPLAN-'.length);
      }
      final bytes = base64.decode(raw);
      final jsonStr = utf8.decode(bytes);
      final data = jsonDecode(jsonStr);
      if (data is Map<String, dynamic> && data['sectionIds'] != null) {
        return data;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Tạo bản in / tóm tắt thời khóa biểu dạng văn bản để gửi tin nhắn / in ấn
  static String generateTextSummary({
    required RegistrationPlan plan,
    required List<Course> allCourses,
    required String studentName,
    required String studentId,
  }) {
    final courseMap = {for (var c in allCourses) c.code: c};
    final sb = StringBuffer();
    sb.writeln('====================================================');
    sb.writeln('  KẾ HOẠCH ĐĂNG KÝ TÍN CHỈ - UNIPLAN AI');
    sb.writeln('====================================================');
    sb.writeln('Sinh viên: $studentName (MSSV: $studentId)');
    sb.writeln('Phương án: ${plan.name}');
    sb.writeln('Ngày tạo: ${plan.updatedAt.day}/${plan.updatedAt.month}/${plan.updatedAt.year}');
    sb.writeln('----------------------------------------------------');
    sb.writeln('DANH SÁCH HỌC PHẦN ĐĂNG KÝ:');

    int totalCredits = 0;
    int idx = 1;

    for (final sec in plan.selectedSections.values) {
      final course = courseMap[sec.courseCode];
      final credits = course?.credits ?? 0;
      totalCredits += credits;

      sb.writeln('$idx. [${sec.courseCode}] ${sec.courseName}');
      sb.writeln('   - Lớp HP: ${sec.id} | Giảng viên: ${sec.lecturer}');
      sb.writeln('   - Số tín chỉ: $credits TC (LT: ${course?.theoryCredits ?? 0}, TH: ${course?.practiceCredits ?? 0})');
      for (final slot in sec.slots) {
        sb.writeln('   - Lịch học: ${slot.dayName}, Tiết ${slot.startPeriod}-${slot.endPeriod} (${slot.timeFormatted}) tại ${slot.room} (${sec.campus})');
      }
      sb.writeln();
      idx++;
    }

    sb.writeln('----------------------------------------------------');
    sb.writeln('TỔNG SỐ TÍN CHỈ: $totalCredits TC (${plan.selectedSections.length} học phần)');
    sb.writeln('====================================================');
    sb.writeln('UniPlan AI - Hệ thống lập kế hoạch đăng ký tín chỉ thông minh');

    return sb.toString();
  }
}

