import urllib.request
import urllib.parse
import re
import sys
import time
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
            
            # Check if student exists
            # Format: Mã SV: <b>23103022</b> - Họ tên: <b>Lê Xuân Hoàng</b>
            name_match = re.search(r'Họ tên:\s*<b>([^<]+)</b>', html)
            if name_match:
                full_name = name_match.group(1).strip()
                # Check schedule content
                # count HP:
                hp_matches = re.findall(r'HP:\s*([^<(]+)', html)
                slots_count = len(hp_matches)
                return {
                    'studentId': str(msv),
                    'fullName': full_name,
                    'major': 'Công nghệ thông tin',
                    'cohort': 'K23',
                    'slotsCount': slots_count,
                    'courses': list(set(hp_matches)),
                    'html': html,
                    'exists': True
                }
            else:
                return {'studentId': str(msv), 'exists': False}
    except Exception as e:
        return {'studentId': str(msv), 'exists': False, 'error': str(e)}

# Scan from 23103001 to 23103120
print("Bắt đầu quét danh sách toàn bộ sinh viên ngành Công nghệ thông tin K23 (23103001 - 23103120)...")
results = {}

with ThreadPoolExecutor(max_workers=8) as executor:
    futures = {executor.submit(query_student, f"23103{i:03d}"): f"23103{i:03d}" for i in range(1, 110)}
    for f in futures:
        res = f.result()
        if res.get('exists'):
            results[res['studentId']] = res
            status_text = f"ĐANG HỌC ({res['slotsCount']} ca)" if res['slotsCount'] > 0 else "ĐÃ NGHỈ HỌC (0 ca)"
            print(f"-> Tìm thấy: {res['studentId']} | {res['fullName']} | {status_text}")

print(f"\n===> TỔNG CỘNG TÌM THẤY: {len(results)} sinh viên K23 CNTT trên hệ thống trường ĐH Tây Nguyên!")

# Check active vs inactive
active = [s for s in results.values() if s['slotsCount'] > 0]
inactive = [s for s in results.values() if s['slotsCount'] == 0]

print(f"- Đang học: {len(active)} sinh viên")
print(f"- Đã nghỉ học: {len(inactive)} sinh viên")

with open('assets/data/cntt_k23_full_crawled.json', 'w', encoding='utf-8') as f:
    # Save without raw html to keep clean
    clean_dict = {
        sid: {k: v for k, v in data.items() if k != 'html'}
        for sid, data in results.items()
    }
    json.dump(clean_dict, f, ensure_ascii=False, indent=2)
print("Đã lưu kết quả vào assets/data/cntt_k23_full_crawled.json")

