import json

data = json.load(open('assets/data/so_tay_sinh_vien_2023_cntt_clean.json', encoding='utf-8'))

out = """/// Dữ liệu Chương trình đào tạo ngành Công nghệ thông tin (Mã ngành: 7480201)
/// Trích xuất từ Sổ tay Sinh viên 2023 Trường Đại học Tây Nguyên (ttn.edu.vn - QĐ 1574/QĐ-ĐHTN)
class TTNHandbookCourse {
  final int stt;
  final String code;
  final String name;
  final int semester;
  final int credits;
  final double theoryCredits;
  final double practiceCredits;
  final bool isMandatory;
  final String note;

  const TTNHandbookCourse({
    required this.stt,
    required this.code,
    required this.name,
    required this.semester,
    required this.credits,
    required this.theoryCredits,
    required this.practiceCredits,
    required this.isMandatory,
    this.note = '',
  });
}

class TTNHandbookDatabase {
  static const String majorName = 'Công nghệ thông tin';
  static const String majorCode = '7480201';
  static const String faculty = 'Khoa Khoa học Tự nhiên và Công nghệ';
  static const int totalCredits = 145;
  static const String decision = 'Quyết định số 1574/QĐ-ĐHTN ngày 24/8/2021 của Hiệu trưởng Trường ĐH Tây Nguyên';

  static const List<TTNHandbookCourse> allCourses = [
"""

for sem_str in sorted(data.keys(), key=int):
    sem = int(sem_str)
    c_list = data[sem_str]['courses']
    for c in c_list:
        stt = c['stt']
        code = c['code']
        name = c['name']
        nums = c['numbers']
        
        # Determine credits:
        # nums usually has [total, lt, th, bb] or [total, lt, th]
        tc = 2
        lt = 2.0
        th = 0.0
        is_bb = True
        
        try:
            if len(nums) >= 4:
                tc = int(float(nums[0]))
                lt = float(nums[1])
                th = float(nums[2])
                # if 4th exists, check if bb or tc
                is_bb = (float(nums[3]) > 0)
            elif len(nums) == 3:
                tc = int(float(nums[0]))
                lt = float(nums[1])
                th = float(nums[2])
            elif len(nums) >= 1:
                tc = int(float(nums[0]))
        except Exception:
            pass

        # fix some special names if needed
        clean_name = name.replace("'", "\\'")
        out += f"    TTNHandbookCourse(stt: {stt}, code: '{code}', name: '{clean_name}', semester: {sem}, credits: {tc}, theoryCredits: {lt}, practiceCredits: {th}, isMandatory: {str(is_bb).lower()}),\n"

out += """  ];

  static List<TTNHandbookCourse> getCoursesBySemester(int semester) {
    return allCourses.where((c) => c.semester == semester).toList();
  }

  static TTNHandbookCourse? getCourseByCode(String code) {
    try {
      return allCourses.firstWhere((c) => c.code.toUpperCase() == code.toUpperCase().trim());
    } catch (_) {
      return null;
    }
  }
}
"""

with open('lib/services/ttn_handbook_data.dart', 'w', encoding='utf-8') as f:
    f.write(out)

print("Generated lib/services/ttn_handbook_data.dart successfully!")

