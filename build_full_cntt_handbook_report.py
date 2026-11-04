import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Read raw text of CNTT handbook
with open('assets/data/ttn_cntt_raw_handbook_pages.txt', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's parse each semester's courses
semesters_data = {}
current_sem = None

lines = text.splitlines()
i = 0
n = len(lines)

while i < n:
    line = lines[i].strip()
    # Check for semester header
    m_sem = re.search(r'HỌC KỲ\s*(\d+)', line, re.IGNORECASE)
    if m_sem:
        current_sem = int(m_sem.group(1))
        semesters_data[current_sem] = {
            "semester": current_sem,
            "courses": [],
            "summary": ""
        }
        i += 1
        continue
    
    # Check for course row (starts with number and course code)
    # Example: 1  FL211011     Tiếng Anh 1                                     3      3     0     3
    # Or: 10  KC213629  Phát triển phần mềm hướng đối tượng                2     2     0           2
    m_course = re.match(r'^(\d+)\s+([A-Z]{2}\d{6})\s+(.+)$', line)
    if m_course and current_sem:
        num = int(m_course.group(1))
        code = m_course.group(2)
        rest = m_course.group(3).strip()
        
        # parse the trailing numbers: Total, LT, TH, BB, TC
        tokens = rest.split()
        # Find where numbers start from the end
        # Sometimes numbers are separated like "3 3 0 3" or "1 0 1 1" or "2 1.5 0.5 2"
        # Let's extract trailing float/int numbers
        num_tokens = []
        name_tokens = []
        for t in reversed(tokens):
            t_clean = t.replace(',', '.')
            try:
                val = float(t_clean)
                if len(num_tokens) < 5:
                    num_tokens.insert(0, t)
                else:
                    name_tokens.insert(0, t)
            except ValueError:
                name_tokens.insert(0, t)
        
        name = ' '.join(name_tokens)
        semesters_data[current_sem]["courses"].append({
            "stt": num,
            "code": code,
            "name": name,
            "raw_credits": num_tokens
        })
    elif 'Tổng kỳ' in line or 'Tổng Học kỳ' in line:
        if current_sem:
            semesters_data[current_sem]["summary"] = line
            
    i += 1

print(f"Parsed {len(semesters_data)} semesters!")
for sem, d in sorted(semesters_data.items()):
    print(f"Học kỳ {sem}: {len(d['courses'])} học phần. {d['summary']}")

with open('assets/data/so_tay_sinh_vien_2023_cntt_parsed.json', 'w', encoding='utf-8') as f:
    json.dump(semesters_data, f, ensure_ascii=False, indent=2)

