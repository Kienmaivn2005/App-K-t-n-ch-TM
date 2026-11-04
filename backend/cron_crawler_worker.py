"""
WORKER TỰ ĐỘNG THU THẬP & ĐỒNG BỘ DỮ LIỆU ĐÀO TẠO (CRON CRAWLER WORKER)
Trường Đại học Tây Nguyên (TTN) - UniPlan AI System

Nhiệm vụ:
1. Định kỳ (Cron schedule) hoặc khi có yêu cầu kích hoạt, kết nối đến cổng portal trường (ttn.edu.vn).
2. Trích xuất thời khóa biểu chính xác theo từng tuần, từng buổi, từng ngày cho mọi mã sinh viên (MSSV).
3. Bóc tách môn học: mã/tên học phần, thứ, tiết học, phòng học, giảng viên, ngày học cụ thể và tuần học.
4. Hỗ trợ nhận diện các tuần trống (hết môn / nghỉ thi) khớp 100% Cổng đào tạo trường.
5. Cập nhật và đồng bộ dữ liệu vào hệ thống UniPlan AI.
"""

import sys
import io
import json
import time
import datetime
import urllib.request
import urllib.parse
import ssl
import re

# Đảm bảo in Tiếng Việt UTF-8 chuẩn trên Windows Console
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8')

# Cấu hình Cổng đào tạo Trường Đại học Tây Nguyên (TTN)
TTN_CONFIG = {
    'GRADES_URL': 'https://www.ttn.edu.vn/libraries/tnu/kqcq.php',
    'GRADES_REFERER': 'https://www.ttn.edu.vn/index.php?option=com_tnu&view=kqchinhquy',
    'SCHEDULE_URL': 'https://www.ttn.edu.vn/libraries/tnu/tkbieusinhvien.php',
    'SCHEDULE_REFERER': 'https://www.ttn.edu.vn/index.php/component/tnu/?view=sinhvien',
    'COMMON_HEADERS': {
        'Host': 'www.ttn.edu.vn',
        'Origin': 'https://www.ttn.edu.vn',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36',
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'X-Requested-With': 'XMLHttpRequest'
    }
}

# SSL context bỏ qua chứng chỉ tự ký nếu có
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

# Hàng đợi & chống cào lặp đồng thời (In-flight sync tracking)
in_flight_schedule_syncs = set()
in_flight_grade_syncs = set()

# Thời gian sống của Cache (TTL)
TTL_GRADES_SEC = 12 * 3600    # 12 giờ cho Điểm thi
TTL_SCHEDULE_SEC = 24 * 3600  # 24 giờ cho Thời khóa biểu


def clean_name(name):
    """Làm sạch chuỗi tên môn học hoặc họ tên sinh viên"""
    if not name:
        return ""
    cleaned = re.sub(r'[\(\[\-]?\s*(trạng thái|đang học).*?[\)\]]?', '', name, flags=re.IGNORECASE)
    cleaned = re.sub(r'^[:\-\s]+|[:\-\s]+$', '', cleaned)
    cleaned = re.sub(r'\s*\)+$', '', cleaned)
    cleaned = re.sub(r'\s*\({2,}', '(', cleaned)
    return cleaned.strip()


def extract_full_name_from_html(html_content):
    """Trích xuất họ tên sinh viên từ HTML trả về của Cổng trường TTN"""
    if not html_content:
        return None

    # 1. Tìm theo mẫu chuẩn: "Họ tên: <b>Trần Thị Thu Hiền</b>"
    match = re.search(r'(?:Họ\s*và\s*tên|Họ\s*tên)\s*[:\-]\s*(?:<b>)?([^<]+)(?:</b>)?', html_content, re.IGNORECASE)
    if match and match.group(1):
        cleaned = re.sub(r'<\/?b>', '', match.group(1), flags=re.IGNORECASE)
        cleaned = re.sub(r'\s*\([^)]*trạng thái[^)]*\)', '', cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r'[-–—]\s*$', '', cleaned).strip()
        if len(cleaned) > 2:
            return clean_name(cleaned)

    # 2. Tìm theo thẻ bất kỳ chứa text "Họ tên:"
    for line in html_content.splitlines():
        if ('Họ và tên:' in line or 'Họ tên:' in line) and len(line) < 120:
            parts = re.split(r'[:\-]', line)
            if len(parts) > 1:
                candidate = parts[1].replace('</b>', '').replace('<b>', '')
                candidate = re.sub(r'\([^)]*trạng thái[^)]*\)', '', candidate, flags=re.IGNORECASE).strip()
                if len(candidate) > 2:
                    return clean_name(candidate)

    return None


