import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../models/plan.dart';
import '../models/student_profile.dart';
import '../models/conflict_issue.dart';
import '../models/auto_schedule_options.dart';
import '../services/mock_data.dart';
import '../services/conflict_checker.dart';
import '../services/storage_service.dart';
import '../services/share_service.dart';
import '../services/ttn_database.dart';

class PlannerProvider extends ChangeNotifier {
  List<Course> _courses = [];
  List<RegistrationPlan> _plans = [];
  String _activePlanId = '';
  StudentProfile _profile = StudentProfile.defaultProfile();
  List<ConflictIssue> _currentIssues = [];
  bool _isLoading = true;
  bool _isAuthenticated = true; // Simulated Auth State

  // Filter & Search states
  String _searchQuery = '';
  String _selectedDepartment = 'Tất cả';
  int? _selectedCredits;
  int? _selectedSemester;
  CourseCategory? _selectedCategory;

  List<Course> get courses => _courses;
  List<RegistrationPlan> get plans => _plans;
  String get activePlanId => _activePlanId;
  StudentProfile get profile => _profile;
  List<ConflictIssue> get currentIssues => _currentIssues;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  String get searchQuery => _searchQuery;
  String get selectedDepartment => _selectedDepartment;
  int? get selectedCredits => _selectedCredits;
  int? get selectedSemester => _selectedSemester;
  CourseCategory? get selectedCategory => _selectedCategory;

  Map<String, Course> _courseMap = {};
  RegistrationPlan? _cachedActivePlan;
  String? _lastActivePlanId;

  RegistrationPlan get activePlan {
    if (_cachedActivePlan != null && _lastActivePlanId == _activePlanId) {
      return _cachedActivePlan!;
    }
    final idx = _plans.indexWhere((p) => p.id == _activePlanId);
    if (idx != -1) {
      _lastActivePlanId = _activePlanId;
      return _cachedActivePlan = _plans[idx];
    }
    if (_plans.isNotEmpty) {
      _lastActivePlanId = _plans.first.id;
      return _cachedActivePlan = _plans.first;
    }
    final fallback = RegistrationPlan(id: 'plan_fallback', name: 'Phương án 1');
    _plans.add(fallback);
    _activePlanId = fallback.id;
    _lastActivePlanId = fallback.id;
    return _cachedActivePlan = fallback;
  }

  PlannerProvider() {
    _initData();
  }

  Future<void> _initData() async {
    _isLoading = true;
    notifyListeners();

    _courses = MockDataService.getSampleCourses();
    _courseMap = {for (final c in _courses) c.code: c};

    final savedProfile = await StorageService.loadProfile();
    if (savedProfile != null) {
      final dynamicPassed = TTNDatabase.getPassedCoursesForStudent(savedProfile.studentId, savedProfile.major);
      final combinedPassed = {...savedProfile.passedCourses, ...dynamicPassed}.toList();
      _profile = savedProfile.copyWith(
        passedCourses: combinedPassed,
        birthDate: TTNDatabase.getBirthDateForStudent(savedProfile.studentId),
        currentGpa: TTNDatabase.calculateGpaForStudent(savedProfile.studentId, savedProfile.major),
      );
      await StorageService.saveProfile(_profile);
    } else {
      final dynamicPassed = TTNDatabase.getPassedCoursesForStudent(_profile.studentId, _profile.major);
      final combinedPassed = {..._profile.passedCourses, ...dynamicPassed}.toList();
      _profile = _profile.copyWith(
        passedCourses: combinedPassed,
        birthDate: TTNDatabase.getBirthDateForStudent(_profile.studentId),
        currentGpa: TTNDatabase.calculateGpaForStudent(_profile.studentId, _profile.major),
      );
    }

    final savedPlans = await StorageService.loadPlans();
    final official8Codes = [
      'KC213613',
      'KC213668',
      'KC213678',
      'KC213685',
      'KC215046',
      'KC215050',
      'ML211033',
      'SP211014',
    ];

    if (savedPlans != null && savedPlans.isNotEmpty) {
      _plans = savedPlans;
      // Đảm bảo phương án luôn chuẩn xác đúng 8 môn đăng ký chính thức (18 tín chỉ), loại bỏ triệt để các môn thừa như KC212604
      for (final plan in _plans) {
        plan.selectedSections.removeWhere((code, _) => !official8Codes.contains(code));
        for (final code in official8Codes) {
          if (!plan.selectedSections.containsKey(code)) {
            final matchCourse = _courses.where((c) => c.code == code).firstOrNull;
            if (matchCourse != null && matchCourse.sections.isNotEmpty) {
              plan.selectedSections[code] = matchCourse.sections.first;
            }
          }
        }
      }
      await StorageService.savePlans(_plans);
      final savedActiveId = await StorageService.loadActivePlanId();
      if (savedActiveId != null && _plans.any((p) => p.id == savedActiveId)) {
        _activePlanId = savedActiveId;
      } else {
        _activePlanId = _plans.first.id;
      }
    } else {
      _plans = MockDataService.getInitialPlans(_courses);
      _activePlanId = _plans.first.id;
      await StorageService.savePlans(_plans);
      await StorageService.saveActivePlanId(_activePlanId);
    }

    _recomputeConflicts();
    _isLoading = false;
    notifyListeners();
  }

