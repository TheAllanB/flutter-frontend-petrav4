import 'dart:convert';
import 'api_client.dart';

class ReportService {
  final ApiClient _apiClient = ApiClient();

  // keeping constructor signature unchanged for backwards compat
  ReportService([String? token]);

  Future<Map<String, dynamic>> createReport(int orgId, Map<String, dynamic> data, {int? roleId}) async {
    if (roleId != null) {
      data['active_role_id'] = roleId;
    }
    final response = await _apiClient.post(
      '/organizations/$orgId/reports',
      body: data,
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create report: ${response.body}');
  }

  Future<List<dynamic>> getPendingReports(int orgId, {int? roleId}) async {
    String url = '/organizations/$orgId/reports/pending';
    if (roleId != null) url += '?role_id=$roleId';
    final response = await _apiClient.get(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return (decoded['reports'] as List?) ?? [];
    }
    throw Exception('Failed to fetch pending reports: ${response.body}');
  }

  Future<Map<String, dynamic>> getReportTargets(int orgId, {int? roleId}) async {
    String url = '/organizations/$orgId/report-targets';
    if (roleId != null) url += '?role_id=$roleId';
    final response = await _apiClient.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch report targets: ${response.body}');
  }

  Future<Map<String, dynamic>> submitReport(int orgId, int reportId, List<Map<String, dynamic>> answers, {int? roleId}) async {
    String url = '/organizations/$orgId/reports/$reportId/submit';
    if (roleId != null) url += '?role_id=$roleId';
    final response = await _apiClient.post(
      url,
      body: {'answers': answers},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to submit report: ${response.body}');
  }

  Future<List<dynamic>> getCreatedReports(int orgId, {int? roleId}) async {
    String url = '/organizations/$orgId/reports/created';
    if (roleId != null) url += '?role_id=$roleId';
    final response = await _apiClient.get(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return (decoded['reports'] as List?) ?? [];
    }
    throw Exception('Failed to fetch created reports: ${response.body}');
  }

  Future<Map<String, dynamic>> getReportSubmissions(int orgId, int reportId, {int? roleId}) async {
    String url = '/organizations/$orgId/reports/$reportId/submissions';
    if (roleId != null) url += '?role_id=$roleId';
    final response = await _apiClient.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch report submissions: ${response.body}');
  }
}
