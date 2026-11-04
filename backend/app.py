"""
HỆ THỐNG LẬP KẾ HOẠCH ĐĂNG KÝ TÍN CHỈ THÔNG MINH (UNIPLAN AI)
RESTful API Backend Service - Trường Đại học Tây Nguyên (TTN)
Cung cấp các API:
1. /api/v1/auth/login, /api/v1/auth/register, /api/v1/auth/me
2. /api/v1/majors, /api/v1/courses, /api/v1/sections, /api/v1/curriculum/<major_code>
3. /api/v1/schedule/solve (Bộ giải Constraint Satisfaction Problem - CSP Server-side)
4. /api/v1/schedule/sync, /api/v1/schedule/saved/<mssv> (Đồng bộ Cloud đa nền tảng)
5. /api/v1/crawler/trigger, /api/v1/crawler/status (Worker cập nhật lớp học phần)
"""

import json
import time
import uuid
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# MOCK IN-MEMORY DATABASE & KNOWLEDGE BASE TTN
MOCK_USERS = {
    "23103022": {
        "id": "usr_23103022",
        "mssv": "23103022",
        "fullName": "Lê Xuân Hoàng",
        "email": "lxhoang.23103022@ttn.edu.vn",
        "role": "STUDENT",
        "major": "Công nghệ thông tin",
        "faculty": "Khoa Kỹ thuật - Công nghệ",
        "cohort": "K23",
        "currentGpa": 3.42,
        "trainingPoints": 85,
        "academicWarning": 0,
        "maxCredits": 24,
    },
    "23103035": {
        "id": "usr_23103035",
        "mssv": "23103035",
        "fullName": "Mai Đàm Thế Kiên",
        "email": "mdtkien.23103035@ttn.edu.vn",
        "role": "STUDENT",
        "major": "Công nghệ thông tin",
        "faculty": "Khoa Kỹ thuật - Công nghệ",
        "cohort": "K23",
        "currentGpa": 2.17,
        "trainingPoints": 80,
        "academicWarning": 0,
        "maxCredits": 24,
    }
}

MOCK_MAJORS = [
    {"code": "CNTT", "name": "Công nghệ thông tin", "faculty": "Khoa Kỹ thuật - Công nghệ", "totalCredits": 140},
    {"code": "SPTOAN", "name": "Sư phạm Toán học", "faculty": "Khoa Sư phạm", "totalCredits": 138},
    {"code": "QTKD", "name": "Quản trị kinh doanh", "faculty": "Khoa Kinh tế", "totalCredits": 135},
    {"code": "YDAKHOA", "name": "Y khoa", "faculty": "Khoa Y Dược", "totalCredits": 200},
    {"code": "KHCT", "name": "Khoa học cây trồng", "faculty": "Khoa Nông Lâm nghiệp", "totalCredits": 135},
]

