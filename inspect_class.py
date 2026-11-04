import re
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

with open('lib/services/ttn_database.dart', 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r"'(\d{8})':\s*\{\s*'studentId':\s*'(\d{8})',\s*'fullName':\s*'([^']+)'.*?'slotsCount':\s*(\d+)"
matches = re.findall(pattern, content, re.DOTALL)

active_list = []
inactive_list = []

for sid, sid2, name, count_str in matches:
    count = int(count_str)
    # Extract courses for active students
    idx = content.find(f"'{sid}':")
    sub = content[idx: idx + 4000]
    courses = list(set(re.findall(r"'courseName':\s*'([^']+)'", sub)))
    
    if count > 0:
        active_list.append((sid, name, count, courses))
    else:
        inactive_list.append((sid, name))

print(f"Tổng số sinh viên K23 CNTT điều tra được: {len(matches)}")
print(f"Số sinh viên đang theo học (Active): {len(active_list)}")
print(f"Số sinh viên đã nghỉ học / không có lịch: {len(inactive_list)}")

print("\n" + "="*80)
print(f"{'STT':<4} | {'MSSV':<10} | {'HỌ VÀ TÊN':<28} | {'SỐ CA':<6} | MÔN HỌC ĐĂNG KÝ")
print("="*80)
for i, (sid, name, cnt, crs) in enumerate(active_list, 1):
    crs_str = ", ".join(crs[:3]) + (f" (+{len(crs)-3} môn)" if len(crs) > 3 else "")
    print(f"{i:<4} | {sid:<10} | {name:<28} | {cnt:<6} | {crs_str}")

print("\n" + "="*80)
print("DANH SÁCH SINH VIÊN ĐÃ NGHỈ HỌC / THÔI HỌC (ĐÃ LOẠI TRỪ):")
print("="*80)
for i, (sid, name) in enumerate(inactive_list, 1):
    print(f"{i:<4} | {sid:<10} | {name:<28} | Đã nghỉ học / 0 ca học")