def push_schedule_row(headers, col_idx, buoi, current_lesson, parsed_rows, week_range_text=''):
    """
    Tính toán thứ và ngày học chính xác theo quy chuẩn Cổng Đào Tạo TTN
    Khớp logic pushScheduleRow từ studentSyncService.js
    """
    header_idx = col_idx - 1
    day_str = headers[header_idx].strip() if 0 <= header_idx < len(headers) else "Thứ 2"
    day_name = "Thứ 2"
    ngay_hoc = None

    match = re.search(r'^(Thứ\s+\d+|CN|Chủ\s+nhật)(?:\s+(\d{1,2}/\d{1,2}(?:/\d{4})?))?', day_str, re.IGNORECASE)
    if match:
        raw_name = match.group(1)
        day_name = re.sub(r'chủ\s+nhật', 'CN', raw_name, flags=re.IGNORECASE)
        day_name = re.sub(r'\s+', ' ', day_name).strip()

        if match.group(2):
            d_str = match.group(2)
            if len(d_str.split('/')) == 2:
                year_match = re.search(r'\b(20\d{2})\b', week_range_text or '')
                year = year_match.group(1) if year_match else '2026'
                d_str = f"{d_str}/{year}"
            parts = d_str.split('/')
            ngay_hoc = f"{parts[0].zfill(2)}/{parts[1].zfill(2)}/{parts[2]}"
    elif 'CN' in day_str.upper() or 'chủ nhật' in day_str.lower():
        day_name = 'CN'
    else:
        day_name = day_str

    # Nếu chưa có ngày học từ cột header, tự động tính từ chuỗi "Từ ngày DD/MM/YYYY"
    if not ngay_hoc and week_range_text:
        w_match = re.search(r'(\d{1,2})/(\d{1,2})/(\d{4})', week_range_text)
        if w_match:
            try:
                mon_date = datetime.date(int(w_match.group(3)), int(w_match.group(2)), int(w_match.group(1)))
                day_num_match = re.search(r'\d+', day_name)
                day_num = 2
                if day_name.upper() == 'CN':
                    day_num = 1
                elif day_num_match:
                    day_num = int(day_num_match.group(0))

                offset = 6 if day_num == 1 else (day_num - 2)
                cur_date = mon_date + datetime.timedelta(days=offset)
                ngay_hoc = f"{str(cur_date.day).zfill(2)}/{str(cur_date.month).zfill(2)}/{cur_date.year}"
            except Exception:
                pass

    tiet = current_lesson.get('tiet') or ('1-4' if buoi == 'Sáng' else ('7-10' if buoi == 'Chiều' else '11-12'))
    phong = current_lesson.get('phong') or 'Chưa xếp'
    giang_vien = current_lesson.get('giang_vien') or 'Giảng viên'

    parsed_rows.append([
        day_name.strip(),
        current_lesson.get('ten_hp', ''),
        tiet,
        phong,
        giang_vien,
        ngay_hoc
    ])


