import 'package:flutter_test/flutter_test.dart';
import 'package:uniplan_ai/services/ttn_database.dart';

void main() {
  group('Timetable Week & Day Sync Tests', () {
    test('MSSV 23103035 in Week 14: Week Schedule and Day Schedule are empty (0 classes)', () {
      final rowsW14 = TTNDatabase.getStudentTimetableRows('23103035', null, null, 14);
      expect(rowsW14.isEmpty, isTrue);

      final scheduleW14 = TTNDatabase.getStudentSchoolWeekSchedule('23103035', 14);
      expect(scheduleW14.isEmptyWeek, isTrue);
      expect(scheduleW14.totalLessonsCount, equals(0));

      // Check all days 2..8
      for (int day = 2; day <= 8; day++) {
        expect(scheduleW14.getLessons('Sáng', day).isEmpty, isTrue);
        expect(scheduleW14.getLessons('Chiều', day).isEmpty, isTrue);
        expect(scheduleW14.getLessons('Tối', day).isEmpty, isTrue);
      }
    });

    test('MSSV 23103035 in Week 12: Week Schedule and Day Schedule have 9 classes', () {
      final scheduleW12 = TTNDatabase.getStudentSchoolWeekSchedule('23103035', 12);
      expect(scheduleW12.isEmptyWeek, isFalse);
      expect(scheduleW12.totalLessonsCount, equals(9));

      // Thứ 2: Sáng có LS Đảng
      final t2Morning = scheduleW12.getLessons('Sáng', 2);
      expect(t2Morning.length, equals(1));
      expect(t2Morning.first.courseName.contains('LS Đảng'), isTrue);
    });
  });
}
