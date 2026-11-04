import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../domain/models/school_week_schedule.dart';
import 'academic_date_engine.dart';
import 'ttn_database.dart';

/// Kết quả tra cứu thời khóa biểu trực tuyến từ Cổng TTN
class TTNPortalFetchResult {
  final bool success;
  final String msv;
  final String fullName;
  final String? errorMessage;
  final int totalLessons;
  final List<Map<String, dynamic>> slots;
  final Map<int, SchoolWeekSchedule> weekSchedules;

  const TTNPortalFetchResult({
    required this.success,
    required this.msv,
    required this.fullName,
    this.errorMessage,
    this.totalLessons = 0,
    this.slots = const [],
    this.weekSchedules = const {},
  });

  factory TTNPortalFetchResult.failed(String msv, String error) {
    return TTNPortalFetchResult(
      success: false,
      msv: msv,
      fullName: '',
      errorMessage: error,
    );
  }
}

/// ============================================================================
/// TTN PORTAL SERVICE
/// Tự động lấy dữ liệu thời khóa biểu chính xác từ web:
/// https://www.ttn.edu.vn/index.php/component/tnu/?view=sinhvien
/// (Endpoint: https://www.ttn.edu.vn/libraries/tnu/tkbieusinhvien.php)
/// ============================================================================
class TTNPortalService {
  static const String portalUrl = 'https://www.ttn.edu.vn/libraries/tnu/tkbieusinhvien.php';

  /// Cache dữ liệu thời khóa biểu đã tải về theo mã sinh viên
  static final Map<String, TTNPortalFetchResult> _cachedResults = {};

  /// Kiểm tra xem MSSV đã có trong cache chưa
  static bool hasCached(String msv) => _cachedResults.containsKey(msv.trim());

  /// Lấy kết quả từ cache nếu có
  static TTNPortalFetchResult? getCached(String msv) => _cachedResults[msv.trim()];

