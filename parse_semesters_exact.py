import re
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open('assets/data/ttn_cntt_raw_handbook_pages.txt', 'r', encoding='utf-8') as f:
    raw = f.read()

# Find all semesters
sem_splits = re.split(r'HỌC KỲ\s*(\d+)', raw)
semesters = {}

# sem_splits[0] is preamble
for i in range(1, len(sem_splits), 2):
    sem_num = int(sem_splits[i])
    sem_content = sem_splits[i+1]
    
    # Extract courses in this semester
    # Each course pattern: (\d+)\s+([A-Z]{2}\d{6})\s+(.+?)(?=\s+\d+\s+[A-Z]{2}\d{6}|\s+Tổng|\s+HỌC KỲ|$)
    course_matches = re.finditer(r'(?:^|\s)(\d{1,2})\s+([A-Z]{2}\d{6})\s+(.+?)(?=\s+\d{1,2}\s+[A-Z]{2}\d{6}|\s+Tổng|\s+HỌC KỲ|$)', sem_content)
    courses = []
    for cm in course_matches:
        stt = int(cm.group(1))
        code = cm.group(2)
        raw_text = cm.group(3).strip()
        
        # Parse tokens
        tokens = raw_text.split()
        num_tokens = []
        name_tokens = []
        for t in reversed(tokens):
            t_val = t.replace(',', '.')
            try:
                float(t_val)
                if len(num_tokens) < 5:
                    num_tokens.insert(0, t)
                else:
                    name_tokens.insert(0, t)
            except ValueError:
                name_tokens.insert(0, t)
        
        course_name = ' '.join(name_tokens)
        courses.append({
            "stt": stt,
            "code": code,
            "name": course_name,
            "numbers": num_tokens
        })
    
    # Extract Total credits summary
    m_tot = re.search(r'Tổng\s+(?:kỳ|Học kỳ)\s*\d*\s*(\d+)\s*(\d*)', sem_content)
    total_bb = m_tot.group(1) if m_tot else ""
    total_tc = m_tot.group(2) if m_tot else ""
    
    semesters[sem_num] = {
        "semester": sem_num,
        "total_bb": total_bb,
        "total_tc": total_tc,
        "courses_count": len(courses),
        "courses": courses
    }

print(f"Parsed {len(semesters)} semesters successfully!")
for sem in sorted(semesters.keys()):
    d = semesters[sem]
    print(f"\n==================== HỌC KỲ {sem} (Tổng: {d['total_bb']} BB + {d['total_tc']} TC, {d['courses_count']} môn) ====================")
    for c in d['courses']:
        print(f"  {c['stt']:2d}. [{c['code']}] {c['name']:<40} -> {c['numbers']}")

with open('assets/data/so_tay_sinh_vien_2023_cntt_clean.json', 'w', encoding='utf-8') as f:
    json.dump(semesters, f, ensure_ascii=False, indent=2)