  void _recomputeConflicts() {
    _currentIssues = ConflictCheckerService.checkConflicts(
      selectedSections: activePlan.selectedSections,
      allCourses: _courses,
      student: _profile,
    );
  }

  void _persist() {
    StorageService.savePlans(_plans);
    StorageService.saveActivePlanId(_activePlanId);
    StorageService.saveProfile(_profile);
  }

  // --- Search & Filter operations ---
  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setSelectedDepartment(String dept) {
    _selectedDepartment = dept;
    notifyListeners();
  }

  void setSelectedCredits(int? credits) {
    _selectedCredits = credits;
    notifyListeners();
  }

  void setSelectedSemester(int? sem) {
    _selectedSemester = sem;
    notifyListeners();
  }

  void setSelectedCategory(CourseCategory? cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedDepartment = 'Tất cả';
    _selectedCredits = null;
    _selectedSemester = null;
    _selectedCategory = null;
    notifyListeners();
  }

  List<Course> get filteredCourses {
    return _courses.where((c) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchCode = c.code.toLowerCase().contains(query);
        final matchName = c.name.toLowerCase().contains(query);
        final matchLecturer = c.sections.any((s) => s.lecturer.toLowerCase().contains(query));
        if (!matchCode && !matchName && !matchLecturer) return false;
      }

      if (_selectedDepartment != 'Tất cả' && c.department != _selectedDepartment) {
        return false;
      }

      if (_selectedCredits != null && c.credits != _selectedCredits) {
        return false;
      }

      if (_selectedSemester != null && c.recommendedSemester != _selectedSemester) {
        return false;
      }

      if (_selectedCategory != null && c.category != _selectedCategory) {
        return false;
      }

      return true;
    }).toList();
  }

  List<String> get allDepartments {
    final list = _courses.map((c) => c.department).toSet().toList();
    list.sort();
    return ['Tất cả', ...list];
  }

  // --- Course CRUD Operations ---
  void addCourse(Course course) {
    _courses.insert(0, course);
    notifyListeners();
  }

  void updateCourse(Course updatedCourse) {
    final idx = _courses.indexWhere((c) => c.code == updatedCourse.code);
    if (idx != -1) {
      _courses[idx] = updatedCourse;
      // Nếu có môn này trong phương án đăng ký hiện tại, cập nhật lại thông tin section
      for (final plan in _plans) {
        if (plan.selectedSections.containsKey(updatedCourse.code)) {
          final currentSec = plan.selectedSections[updatedCourse.code]!;
          final match = updatedCourse.sections.firstWhere((s) => s.id == currentSec.id, orElse: () => updatedCourse.sections.first);
          plan.selectedSections[updatedCourse.code] = match;
        }
      }
      _recomputeConflicts();
      _persist();
      notifyListeners();
    }
  }

  void deleteCourse(String courseCode) {
    _courses.removeWhere((c) => c.code == courseCode);
    for (final plan in _plans) {
      plan.selectedSections.remove(courseCode);
    }
    _recomputeConflicts();
    _persist();
    notifyListeners();
  }

  // --- Plan Operations ---
  void switchPlan(String planId) {
    if (_activePlanId == planId) return;
    _activePlanId = planId;
    _recomputeConflicts();
    _persist();
    notifyListeners();
  }

  void createNewPlan({String? name, String? description}) {
    final nextNum = _plans.length + 1;
    final newPlan = RegistrationPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Phương án $nextNum',
      description: description ?? 'Kế hoạch dự phòng tùy chỉnh',
    );
    _plans.add(newPlan);
    _activePlanId = newPlan.id;
    _recomputeConflicts();
    _persist();
    notifyListeners();
  }

  void duplicatePlan(String sourcePlanId, {String? newName}) {
    final source = _plans.firstWhere((p) => p.id == sourcePlanId, orElse: () => activePlan);
    final dup = RegistrationPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      name: newName ?? '${source.name} (Bản sao)',
      description: 'Nhân bản từ ${source.name}',
      selectedSections: Map.from(source.selectedSections),
    );
    _plans.add(dup);
    _activePlanId = dup.id;
    _recomputeConflicts();
    _persist();
    notifyListeners();
  }

  void renamePlan(String planId, String newName, String newDesc) {
    final p = _plans.firstWhere((element) => element.id == planId);
    p.name = newName;
    p.description = newDesc;
    p.updatedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void deletePlan(String planId) {
    if (_plans.length <= 1) return; // Không xóa phương án cuối cùng
    _plans.removeWhere((p) => p.id == planId);
    if (_activePlanId == planId) {
      _activePlanId = _plans.first.id;
    }
    _recomputeConflicts();
    _persist();
    notifyListeners();
  }

  // --- Section Selection & Timetable Operations ---
  void selectSection(ClassSection section) {
    activePlan.selectedSections[section.courseCode] = section;
    activePlan.updatedAt = DateTime.now();
    _recomputeConflicts();
    _persist();
    notifyListeners();
  }

  void removeSection(String courseCode) {
    activePlan.selectedSections.remove(courseCode);
    activePlan.updatedAt = DateTime.now();
    _recomputeConflicts();
    _persist();
    notifyListeners();
  }

  void clearActivePlan() {
    activePlan.selectedSections.clear();
    activePlan.updatedAt = DateTime.now();
    _recomputeConflicts();
    _persist();
    notifyListeners();
  }

  bool isSectionSelected(String sectionId) {
    return activePlan.selectedSections.values.any((s) => s.id == sectionId);
  }

  bool isCourseSelected(String courseCode) {
    return activePlan.selectedSections.containsKey(courseCode);
  }

  ClassSection? getSelectedSectionForCourse(String courseCode) {
    return activePlan.selectedSections[courseCode];
  }

  // --- Apply AI Solution ---
  void applyAutoScheduleSolution(AutoScheduleSolution solution, {bool createNewPlanOption = false}) {
    if (createNewPlanOption) {
      final newPlan = RegistrationPlan(
        id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
        name: 'AI: ${solution.title}',
        description: 'Được xếp tự động bởi UniPlan AI (${solution.score.toStringAsFixed(0)}% tối ưu)',
        selectedSections: Map.from(solution.sections),
      );
      _plans.add(newPlan);
      _activePlanId = newPlan.id;
    } else {
      activePlan.selectedSections.clear();
      activePlan.selectedSections.addAll(solution.sections);
      activePlan.updatedAt = DateTime.now();
    }
    _recomputeConflicts();
    _persist();
    notifyListeners();
  }

  // --- Import from Share Code ---
  bool importShareCode(String shareCode) {
    final data = ShareService.decodeShareCode(shareCode);
    if (data == null) return false;

    final planName = data['planName'] as String? ?? 'Phương án Nhập từ bạn bè';
    final sectionIds = List<String>.from(data['sectionIds'] ?? []);

    final matchedSections = <String, ClassSection>{};
    for (final secId in sectionIds) {
      for (final course in _courses) {
        for (final sec in course.sections) {
          if (sec.id == secId) {
            matchedSections[sec.courseCode] = sec;
          }
        }
      }
    }

    final newPlan = RegistrationPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      name: '$planName (Chia sẻ)',
      description: 'Nhập thành công ${matchedSections.length} lớp học phần từ mã chia sẻ.',
      selectedSections: matchedSections,
    );

    _plans.add(newPlan);
    _activePlanId = newPlan.id;
    _recomputeConflicts();
    _persist();
    notifyListeners();
    return true;
  }

  // --- Profile Operations ---
  void updateProfile(StudentProfile newProfile) {
    final dynamicPassed = TTNDatabase.getPassedCoursesForStudent(newProfile.studentId, newProfile.major);
    final combinedPassed = {...newProfile.passedCourses, ...dynamicPassed}.toList();
    _profile = newProfile.copyWith(passedCourses: combinedPassed);
    _recomputeConflicts();
    _persist();
    notifyListeners();
  }

  void togglePassedCourse(String courseCode) {
    final list = List<String>.from(_profile.passedCourses);
    if (list.contains(courseCode)) {
      list.remove(courseCode);
    } else {
      list.add(courseCode);
    }
    _profile = _profile.copyWith(passedCourses: list);
    _recomputeConflicts();
    _persist();
    notifyListeners();
  }

  // --- Credit & Financial Calculations ---
  Course? getCourseByCode(String code) {
    if (_courseMap.isEmpty && _courses.isNotEmpty) {
      _courseMap = {for (final c in _courses) c.code: c};
    }
    return _courseMap[code];
  }

  int get totalCredits {
    int sum = 0;
    for (final sec in activePlan.selectedSections.values) {
      final c = getCourseByCode(sec.courseCode);
      if (c != null) sum += c.credits;
    }
    return sum;
  }

  int get totalTheoryCredits {
    int sum = 0;
    for (final sec in activePlan.selectedSections.values) {
      final c = getCourseByCode(sec.courseCode);
      if (c != null) sum += c.theoryCredits;
    }
    return sum;
  }

  int get totalPracticeCredits {
    int sum = 0;
    for (final sec in activePlan.selectedSections.values) {
      final c = getCourseByCode(sec.courseCode);
      if (c != null) sum += c.practiceCredits;
    }
    return sum;
  }

  /// Tính toán học bổng khuyến khích học tập dựa trên GPA
  double get scholarshipRate {
    if (_profile.targetGpa >= 3.60) {
      return 1.0; // Xuất sắc: 100% học bổng
    } else if (_profile.targetGpa >= 3.20) {
      return 0.8; // Giỏi: 80% học bổng
    } else if (_profile.targetGpa >= 2.80) {
      return 0.5; // Khá: 50% học bổng
    }
    return 0.0;
  }

  String get scholarshipTitle {
    if (_profile.targetGpa >= 3.60) return 'Học bổng Xuất Sắc (100%)';
    if (_profile.targetGpa >= 3.20) return 'Học bổng Giỏi (80%)';
    if (_profile.targetGpa >= 2.80) return 'Học bổng Khá (50%)';
    return 'Chưa đạt mức học bổng';
  }

  /// Tính toán học phí chi tiết
  int get baseTuitionCost {
    final pricePerCredit = _profile.program.basePricePerCredit;
    // Phụ phí thực hành 20%
    final theoryCost = totalTheoryCredits * pricePerCredit;
    final practiceCost = (totalPracticeCredits * pricePerCredit * 1.2).round();
    return theoryCost + practiceCost;
  }

  int get policyDiscountAmount {
    final rate = _profile.tuitionPolicy.discountRate;
    return (baseTuitionCost * rate).round();
  }

  int get scholarshipDiscountAmount {
    // Học bổng áp dụng sau chính sách miễn giảm
    final remaining = baseTuitionCost - policyDiscountAmount;
    return (remaining * scholarshipRate).round();
  }

  int get finalPayableTuition {
    final total = baseTuitionCost - policyDiscountAmount - scholarshipDiscountAmount;
    return total.clamp(0, 999999999);
  }

  // Conflict status helpers
  int get errorCount => _currentIssues.where((i) => i.isError).length;
  int get warningCount => _currentIssues.where((i) => i.isWarning).length;
  bool get hasErrors => errorCount > 0;
  bool get hasWarnings => warningCount > 0;

  // Simulated Authentication Methods
  void login({
    required String studentId,
    required String password,
    String? fullName,
    String? major,
    String? cohort,
  }) {
    _isAuthenticated = true;
    final cleanId = studentId.trim();
    final ttnStudent = TTNDatabase.getStudent(cleanId);
    final effName = fullName ?? (ttnStudent != null ? ttnStudent['fullName'] as String : _profile.fullName);
    final effMajor = major ?? (ttnStudent != null ? ttnStudent['major'] as String : _profile.major);
    final effCohort = cohort ?? (ttnStudent != null ? ttnStudent['cohort'] as String : _profile.cohort);
    final effBirth = TTNDatabase.getBirthDateForStudent(cleanId);
    final effGpa = TTNDatabase.calculateGpaForStudent(cleanId, effMajor);
    final effFaculty = (ttnStudent != null && ttnStudent['faculty'] != null)
        ? ttnStudent['faculty'] as String
        : _profile.faculty;
    final effAdvisor = (ttnStudent != null && ttnStudent['advisor'] != null)
        ? ttnStudent['advisor'] as String
        : _profile.advisor;

    final studentPassed = TTNDatabase.getPassedCoursesForStudent(cleanId, effMajor);

    _profile = _profile.copyWith(
      studentId: cleanId,
      fullName: effName,
      major: effMajor,
      cohort: effCohort,
      faculty: effFaculty,
      advisor: effAdvisor,
      birthDate: effBirth,
      currentGpa: effGpa,
      passedCourses: studentPassed,
    );

    // Đảm bảo đủ đúng 8 môn đăng ký (18 tín chỉ) cho mọi sinh viên
    final official8Codes = [
      'KC213613',
      'KC213668',
      'KC213678',
      'KC213685',
      'KC215046',
      'KC215050',
      'ML211033',
      'SP211014',
    ];
    activePlan.selectedSections.removeWhere((code, _) => !official8Codes.contains(code));
    for (final code in official8Codes) {
      if (!activePlan.selectedSections.containsKey(code)) {
        final match = _courses.where((c) => c.code == code).firstOrNull;
        if (match != null && match.sections.isNotEmpty) {
          activePlan.selectedSections[code] = match.sections.first;
        }
      }
    }

    StorageService.saveProfile(_profile);
    _persist();
    _recomputeConflicts();
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  void switchAccount(StudentProfile newProfile) {
    final cleanId = newProfile.studentId.trim();
    final studentPassed = TTNDatabase.getPassedCoursesForStudent(cleanId, newProfile.major);
    _profile = newProfile.copyWith(
      studentId: cleanId,
      birthDate: TTNDatabase.getBirthDateForStudent(cleanId),
      currentGpa: TTNDatabase.calculateGpaForStudent(cleanId, newProfile.major),
      passedCourses: studentPassed,
    );
    _isAuthenticated = true;

    final official8Codes = [
      'KC213613',
      'KC213668',
      'KC213678',
      'KC213685',
      'KC215046',
      'KC215050',
      'ML211033',
      'SP211014',
    ];
    activePlan.selectedSections.removeWhere((code, _) => !official8Codes.contains(code));
    for (final code in official8Codes) {
      if (!activePlan.selectedSections.containsKey(code)) {
        final match = _courses.where((c) => c.code == code).firstOrNull;
        if (match != null && match.sections.isNotEmpty) {
          activePlan.selectedSections[code] = match.sections.first;
        }
      }
    }

    StorageService.saveProfile(_profile);
    _persist();
    _recomputeConflicts();
    notifyListeners();
  }
}

