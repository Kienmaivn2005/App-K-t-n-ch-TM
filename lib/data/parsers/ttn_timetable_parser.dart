import '../../domain/models/timetable_models.dart';

/// ============================================================================
/// TTN TIMETABLE PARSER
/// Feature-First Clean Architecture: lib/data/parsers/ttn_timetable_parser.dart
/// Bóc tách chuỗi copy từ daotao.ttn.edu.vn hoặc bảng Excel phòng đào tạo
/// ============================================================================
class TtnTimetableParser {
  /// Regex nhận diện cấu trúc lịch học chuẩn TTN:
  /// Hỗ trợ: "Thứ 3, Tiết 1-3 (G2-P201)", "T2: 6-8, Lab 4.1", "Thứ Hai: Tiết 1-3"
  static final RegExp _slotRegex = RegExp(
    r'(?:Thứ\s*([2-7]|Hai|Ba|Tư|Năm|Sáu|Bảy)|CN|Chủ\s*Nhật|T([2-7]))'
    r'[\s,:\-]+'
    r'(?:Tiết\s*)?(\d{1,2})\s*[\-–_]\s*(\d{1,2})'
    r'(?:[\s,:\-\(]*(?:Nhà|Phòng|P\.?)?\s*([^\n\r,\;\)]+)\)?)?',
    caseSensitive: false,
  );

  /// Parse một chuỗi buổi học đơn lẻ
  static TimeSlot? parseSingleSlot(String rawText, {String defaultLecturer = 'Chưa phân công'}) {
    final clean = rawText.trim();
    if (clean.isEmpty) return null;

    final match = _slotRegex.firstMatch(clean);
    if (match != null) {
      final rawDay = match.group(1) ?? match.group(2) ?? '';
      final startPeriod = int.tryParse(match.group(3) ?? '1') ?? 1;
      final endPeriod = int.tryParse(match.group(4) ?? '1') ?? 1;
      final room = match.group(5)?.trim() ?? 'Chưa xếp phòng';

      final dayOfWeek = _normalizeDayOfWeek(rawDay, clean);
      final periodCount = (endPeriod - startPeriod + 1).clamp(1, 6);

      return TimeSlot(
        dayOfWeek: dayOfWeek,
        startPeriod: startPeriod.clamp(1, 12),
        periodCount: periodCount,
        room: room.isEmpty ? 'Chưa xếp phòng' : room,
        lecturer: defaultLecturer,
      );
    }

    return _fallbackParseSlot(clean, defaultLecturer);
  }

  /// Parse chuỗi chứa nhiều buổi học cách nhau bởi dấu chấm phẩy (;), gạch đứng (|), hoặc xuống dòng
  static List<TimeSlot> parseMultipleSlots(String text, {String defaultLecturer = 'Chưa phân công'}) {
    if (text.trim().isEmpty) return [];

    final slots = <TimeSlot>[];
    final parts = text.split(RegExp(r'[\n\r;|\+]'));
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final slot = parseSingleSlot(trimmed, defaultLecturer: defaultLecturer);
      if (slot != null) {
        slots.add(slot);
      }
    }
    return slots;
  }

  /// Parse bảng copy clipboard từ portal hoặc Excel
  /// Format dòng: Mã Lớp | Tên Môn | Phân Loại (LT/TH) | Lịch Học | Giảng Viên | Sĩ Số
  static List<ClassSection> parseClipboardTable(String tableText) {
    final lines = tableText.split(RegExp(r'[\r\n]+'));
    final results = <ClassSection>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.toLowerCase().contains('mã lớp') || line.startsWith('#')) {
        continue;
      }

      final List<String> cols;
      if (line.contains('\t')) {
        cols = line.split('\t').map((e) => e.trim()).toList();
      } else if (line.contains('|')) {
        cols = line.split('|').map((e) => e.trim()).toList();
      } else {
        cols = line.split(',').map((e) => e.trim()).toList();
      }

      if (cols.length < 3) continue;

      try {
        final classId = cols[0];
        final courseName = cols.length > 1 ? cols[1] : 'Học phần';
        final typeStr = cols.length > 2 ? cols[2].toLowerCase() : '';
        final scheduleStr = cols.length > 3 ? cols[3] : '';
        final lecturer = cols.length > 4 ? cols[4] : 'Chưa phân công';
        final capacity = cols.length > 5 ? (int.tryParse(cols[5]) ?? 50) : 50;

        final isPractice = typeStr.contains('th') || typeStr.contains('thực hành');
        final courseCode = classId.split('_').first;
        final slots = parseMultipleSlots(scheduleStr, defaultLecturer: lecturer);

        results.add(ClassSection(
          classId: classId,
          sectionName: isPractice ? 'Tổ TH - $classId' : 'Lớp LT - $classId',
          courseCode: courseCode,
          courseName: courseName,
          sectionType: isPractice ? SectionType.practice : SectionType.theory,
          timeSlots: slots,
          capacity: capacity,
          enrolledCount: (capacity * 0.7).toInt(),
          colorHex: _generateColor(courseCode),
        ));
      } catch (_) {}
    }

    return results;
  }

  static int _normalizeDayOfWeek(String rawDay, String fullText) {
    final d = rawDay.trim().toLowerCase();
    if (d == '2' || d == 'hai') return 2;
    if (d == '3' || d == 'ba') return 3;
    if (d == '4' || d == 'tư' || d == 'tu') return 4;
    if (d == '5' || d == 'năm' || d == 'nam') return 5;
    if (d == '6' || d == 'sáu' || d == 'sau') return 6;
    if (d == '7' || d == 'bảy' || d == 'bay') return 7;
    if (d == '8' || d.contains('chủ') || d.contains('cn') || fullText.toLowerCase().contains('chủ nhật')) return 8;
    return 2;
  }

  static TimeSlot? _fallbackParseSlot(String text, String lecturer) {
    final digits = RegExp(r'(\d+)\s*[-–]\s*(\d+)').firstMatch(text);
    if (digits == null) return null;

    final start = int.tryParse(digits.group(1) ?? '1') ?? 1;
    final end = int.tryParse(digits.group(2) ?? '1') ?? 1;

    int day = 2;
    for (int i = 2; i <= 7; i++) {
      if (text.contains('$i')) {
        day = i;
        break;
      }
    }

    return TimeSlot(
      dayOfWeek: day,
      startPeriod: start.clamp(1, 12),
      periodCount: (end - start + 1).clamp(1, 6),
      room: text.replaceAll(RegExp(r'[\d\-\–]'), '').trim(),
      lecturer: lecturer,
    );
  }

  static int _generateColor(String code) {
    const palette = [
      0xFF1E88E5, 0xFF0D9488, 0xFF8B5CF6, 0xFFEA580C,
      0xFF059669, 0xFFD97706, 0xFFE11D48, 0xFF4F46E5,
    ];
    return palette[code.hashCode.abs() % palette.length];
  }
}
