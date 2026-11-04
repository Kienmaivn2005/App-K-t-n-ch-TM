import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/algorithm/schedule_evaluator.dart';
import '../../core/algorithm/schedule_solver.dart';
import '../../data/models/course_model.dart';
import '../../data/repositories/mock_course_repository.dart';

/// State chứa kết quả tính toán thời khóa biểu và các tiêu chí lọc
class SchedulePlannerState {
  final bool isLoading;
  final List<SchedulePlan> plans;
  final int currentPlanIndex;
  final ScheduleFilterCriteria criteria;
  final String? errorMessage;
  final List<SchedulePlan> savedPlans;

  const SchedulePlannerState({
    this.isLoading = false,
    this.plans = const [],
    this.currentPlanIndex = 0,
    this.criteria = const ScheduleFilterCriteria(),
    this.errorMessage,
    this.savedPlans = const [],
  });

  /// Phương án đang được chọn hiển thị
  SchedulePlan? get currentPlan {
    if (plans.isEmpty || currentPlanIndex < 0 || currentPlanIndex >= plans.length) {
      return null;
    }
    return plans[currentPlanIndex];
  }

  /// Tổng số phương án tìm được
  int get totalPlans => plans.length;

  /// Đã lưu phương án hiện tại chưa
  bool get isCurrentPlanSaved {
    final current = currentPlan;
    if (current == null) return false;
    return savedPlans.any((p) => p.id == current.id || p.selectedSections == current.selectedSections);
  }

  SchedulePlannerState copyWith({
    bool? isLoading,
    List<SchedulePlan>? plans,
    int? currentPlanIndex,
    ScheduleFilterCriteria? criteria,
    String? errorMessage,
    List<SchedulePlan>? savedPlans,
  }) {
    return SchedulePlannerState(
      isLoading: isLoading ?? this.isLoading,
      plans: plans ?? this.plans,
      currentPlanIndex: currentPlanIndex ?? this.currentPlanIndex,
      criteria: criteria ?? this.criteria,
      errorMessage: errorMessage,
      savedPlans: savedPlans ?? this.savedPlans,
    );
  }
}

/// Notifier điều khiển thuật toán CSP và quản lý phương án thời khóa biểu
class SchedulePlannerNotifier extends Notifier<SchedulePlannerState> {
  @override
  SchedulePlannerState build() {
    _loadSavedPlans();
    return const SchedulePlannerState();
  }

  Future<void> _loadSavedPlans() async {
    final saved = await MockCourseRepository.loadSavedPlans();
    state = state.copyWith(savedPlans: saved);
  }

  /// Kích hoạt thuật toán xếp lịch tự động chạy trong Dart Background Isolate
  Future<void> generateSchedules(List<Course> selectedCourses) async {
    if (selectedCourses.isEmpty) {
      state = state.copyWith(
        plans: [],
        currentPlanIndex: 0,
        errorMessage: 'Vui lòng chọn ít nhất một môn học để lập lịch!',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Chạy Isolate bất đồng bộ giải CSP
      final resultPlans = await ScheduleSolver.solveAsync(
        selectedCourses: selectedCourses,
        criteria: state.criteria,
      );

      if (resultPlans.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          plans: [],
          currentPlanIndex: 0,
          errorMessage: 'Không tìm thấy phương án nào không bị xung đột tiết học. Hãy thử đổi môn hoặc nới lỏng tiêu chí!',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          plans: resultPlans,
          currentPlanIndex: 0,
          errorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Đã xảy ra lỗi trong quá trình tối ưu lịch: $e',
      );
    }
  }

  /// Cập nhật tiêu chí lọc mềm (Học sáng, Tránh T6, Tránh Tiết 1...) và tính lại điểm
  Future<void> updateCriteria(
    ScheduleFilterCriteria newCriteria,
    List<Course> selectedCourses,
  ) async {
    state = state.copyWith(criteria: newCriteria);
    await generateSchedules(selectedCourses);
  }

  /// Chuyển sang phương án tiếp theo
  void nextPlan() {
    if (state.plans.isEmpty) return;
    final nextIndex = (state.currentPlanIndex + 1) % state.plans.length;
    state = state.copyWith(currentPlanIndex: nextIndex);
  }

  /// Quay lại phương án trước đó
  void previousPlan() {
    if (state.plans.isEmpty) return;
    final prevIndex =
        (state.currentPlanIndex - 1 + state.plans.length) % state.plans.length;
    state = state.copyWith(currentPlanIndex: prevIndex);
  }

  /// Chọn một phương án theo chỉ số
  void setPlanIndex(int index) {
    if (index >= 0 && index < state.plans.length) {
      state = state.copyWith(currentPlanIndex: index);
    }
  }

  /// Lưu hoặc hủy lưu phương án yêu thích
  Future<void> toggleFavoriteCurrentPlan() async {
    final current = state.currentPlan;
    if (current == null) return;

    await MockCourseRepository.toggleFavoritePlan(current);
    final updatedSaved = await MockCourseRepository.loadSavedPlans();
    state = state.copyWith(savedPlans: updatedSaved);
  }

  /// Xóa phương án đã lưu
  Future<void> removeSavedPlan(String planId) async {
    final updated = state.savedPlans.where((p) => p.id != planId).toList();
    await MockCourseRepository.savePlans(updated);
    state = state.copyWith(savedPlans: updated);
  }
}

/// Provider cho SchedulePlanner
final schedulePlannerProvider =
    NotifierProvider<SchedulePlannerNotifier, SchedulePlannerState>(() {
  return SchedulePlannerNotifier();
});