def parse_table_rows(table_html, week_range_text=''):
    """
    Phân giải các dòng trong 1 bảng tuần thời khóa biểu: Header, Sáng, Chiều, Tối
    Khớp parseTableRows từ studentSyncService.js
    """
    rows = [["Ngày", "Tên môn học", "Tiết", "Phòng", "Giảng viên", "Ngày học"]]
    if not table_html:
        return rows

    tr_blocks = re.findall(r'<tr[^>]*>([\s\S]*?)</tr>', table_html, re.IGNORECASE)
    if not tr_blocks:
        return rows

    # 1. Trích xuất Header (bỏ qua cột đầu tiên là Thứ/Buổi)
    headers = []
    first_tr = tr_blocks[0]
    th_cells = re.findall(r'<t[hd][^>]*>([\s\S]*?)</t[hd]>', first_tr, re.IGNORECASE)
    for cell in th_cells[1:]:
        clean_text = re.sub(r'<br\s*/?>', ' ', cell, flags=re.IGNORECASE)
        clean_text = re.sub(r'<[^>]+>', '', clean_text)
        clean_text = re.sub(r'\s+', ' ', clean_text).strip()
        headers.append(clean_text)

    # 2. Trích xuất các dòng dữ liệu (Sáng, Chiều, Tối)
    for tr in tr_blocks[1:]:
        td_cells = re.findall(r'<td[^>]*>([\s\S]*?)</td>', tr, re.IGNORECASE)
        if not td_cells:
            continue

        buoi_raw = re.sub(r'<[^>]+>', '', td_cells[0]).strip()
        buoi = 'Sáng'
        if 'Chiều' in buoi_raw:
            buoi = 'Chiều'
        elif 'Tối' in buoi_raw:
            buoi = 'Tối'

        for col_idx in range(1, len(td_cells)):
            cell_html = td_cells[col_idx].strip()
            if 'HP:' not in cell_html:
                continue

            lines = re.split(r'<br\s*/?>', cell_html, flags=re.IGNORECASE)
            current_lesson = {'ten_hp': '', 'tiet': '', 'phong': '', 'giang_vien': ''}

            for raw_line in lines:
                line = re.sub(r'<[^>]+>', '', raw_line).strip()
                if not line:
                    continue

                if line.startswith('HP:'):
                    if current_lesson['ten_hp']:
                        push_schedule_row(headers, col_idx, buoi, current_lesson, rows, week_range_text)
                        current_lesson = {'ten_hp': '', 'tiet': '', 'phong': '', 'giang_vien': ''}

                    m = re.search(r'HP:\s*(.*?)\s*\(([\d\s\-–]+)\)', line)
                    if m:
                        current_lesson['ten_hp'] = m.group(1).strip()
                        current_lesson['tiet'] = m.group(2).replace('–', '-').replace(' ', '').strip()
                    else:
                        current_lesson['ten_hp'] = line.replace('HP:', '').strip()
                elif line.startswith('GV:'):
                    current_lesson['giang_vien'] = line.replace('GV:', '').strip()
                elif line.startswith('Phòng:'):
                    current_lesson['phong'] = line.replace('Phòng:', '').strip()

            if current_lesson['ten_hp']:
                push_schedule_row(headers, col_idx, buoi, current_lesson, rows, week_range_text)

    return rows


def parse_schedule_html_to_weeks(html_text):
    """
    Trích xuất toàn bộ các bảng thời khóa biểu trên trang web trường
    Khớp logic tìm thẻ table và 'Từ ngày' trong studentSyncService.js
    """
    parsed_weeks = []
    if not html_text:
        return parsed_weeks

    # Tìm tất cả khối <p>Từ ngày... và <table>...
    pattern = re.compile(
        r'<p[^>]*>\s*(Từ\s*ngày\s*\d{1,2}/\d{1,2}/\d{4}\s*đến\s*ngày\s*\d{1,2}/\d{1,2}/\d{4})\s*</p>\s*<table[^>]*>([\s\S]*?)</table>',
        re.IGNORECASE
    )

    matches = pattern.findall(html_text)
    if matches:
        for idx, (week_range_text, table_html) in enumerate(matches):
            week_range_clean = re.sub(r'\s+', ' ', week_range_text).strip()
            rows = parse_table_rows(table_html, week_range_clean)
            parsed_weeks.append({
                'index': idx,
                'weekRangeText': week_range_clean,
                'rows': rows,
                'isEmptyWeek': len(rows) <= 1
            })
    else:
        # Fallback nếu cấu trúc bảng không có thẻ <p> bọc trực tiếp
        tables = re.findall(r'<table[^>]*>([\s\S]*?)</table>', html_text, re.IGNORECASE)
        for idx, table_html in enumerate(tables):
            week_range = f"Tuần {idx + 1}"
            rows = parse_table_rows(table_html, week_range)
            parsed_weeks.append({
                'index': idx,
                'weekRangeText': week_range,
                'rows': rows,
                'isEmptyWeek': len(rows) <= 1
            })

    return parsed_weeks


