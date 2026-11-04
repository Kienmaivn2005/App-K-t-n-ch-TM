import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/planner_provider.dart';
import '../../services/storage_service.dart';
import '../../services/ttn_database.dart';
import '../theme/app_theme.dart';

/// Mô hình một buổi thi kết thúc học phần chuẩn Trường Đại học Tây Nguyên (TTN)
class ExamScheduleItem {
  final String courseCode;
  final String courseName;
  final int credits;
  final String examDate; // dd/MM/yyyy
  final String dayOfWeek; // Thứ 2 ... Thứ 7, CN
  final String examTime; // ví dụ: "07:30 - 09:00"
  final String session; // Ca 1 (Sáng), Ca 2 (Sáng), Ca 3 (Chiều)...
  final String duration; // 90 phút, 60 phút, 180 phút...
  final String room; // Phòng thi chính xác (ví dụ: "Phòng 6.11", "Phòng 2.4", "Lab 7.3.18")
  final String building; // Nhà 6, Nhà 2, Nhà 7 (Khoa CNTT)
  final String examFormat; // Hình thức thi: Tự luận, Trắc nghiệm máy, Vấn đáp & Demo, Tiểu luận...
  final String sbd; // Số báo danh (trùng khớp với MSSV)
  final String examiner; // Giảng viên / Giám thị coi thi
  final String note; // Quy chế thi & tài liệu được mang
  final bool isMyCourse; // Môn học thuộc thời khóa biểu của sinh viên hiện tại

  const ExamScheduleItem({
    required this.courseCode,
    required this.courseName,
    required this.credits,
    required this.examDate,
    required this.dayOfWeek,
    required this.examTime,
    required this.session,
    required this.duration,
    required this.room,
    required this.building,
    required this.examFormat,
    required this.sbd,
    required this.examiner,
    required this.note,
    this.isMyCourse = true,
  });

  Map<String, dynamic> toJson() => {
    'courseCode': courseCode,
    'courseName': courseName,
    'credits': credits,
    'examDate': examDate,
    'dayOfWeek': dayOfWeek,
    'examTime': examTime,
    'session': session,
    'duration': duration,
    'room': room,
    'building': building,
    'examFormat': examFormat,
    'sbd': sbd,
    'examiner': examiner,
    'note': note,
    'isMyCourse': isMyCourse,
  };

  factory ExamScheduleItem.fromJson(Map<String, dynamic> json) => ExamScheduleItem(
    courseCode: json['courseCode'] ?? '',
    courseName: json['courseName'] ?? '',
    credits: json['credits'] ?? 3,
    examDate: json['examDate'] ?? '',
    dayOfWeek: json['dayOfWeek'] ?? '',
    examTime: json['examTime'] ?? '',
    session: json['session'] ?? '',
    duration: json['duration'] ?? '',
    room: json['room'] ?? '',
    building: json['building'] ?? '',
    examFormat: json['examFormat'] ?? '',
    sbd: json['sbd'] ?? '',
    examiner: json['examiner'] ?? '',
    note: json['note'] ?? '',
    isMyCourse: json['isMyCourse'] ?? true,
  );

  DateTime get parsedDate {
    try {
      final parts = examDate.split('/');
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) {
      return DateTime.now();
    }
  }

  int get daysUntilExam {
    final now = DateTime.now();
    final exam = parsedDate;
    final diff = exam.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff;
  }
}

class ExamScheduleScreen extends StatefulWidget {
  const ExamScheduleScreen({super.key});

  @override
  State<ExamScheduleScreen> createState() => _ExamScheduleScreenState();
}

class _ExamScheduleScreenState extends State<ExamScheduleScreen> {
  String _searchFilter = '';
  String _selectedFormat = 'Tất cả';
  bool _onlyMyExams = true; // Mặc định chỉ hiển thị đúng các môn thi của sinh viên hiện tại

  // Danh sách môn thi có thể chỉnh sửa, thêm mới, xóa trực tiếp
  List<ExamScheduleItem>? _customExams;

  @override
  void initState() {
    super.initState();
    _loadSavedExams();
  }

