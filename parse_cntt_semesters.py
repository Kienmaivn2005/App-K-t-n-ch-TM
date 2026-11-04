import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open('assets/data/search_config.js', 'r', encoding='utf-8', errors='ignore') as f:
    raw_data = f.read()

prefix = 'var textForPages = ['
idx = raw_data.find(prefix)
body = raw_data[idx + len(prefix):raw_data.rfind('];')]

pages = []
pos = 0
n = len(body)
while pos < n:
    while pos < n and body[pos] in ' \t\r\n,': pos += 1
    if pos >= n: break
    if body[pos] == '"':
        pos += 1
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
    else: pos += 1

cntt_raw_pages = [pages[215], pages[216], pages[217], pages[218]]

# Save full raw text of CNTT
with open('assets/data/ttn_cntt_raw_handbook_pages.txt', 'w', encoding='utf-8') as f:
    for i, p in enumerate(cntt_raw_pages):
        f.write(f"\n==================== TRANG SỔ TAY CNTT {i+1} (Page index {215+i}) ====================\n")
        f.write(p)

print("Saved raw text of CNTT handbook pages to assets/data/ttn_cntt_raw_handbook_pages.txt")

# Now let's print line by line
for i, p in enumerate(cntt_raw_pages):
    print(f"\n==================== TRANG {i+1} ====================\n")
    for line in p.splitlines():
        if line.strip():
            print(line.strip())