  /// Tra cứu thời khóa biểu của một sinh viên bất kỳ từ web trường TTN
  static Future<TTNPortalFetchResult> fetchStudentTimetable(String msv) async {
    final cleanMsv = msv.trim();
    if (cleanMsv.isEmpty) {
      return TTNPortalFetchResult.failed(cleanMsv, 'Mã số sinh viên không được để trống');
    }

    String? htmlResponse;
    String? lastError;

    // 1. Thử gọi qua Proxy nội bộ nếu đang chạy trên Flutter Web (tránh lỗi CORS trình duyệt)
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        final proxyUri = Uri.parse('$origin/api/ttn?msv=$cleanMsv');
        final res = await http.get(proxyUri).timeout(const Duration(seconds: 12));
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          htmlResponse = utf8.decode(res.bodyBytes, allowMalformed: true);
        }
      } catch (e) {
        lastError = e.toString();
      }
    }

    // 2. Thử gọi trực tiếp đến cổng đào tạo TTN (Hoạt động tốt trên Native Android, iOS, Windows, macOS)
    if (htmlResponse == null || htmlResponse.isEmpty) {
      try {
        final uri = Uri.parse(portalUrl);
        final response = await http.post(
          uri,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'Referer': 'https://www.ttn.edu.vn/index.php/component/tnu/?view=sinhvien',
            'X-Requested-With': 'XMLHttpRequest',
          },
          body: {
            'msv': cleanMsv,
            'dk': '10',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          htmlResponse = utf8.decode(response.bodyBytes, allowMalformed: true);
        } else {
          lastError = 'Cổng trường trả về mã lỗi HTTP: ${response.statusCode}';
        }
      } catch (e) {
        lastError = 'Không thể kết nối đến web trường ttn.edu.vn ($e)';
      }
    }

    // 3. Nếu lấy được HTML từ web trường, tiến hành phân giải DOM
    if (htmlResponse != null && htmlResponse.isNotEmpty) {
      try {
        final parsed = parsePortalHtml(cleanMsv, htmlResponse);
        if (parsed.success) {
          _cachedResults[cleanMsv] = parsed;
          // Đồng bộ tự động vào cơ sở dữ liệu TTNDatabase
          TTNDatabase.registerOrUpdateStudentFromWeb(
            msv: cleanMsv,
            fullName: parsed.fullName,
            slots: parsed.slots,
            weekSchedules: parsed.weekSchedules,
          );
          return parsed;
        } else {
          lastError = parsed.errorMessage ?? 'Không tìm thấy dữ liệu sinh viên trên web';
        }
      } catch (e) {
        lastError = 'Lỗi phân giải HTML thời khóa biểu: $e';
      }
    }

    // 4. Nếu mất mạng hoặc web trường lỗi, thử tra cứu trong cơ sở dữ liệu nội bộ sẵn có
    final existingStudent = TTNDatabase.getStudent(cleanMsv);
    if (existingStudent != null) {
      final name = existingStudent['fullName'] as String? ?? 'Sinh viên $cleanMsv';
      final slots = (existingStudent['slots'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      final result = TTNPortalFetchResult(
        success: true,
        msv: cleanMsv,
        fullName: name,
        slots: slots,
        totalLessons: slots.length,
      );
      _cachedResults[cleanMsv] = result;
      return result;
    }

    return TTNPortalFetchResult.failed(
      cleanMsv,
      lastError ?? 'Không tìm thấy sinh viên có mã "$cleanMsv" trên web ttn.edu.vn',
    );
  }

  /// Phân giải HTML trả về từ `https://www.ttn.edu.vn/libraries/tnu/tkbieusinhvien.php`
  static TTNPortalFetchResult parsePortalHtml(String msv, String html) {
    if (html.trim().isEmpty) {
      return TTNPortalFetchResult.failed(msv, 'Dữ liệu web trả về rỗng');
    }

    // 1. Trích xuất họ tên sinh viên
    // Cú pháp web trường: Mã SV: <b>24103035</b> - Họ tên: <b>Trần Thị Thu Hiền</b><br/>
    final nameRegex = RegExp(r'Họ\s*tên:\s*<b>(.*?)</b>', caseSensitive: false);
    final nameMatch = nameRegex.firstMatch(html);
    String fullName = nameMatch?.group(1)?.trim() ?? '';

    // Nếu không tìm thấy tên và không có bảng nào thì mã sinh viên không hợp lệ
    if (fullName.isEmpty && !html.contains('<table>')) {
      return TTNPortalFetchResult.failed(msv, 'Mã sinh viên $msv không tồn tại trên web trường');
    }

    if (fullName.isEmpty) {
      fullName = 'Sinh viên $msv';
    }

    // 2. Trích xuất từng khối tuần
    // Cú pháp web trường: <p>Từ ngày 02/11/2026 đến ngày 08/11/2026</p><table>...</table>
    final weekBlockRegex = RegExp(
      r'<p>\s*Từ\s*ngày\s*(\d{1,2}/\d{1,2}/\d{4})\s*đến\s*ngày\s*(\d{1,2}/\d{1,2}/\d{4})\s*</p>\s*<table>([\s\S]*?)</table>',
      caseSensitive: false,
    );

    final matches = weekBlockRegex.allMatches(html);
    final Map<int, SchoolWeekSchedule> weekSchedules = {};
    final List<Map<String, dynamic>> rawCollectedSlots = [];

    final colors = [
      const Color(0xFFF3E8FF), // Tím
      const Color(0xFFFFEDD5), // Cam
      const Color(0xFFE0F2FE), // Xanh lam
      const Color(0xFFE0F7FA), // Cyan
      const Color(0xFFFFE4E6), // Hồng
      const Color(0xFFDCFCE7), // Xanh lá
      const Color(0xFFEDE9FE), // Indigo
      const Color(0xFFFEF3C7), // Vàng hổ phách
    ];

    for (final match in matches) {
      final startStr = match.group(1)!;
      final endStr = match.group(2)!;
      final tableContent = match.group(3)!;

      final startDate = _parseDate(startStr);
      final endDate = _parseDate(endStr);

      // Tính số tuần học
      final weekNumber = AcademicDateEngine.defaultInstance.getCurrentWeek(startDate);

      // Phân giải các dòng trong bảng: Header (Thứ 2..CN), Sáng, Chiều, Tối
      final rowRegex = RegExp(r'<tr>([\s\S]*?)</tr>', caseSensitive: false);
      final rowMatches = rowRegex.allMatches(tableContent).toList();

      final Map<String, Map<int, List<ScheduleLessonItem>>> grid = {
        'Sáng': {for (int d = 2; d <= 8; d++) d: []},
        'Chiều': {for (int d = 2; d <= 8; d++) d: []},
        'Tối': {for (int d = 2; d <= 8; d++) d: []},
      };

      for (final rMatch in rowMatches) {
        final rowHtml = rMatch.group(1)!;
        final tdRegex = RegExp(r'<td>([\s\S]*?)</td>', caseSensitive: false);
        final tdMatches = tdRegex.allMatches(rowHtml).toList();

        if (tdMatches.isEmpty) continue;

        // Cột 0: Tên buổi ('Sáng', 'Chiều', 'Tối')
        final sessionRaw = tdMatches[0].group(1)!.trim();
        String session = 'Sáng';
        if (sessionRaw.contains('Chiều')) {
          session = 'Chiều';
        } else if (sessionRaw.contains('Tối')) {
          session = 'Tối';
        }

        // Cột 1 đến 7: Thứ 2 (2) đến Chủ Nhật (8)
        for (int i = 1; i < tdMatches.length && i <= 7; i++) {
          final dayOfWeek = i + 1; // 1 -> T2 (2), 2 -> T3 (3), ..., 7 -> CN (8)
          final cellHtml = tdMatches[i].group(1)!.trim();
          if (cellHtml.isEmpty) continue;

          // Trong một ô có thể có một hoặc nhiều học phần, bắt đầu bằng "HP:"
          final hpSections = cellHtml.split(RegExp(r'(?=HP:)'));

          for (final section in hpSections) {
            final trimmedSection = section.trim();
            if (!trimmedSection.startsWith('HP:')) continue;

            // 1. Tên học phần & tiết học
            // Mẫu: HP: Khởi nghiệp (1-4)<br/>
            // Hoặc: HP: TH(1):CS VL cho TH (1-4)<br/>
            String courseName = '';
            String period = session == 'Sáng' ? '1-4' : (session == 'Chiều' ? '7-10' : '11-12');

            final hpMatch = RegExp(r'HP:\s*([\s\S]*?)(?:<br|$)').firstMatch(trimmedSection);
            if (hpMatch != null) {
              final rawHpText = hpMatch.group(1)!.trim();
              // Tìm nhóm tiết (X-Y) ở cuối tên môn
              final periodMatch = RegExp(r'\(([\d]{1,2}\s*[\-–]\s*[\d]{1,2})\)$').firstMatch(rawHpText);
              if (periodMatch != null) {
                period = periodMatch.group(1)!.replaceAll('–', '-').trim();
                courseName = rawHpText.substring(0, periodMatch.start).trim();
              } else {
                courseName = rawHpText;
              }
            }

            if (courseName.isEmpty) courseName = 'Môn học';

            // 2. Giảng viên
            String? lecturer;
            final gvMatch = RegExp(r'GV:\s*([^<]+)').firstMatch(trimmedSection);
            if (gvMatch != null) {
              lecturer = gvMatch.group(1)!.trim();
            }

            // 3. Phòng học
            String room = '';
            final roomMatch = RegExp(r'Phòng:\s*([^<]+)').firstMatch(trimmedSection);
            if (roomMatch != null) {
              room = roomMatch.group(1)!.trim();
            }

            final color = colors[courseName.hashCode.abs() % colors.length];

            final lesson = ScheduleLessonItem(
              courseName: courseName,
              room: room,
              lecturer: lecturer,
              periodString: period,
              badgeColor: color,
              rawTitle: courseName,
            );

            grid[session]![dayOfWeek]!.add(lesson);

            // Lưu lại slot tổng quát
            rawCollectedSlots.add({
              'weekNumber': weekNumber,
              'dayIndex': dayOfWeek,
              'courseName': courseName,
              'rawTitle': courseName,
              'period': period,
              'room': room,
              'lecturer': lecturer ?? '',
              'session': session,
              'color': color.toARGB32(),
            });
          }
        }
      }

      final weekSchedule = SchoolWeekSchedule(
        weekNumber: weekNumber,
        startDate: startDate,
        endDate: endDate,
        grid: grid,
      );

      weekSchedules[weekNumber] = weekSchedule;
    }

    // 3. Gom nhóm các slot theo môn học để tạo danh sách activeWeeks chuẩn
    final Map<String, Map<String, dynamic>> consolidatedSlots = {};
    for (final raw in rawCollectedSlots) {
      final key = '${raw['courseName']}_${raw['dayIndex']}_${raw['period']}_${raw['room']}';
      final weekNum = raw['weekNumber'] as int;
      if (!consolidatedSlots.containsKey(key)) {
        consolidatedSlots[key] = {
          'dayIndex': raw['dayIndex'],
          'courseName': raw['courseName'],
          'rawTitle': raw['rawTitle'],
          'period': raw['period'],
          'room': raw['room'],
          'lecturer': raw['lecturer'],
          'session': raw['session'],
          'color': raw['color'],
          'activeWeeks': <int>[weekNum],
        };
      } else {
        final existingWeeks = consolidatedSlots[key]!['activeWeeks'] as List<int>;
        if (!existingWeeks.contains(weekNum)) {
          existingWeeks.add(weekNum);
          existingWeeks.sort();
        }
      }
    }

    final slotsList = consolidatedSlots.values.toList();

    return TTNPortalFetchResult(
      success: true,
      msv: msv,
      fullName: fullName,
      totalLessons: rawCollectedSlots.length,
      slots: slotsList,
      weekSchedules: weekSchedules,
    );
  }

  static DateTime _parseDate(String ddMMyyyy) {
    try {
      final parts = ddMMyyyy.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (_) {
      return DateTime.now();
    }
  }
}
