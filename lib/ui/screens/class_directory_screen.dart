import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/planner_provider.dart';
import '../../services/ttn_database.dart';

class ClassDirectoryScreen extends StatefulWidget {
  const ClassDirectoryScreen({super.key});

  @override
  State<ClassDirectoryScreen> createState() => _ClassDirectoryScreenState();
}

class _ClassDirectoryScreenState extends State<ClassDirectoryScreen> {
  String _searchQuery = '';
  int _statusFilter = 1; // 1: Đang học (59), 0: Đã nghỉ (24), -1: Tất cả (83)

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final activeStudents = TTNDatabase.getActiveStudents();
    final inactiveStudents = TTNDatabase.getInactiveStudents();
    final allStudents = TTNDatabase.getAllStudents();

    final sourceList = _statusFilter == 1
        ? activeStudents
        : (_statusFilter == 0 ? inactiveStudents : allStudents);

    final filtered = sourceList.where((s) {
      final id = (s['studentId'] as String).toLowerCase();
      final name = (s['fullName'] as String).toLowerCase();
      final q = _searchQuery.toLowerCase();
      return id.contains(q) || name.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danh Sách Sinh Viên CNTT K23',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Trường Đại học Tây Nguyên (TNU) • Khóa 2023 - 2027',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF93C5FD)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới danh sách',
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã cập nhật danh sách 83 sinh viên!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stat Overview Cards
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildStatItem('Tổng Sĩ Số', '${allStudents.length} SV', const Color(0xFF1E3A8A), Icons.groups),
                const SizedBox(width: 8),
                _buildStatItem('Đang Theo Học', '${activeStudents.length} SV', const Color(0xFF166534), Icons.check_circle_outline),
                const SizedBox(width: 8),
                _buildStatItem('Đã Thôi Học', '${inactiveStudents.length} SV', const Color(0xFF991B1B), Icons.person_off_outlined),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Search and Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên sinh viên hoặc MSSV (vd: 23103022)...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),
                // Filter Choice Chips
                Row(
                  children: [
                    ChoiceChip(
                      label: Text(
                        'Đang học (${activeStudents.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _statusFilter == 1 ? FontWeight.bold : FontWeight.normal,
                          color: _statusFilter == 1 ? const Color(0xFF1E3A8A) : const Color(0xFF475569),
                        ),
                      ),
                      selected: _statusFilter == 1,
                      selectedColor: const Color(0xFFDBEAFE),
                      backgroundColor: const Color(0xFFF1F5F9),
                      onSelected: (_) => setState(() => _statusFilter = 1),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(
                        'Đã thôi học (${inactiveStudents.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _statusFilter == 0 ? FontWeight.bold : FontWeight.normal,
                          color: _statusFilter == 0 ? const Color(0xFF991B1B) : const Color(0xFF475569),
                        ),
                      ),
                      selected: _statusFilter == 0,
                      selectedColor: const Color(0xFFFEE2E2),
                      backgroundColor: const Color(0xFFF1F5F9),
                      onSelected: (_) => setState(() => _statusFilter = 0),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(
                        'Tất cả (${allStudents.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _statusFilter == -1 ? FontWeight.bold : FontWeight.normal,
                          color: _statusFilter == -1 ? const Color(0xFF0F172A) : const Color(0xFF475569),
                        ),
                      ),
                      selected: _statusFilter == -1,
                      selectedColor: const Color(0xFFE2E8F0),
                      backgroundColor: const Color(0xFFF1F5F9),
                      onSelected: (_) => setState(() => _statusFilter = -1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Results List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 10),
                        Text(
                          'Không tìm thấy sinh viên nào khớp với "$_searchQuery"',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final s = filtered[idx];
                      final sid = s['studentId'] as String;
                      final name = s['fullName'] as String;
                      final slotsCount = (s['slotsCount'] as int? ?? 0);
                      final isActive = slotsCount > 0;
                      final isCurrent = sid == planner.profile.studentId;
                      final slots = (s['slots'] as List<dynamic>? ?? []);

                      // Distinct courses
                      final courses = <String>{};
                      for (final sl in slots) {
                        if (sl is Map && sl['courseName'] != null) {
                          courses.add(sl['courseName'] as String);
                        }
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                            width: isCurrent ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isCurrent
                                        ? const Color(0xFFDBEAFE)
                                        : (isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9)),
                                    child: Text(
                                      name.isNotEmpty ? name[0] : 'S',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isCurrent
                                            ? const Color(0xFF1D4ED8)
                                            : (isActive ? const Color(0xFF166534) : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.5,
                                                color: isCurrent ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            if (isCurrent) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFDBEAFE),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Hồ sơ hiện tại',
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'MSSV: $sid • Lớp: ${s['cohort']} (${s['major']})',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isActive ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                                      ),
                                    ),
                                    child: Text(
                                      isActive ? 'Đang học ($slotsCount ca)' : 'Đã thôi học',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (courses.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: courses.map((c) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        c,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],

                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),

                              // Action Buttons
                              Row(
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.copy_rounded, size: 14),
                                    label: const Text('Copy MSSV', style: TextStyle(fontSize: 11.5)),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: sid));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Đã copy MSSV: $sid')),
                                      );
                                    },
                                  ),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isCurrent ? const Color(0xFF166534) : const Color(0xFF1E3A8A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: Icon(isCurrent ? Icons.check : Icons.visibility_rounded, size: 14),
                                    label: Text(
                                      isCurrent ? 'Đang Xem' : 'Xem Thời Khóa Biểu',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      planner.updateProfile(planner.profile.copyWith(
                                        studentId: sid,
                                        fullName: name,
                                      ));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Đã nạp thời khóa biểu của: $name ($sid)'),
                                          backgroundColor: const Color(0xFF1E3A8A),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.85), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
