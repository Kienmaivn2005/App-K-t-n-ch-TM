import urllib.request
import re
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

url = 'https://www.ttn.edu.vn/flipbook/sotaysinhvien2023/mobile/javascript/search_config.js'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req, timeout=20) as res:
    raw_data = res.read().decode('utf-8', errors='ignore')

# Extract array items by splitting or regex
prefix = 'var textForPages = ['
idx = raw_data.find(prefix)
if idx != -1:
    body = raw_data[idx + len(prefix):]
    # find closing bracket at the end
    end_idx = body.rfind('];')
    if end_idx != -1:
        body = body[:end_idx]

pages = []
pos = 0
n = len(body)
while pos < n:
    while pos < n and body[pos] in ' \t\r\n,':
        pos += 1
    if pos >= n:
        break
    if body[pos] == '"':
        pos += 1
        start = pos
        val_chars = []
        while pos < n:
            ch = body[pos]
            if ch == '\\':
                pos += 1
                if pos < n:
                    escaped = body[pos]
                    if escaped == 'n': val_chars.append('\n')
                    elif escaped == 't': val_chars.append('\t')
                    elif escaped == 'r': val_chars.append('\r')
                    elif escaped == '"': val_chars.append('"')
                    elif escaped == '\\': val_chars.append('\\')
                    elif escaped == '/': val_chars.append('/')
                    else: val_chars.append(escaped)
                pos += 1
            elif ch == '"':
                pos += 1
                break
            else:
                val_chars.append(ch)
                pos += 1
        pages.append(''.join(val_chars))
    else:
        pos += 1

print(f"Total extracted pages: {len(pages)}")

# Print Table of Contents (Pages 1, 2, 3, 4)
for i in range(1, min(6, len(pages))):
    print(f"=== Table of Contents Page {i} ===")
    print(pages[i])

# Search for Công nghệ thông tin curriculum pages
curriculum_pages = []
for i, page in enumerate(pages):
    p_lower = page.lower()
    if 'ngành công nghệ thông tin' in p_lower or 'công nghệ thông tin' in p_lower:
        # Check if it has course codes or table headers
        if 'mã hp' in p_lower or 'tên học phần' in p_lower or 'số tc' in p_lower or 'tiến trình' in p_lower or 'chương trình' in p_lower or '7480201' in page:
            curriculum_pages.append((i, page))

print(f"\nFound {len(curriculum_pages)} curriculum-related pages for CNTT:")
for p in curriculum_pages:
    print(f"- Page {p[0]}")

output = {
    "total_pages": len(pages),
    "cntt_curriculum_pages": [{"page_number": p[0], "content": p[1]} for p in curriculum_pages],
    "all_pages": [{"page_number": i, "content": page} for i, page in enumerate(pages) if 'công nghệ thông tin' in page.lower()]
}

os.makedirs('assets/data', exist_ok=True)
with open('assets/data/so_tay_sinh_vien_2023_cntt.json', 'w', encoding='utf-8') as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print("\nSaved to assets/data/so_tay_sinh_vien_2023_cntt.json")

