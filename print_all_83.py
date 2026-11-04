import json
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

with open('assets/data/cntt_k23_all_83_students.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

active = [s for s in data.values() if s['slotsCount'] > 0]
inactive = [s for s in data.values() if s['slotsCount'] == 0]

print(f"Tổng: {len(data)}, Đang học: {len(active)}, Đã nghỉ: {len(inactive)}")

print("\n--- 59 SINH VIÊN ĐANG THEO HỌC (ACTIVE) ---")
for i, s in enumerate(active, 1):
    crs = ", ".join(s.get('courses', []))
    print(f"{i:<2}. MSSV: {s['studentId']} | Họ tên: {s['fullName']:<28} | {s['slotsCount']:<2} ca | Môn: {crs}")

print("\n--- 24 SINH VIÊN ĐÃ NGHỈ HỌC / THÔI HỌC (0 CA HỌC - ĐÃ LOẠI TRỪ) ---")
for i, s in enumerate(inactive, 1):
    print(f"{i:<2}. MSSV: {s['studentId']} | Họ tên: {s['fullName']:<28} | Đã nghỉ học")

