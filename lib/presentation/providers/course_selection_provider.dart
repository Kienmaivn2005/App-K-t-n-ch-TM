import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/course_model.dart';
import '../../data/repositories/mock_course_repository.dart';

/// Trạng thái chọn môn học
class CourseSelectionState {
  final List<Course> allCourses;
  final Set<String> selectedCourseIds;
  final String searchQuery;
  final String selectedFaculty;
  final Set<String> passedCourseIds; // Môn đã qua môn từ trước

  const CourseSelectionState({
    this.allCourses = const [],
    this.selectedCourseIds = const {},
    this.searchQuery = '',
    this.selectedFaculty = 'Tất cả',
    this.passedCourseIds = const {'KC212604'}, // Ví dụ: Đã qua Kỹ thuật lập trình
  });

  /// Danh sách môn học hiển thị sau khi lọc tìm kiếm & khoa
  List<Course> get filteredCourses {
    final query = searchQuery.trim().toLowerCase();
    return allCourses.where((c) {
      final matchesQuery = query.isEmpty ||
          c.name.toLowerCase().contains(query) ||
          c.id.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      if (selectedFaculty != 'Tất cả' && c.faculty != selectedFaculty) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Danh sách môn học thực tế đang được chọn
  List<Course> get selectedCourses {
    return allCourses.where((c) => selectedCourseIds.contains(c.id)).toList();
  }

  /// Tổng số tín chỉ của các môn đang chọn
  int get totalCredits {
    return selectedCourses.fold(0, (sum, c) => sum + c.credits);
  }

  /// Kiểm tra số tín chỉ hợp lệ (Quy chuẩn ĐH Tây Nguyên: 12 - 24 TC)
  bool get isCreditsValid => totalCredits >= 12 && totalCredits <= 24;

  /// Cảnh báo điều kiện tiên quyết
  List<String> get prerequisiteWarnings {
    final warnings = <String>[];
    for (final course in selectedCourses) {
      for (final prereq in course.prerequisites) {
        // Nếu tiên quyết chưa học VÀ cũng không nằm trong danh sách đang chọn
        final hasPassed = passedCourseIds.contains(prereq);
        final isSelected = selectedCourseIds.contains(prereq);
        if (!hasPassed && !isSelected) {
          warnings.add(
            'Học phần "${course.name}" (${course.id}) yêu cầu môn tiên quyết "$prereq" chưa hoàn thành!',
          );
        }
      }
    }
    return warnings;
  }

  CourseSelectionState copyWith({
    List<Course>? allCourses,
    Set<String>? selectedCourseIds,
    String? searchQuery,
    String? selectedFaculty,
    Set<String>? passedCourseIds,
  }) {
    return CourseSelectionState(
      allCourses: allCourses ?? this.allCourses,
      selectedCourseIds: selectedCourseIds ?? this.selectedCourseIds,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFaculty: selectedFaculty ?? this.selectedFaculty,
      passedCourseIds: passedCourseIds ?? this.passedCourseIds,
    );
  }
}

/// Notifier quản lý tương tác và cập nhật danh sách môn học đã chọn
class CourseSelectionNotifier extends Notifier<CourseSelectionState> {
  @override
  CourseSelectionState build() {
    // Khởi tạo với danh sách môn học mặc định từ MockCourseRepository
    _initData();
    return const CourseSelectionState();
  }

  Future<void> _initData() async {
    final courses = await MockCourseRepository.searchCourses();
    // Mặc định gợi ý chọn trước một vài môn năm 3 học kỳ 1 CNTT
    final defaultSelected = {'KC215046', 'KC215047', 'KC215048', 'KC215049', 'KC215050'};
    state = state.copyWith(
      allCourses: courses,
      selectedCourseIds: defaultSelected,
    );
  }

  void toggleCourse(String courseId) {
    final nextIds = Set<String>.from(state.selectedCourseIds);
    if (nextIds.contains(courseId)) {
      nextIds.remove(courseId);
    } else {
      nextIds.add(courseId);
    }
    state = state.copyWith(selectedCourseIds: nextIds);
  }

  void selectCourse(String courseId, bool selected) {
    final nextIds = Set<String>.from(state.selectedCourseIds);
    if (selected) {
      nextIds.add(courseId);
    } else {
      nextIds.remove(courseId);
    }
    state = state.copyWith(selectedCourseIds: nextIds);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedFaculty(String faculty) {
    state = state.copyWith(selectedFaculty: faculty);
  }

  void clearSelection() {
    state = state.copyWith(selectedCourseIds: <String>{});
  }

  void selectAllFiltered() {
    final nextIds = Set<String>.from(state.selectedCourseIds);
    for (final course in state.filteredCourses) {
      nextIds.add(course.id);
    }
    state = state.copyWith(selectedCourseIds: nextIds);
  }
}

/// Provider cho CourseSelection
final courseSelectionProvider =
    NotifierProvider<CourseSelectionNotifier, CourseSelectionState>(() {
  return CourseSelectionNotifier();
});

