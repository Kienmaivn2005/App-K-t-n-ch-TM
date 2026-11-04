import '../models/course.dart';
import '../models/plan.dart';

class MockDataService {
  static const List<int> coursePalette = [
    0xFF2563EB, // Royal Blue
    0xFF7C3AED, // Violet
    0xFF059669, // Emerald Green
    0xFFD97706, // Amber
    0xFFDC2626, // Crimson Red
    0xFF0891B2, // Cyan
    0xFF4F46E5, // Indigo
    0xFFDB2777, // Pink
    0xFF0D9488, // Teal
    0xFFEA580C, // Orange
    0xFF475569, // Slate
    0xFF65A30D, // Lime
  ];

  /// Danh mục đầy đủ đúng 90 học phần trong Chương trình đào tạo CNTT ĐH Tây Nguyên (Khớp 100% Cổng TTN)
  static List<Map<String, dynamic>>? _cachedBaseCurriculum;

  static List<Map<String, dynamic>> getTayNguyenCurriculum() {
    if (_cachedBaseCurriculum != null) return _cachedBaseCurriculum!;
    return _cachedBaseCurriculum = [
      {'tt': 1, 'code': 'SP211105', 'name': 'Tiếng Việt nâng cao(2.0)', 'credits': 2, 'score': null},
      {'tt': 2, 'code': 'SP211106', 'name': 'Văn hóa Việt Nam (3.0)', 'credits': 3, 'score': null},
      {'tt': 3, 'code': 'SP211107', 'name': 'Lịch sử Việt Nam(3.0)', 'credits': 3, 'score': null},
      {'tt': 4, 'code': 'FL211011', 'name': 'Tiếng Anh 1(3.0)', 'credits': 3, 'score': 5.6},
      {'tt': 5, 'code': 'KC211027', 'name': 'Tin học đại cương(2.0)', 'credits': 2, 'score': 6.1},
      {'tt': 6, 'code': 'KC211685', 'name': 'Toán cho Công nghệ thông tin', 'credits': 3, 'score': 6.0},
      {'tt': 7, 'code': 'KC212604', 'name': 'Kỹ thuật lập trình(2.0)', 'credits': 2, 'score': 7.5},
      {'tt': 8, 'code': 'KC212681', 'name': 'Nhập môn ngành công nghệ t', 'credits': 2, 'score': 7.0},
      {'tt': 9, 'code': 'KC212682', 'name': 'Thực hành Kỹ thuật lập trình(', 'credits': 1, 'score': 6.7},
      {'tt': 10, 'code': 'KT212202', 'name': 'Kỹ năng mềm(2.0)', 'credits': 2, 'score': 8.2},
      {'tt': 11, 'code': 'SP211032', 'name': 'Thể dục cơ bản và điền kinh(', 'credits': 1, 'score': 10.0},
      {'tt': 12, 'code': 'SP211039', 'name': 'Cờ vua 1(1.0)', 'credits': 1, 'score': null},
      {'tt': 13, 'code': 'FL211012', 'name': 'Tiếng Anh 2(3.0)', 'credits': 3, 'score': 6.6},
      {'tt': 14, 'code': 'KC211604', 'name': 'Lý thuyết thông tin(2.0)', 'credits': 2, 'score': 7.9},
      {'tt': 15, 'code': 'KC212601', 'name': 'Cấu trúc rời rạc(2.0)', 'credits': 2, 'score': 5.7},
      {'tt': 16, 'code': 'KC212602', 'name': 'Tổ chức máy tính(3.0)', 'credits': 3, 'score': 5.4},
      {'tt': 17, 'code': 'KC215037', 'name': 'Cấu trúc dữ liệu và giải thuật(', 'credits': 3, 'score': 10.0},
      {'tt': 18, 'code': 'NL211702', 'name': 'Pháp luật Việt Nam đại cương', 'credits': 2, 'score': 4.5},
      {'tt': 19, 'code': 'SP211006', 'name': 'Xã hội học đại cương(2.0)', 'credits': 2, 'score': null},
      {'tt': 20, 'code': 'SP211033', 'name': 'Bóng chuyền cơ bản(1.0)', 'credits': 1, 'score': null},
      {'tt': 21, 'code': 'SP211034', 'name': 'Bơi lội cơ bản(1.0)', 'credits': 1, 'score': null},
      {'tt': 22, 'code': 'SP211035', 'name': 'Cầu lông cơ bản(1.0)', 'credits': 1, 'score': 7.0},
      {'tt': 23, 'code': 'SP211040', 'name': 'Cờ vua 2(1.0)', 'credits': 1, 'score': null},
      {'tt': 24, 'code': 'SP211042', 'name': 'Bóng bàn cơ bản(1.0)', 'credits': 1, 'score': null},
      {'tt': 25, 'code': 'FL211013', 'name': 'Tiếng Anh 3(3.0)', 'credits': 3, 'score': 6.2},
      {'tt': 26, 'code': 'KC212605', 'name': 'Cơ sở dữ liệu(3.0)', 'credits': 3, 'score': 5.8},
      {'tt': 27, 'code': 'KC212686', 'name': 'Thực tế nghề nghiệp(1.0)', 'credits': 1, 'score': 8.5},
      {'tt': 28, 'code': 'KC215039', 'name': 'Nhập môn mạng máy tính(3.0', 'credits': 3, 'score': 7.5},
      {'tt': 29, 'code': 'ML211030', 'name': 'Triết học Mác - Lênin(3.0)', 'credits': 3, 'score': 6.5},
      {'tt': 30, 'code': 'KC213611', 'name': 'Lập trình hướng đối tượng(3.', 'credits': 3, 'score': 6.2},
      {'tt': 31, 'code': 'KC215040', 'name': 'Lập trình Windows(3.0)', 'credits': 3, 'score': null},
      {'tt': 32, 'code': 'SP211036', 'name': 'Thể dục nhịp điệu cơ bản(1.0', 'credits': 1, 'score': null},
      {'tt': 33, 'code': 'SP211037', 'name': 'Taekwondo cơ bản(1.0)', 'credits': 1, 'score': null},
      {'tt': 34, 'code': 'SP211038', 'name': 'Bóng đá cơ bản(1.0)', 'credits': 1, 'score': 6.8},
      {'tt': 35, 'code': 'SP211041', 'name': 'Cờ vua 3(1.0)', 'credits': 1, 'score': null},
      {'tt': 36, 'code': 'SP211043', 'name': 'Bóng rổ cơ bản(1.0)', 'credits': 1, 'score': null},
      {'tt': 37, 'code': 'FL211014', 'name': 'Tiếng Anh 4(3.0)', 'credits': 3, 'score': 6.8},
      {'tt': 38, 'code': 'KC211006', 'name': 'Xác suất thống kê(2.0)', 'credits': 2, 'score': 6.5},
      {'tt': 39, 'code': 'KC213608', 'name': 'Nhập môn kỹ nghệ phần mềm(3.0)', 'credits': 3, 'score': 7.5},
      {'tt': 40, 'code': 'KC215036', 'name': 'Phương pháp NCKH CNTT(2.0)', 'credits': 2, 'score': 8.5},
      {'tt': 41, 'code': 'KC215038', 'name': 'Thiết kế và lập trình Web cơ bản(3.0)', 'credits': 3, 'score': 8.0},
      {'tt': 42, 'code': 'KC215042', 'name': 'Lập trình Python(3.0)', 'credits': 3, 'score': 8.4},
      {'tt': 43, 'code': 'ML211031', 'name': 'Kinh tế chính trị Mác - Lênin(2.0)', 'credits': 2, 'score': 6.5},
      {'tt': 44, 'code': 'KC211615', 'name': 'Tiếng Anh Chuyên ngành CNTT(2.0)', 'credits': 2, 'score': 7.0},
      {'tt': 45, 'code': 'KC211682', 'name': 'Cơ sở vật lý cho Tin học(2.0)', 'credits': 2, 'score': 6.2},
      {'tt': 46, 'code': 'KC213607', 'name': 'Phân tích thiết kế hệ thống(3.0)', 'credits': 3, 'score': 7.8},
      {'tt': 47, 'code': 'KC213682', 'name': 'Hệ quản trị cơ sở dữ liệu(3.0)', 'credits': 3, 'score': 7.5},
      {'tt': 48, 'code': 'KC215044', 'name': 'Thiết kế và lập trình Web nâng cao(3.0)', 'credits': 3, 'score': 8.2},
      {'tt': 49, 'code': 'KT213007', 'name': 'Khởi nghiệp(2.0)', 'credits': 2, 'score': 8.5},
      {'tt': 50, 'code': 'ML211032', 'name': 'Chủ nghĩa xã hội khoa học(2.0)', 'credits': 2, 'score': 7.0},
      {'tt': 51, 'code': 'KC213609', 'name': 'Trí tuệ nhân tạo(2.0)', 'credits': 2, 'score': 7.8},
      {'tt': 52, 'code': 'KC213667', 'name': 'Nhập môn Hệ điều hành(2.0)', 'credits': 2, 'score': 7.2},
      {'tt': 53, 'code': 'KC215041', 'name': 'Xử lý ảnh số(3.0)', 'credits': 3, 'score': 7.5},
      {'tt': 54, 'code': 'KC215043', 'name': 'Lập trình ứng dụng mã nguồn mở(3.0)', 'credits': 3, 'score': 8.0},
      {'tt': 55, 'code': 'ML211002', 'name': 'Tư tưởng Hồ Chí Minh(2.0)', 'credits': 2, 'score': 7.5},
      {'tt': 56, 'code': 'QP211006', 'name': 'Công tác quốc phòng - An ninh', 'credits': 2, 'score': 7.1},
      {'tt': 57, 'code': 'QP211011', 'name': 'Đường lối quốc phòng và an n', 'credits': 3, 'score': 7.8},
      {'tt': 58, 'code': 'QP211012', 'name': 'Quân sự chung(1.0)', 'credits': 1, 'score': 7.8},
      {'tt': 59, 'code': 'QP211013', 'name': 'Kỹ thuật chiến đấu bộ binh và', 'credits': 2, 'score': 7.4},
      {'tt': 60, 'code': 'KC213629', 'name': 'Phát triển phần mềm hướng đ', 'credits': 2, 'score': null},
      {'tt': 61, 'code': 'KC213633', 'name': 'Các quy trình phát triển phần', 'credits': 2, 'score': 8.0},
      {'tt': 62, 'code': 'KC213613', 'name': 'An toàn thông tin(2.0)', 'credits': 2, 'score': null},
      {'tt': 63, 'code': 'KC213685', 'name': 'Những vấn đề hiện đại của CN', 'credits': 2, 'score': null},
      {'tt': 64, 'code': 'ML211033', 'name': 'Lịch sử Đảng Cộng sản Việt N', 'credits': 2, 'score': null},
      {'tt': 65, 'code': 'KC213619', 'name': 'Lập trình mạng(2.0)', 'credits': 2, 'score': null},
      {'tt': 66, 'code': 'KC213630', 'name': 'Quản lý dự án CN thông tin(2.', 'credits': 2, 'score': null},
      {'tt': 67, 'code': 'KC213635', 'name': 'CSDL phân tán(2.0)', 'credits': 2, 'score': null},
      {'tt': 68, 'code': 'KC213661', 'name': 'Quản trị mạng Linux(2.0)', 'credits': 2, 'score': null},
      {'tt': 69, 'code': 'KC213668', 'name': 'Quản trị mạng trên môi trường', 'credits': 2, 'score': null},
      {'tt': 70, 'code': 'KC213676', 'name': 'Đảm bảo chất lượng phần mề', 'credits': 2, 'score': null},
      {'tt': 71, 'code': 'KC213678', 'name': 'Thương mại điện tử(2.0)', 'credits': 2, 'score': null},
      {'tt': 72, 'code': 'KC213679', 'name': 'Mạng máy tính nâng cao(2.0)', 'credits': 2, 'score': null},
      {'tt': 73, 'code': 'KC215046', 'name': 'Lập trình di động(3.0)', 'credits': 3, 'score': null},
      {'tt': 74, 'code': 'KC215047', 'name': 'Phát triển ứng dụng web(3.0)', 'credits': 3, 'score': null},
      {'tt': 75, 'code': 'KC215048', 'name': 'Kiểm thử phần mềm(3.0)', 'credits': 3, 'score': null},
      {'tt': 76, 'code': 'KC215049', 'name': 'Hệ quản trị CSDL NoSQL(3.0)', 'credits': 3, 'score': null},
      {'tt': 77, 'code': 'KC215050', 'name': 'Công nghệ lập trình đa nền tả', 'credits': 3, 'score': null},
      {'tt': 78, 'code': 'KC215051', 'name': 'Thiết kế mạng(3.0)', 'credits': 3, 'score': null},
      {'tt': 79, 'code': 'KC215052', 'name': 'Điện toán đám mây(3.0)', 'credits': 3, 'score': null},
      {'tt': 80, 'code': 'SP211001', 'name': 'Tiếng Việt thực hành(2.0)', 'credits': 2, 'score': null},
      {'tt': 81, 'code': 'SP211003', 'name': 'Cơ sở văn hóa Việt Nam(2.0)', 'credits': 2, 'score': null},
      {'tt': 82, 'code': 'SP211014', 'name': 'Tâm lý học đại cương(2.0)', 'credits': 2, 'score': null},
      {'tt': 83, 'code': 'KC215045', 'name': 'Thực tập nghề nghiệp(5.0)', 'credits': 5, 'score': null},
      {'tt': 84, 'code': 'KC213647', 'name': 'Khai phá dữ liệu(2.0)', 'credits': 2, 'score': null},
      {'tt': 85, 'code': 'KC213660', 'name': 'Digital marketing(2.0)', 'credits': 2, 'score': null},
      {'tt': 86, 'code': 'KC213669', 'name': 'Phát triển ứng dụng Internet o', 'credits': 2, 'score': null},
      {'tt': 87, 'code': 'KC213696', 'name': 'Phân tích dữ liệu(2.0)', 'credits': 2, 'score': null},
      {'tt': 88, 'code': 'KC215698', 'name': 'Chuyên đề tốt nghiệp(4.0)', 'credits': 4, 'score': null},
      {'tt': 89, 'code': 'KC215699', 'name': 'Khóa luận tốt nghiệp(10.0)', 'credits': 10, 'score': null},
      {'tt': 90, 'code': 'KC217003', 'name': 'Công nghệ .Net(2.0)', 'credits': 2, 'score': null},
    ];
  }

