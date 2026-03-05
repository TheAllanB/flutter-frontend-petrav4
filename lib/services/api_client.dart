import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class ApiClient {
  final _storage = const FlutterSecureStorage();
  
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return await http.get(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: headers);
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    return await http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'), 
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    return await http.put(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'), 
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    return await http.patch(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'), 
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return await http.delete(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: headers);
  }
}
