import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart';
import '../models/course_section_model.dart';
import '../models/time_slot_model.dart';

/// Repository cung cấp dữ liệu học phần và quản lý lưu trữ phương án lịch
class MockCourseRepository {
  static const String _savedPlansKey = 'uniplan_saved_plans_v1';

  /// Danh mục học phần phong phú của Trường Đại học Tây Nguyên (TTN)
  static final List<Course> _allCourses = [
    // 1. Lập trình di động (3 TC) - Có môn tiên quyết: Kỹ thuật lập trình (KC212604)
    Course(
      id: 'KC215046',
      name: 'Lập trình di động',
      credits: 3,
      prerequisites: ['KC212604'],
      faculty: 'Khoa KHTN&CN',
      semester: 1,
      theoryCredits: 2,
      practiceCredits: 1,
      sections: [
        const CourseSection(
          classId: 'KC215046_74297',
          courseId: 'KC215046',
          courseName: 'Lập trình di động',
          lecturer: 'ThS. Trương Thị Hương Giang',
          slots: [
            TimeSlot(dayOfWeek: 4, startPeriod: 1, length: 4, room: '7.3.18'),
            TimeSlot(dayOfWeek: 5, startPeriod: 7, length: 3, room: 'Lab 7.3.18'),
          ],
          capacity: 65,
          enrolled: 59,
        ),
        const CourseSection(
          classId: 'KC215046_74298',
          courseId: 'KC215046',
          courseName: 'Lập trình di động',
          lecturer: 'ThS. Bùi Văn Hùng',
          slots: [
            TimeSlot(dayOfWeek: 2, startPeriod: 1, length: 4, room: '7.3.18'),
            TimeSlot(dayOfWeek: 3, startPeriod: 7, length: 3, room: 'Lab 7.3.16'),
          ],
          capacity: 65,
          enrolled: 48,
        ),
        const CourseSection(
          classId: 'KC215046_74299',
          courseId: 'KC215046',
          courseName: 'Lập trình di động',
          lecturer: 'ThS. Lê Hoàng Long',
          slots: [
            TimeSlot(dayOfWeek: 6, startPeriod: 1, length: 4, room: '7.3.18'),
            TimeSlot(dayOfWeek: 7, startPeriod: 7, length: 3, room: 'Lab 7.3.18'),
          ],
          capacity: 65,
          enrolled: 42,
        ),
      ],
    ),

    // 2. An toàn thông tin (2 TC)
    Course(
      id: 'KC213613',
      name: 'An toàn thông tin',
      credits: 2,
      prerequisites: [],
      faculty: 'Khoa KHTN&CN',
      semester: 1,
      theoryCredits: 2,
      practiceCredits: 0,
      sections: [
        const CourseSection(
          classId: 'KC213613_74293',
          courseId: 'KC213613',
          courseName: 'An toàn thông tin',
          lecturer: 'ThS. Trần Đình Hưng',
          slots: [
            TimeSlot(dayOfWeek: 3, startPeriod: 7, length: 3, room: '6.12'),
          ],
          capacity: 70,
          enrolled: 67,
        ),
        const CourseSection(
          classId: 'KC213613_74294',
          courseId: 'KC213613',
          courseName: 'An toàn thông tin',
          lecturer: 'TS. Võ Quốc Thông',
          slots: [
            TimeSlot(dayOfWeek: 5, startPeriod: 1, length: 3, room: '6.14'),
          ],
          capacity: 70,
          enrolled: 52,
        ),
      ],
    ),

    // 3. Quản trị mạng trên MT Windows (2 TC)
    Course(
      id: 'KC213668',
      name: 'QTM trên MT Windows',
      credits: 2,
      prerequisites: [],
      faculty: 'Khoa KHTN&CN',
      semester: 1,
      theoryCredits: 1,
      practiceCredits: 1,
      sections: [
        const CourseSection(
          classId: 'KC213668_74310',
          courseId: 'KC213668',
          courseName: 'QTM trên MT Windows',
          lecturer: 'ThS. Lê Hoàng Long',
          slots: [
            TimeSlot(dayOfWeek: 4, startPeriod: 7, length: 3, room: 'Lab Mạng 2'),
          ],
          capacity: 65,
          enrolled: 62,
        ),
        const CourseSection(
          classId: 'KC213668_74311',
          courseId: 'KC213668',
          courseName: 'QTM trên MT Windows',
          lecturer: 'ThS. Bùi Văn Hùng',
          slots: [
            TimeSlot(dayOfWeek: 2, startPeriod: 7, length: 3, room: 'Lab Mạng 1'),
          ],
          capacity: 65,
          enrolled: 55,
        ),
      ],
    ),

    // 4. Thương mại điện tử (2 TC)
    Course(
      id: 'KC213678',
      name: 'Thương mại điện tử',
      credits: 2,
      prerequisites: [],
      faculty: 'Khoa KHTN&CN',
      semester: 1,
      theoryCredits: 2,
      practiceCredits: 0,
      sections: [
        const CourseSection(
          classId: 'KC213678_74306',
          courseId: 'KC213678',
          courseName: 'Thương mại điện tử',
          lecturer: 'TS. Nguyễn Thị Mai Lan',
          slots: [
            TimeSlot(dayOfWeek: 5, startPeriod: 7, length: 3, room: '3.2.04'),
          ],
          capacity: 70,
          enrolled: 63,
        ),
        const CourseSection(
          classId: 'KC213678_74307',
          courseId: 'KC213678',
          courseName: 'Thương mại điện tử',
          lecturer: 'ThS. Nguyễn Hữu Dũng',
          slots: [
            TimeSlot(dayOfWeek: 3, startPeriod: 1, length: 3, room: '3.2.02'),
          ],
          capacity: 70,
          enrolled: 58,
        ),
      ],
    ),

    // 5. Những vấn đề hiện đại của CNTT (2 TC)
    Course(
      id: 'KC213685',
      name: 'Những VĐ HĐ của CNTT',
      credits: 2,
      prerequisites: [],
      faculty: 'Khoa KHTN&CN',
      semester: 1,
      theoryCredits: 2,
      practiceCredits: 0,
      sections: [
        const CourseSection(
          classId: 'KC213685_74292',
          courseId: 'KC213685',
          courseName: 'Những VĐ HĐ của CNTT',
          lecturer: 'ThS. Trương Thị Hương Giang',
          slots: [
            TimeSlot(dayOfWeek: 6, startPeriod: 1, length: 3, room: '7.3.18'),
          ],
          capacity: 70,
          enrolled: 63,
        ),
        const CourseSection(
          classId: 'KC213685_74293',
          courseId: 'KC213685',
          courseName: 'Những VĐ HĐ của CNTT',
          lecturer: 'TS. Trần Văn Hùng',
          slots: [
            TimeSlot(dayOfWeek: 2, startPeriod: 7, length: 3, room: '7.3.18'),
          ],
          capacity: 70,
          enrolled: 49,
        ),
      ],
    ),

    // 6. Công nghệ trình đa nền (3 TC) - Tiên quyết: KC212604
    Course(
      id: 'KC215050',
      name: 'CN trình đa nền',
      credits: 3,
      prerequisites: ['KC212604'],
      faculty: 'Khoa KHTN&CN',
      semester: 1,
      theoryCredits: 2,
      practiceCredits: 1,
      sections: [
        const CourseSection(
          classId: 'KC215050_74301',
          courseId: 'KC215050',
          courseName: 'CN trình đa nền',
          lecturer: 'ThS. Bùi Văn Hùng',
          slots: [
            TimeSlot(dayOfWeek: 6, startPeriod: 7, length: 3, room: 'Lab 5'),
            TimeSlot(dayOfWeek: 7, startPeriod: 1, length: 2, room: 'Lab 5'),
          ],
          capacity: 65,
          enrolled: 59,
        ),
        const CourseSection(
          classId: 'KC215050_74302',
          courseId: 'KC215050',
          courseName: 'CN trình đa nền',
          lecturer: 'ThS. Trương Thị Hương Giang',
          slots: [
            TimeSlot(dayOfWeek: 4, startPeriod: 7, length: 3, room: 'Lab 5'),
            TimeSlot(dayOfWeek: 5, startPeriod: 1, length: 2, room: 'Lab 5'),
          ],
          capacity: 65,
          enrolled: 47,
        ),
      ],
    ),

    // 7. Lịch sử Đảng Cộng sản Việt Nam (2 TC)
    Course(
      id: 'ML211033',
      name: 'LS Đảng CS VN',
      credits: 2,
      prerequisites: [],
      faculty: 'Khoa Lý luận Chính trị',
      semester: 1,
      theoryCredits: 2,
      practiceCredits: 0,
      sections: [
        const CourseSection(
          classId: 'ML211033_74291',
          courseId: 'ML211033',
          courseName: 'LS Đảng CS VN',
          lecturer: 'Đoàn Văn Kỳ',
          slots: [
            TimeSlot(dayOfWeek: 2, startPeriod: 1, length: 4, room: '6.11'),
          ],
          capacity: 70,
          enrolled: 67,
        ),
        const CourseSection(
          classId: 'ML211033_74292',
          courseId: 'ML211033',
          courseName: 'LS Đảng CS VN',
          lecturer: 'Nguyễn Thị Hoa',
          slots: [
            TimeSlot(dayOfWeek: 5, startPeriod: 7, length: 4, room: '6.11'),
          ],
          capacity: 70,
          enrolled: 54,
        ),
      ],
    ),

    // 8. Tâm lý học đại cương (2 TC)
    Course(
      id: 'SP211014',
      name: 'Tâm lý học đại cương',
      credits: 2,
      prerequisites: [],
      faculty: 'Khoa Sư phạm',
      semester: 1,
      theoryCredits: 2,
      practiceCredits: 0,
      sections: [
        const CourseSection(
          classId: 'SP211014_74294',
          courseId: 'SP211014',
          courseName: 'Tâm lý học đại cương',
          lecturer: 'Lê Tô Đỗ Quyên',
          slots: [
            TimeSlot(dayOfWeek: 3, startPeriod: 1, length: 4, room: '2.4'),
            TimeSlot(dayOfWeek: 5, startPeriod: 1, length: 2, room: '2.4'),
          ],
          capacity: 70,
          enrolled: 64,
        ),
        const CourseSection(
          classId: 'SP211014_74295',
          courseId: 'SP211014',
          courseName: 'Tâm lý học đại cương',
          lecturer: 'TS. Trần Thị Thu Thủy',
          slots: [
            TimeSlot(dayOfWeek: 4, startPeriod: 1, length: 4, room: '4.11 Nhà SP'),
            TimeSlot(dayOfWeek: 6, startPeriod: 7, length: 2, room: '4.11 Nhà SP'),
          ],
          capacity: 70,
          enrolled: 51,
        ),
      ],
    ),

    // 9. Trí tuệ nhân tạo (3 TC) - Tiên quyết: KC212604
    Course(
      id: 'KC214012',
      name: 'Trí tuệ nhân tạo',
      credits: 3,
      prerequisites: ['KC212604'],
      faculty: 'Khoa KHTN&CN',
      semester: 1,
      theoryCredits: 2,
      practiceCredits: 1,
      sections: [
        const CourseSection(
          classId: 'KC214012_74315',
          courseId: 'KC214012',
          courseName: 'Trí tuệ nhân tạo',
          lecturer: 'TS. Võ Quốc Thông',
          slots: [
            TimeSlot(dayOfWeek: 3, startPeriod: 4, length: 3, room: '501 - Tòa C'),
            TimeSlot(dayOfWeek: 5, startPeriod: 4, length: 3, room: 'Lab Mạng 2'),
          ],
          capacity: 65,
          enrolled: 61,
        ),
        const CourseSection(
          classId: 'KC214012_74316',
          courseId: 'KC214012',
          courseName: 'Trí tuệ nhân tạo',
          lecturer: 'ThS. Trần Thị B',
          slots: [
            TimeSlot(dayOfWeek: 2, startPeriod: 4, length: 3, room: '501 - Tòa C'),
            TimeSlot(dayOfWeek: 4, startPeriod: 7, length: 3, room: 'Lab Mạng 2'),
          ],
          capacity: 65,
          enrolled: 50,
        ),
      ],
    ),

    // 10. Thể dục (Bóng rổ) (1 TC)
    Course(
      id: 'TC211001',
      name: 'Thể dục (Bóng rổ)',
      credits: 1,
      prerequisites: [],
      faculty: 'Bộ môn Giáo dục Thể chất',
      semester: 1,
      theoryCredits: 0,
      practiceCredits: 1,
      sections: [
        const CourseSection(
          classId: 'TC211001_74320',
          courseId: 'TC211001',
          courseName: 'Thể dục (Bóng rổ)',
          lecturer: 'Thầy Lê Văn C',
          slots: [
            TimeSlot(dayOfWeek: 2, startPeriod: 7, length: 3, room: 'Sân Thể chất'),
          ],
          capacity: 50,
          enrolled: 48,
        ),
        const CourseSection(
          classId: 'TC211001_74321',
          courseId: 'TC211001',
          courseName: 'Thể dục (Bóng rổ)',
          lecturer: 'Thầy Hoàng Văn D',
          slots: [
            TimeSlot(dayOfWeek: 6, startPeriod: 7, length: 3, room: 'Sân Thể chất'),
          ],
          capacity: 50,
          enrolled: 45,
        ),
      ],
    ),

    // 11. Cơ sở dữ liệu (3 TC)
    Course(
      id: 'KC214055',
      name: 'Cơ sở dữ liệu',
      credits: 3,
      prerequisites: [],
      faculty: 'Khoa KHTN&CN',
      semester: 1,
      theoryCredits: 2,
      practiceCredits: 1,
      sections: [
        const CourseSection(
          classId: 'KC214055_74325',
          courseId: 'KC214055',
          courseName: 'Cơ sở dữ liệu',
          lecturer: 'ThS. Trương Hải',
          slots: [
            TimeSlot(dayOfWeek: 3, startPeriod: 7, length: 3, room: 'Lab 5'),
            TimeSlot(dayOfWeek: 5, startPeriod: 7, length: 3, room: '6.12'),
          ],
          capacity: 65,
          enrolled: 58,
        ),
      ],
    ),

    // 12. Phân tích thiết kế hệ thống (3 TC)
    Course(
      id: 'KC214088',
      name: 'Phân tích hệ thống',
      credits: 3,
      prerequisites: ['KC214055'],
      faculty: 'Khoa KHTN&CN',
      semester: 1,
      theoryCredits: 2,
      practiceCredits: 1,
      sections: [
        const CourseSection(
          classId: 'KC214088_74330',
          courseId: 'KC214088',
          courseName: 'Phân tích hệ thống',
          lecturer: 'TS. Nguyễn Thị Mai Lan',
          slots: [
            TimeSlot(dayOfWeek: 5, startPeriod: 7, length: 3, room: '3.2.04'),
          ],
          capacity: 65,
          enrolled: 56,
        ),
      ],
    ),
  ];