  /// Danh sách học phần giảng dạy & lớp học phần Đại học Tây Nguyên
  static List<Course> getSampleCourses() {
    return [
      // 1. Kỹ thuật lập trình
      Course(
        code: 'KC212604',
        name: 'Kỹ thuật lập trình',
        credits: 2,
        theoryCredits: 2,
        practiceCredits: 0,
        department: 'Khoa Công nghệ thông tin',
        recommendedSemester: 3,
        category: CourseCategory.foundation,
        prerequisites: ['KC211027'],
        description: 'Con trỏ, cấp phát động, đệ quy, xử lý tập tin, cấu trúc struct và giải thuật lập trình nâng cao trong C/C++.',
        sections: [
          const ClassSection(
            id: 'KC212604_76098',
            courseCode: 'KC212604',
            courseName: 'Kỹ thuật lập trình (2.0/0.0)',
            lecturer: 'ThS. Nguyễn Văn Hải',
            lecturerRating: 4.6,
            capacity: 130,
            enrolled: 7,
            campus: 'Cơ sở chính',
            colorHex: 0xFF2563EB,
            slots: [
              ScheduleSlot(dayOfWeek: 2, startPeriod: 6, endPeriod: 8, room: '3.1.05'),
            ],
          ),
          const ClassSection(
            id: 'KC212604_76099',
            courseCode: 'KC212604',
            courseName: 'Kỹ thuật lập trình (2.0/0.0)',
            lecturer: 'TS. Phan Thanh Bình',
            lecturerRating: 4.8,
            capacity: 80,
            enrolled: 65,
            campus: 'Cơ sở chính',
            colorHex: 0xFF2563EB,
            slots: [
              ScheduleSlot(dayOfWeek: 4, startPeriod: 6, endPeriod: 8, room: '3.1.06'),
            ],
          ),
        ],
      ),

      // 2. An toàn thông tin
      Course(
        code: 'KC213613',
        name: 'An toàn thông tin',
        credits: 2,
        theoryCredits: 2,
        practiceCredits: 0,
        department: 'Khoa Công nghệ thông tin',
        recommendedSemester: 5,
        category: CourseCategory.specializedMandatory,
        prerequisites: ['KC215039'],
        description: 'Mật mã học, an toàn dữ liệu, chữ ký số, tường lửa và chính sách bảo mật mạng doanh nghiệp.',
        sections: [
          const ClassSection(
            id: 'KC213613_74293',
            courseCode: 'KC213613',
            courseName: 'An toàn thông tin (2.0/0.0)',
            lecturer: 'ThS. Trần Đình Hưng',
            lecturerRating: 4.7,
            capacity: 70,
            enrolled: 67,
            campus: 'Cơ sở chính',
            colorHex: 0xFF7C3AED,
            slots: [
              ScheduleSlot(dayOfWeek: 3, startPeriod: 6, endPeriod: 8, room: '6.12'),
            ],
          ),
        ],
      ),

      // 3. Quản trị mạng trên môi trường Windows
      Course(
        code: 'KC213668',
        name: 'Quản trị mạng trên MT Windows',
        credits: 2,
        theoryCredits: 1,
        practiceCredits: 1,
        department: 'Khoa Công nghệ thông tin',
        recommendedSemester: 5,
        category: CourseCategory.specializedElective,
        prerequisites: ['KC215039'],
        description: 'Triển khai Windows Server, Active Directory, DNS, DHCP, phân quyền Group Policy và bảo mật hạ tầng mạng.',
        sections: [
          const ClassSection(
            id: 'KC213668_74310',
            courseCode: 'KC213668',
            courseName: 'QTM trên MT Windows (1.5/0.5)',
            lecturer: 'ThS. Lê Hoàng Long',
            lecturerRating: 4.6,
            capacity: 65,
            enrolled: 62,
            campus: 'Cơ sở chính',
            colorHex: 0xFF059669,
            slots: [
              ScheduleSlot(dayOfWeek: 4, startPeriod: 6, endPeriod: 9, room: 'Lab Mạng 2'),
            ],
          ),
        ],
      ),

      // 4. Thương mại điện tử
      Course(
        code: 'KC213678',
        name: 'Thương mại điện tử',
        credits: 2,
        theoryCredits: 2,
        practiceCredits: 0,
        department: 'Khoa Công nghệ thông tin',
        recommendedSemester: 5,
        category: CourseCategory.specializedElective,
        prerequisites: [],
        description: 'Các mô hình kinh doanh số B2B, B2C, cổng thanh toán trực tuyến, logistics số và pháp lý thương mại điện tử.',
        sections: [
          const ClassSection(
            id: 'KC213678_74306',
            courseCode: 'KC213678',
            courseName: 'Thương mại điện tử (2.0/0.0)',
            lecturer: 'TS. Nguyễn Thị Mai Lan',
            lecturerRating: 4.85,
            capacity: 70,
            enrolled: 63,
            campus: 'Cơ sở chính',
            colorHex: 0xFFD97706,
            slots: [
              ScheduleSlot(dayOfWeek: 5, startPeriod: 6, endPeriod: 8, room: '3.2.04'),
            ],
          ),
        ],
      ),

      // 5. Những vấn đề hiện đại của CNTT
      Course(
        code: 'KC213685',
        name: 'Những VĐ hiện đại của CNTT',
        credits: 2,
        theoryCredits: 2,
        practiceCredits: 0,
        department: 'Khoa Công nghệ thông tin',
        recommendedSemester: 5,
        category: CourseCategory.specializedMandatory,
        prerequisites: [],
        description: 'Điện toán đám mây Cloud Computing, Trí tuệ nhân tạo sinh mẫu Generative AI, Big Data và IoT ứng dụng.',
        sections: [
          const ClassSection(
            id: 'KC213685_74292',
            courseCode: 'KC213685',
            courseName: 'Những VD HD của CNTT (2.0/0.0)',
            lecturer: 'Trương Thị Hương Giang',
            lecturerRating: 4.9,
            capacity: 70,
            enrolled: 63,
            campus: 'Cơ sở chính',
            colorHex: 0xFFDC2626,
            slots: [
              ScheduleSlot(dayOfWeek: 6, startPeriod: 1, endPeriod: 3, room: '7.3.18'),
            ],
          ),
        ],
      ),

      // 6. Lập trình di động
      Course(
        code: 'KC215046',
        name: 'Lập trình di động',
        credits: 3,
        theoryCredits: 2,
        practiceCredits: 1,
        department: 'Khoa Công nghệ thông tin',
        recommendedSemester: 5,
        category: CourseCategory.specializedMandatory,
        prerequisites: ['KC213611'],
        description: 'Phát triển ứng dụng Android/iOS với kiến trúc MVVM, kết nối RESTful API, lưu trữ Room/SQLite và thông báo đẩy Push Notifications.',
        sections: [
          const ClassSection(
            id: 'KC215046_74297',
            courseCode: 'KC215046',
            courseName: 'Lập trình di động (2.0/1.0)',
            lecturer: 'Trương Thị Hương Giang',
            lecturerRating: 4.95,
            capacity: 65,
            enrolled: 59,
            campus: 'Cơ sở chính',
            colorHex: 0xFF0891B2,
            slots: [
              ScheduleSlot(dayOfWeek: 4, startPeriod: 1, endPeriod: 4, room: '7.3.18'),
            ],
          ),
        ],
      ),

      // 7. Công nghệ lập trình đa nền tảng
      Course(
        code: 'KC215050',
        name: 'Công nghệ lập trình đa nền tảng',
        credits: 3,
        theoryCredits: 2,
        practiceCredits: 1,
        department: 'Khoa Công nghệ thông tin',
        recommendedSemester: 5,
        category: CourseCategory.specializedMandatory,
        prerequisites: ['KC213611'],
        description: 'Lập trình ứng dụng đa nền tảng với Flutter và React Native, quản trị state, tối ưu hiệu năng UI 60fps và xuất bản ứng dụng đa nền.',
        sections: [
          const ClassSection(
            id: 'KC215050_74301',
            courseCode: 'KC215050',
            courseName: 'CN trình đa nền (2.0/1.0)',
            lecturer: 'ThS. Bùi Văn Hùng',
            lecturerRating: 4.8,
            capacity: 65,
            enrolled: 59,
            campus: 'Cơ sở chính',
            colorHex: 0xFF4F46E5,
            slots: [
              ScheduleSlot(dayOfWeek: 6, startPeriod: 6, endPeriod: 9, room: 'Lab 5'),
            ],
          ),
        ],
      ),

      // 8. Lịch sử Đảng Cộng sản Việt Nam
      Course(
        code: 'ML211033',
        name: 'Lịch sử Đảng Cộng sản Việt Nam',
        credits: 2,
        theoryCredits: 1,
        practiceCredits: 1,
        department: 'Khoa Lý luận Chính trị',
        recommendedSemester: 4,
        category: CourseCategory.general,
        prerequisites: ['ML211030'],
        description: 'Sự ra đời của Đảng Cộng sản Việt Nam, đường lối kháng chiến cứu nước và công cuộc đổi mới phát triển đất nước.',
        sections: [
          const ClassSection(
            id: 'ML211033_74291',
            courseCode: 'ML211033',
            courseName: 'LS Đảng CS VN (1.4/0.6)',
            lecturer: 'Đoàn Văn Kỳ',
            lecturerRating: 4.75,
            capacity: 70,
            enrolled: 67,
            campus: 'Cơ sở chính',
            colorHex: 0xFFDB2777,
            slots: [
              ScheduleSlot(dayOfWeek: 2, startPeriod: 1, endPeriod: 4, room: '6.11'),
            ],
          ),
        ],
      ),

      // 9. Tâm lý học đại cương
      Course(
        code: 'SP211014',
        name: 'Tâm lý học đại cương',
        credits: 2,
        theoryCredits: 2,
        practiceCredits: 0,
        department: 'Khoa Sư phạm',
        recommendedSemester: 4,
        category: CourseCategory.general,
        prerequisites: [],
        description: 'Bản chất hiện tượng tâm lý người, quá trình nhận thức cảm tính - lý tính, tình cảm, ý chí và nhân cách con người.',
        sections: [
          const ClassSection(
            id: 'SP211014_74294',
            courseCode: 'SP211014',
            courseName: 'Tâm lý học đại cương (2.0/0.0)',
            lecturer: 'Lê Tô Đỗ Quyên',
            lecturerRating: 4.88,
            capacity: 70,
            enrolled: 64,
            campus: 'Cơ sở chính',
            colorHex: 0xFF0D9488,
            slots: [
              ScheduleSlot(dayOfWeek: 3, startPeriod: 1, endPeriod: 4, room: '2.4'),
              ScheduleSlot(dayOfWeek: 5, startPeriod: 1, endPeriod: 2, room: '2.4'),
            ],
          ),
        ],
      ),
    ];
  }

