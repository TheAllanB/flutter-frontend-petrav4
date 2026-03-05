import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ReportService {
  final Map<String, String> _headers;

  ReportService(String token)
      : _headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

  Future<Map<String, dynamic>> createReport(int orgId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/organizations/$orgId/reports'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create report: ${response.body}');
  }

  Future<List<dynamic>> getPendingReports(int orgId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/organizations/$orgId/reports/pending'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return (decoded['reports'] as List?) ?? [];
    }
    throw Exception('Failed to fetch pending reports: ${response.body}');
  }

  Future<Map<String, dynamic>> submitReport(int orgId, int reportId, List<Map<String, dynamic>> answers) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/organizations/$orgId/reports/$reportId/submit'),
      headers: _headers,
      body: jsonEncode({'answers': answers}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to submit report: ${response.body}');
  }

  Future<List<dynamic>> getCreatedReports(int orgId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/organizations/$orgId/reports/created'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return (decoded['reports'] as List?) ?? [];
    }
    throw Exception('Failed to fetch created reports: ${response.body}');
  }

  Future<Map<String, dynamic>> getReportSubmissions(int orgId, int reportId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/organizations/$orgId/reports/$reportId/submissions'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch report submissions: ${response.body}');
  }
}
