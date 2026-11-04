import 'package:flutter_test/flutter_test.dart';
import 'package:uniplan_ai/services/ttn_database.dart';
import 'package:uniplan_ai/domain/models/student_deadline_task.dart';
import 'package:uniplan_ai/providers/planner_provider.dart';

void main() {
  group('UniPlan CRUD Features Tests', () {
    test('1. Student CRUD: Thêm, Sửa, Xóa sinh viên', () {
      const testMsv = '99999999';

      // Create
      TTNDatabase.addCustomStudent(
        studentId: testMsv,
        fullName: 'Nguyễn Văn Test',
        major: 'Kỹ thuật phần mềm',
        cohort: 'K24',
      );
      final student = TTNDatabase.getStudent(testMsv);
      expect(student, isNotNull);
      expect(student!['fullName'], equals('Nguyễn Văn Test'));
      expect(student['major'], equals('Kỹ thuật phần mềm'));

      // Update
      TTNDatabase.updateStudent(
        studentId: testMsv,
        fullName: 'Nguyễn Văn Đã Sửa',
        major: 'Công nghệ thông tin',
        cohort: 'K23',
      );
      final updated = TTNDatabase.getStudent(testMsv);
      expect(updated!['fullName'], equals('Nguyễn Văn Đã Sửa'));
      expect(updated['major'], equals('Công nghệ thông tin'));

      // Delete
      TTNDatabase.deleteStudent(testMsv);
      expect(TTNDatabase.students.containsKey(testMsv), isFalse);
    });

    test('2. Timetable CRUD: Thêm, Sửa, Xóa sự kiện và môn học thời khóa biểu', () {
      const testMsv = '23103035';
      const eventId = 'test_evt_101';

      // Create
      final newEvent = {
        'id': eventId,
        'khid': eventId,
        'name': 'Học Bù Trí Tuệ Nhân Tạo (4)',
        'rawTitle': 'Học Bù Trí Tuệ Nhân Tạo',
        'day': 3,
        'session': 'Sáng',
        'period': '1-4',
        'room': 'P.Lab 5',
        'lecturer': 'TS. Test GV',
        'activeWeeks': const [14],
        'isCustom': true,
      };
      TTNDatabase.addCustomTimetableEvent(testMsv, newEvent);

      // Verify in getStudentTimetableRows
      final rowsW14 = TTNDatabase.getStudentTimetableRows(testMsv, null, null, 14);
      expect(rowsW14.any((r) => r['id'] == eventId), isTrue);

      // Verify in SchoolWeekSchedule
      final weekSchedule = TTNDatabase.getStudentSchoolWeekSchedule(testMsv, 14);
      final t3Lessons = weekSchedule.getLessons('Sáng', 3);
      expect(t3Lessons.any((l) => l.courseName.contains('Học Bù Trí Tuệ Nhân Tạo')), isTrue);

      // Update
      final updatedEvent = Map<String, dynamic>.from(newEvent);
      updatedEvent['room'] = 'P.Lab 9';
      TTNDatabase.updateCustomTimetableEvent(testMsv, eventId, updatedEvent);
      final rowsUpdated = TTNDatabase.getStudentTimetableRows(testMsv, null, null, 14);
      final updatedItem = rowsUpdated.firstWhere((r) => r['id'] == eventId);
      expect(updatedItem['room'], equals('P.Lab 9'));

      // Delete
      TTNDatabase.deleteCustomTimetableEvent(testMsv, eventId);
      final rowsAfterDelete = TTNDatabase.getStudentTimetableRows(testMsv, null, null, 14);
      expect(rowsAfterDelete.any((r) => r['id'] == eventId), isFalse);
    });

    test('3. Deadlines CRUD: Thêm, Sửa, Hoàn thành, Xóa Deadline & Nhiệm vụ', () {
      const testMsv = '23103035';
      final taskId = 'task_${DateTime.now().millisecondsSinceEpoch}';

      // Create
      final task = StudentDeadlineTask(
        id: taskId,
        studentId: testMsv,
        title: 'Nộp báo cáo thử nghiệm CRUD',
        courseName: 'Lập trình di động',
        dueDate: DateTime.now().add(const Duration(days: 4)),
        priority: 'Cao',
        notes: 'Ghi chú kiểm thử',
      );
      TTNDatabase.addDeadlineTask(testMsv, task);

      final deadlines = TTNDatabase.getStudentDeadlines(testMsv);
      expect(deadlines.any((d) => d.id == taskId), isTrue);

      // Toggle Complete
      expect(task.isCompleted, isFalse);
      TTNDatabase.toggleDeadlineTask(testMsv, taskId);
      expect(task.isCompleted, isTrue);

      // Update
      task.title = 'Nộp báo cáo thử nghiệm CRUD ĐÃ SỬA';
      TTNDatabase.updateDeadlineTask(testMsv, task);
      final updatedTask = deadlines.firstWhere((d) => d.id == taskId);
      expect(updatedTask.title, equals('Nộp báo cáo thử nghiệm CRUD ĐÃ SỬA'));

      // Delete
      TTNDatabase.deleteDeadlineTask(testMsv, taskId);
      final remaining = TTNDatabase.getStudentDeadlines(testMsv);
      expect(remaining.any((d) => d.id == taskId), isFalse);
    });

    test('4. Plans CRUD: Thêm, Đổi tên, Xóa phương án đăng ký', () async {
      final planner = PlannerProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // Đảm bảo có ít nhất 2 plans
      planner.createNewPlan(name: 'Phương Án Test 1');
      planner.createNewPlan(name: 'Phương Án Test 2');
      final plan2Id = planner.activePlanId;
      expect(planner.activePlan.name, equals('Phương Án Test 2'));

      // Rename
      planner.renamePlan(plan2Id, 'Phương Án Đã Đổi Tên', 'Mô tả mới');
      expect(planner.activePlan.name, equals('Phương Án Đã Đổi Tên'));

      // Delete plan2
      planner.deletePlan(plan2Id);
      expect(planner.plans.any((p) => p.id == plan2Id), isFalse);
    });
  });
}