  static List<RegistrationPlan> getInitialPlans(List<Course> courses) {
    // 8 Học phần chính thức đã đăng ký Học kỳ 1 Năm học 2026-2027 (Khớp chuẩn 100% Cổng Đào Tạo ĐH Tây Nguyên - 18 TC)
    // 1. KC213613 - An toàn thông tin (2.0/0.0)
    // 2. KC213668 - Quản trị mạng trên môi trường Windows
    // 3. KC213678 - Thương mại điện tử (2.0/0.0)
    // 4. KC213685 - Những vấn đề hiện đại của CNTT
    // 5. KC215046 - Lập trình di động (2.0/1.0)
    // 6. KC215050 - Công nghệ lập trình đa nền tảng cho thiết bị di động (2.0/1.0)
    // 7. ML211033 - Lịch sử Đảng Cộng sản Việt Nam
    // 8. SP211014 - Tâm lý học đại cương (2.0/0.0)
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

    final default8Sections = <String, ClassSection>{};
    for (final code in official8Codes) {
      final c = courses.where((c) => c.code == code).firstOrNull;
      if (c != null && c.sections.isNotEmpty) {
        default8Sections[code] = c.sections.first;
      }
    }

    final planA = RegistrationPlan(
      id: 'plan_taynguyen_k23',
      name: 'Phương án 1 (Học kỳ 1 Năm học 2026-2027) • 18 TC',
      description: 'Danh sách 8 học phần chính thức đã đăng ký trên Cổng TTN (18 TC).',
      selectedSections: Map.from(default8Sections),
    );

    final planB = RegistrationPlan(
      id: 'plan_duphong_k23',
      name: 'Phương án 2 (Kế hoạch dự phòng / Tối ưu lịch học)',
      description: 'Phương án dự phòng 8 học phần đã đăng ký (18 TC).',
      selectedSections: Map.from(default8Sections),
    );

    return [planA, planB];
  }