MOCK_COURSES = [
    {
        "code": "KC212604",
        "name": "Kỹ thuật lập trình",
        "credits": 2,
        "theoryCredits": 2,
        "practiceCredits": 0,
        "department": "Khoa Kỹ thuật - Công nghệ",
        "recommendedSemester": 1,
        "prerequisites": ["KC211027"],
        "sections": [
            {
                "id": "KC212604_76098",
                "lecturer": "ThS. Nguyễn Văn Hải",
                "lecturerRating": 4.6,
                "campus": "Cơ sở chính",
                "capacity": 130,
                "enrolled": 7,
                "slots": [{"dayOfWeek": 2, "startPeriod": 6, "endPeriod": 8, "room": "3.1.05"}]
            },
            {
                "id": "KC212604_76099",
                "lecturer": "TS. Phan Thanh Bình",
                "lecturerRating": 4.8,
                "campus": "Cơ sở chính",
                "capacity": 80,
                "enrolled": 65,
                "slots": [{"dayOfWeek": 4, "startPeriod": 6, "endPeriod": 8, "room": "3.1.06"}]
            }
        ]
    },
    {
        "code": "KC213613",
        "name": "An toàn thông tin",
        "credits": 2,
        "theoryCredits": 2,
        "practiceCredits": 0,
        "department": "Khoa Kỹ thuật - Công nghệ",
        "recommendedSemester": 5,
        "prerequisites": ["KC215039"],
        "sections": [
            {
                "id": "KC213613_74293",
                "lecturer": "ThS. Trần Đình Hưng",
                "lecturerRating": 4.7,
                "campus": "Cơ sở chính",
                "capacity": 70,
                "enrolled": 67,
                "slots": [{"dayOfWeek": 3, "startPeriod": 6, "endPeriod": 8, "room": "6.12"}]
            }
        ]
    },
    {
        "code": "KC215046",
        "name": "Lập trình di động",
        "credits": 3,
        "theoryCredits": 2,
        "practiceCredits": 1,
        "department": "Khoa Kỹ thuật - Công nghệ",
        "recommendedSemester": 5,
        "prerequisites": ["KC213611"],
        "sections": [
            {
                "id": "KC215046_01",
                "lecturer": "Trương Thị Hương Giang",
                "lecturerRating": 4.85,
                "campus": "Cơ sở chính",
                "capacity": 60,
                "enrolled": 52,
                "slots": [{"dayOfWeek": 4, "startPeriod": 1, "endPeriod": 4, "room": "7.3.18"}]
            }
        ]
    },
    {
        "code": "FL211012",
        "name": "Tiếng Anh 2",
        "credits": 3,
        "theoryCredits": 3,
        "practiceCredits": 0,
        "department": "Khoa Sư phạm Ngoại ngữ",
        "recommendedSemester": 2,
        "prerequisites": ["FL211011"],
        "sections": [
            {
                "id": "FL211012_ONL",
                "lecturer": "Nguyễn Thị Mỹ Liên",
                "lecturerRating": 4.9,
                "campus": "Online",
                "platform": "MS Teams, mã: 3l3di28",
                "capacity": 150,
                "enrolled": 142,
                "slots": [
                    {"dayOfWeek": 7, "startPeriod": 1, "endPeriod": 4, "room": "Online"},
                    {"dayOfWeek": 7, "startPeriod": 7, "endPeriod": 10, "room": "Online"}
                ]
            }
        ]
    }
]

SAVED_SCHEDULES_STORE = {}

def check_slot_conflict(s1, s2):
    if s1["dayOfWeek"] != s2["dayOfWeek"]:
        return False
    return s1["startPeriod"] <= s2["endPeriod"] and s2["startPeriod"] <= s1["endPeriod"]

def check_section_conflict(sec1, sec2):
    for slot1 in sec1["slots"]:
        for slot2 in sec2["slots"]:
            if check_slot_conflict(slot1, slot2):
                return True
    return False

def solve_csp_schedules(courses_list, criteria):
    """
    Backtracking Constraint Satisfaction Problem Solver
    """
    solutions = []
    
    def backtrack(idx, current):
        if len(solutions) >= 50:
            return
        if idx == len(courses_list):
            solutions.append(dict(current))
            return
        
        course = courses_list[idx]
        for sec in course.get("sections", []):
            conflict = False
            for sel_sec in current.values():
                if check_section_conflict(sec, sel_sec):
                    conflict = True
                    break
            if not conflict:
                current[course["code"]] = sec
                backtrack(idx + 1, current)
                del current[course["code"]]

    backtrack(0, {})

    # Evaluate & Rank Solutions
    ranked_solutions = []
    for i, sol in enumerate(solutions):
        score = 100.0
        early_morning = 0
        weekend_slots = 0
        friday_slots = 0
        days = set()

        for sec in sol.values():
            for slot in sec["slots"]:
                days.add(slot["dayOfWeek"])
                if slot["startPeriod"] <= 2:
                    early_morning += 1
                if slot["dayOfWeek"] >= 7:
                    weekend_slots += 1
                if slot["dayOfWeek"] == 6:
                    friday_slots += 1
        
        if criteria.get("avoidEarlyMorning", True) and early_morning > 0:
            score -= early_morning * 10.0
        if criteria.get("noWeekend", True) and weekend_slots > 0:
            score -= weekend_slots * 15.0
        if criteria.get("freeFriday", False) and friday_slots > 0:
            score -= friday_slots * 12.0
        if criteria.get("minimizeDays", True):
            if len(days) <= 3:
                score += 10.0
            elif len(days) >= 5:
                score -= (len(days) - 4) * 8.0

        score = max(20.0, min(100.0, score))
        ranked_solutions.append({
            "id": f"sol_{i+1}",
            "title": f"Phương án Tối ưu #{i+1} ({score:.0f}% phù hợp)",
            "score": score,
            "totalDays": len(days),
            "earlyMorningSlots": early_morning,
            "sections": sol
        })

    ranked_solutions.sort(key=lambda s: s["score"], reverse=True)
    return ranked_solutions[:5]