def sync_schedule_for_student(mssv, dk='10'):
    """
    Cào thời khóa biểu chính xác của 1 sinh viên bất kỳ từ cổng web trường TTN
    Khớp API syncScheduleForStudent(mssv, dk) từ studentSyncService.js
    """
    clean_mssv = str(mssv).strip()
    if not clean_mssv or clean_mssv.lower() == 'guest' or '@' in clean_mssv or len(clean_mssv) < 4:
        return {'success': False, 'message': 'MSSV không hợp lệ'}

    if clean_mssv in in_flight_schedule_syncs:
        return {'success': False, 'message': f'Đang tiến hành đồng bộ MSSV {clean_mssv}'}

    in_flight_schedule_syncs.add(clean_mssv)
    try:
        post_data = urllib.parse.urlencode({'msv': clean_mssv, 'mssv': clean_mssv, 'dk': str(dk)}).encode('utf-8')
        req = urllib.request.Request(
            TTN_CONFIG['SCHEDULE_URL'],
            data=post_data,
            headers={
                **TTN_CONFIG['COMMON_HEADERS'],
                'Referer': TTN_CONFIG['SCHEDULE_REFERER'],
                'Accept': 'text/plain, */*; q=0.01'
            }
        )

        with urllib.request.urlopen(req, timeout=15, context=ssl_context) as resp:
            html_text = resp.read().decode('utf-8', 'ignore')

        extracted_name = extract_full_name_from_html(html_text)
        parsed_weeks = parse_schedule_html_to_weeks(html_text)

        total_saved = 0
        flat_sections = []

        if parsed_weeks:
            for w in parsed_weeks:
                rows = w.get('rows', [])
                if len(rows) > 1:
                    for i in range(1, len(rows)):
                        r = rows[i]
                        item = {
                            'mssv': clean_mssv,
                            'ma_hp': f"HP-{w['index']}-{i}",
                            'ten_hp': r[1],
                            'thu': r[0],
                            'tiet': r[2],
                            'phong': r[3],
                            'giang_vien': r[4],
                            'hoc_ky': 'HK1 (2026-2027)',
                            'loai_lich': 'chinh_khoa',
                            'week_range': w['weekRangeText'],
                            'ngay_hoc': r[5]
                        }
                        flat_sections.append(item)
                        total_saved += 1
                else:
                    flat_sections.append({
                        'mssv': clean_mssv,
                        'ma_hp': f"EMPTY_WEEK_{w['index']}",
                        'ten_hp': '',
                        'thu': 'Thứ 2',
                        'tiet': '',
                        'phong': '',
                        'giang_vien': '',
                        'hoc_ky': 'HK1 (2026-2027)',
                        'loai_lich': 'empty_week',
                        'week_range': w['weekRangeText'],
                        'ngay_hoc': None
                    })

            return {
                'success': True,
                'mssv': clean_mssv,
                'studentName': extracted_name or f"Sinh viên {clean_mssv}",
                'count': total_saved,
                'totalWeeks': len(parsed_weeks),
                'weeks': parsed_weeks,
                'sections': flat_sections
            }

        return {'success': False, 'message': 'Không có bảng thời khóa biểu nào trả về từ web trường'}
    except Exception as e:
        return {'success': False, 'error': str(e)}
    finally:
        in_flight_schedule_syncs.discard(clean_mssv)


