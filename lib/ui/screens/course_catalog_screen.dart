import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../providers/planner_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/prerequisite_dialog.dart';
import '../widgets/conflict_banner.dart';
import '../widgets/stat_cards.dart';

class CourseCatalogScreen extends StatelessWidget {
  const CourseCatalogScreen({super.key});

  void _showAddEditCourseDialog(BuildContext context, PlannerProvider planner, {Course? existing}) {
    final isEditing = existing != null;
    final formKey = GlobalKey<FormState>();

    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final creditsCtrl = TextEditingController(text: (existing?.credits ?? 3).toString());
    final theoryCreditsCtrl = TextEditingController(text: (existing?.theoryCredits ?? 2).toString());
    final practiceCreditsCtrl = TextEditingController(text: (existing?.practiceCredits ?? 1).toString());
    final deptCtrl = TextEditingController(text: existing?.department ?? 'Khoa Công nghệ thông tin');
    final semCtrl = TextEditingController(text: (existing?.recommendedSemester ?? 5).toString());
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    CourseCategory categoryVal = existing?.category ?? CourseCategory.specializedElective;

    // Default section info
    final sectionIdCtrl = TextEditingController(text: existing?.sections.firstOrNull?.id ?? '${codeCtrl.text}_01');
    final lecturerCtrl = TextEditingController(text: existing?.sections.firstOrNull?.lecturer ?? 'TS. Giảng viên TTN');
    final roomCtrl = TextEditingController(text: existing?.sections.firstOrNull?.slots.firstOrNull?.room ?? '6.11');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'Sửa Thông Tin Học Phần' : 'Thêm Học Phần Mới',
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
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: codeCtrl,
                            enabled: !isEditing,
                            decoration: const InputDecoration(
                              labelText: 'Mã học phần *',
                              prefixIcon: Icon(Icons.tag_rounded, size: 18),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 5,
                          child: TextFormField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tên học phần *',
                              prefixIcon: Icon(Icons.menu_book_rounded, size: 18),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: creditsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Tổng TC *', isDense: true),
                            validator: (v) => v == null || int.tryParse(v) == null ? 'Số' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: theoryCreditsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'TC Lý thuyết', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: practiceCreditsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'TC Thực hành', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: semCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Học kỳ gợi ý', isDense: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: deptCtrl,
                            decoration: const InputDecoration(labelText: 'Khoa phụ trách', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<CourseCategory>(
                            initialValue: categoryVal,
                            decoration: const InputDecoration(labelText: 'Loại học phần', isDense: true),
                            items: CourseCategory.values.map((cat) {
                              return DropdownMenuItem(value: cat, child: Text(cat.label, style: const TextStyle(fontSize: 12)));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setDlgState(() => categoryVal = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lớp học phần mở (Thời khóa biểu):',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF166534)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: sectionIdCtrl,
                                  decoration: const InputDecoration(labelText: 'Mã lớp HP', isDense: true, filled: true, fillColor: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: lecturerCtrl,
                                  decoration: const InputDecoration(labelText: 'Giảng viên', isDense: true, filled: true, fillColor: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: roomCtrl,
                                  decoration: const InputDecoration(labelText: 'Phòng học', isDense: true, filled: true, fillColor: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Mô tả học phần', isDense: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final totalCredits = int.parse(creditsCtrl.text.trim());
                final theoryCredits = int.tryParse(theoryCreditsCtrl.text.trim()) ?? totalCredits;
                final practiceCredits = int.tryParse(practiceCreditsCtrl.text.trim()) ?? 0;
                final sem = int.tryParse(semCtrl.text.trim()) ?? 5;

                final cCode = codeCtrl.text.trim().toUpperCase();
                final secId = sectionIdCtrl.text.trim().isNotEmpty ? sectionIdCtrl.text.trim() : '${cCode}_01';

                final List<ClassSection> sectionsList = existing?.sections.isNotEmpty == true
                    ? existing!.sections.map((s) {
                        return ClassSection(
                          id: s.id,
                          courseCode: cCode,
                          courseName: nameCtrl.text.trim(),
                          lecturer: lecturerCtrl.text.trim(),
                          lecturerRating: s.lecturerRating,
                          capacity: s.capacity,
                          enrolled: s.enrolled,
                          slots: s.slots,
                          campus: s.campus,
                          colorHex: s.colorHex,
                        );
                      }).toList()
                    : [
                        ClassSection(
                          id: secId,
                          courseCode: cCode,
                          courseName: nameCtrl.text.trim(),
                          lecturer: lecturerCtrl.text.trim(),
                          lecturerRating: 4.8,
                          capacity: 50,
                          enrolled: 35,
                          slots: [
                            ScheduleSlot(
                              dayOfWeek: 2,
                              startPeriod: 1,
                              endPeriod: 3,
                              room: roomCtrl.text.trim(),
                            ),
                          ],
                        ),
                      ];

                final courseObj = Course(
                  code: cCode,
                  name: nameCtrl.text.trim(),
                  credits: totalCredits,
                  theoryCredits: theoryCredits,
                  practiceCredits: practiceCredits,
                  department: deptCtrl.text.trim(),
                  recommendedSemester: sem,
                  category: categoryVal,
                  description: descCtrl.text.trim(),
                  prerequisites: existing?.prerequisites ?? [],
                  sections: sectionsList,
                );

                Navigator.pop(ctx);
                if (isEditing) {
                  planner.updateCourse(courseObj);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã cập nhật học phần: ${courseObj.name}'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                } else {
                  planner.addCourse(courseObj);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm học phần mới: ${courseObj.name}'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: Text(isEditing ? 'Lưu Thay Đổi' : 'Thêm Mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCourse(BuildContext context, PlannerProvider planner, Course course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa Học Phần Này?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa học phần "${course.name}" (${course.code})? Hành động này cũng sẽ loại bỏ môn khỏi phương án nếu đang được chọn.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              planner.deleteCourse(course.code);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa học phần ${course.name}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final courses = planner.filteredCourses;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditCourseDialog(context, planner),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Thêm Học Phần', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppTheme.primary,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const StatCardsHeader(),
                const ConflictBanner(),
                _buildSearchAndFilters(context, planner),
              ],
            ),
          ),
          if (courses.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 64, color: AppTheme.slate300),
                    const SizedBox(height: 12),
                    const Text(
                      'Không tìm thấy học phần phù hợp',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thử thay đổi từ khóa tìm kiếm hoặc đặt lại bộ lọc',
                      style: TextStyle(color: AppTheme.slate500, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => planner.resetFilters(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Đặt lại bộ lọc'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final course = courses[index];
                    return _CourseCard(course: course);
                  },
                  childCount: courses.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, PlannerProvider planner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm theo mã môn (CS201), tên học phần, giảng viên...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.slate400),
                    suffixIcon: planner.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => planner.setSearchQuery(''),
                          )
                        : null,
                  ),
                  onChanged: (val) => planner.setSearchQuery(val),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => planner.resetFilters(),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Đặt lại'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Dropdown Khoa
                _buildFilterDropdown<String>(
                  label: 'Khoa',
                  value: planner.selectedDepartment,
                  items: planner.allDepartments.map((d) {
                    return DropdownMenuItem(value: d, child: Text(d));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) planner.setSelectedDepartment(val);
                  },
                ),
                const SizedBox(width: 8),
                // Dropdown Số Tín chỉ
                _buildFilterDropdown<int?>(
                  label: 'Số TC',
                  value: planner.selectedCredits,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tất cả TC')),
                    DropdownMenuItem(value: 3, child: Text('3 Tín chỉ')),
                    DropdownMenuItem(value: 4, child: Text('4 Tín chỉ')),
                  ],
                  onChanged: (val) => planner.setSelectedCredits(val),
                ),
                const SizedBox(width: 8),
                // Dropdown Học kỳ gợi ý
                _buildFilterDropdown<int?>(
                  label: 'Học kỳ',
                  value: planner.selectedSemester,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tất cả HK')),
                    DropdownMenuItem(value: 3, child: Text('Học kỳ 3')),
                    DropdownMenuItem(value: 4, child: Text('Học kỳ 4')),
                    DropdownMenuItem(value: 5, child: Text('Học kỳ 5')),
                    DropdownMenuItem(value: 6, child: Text('Học kỳ 6')),
                  ],
                  onChanged: (val) => planner.setSelectedSemester(val),
                ),
                const SizedBox(width: 8),
                // Dropdown Loại Môn
                _buildFilterDropdown<CourseCategory?>(
                  label: 'Phân loại',
                  value: planner.selectedCategory,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả loại')),
                    ...CourseCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))),
                  ],
                  onChanged: (val) => planner.setSelectedCategory(val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.slate100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 12.5, color: AppTheme.slate800, fontWeight: FontWeight.w500),
          icon: const Icon(Icons.arrow_drop_down, size: 20, color: AppTheme.slate500),
          isDense: true,
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final isSelected = planner.isCourseSelected(course.code);
    final selectedSection = planner.getSelectedSectionForCourse(course.code);
    final isPassed = planner.profile.hasPassed(course.code);

    // Prerequisite status check
    bool hasMissingPrereq = false;
    for (final p in course.prerequisites) {
      if (!planner.profile.hasPassed(p)) {
        hasMissingPrereq = true;
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.5)
              : (hasMissingPrereq ? AppTheme.danger.withValues(alpha: 0.3) : AppTheme.slate200),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: ExpansionTile(
        initiallyExpanded: isSelected,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: const Border(),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isPassed
                ? AppTheme.successLight
                : (isSelected ? AppTheme.primaryLight : AppTheme.slate100),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPassed
                  ? AppTheme.success.withValues(alpha: 0.4)
                  : (isSelected ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.slate200),
            ),
          ),
          child: Center(
            child: Text(
              '${course.credits}TC',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isPassed
                    ? AppTheme.success
                    : (isSelected ? AppTheme.primary : AppTheme.slate700),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.slate100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                course.code,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.slate700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                course.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
              tooltip: 'Sửa học phần',
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              onPressed: () {
                final parent = context.findAncestorWidgetOfExactType<CourseCatalogScreen>();
                parent?._showAddEditCourseDialog(context, planner, existing: course);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.danger),
              tooltip: 'Xóa học phần',
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              onPressed: () {
                final parent = context.findAncestorWidgetOfExactType<CourseCatalogScreen>();
                parent?._confirmDeleteCourse(context, planner, course);
              },
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildTag(course.department, AppTheme.slate600, AppTheme.slate100),
              _buildTag('HK ${course.recommendedSemester}', AppTheme.primary, AppTheme.primaryLight),
              _buildTag(course.category.label, AppTheme.secondary, AppTheme.secondaryLight),
              if (isSelected && selectedSection != null)
                _buildTag('Đã chọn: ${selectedSection.id}', Colors.white, AppTheme.primary),
              if (isPassed)
                _buildTag('Đã hoàn thành', const Color(0xFF065F46), AppTheme.successLight),
              if (hasMissingPrereq)
                _buildTag('Thiếu môn tiên quyết', const Color(0xFF991B1B), AppTheme.dangerLight),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.description.isNotEmpty) ...[
                  Text(
                    course.description,
                    style: TextStyle(color: AppTheme.slate600, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                ],
                // Row details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tín chỉ: ${course.credits} TC (LT: ${course.theoryCredits} • TH: ${course.practiceCredits})',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => PrerequisiteDialog(course: course),
                        );
                      },
                      icon: const Icon(Icons.account_tree_rounded, size: 16),
                      label: Text(
                        course.prerequisites.isEmpty
                            ? 'Xem điều kiện (0)'
                            : 'Xem cây tiên quyết (${course.prerequisites.length})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                const Text(
                  'Danh sách Lớp Học Phần Mở (Chọn 1 lớp để xếp thời khóa biểu):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...course.sections.map((section) {
                  final isThisSectionSelected = selectedSection?.id == section.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isThisSectionSelected ? AppTheme.primaryLight : AppTheme.slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isThisSectionSelected ? AppTheme.primary : AppTheme.slate200,
                        width: isThisSectionSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RadioGroup<String>(
                          groupValue: selectedSection?.id,
                          onChanged: (val) {
                            if (val != null) planner.selectSection(section);
                          },
                          child: Radio<String>(
                            value: section.id,
                            activeColor: AppTheme.primary,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    section.id,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                                        const SizedBox(width: 2),
                                        Text(
                                          section.lecturerRating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Còn ${section.remainingSlots}/${section.capacity} chỗ',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: section.isFull ? AppTheme.danger : AppTheme.slate600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'GV: ${section.lecturer} • ${section.campus}',
                                style: TextStyle(color: AppTheme.slate700, fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: section.slots.map((slot) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.slate200),
                                    ),
                                    child: Text(
                                      '${slot.dayName}: Tiết ${slot.startPeriod}-${slot.endPeriod} (${slot.room})',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        if (isThisSectionSelected)
                          IconButton(
                            tooltip: 'Hủy chọn môn này',
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 20),
                            onPressed: () => planner.removeSection(course.code),
                          )
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => planner.selectSection(section),
                            child: const Text('Chọn lớp'),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
