/// Dữ liệu Chương trình đào tạo ngành Công nghệ thông tin (Mã ngành: 7480201)
/// Trích xuất từ Sổ tay Sinh viên 2023 Trường Đại học Tây Nguyên (ttn.edu.vn - QĐ 1574/QĐ-ĐHTN)
class TTNHandbookCourse {
  final int stt;
  final String code;
  final String name;
  final int semester;
  final int credits;
  final double theoryCredits;
  final double practiceCredits;
  final bool isMandatory;
  final String note;

  const TTNHandbookCourse({
    required this.stt,
    required this.code,
    required this.name,
    required this.semester,
    required this.credits,
    required this.theoryCredits,
    required this.practiceCredits,
    required this.isMandatory,
    this.note = '',
  });
}

class TTNHandbookDatabase {
  static const String majorName = 'Công nghệ thông tin';
  static const String majorCode = '7480201';
  static const String faculty = 'Khoa Khoa học Tự nhiên và Công nghệ';
  static const int totalCredits = 145;
  static const String decision = 'Quyết định số 1574/QĐ-ĐHTN ngày 24/8/2021 của Hiệu trưởng Trường ĐH Tây Nguyên';

  static const List<TTNHandbookCourse> allCourses = [
    TTNHandbookCourse(stt: 1, code: 'FL211011', name: 'Tiếng Anh', semester: 1, credits: 1, theoryCredits: 3.0, practiceCredits: 3.0, isMandatory: false),
    TTNHandbookCourse(stt: 2, code: 'KC211027', name: 'Tin học đại cương', semester: 1, credits: 2, theoryCredits: 1.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 3, code: 'KC211685', name: 'Toán cho Công nghệ thông tin', semester: 1, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 4, code: 'KC212604', name: 'Kỹ thuật lập trình', semester: 1, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 5, code: 'KC212681', name: 'Nhập môn ngành công nghệ thông tin', semester: 1, credits: 2, theoryCredits: 1.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 6, code: 'KC212682', name: 'Thực hành Kỹ thuật lập trình', semester: 1, credits: 2, theoryCredits: 0.0, practiceCredits: 2.0, isMandatory: true),
    TTNHandbookCourse(stt: 7, code: 'KT212202', name: 'Kỹ năng mềm', semester: 1, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 8, code: 'SP211032', name: 'Thể dục cơ bản và điền kinh', semester: 1, credits: 1, theoryCredits: 0.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 9, code: 'SP211039', name: 'Cờ vua', semester: 1, credits: 1, theoryCredits: 1.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 10, code: 'SP211105', name: 'Tiếng Việt nâng cao', semester: 1, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 11, code: 'SP211106', name: 'Văn hóa Việt Nam', semester: 1, credits: 3, theoryCredits: 3.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 12, code: 'SP211107', name: 'Lịch sử Việt Nam', semester: 1, credits: 3, theoryCredits: 3.0, practiceCredits: 0.0, isMandatory: true),

    TTNHandbookCourse(stt: 1, code: 'FL211012', name: 'Tiếng Anh', semester: 2, credits: 2, theoryCredits: 3.0, practiceCredits: 3.0, isMandatory: false),
    TTNHandbookCourse(stt: 2, code: 'KC211604', name: 'Lý thuyết thông tin', semester: 2, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 3, code: 'KC212601', name: 'Cấu trúc rời rạc', semester: 2, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 4, code: 'KC212602', name: 'Tổ chức máy tính', semester: 2, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 5, code: 'KC215037', name: 'Cấu trúc dữ liệu và giải thuật', semester: 2, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 6, code: 'NL211702', name: 'Pháp luật Việt Nam đại cương', semester: 2, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 7, code: 'SP211006', name: 'Xã hội học đại cương', semester: 2, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 8, code: 'SP211033', name: 'Bóng chuyền cơ bản', semester: 2, credits: 1, theoryCredits: 0.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 9, code: 'SP211034', name: 'Bơi lội cơ bản', semester: 2, credits: 1, theoryCredits: 0.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 10, code: 'SP211035', name: 'Cầu lông cơ bản', semester: 2, credits: 1, theoryCredits: 0.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 11, code: 'SP211040', name: 'Cờ vua', semester: 2, credits: 2, theoryCredits: 1.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 12, code: 'SP211042', name: 'Bóng bàn cơ bản', semester: 2, credits: 1, theoryCredits: 0.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 1, code: 'FL211013', name: 'Tiếng Anh', semester: 3, credits: 3, theoryCredits: 3.0, practiceCredits: 3.0, isMandatory: false),
    TTNHandbookCourse(stt: 2, code: 'KC212605', name: 'Cơ sở dữ liệu', semester: 3, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 3, code: 'KC212686', name: 'Thực tế nghề nghiệp', semester: 3, credits: 1, theoryCredits: 0.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 4, code: 'KC215039', name: 'Nhập môn mạng máy tính', semester: 3, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 5, code: 'ML211030', name: 'Triết học Mác - Lênin', semester: 3, credits: 3, theoryCredits: 3.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 6, code: 'KC213611', name: 'Lập trình hướng đối tượng', semester: 3, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 7, code: 'KC215040', name: 'Lập trình Windows', semester: 3, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 8, code: 'SP211036', name: 'Thể dục nhịp điệu cơ bản', semester: 3, credits: 1, theoryCredits: 0.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 9, code: 'SP211037', name: 'Taekwondo cơ bản', semester: 3, credits: 1, theoryCredits: 0.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 10, code: 'SP211038', name: 'Bóng đá cơ bản', semester: 3, credits: 1, theoryCredits: 0.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 11, code: 'SP211041', name: 'Cờ vua', semester: 3, credits: 3, theoryCredits: 1.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 12, code: 'SP211043', name: 'Bóng rổ cơ bản', semester: 3, credits: 1, theoryCredits: 0.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 1, code: 'FL211014', name: 'Tiếng Anh', semester: 4, credits: 4, theoryCredits: 3.0, practiceCredits: 3.0, isMandatory: false),
    TTNHandbookCourse(stt: 2, code: 'KC211006', name: 'Xác suất thống kê', semester: 4, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 3, code: 'KC213608', name: 'Nhập môn kỹ nghệ phần mềm', semester: 4, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 4, code: 'KC215036', name: 'Phương pháp nghiên cứu khoa học CNTT', semester: 4, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 5, code: 'KC215038', name: 'Thiết kế và lập trình Web cơ bản', semester: 4, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 6, code: 'KC215042', name: 'Lập trình Python', semester: 4, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 7, code: 'ML211031', name: 'Kinh tế chính trị Mác - Lênin', semester: 4, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 1, code: 'KC211615', name: 'Tiếng Anh Chuyên ngành CNTT', semester: 5, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 2, code: 'KC211682', name: 'Cơ sở vật lý cho Tin học', semester: 5, credits: 2, theoryCredits: 1.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 3, code: 'KC213607', name: 'Phân tích thiết kế hệ thống', semester: 5, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 4, code: 'KC213682', name: 'Hệ quản trị cơ sở dữ liệu', semester: 5, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 5, code: 'KC215044', name: 'Thiết kế và lập trình Web nâng cao', semester: 5, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 6, code: 'KT213007', name: 'Khởi nghiệp', semester: 5, credits: 2, theoryCredits: 1.5, practiceCredits: 0.5, isMandatory: true),
    TTNHandbookCourse(stt: 7, code: 'ML211032', name: 'Chủ nghĩa xã hội khoa học', semester: 5, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 1, code: 'KC213609', name: 'Trí tuệ nhân tạo', semester: 6, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 2, code: 'KC213667', name: 'Nhập môn Hệ điều hành', semester: 6, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 3, code: 'KC215041', name: 'Xử lý ảnh số', semester: 6, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 4, code: 'KC215043', name: 'Lập trình ứng dụng mã nguồn mở', semester: 6, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 5, code: 'ML211002', name: 'Tư tưởng Hồ Chí Minh', semester: 6, credits: 2, theoryCredits: 1.5, practiceCredits: 0.5, isMandatory: true),
    TTNHandbookCourse(stt: 6, code: 'QP211006', name: 'Công tác quốc phòng - An ninh Đường lối quốc phòng và an ninh của Đảng', semester: 6, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 7, code: 'QP211011', name: 'Cộng sản Việt Nam', semester: 6, credits: 3, theoryCredits: 3.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 8, code: 'QP211012', name: 'Quân sự chung', semester: 6, credits: 1, theoryCredits: 0.7, practiceCredits: 0.3, isMandatory: true),
    TTNHandbookCourse(stt: 9, code: 'QP211013', name: 'Kỹ thuật chiến đấu bộ binh và chiến thuật', semester: 6, credits: 2, theoryCredits: 0.0, practiceCredits: 2.0, isMandatory: true),
    TTNHandbookCourse(stt: 10, code: 'KC213629', name: 'Phát triển phần mềm hướng đối tượng', semester: 6, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 11, code: 'KC213633', name: 'Các quy trình phát triển phần mềm hiện đại', semester: 6, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 1, code: 'KC213613', name: 'An toàn thông tin', semester: 7, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 2, code: 'KC213685', name: 'Những vấn đề hiện đại của CNTT', semester: 7, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 3, code: 'ML211033', name: 'Lịch sử Đảng Cộng sản Việt Nam', semester: 7, credits: 2, theoryCredits: 1.4, practiceCredits: 0.6, isMandatory: true),
    TTNHandbookCourse(stt: 4, code: 'KC213619', name: 'Lập trình mạng', semester: 7, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 5, code: 'KC213661', name: 'Quản trị mạng Linux', semester: 7, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 6, code: 'KC213668', name: 'Quản trị mạng trên môi trường Windows', semester: 7, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 8, code: 'KC213630', name: 'Quản lý dự án CN thông tin', semester: 7, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 9, code: 'KC213635', name: 'CSDL phân tán', semester: 7, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 10, code: 'KC213676', name: 'Đảm bảo chất lượng phần mềm', semester: 7, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 11, code: 'KC213679', name: 'Mạng máy tính nâng cao', semester: 7, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),

    TTNHandbookCourse(stt: 12, code: 'KC213678', name: 'Thương mại điện tử', semester: 7, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 13, code: 'KC215046', name: 'Lập trình di động', semester: 7, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 14, code: 'KC215047', name: 'Phát triển ứng dụng web', semester: 7, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 15, code: 'KC215048', name: 'Kiểm thử phần mềm', semester: 7, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 16, code: 'KC215049', name: 'Hệ quản trị CSDL NoSQL Công nghệ lập trình đa nền tảng cho ứng dụng', semester: 7, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 17, code: 'KC215050', name: 'di động', semester: 7, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 18, code: 'KC215051', name: 'Thiết kế mạng', semester: 7, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 19, code: 'KC215052', name: 'Điện toán đám mây', semester: 7, credits: 3, theoryCredits: 2.0, practiceCredits: 1.0, isMandatory: true),
    TTNHandbookCourse(stt: 20, code: 'SP211001', name: 'Tiếng Việt thực hành', semester: 7, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 21, code: 'SP211003', name: 'Cơ sở văn hóa Việt Nam', semester: 7, credits: 2, theoryCredits: 1.5, practiceCredits: 0.5, isMandatory: true),
    TTNHandbookCourse(stt: 22, code: 'SP211014', name: 'Tâm lý học đại cương', semester: 7, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 1, code: 'KC215045', name: 'Thực tập nghề nghiệp', semester: 8, credits: 5, theoryCredits: 0.0, practiceCredits: 5.0, isMandatory: true),
    TTNHandbookCourse(stt: 2, code: 'KC215698', name: 'Chuyên đề tốt nghiệp', semester: 8, credits: 4, theoryCredits: 0.0, practiceCredits: 4.0, isMandatory: true),
    TTNHandbookCourse(stt: 3, code: 'KC215699', name: 'Khóa luận tốt nghiệp', semester: 8, credits: 10, theoryCredits: 0.0, practiceCredits: 10.0, isMandatory: true),
    TTNHandbookCourse(stt: 4, code: 'KC213647', name: 'Khai phá dữ liệu', semester: 8, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 5, code: 'KC213660', name: 'Digital marketing', semester: 8, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 6, code: 'KC213669', name: 'Phát triển ứng dụng Internet of Things', semester: 8, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 7, code: 'KC213696', name: 'Phân tích dữ liệu', semester: 8, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
    TTNHandbookCourse(stt: 8, code: 'KC217003', name: 'Công nghệ .Net', semester: 8, credits: 2, theoryCredits: 2.0, practiceCredits: 0.0, isMandatory: true),
  ];

  static List<TTNHandbookCourse> getCoursesBySemester(int semester) {
    return allCourses.where((c) => c.semester == semester).toList();
  }

  static TTNHandbookCourse? getCourseByCode(String code) {
    try {
      return allCourses.firstWhere((c) => c.code.toUpperCase() == code.toUpperCase().trim());
    } catch (_) {
      return null;
    }
  }
}