  /// Lấy tất cả môn học
  static Future<List<Course>> getAllCourses() async {
    // Giả lập độ trễ mạng nhẹ (30ms)
    await Future.delayed(const Duration(milliseconds: 30));
    return List<Course>.from(_allCourses);
  }

  /// Tìm kiếm và lọc môn học
  static Future<List<Course>> searchCourses({
    String query = '',
    String faculty = 'Tất cả',
    int? semester,
  }) async {
    final cleanQuery = query.trim().toLowerCase();
    return _allCourses.where((c) {
      final matchesQuery = cleanQuery.isEmpty ||
          c.name.toLowerCase().contains(cleanQuery) ||
          c.id.toLowerCase().contains(cleanQuery);
      if (!matchesQuery) return false;

      if (faculty != 'Tất cả' && c.faculty != faculty) return false;
      if (semester != null && c.semester != semester) return false;

      return true;
    }).toList();
  }

  /// Lấy danh sách các khoa đào tạo
  static List<String> getFaculties() {
    final set = {'Tất cả'};
    for (final c in _allCourses) {
      set.add(c.faculty);
    }
    return set.toList();
  }

  /// Lưu trữ các phương án yêu thích vào SharedPreferences
  static Future<void> savePlans(List<SchedulePlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = plans.map((p) => p.toJson()).toList();
    await prefs.setString(_savedPlansKey, jsonEncode(jsonList));
  }

  /// Đọc các phương án đã lưu từ SharedPreferences
  static Future<List<SchedulePlan>> loadSavedPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_savedPlansKey);
      if (str == null || str.isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(str);
      return jsonList
          .map((item) => SchedulePlan.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Thêm hoặc xóa một phương án khỏi mục yêu thích
  static Future<void> toggleFavoritePlan(SchedulePlan plan) async {
    final current = await loadSavedPlans();
    final index = current.indexWhere((p) => p.id == plan.id);
    if (index >= 0) {
      current.removeAt(index);
    } else {
      current.add(plan.copyWith(isFavorite: true));
    }
    await savePlans(current);
  }
}

