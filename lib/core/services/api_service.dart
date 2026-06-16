import 'dart:convert';

import 'package:http/http.dart' as http;

import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiService {
  static String get _base => StorageService.getBackendUrl();
  static const int _timeout = 120000;

  static Map<String, String> get _headers {
    final token = StorageService.getToken();
    final isReal = token != null && token != 'offline_mode_token';
    return {
      'Content-Type': 'application/json',
      if (isReal) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String path, {Map<String, String>? params}) async {
    try {
      var uri = Uri.parse('$_base$path');
      if (params != null && params.isNotEmpty) uri = uri.replace(queryParameters: params);
      final res = await http.get(uri, headers: _headers).timeout(const Duration(milliseconds: _timeout));
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  static Future<dynamic> post(String path, {dynamic body}) async {
    try {
      final res =
          await http.post(Uri.parse('$_base$path'), headers: _headers, body: jsonEncode(body ?? {})).timeout(const Duration(milliseconds: _timeout));
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  static Future<dynamic> put(String path, {dynamic body}) async {
    try {
      final res =
          await http.put(Uri.parse('$_base$path'), headers: _headers, body: jsonEncode(body ?? {})).timeout(const Duration(milliseconds: _timeout));
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  static Future<dynamic> patch(String path, {dynamic body}) async {
    try {
      final res =
          await http.patch(Uri.parse('$_base$path'), headers: _headers, body: jsonEncode(body ?? {})).timeout(const Duration(milliseconds: _timeout));
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  static Future<dynamic> delete(String path) async {
    try {
      final res = await http.delete(Uri.parse('$_base$path'), headers: _headers).timeout(const Duration(milliseconds: _timeout));
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  static dynamic _handle(http.Response res) {
    if (res.statusCode == 204) return {};
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : <String, dynamic>{};
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    if (res.statusCode == 401) {
      StorageService.clearToken();
      throw ApiException('Unauthorized', statusCode: 401);
    }
    final msg = body is Map ? (body['detail'] ?? body['message'] ?? 'Server error').toString() : 'Server error';
    throw ApiException(msg, statusCode: res.statusCode);
  }

  // Leads
  static Future<List<dynamic>> getLeads({String? status, String? search}) =>
      get('/leads', params: {if (status != null) 'status': status, if (search != null) 'search': search})
          .then((d) => d is List ? d : (d['leads'] ?? <dynamic>[]));
  static Future<dynamic> createLead(Map<String, dynamic> d) => post('/leads', body: d);
  static Future<dynamic> updateLead(String id, Map<String, dynamic> d) => put('/leads/$id', body: d);
  static Future<dynamic> updateLeadStatus(String id, String status) => patch('/leads/$id/status', body: {'status': status});
  static Future<void> deleteLead(String id) => delete('/leads/$id');
  static Future<dynamic> addNote(String id, String note) =>
      post('/leads/$id/notes', body: {'note': note, 'timestamp': DateTime.now().toIso8601String()});

  // Email
  static Future<dynamic> sendEmail(Map<String, dynamic> p) =>
      post('/email/send', body: {...p, 'sender_email': StorageService.getSenderEmail(), 'sender_name': StorageService.getSenderName()});
  static Future<List<dynamic>> getEmailHistory(String id) => get('/email/history/$id').then((d) => d is List ? d : <dynamic>[]);

  // AI
  static Future<dynamic> generateEmail(Map<String, dynamic> p) => post('/ai/generate-email', body: {
        ...p,
        'groq_key': StorageService.getGroqKey(),
        'sender_name': StorageService.getSenderName(),
        'sender_company': StorageService.getCompanyName()
      });
  static Future<dynamic> generateFollowup(Map<String, dynamic> p) =>
      post('/ai/generate-followup', body: {...p, 'groq_key': StorageService.getGroqKey()});

  // Discovery
  static Future<dynamic> discoverImporters() => post('/discovery/search', body: {
        'groqKey': StorageService.getGroqKey(),
        'cfToken': StorageService.getCfToken(),
        'cfAccountId': StorageService.getCfAccountId(),
        'count': 10,
        'runAnalysis': true
      });
  static Future<List<dynamic>> getDiscoverySuggestions({String? verdict}) =>
      get('/discovery/suggestions', params: verdict != null && verdict != 'All' ? {'verdict': verdict} : null)
          .then((d) => d is List ? d : <dynamic>[]);
  static Future<dynamic> approveDiscovery(String id) => post('/discovery/approve/$id');
  static Future<dynamic> revokeDiscovery(String id) => post('/discovery/revoke/$id');
  static Future<dynamic> approveAllProceed() => post('/discovery/approve-all-proceed');
  static Future<dynamic> revalidateDiscovery(String id) => post('/discovery/validate/$id',
      body: {'groqKey': StorageService.getGroqKey(), 'cfToken': StorageService.getCfToken(), 'cfAccountId': StorageService.getCfAccountId()});
  static Future<dynamic> deleteRevokedById(String id) => delete('/revoke/$id');
  static Future<dynamic> deleteAllRevoked() => delete('/discovery/revoke');
  // Analytics & Campaigns
  static Future<dynamic> getAnalytics() => get('/analytics/overview');
  static Future<List<dynamic>> getCampaigns() => get('/campaigns').then((d) => d is List ? d : <dynamic>[]);
  static Future<dynamic> createCampaign(Map<String, dynamic> d) => post('/campaigns', body: d);

  // Auth
  static Future<dynamic> login(String email, String password) => post('/auth/login', body: {'email': email, 'password': password});
}
