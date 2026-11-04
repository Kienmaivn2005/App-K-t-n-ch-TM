import json
import sys

sys.stdout.reconfigure(encoding='utf-8')
data = json.load(open('assets/data/so_tay_sinh_vien_2023_cntt.json', encoding='utf-8'))
print('Keys:', list(data.keys()))
print('Total pages:', data.get('total_pages'))
print('cntt_curriculum_pages count:', len(data.get('cntt_curriculum_pages', [])))
for p in data.get('cntt_curriculum_pages', []):
    print(f"=== Page {p['page_number']} ===")
    for line in p['content'].splitlines():
        if line.strip():
            print(' ', line.strip())

print('\nAll pages with CNTT mentioned:')
for p in data.get('all_pages', []):
    print(f"Page {p['page_number']}")