  static Map<String, String> getCompletedCoursesDetails() {
    return {
      'KC211027': 'Tin học đại cương (Điểm: 5.6)',
      'FL211011': 'Tiếng Anh 1 (Điểm: 5.4)',
      'KC211685': 'Toán cho CNTT (Điểm: 4.3)',
      'KC212682': 'Thực hành Kỹ thuật lập trình (Điểm: 10.0)',
      'SP211039': 'Cờ vua 1 (Điểm: 8.1)',
      'FL211012': 'Tiếng Anh 2 (Điểm: 5.0)',
      'KC211604': 'Lý thuyết thông tin (Điểm: 6.5)',
      'KC212601': 'Cấu trúc rời rạc (Điểm: 5.1)',
      'KC215037': 'Cấu trúc dữ liệu và giải thuật (Điểm: 8.0)',
      'SP211040': 'Cờ vua 2 (Điểm: 10.0)',
      'KC212686': 'Thực tế nghề nghiệp (Điểm: 8.0)',
      'KC215039': 'Nhập môn mạng máy tính (Điểm: 6.9)',
      'KC213611': 'Lập trình hướng đối tượng (Điểm: 8.6)',
      'SP211041': 'Cờ vua 3 (Điểm: 10.0)',
    };
  }

  /// Lấy danh mục chương trình đào tạo theo từng ngành của Trường Đại học Tây Nguyên (Đầy đủ đúng 90 học phần)
  static final Map<String, List<Map<String, dynamic>>> _curriculumCache = {};

