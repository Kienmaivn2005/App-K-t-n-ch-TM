import urllib.request
import urllib.parse
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

url = "https://www.ttn.edu.vn/libraries/tnu/tkbieusinhvien.php"
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    'Referer': 'https://ttn.edu.vn/index.php/component/tnu/?view=sinhvien'
}

data = urllib.parse.urlencode({'msv': '23103022', 'dk': '10'}).encode('utf-8')
req = urllib.request.Request(url, data=data, headers=headers)

try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        res = resp.read().decode('utf-8', errors='ignore')
        print(f"Status: {resp.status}, length: {len(res)}")
        print("First 500 chars:")
        print(res[:500])
except Exception as e:
    print("Error:", e)

