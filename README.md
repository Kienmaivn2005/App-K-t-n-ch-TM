# UniPlan AI - Hệ Thống Lập Kế Hoạch Đăng Ký Tín Chỉ Thông Minh (Flutter)

Ứng dụng Flutter đa nền tảng (**Web**, **Windows Desktop**, **Android**, **iOS**) hỗ trợ sinh viên lập kế hoạch đăng ký tín chỉ thông minh, tối ưu thời khóa biểu, phát hiện xung đột và dự toán học phí tự động.

---

## 🌟 6 Nhóm Chức Năng Cốt Lõi Đã Hoàn Thiện

### 1. 🔍 Tra cứu & Lọc Danh mục Học phần (Course Catalog & Filter)
- **Tìm kiếm tức thì**: Lọc theo Mã môn (CS201, SE301...), Tên môn học, Giảng viên.
- **Bộ lọc đa tiêu chí**: Khoa/Viện (Khoa học máy tính, Kỹ thuật phần mềm, Hệ thống thông tin, Toán-Tin...), Số tín chỉ (3, 4 TC), Học kỳ gợi ý (HK3 - HK6), Phân loại môn (Đại cương, Cơ sở ngành, Chuyên ngành bắt buộc, Tự chọn).
- **Cây điều kiện tiên quyết trực quan**: Xem sơ đồ/danh sách môn tiên quyết, hiển thị trạng thái Đã tích lũy (Passed), Đang chọn, hoặc Chưa đạt.
- **Chọn lớp học phần trực tiếp**: Hiển thị giảng viên, điểm đánh giá ★, phòng học, cơ sở, sĩ số còn trống.

### 2. ⚡ Hệ thống Kiểm tra Xung đột & Ràng buộc Thông minh (Smart Conflict & Constraint Checker)
- **Phát hiện trùng lịch học (Time Overlap)**: Bắt lỗi chi tiết các lớp trùng thứ & tiết học; viền đỏ cảnh báo trên ô thời khóa biểu.
- **Kiểm tra vi phạm môn tiên quyết**: So khớp tự động với hồ sơ điểm của sinh viên; chặn đăng ký nếu môn tiên quyết chưa đạt.
- **Giới hạn số lượng tín chỉ quy chế (12 - 24 TC)**: Cảnh báo thiếu tín chỉ (< 12 TC) hoặc vượt quá hạn mức tối đa (> 24 TC).
- **Cảnh báo di chuyển cơ sở sát giờ**: Cảnh báo khi ca sáng và ca chiều học ở hai cơ sở khác nhau.
- **Banner trạng thái thời gian thực**: Thanh thông báo đầu trang hiển thị tổng số Lỗi (Error) & Cảnh báo (Warning) kèm modal giải thích chi tiết.

### 3. 📅 Thời khóa biểu Tuần trực quan (Interactive Timetable Grid & List)
- **Lưới 7 ngày (Thứ 2 đến Chủ Nhật)**, 12 tiết chuẩn (Sáng: 1-5, Chiều: 6-10, Tối: 11-12) kèm khung giờ thực tế.
- **Mã màu học phần riêng biệt**: Phân biệt trực quan từng môn học.
- **Tương tác linh hoạt**: Nhấp vào ca học để xem chi tiết, đổi sang lớp học phần khác của cùng môn hoặc xóa khỏi lịch ngay trên lưới.
- **Chế độ xem kép**: Chuyển đổi giữa **Lưới tuần (Grid View)** và **Danh sách ngày (List View)** tối ưu cho điện thoại.

### 4. 🤖 Trợ lý AI Tự động Xếp Lịch Tối Ưu (Smart Auto-Scheduler Engine)
- **Thuật toán Constraint Satisfaction Problem (CSP) + Heuristic Ranking**:
  - Không học sáng sớm (Né tiết 1-2, bắt đầu từ tiết 3 trở đi).
  - Nghỉ trọn vẹn cuối tuần (Không có lịch Thứ 7 & Chủ Nhật).
  - Gom lịch học (Tối thiểu số ngày tới trường, chỉ 3-4 ngày/tuần).
  - Tránh tiết trống/cửa sổ (Học liền mạch, không phải ngồi chờ 2-3 tiếng).
  - Ưu tiên giảng viên có rating cao (4.7★+).
- **Xếp hạng phương án theo Match Score (%)**: Hiển thị điểm số phù hợp, ưu điểm nổi bật, và nút 1-click **"Áp dụng ngay"** hoặc **"Lưu thành phương án mới"**.

