import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/planner_provider.dart';
import '../../services/ttn_database.dart';

class RoadmapNode {
  final String code;
  final String name;
  final int semester;
  final int credits;
  final List<String> prerequisites;
  final String category; // Lập trình, Mạng & Hạ tầng, Dữ liệu & AI, Ngoại ngữ, Chính trị & Xã hội, Tốt nghiệp
  final String? description;

  const RoadmapNode({
    required this.code,
    required this.name,
    required this.semester,
    required this.credits,
    this.prerequisites = const [],
    required this.category,
    this.description,
  });
}

class PrerequisiteRoadmapScreen extends StatefulWidget {
  const PrerequisiteRoadmapScreen({super.key});

  @override
  State<PrerequisiteRoadmapScreen> createState() => _PrerequisiteRoadmapScreenState();
}

class _PrerequisiteRoadmapScreenState extends State<PrerequisiteRoadmapScreen> {
  String _selectedCategory = 'Tất cả';
  bool _isGraphView = true; // true: Sơ đồ cây phân nhánh, false: Danh sách kiểm tra

  static const List<RoadmapNode> roadmap = [
    // 1. Chuỗi Lập trình & Kỹ nghệ Phần mềm
    RoadmapNode(
      code: 'KC211027',
      name: 'Tin học đại cương',
      semester: 1,
      credits: 2,
      category: 'Lập trình',
      description: 'Nền tảng thuật toán, lưu đồ khối và tư duy lập trình căn bản.',
    ),
    RoadmapNode(
      code: 'KC212604',
      name: 'Kỹ thuật lập trình',
      semester: 1,
      credits: 2,
      prerequisites: ['KC211027'],
      category: 'Lập trình',
      description: 'Ngôn ngữ C/C++, con trỏ, đệ quy, cấp phát bộ nhớ động.',
    ),
    RoadmapNode(
      code: 'KC212682',
      name: 'Thực hành Kỹ thuật lập trình',
      semester: 1,
      credits: 1,
      prerequisites: ['KC212604'],
      category: 'Lập trình',
      description: 'Bài tập lab thực hành trên IDE, debug và tối ưu mã nguồn.',
    ),
    RoadmapNode(
      code: 'KC215037',
      name: 'Cấu trúc dữ liệu & Giải thuật',
      semester: 2,
      credits: 3,
      prerequisites: ['KC212604'],
      category: 'Lập trình',
      description: 'Danh sách liên kết, Stack, Queue, Cây nhị phân, Thuật toán sắp xếp & tìm kiếm.',
    ),
    RoadmapNode(
      code: 'KC213611',
      name: 'Lập trình hướng đối tượng (OOP)',
      semester: 3,
      credits: 3,
      prerequisites: ['KC215037'],
      category: 'Lập trình',
      description: 'Tính đóng gói, kế thừa, đa hình, trừu tượng bằng Java/C#.',
    ),
    RoadmapNode(
      code: 'KC215038',
      name: 'Thiết kế & Lập trình Web cơ bản',
      semester: 4,
      credits: 3,
      prerequisites: ['KC212604'],
      category: 'Lập trình',
      description: 'HTML5, CSS3, JavaScript ES6 và Responsive UI design.',
    ),
    RoadmapNode(
      code: 'KC215042',
      name: 'Lập trình Python',
      semester: 4,
      credits: 3,
      prerequisites: ['KC212604'],
      category: 'Lập trình',
      description: 'Cú pháp Python, xử lý file, thư viện NumPy, Pandas và automation script.',
    ),
    RoadmapNode(
      code: 'KC213608',
      name: 'Nhập môn kỹ nghệ phần mềm',
      semester: 4,
      credits: 3,
      prerequisites: ['KC213611'],
      category: 'Lập trình',
      description: 'Quy trình phần mềm Agile/Scrum, phân tích yêu cầu SRS, mô hình hóa UML.',
    ),
    RoadmapNode(
      code: 'KC215044',
      name: 'Lập trình Web nâng cao',
      semester: 5,
      credits: 3,
      prerequisites: ['KC215038'],
      category: 'Lập trình',
      description: 'Fullstack Web: Backend RESTful API, xác thực JWT, NodeJS/PHP/Laravel.',
    ),
    RoadmapNode(
      code: 'KC213607',
      name: 'Phân tích thiết kế hệ thống',
      semester: 5,
      credits: 3,
      prerequisites: ['KC213608'],
      category: 'Lập trình',
      description: 'Thiết kế kiến trúc hệ thống phần mềm quy mô lớn, sơ đồ tuần tự, ERD.',
    ),
    RoadmapNode(
      code: 'KC215046',
      name: 'Lập trình di động',
      semester: 7,
      credits: 3,
      prerequisites: ['KC213611'],
      category: 'Lập trình',
      description: 'Phát triển ứng dụng Android Native bằng Kotlin/Java, Activity, Fragment.',
    ),
    RoadmapNode(
      code: 'KC215050',
      name: 'Lập trình đa nền tảng di động',
      semester: 7,
      credits: 3,
      prerequisites: ['KC213611'],
      category: 'Lập trình',
      description: 'Phát triển ứng dụng Flutter/Dart đa nền tảng iOS, Android, Web.',
    ),
    RoadmapNode(
      code: 'KC215048',
      name: 'Kiểm thử phần mềm (Testing)',
      semester: 7,
      credits: 3,
      prerequisites: ['KC213608'],
      category: 'Lập trình',
      description: 'Unit Test, Integration Test, Automation Test với Selenium, Test Plan.',
    ),

    // 2. Chuỗi Mạng & Hạ tầng Hệ thống
    RoadmapNode(
      code: 'KC212601',
      name: 'Cấu trúc rời rạc',
      semester: 2,
      credits: 2,
      category: 'Mạng & Hạ tầng',
      description: 'Logic mệnh đề, đại số Boole, lý thuyết đồ thị và bài toán tối ưu mạng.',
    ),
    RoadmapNode(
      code: 'KC212602',
      name: 'Tổ chức máy tính',
      semester: 2,
      credits: 3,
      prerequisites: ['KC212601'],
      category: 'Mạng & Hạ tầng',
      description: 'Kiến trúc CPU, tập lệnh ALU, bộ nhớ Cache, bus và cơ chế ngắt phần cứng.',
    ),
    RoadmapNode(
      code: 'KC215039',
      name: 'Nhập môn mạng máy tính',
      semester: 3,
      credits: 3,
      prerequisites: ['KC212602'],
      category: 'Mạng & Hạ tầng',
      description: 'Mô hình OSI & TCP/IP, địa chỉ IPv4/IPv6, định tuyến Routing, Switching.',
    ),
    RoadmapNode(
      code: 'KC213667',
      name: 'Nhập môn Hệ điều hành',
      semester: 6,
      credits: 2,
      prerequisites: ['KC212602'],
      category: 'Mạng & Hạ tầng',
      description: 'Tiến trình Process, luồng Thread, đồng bộ hóa Mutex, Deadlock, phân trang bộ nhớ ảo.',
    ),
    RoadmapNode(
      code: 'KC213613',
      name: 'An toàn thông tin',
      semester: 7,
      credits: 2,
      prerequisites: ['KC215039'],
      category: 'Mạng & Hạ tầng',
      description: 'Mã hóa RSA, AES, chữ ký số PKI, tường lửa Firewall và an toàn mạng.',
    ),
    RoadmapNode(
      code: 'KC213661',
      name: 'Quản trị mạng Linux',
      semester: 7,
      credits: 2,
      prerequisites: ['KC215039'],
      category: 'Mạng & Hạ tầng',
      description: 'Dịch vụ mạng DNS, DHCP, Web Server Nginx, bảo mật SSH trên Ubuntu/CentOS.',
    ),
    RoadmapNode(
      code: 'KC213668',
      name: 'Quản trị Windows Server',
      semester: 7,
      credits: 2,
      prerequisites: ['KC215039'],
      category: 'Mạng & Hạ tầng',
      description: 'Active Directory Domain Services, Group Policy GPO, DNS, VPN Server.',
    ),
    RoadmapNode(
      code: 'KC215051',
      name: 'Thiết kế mạng',
      semester: 7,
      credits: 3,
      prerequisites: ['KC215039'],
      category: 'Mạng & Hạ tầng',
      description: 'Thiết kế hạ tầng mạng LAN/WAN doanh nghiệp với Cisco Packet Tracer.',
    ),
    RoadmapNode(
      code: 'KC215052',
      name: 'Điện toán đám mây (Cloud)',
      semester: 7,
      credits: 3,
      prerequisites: ['KC215039'],
      category: 'Mạng & Hạ tầng',
      description: 'Mô hình IaaS, PaaS, SaaS, triển khai dịch vụ AWS / Google Cloud Platform.',
    ),

    // 3. Chuỗi Cơ sở Dữ liệu & Trí tuệ Nhân tạo
    RoadmapNode(
      code: 'KC212605',
      name: 'Cơ sở dữ liệu',
      semester: 3,
      credits: 3,
      prerequisites: ['KC212601'],
      category: 'Dữ liệu & AI',
      description: 'Mô hình thực thể kết hợp ERD, đại số quan hệ và câu lệnh truy vấn SQL.',
    ),
    RoadmapNode(
      code: 'KC213682',
      name: 'Hệ quản trị cơ sở dữ liệu',
      semester: 5,
      credits: 3,
      prerequisites: ['KC212605'],
      category: 'Dữ liệu & AI',
      description: 'Quản trị MS SQL Server, Stored Procedure, Trigger, Transaction & Index tối ưu.',
    ),
    RoadmapNode(
      code: 'KC213609',
      name: 'Trí tuệ nhân tạo (AI)',
      semester: 6,
      credits: 2,
      prerequisites: ['KC215037'],
      category: 'Dữ liệu & AI',
      description: 'Tìm kiếm không gian trạng thái A*, trò chơi Alpha-Beta, Machine Learning cơ bản.',
    ),
    RoadmapNode(
      code: 'KC215041',
      name: 'Xử lý ảnh số (Vision)',
      semester: 6,
      credits: 3,
      prerequisites: ['KC215037'],
      category: 'Dữ liệu & AI',
      description: 'Xử lý ảnh với OpenCV, lọc nhiễu, phân đoạn ảnh, nhận diện biên và khuôn mặt.',
    ),
    RoadmapNode(
      code: 'KC215049',
      name: 'Hệ quản trị CSDL NoSQL',
      semester: 7,
      credits: 3,
      prerequisites: ['KC212605'],
      category: 'Dữ liệu & AI',
      description: 'Cơ sở dữ liệu phi quan hệ MongoDB, Redis, xử lý dữ liệu lớn Big Data.',
    ),
    RoadmapNode(
      code: 'KC213647',
      name: 'Khai phá dữ liệu (Data Mining)',
      semester: 8,
      credits: 2,
      prerequisites: ['KC212605'],
      category: 'Dữ liệu & AI',
      description: 'Khai phá luật kết hợp Apriori, phân cụm K-Means, cây quyết định Decision Tree.',
    ),

    // 4. Chuỗi Ngoại ngữ Tiếng Anh Chuẩn Đầu Ra
    RoadmapNode(
      code: 'FL211011',
      name: 'Tiếng Anh 1',
      semester: 1,
      credits: 3,
      category: 'Ngoại ngữ',
      description: 'Ngữ pháp cơ bản, từ vựng giao tiếp hàng ngày, luyện phát âm chuẩn.',
    ),
    RoadmapNode(
      code: 'FL211012',
      name: 'Tiếng Anh 2',
      semester: 2,
      credits: 3,
      prerequisites: ['FL211011'],
      category: 'Ngoại ngữ',
      description: 'Kỹ năng đọc hiểu văn bản, viết đoạn văn và nghe đàm thoại sơ trung cấp.',
    ),
    RoadmapNode(
      code: 'FL211013',
      name: 'Tiếng Anh 3',
      semester: 3,
      credits: 3,
      prerequisites: ['FL211012'],
      category: 'Ngoại ngữ',
      description: 'Giao tiếp nâng cao, thuyết trình tiếng Anh, viết luận và đọc tài liệu học thuật.',
    ),
    RoadmapNode(
      code: 'FL211014',
      name: 'Tiếng Anh 4 (Chuẩn B1)',
      semester: 4,
      credits: 3,
      prerequisites: ['FL211013'],
      category: 'Ngoại ngữ',
      description: 'Ôn luyện chứng chỉ B1 khung châu Âu (CEFR), kỹ năng tổng hợp 4 kỹ năng.',
    ),
    RoadmapNode(
      code: 'KC211615',
      name: 'Tiếng Anh Chuyên ngành CNTT',
      semester: 5,
      credits: 2,
      prerequisites: ['FL211014'],
      category: 'Ngoại ngữ',
      description: 'Thuật ngữ kỹ thuật CNTT, đọc hiểu tài liệu phần mềm, viết tài liệu kỹ thuật API.',
    ),

    // 5. Chuỗi Lý Luận Chính Trị & Khoa Học Xã Hội
    RoadmapNode(
      code: 'ML211030',
      name: 'Triết học Mác - Lênin',
      semester: 1,
      credits: 3,
      category: 'Chính trị & Xã hội',
      description: 'Chủ nghĩa duy vật biện chứng, phép biện chứng duy vật và chủ nghĩa duy vật lịch sử.',
    ),
    RoadmapNode(
      code: 'ML211031',
      name: 'Kinh tế chính trị Mác - Lênin',
      semester: 2,
      credits: 2,
      prerequisites: ['ML211030'],
      category: 'Chính trị & Xã hội',
      description: 'Hàng hóa, giá trị thặng dư, quy luật kinh tế thị trường định hướng XHCN.',
    ),
    RoadmapNode(
      code: 'ML211032',
      name: 'Chủ nghĩa xã hội khoa học',
      semester: 3,
      credits: 2,
      prerequisites: ['ML211031'],
      category: 'Chính trị & Xã hội',
      description: 'Sứ mệnh lịch sử của giai cấp công nhân, dân chủ XHCN và vấn đề dân tộc, tôn giáo.',
    ),
    RoadmapNode(
      code: 'ML211033',
      name: 'Lịch sử Đảng Cộng sản Việt Nam',
      semester: 4,
      credits: 2,
      prerequisites: ['ML211030'],
      category: 'Chính trị & Xã hội',
      description: 'Sự ra đời của Đảng, quá trình lãnh đạo cách mạng giải phóng dân tộc và thời kỳ đổi mới.',
    ),
    RoadmapNode(
      code: 'SP211014',
      name: 'Tâm lý học đại cương',
      semester: 1,
      credits: 2,
      category: 'Chính trị & Xã hội',
      description: 'Hiện tượng tâm lý con người, nhân cách, nhận thức, tình cảm và ý chí.',
    ),

    // 6. Chuỗi Tốt nghiệp
    RoadmapNode(
      code: 'KC215045',
      name: 'Thực tập nghề nghiệp (Doanh nghiệp)',
      semester: 8,
      credits: 5,
      category: 'Tốt nghiệp',
      description: 'Thực tập toàn thời gian tại công ty phần mềm, tham gia dự án thực tế.',
    ),
    RoadmapNode(
      code: 'KC215699',
      name: 'Khóa luận tốt nghiệp CNTT',
      semester: 8,
      credits: 10,
      prerequisites: ['KC215045'],
      category: 'Tốt nghiệp',
      description: 'Nghiên cứu ứng dụng công nghệ mới hoặc phát triển sản phẩm phần mềm bảo vệ hội đồng.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final profile = planner.profile;
    final activeCodes = planner.activePlan.selectedSections.values.map((s) => s.courseCode).toSet();

    // Tính toán số tín chỉ tích lũy động chuẩn xác
    const totalDegreeCredits = 140;
    int passedCredits = 0;
    for (final code in profile.passedCourses) {
      if (!code.startsWith('QP') && !code.startsWith('SP21103') && !code.startsWith('SP21104')) {
        passedCredits += TTNDatabase.curriculumCourseCredits[code] ?? planner.getCourseByCode(code)?.credits ?? 2;
      }
    }
    final progressValue = (passedCredits / totalDegreeCredits).clamp(0.0, 1.0);
    final progressPercent = (progressValue * 100).round();
    final remainingCredits = (totalDegreeCredits - passedCredits).clamp(0, totalDegreeCredits);

    final categories = ['Tất cả', 'Lập trình', 'Mạng & Hạ tầng', 'Dữ liệu & AI', 'Ngoại ngữ', 'Chính trị & Xã hội', 'Tốt nghiệp'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.account_tree_rounded, size: 20),
            SizedBox(width: 8),
            Text('Sơ Đồ Cây Môn Học Tiên Quyết', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isGraphView ? 'Xem dạng Danh sách chi tiết' : 'Xem dạng Sơ đồ Cây',
            icon: Icon(_isGraphView ? Icons.view_list_rounded : Icons.account_tree_rounded),
            onPressed: () => setState(() => _isGraphView = !_isGraphView),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Banner Tiến độ tích lũy động
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x261E3A8A),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Lộ Trình Tích Lũy: ${profile.fullName} (${profile.studentId})',
                          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$progressPercent% chặng đường',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã tích lũy: $passedCredits / $totalDegreeCredits Tín chỉ',
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Còn lại: $remainingCredits TC (Dự kiến tốt nghiệp: 2027)',
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Category Chips Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: const Color(0xFF1E3A8A),
                      labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF1E293B)),
                      backgroundColor: const Color(0xFFF1F5F9),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Legend Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8F0),
              border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
            ),
            child: const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _LegendBadge(color: Color(0xFF16A34A), label: '✅ Đã tích lũy (Đạt)'),
                  SizedBox(width: 14),
                  _LegendBadge(color: Color(0xFF2563EB), label: '📘 Đang xếp trong kỳ'),
                  SizedBox(width: 14),
                  _LegendBadge(color: Color(0xFFD97706), label: '⭐ Đủ điều kiện đăng ký'),
                  SizedBox(width: 14),
                  _LegendBadge(color: Color(0xFFDC2626), label: '❌ Chưa đủ tiên quyết'),
                ],
              ),
            ),
          ),

          // Main Roadmap Body
          Expanded(
            child: _isGraphView
                ? _buildTreeGraphView(context, planner, profile, activeCodes)
                : _buildListView(context, planner, profile, activeCodes),
          ),
        ],
      ),
    );
  }

  // --- 1. SƠ ĐỒ CÂY PHÂN NHÁNH TRỰC QUAN (TREE GRAPH VIEW) ---
  Widget _buildTreeGraphView(BuildContext context, PlannerProvider planner, dynamic profile, Set<String> activeCodes) {
    final Map<String, List<RoadmapNode>> grouped = {};
    for (final node in roadmap) {
      if (_selectedCategory != 'Tất cả' && node.category != _selectedCategory) {
        continue;
      }
      grouped.putIfAbsent(node.category, () => []).add(node);
    }

    if (grouped.isEmpty) {
      return const Center(
        child: Text('Không có môn học nào thuộc nhóm đã chọn.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: grouped.entries.map((entry) {
        final categoryName = entry.key;
        final nodes = entry.value;

        // Đếm số môn đã đạt trong nhóm
        final completedInTrack = nodes.where((n) => profile.passedCourses.contains(n.code)).length;

        IconData trackIcon;
        Color trackColor;
        switch (categoryName) {
          case 'Lập trình':
            trackIcon = Icons.code_rounded;
            trackColor = const Color(0xFF2563EB);
            break;
          case 'Mạng & Hạ tầng':
            trackIcon = Icons.lan_rounded;
            trackColor = const Color(0xFF0D9488);
            break;
          case 'Dữ liệu & AI':
            trackIcon = Icons.psychology_rounded;
            trackColor = const Color(0xFF7C3AED);
            break;
          case 'Ngoại ngữ':
            trackIcon = Icons.translate_rounded;
            trackColor = const Color(0xFFD97706);
            break;
          case 'Chính trị & Xã hội':
            trackIcon = Icons.auto_stories_rounded;
            trackColor = const Color(0xFFDC2626);
            break;
          default:
            trackIcon = Icons.school_rounded;
            trackColor = const Color(0xFF059669);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Track Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: trackColor.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  border: Border(bottom: BorderSide(color: trackColor.withValues(alpha: 0.2))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: trackColor, borderRadius: BorderRadius.circular(8)),
                      child: Icon(trackIcon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chuỗi $categoryName',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: trackColor),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: completedInTrack == nodes.length ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: completedInTrack == nodes.length ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        'Đạt: $completedInTrack / ${nodes.length} môn',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: completedInTrack == nodes.length ? const Color(0xFF15803D) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Track Tree Nodes with connecting arrows
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(nodes.length, (idx) {
                    final node = nodes[idx];
                    final isPassed = profile.passedCourses.contains(node.code);
                    final isInActivePlan = activeCodes.contains(node.code);
                    final missingPrereqs = node.prerequisites.where((p) => !profile.passedCourses.contains(p)).toList();
                    final isPrereqSatisfied = missingPrereqs.isEmpty;

                    return Column(
                      children: [
                        _buildTreeNodeCard(
                          context,
                          node: node,
                          isPassed: isPassed,
                          isInActivePlan: isInActivePlan,
                          isPrereqSatisfied: isPrereqSatisfied,
                          missingPrereqs: missingPrereqs,
                          planner: planner,
                        ),
                        if (idx < nodes.length - 1)
                          _buildTreeConnector(
                            fromNode: node,
                            toNode: nodes[idx + 1],
                            isPassed: isPassed,
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Node Card in Tree
  Widget _buildTreeNodeCard(
    BuildContext context, {
    required RoadmapNode node,
    required bool isPassed,
    required bool isInActivePlan,
    required bool isPrereqSatisfied,
    required List<String> missingPrereqs,
    required PlannerProvider planner,
  }) {
    Color cardBg;
    Color borderColor;
    Color badgeBg;
    Color badgeText;
    String statusText;
    IconData statusIcon;

    if (isPassed) {
      cardBg = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFF22C55E);
      badgeBg = const Color(0xFFDCFCE7);
      badgeText = const Color(0xFF15803D);
      statusText = 'ĐÃ TÍCH LŨY (ĐẠT)';
      statusIcon = Icons.check_circle_rounded;
    } else if (isInActivePlan) {
      cardBg = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFF3B82F6);
      badgeBg = const Color(0xFFDBEAFE);
      badgeText = const Color(0xFF1D4ED8);
      statusText = 'ĐANG XẾP TRONG KỲ';
      statusIcon = Icons.menu_book_rounded;
    } else if (isPrereqSatisfied) {
      cardBg = const Color(0xFFFEFCE8);
      borderColor = const Color(0xFFEAB308);
      badgeBg = const Color(0xFFFEF08A);
      badgeText = const Color(0xFF854D0E);
      statusText = 'ĐỦ ĐIỀU KIỆN ĐĂNG KÝ';
      statusIcon = Icons.star_rounded;
    } else {
      cardBg = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFEF4444);
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFFB91C1C);
      statusText = 'THIẾU TIÊN QUYẾT: ${missingPrereqs.join(", ")}';
      statusIcon = Icons.lock_clock_rounded;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showCourseNodeDetails(context, node, statusText, isPassed, isInActivePlan, isPrereqSatisfied),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.4),
        ),
        child: Row(
          children: [
            // Code Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                node.code,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            // Title & Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${node.credits} TC • Học kỳ ${node.semester}${node.prerequisites.isNotEmpty ? ' • Tiên quyết: ${node.prerequisites.join(", ")}' : ' • Cơ sở mở đầu'}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 13, color: badgeText),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Connecting line & arrow between nodes
  Widget _buildTreeConnector({required RoadmapNode fromNode, required RoadmapNode toNode, required bool isPassed}) {
    final bool isDirectPrereq = toNode.prerequisites.contains(fromNode.code);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDirectPrereq ? const Color(0xFFE2E8F0) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.south_rounded,
                  size: 15,
                  color: isPassed ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                ),
                if (isDirectPrereq) ...[
                  const SizedBox(width: 4),
                  Text(
                    'Tiên quyết cho ${toNode.code}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. DANH SÁCH CHI TIẾT (LIST VIEW) ---
  Widget _buildListView(BuildContext context, PlannerProvider planner, dynamic profile, Set<String> activeCodes) {
    final filtered = roadmap.where((n) {
      if (_selectedCategory != 'Tất cả' && n.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (ctx, idx) {
        final node = filtered[idx];
        final isPassed = profile.passedCourses.contains(node.code);
        final isInActivePlan = activeCodes.contains(node.code);
        final missingPrereqs = node.prerequisites.where((p) => !profile.passedCourses.contains(p)).toList();
        final isPrereqSatisfied = missingPrereqs.isEmpty;

        return _buildTreeNodeCard(
          context,
          node: node,
          isPassed: isPassed,
          isInActivePlan: isInActivePlan,
          isPrereqSatisfied: isPrereqSatisfied,
          missingPrereqs: missingPrereqs,
          planner: planner,
        );
      },
    );
  }

  // Course Node Details Bottom Sheet
  void _showCourseNodeDetails(
    BuildContext context,
    RoadmapNode node,
    String status,
    bool isPassed,
    bool isInActivePlan,
    bool isPrereqSatisfied,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(6)),
                  child: Text(node.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    node.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              node.description ?? 'Học phần thuộc chương trình đào tạo chuẩn Trường Đại học Tây Nguyên.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildInfoBadge('Khuyên học', 'Học kỳ ${node.semester}'),
                const SizedBox(width: 8),
                _buildInfoBadge('Số tín chỉ', '${node.credits} TC'),
                const SizedBox(width: 8),
                _buildInfoBadge('Phân hệ', node.category),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      node.prerequisites.isEmpty
                          ? 'Môn cơ sở mở đầu: Không yêu cầu điều kiện tiên quyết.'
                          : 'Điều kiện tiên quyết: Phải tích lũy trước ${node.prerequisites.join(", ")}.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

class _LegendBadge extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
      ],
    );
  }
}
