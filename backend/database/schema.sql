-- =============================================================================
-- TRƯỜNG ĐẠI HỌC TÂY NGUYÊN (TAY NGUYEN UNIVERSITY - TTN)
-- HỆ THỐNG LẬP KẾ HOẠCH ĐĂNG KÝ TÍN CHỈ THÔNG MINH (UNIPLAN AI)
-- CƠ SỞ DỮ LIỆU QUẢN LÝ ĐÀO TẠO & LẬP LỊCH TỰ ĐỘNG
-- Phiên bản: 2.0 (PostgreSQL / SQLite Compatible)
-- =============================================================================

PRAGMA foreign_keys = ON;

-- 1. BẢNG KHOA ĐÀO TẠO (FACULTIES)
CREATE TABLE IF NOT EXISTS faculties (
    id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    dean_name VARCHAR(150),
    office_location VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. BẢNG CHUYÊN NGÀNH (MAJORS)
CREATE TABLE IF NOT EXISTS majors (
    id VARCHAR(50) PRIMARY KEY,
    faculty_id VARCHAR(50) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    degree_level VARCHAR(50) DEFAULT 'Kỹ sư / Cử nhân',
    total_required_credits INT NOT NULL DEFAULT 140,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (faculty_id) REFERENCES faculties(id) ON DELETE CASCADE
);

-- 3. BẢNG NGƯỜI DÙNG / SINH VIÊN (USERS)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(50) PRIMARY KEY,
    mssv VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(30) DEFAULT 'STUDENT', -- 'STUDENT', 'ADVISOR', 'ADMIN'
    major_id VARCHAR(50),
    cohort VARCHAR(50) DEFAULT 'K23',
    current_gpa REAL DEFAULT 0.0,
    training_points INT DEFAULT 80, -- Điểm rèn luyện 0-100
    academic_warning_level INT DEFAULT 0, -- 0: Normal, 1: Mức 1 (Max 14 TC), 2: Mức 2 (Max 12 TC)
    advisor_name VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (major_id) REFERENCES majors(id) ON DELETE SET NULL
);

-- 4. BẢNG MÔN HỌC (COURSES)
CREATE TABLE IF NOT EXISTS courses (
    id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE, -- VD: KC212604, FL211012
    name VARCHAR(255) NOT NULL,
    credits INT NOT NULL DEFAULT 2,
    theory_credits INT NOT NULL DEFAULT 2,
    practice_credits INT NOT NULL DEFAULT 0,
    department VARCHAR(100) DEFAULT 'Khoa Kỹ thuật - Công nghệ',
    recommended_semester INT DEFAULT 1,
    category VARCHAR(50) DEFAULT 'Cơ sở ngành', -- 'Đại cương', 'Cơ sở ngành', 'Chuyên ngành'
    prerequisites TEXT DEFAULT '[]', -- JSON Array: ['KC211027']
    corequisites TEXT DEFAULT '[]',  -- JSON Array: ['KC212682']
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. BẢNG KHUNG CHƯƠNG TRÌNH ĐÀO TẠO THEO KHÓA (CURRICULUM)
CREATE TABLE IF NOT EXISTS curriculums (
    id VARCHAR(50) PRIMARY KEY,
    major_id VARCHAR(50) NOT NULL,
    cohort_year INT NOT NULL DEFAULT 2023, -- Khóa 2023
    course_id VARCHAR(50) NOT NULL,
    semester_index INT NOT NULL, -- Kỳ 1 -> 8
    is_mandatory BOOLEAN NOT NULL DEFAULT 1,
    group_elective_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (major_id) REFERENCES majors(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

-- 6. BẢNG LỚP HỌC PHẦN MỞ ĐĂNG KÝ (SECTIONS)
CREATE TABLE IF NOT EXISTS sections (
    id VARCHAR(50) PRIMARY KEY, -- VD: KC212604_76098
    course_id VARCHAR(50) NOT NULL,
    section_code VARCHAR(50) NOT NULL,
    semester VARCHAR(20) NOT NULL DEFAULT '1',
    academic_year VARCHAR(30) NOT NULL DEFAULT '2026-2027',
    lecturer_name VARCHAR(150) NOT NULL,
    lecturer_rating REAL DEFAULT 4.5,
    campus VARCHAR(50) DEFAULT 'Cơ sở chính',
    capacity INT NOT NULL DEFAULT 80,
    enrolled_count INT NOT NULL DEFAULT 0,
    is_online BOOLEAN DEFAULT 0,
    platform_info VARCHAR(255), -- VD: MS Teams, mã: 3l3di28
    color_hex INT DEFAULT 4280549867,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

-- 7. BẢNG KHUNG GIỜ / TIẾT HỌC LỚP HỌC PHẦN (SECTION_SLOTS)
CREATE TABLE IF NOT EXISTS section_slots (
    id VARCHAR(50) PRIMARY KEY,
    section_id VARCHAR(50) NOT NULL,
    day_of_week INT NOT NULL, -- 2: Thứ 2, ..., 7: Thứ 7, 8: Chủ Nhật
    start_period INT NOT NULL, -- 1 -> 12
    end_period INT NOT NULL,   -- 1 -> 12
    room VARCHAR(50) NOT NULL, -- 7.3.18, 3.1.05, Online
    building VARCHAR(50),
    week_range VARCHAR(50) DEFAULT '1-15',
    FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE
);

-- 8. BẢNG LƯU VẾT & PHƯƠNG ÁN THỜI KHÓA BIỂU CỦA SINH VIÊN (SAVED_SCHEDULES)
CREATE TABLE IF NOT EXISTS saved_schedules (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    plan_name VARCHAR(150) NOT NULL, -- VD: Phương án A (Ưu tiên sáng), Phương án B
    semester VARCHAR(20) NOT NULL DEFAULT '1',
    academic_year VARCHAR(30) NOT NULL DEFAULT '2026-2027',
    is_active BOOLEAN DEFAULT 0,
    total_credits INT NOT NULL DEFAULT 0,
    score REAL DEFAULT 100.0,
    selected_section_ids TEXT NOT NULL, -- JSON Array: ['KC212604_76098', ...]
    backup_section_ids TEXT,           -- JSON Object: {'KC212604': ['KC212604_76099']}
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 9. BẢNG LOG LỊCH SỬ ĐỒNG BỘ CRAWLER (SYNC_AUDIT_LOGS)
CREATE TABLE IF NOT EXISTS sync_audit_logs (
    id VARCHAR(50) PRIMARY KEY,
    source_url VARCHAR(255) NOT NULL,
    sync_status VARCHAR(50) NOT NULL, -- 'SUCCESS', 'FAILED', 'PARTIAL'
    total_courses_crawled INT DEFAULT 0,
    total_sections_crawled INT DEFAULT 0,
    execution_duration_ms INT DEFAULT 0,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    error_message TEXT
);

-- CHỈ MỤC TỐI ƯU HÓA TRUY VẤN XẾP LỊCH (INDEXES FOR FAST CSP LOOKUPS)
CREATE INDEX IF NOT EXISTS idx_users_mssv ON users(mssv);
CREATE INDEX IF NOT EXISTS idx_courses_code ON courses(code);
CREATE INDEX IF NOT EXISTS idx_sections_course ON sections(course_id);
CREATE INDEX IF NOT EXISTS idx_section_slots_day ON section_slots(day_of_week, start_period, end_period);
CREATE INDEX IF NOT EXISTS idx_saved_schedules_user ON saved_schedules(user_id);

