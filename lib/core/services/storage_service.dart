import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static Future<void> init() async => _prefs = await SharedPreferences.getInstance();
  static SharedPreferences get prefs => _prefs!;

  static Future<void> saveToken(String t) async => prefs.setString('auth_token', t);
  static String? getToken() => prefs.getString('auth_token');
  static Future<void> clearToken() async => prefs.remove('auth_token');
  static Future<void> saveUser(Map<String, dynamic> u) async =>
      prefs.setString('current_user', jsonEncode(u));
  static Map<String, dynamic>? getUser() {
    final s = prefs.getString('current_user');
    return s != null ? Map<String, dynamic>.from(jsonDecode(s)) : null;
  }
  static bool get isLoggedIn => getToken() != null;
  static bool get isOfflineMode => getToken() == 'offline_mode_token';

  static Future<void> saveSettings(Map<String, dynamic> s) async =>
      prefs.setString('app_settings', jsonEncode(s));
  static Map<String, dynamic> getSettings() {
    final s = prefs.getString('app_settings');
    if (s != null) return Map<String, dynamic>.from(jsonDecode(s));
    return {
      'backendUrl': 'http://localhost:8000',
      'groqApiKey': '', 'cfApiToken': '', 'cfAccountId': '',
      'emailApiKey': '', 'emailProvider': 'resend',
      'senderEmail': '', 'senderName': '', 'companyName': '',
      'companyCity': 'India', 'defaultProduct': 'Premium Indian Beedi & Tobacco',
      'mondayAutomation': true, 'fridayDiscovery': true,
    };
  }
  static String getBackendUrl()  => getSettings()['backendUrl']  ?? 'http://localhost:8000';
  static String getGroqKey()     => getSettings()['groqApiKey']  ?? '';
  static String getCfToken()     => getSettings()['cfApiToken']  ?? '';
  static String getCfAccountId() => getSettings()['cfAccountId'] ?? '';
  static String getEmailApiKey() => getSettings()['emailApiKey'] ?? '';
  static String getSenderEmail() => getSettings()['senderEmail'] ?? '';
  static String getSenderName()  => getSettings()['senderName']  ?? '';
  static String getCompanyName() => getSettings()['companyName'] ?? '';

  static Future<void> cacheLeads(List<dynamic> l) async =>
      prefs.setString('cached_leads', jsonEncode(l));
  static List<dynamic>? getCachedLeads() {
    final s = prefs.getString('cached_leads');
    return s != null ? jsonDecode(s) as List : null;
  }
  static Future<void> clearAll() async => prefs.clear();
}
