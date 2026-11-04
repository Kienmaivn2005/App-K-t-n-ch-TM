import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/planner_provider.dart';
import '../theme/app_theme.dart';
import 'course_catalog_screen.dart';
import 'timetable_screen.dart';
import 'auto_scheduler_screen.dart';
import 'tuition_screen.dart';
import 'plan_manager_screen.dart';
import 'profile_screen.dart';
import 'exam_schedule_screen.dart';
import 'auth_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 1; // Default to Timetable (index 1) or Catalog (index 0)

  final List<Widget> _screens = const [
    CourseCatalogScreen(),
    TimetableScreen(),
    AutoSchedulerScreen(),
    ExamScheduleScreen(),
    TuitionScreen(),
    PlanManagerScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = const [
    'Môn học',
    'Thời khóa biểu',
    'Xếp lịch tự động',
    'Lịch thi',
    'Ước tính học phí',
    'Kế hoạch dự phòng',
    'Lộ trình học tập',
  ];

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();

    if (planner.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Đang khởi tạo Đăng Ký Tín Chỉ...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (!planner.isAuthenticated) {
      return const AuthScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                _buildSidebar(planner),
                const VerticalDivider(width: 1, color: AppTheme.slate200),
                Expanded(
                  child: Scaffold(
                    appBar: _buildAppBar(planner),
                    body: _screens[_currentIndex],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(planner),
          body: _screens[_currentIndex],
          bottomNavigationBar: _buildBottomNav(planner),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(PlannerProvider planner) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titles[_currentIndex],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          Text(
            '${planner.activePlan.name} • ${planner.totalCredits} TC',
            style: const TextStyle(color: AppTheme.slate500, fontSize: 12),
          ),
        ],
      ),
      actions: [
        // Conflict Badge Indicator
        if (planner.hasErrors)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.dangerLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.danger),
                const SizedBox(width: 4),
                Text(
                  '${planner.errorCount} Lỗi',
                  style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          )
        else if (planner.hasWarnings)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warningLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.warning),
                const SizedBox(width: 4),
                Text(
                  '${planner.warningCount} Cảnh báo',
                  style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        PopupMenuButton<String>(
          tooltip: 'Tài khoản: ${planner.profile.fullName}',
          icon: CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primaryLight,
            child: Text(
              planner.profile.fullName.isNotEmpty ? planner.profile.fullName[0] : 'S',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          ),
          onSelected: (val) {
            if (val == 'profile') {
              setState(() => _currentIndex = 5);
            } else if (val == 'logout') {
              planner.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đăng xuất khỏi tài khoản!')),
              );
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(planner.profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('MSSV: ${planner.profile.studentId}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Đăng xuất tài khoản', style: TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSidebar(PlannerProvider planner) {
    return Container(
      width: 250,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đăng Ký Tín Chỉ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.3),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Smart Credit Planner • TTN',
                    style: TextStyle(color: AppTheme.slate500, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: AppTheme.slate200),
          const SizedBox(height: 12),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildSidebarItem(
                  icon: Icons.search_rounded,
                  label: 'Tra Cứu Học Phần',
                  index: 0,
                ),
                _buildSidebarItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Thời Khóa Biểu',
                  index: 1,
                  badgeText: '${planner.totalCredits} TC',
                ),
                _buildSidebarItem(
                  icon: Icons.alt_route_rounded,
                  label: 'Xếp Lịch Tự Động',
                  index: 2,
                  isSpecial: true,
                ),
                _buildSidebarItem(
                  icon: Icons.assignment_outlined,
                  label: 'Lịch Thi Học Kỳ',
                  index: 3,
                ),
                _buildSidebarItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Ước Tính Học Phí',
                  index: 4,
                ),
                _buildSidebarItem(
                  icon: Icons.layers_rounded,
                  label: 'Kế Hoạch Dự Phòng',
                  index: 5,
                  badgeText: '${planner.plans.length}',
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppTheme.slate200),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  icon: Icons.account_tree_rounded,
                  label: 'Lộ Trình Học Tập',
                  index: 6,
                ),
              ],
            ),
          ),
          // Student quick info at bottom of sidebar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryLight,
                  child: Text(
                    planner.profile.fullName.isNotEmpty ? planner.profile.fullName[0] : 'S',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planner.profile.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'MSSV: ${planner.profile.studentId}',
                        style: TextStyle(color: AppTheme.slate500, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF94A3B8)),
                  tooltip: 'Đăng xuất',
                  onPressed: () {
                    planner.logout();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã đăng xuất khỏi tài khoản!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required int index,
    String? badgeText,
    bool isSpecial = false,
  }) {
    final isSelected = _currentIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? (isSpecial ? AppTheme.secondaryLight : AppTheme.primaryLight)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isSelected
              ? (isSpecial ? AppTheme.secondary : AppTheme.primary)
              : AppTheme.slate600,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isSpecial ? AppTheme.secondary : AppTheme.primary)
                : AppTheme.slate700,
          ),
        ),
        trailing: badgeText != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.slate200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.slate700,
                  ),
                ),
              )
            : null,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildBottomNav(PlannerProvider planner) {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (idx) {
        setState(() {
          _currentIndex = idx;
        });
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.search_rounded),
          label: 'Học phần',
        ),
        NavigationDestination(
          icon: Badge(
            label: Text('${planner.totalCredits}'),
            child: const Icon(Icons.calendar_month_rounded),
          ),
          label: 'Lịch học',
        ),
        const NavigationDestination(
          icon: Icon(Icons.alt_route_rounded),
          label: 'Xếp lịch tự động',
        ),
        const NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          label: 'Lịch thi',
        ),
        const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Ước tính học phí',
        ),
        const NavigationDestination(
          icon: Icon(Icons.layers_rounded),
          label: 'Kế hoạch dự phòng',
        ),
        const NavigationDestination(
          icon: Icon(Icons.account_tree_rounded),
          label: 'Lộ trình',
        ),
      ],
    );
  }
}