class UniPlanApiHandler(BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")

    def _send_json_response(self, status_code, data):
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self._send_cors_headers()
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode("utf-8"))

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self):
        url = urlparse(self.path)
        path = url.path

        if path == "/api/v1/health":
            self._send_json_response(200, {
                "status": "UP",
                "service": "UniPlan AI TTN Backend",
                "version": "2.0.0",
                "timestamp": time.time()
            })
        elif path == "/api/v1/majors":
            self._send_json_response(200, {"success": True, "data": MOCK_MAJORS})
        elif path == "/api/v1/courses":
            self._send_json_response(200, {"success": True, "data": MOCK_COURSES})
        elif path.startswith("/api/v1/schedule/saved/"):
            mssv = path.split("/")[-1]
            saved = SAVED_SCHEDULES_STORE.get(mssv, [])
            self._send_json_response(200, {"success": True, "mssv": mssv, "plans": saved})
        elif path == "/api/v1/crawler/status":
            self._send_json_response(200, {
                "success": True,
                "lastSync": "2026-10-23T08:00:00Z",
                "status": "COMPLETED",
                "totalCourses": len(MOCK_COURSES),
                "schoolPortal": "ttn.edu.vn"
            })
        else:
            self._send_json_response(404, {"error": "Endpoint not found"})

    def do_POST(self):
        url = urlparse(self.path)
        path = url.path
        content_len = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_len).decode("utf-8")
        payload = json.loads(body) if body else {}

        if path == "/api/v1/auth/login":
            mssv = payload.get("mssv")
            user = MOCK_USERS.get(mssv)
            if user:
                token = f"jwt_ttn_{uuid.uuid4().hex[:16]}"
                self._send_json_response(200, {
                    "success": True,
                    "token": token,
                    "user": user
                })
            else:
                self._send_json_response(401, {"success": False, "message": "Mã sinh viên không tồn tại trong hệ thống TTN"})

        elif path == "/api/v1/schedule/solve":
            target_codes = payload.get("targetCourseCodes", [])
            criteria = payload.get("criteria", {})
            target_courses = [c for c in MOCK_COURSES if c["code"] in target_codes]
            if not target_courses:
                target_courses = MOCK_COURSES[:3]
            
            solutions = solve_csp_schedules(target_courses, criteria)
            self._send_json_response(200, {
                "success": True,
                "solutionsCount": len(solutions),
                "solutions": solutions
            })

        elif path == "/api/v1/schedule/sync":
            mssv = payload.get("mssv", "23103022")
            plans = payload.get("plans", [])
            SAVED_SCHEDULES_STORE[mssv] = plans
            self._send_json_response(200, {
                "success": True,
                "message": f"Đã đồng bộ {len(plans)} phương án lên Cloud TTN cho sinh viên {mssv}",
                "syncTime": time.time()
            })

        elif path == "/api/v1/crawler/trigger":
            self._send_json_response(200, {
                "success": True,
                "jobId": f"crawl_{uuid.uuid4().hex[:8]}",
                "message": "Đã kích hoạt worker crawl lịch học phần mới nhất từ ttn.edu.vn",
                "status": "QUEUED"
            })
        else:
            self._send_json_response(404, {"error": "Endpoint not found"})

def run_backend(port=8000):
    server_address = ("", port)
    httpd = HTTPServer(server_address, UniPlanApiHandler)
    print(f"UniPlan AI Backend running at http://localhost:{port}")
    httpd.serve_forever()

if __name__ == "__main__":
    run_backend()