  static List<Map<String, dynamic>> getCurriculumForMajor(String? major) {
    final key = major?.trim().toLowerCase() ?? 'default';
    if (_curriculumCache.containsKey(key)) return _curriculumCache[key]!;
    final base = getTayNguyenCurriculum();
    if (major == null || major.isEmpty || major.contains('103') || major.toLowerCase().contains('công nghệ thông tin')) {
      _curriculumCache[key] = base;
      return base;
    }

    final m = major.toLowerCase();
    // Danh sách học phần chuyên ngành thay thế cho các dòng chuyên ngành (Đảm bảo tổng luôn đúng 90 học phần)
    List<Map<String, dynamic>> specialized = [];
    if (m.contains('772') || m.contains('y khoa') || m.contains('bác sĩ')) {
      specialized = [
        {'code': 'YD211001', 'name': 'Giải phẫu học 1 (3.0)', 'credits': 3, 'score': 7.8},
        {'code': 'YD211002', 'name': 'Giải phẫu học 2 (3.0)', 'credits': 3, 'score': 8.0},
        {'code': 'YD211003', 'name': 'Mô phôi học (2.0)', 'credits': 2, 'score': 7.5},
        {'code': 'YD211004', 'name': 'Sinh lý học 1 (3.0)', 'credits': 3, 'score': 8.2},
        {'code': 'YD211005', 'name': 'Sinh lý học 2 (3.0)', 'credits': 3, 'score': 8.0},
        {'code': 'YD211006', 'name': 'Hóa sinh y học (3.0)', 'credits': 3, 'score': 7.6},
        {'code': 'YD211007', 'name': 'Vi sinh - Ký sinh trùng (3.0)', 'credits': 3, 'score': 7.9},
        {'code': 'YD211008', 'name': 'Dược lý học (3.0)', 'credits': 3, 'score': 8.1},
        {'code': 'YD211009', 'name': 'Giải phẫu bệnh (2.0)', 'credits': 2, 'score': 7.8},
        {'code': 'YD211010', 'name': 'Điều dưỡng cơ bản (2.0)', 'credits': 2, 'score': 8.5},
        {'code': 'YD211011', 'name': 'Bệnh học Nội khoa 1 (4.0)', 'credits': 4, 'score': 8.0},
        {'code': 'YD211012', 'name': 'Bệnh học Ngoại khoa 1 (4.0)', 'credits': 4, 'score': 8.3},
        {'code': 'YD211013', 'name': 'Sản phụ khoa 1 (3.0)', 'credits': 3, 'score': null},
        {'code': 'YD211014', 'name': 'Nhi khoa 1 (3.0)', 'credits': 3, 'score': null},
        {'code': 'YD211015', 'name': 'Truyền nhiễm và Da liễu (3.0)', 'credits': 3, 'score': null},
        {'code': 'YD211016', 'name': 'Huyết học - Truyền máu (2.0)', 'credits': 2, 'score': null},
        {'code': 'YD211017', 'name': 'Chẩn đoán hình ảnh (3.0)', 'credits': 3, 'score': null},
        {'code': 'YD211018', 'name': 'Hồi sức cấp cứu và Chống độc (3.0)', 'credits': 3, 'score': null},
        {'code': 'YD211019', 'name': 'Y học cổ truyền (2.0)', 'credits': 2, 'score': null},
        {'code': 'YD211020', 'name': 'Phục hồi chức năng (2.0)', 'credits': 2, 'score': null},
        {'code': 'YD211021', 'name': 'Tai Mũi Họng - Răng Hàm Mặt (3.0)', 'credits': 3, 'score': null},
        {'code': 'YD211022', 'name': 'Mắt và Nhãn khoa (2.0)', 'credits': 2, 'score': null},
        {'code': 'YD211023', 'name': 'Tâm thần học (2.0)', 'credits': 2, 'score': null},
        {'code': 'YD211024', 'name': 'Thần kinh học (2.0)', 'credits': 2, 'score': null},
        {'code': 'YD211025', 'name': 'Dinh dưỡng và An toàn thực phẩm (2.0)', 'credits': 2, 'score': null},
        {'code': 'YD211026', 'name': 'Dịch tễ học (2.0)', 'credits': 2, 'score': null},
        {'code': 'YD211027', 'name': 'Tổ chức và Quản lý y tế (2.0)', 'credits': 2, 'score': null},
        {'code': 'YD211028', 'name': 'Thực tập lâm sàng BV Đa khoa Tây Nguyên (10.0)', 'credits': 10, 'score': null},
        {'code': 'YD211029', 'name': 'Chuyên đề lâm sàng tốt nghiệp (4.0)', 'credits': 4, 'score': null},
        {'code': 'YD211030', 'name': 'Khóa luận tốt nghiệp Bác sĩ y khoa (10.0)', 'credits': 10, 'score': null},
        {'code': 'YD211031', 'name': 'Đạo đức Y học và Pháp luật Y tế (2.0)', 'credits': 2, 'score': null},
      ];
    } else if (m.contains('101') || m.contains('sư phạm toán')) {
      specialized = [
        {'code': 'TO211001', 'name': 'Đại số đại cương (3.0)', 'credits': 3, 'score': 7.5},
        {'code': 'TO211002', 'name': 'Giải tích 1 (3.0)', 'credits': 3, 'score': 8.0},
        {'code': 'TO211003', 'name': 'Giải tích 2 (3.0)', 'credits': 3, 'score': 7.8},
        {'code': 'TO211004', 'name': 'Hình học Afin và Euclid (3.0)', 'credits': 3, 'score': 8.2},
        {'code': 'TO211005', 'name': 'Phương trình vi phân (3.0)', 'credits': 3, 'score': 7.9},
        {'code': 'TO211006', 'name': 'Xác suất và Thống kê toán (3.0)', 'credits': 3, 'score': 8.5},
        {'code': 'TO211007', 'name': 'Giải tích phức (3.0)', 'credits': 3, 'score': null},
        {'code': 'TO211008', 'name': 'Hình học vi phân (3.0)', 'credits': 3, 'score': null},
        {'code': 'TO211009', 'name': 'Phương pháp tính (2.0)', 'credits': 2, 'score': null},
        {'code': 'TO211010', 'name': 'Đại số tuyến tính nâng cao (3.0)', 'credits': 3, 'score': null},
        {'code': 'TO211011', 'name': 'Topology đại cương (3.0)', 'credits': 3, 'score': null},
        {'code': 'TO211012', 'name': 'Lý thuyết số (2.0)', 'credits': 2, 'score': null},
        {'code': 'SP212001', 'name': 'Tâm lý học sư phạm (2.0)', 'credits': 2, 'score': 8.5},
        {'code': 'SP212002', 'name': 'Giáo dục học đại cương (3.0)', 'credits': 3, 'score': 8.2},
        {'code': 'SP212003', 'name': 'Lý luận dạy học môn Toán (3.0)', 'credits': 3, 'score': 8.8},
        {'code': 'SP212004', 'name': 'Phương pháp NCKH giáo dục (2.0)', 'credits': 2, 'score': null},
        {'code': 'SP212005', 'name': 'Rèn luyện nghiệp vụ sư phạm (2.0)', 'credits': 2, 'score': 9.0},
        {'code': 'SP212006', 'name': 'Ứng dụng CNTT dạy học Toán (2.0)', 'credits': 2, 'score': null},
        {'code': 'SP212007', 'name': 'Kiểm tra đánh giá dạy học Toán (2.0)', 'credits': 2, 'score': null},
        {'code': 'SP212008', 'name': 'Thiết kế giáo án điện tử (2.0)', 'credits': 2, 'score': null},
        {'code': 'SP212009', 'name': 'Thực tập sư phạm 1 (2.0)', 'credits': 2, 'score': null},
        {'code': 'SP212010', 'name': 'Thực tập sư phạm phổ thông (5.0)', 'credits': 5, 'score': null},
        {'code': 'SP212011', 'name': 'Khóa luận tốt nghiệp Sư phạm Toán (10.0)', 'credits': 10, 'score': null},
        {'code': 'TO211013', 'name': 'Lịch sử Toán học (2.0)', 'credits': 2, 'score': null},
        {'code': 'TO211014', 'name': 'Toán sơ cấp (3.0)', 'credits': 3, 'score': null},
        {'code': 'TO211015', 'name': 'Phương pháp giải toán hình học (2.0)', 'credits': 2, 'score': null},
        {'code': 'TO211016', 'name': 'Phương pháp giải toán đại số (2.0)', 'credits': 2, 'score': null},
        {'code': 'TO211017', 'name': 'Bất đẳng thức và cực trị (2.0)', 'credits': 2, 'score': null},
        {'code': 'TO211018', 'name': 'Chuyên đề bồi dưỡng HSG Toán (3.0)', 'credits': 3, 'score': null},
        {'code': 'TO211019', 'name': 'Tối ưu hóa (2.0)', 'credits': 2, 'score': null},
        {'code': 'TO211020', 'name': 'Quy hoạch tuyến tính (2.0)', 'credits': 2, 'score': null},
      ];
    } else if (m.contains('734') || m.contains('quản trị kinh doanh')) {
      specialized = [
        {'code': 'KT211001', 'name': 'Kinh tế vi mô (3.0)', 'credits': 3, 'score': 7.8},
        {'code': 'KT211002', 'name': 'Kinh tế vĩ mô (3.0)', 'credits': 3, 'score': 7.5},
        {'code': 'KT211003', 'name': 'Nguyên lý kế toán (3.0)', 'credits': 3, 'score': 8.0},
        {'code': 'KT211004', 'name': 'Quản trị học (3.0)', 'credits': 3, 'score': 8.5},
        {'code': 'KT211005', 'name': 'Marketing căn bản (3.0)', 'credits': 3, 'score': 8.2},
        {'code': 'KT211006', 'name': 'Tài chính - Tiền tệ (3.0)', 'credits': 3, 'score': 7.5},
        {'code': 'KT211007', 'name': 'Thống kê kinh doanh (3.0)', 'credits': 3, 'score': 7.8},
        {'code': 'KT211008', 'name': 'Luật kinh tế (2.0)', 'credits': 2, 'score': 8.0},
        {'code': 'KT211009', 'name': 'Quản trị tài chính doanh nghiệp (3.0)', 'credits': 3, 'score': 8.1},
        {'code': 'KT211010', 'name': 'Quản trị nhân sự (3.0)', 'credits': 3, 'score': 8.4},
        {'code': 'KT211011', 'name': 'Quản trị chuỗi cung ứng Logistics (3.0)', 'credits': 3, 'score': null},
        {'code': 'KT211012', 'name': 'Quản trị chiến lược (3.0)', 'credits': 3, 'score': null},
        {'code': 'KT211013', 'name': 'Quản trị dự án kinh doanh (3.0)', 'credits': 3, 'score': null},
        {'code': 'KT211014', 'name': 'Quản trị bán hàng (2.0)', 'credits': 2, 'score': null},
        {'code': 'KT211015', 'name': 'Quản trị thương hiệu (2.0)', 'credits': 2, 'score': null},
        {'code': 'KT211016', 'name': 'Kinh doanh quốc tế (3.0)', 'credits': 3, 'score': null},
        {'code': 'KT211017', 'name': 'Giao tiếp trong kinh doanh (2.0)', 'credits': 2, 'score': null},
        {'code': 'KT211018', 'name': 'Quản trị chất lượng TQM (2.0)', 'credits': 2, 'score': null},
        {'code': 'KT211019', 'name': 'Thương mại điện tử doanh nghiệp (3.0)', 'credits': 3, 'score': null},
        {'code': 'KT211020', 'name': 'Hành vi tổ chức (2.0)', 'credits': 2, 'score': null},
        {'code': 'KT211021', 'name': 'Quản trị rủi ro kinh doanh (2.0)', 'credits': 2, 'score': null},
        {'code': 'KT211022', 'name': 'Hệ thống thông tin quản lý MIS (2.0)', 'credits': 2, 'score': null},
        {'code': 'KT211023', 'name': 'Phân tích hoạt động kinh doanh (3.0)', 'credits': 3, 'score': null},
        {'code': 'KT211024', 'name': 'Nghiên cứu thị trường (2.0)', 'credits': 2, 'score': null},
        {'code': 'KT211025', 'name': 'Khởi nghiệp và lập kế hoạch KD (3.0)', 'credits': 3, 'score': null},
        {'code': 'KT211026', 'name': 'Quản trị dịch vụ khách hàng (2.0)', 'credits': 2, 'score': null},
        {'code': 'KT211027', 'name': 'Thực tập giữa khóa (2.0)', 'credits': 2, 'score': null},
        {'code': 'KT211028', 'name': 'Thực tập doanh nghiệp (5.0)', 'credits': 5, 'score': null},
        {'code': 'KT211029', 'name': 'Chuyên đề tốt nghiệp QTKD (4.0)', 'credits': 4, 'score': null},
        {'code': 'KT211030', 'name': 'Khóa luận tốt nghiệp Cử nhân QTKD (10.0)', 'credits': 10, 'score': null},
        {'code': 'KT211031', 'name': 'Đạo đức kinh doanh và CSR (2.0)', 'credits': 2, 'score': null},
      ];
    }

    // Ghép: 59 môn đại cương cơ bản + 31 môn chuyên ngành -> ĐẢM BẢO CHÍNH XÁC ĐỦ 90 HỌC PHẦN
    final result = <Map<String, dynamic>>[];
    for (int i = 0; i < 59; i++) {
      result.add(Map<String, dynamic>.from(base[i]));
    }
    for (int i = 0; i < 31; i++) {
      if (i < specialized.length) {
        final item = Map<String, dynamic>.from(specialized[i]);
        item['tt'] = 60 + i;
        result.add(item);
      } else {
        final item = Map<String, dynamic>.from(base[59 + i]);
        item['tt'] = 60 + i;
        result.add(item);
      }
    }

    _curriculumCache[key] = result;
    return result;
  }
}
