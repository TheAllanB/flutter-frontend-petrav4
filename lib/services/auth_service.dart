import 'dart:convert';
import 'api_client.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiClient.post(
      '/login',
      body: {'email': email, 'password': password},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'token': data['token'],
        'user': User.fromJson(data['user']),
      };
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _apiClient.post(
      '/register',
      body: {'name': name, 'email': email, 'password': password},
    );
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'token': data['token'],
        'user': User.fromJson(data['user']),
      };
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  // ApiClient will automatically attach the token from secure storage.
  Future<Map<String, dynamic>> getMe() async {
    final response = await _apiClient.get('/me');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Usually /me returns the user object directly, or wrapped in 'user'.
      // We'll accommodate both based on original code usage data['user'] in provider.
      final userData = data.containsKey('user') ? data['user'] : data;
      return {
        'user': User.fromJson(userData),
      };
    } else {
      throw Exception('Failed to fetch user');
    }
  }
}
