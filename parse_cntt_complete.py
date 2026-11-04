import sys
import json
import os

sys.stdout.reconfigure(encoding='utf-8')

with open('assets/data/search_config.js', 'r', encoding='utf-8', errors='ignore') as f:
    raw_data = f.read()

prefix = 'var textForPages = ['
idx = raw_data.find(prefix)
if idx != -1:
    body = raw_data[idx + len(prefix):]
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

print(f"Total pages loaded: {len(pages)}")

# Let's inspect pages 185 to 192
for i in range(185, 192):
    print(f"\n=======================================================")
    print(f"               PAGE INDEX {i}                          ")
    print(f"=======================================================\n")
    print(pages[i])

# Let's save the exact CNTT pages
cntt_full_curriculum = {
    "title": "Chương trình đào tạo ngành Công nghệ thông tin - Sổ tay sinh viên 2023 - ĐH Tây Nguyên",
    "major": "Công nghệ thông tin",
    "major_code": "7480201",
    "pages": [
        {"page_index": i, "content": pages[i]} for i in range(186, 190)
    ]
}

with open('assets/data/cntt_curriculum_2023.json', 'w', encoding='utf-8') as f:
    json.dump(cntt_full_curriculum, f, ensure_ascii=False, indent=2)

print("\nSaved full curriculum to assets/data/cntt_curriculum_2023.json")

