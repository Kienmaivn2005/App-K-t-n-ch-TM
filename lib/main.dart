import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'providers/planner_provider.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/uniplan_mobile_app_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ProviderScope cho Riverpod Clean Architecture + MultiProvider cho Legacy Provider
  runApp(
    const ProviderScope(
      child: UniPlanApp(),
    ),
  );
}

/// Ứng dụng UniPlan - Quản lý Kế hoạch Đăng ký Tín chỉ & Thời khóa biểu Thông minh
/// 100% Giao diện Ứng dụng Di động Hiện Đại (App Mobile)
class UniPlanApp extends StatelessWidget {
  const UniPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return legacy_provider.MultiProvider(
      providers: [
        legacy_provider.ChangeNotifierProvider(create: (_) => PlannerProvider()),
      ],
      child: MaterialApp(
        title: 'Đăng Ký Tín Chỉ Thông Minh',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const UniPlanMobileAppScreen(),
      ),
    );
  }
}

