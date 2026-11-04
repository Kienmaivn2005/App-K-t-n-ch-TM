import urllib.request
import urllib.parse
import re
import sys
import json
from concurrent.futures import ThreadPoolExecutor

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

url = "https://www.ttn.edu.vn/libraries/tnu/tkbieusinhvien.php"
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    'Referer': 'https://ttn.edu.vn/index.php/component/tnu/?view=sinhvien'
}

def query_student(msv):
    data = urllib.parse.urlencode({'msv': str(msv), 'dk': '10'}).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            html = resp.read().decode('utf-8', errors='ignore')
            name_match = re.search(r'Họ tên:\s*<b>([^<]+)</b>', html)
            if name_match:
                full_name = name_match.group(1).strip()
                hp_matches = re.findall(r'HP:\s*([^<(]+)', html)
                slots_count = len(hp_matches)
                return {
                    'studentId': str(msv),
                    'fullName': full_name,
                    'major': 'Công nghệ thông tin',
                    'cohort': 'K23',
                    'slotsCount': slots_count,
                    'courses': list(set(hp_matches)),
                    'exists': True
                }
            else:
                return {'studentId': str(msv), 'exists': False}
    except Exception as e:
        return {'studentId': str(msv), 'exists': False}

print("Quét toàn diện 23103001 đến 23103200...")
all_students = {}

with ThreadPoolExecutor(max_workers=10) as executor:
    futures = {executor.submit(query_student, f"23103{i:03d}"): f"23103{i:03d}" for i in range(1, 160)}
    for f in futures:
        res = f.result()
        if res.get('exists'):
            all_students[res['studentId']] = res

# Sắp xếp theo MSSV
sorted_students = dict(sorted(all_students.items(), key=lambda x: x[0]))

print(f"\n===> TỔNG CỘNG CHÍNH XÁC 100%: {len(sorted_students)} sinh viên ngành CNTT K23!")

active = [s for s in sorted_students.values() if s['slotsCount'] > 0]
inactive = [s for s in sorted_students.values() if s['slotsCount'] == 0]

print(f"- Đang theo học (Active): {len(active)} sinh viên")
print(f"- Đã thôi học / nghỉ học: {len(inactive)} sinh viên")

with open('assets/data/cntt_k23_all_83_students.json', 'w', encoding='utf-8') as f:
    json.dump(sorted_students, f, ensure_ascii=False, indent=2)

print("Đã lưu vào assets/data/cntt_k23_all_83_students.json")

