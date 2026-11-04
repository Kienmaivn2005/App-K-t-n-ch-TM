class TTNMajor {
  final String code; // Mã chuyên ngành rút gọn (vd: 103, 101, 772, 734)
  final String moetCode; // Mã ngành chuẩn Bộ GD&ĐT (vd: 7480201, 7720101)
  final String name; // Tên ngành đào tạo
  final String faculty; // Khoa trực thuộc
  final String defaultAdvisor; // Cố vấn học tập mặc định
  final int totalCredits; // Tổng số tín chỉ tốt nghiệp
  final String degreeType; // Cử nhân / Kỹ sư / Bác sĩ

  const TTNMajor({
    required this.code,
    required this.moetCode,
    required this.name,
    required this.faculty,
    required this.defaultAdvisor,
    this.totalCredits = 135,
    this.degreeType = 'Cử nhân',
  });

  String get displayName => '$code $name';
  String get fullTitle => '$code - $name ($faculty)';
}

/// Danh bạ đầy đủ tất cả các ngành đào tạo chuẩn của Trường Đại học Tây Nguyên (TTN)
class TTNMajorsDirectory {
  static const List<TTNMajor> allMajors = [
    // 1. Khoa Khoa học Tự nhiên và Công nghệ
    TTNMajor(
      code: '103',
      moetCode: '7480201',
      name: 'Công nghệ thông tin',
      faculty: 'Khoa Khoa học Tự nhiên và Công nghệ',
      defaultAdvisor: 'GV2. Nguyễn Thị Như (Tel: 0906200625; mail:nhubmt@dng.vnn.vndc)',
      totalCredits: 145,
      degreeType: 'Kỹ sư / Cử nhân',
    ),
    TTNMajor(
      code: '104',
      moetCode: '7480103',
      name: 'Kỹ thuật phần mềm',
      faculty: 'Khoa Khoa học Tự nhiên và Công nghệ',
      defaultAdvisor: 'TS. Trần Văn Hùng (Tel: 0905889900; mail:tvhung@ttn.edu.vn)',
      totalCredits: 145,
      degreeType: 'Kỹ sư',
    ),
    TTNMajor(
      code: '746',
      moetCode: '7460112',
      name: 'Khoa học dữ liệu',
      faculty: 'Khoa Khoa học Tự nhiên và Công nghệ',
      defaultAdvisor: 'TS. Võ Quốc Thông (Tel: 0903112244; mail:vqthong@ttn.edu.vn)',
      totalCredits: 140,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '741',
      moetCode: '7460101',
      name: 'Toán ứng dụng',
      faculty: 'Khoa Khoa học Tự nhiên và Công nghệ',
      defaultAdvisor: 'TS. Nguyễn Đình Bình (Tel: 0905123456; mail:ndbinh@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '742',
      moetCode: '7420201',
      name: 'Công nghệ sinh học',
      faculty: 'Khoa Khoa học Tự nhiên và Công nghệ',
      defaultAdvisor: 'TS. Bùi Thị Thu Hiền (Tel: 0914223344; mail:btthien@ttn.edu.vn)',
      totalCredits: 140,
      degreeType: 'Kỹ sư',
    ),
    TTNMajor(
      code: '744',
      moetCode: '7440102',
      name: 'Sinh học ứng dụng',
      faculty: 'Khoa Khoa học Tự nhiên và Công nghệ',
      defaultAdvisor: 'TS. Nguyễn Thị Hà (Tel: 0988776655; mail:ntha@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '747',
      moetCode: '7440112',
      name: 'Hóa học',
      faculty: 'Khoa Khoa học Tự nhiên và Công nghệ',
      defaultAdvisor: 'TS. Đặng Thị Nga (Tel: 0913554433; mail:dtnga@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),

    // 2. Khoa Y Dược
    TTNMajor(
      code: '772',
      moetCode: '7720101',
      name: 'Y khoa (Bác sĩ đa khoa)',
      faculty: 'Khoa Y Dược',
      defaultAdvisor: 'BS.CKII. Phạm Gia Hưng (Tel: 0914056789; mail:pghung@ttn.edu.vn)',
      totalCredits: 196,
      degreeType: 'Bác sĩ',
    ),
    TTNMajor(
      code: '773',
      moetCode: '7720301',
      name: 'Điều dưỡng',
      faculty: 'Khoa Y Dược',
      defaultAdvisor: 'ThS. Đỗ Thị Hoàng Yến (Tel: 0905667788; mail:dthyen@ttn.edu.vn)',
      totalCredits: 140,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '776',
      moetCode: '7720601',
      name: 'Kỹ thuật xét nghiệm y học',
      faculty: 'Khoa Y Dược',
      defaultAdvisor: 'TS. Bùi Minh Đức (Tel: 0903889911; mail:bmduc@ttn.edu.vn)',
      totalCredits: 140,
      degreeType: 'Cử nhân',
    ),

    // 3. Khoa Sư phạm
    TTNMajor(
      code: '101',
      moetCode: '7140209',
      name: 'Sư phạm Toán học',
      faculty: 'Khoa Sư phạm',
      defaultAdvisor: 'TS. Nguyễn Đình Bình (Tel: 0905123456; mail:ndbinh@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '102',
      moetCode: '7140210',
      name: 'Sư phạm Tin học',
      faculty: 'Khoa Sư phạm',
      defaultAdvisor: 'ThS. Lê Minh Quân (Tel: 0914887766; mail:lmquan@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '105',
      moetCode: '7140211',
      name: 'Sư phạm Vật lý',
      faculty: 'Khoa Sư phạm',
      defaultAdvisor: 'TS. Hoàng Trọng Dũng (Tel: 0982334455; mail:htdung@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '106',
      moetCode: '7140212',
      name: 'Sư phạm Hóa học',
      faculty: 'Khoa Sư phạm',
      defaultAdvisor: 'TS. Vũ Thị Lan (Tel: 0905443322; mail:vtlan@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '107',
      moetCode: '7140213',
      name: 'Sư phạm Sinh học',
      faculty: 'Khoa Sư phạm',
      defaultAdvisor: 'TS. Lê Viết Báu (Tel: 0913998877; mail:lvbau@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '108',
      moetCode: '7140217',
      name: 'Sư phạm Ngữ văn',
      faculty: 'Khoa Sư phạm',
      defaultAdvisor: 'TS. Đoàn Văn Kỳ (Tel: 0903556677; mail:dvky@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '109',
      moetCode: '7140218',
      name: 'Sư phạm Lịch sử',
      faculty: 'Khoa Sư phạm',
      defaultAdvisor: 'ThS. Đỗ Quang Nam (Tel: 0989112233; mail:dqnam@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '110',
      moetCode: '7140231',
      name: 'Sư phạm Tiếng Anh',
      faculty: 'Khoa Sư phạm',
      defaultAdvisor: 'ThS. Nguyễn Quỳnh Chi (Tel: 0905990011; mail:nqchi@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '111',
      moetCode: '7140201',
      name: 'Giáo dục Mầm non',
      faculty: 'Khoa Sư phạm',
      defaultAdvisor: 'TS. Phan Thị Thu (Tel: 0914778899; mail:ptthu@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '112',
      moetCode: '7140202',
      name: 'Giáo dục Tiểu học',
      faculty: 'Khoa Sư phạm',
      defaultAdvisor: 'TS. Trần Quốc Tuấn (Tel: 0903445566; mail:tqtuan@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '113',
      moetCode: '7140206',
      name: 'Giáo dục Thể chất',
      faculty: 'Khoa Sư phạm',
      defaultAdvisor: 'ThS. Bùi Đình Thắng (Tel: 0988667788; mail:bdthang@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '114',
      moetCode: '7140205',
      name: 'Giáo dục Chính trị',
      faculty: 'Khoa Sư phạm',
      defaultAdvisor: 'TS. Nguyễn Thành Long (Tel: 0913223344; mail:ntlong@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),

    // 4. Khoa Kinh tế
    TTNMajor(
      code: '734',
      moetCode: '7340101',
      name: 'Quản trị kinh doanh',
      faculty: 'Khoa Kinh tế',
      defaultAdvisor: 'TS. Nguyễn Hữu Dũng (Tel: 0903987654; mail:nhdung@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '735',
      moetCode: '7340201',
      name: 'Tài chính - Ngân hàng',
      faculty: 'Khoa Kinh tế',
      defaultAdvisor: 'TS. Đỗ Thị Kim Dung (Tel: 0905334455; mail:dtkdung@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '736',
      moetCode: '7340301',
      name: 'Kế toán',
      faculty: 'Khoa Kinh tế',
      defaultAdvisor: 'ThS. Hoàng Thị Mơ (Tel: 0914556677; mail:htmo@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '731',
      moetCode: '7310101',
      name: 'Kinh tế',
      faculty: 'Khoa Kinh tế',
      defaultAdvisor: 'TS. Lê Viết Hùng (Tel: 0989223344; mail:lvhung@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '739',
      moetCode: '7340115',
      name: 'Quản trị dịch vụ du lịch và lữ hành',
      faculty: 'Khoa Kinh tế',
      defaultAdvisor: 'ThS. Trần Thu Nga (Tel: 0905778899; mail:ttnga@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),

    // 5. Khoa Chăn nuôi - Thú y
    TTNMajor(
      code: '764',
      moetCode: '7640101',
      name: 'Thú y (Bác sĩ thú y)',
      faculty: 'Khoa Chăn nuôi - Thú y',
      defaultAdvisor: 'PGS.TS. Nguyễn Văn Thanh (Tel: 0913876543; mail:nvthanh@ttn.edu.vn)',
      totalCredits: 160,
      degreeType: 'Bác sĩ',
    ),
    TTNMajor(
      code: '765',
      moetCode: '7620105',
      name: 'Chăn nuôi',
      faculty: 'Khoa Chăn nuôi - Thú y',
      defaultAdvisor: 'TS. Trần Văn Tốt (Tel: 0905667799; mail:tvtot@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Kỹ sư',
    ),

    // 6. Khoa Nông Lâm nghiệp
    TTNMajor(
      code: '762',
      moetCode: '7620110',
      name: 'Nông học',
      faculty: 'Khoa Nông Lâm nghiệp',
      defaultAdvisor: 'TS. Nguyễn Thị Sen (Tel: 0912445566; mail:ntsen@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Kỹ sư',
    ),
    TTNMajor(
      code: '763',
      moetCode: '7620112',
      name: 'Khoa học cây trồng',
      faculty: 'Khoa Nông Lâm nghiệp',
      defaultAdvisor: 'TS. Lê Đức Thắng (Tel: 0988112244; mail:ldthang@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Kỹ sư',
    ),
    TTNMajor(
      code: '768',
      moetCode: '7620113',
      name: 'Bảo vệ thực vật',
      faculty: 'Khoa Nông Lâm nghiệp',
      defaultAdvisor: 'TS. Phan Thanh Dũng (Tel: 0905223311; mail:ptdung@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Kỹ sư',
    ),
    TTNMajor(
      code: '766',
      moetCode: '7620201',
      name: 'Lâm sinh',
      faculty: 'Khoa Nông Lâm nghiệp',
      defaultAdvisor: 'TS. Nguyễn Hoàng Phương (Tel: 0914998811; mail:nhphuong@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Kỹ sư',
    ),
    TTNMajor(
      code: '767',
      moetCode: '7620205',
      name: 'Quản lý tài nguyên rừng',
      faculty: 'Khoa Nông Lâm nghiệp',
      defaultAdvisor: 'TS. Lê Bảo Châu (Tel: 0903332211; mail:lbchau@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Kỹ sư',
    ),
    TTNMajor(
      code: '785',
      moetCode: '7850101',
      name: 'Quản lý đất đai',
      faculty: 'Khoa Nông Lâm nghiệp',
      defaultAdvisor: 'ThS. Vũ Ngọc Hùng (Tel: 0987445566; mail:vnhung@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Kỹ sư',
    ),
    TTNMajor(
      code: '754',
      moetCode: '7540101',
      name: 'Công nghệ thực phẩm',
      faculty: 'Khoa Nông Lâm nghiệp',
      defaultAdvisor: 'TS. Nguyễn Thị Bích (Tel: 0913887755; mail:ntbich@ttn.edu.vn)',
      totalCredits: 140,
      degreeType: 'Kỹ sư',
    ),

    // 7. Khoa Ngoại ngữ
    TTNMajor(
      code: '722',
      moetCode: '7220201',
      name: 'Ngôn ngữ Anh',
      faculty: 'Khoa Ngoại ngữ',
      defaultAdvisor: 'ThS. Lê Thị Quỳnh Như (Tel: 0983112233; mail:ltqnhu@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '723',
      moetCode: '7220202',
      name: 'Ngôn ngữ Pháp',
      faculty: 'Khoa Ngoại ngữ',
      defaultAdvisor: 'ThS. Phạm Thị Mai (Tel: 0905886644; mail:ptmai@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),

    // 8. Khoa Lý luận Chính trị
    TTNMajor(
      code: '738',
      moetCode: '7380101',
      name: 'Luật',
      faculty: 'Khoa Lý luận Chính trị',
      defaultAdvisor: 'ThS. LS. Đinh Trọng Quý (Tel: 0914332211; mail:dtquy@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '729',
      moetCode: '7229030',
      name: 'Triết học',
      faculty: 'Khoa Lý luận Chính trị',
      defaultAdvisor: 'TS. Nguyễn Hữu Tâm (Tel: 0905114477; mail:nhtam@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
    TTNMajor(
      code: '730',
      moetCode: '7310301',
      name: 'Xã hội học',
      faculty: 'Khoa Lý luận Chính trị',
      defaultAdvisor: 'ThS. Lê Tô Đỗ Quyên (Tel: 0989554433; mail:ltdquyen@ttn.edu.vn)',
      totalCredits: 135,
      degreeType: 'Cử nhân',
    ),
  ];

  static final TTNMajor defaultMajor = allMajors[0]; // 103 Công nghệ thông tin

  /// Tìm kiếm ngành theo từ khóa (Mã số rút gọn, Mã Bộ GD&ĐT hoặc Tên ngành)
  static TTNMajor findMajor(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return defaultMajor;

    // 1. Khớp chính xác mã ngành rút gọn (vd: '103', '772', '101')
    for (final m in allMajors) {
      if (m.code.toLowerCase() == q || m.moetCode.toLowerCase() == q) {
        return m;
      }
    }

    // 2. Kiểm tra nếu chuỗi bắt đầu bằng mã ngành (vd: '103 Công nghệ thông tin')
    for (final m in allMajors) {
      if (q.startsWith(m.code.toLowerCase()) || q.startsWith(m.moetCode.toLowerCase())) {
        return m;
      }
    }

    // 3. Khớp theo tên ngành học
    for (final m in allMajors) {
      if (m.name.toLowerCase() == q || q.contains(m.name.toLowerCase()) || m.name.toLowerCase().contains(q)) {
        return m;
      }
    }

    // 4. Khớp theo khoa
    for (final m in allMajors) {
      if (q.contains(m.faculty.toLowerCase())) {
        return m;
      }
    }

    return defaultMajor;
  }

  /// Tự động phân tích MSSV để nhận diện Khóa (K20-K24) và Mã Ngành
  static Map<String, dynamic> detectMajorAndCohort(String msv) {
    final clean = msv.trim();
    if (clean.length < 2) {
      return {'cohort': 'K23', 'major': defaultMajor};
    }

    // Nhận diện Khóa theo 2 chữ số đầu tiên (23 -> K23, 24 -> K24, v.v.)
    final yearPrefix = clean.substring(0, 2);
    final cohort = 'K$yearPrefix';

    // Nhận diện mã ngành: thử lấy 3 ký tự tiếp theo (vd: 23103035 -> '103', 23772018 -> '772')
    if (clean.length >= 5) {
      final code3 = clean.substring(2, 5);
      for (final m in allMajors) {
        if (m.code == code3) {
          return {'cohort': cohort, 'major': m};
        }
      }
    }

    // Kiểm tra mã MOET nếu người dùng nhập mã dài
    for (final m in allMajors) {
      if (clean.contains(m.moetCode)) {
        return {'cohort': cohort, 'major': m};
      }
    }

    // Kiểm tra bất kỳ mã ngành nào xuất hiện trong MSSV
    for (final m in allMajors) {
      if (clean.contains(m.code)) {
        return {'cohort': cohort, 'major': m};
      }
    }

    return {'cohort': cohort, 'major': defaultMajor};
  }
}

