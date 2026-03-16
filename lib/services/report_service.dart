import 'dart:convert';
import 'api_client.dart';

class ReportService {
  final ApiClient _apiClient = ApiClient();

  // keeping constructor signature unchanged for backwards compat
  ReportService([String? token]);

  Future<Map<String, dynamic>> createReport(int orgId, Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      '/organizations/$orgId/reports',
      body: data,
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create report: ${response.body}');
  }

  Future<List<dynamic>> getPendingReports(int orgId) async {
    final response = await _apiClient.get('/organizations/$orgId/reports/pending');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return (decoded['reports'] as List?) ?? [];
    }
    throw Exception('Failed to fetch pending reports: ${response.body}');
  }

  Future<Map<String, dynamic>> submitReport(int orgId, int reportId, List<Map<String, dynamic>> answers) async {
    final response = await _apiClient.post(
      '/organizations/$orgId/reports/$reportId/submit',
      body: {'answers': answers},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to submit report: ${response.body}');
  }

  Future<List<dynamic>> getCreatedReports(int orgId) async {
    final response = await _apiClient.get('/organizations/$orgId/reports/created');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return (decoded['reports'] as List?) ?? [];
    }
    throw Exception('Failed to fetch created reports: ${response.body}');
  }

  Future<Map<String, dynamic>> getReportSubmissions(int orgId, int reportId) async {
    final response = await _apiClient.get('/organizations/$orgId/reports/$reportId/submissions');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch report submissions: ${response.body}');
  }
}
