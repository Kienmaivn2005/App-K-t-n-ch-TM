import json
import re
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

with open('assets/data/cntt_k23_all_83_students.json', 'r', encoding='utf-8') as f:
    all_83 = json.load(f)

with open('lib/services/ttn_database.dart', 'r', encoding='utf-8') as f:
    dart_code = f.read()

current_keys = set(re.findall(r"'(\d{8})':\s*\{", dart_code))

print(f"Tổng số sinh viên trong JSON: {len(all_83)}")
print(f"Sinh viên đã có trong Dart: {len(current_keys)}")
missing_keys = [k for k in all_83.keys() if k not in current_keys]
print(f"Sinh viên cần bổ sung thêm vào Dart: {len(missing_keys)}")
print("Danh sách cần bổ sung:", missing_keys)