### 5. 💰 Dự toán Học phí & Thống kê Tín chỉ (Tuition Estimator & Analytics)
- Thống kê chi tiết tín chỉ: Tổng số tín chỉ, Tín chỉ Lý thuyết, Tín chỉ Thực hành (hệ số phụ phí 1.2x).
- Đơn giá linh hoạt theo hệ đào tạo: Chương trình Chuẩn, Chất lượng cao, Tiên tiến / Quốc tế.
- **Mô phỏng Học bổng Khuyến khích học tập**: Tự động tính miễn giảm dựa trên GPA mục tiêu (Xuất sắc >= 3.6: 100%, Giỏi >= 3.2: 80%, Khá >= 2.8: 50%).
- **Chính sách miễn giảm xã hội**: Hộ nghèo (100%), Con thương binh (100%), Vùng sâu vùng xa (50%).
- Bảng kê chi tiết học phí từng môn và tổng tiền sinh viên thực nộp.

### 6. 📁 Quản lý Đa Phương án & Xuất Dữ liệu (Plan Manager & Export)
- **Đa phương án (Plan A, B, C...)**: Tạo mới, nhân bản, đổi tên, xóa phương án dự phòng khi mở cổng đăng ký.
- **Lưu trữ tự động (Auto-save)**: Lưu trạng thái vào `SharedPreferences` / LocalStorage.
- **Xuất file iCalendar (`.ics`) chuẩn RFC 5545**: Nhập trực tiếp vào Google Calendar, Apple Calendar, Outlook Calendar.
- **Mã chia sẻ cấu hình (Share Code Base64)**: Sinh viên sao chép mã gửi cho bạn bè để học cùng lớp chỉ với 1 click nhập mã.
- **Bản in ấn & tóm tắt text**: Sao chép tóm tắt TKB đẹp mắt gửi qua Zalo/Messenger hoặc in ra giấy.




---

## 🏗️ Cấu Trúc Mã Nguồn

```
lib/
├── main.dart                      # Điểm khởi chạy ứng dụng (Provider + Theme)
├── models/
│   ├── course.dart                # Model Môn học, Lớp HP, Khung giờ, Ca học
│   ├── plan.dart                  # Model Phương án đăng ký tín chỉ
│   ├── student_profile.dart       # Model Hồ sơ sinh viên, Bảng điểm tích lũy, Học phí
│   ├── conflict_issue.dart        # Model Lỗi xung đột & Cảnh báo ràng buộc
│   └── auto_schedule_options.dart # Model Tiêu chí AI & Kết quả xếp lịch
├── services/
│   ├── mock_data.dart             # Dữ liệu mô phỏng học phần, lớp học phần, môn tiên quyết
│   ├── conflict_checker.dart      # Bộ máy kiểm tra trùng tiết, tiên quyết, giới hạn 12-24 TC
│   ├── auto_scheduler.dart        # Thuật toán quay lui Heuristic CSP xếp lịch AI
│   ├── ical_export_service.dart   # Trình tạo file .ics chuẩn RFC 5545 cho Google Calendar
│   ├── share_service.dart         # Mã hóa/Giải mã Share Code Base64 & Tóm tắt in ấn
│   └── storage_service.dart       # Quản lý lưu trữ cục bộ (SharedPreferences + Memory)
├── providers/
│   └── planner_provider.dart      # Quản lý trạng thái tập trung (State Management)
└── ui/
    ├── theme/
    │   └── app_theme.dart         # Thiết kế Material 3 + Tailwind CSS Aesthetic
    ├── widgets/
    │   ├── conflict_banner.dart   # Banner thông báo lỗi & cảnh báo tức thì
    │   ├── stat_cards.dart        # Thẻ thống kê tín chỉ & học phí trên thanh đầu trang
    │   └── prerequisite_dialog.dart # Hộp thoại đồ thị/cây môn tiên quyết
    └── screens/
        ├── home_shell.dart        # Giao diện responsive (Sidebar Desktop & BottomNav Mobile)
        ├── course_catalog_screen.dart # Module 1: Tra cứu & Lọc học phần
        ├── timetable_screen.dart  # Module 3: Lưới TKB 7x12 tương tác & xem danh sách
        ├── auto_scheduler_screen.dart # Module 4: Trợ lý AI xếp lịch tối ưu
        ├── tuition_screen.dart    # Module 5: Dự toán học phí & học bổng
        ├── plan_manager_screen.dart # Module 6: Quản lý Phương án A/B/C & Xuất .ics
        └── profile_screen.dart    # Hồ sơ sinh viên & Bảng điểm hoàn thành
```

---

## 🚀 Hướng Dẫn Chạy Ứng Dụng

### 1. Chạy trên trình duyệt Web (Chrome / Edge)
```powershell
flutter run -d chrome
```

### 2. Chạy trên Windows Desktop
```powershell
flutter run -d windows
```

### 3. Build bản Web Production
```powershell
flutter build web --no-tree-shake-icons
```
Thư mục xuất bản sẵn sàng để deploy lên GitHub Pages, Vercel, Netlify hoặc Hosting tĩnh: `build/web/`.

### 4. Chạy kiểm thử tự động
```powershell
flutter test
```
\