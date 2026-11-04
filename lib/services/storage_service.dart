import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plan.dart';
import '../models/student_profile.dart';

class StorageService {
  static const String _keyPlans = 'uniplan_saved_plans';
  static const String _keyActivePlanId = 'uniplan_active_plan_id';
  static const String _keyProfile = 'uniplan_student_profile';
  static const String _keyCustomExams = 'uniplan_custom_exams';

  // Bộ nhớ đệm fallback trong trường hợp SharedPreferences không khả dụng
  static final Map<String, String> _memoryStore = {};

  static Future<void> saveCustomExamsJson(String jsonString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCustomExams, jsonString);
      _memoryStore[_keyCustomExams] = jsonString;
    } catch (_) {
      _memoryStore[_keyCustomExams] = jsonString;
    }
  }

  static Future<String?> loadCustomExamsJson() async {
    try {
      String? str;
      try {
        final prefs = await SharedPreferences.getInstance();
        str = prefs.getString(_keyCustomExams);
      } catch (_) {
        str = _memoryStore[_keyCustomExams];
      }
      if (str == null || str.isEmpty) {
        str = _memoryStore[_keyCustomExams];
      }
      return str;
    } catch (_) {
      return _memoryStore[_keyCustomExams];
    }
  }

  static Future<void> savePlans(List<RegistrationPlan> plans) async {
    try {
      final jsonList = plans.map((p) => p.toJson()).toList();
      final str = jsonEncode(jsonList);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPlans, str);
      _memoryStore[_keyPlans] = str;
    } catch (_) {
      final jsonList = plans.map((p) => p.toJson()).toList();
      _memoryStore[_keyPlans] = jsonEncode(jsonList);
    }
  }

  static Future<List<RegistrationPlan>?> loadPlans() async {
    try {
      String? str;
      try {
        final prefs = await SharedPreferences.getInstance();
        str = prefs.getString(_keyPlans);
      } catch (_) {
        str = _memoryStore[_keyPlans];
      }

      if (str == null || str.isEmpty) {
        str = _memoryStore[_keyPlans];
      }

      if (str != null && str.isNotEmpty) {
        final List<dynamic> list = jsonDecode(str);
        return list.map((e) => RegistrationPlan.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<void> saveActivePlanId(String planId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyActivePlanId, planId);
    } catch (_) {}
    _memoryStore[_keyActivePlanId] = planId;
  }

  static Future<String?> loadActivePlanId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_keyActivePlanId);
      if (id != null) return id;
    } catch (_) {}
    return _memoryStore[_keyActivePlanId];
  }

  static Future<void> saveProfile(StudentProfile profile) async {
    try {
      final str = jsonEncode(profile.toJson());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyProfile, str);
      _memoryStore[_keyProfile] = str;
    } catch (_) {
      _memoryStore[_keyProfile] = jsonEncode(profile.toJson());
    }
  }

  static Future<StudentProfile?> loadProfile() async {
    try {
      String? str;
      try {
        final prefs = await SharedPreferences.getInstance();
        str = prefs.getString(_keyProfile);
      } catch (_) {
        str = _memoryStore[_keyProfile];
      }

      if (str == null || str.isEmpty) {
        str = _memoryStore[_keyProfile];
      }

      if (str != null && str.isNotEmpty) {
        final map = jsonDecode(str) as Map<String, dynamic>;
        return StudentProfile.fromJson(map);
      }
    } catch (_) {}
    return null;
  }
}

