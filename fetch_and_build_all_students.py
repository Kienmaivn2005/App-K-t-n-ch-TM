import urllib.request
import urllib.parse
import re
import sys
import json

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

url = "https://www.ttn.edu.vn/libraries/tnu/tkbieusinhvien.php"
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    'Referer': 'https://ttn.edu.vn/index.php/component/tnu/?view=sinhvien'
}

with open('assets/data/cntt_k23_all_83_students.json', 'r', encoding='utf-8') as f:
    all_83 = json.load(f)

with open('lib/services/ttn_database.dart', 'r', encoding='utf-8') as f:
    dart_code = f.read()

current_keys = set(re.findall(r"'(\d{8})':\s*\{", dart_code))
missing_keys = [k for k in all_83.keys() if k not in current_keys]

print(f"Cần trích xuất lịch học chi tiết cho {len(missing_keys)} sinh viên mới...")

def parse_student_slots(html):
    # Regex to find table cells
    # Each row is a session (Sáng / Chiều / Tối)
    # 7 columns: Thứ 2 (2) -> CN (8)
    slots = []
    
    # Extract week date
    week_match = re.search(r'<p>(Từ ngày [^<]+)</p>', html)
    week_str = week_match.group(1).strip() if week_match else 'Từ ngày 19/10/2026 đến ngày 25/10/2026'

    # Extract all rows
    rows = re.findall(r'<tr>([\s\S]*?)</tr>', html)
    if not rows:
        return slots
    
    # Row 0 is header: Thứ 2 19/10, Thứ 3 20/10...
    headers = re.findall(r'<th>([\s\S]*?)</th>', rows[0])
    day_headers = {}
    for col_idx, h in enumerate(headers[1:], 2): # col 1 is Thứ/Buổi, col 2 is Thứ 2...
        clean_h = re.sub(r'<[^>]+>', ' ', h).strip()
        clean_h = re.sub(r'\s+', ' ', clean_h)
        day_headers[col_idx] = clean_h

    for r in rows[1:]:
        tds = re.findall(r'<td[^>]*>([\s\S]*?)</td>', r)
        if not tds: continue
        session_name = re.sub(r'<[^>]+>', '', tds[0]).strip()
        for col_idx, cell_content in enumerate(tds[1:], 2):
            if not cell_content.strip(): continue
            # Check if there is an HP in this cell
            # Format: HP: Lập trình di động (1-4)<br/>GV: Trương Thị Hương Giang<br/>Phòng: 7.3.18
            # or with PM:
            parts = [p.strip() for p in re.split(r'<br\s*/?>', cell_content) if p.strip()]
            if not parts: continue
            
            raw_title = parts[0]
            course_name = raw_title.replace('HP:', '').strip()
            period = ''
            period_m = re.search(r'\((\d+-\d+)\)', raw_title)
            if period_m:
                period = period_m.group(1)
                course_name = re.sub(r'\(\d+-\d+\)', '', course_name).strip()
            
            course_name = re.sub(r'\(\d+\.\d+/\d+\.\d+\)', '', course_name).strip()

            lecturer = ''
            room = ''
            platform = ''
            for p in parts[1:]:
                if p.startswith('GV:'):
                    lecturer = p.replace('GV:', '').strip()
                elif p.startswith('Phòng:'):
                    room = p.replace('Phòng:', '').strip()
                elif p.startswith('PM:'):
                    platform = p.replace('PM:', '').strip()

            slots.append({
                'week': week_str,
                'session': session_name,
                'dayIndex': col_idx,
                'dayHeader': day_headers.get(col_idx, f'Thứ {col_idx}'),
                'rawTitle': raw_title,
                'courseName': course_name,
                'period': period,
                'lecturer': lecturer,
                'room': room,
                'platform': platform
            })
    return slots

new_entries = []

for sid in missing_keys:
    data = urllib.parse.urlencode({'msv': sid, 'dk': '10'}).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers=headers)
    full_name = all_83[sid]['fullName']
    slots = []
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            html = resp.read().decode('utf-8', errors='ignore')
            slots = parse_student_slots(html)
    except Exception as e:
        print(f"Error {sid}: {e}")

    slots_count = len(slots)
    
    # Build Dart code block for this student
    entry = f"    '{sid}': {{\n"
    entry += f"      'studentId': '{sid}',\n"
    entry += f"      'fullName': '{full_name}',\n"
    entry += f"      'major': 'Công nghệ thông tin',\n"
    entry += f"      'cohort': 'K23',\n"
    entry += f"      'slotsCount': {slots_count},\n"
    entry += f"      'slots': [\n"
    for sl in slots:
        entry += f"        {{\n"
        entry += f"          'week': '{sl['week']}',\n"
        entry += f"          'session': '{sl['session']}',\n"
        entry += f"          'dayIndex': {sl['dayIndex']},\n"
        entry += f"          'dayHeader': '{sl['dayHeader']}',\n"
        entry += f"          'rawTitle': '{sl['rawTitle']}',\n"
        entry += f"          'courseName': '{sl['courseName']}',\n"
        entry += f"          'period': '{sl['period']}',\n"
        entry += f"          'lecturer': '{sl['lecturer']}',\n"
        entry += f"          'room': '{sl['room']}',\n"
        if sl.get('platform'):
            entry += f"          'platform': '{sl['platform']}',\n"
        entry += f"        }},\n"
    entry += f"      ],\n"
    entry += f"    }},\n"
    
    new_entries.append(entry)
    status_str = f"ĐANG HỌC ({slots_count} ca)" if slots_count > 0 else "ĐÃ NGHỈ HỌC"
    print(f"Parsed {sid} - {full_name}: {status_str}")

# Insert before '  };' at end of students map
target_end = "  };\n\n  /// Tra cứu sinh viên theo MSSV"
if target_end in dart_code:
    replacement = "".join(new_entries) + target_end
    new_dart = dart_code.replace(target_end, replacement, 1)
    # Update header comment
    new_dart = new_dart.replace("/// 44 Sinh viên Khóa K23", "/// 83 Sinh viên Khóa K23 (59 đang học, 24 đã nghỉ học)")
    with open('lib/services/ttn_database.dart', 'w', encoding='utf-8') as f:
        f.write(new_dart)
    print("\n===> ĐÃ CẬP NHẬT THÀNH CÔNG TOÀN BỘ 83 SINH VIÊN VÀO lib/services/ttn_database.dart!")
else:
    print("TARGET END NOT FOUND")