  Future<void> _loadSavedExams() async {
    try {
      final savedJson = await StorageService.loadCustomExamsJson();
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(savedJson);
        if (mounted) {
          setState(() {
            _customExams = list.map((e) => ExamScheduleItem.fromJson(e as Map<String, dynamic>)).toList();
          });
          return;
        }
      }
    } catch (_) {}
  }

  Future<void> _persistExams() async {
    if (_customExams != null) {
      final jsonList = _customExams!.map((e) => e.toJson()).toList();
      await StorageService.saveCustomExamsJson(jsonEncode(jsonList));
    }
  }

  List<ExamScheduleItem> _getExams(String studentId) {
    if (_customExams != null) {
      return _customExams!;
    }
    _customExams = List.from(_getOfficialExams(studentId));
    return _customExams!;
  }

  void _addNewExam(ExamScheduleItem newExam) {
    setState(() {
      _customExams ??= List.from(_getOfficialExams('23103035'));
      _customExams!.insert(0, newExam);
    });
    _persistExams();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm môn thi: ${newExam.courseName} (Phòng: ${newExam.room})'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  void _updateExam(int index, ExamScheduleItem updated) {
    setState(() {
      if (_customExams != null && index >= 0 && index < _customExams!.length) {
        _customExams![index] = updated;
      }
    });
    _persistExams();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã cập nhật giờ & phòng thi: ${updated.courseName}'),
        backgroundColor: const Color(0xFF0284C7),
      ),
    );
  }

  void _deleteExam(int index, String courseName) {
    setState(() {
      if (_customExams != null && index >= 0 && index < _customExams!.length) {
        _customExams!.removeAt(index);
      }
    });
    _persistExams();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa môn thi: $courseName'),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  void _showAddEditExamDialog({ExamScheduleItem? existingItem, int? targetIndex}) {
    final isEditing = existingItem != null;
    final formKey = GlobalKey<FormState>();

    final courseCodeCtrl = TextEditingController(text: existingItem?.courseCode ?? 'KC21');
    final courseNameCtrl = TextEditingController(text: existingItem?.courseName ?? '');
    final creditsCtrl = TextEditingController(text: (existingItem?.credits ?? 3).toString());
    final examDateCtrl = TextEditingController(text: existingItem?.examDate ?? '25/01/2027');
    final dayOfWeekCtrl = TextEditingController(text: existingItem?.dayOfWeek ?? 'Thứ 2');
    final examTimeCtrl = TextEditingController(text: existingItem?.examTime ?? '07:30 - 09:30');
    final sessionCtrl = TextEditingController(text: existingItem?.session ?? 'Ca 1 (Sáng)');
    final durationCtrl = TextEditingController(text: existingItem?.duration ?? '90 phút');
    final roomCtrl = TextEditingController(text: existingItem?.room ?? 'Phòng 6.11');
    final buildingCtrl = TextEditingController(text: existingItem?.building ?? 'Nhà 6 (Tầng 1)');
    final formatCtrl = TextEditingController(text: existingItem?.examFormat ?? 'Tự luận');
    final examinerCtrl = TextEditingController(text: existingItem?.examiner ?? 'ThS. Giảng viên TTN');
    final noteCtrl = TextEditingController(text: existingItem?.note ?? 'Không sử dụng tài liệu. Thí sinh mang CCCD/Thẻ SV.');
    bool isMyCourseVal = existingItem?.isMyCourse ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  isEditing ? Icons.edit_calendar_rounded : Icons.add_circle_outline_rounded,
                  color: const Color(0xFF1E3A8A),
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'Sửa Phòng Thi & Giờ Thi' : 'Thêm Môn Thi Mới',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tên môn & Mã môn
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              controller: courseNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Tên môn học *',
                                prefixIcon: Icon(Icons.book_outlined, size: 18),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên môn' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: courseCodeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Mã học phần *',
                                prefixIcon: Icon(Icons.tag_rounded, size: 18),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Nhập mã môn' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Giờ thi & Phòng thi (TRỌNG TÂM)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.tune_rounded, size: 16, color: Color(0xFF16A34A)),
                                SizedBox(width: 6),
                                Text(
                                  'Cấu hình Giờ thi & Phòng thi (Nổi bật)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF166534)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: examTimeCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Giờ thi (Ví dụ: 07:30 - 09:30) *',
                                      prefixIcon: Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF0284C7)),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Nhập giờ thi' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: durationCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Thời lượng (90 phút) *',
                                      prefixIcon: Icon(Icons.timelapse_rounded, size: 18),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: roomCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Phòng thi chính xác (Ví dụ: Phòng 6.11) *',
                                      prefixIcon: Icon(Icons.meeting_room_rounded, size: 18, color: Color(0xFFD97706)),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Nhập phòng thi' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: buildingCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Tòa nhà / Khu vực *',
                                      prefixIcon: Icon(Icons.location_city_rounded, size: 18),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tòa nhà' : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Ngày thi & Ca thi
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: examDateCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Ngày thi (dd/MM/yyyy) *',
                                prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Nhập ngày thi' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: dayOfWeekCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Thứ (Thứ 2... Thứ 7, CN) *',
                                prefixIcon: Icon(Icons.date_range_rounded, size: 18),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: sessionCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Ca thi (Ca 1 / Sáng) *',
                                prefixIcon: Icon(Icons.wb_sunny_outlined, size: 18),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Giám thị, Hình thức, Số tín chỉ
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: examinerCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Cán bộ chấm / coi thi',
                                prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: ['Tự luận', 'Trắc nghiệm máy tính', 'Vấn đáp & Demo sản phẩm', 'Tiểu luận & Thuyết trình', 'Thực hành máy tính']
                                      .contains(formatCtrl.text)
                                  ? formatCtrl.text
                                  : 'Tự luận',
                              decoration: const InputDecoration(
                                labelText: 'Hình thức thi',
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Tự luận', child: Text('Tự luận')),
                                DropdownMenuItem(value: 'Trắc nghiệm máy tính', child: Text('Trắc nghiệm máy tính')),
                                DropdownMenuItem(value: 'Vấn đáp & Demo sản phẩm', child: Text('Vấn đáp & Demo')),
                                DropdownMenuItem(value: 'Tiểu luận & Thuyết trình', child: Text('Tiểu luận & Báo cáo')),
                                DropdownMenuItem(value: 'Thực hành máy tính', child: Text('Thực hành máy')),
                              ],
                              onChanged: (v) {
                                if (v != null) formatCtrl.text = v;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: creditsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Số TC',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Ghi chú quy chế thi
                      TextFormField(
                        controller: noteCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú tài liệu & quy chế phòng thi',
                          prefixIcon: Icon(Icons.note_alt_outlined, size: 18),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Checkbox thuộc lịch thi cá nhân
                      CheckboxListTile(
                        value: isMyCourseVal,
                        onChanged: (v) => setDialogState(() => isMyCourseVal = v ?? true),
                        title: const Text('Thuộc môn thi của tôi (Thời khóa biểu kỳ này)', style: TextStyle(fontSize: 12.5)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy bỏ'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;

                  final item = ExamScheduleItem(
                    courseCode: courseCodeCtrl.text.trim(),
                    courseName: courseNameCtrl.text.trim(),
                    credits: int.tryParse(creditsCtrl.text.trim()) ?? 3,
                    examDate: examDateCtrl.text.trim(),
                    dayOfWeek: dayOfWeekCtrl.text.trim(),
                    examTime: examTimeCtrl.text.trim(),
                    session: sessionCtrl.text.trim(),
                    duration: durationCtrl.text.trim(),
                    room: roomCtrl.text.trim(),
                    building: buildingCtrl.text.trim(),
                    examFormat: formatCtrl.text.trim(),
                    sbd: existingItem?.sbd ?? '23103035',
                    examiner: examinerCtrl.text.trim(),
                    note: noteCtrl.text.trim(),
                    isMyCourse: isMyCourseVal,
                  );

                  Navigator.pop(ctx);

                  if (isEditing && targetIndex != null) {
                    _updateExam(targetIndex, item);
                  } else {
                    _addNewExam(item);
                  }
                },
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(isEditing ? 'Lưu Thay Đổi' : 'Thêm Môn Thi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteExam(int index, ExamScheduleItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa Môn Thi Này?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa môn thi "${item.courseName}" (Phòng: ${item.room}, Giờ: ${item.examTime}) khỏi danh sách lịch thi?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteExam(index, item.courseName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }

  /// Danh sách môn thi chuẩn xác theo kỳ thi Kết thúc Học phần 1 Năm học 2026-2027
  /// Khoa Khoa học Tự nhiên và Công nghệ - Trường Đại học Tây Nguyên (TTN)
  static List<ExamScheduleItem> _getOfficialExams(String studentId) {
    final sbdCode = studentId.isNotEmpty ? studentId : '23103035';

    final baseList = [
      // 1. Lịch sử Đảng Cộng sản Việt Nam (Môn học thực tế của Mai Đàm Thế Kiên)
      ExamScheduleItem(
        courseCode: 'ML211033',
        courseName: 'Lịch sử Đảng Cộng sản Việt Nam',
        credits: 2,
        examDate: '18/01/2027',
        dayOfWeek: 'Thứ 2',
        examTime: '07:30 - 09:00',
        session: 'Ca 1 (Sáng)',
        duration: '90 phút',
        room: 'Phòng 6.11',
        building: 'Nhà 6 (Tầng 1)',
        examFormat: 'Tự luận',
        sbd: sbdCode,
        examiner: 'ThS. Đoàn Văn Kỳ',
        note: 'Được sử dụng Giáo trình in chính thống của NXB Chính trị quốc gia Sự thật. Không dùng điện thoại.',
        isMyCourse: true,
      ),

      // 2. Tâm lý học đại cương (Môn học thực tế của Mai Đàm Thế Kiên)
      ExamScheduleItem(
        courseCode: 'SP211014',
        courseName: 'Tâm lý học đại cương',
        credits: 2,
        examDate: '20/01/2027',
        dayOfWeek: 'Thứ 4',
        examTime: '07:30 - 08:30',
        session: 'Ca 1 (Sáng)',
        duration: '60 phút',
        room: 'Phòng 2.4',
        building: 'Nhà 2 (Tầng 1)',
        examFormat: 'Trắc nghiệm máy tính',
        sbd: sbdCode,
        examiner: 'TS. Lê Tô Đỗ Quyên',
        note: 'Thi trắc nghiệm tập trung trên hệ thống máy tính. Thí sinh có mặt trước 15 phút nhận máy.',
        isMyCourse: true,
      ),

      // 3. Lập trình di động (Môn học thực tế của Mai Đàm Thế Kiên)
      ExamScheduleItem(
        courseCode: 'KC215046',
        courseName: 'Lập trình di động (Flutter / Android)',
        credits: 3,
        examDate: '23/01/2027',
        dayOfWeek: 'Thứ 7',
        examTime: '13:30 - 16:30',
        session: 'Ca 3 (Chiều)',
        duration: '180 phút',
        room: 'Lab 7.3.18',
        building: 'Nhà 7 (Tầng 3 - Khoa CNTT)',
        examFormat: 'Vấn đáp & Demo sản phẩm',
        sbd: sbdCode,
        examiner: 'ThS. Trương Thị Hương Giang',
        note: 'Mang Laptop / Smartphone đã cài đặt APK demo. Đẩy toàn bộ source code lên GitHub trước 12:00.',
        isMyCourse: true,
      ),

      // 4. Những Vấn đề Hiện đại của CNTT (Môn học thực tế của Mai Đàm Thế Kiên)
      ExamScheduleItem(
        courseCode: 'KC213685',
        courseName: 'Những Vấn đề Hiện đại của CNTT',
        credits: 2,
        examDate: '26/01/2027',
        dayOfWeek: 'Thứ 3',
        examTime: '07:30 - 09:30',
        session: 'Ca 1 (Sáng)',
        duration: '120 phút',
        room: 'Phòng 7.3.18',
        building: 'Nhà 7 (Tầng 3 - Khoa CNTT)',
        examFormat: 'Tiểu luận & Thuyết trình',
        sbd: sbdCode,
        examiner: 'ThS. Trương Thị Hương Giang',
        note: 'Trình chiếu Slide báo cáo đề tài nhóm và nộp 01 bản in báo cáo chuyên đề đóng bìa mica.',
        isMyCourse: true,
      ),

      // --- Các môn khác thuộc K23 CNTT (Phục vụ tra cứu toàn khóa) ---
      ExamScheduleItem(
        courseCode: 'FL211012',
        courseName: 'Tiếng Anh 2',
        credits: 3,
        examDate: '29/01/2027',
        dayOfWeek: 'Thứ 6',
        examTime: '14:00 - 16:00',
        session: 'Ca 4 (Chiều)',
        duration: '120 phút',
        room: 'Online (MS Teams)',
        building: 'Trực tuyến - Phòng thi 03',
        examFormat: 'Trắc nghiệm & Nghe',
        sbd: sbdCode,
        examiner: 'ThS. Nguyễn Thị Mỹ Liên',
        note: 'Đăng nhập MS Teams trước 15 phút, bật webcam và xuất trình CCCD trước ống kính.',
        isMyCourse: false,
      ),

      ExamScheduleItem(
        courseCode: 'KC212604',
        courseName: 'Kỹ thuật lập trình',
        credits: 2,
        examDate: '02/02/2027',
        dayOfWeek: 'Thứ 3',
        examTime: '08:00 - 10:00',
        session: 'Ca 1 (Sáng)',
        duration: '120 phút',
        room: 'Lab Mạng 2',
        building: 'Nhà 7 (Tầng 3 - Khoa CNTT)',
        examFormat: 'Thực hành máy tính',
        sbd: sbdCode,
        examiner: 'ThS. Nguyễn Trọng Hải',
        note: 'Chấm bài thi tự động qua bộ Testcase chuẩn. Không truy cập Internet trong giờ thi.',
        isMyCourse: false,
      ),

      ExamScheduleItem(
        courseCode: 'KC213613',
        courseName: 'Đồ họa máy tính',
        credits: 2,
        examDate: '04/02/2027',
        dayOfWeek: 'Thứ 5',
        examTime: '09:30 - 11:30',
        session: 'Ca 2 (Sáng)',
        duration: '120 phút',
        room: 'Phòng 6.12',
        building: 'Nhà 6 (Tầng 1)',
        examFormat: 'Tự luận & Bài tập',
        sbd: sbdCode,
        examiner: 'ThS. Trần Đình Trọng',
        note: 'Được sử dụng tài liệu giấy in. Được mang máy tính bỏ túi nằm trong danh mục Bộ GD&ĐT.',
        isMyCourse: false,
      ),

      ExamScheduleItem(
        courseCode: 'KC213678',
        courseName: 'Kiến trúc máy tính',
        credits: 2,
        examDate: '06/02/2027',
        dayOfWeek: 'Thứ 7',
        examTime: '07:30 - 09:30',
        session: 'Ca 1 (Sáng)',
        duration: '120 phút',
        room: 'Phòng 8.1.7',
        building: 'Nhà 8 (Tầng 1)',
        examFormat: 'Trắc nghiệm & Tự luận',
        sbd: sbdCode,
        examiner: 'TS. Nguyễn Công Thảo',
        note: 'Không sử dụng tài liệu. Thí sinh chuẩn bị bút chì 2B và gôm để tô phiếu trả lời trắc nghiệm.',
        isMyCourse: false,
      ),
    ];

    // Tự động đồng bộ lịch thi từ cơ sở dữ liệu Hệ thống ĐH Tây Nguyên
    return baseList.map((item) {
      final info = TTNDatabase.getExamScheduleForCourse(item.courseCode, sbdCode);
      final ngay = info['ngay1'] as String? ?? '';
      final buoi = info['buoi1'] as String? ?? '';
      final phong = info['phong1'] as String? ?? '';
      if (ngay.isNotEmpty || phong.isNotEmpty) {
        return ExamScheduleItem(
          courseCode: item.courseCode,
          courseName: item.courseName,
          credits: item.credits,
          examDate: ngay.isNotEmpty ? ngay : item.examDate,
          dayOfWeek: item.dayOfWeek,
          examTime: item.examTime,
          session: buoi.isNotEmpty ? 'Ca 1 ($buoi)' : item.session,
          duration: item.duration,
          room: phong.isNotEmpty ? (phong.startsWith('P.') ? 'Phòng ${phong.substring(2)}' : phong) : item.room,
          building: item.building,
          examFormat: item.examFormat,
          sbd: sbdCode,
          examiner: item.examiner,
          note: item.note,
          isMyCourse: item.isMyCourse,
        );
      }
      return item;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final student = planner.profile;

    final allExams = _getExams(student.studentId);

    // Lọc theo chế độ xem (Môn thi của tôi vs Toàn khóa)
    final baseList = _onlyMyExams ? allExams.where((e) => e.isMyCourse).toList() : allExams;

    // Lọc theo từ khóa tìm kiếm và hình thức thi
    final filtered = baseList.where((e) {
      final matchSearch = e.courseName.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          e.courseCode.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          e.room.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          e.building.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          e.examiner.toLowerCase().contains(_searchFilter.toLowerCase());

      final matchFormat = _selectedFormat == 'Tất cả' || e.examFormat.contains(_selectedFormat);
      return matchSearch && matchFormat;
    }).toList();

    // Môn thi sắp tới nhất
    final nextExam = allExams.where((e) => e.isMyCourse).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditExamDialog(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Thêm Môn Thi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Thẻ thông tin sinh viên dự thi & Đếm ngược
          SliverToBoxAdapter(
            child: _buildExamHeader(student, allExams.where((e) => e.isMyCourse).length),
          ),

          // 2. Banner đếm ngược môn thi sắp tới
          if (nextExam != null)
            SliverToBoxAdapter(
              child: _buildNextExamBanner(nextExam),
            ),

          // 3. Tab chuyển đổi: "Môn thi của tôi" vs "Toàn bộ kỳ thi K23"
          SliverToBoxAdapter(
            child: _buildScopeSwitch(),
          ),

          // 4. Thanh lọc & tìm kiếm môn thi
          SliverToBoxAdapter(
            child: _buildSearchAndFilter(),
          ),

          // 5. Danh sách các môn thi dạng Thẻ thông minh
          filtered.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                          SizedBox(height: 12),
                          Text(
                            'Không tìm thấy môn thi phù hợp',
                            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hãy thử điều chỉnh từ khóa tìm kiếm hoặc chọn "Tất cả"',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, idx) => _buildExamCard(filtered[idx], idx),
                      childCount: filtered.length,
                    ),
                  ),
                ),

          // 6. Nút tiện ích mở Sơ đồ phòng thi TTN
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                onPressed: () => _showCampusMapModal(context),
                icon: const Icon(Icons.map_outlined, color: Color(0xFF0284C7)),
                label: const Text(
                  'Xem Sơ Đồ Chỉ Dẫn Phòng Thi & Toà Nhà TTN',
                  style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFBAE6FD)),
                  backgroundColor: const Color(0xFFF0F9FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 36),
          ),
        ],
      ),
    );
  }

  /// Header tóm tắt thông tin thí sinh & Kỳ thi TTN
  Widget _buildExamHeader(dynamic student, int totalMyExams) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lịch Thi Kết Thúc Học Phần',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Học kỳ 1 Năm học 2026-2027 • ĐH Tây Nguyên',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditExamDialog(),
                    icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF1E3A8A)),
                    label: const Text('Thêm môn thi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalMyExams Môn thi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 16, color: Colors.cyanAccent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${student.fullName} (${student.studentId})',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 13, color: Colors.cyanAccent),
                      const SizedBox(width: 4),
                      Text(
                        'SBD: ${student.studentId}',
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Banner đếm ngược môn thi sắp tới
  Widget _buildNextExamBanner(ExamScheduleItem exam) {
    final daysLeft = exam.daysUntilExam;
    final String countdownText = daysLeft > 0
        ? 'Còn $daysLeft ngày nữa'
        : (daysLeft == 0 ? '🔥 Hôm nay thi!' : 'Đã kết thúc');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AF59E0B),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB45309),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        countdownText,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    Text(
                      '${exam.dayOfWeek}, ${exam.examDate}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  exam.courseName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Phòng thi: ${exam.room} (${exam.building}) • Giờ thi: ${exam.examTime}',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Switch chuyển đổi giữa: Môn thi của tôi vs Toàn khóa K23
  Widget _buildScopeSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _onlyMyExams = true),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _onlyMyExams ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _onlyMyExams
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_pin_rounded,
                        size: 16,
                        color: _onlyMyExams ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Lịch thi của tôi (4 môn)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _onlyMyExams ? FontWeight.bold : FontWeight.w500,
                          color: _onlyMyExams ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _onlyMyExams = false),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: !_onlyMyExams ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: !_onlyMyExams
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 16,
                        color: !_onlyMyExams ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Toàn bộ kỳ thi CNTT K23',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: !_onlyMyExams ? FontWeight.bold : FontWeight.w500,
                          color: !_onlyMyExams ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
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
    );
  }

  /// Thanh tìm kiếm và bộ lọc hình thức thi
  Widget _buildSearchAndFilter() {
    const formats = ['Tất cả', 'Tự luận', 'Trắc nghiệm', 'Vấn đáp', 'Tiểu luận', 'Thực hành'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchFilter = val),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên môn, mã HP, phòng thi, giảng viên...',
              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
              suffixIcon: _searchFilter.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchFilter = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: formats.map((fmt) {
                final isSel = _selectedFormat == fmt;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      fmt,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isSel ? Colors.white : const Color(0xFF475569),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: const Color(0xFF1E3A8A),
                    backgroundColor: Colors.white,
                    onSelected: (_) => setState(() => _selectedFormat = fmt),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ Card chi tiết của một môn thi (với Ngày thi & Phòng thi chuẩn xác)
  Widget _buildExamCard(ExamScheduleItem item, int index) {
    Color formatColor = const Color(0xFF0284C7);
    IconData formatIcon = Icons.quiz_outlined;

    if (item.examFormat.contains('Thực hành')) {
      formatColor = const Color(0xFF059669);
      formatIcon = Icons.code_rounded;
    } else if (item.examFormat.contains('Vấn đáp')) {
      formatColor = const Color(0xFFEA580C);
      formatIcon = Icons.record_voice_over_rounded;
    } else if (item.examFormat.contains('Tự luận')) {
      formatColor = const Color(0xFF7C3AED);
      formatIcon = Icons.edit_note_rounded;
    } else if (item.examFormat.contains('Tiểu luận')) {
      formatColor = const Color(0xFFDC2626);
      formatIcon = Icons.article_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Ngày thi & Hình thức thi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: formatColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(bottom: BorderSide(color: formatColor.withValues(alpha: 0.2))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 16, color: formatColor),
                    const SizedBox(width: 6),
                    Text(
                      '${item.dayOfWeek}, ${item.examDate}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: formatColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: formatColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(formatIcon, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            item.examFormat,
                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Nút Sửa nhanh
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF1E3A8A)),
                      tooltip: 'Sửa giờ & phòng thi',
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        final rawList = _customExams ?? _getOfficialExams('23103035');
                        final targetIdx = rawList.indexOf(item);
                        _showAddEditExamDialog(
                          existingItem: item,
                          targetIndex: targetIdx != -1 ? targetIdx : index,
                        );
                      },
                    ),
                    // Nút Xóa môn thi
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                      tooltip: 'Xóa môn thi',
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        final rawList = _customExams ?? _getOfficialExams('23103035');
                        final targetIdx = rawList.indexOf(item);
                        _confirmDeleteExam(targetIdx != -1 ? targetIdx : index, item);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nội dung chi tiết môn thi
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.courseName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.credits} Tín chỉ',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Mã học phần: ${item.courseCode} • Cán bộ chấm/coi thi: ${item.examiner}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const Divider(height: 18),

                // Lưới thông số chính: Giờ thi, Phòng thi, SBD
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: _infoBlock(
                        Icons.access_time_rounded,
                        'Giờ thi (${item.duration})',
                        item.examTime,
                        item.session,
                        const Color(0xFF0284C7),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: _infoBlock(
                        Icons.meeting_room_rounded,
                        'Phòng thi chính xác',
                        item.room,
                        item.building,
                        const Color(0xFFD97706),
                        isHighlight: true,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _infoBlock(
                        Icons.badge_rounded,
                        'Số báo danh',
                        item.sbd,
                        'Khoa CNTT',
                        const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                // Ghi chú chuẩn bị & Quy chế thi TTN
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.note,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                // Thanh nút hành động nhanh
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showRoomDetailsModal(context, item),
                      icon: const Icon(Icons.pin_drop_rounded, size: 14, color: Color(0xFF0284C7)),
                      label: const Text('Bản đồ phòng', style: TextStyle(fontSize: 11.5, color: Color(0xFF0284C7))),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => _exportExamToCalendar(item),
                      icon: const Icon(Icons.event_note_rounded, size: 14, color: Color(0xFF16A34A)),
                      label: const Text('Lưu Calendar', style: TextStyle(fontSize: 11.5, color: Color(0xFF16A34A))),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: 'LỊCH THI ĐH TÂY NGUYÊN (TTN):\n'
                              '• Môn: ${item.courseName} (${item.courseCode})\n'
                              '• Ngày thi: ${item.dayOfWeek}, ${item.examDate}\n'
                              '• Giờ thi: ${item.examTime} (${item.session} - ${item.duration})\n'
                              '• Phòng thi: ${item.room} - ${item.building}\n'
                              '• Hình thức: ${item.examFormat}\n'
                              '• SBD: ${item.sbd}\n'
                              '• Giám thị: ${item.examiner}\n'
                              '• Lưu ý: ${item.note}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã sao chép lịch thi môn ${item.courseName}'),
                            backgroundColor: const Color(0xFF1E3A8A),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 13, color: Colors.white),
                      label: const Text('Sao chép', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(IconData icon, String label, String value, String sub, Color color, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
            backgroundColor: isHighlight ? const Color(0xFFFEF08A).withValues(alpha: 0.3) : Colors.transparent,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          sub,
          style: TextStyle(fontSize: 9.5, color: isHighlight ? const Color(0xFFB45309) : const Color(0xFF94A3B8)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _exportExamToCalendar(ExamScheduleItem item) {
    final sb = StringBuffer();
    sb.writeln('BEGIN:VCALENDAR');
    sb.writeln('VERSION:2.0');
    sb.writeln('PRODID:-//TTN//Exam Schedule//VI');
    sb.writeln('BEGIN:VEVENT');
    sb.writeln('SUMMARY:THI KẾT THÚC HP: ${item.courseName} (${item.courseCode})');
    sb.writeln('DESCRIPTION:Phòng thi: ${item.room} - ${item.building}\\nHình thức: ${item.examFormat}\\nSBD: ${item.sbd}\\nGiám thị: ${item.examiner}\\nLưu ý: ${item.note}');
    sb.writeln('LOCATION:${item.room}, Trường Đại học Tây Nguyên, 567 Lê Duẩn, Buôn Ma Thuột');
    
    // Parse Date and start time
    final pDate = item.parsedDate;
    final timeParts = item.examTime.split('-').first.trim().split(':');
    final startH = int.tryParse(timeParts.first) ?? 7;
    final startM = int.tryParse(timeParts.last) ?? 30;
    final dtStart = DateTime(pDate.year, pDate.month, pDate.day, startH, startM);
    final dtEnd = dtStart.add(const Duration(minutes: 90));

    String formatDt(DateTime dt) {
      return '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}T${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}00';
    }

    sb.writeln('DTSTART:${formatDt(dtStart)}');
    sb.writeln('DTEND:${formatDt(dtEnd)}');
    
    // Nhắc trước 1 ngày
    sb.writeln('BEGIN:VALARM');
    sb.writeln('TRIGGER:-P1D');
    sb.writeln('ACTION:DISPLAY');
    sb.writeln('DESCRIPTION:Nhắc nhở: Ngày mai thi ${item.courseName} lúc ${item.examTime} tại ${item.room}!');
    sb.writeln('END:VALARM');

    // Nhắc trước 2 tiếng
    sb.writeln('BEGIN:VALARM');
    sb.writeln('TRIGGER:-PT2H');
    sb.writeln('ACTION:DISPLAY');
    sb.writeln('DESCRIPTION:Khẩn cấp: 2 tiếng nữa thi ${item.courseName} tại ${item.room}. Mang theo CCCD/Thẻ SV!');
    sb.writeln('END:VALARM');

    sb.writeln('END:VEVENT');
    sb.writeln('END:VCALENDAR');

    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã tạo sự kiện lịch thi môn ${item.courseName} (kèm nhắc trước 1 ngày & 2 tiếng)!'),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Modal chỉ dẫn phòng thi cụ thể
  void _showRoomDetailsModal(BuildContext context, ExamScheduleItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.meeting_room_rounded, color: Color(0xFF0284C7)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chỉ dẫn: ${item.room}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        item.building,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Bản đồ khuôn viên thu nhỏ
            Container(
              height: 120,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sơ đồ toạ độ mô phỏng trực quan
                  Positioned(
                    top: 15,
                    left: 20,
                    child: _mapBuildingBadge('Nhà 6 (Phòng 6.11, 6.12)', item.room.contains('6.'), const Color(0xFF7C3AED)),
                  ),
                  Positioned(
                    bottom: 15,
                    left: 20,
                    child: _mapBuildingBadge('Nhà 2 (Phòng 2.4)', item.room.contains('2.'), const Color(0xFF059669)),
                  ),
                  Positioned(
                    top: 15,
                    right: 20,
                    child: _mapBuildingBadge('Nhà 7 (Lab 7.3.18 CNTT)', item.room.contains('7.'), const Color(0xFF0284C7)),
                  ),
                  Positioned(
                    bottom: 15,
                    right: 20,
                    child: _mapBuildingBadge('Nhà G2 - G3 (Hội trường)', item.room.contains('G'), const Color(0xFFD97706)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.slate300),
                    ),
                    child: const Text('📍 Hồ trung tâm & Quảng trường TTN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  ),
                ],
              ),
            ),
            _locationGuide(item.room, item.building),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quy chế phòng thi ĐH Tây Nguyên (TTN):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('• Có mặt trước giờ làm bài tối thiểu 15 phút.', style: TextStyle(fontSize: 11.5)),
                  Text('• Bắt buộc mang Thẻ sinh viên hoặc CCCD để cán bộ coi thi kiểm tra.', style: TextStyle(fontSize: 11.5)),
                  Text('• Để túi xách, điện thoại di động tại khu vực quy định đầu phòng thi.', style: TextStyle(fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Đã hiểu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapBuildingBadge(String name, bool isTarget, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isTarget ? color : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: isTarget ? 2 : 1),
        boxShadow: isTarget
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isTarget) ...[
            const Icon(Icons.location_on, size: 12, color: Colors.yellowAccent),
            const SizedBox(width: 2),
          ],
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isTarget ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationGuide(String room, String building) {
    String detail = '';
    if (room.contains('6.11') || room.contains('6.12')) {
      detail = 'Vị trí: Dãy Giảng đường Nhà 6 (nằm ở trung tâm khuôn viên trường ĐH Tây Nguyên, đối diện Thư viện trung tâm). Đi vào từ cổng chính 567 Lê Duẩn rẽ phải 100m, phòng nằm ở Tầng 1.';
    } else if (room.contains('2.4')) {
      detail = 'Vị trí: Dãy Giảng đường Nhà 2 (khu giảng đường phía sau Đài phun nước và Hồ trung tâm). Phòng học 2.4 nằm ở Tầng 1, thoáng mát và yên tĩnh.';
    } else if (room.contains('7.3.18')) {
      detail = 'Vị trí: Toà nhà Nhà 7 (Toà nhà Công nghệ thông tin & Kỹ thuật). Đi thang bộ lên Tầng 3, phòng Lab 7.3.18 trang bị máy tính kết nối mạng nội bộ và máy chiếu chuyên dụng.';
    } else if (room.contains('Online')) {
      detail = 'Vị trí: Thi trực tuyến qua nền tảng Microsoft Teams với tài khoản sinh viên do ĐH Tây Nguyên cấp (@ttn.edu.vn).';
    } else {
      detail = 'Vị trí: Khuôn viên Trường Đại học Tây Nguyên (567 Lê Duẩn, Phường Ea Kao, TP. Buôn Ma Thuột, Đắk Lắk).';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.pin_drop_rounded, size: 18, color: Color(0xFFEA580C)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            detail,
            style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.35),
          ),
        ),
      ],
    );
  }

  /// Modal sơ đồ toà nhà trong khuôn viên ĐH Tây Nguyên
  void _showCampusMapModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.apartment_rounded, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sơ Đồ Khuôn Viên Thi ĐH Tây Nguyên',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Địa chỉ: 567 Lê Duẩn, TP. Buôn Ma Thuột, Đắk Lắk',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              _campusBuildingCard(
                title: 'Nhà 7 (Toà nhà Công nghệ Thông tin)',
                rooms: 'Lab 7.3.18, Lab Mạng 2, Phòng thực hành phần mềm',
                description: 'Toà nhà chuyên ngành CNTT, nơi tổ chức thi vấn đáp, chấm đồ án và thi thực hành máy tính.',
                color: const Color(0xFF0284C7),
              ),
              _campusBuildingCard(
                title: 'Nhà 6 (Giảng đường Trung tâm)',
                rooms: 'Phòng 6.11, Phòng 6.12, Phòng 6.14',
                description: 'Dãy giảng đường lớn đối diện Thư viện, chuyên tổ chức thi các học phần Lý luận chính trị và Tự luận.',
                color: const Color(0xFF7C3AED),
              ),
              _campusBuildingCard(
                title: 'Nhà 2 (Khu Giảng đường Sư phạm)',
                rooms: 'Phòng 2.4, Phòng 2.6',
                description: 'Dãy nhà gần hồ trung tâm, phòng thi trắc nghiệm máy tính và các môn đại cương.',
                color: const Color(0xFF059669),
              ),
              _campusBuildingCard(
                title: 'Giảng đường G2 & G3',
                rooms: 'Hội trường G2-P102, G2-P201, Phòng máy G3-P105',
                description: 'Khu giảng đường bậc thang phục vụ thi tập trung quy mô lớn của trường.',
                color: const Color(0xFFD97706),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campusBuildingCard({
    required String title,
    required String rooms,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_city_rounded, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Phòng thi: $rooms',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
