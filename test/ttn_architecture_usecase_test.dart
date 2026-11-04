import 'package:flutter_test/flutter_test.dart';
import 'package:uniplan_ai/domain/models/timetable_models.dart';
import 'package:uniplan_ai/domain/usecases/schedule_generator_usecase.dart';
import 'package:uniplan_ai/data/parsers/ttn_timetable_parser.dart';
import 'package:uniplan_ai/services/ttn_database.dart';

void main() {
  group('Kiến trúc ĐH Tây Nguyên - Parser & Models Test', () {
    test('TtnTimetableParser parses standard TTN time string correctly', () {
      const raw = 'Thứ 3, Tiết 1-3, Nhà G2-P102';
      final slot = TtnTimetableParser.parseSingleSlot(raw, defaultLecturer: 'ThS. Nguyễn Văn A');
      
      expect(slot, isNotNull);
      expect(slot!.dayOfWeek, equals(3));
      expect(slot.startPeriod, equals(1));
      expect(slot.periodCount, equals(3));
      expect(slot.endPeriod, equals(3));
      expect(slot.room, contains('G2-P102'));
      expect(slot.isMorning, isTrue);
    });

    test('TtnTimetableParser parses multiple slots', () {
      const raw = 'Thứ 2, Tiết 1-3, G2-101; Thứ 5, Tiết 6-8, Lab 4.1';
      final slots = TtnTimetableParser.parseMultipleSlots(raw);

      expect(slots.length, equals(2));
      expect(slots[0].dayOfWeek, equals(2));
      expect(slots[0].isMorning, isTrue);
      expect(slots[1].dayOfWeek, equals(5));
      expect(slots[1].isAfternoon, isTrue);
    });

    test('Conflict Detection between overlapping TimeSlots', () {
      const slotA = TimeSlot(dayOfWeek: 2, startPeriod: 1, periodCount: 3); // 1, 2, 3
      const slotB = TimeSlot(dayOfWeek: 2, startPeriod: 3, periodCount: 2); // 3, 4
      const slotC = TimeSlot(dayOfWeek: 2, startPeriod: 4, periodCount: 2); // 4, 5
      const slotD = TimeSlot(dayOfWeek: 3, startPeriod: 1, periodCount: 3); // Khác ngày

      expect(slotA.overlapsWith(slotB), isTrue, reason: 'Trùng Tiết 3');
      expect(slotA.overlapsWith(slotC), isFalse, reason: 'Không giao nhau');
      expect(slotA.overlapsWith(slotD), isFalse, reason: 'Khác thứ trong tuần');
    });
  });

  group('CSP Backtracking & Schedule Generator Use Case', () {
    test('Backtracking resolves Theory and Practice bundles without overlap', () async {
      final courses = [
        Course(
          courseCode: '4110034',
          courseName: 'Cấu trúc dữ liệu và giải thuật',
          credits: 4,
          theoryCredits: 3,
          practiceCredits: 1,
          sections: [
            // Nhóm 1: LT Thứ 2 tiết 1-3, có 2 tổ TH (Tổ 1: T4 tiết 1-2, Tổ 2: T2 tiết 2-3 trùng)
            const ClassSection(
              classId: '4110034_01',
              sectionName: 'Nhóm 01 - LT',
              courseCode: '4110034',
              courseName: 'Cấu trúc dữ liệu và giải thuật',
              sectionType: SectionType.theory,
              timeSlots: [TimeSlot(dayOfWeek: 2, startPeriod: 1, periodCount: 3)],
            ),
            const ClassSection(
              classId: '4110034_01_TH01',
              sectionName: 'Tổ 01 - TH',
              courseCode: '4110034',
              courseName: 'Cấu trúc dữ liệu và giải thuật',
              sectionType: SectionType.practice,
              parentTheoryClassId: '4110034_01',
              timeSlots: [TimeSlot(dayOfWeek: 4, startPeriod: 1, periodCount: 2)],
            ),
          ],
        ),
        Course(
          courseCode: '4110055',
          courseName: 'Cơ sở dữ liệu',
          credits: 3,
          theoryCredits: 3,
          sections: [
            const ClassSection(
              classId: '4110055_01',
              sectionName: 'Nhóm 01 - LT',
              courseCode: '4110055',
              courseName: 'Cơ sở dữ liệu',
              sectionType: SectionType.theory,
              timeSlots: [TimeSlot(dayOfWeek: 3, startPeriod: 6, periodCount: 3)],
            ),
          ],
        ),
      ];

      const constraints = ScheduleConstraints(
        avoidMorning: false,
        freeFriday: true,
        freeSaturday: true,
      );

      final solutions = await ScheduleGeneratorUseCase.executeAsync(
        targetCourses: courses,
        constraints: constraints,
      );

      expect(solutions, isNotEmpty);
      final topPlan = solutions.first;
      expect(topPlan.selectedSections.length, equals(3)); // 1 LT + 1 TH môn 1, 1 LT môn 2
      expect(topPlan.totalCredits, equals(7));
      expect(topPlan.oneClickRegistrationCodes, contains('4110034_01'));
      expect(topPlan.oneClickRegistrationCodes, contains('4110034_01_TH01'));
      expect(topPlan.oneClickRegistrationCodes, contains('4110055_01'));
    });
  });

  group('TTNDatabase - Lịch học & Lịch thi động chuẩn xác cho mọi mã sinh viên', () {
    test('Sinh viên 23103035 (Mai Đàm Thế Kiên) khớp 100% ảnh thời khóa biểu Cổng TTN (9 buổi học)', () {
      final rows = TTNDatabase.getStudentTimetableRows('23103035');
      expect(rows.length, equals(9));

      // Kiểm tra có đầy đủ các môn học thực tế
      final titles = rows.map((r) => r['name'].toString()).toList();
      expect(titles.any((t) => t.contains('LS Đảng')), isTrue);
      expect(titles.any((t) => t.contains('Tâm lý học')), isTrue);
      expect(titles.any((t) => t.contains('Lập trình di động')), isTrue);
      expect(titles.any((t) => t.contains('An toàn thông tin')), isTrue);
      expect(titles.any((t) => t.contains('QTM trên MT')), isTrue);
      expect(titles.any((t) => t.contains('Thương mại điện tử')), isTrue);
      expect(titles.any((t) => t.contains('Những VĐ HĐ')), isTrue);
      expect(titles.any((t) => t.contains('CN trình đa nền')), isTrue);
    });

    test('Sinh viên chưa có lịch học (23103005) trả về danh sách rỗng, không chèn môn ảo', () {
      final rows = TTNDatabase.getStudentTimetableRows('23103005');
      expect(rows, isEmpty);
    });

    test('Lịch thi khớp 100% ảnh 8 môn thi của Mai Đàm Thế Kiên (23103035)', () {
      // 1. An toàn thông tin: Sáng 04/02/2027 P.6.12
      final attt = TTNDatabase.getExamScheduleForCourse('KC213613', '23103035');
      expect(attt['buoi1'], equals('Sáng'));
      expect(attt['ngay1'], equals('04/02/2027'));
      expect(attt['phong1'], equals('P.6.12'));

      // 2. QTM trên MT: Chiều 08/02/2027 Lab Mạng 2
      final qtm = TTNDatabase.getExamScheduleForCourse('KC213668', '23103035');
      expect(qtm['buoi1'], equals('Chiều'));
      expect(qtm['ngay1'], equals('08/02/2027'));
      expect(qtm['phong1'], equals('Lab Mạng 2'));

      // 3. Thương mại điện tử: Sáng 06/02/2027 P.8.1.7
      final tmdt = TTNDatabase.getExamScheduleForCourse('KC213678', '23103035');
      expect(tmdt['buoi1'], equals('Sáng'));
      expect(tmdt['ngay1'], equals('06/02/2027'));
      expect(tmdt['phong1'], equals('P.8.1.7'));

      // 4. Những VĐ HĐ CNTT: Sáng 26/01/2027 P.7.3.18
      final vdhd = TTNDatabase.getExamScheduleForCourse('KC213685', '23103035');
      expect(vdhd['buoi1'], equals('Sáng'));
      expect(vdhd['ngay1'], equals('26/01/2027'));
      expect(vdhd['phong1'], equals('P.7.3.18'));

      // 5. Lập trình di động: Chiều 23/01/2027 Lab 7.3.18
      final ltdd = TTNDatabase.getExamScheduleForCourse('KC215046', '23103035');
      expect(ltdd['buoi1'], equals('Chiều'));
      expect(ltdd['ngay1'], equals('23/01/2027'));
      expect(ltdd['phong1'], equals('Lab 7.3.18'));

      // 6. CN trình đa nền: Chiều 10/02/2027 Lab 7.3.16
      final danen = TTNDatabase.getExamScheduleForCourse('KC215050', '23103035');
      expect(danen['buoi1'], equals('Chiều'));
      expect(danen['ngay1'], equals('10/02/2027'));
      expect(danen['phong1'], equals('Lab 7.3.16'));

      // 7. LS Đảng: Sáng 18/01/2027 P.6.11
      final dang = TTNDatabase.getExamScheduleForCourse('ML211033', '23103035');
      expect(dang['buoi1'], equals('Sáng'));
      expect(dang['ngay1'], equals('18/01/2027'));
      expect(dang['phong1'], equals('P.6.11'));

      // 8. Tâm lý học: Sáng 20/01/2027 P.2.4
      final tlh = TTNDatabase.getExamScheduleForCourse('SP211014', '23103035');
      expect(tlh['buoi1'], equals('Sáng'));
      expect(tlh['ngay1'], equals('20/01/2027'));
      expect(tlh['phong1'], equals('P.2.4'));
    });

    test('Sinh viên chưa được trường xếp lịch thi trả về rỗng (chờ thông báo)', () {
      final exam = TTNDatabase.getExamScheduleForCourse('KC217999', '23772018');
      expect(exam['ngay1'], isEmpty);
      expect(exam['phong1'], isEmpty);
    });

    test('Điểm TBCTL (GPA) Mai Đàm Thế Kiên chuẩn 100% Cổng TTN (2.17)', () {
      final gpa = TTNDatabase.calculateGpaForStudent('23103035');
      expect(gpa, equals(2.17));
    });
  });
}