def sync_grades_for_student(mssv, dk='10'):
    """
    Cào bảng điểm của sinh viên từ web trường TTN
    Khớp API syncGradesForStudent(mssv, dk) từ studentSyncService.js
    """
    clean_mssv = str(mssv).strip()
    if not clean_mssv or clean_mssv.lower() == 'guest' or '@' in clean_mssv or len(clean_mssv) < 4:
        return {'success': False, 'message': 'MSSV không hợp lệ'}

    if clean_mssv in in_flight_grade_syncs:
        return {'success': False, 'message': f'Đang tiến hành đồng bộ điểm MSSV {clean_mssv}'}

    in_flight_grade_syncs.add(clean_mssv)
    try:
        post_data = urllib.parse.urlencode({'msv': clean_mssv, 'mssv': clean_mssv, 'dk': str(dk)}).encode('utf-8')
        req = urllib.request.Request(
            TTN_CONFIG['GRADES_URL'],
            data=post_data,
            headers={
                **TTN_CONFIG['COMMON_HEADERS'],
                'Referer': TTN_CONFIG['GRADES_REFERER'],
                'Accept': '*/*'
            }
        )

        with urllib.request.urlopen(req, timeout=15, context=ssl_context) as resp:
            html_text = resp.read().decode('utf-8', 'ignore')

        extracted_name = extract_full_name_from_html(html_text)
        return {
            'success': True,
            'mssv': clean_mssv,
            'studentName': extracted_name or f"Sinh viên {clean_mssv}",
            'rawHtmlBytes': len(html_text)
        }
    except Exception as e:
        return {'success': False, 'error': str(e)}
    finally:
        in_flight_grade_syncs.discard(clean_mssv)


def fetch_ttn_schedule_data(student_id="23103035"):
    """
    Hàm giao tiếp chuẩn với UniPlan AI Worker
    Trả về danh sách các lớp học phần đã bóc tách từ cổng ttn.edu.vn
    """
    print(f"[{datetime.datetime.now().isoformat()}] Worker khởi chạy crawl thời khóa biểu sinh viên: {student_id}")
    res = sync_schedule_for_student(student_id)
    if res.get('success'):
        sections = res.get('sections', [])
        print(f"[{datetime.datetime.now().isoformat()}] Thu thập thành công {res.get('count', 0)} tiết học trong {res.get('totalWeeks', 0)} tuần cho sinh viên {res.get('studentName')}")
        return sections
    else:
        print(f"[{datetime.datetime.now().isoformat()}] Thông báo: {res.get('message') or res.get('error')}")
        return []


def run_cron_cycle(test_students=None):
    """
    Vòng lặp Cron đồng bộ thời khóa biểu tự động có điều tiết tải (Pacing)
    """
    print("--- BẮT ĐẦU CHU KỲ CRON WORKER UNIPLAN AI (TTN PORTAL CRAWLER) ---")
    start_time = time.time()
    
    students_to_crawl = test_students or ["23103035", "24103035"]
    synced_count = 0

    for idx, msv in enumerate(students_to_crawl):
        print(f"\n[{idx + 1}/{len(students_to_crawl)}] Đang đồng bộ thời khóa biểu MSSV: {msv}...")
        res = sync_schedule_for_student(msv)
        if res.get('success'):
            synced_count += 1
            print(f"  ✓ {res.get('studentName')} ({msv}): {res.get('count')} buổi học, {res.get('totalWeeks')} tuần.")
            for w in res.get('weeks', [])[:2]:
                print(f"    - {w['weekRangeText']}: {len(w['rows']) - 1} buổi học (Tuần trống: {w['isEmptyWeek']})")
        else:
            print(f"  ✗ Thất bại: {res.get('message') or res.get('error')}")

        # Nghỉ 350ms giữa các request để bảo vệ cổng đào tạo trường
        time.sleep(0.35)

    duration = time.time() - start_time
    print(f"\n--- HOÀN TẤT ĐỒNG BỘ {synced_count}/{len(students_to_crawl)} SINH VIÊN TRONG {duration:.2f}s ---")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] != "--test":
        target_msv = sys.argv[1]
        run_cron_cycle([target_msv])
    else:
        run_cron_cycle()
