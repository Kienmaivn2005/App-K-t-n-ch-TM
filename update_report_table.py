import json

with open('assets/data/cntt_k23_all_83_students.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

active = [s for s in data.values() if s['slotsCount'] > 0]
inactive = [s for s in data.values() if s['slotsCount'] == 0]

md_active = "| STT | MSSV | Họ và tên | Chuyên ngành | Số ca học | Môn học đăng ký tiêu biểu |\n"
md_active += "| :---: | :---: | :--- | :--- | :---: | :--- |\n"
for i, s in enumerate(active, 1):
    crs = ", ".join(s.get('courses', []))
    md_active += f"| {i} | `{s['studentId']}` | {s['fullName']} | Công nghệ thông tin | {s['slotsCount']} | {crs} |\n"

md_inactive = "| STT | MSSV | Họ và tên | Tình trạng |\n"
md_inactive += "| :---: | :---: | :--- | :--- |\n"
for i, s in enumerate(inactive, 1):
    md_inactive += f"| {i} | `{s['studentId']}` | {s['fullName']} | Đã nghỉ học / 0 ca học |\n"

section_text = f"""### 1.7. Danh sách Toàn Khóa Sinh viên CNTT K23 (Khảo sát Hệ thống ĐH Tây Nguyên)
Qua quá trình quét toàn diện trực tiếp trên cổng đào tạo và cơ sở dữ liệu thời khóa biểu trường Đại học Tây Nguyên (`ttn.edu.vn/libraries/tnu/tkbieusinhvien.php`), toàn khóa Công nghệ thông tin K23 gồm:
- **Tổng số sinh viên K23 CNTT**: **{len(data)} sinh viên** (từ `23103003` đến `23103117`).
- **Số sinh viên đang theo học (Active - Có thời khóa biểu học kỳ)**: **{len(active)} sinh viên**.
- **Số sinh viên đã thôi học / nghỉ học (0 ca học - Đã loại trừ)**: **{len(inactive)} sinh viên**.

#### Bảng Danh sách {len(active)} Sinh viên Đang Theo Học Lớp CNTT K23:
{md_active}
#### Danh sách {len(inactive)} Sinh viên Đã Nghỉ học / Thôi học (Đã loại trừ khỏi danh sách lớp):
{md_inactive}
"""

with open('BAO_CAO_DE_TAI.md', 'r', encoding='utf-8') as f:
    doc = f.read()

import re
old_sec_pattern = r'### 1\.7\. Danh sách Thực tế Sinh viên[\s\S]*?(?=## GIAI ĐOẠN 2)'
doc_updated = re.sub(old_sec_pattern, section_text + "\n---\n\n", doc)

with open('BAO_CAO_DE_TAI.md', 'w', encoding='utf-8') as f:
    f.write(doc_updated)

print("Đã cập nhật BAO_CAO_DE_TAI.md thành công!")

