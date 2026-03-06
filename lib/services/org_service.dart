import 'dart:convert';
import 'api_client.dart';
import '../models/organization.dart';
import '../models/node.dart';
import '../models/role.dart';

class OrgService {
  final ApiClient _apiClient = ApiClient();
  
  OrgService([String? token]); // keep constructor signature to avoid breaking

  Future<List<Organization>> getJoinedOrgs() async {
    final response = await _apiClient.get('/me/organizations');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['organizations'];
      return data.map((json) => Organization.fromJson(json)).toList();
    }
    throw Exception('Failed to load joined orgs');
  }

  Future<List<Organization>> searchOrgs(String query) async {
    final response = await _apiClient.get('/organizations?search=$query');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((json) => Organization.fromJson(json)).toList();
    }
    throw Exception('Failed to search orgs');
  }

  Future<void> joinOrg(int orgId) async {
    final response = await _apiClient.post('/organizations/$orgId/join');
    if (response.statusCode != 200) {
      throw Exception('Failed to join org');
    }
  }

  Future<bool> checkUid(String uid) async {
    final response = await _apiClient.get('/organizations/check-uid/$uid');
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['available'];
    }
    return false;
  }

  Future<String> generateUid() async {
    final response = await _apiClient.get('/organizations/generate-uid');
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['uid'];
    }
    throw Exception('Failed to generate UID');
  }

  Future<Organization> createOrg(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/organizations', body: data);
    if (response.statusCode == 201) {
      return Organization.fromJson(jsonDecode(response.body)['organization']);
    }
    throw Exception('Failed to create org: ${response.statusCode} - ${response.body}');
  }

  Future<Map<String, dynamic>> getContext(int orgId, {int? activeRoleId}) async {
    final url = activeRoleId != null 
        ? '/organizations/$orgId/context?role_id=$activeRoleId'
        : '/organizations/$orgId/context';

    final response = await _apiClient.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load organization context: ${response.body}');
  }

  Future<List<dynamic>> getMembers(int orgId) async {
    final response = await _apiClient.get('/organizations/$orgId/members');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load members');
  }

  Future<Organization> updateOrg(int orgId, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/organizations/$orgId', body: data);
    if (response.statusCode == 200) {
      return Organization.fromJson(jsonDecode(response.body)['organization']);
    }
    throw Exception('Failed to update organization');
  }

  // ----------------------------------------------------
  // NODES LOGIC
  // ----------------------------------------------------

  Future<List<Node>> getNodes(int orgId, {dynamic parentId}) async {
    final url = parentId != null 
        ? '/organizations/$orgId/nodes?parent_id=$parentId'
        : '/organizations/$orgId/nodes';
        
    final response = await _apiClient.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['nodes'];
      return data.map((json) => Node.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load nodes: ${response.statusCode}');
    }
  }

  Future<Node> createNode(int orgId, String name, String type, {int? parentId}) async {
    final response = await _apiClient.post('/organizations/$orgId/nodes', body: {
        'name': name,
        'type': type,
        if (parentId != null) 'parent_id': parentId,
      });

    if (response.statusCode == 201) {
      return Node.fromJson(jsonDecode(response.body)['node']);
    } else {
      throw Exception('Failed to create node: ${response.body}');
    }
  }

  Future<Node> updateNode(int orgId, int nodeId, String name) async {
    final response = await _apiClient.put('/organizations/$orgId/nodes/$nodeId', body: {
        'name': name,
      });

    if (response.statusCode == 200) {
      return Node.fromJson(jsonDecode(response.body)['node']);
    } else {
      throw Exception('Failed to update node: ${response.body}');
    }
  }

  // ----------------------------------------------------
  // ROLES & PERMISSIONS LOGIC
  // ----------------------------------------------------

  Future<Map<String, dynamic>> getPermissions() async {
    final response = await _apiClient.get('/permissions');
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['groups'];
    }
    throw Exception('Failed to load permissions');
  }

  Future<List<Role>> getRoles(int orgId) async {
    final response = await _apiClient.get('/organizations/$orgId/roles');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['roles'];
      return data.map((json) => Role.fromJson(json)).toList();
    }
    throw Exception('Failed to load roles');
  }

  Future<void> createRole(int orgId, String name, List<String> permissions) async {
    final response = await _apiClient.post('/organizations/$orgId/roles', body: {
        'name': name,
        'permissions': permissions,
      });
    if (response.statusCode != 201) {
      throw Exception('Failed to create role: ${response.body}');
    }
  }

  Future<void> updateRole(int orgId, int roleId, String name, List<String> permissions) async {
    final response = await _apiClient.put('/organizations/$orgId/roles/$roleId', body: {
        'name': name,
        'permissions': permissions,
      });
    if (response.statusCode != 200) {
      throw Exception('Failed to update role: ${response.body}');
    }
  }

  Future<void> assignRoles(int orgId, int userId, List<Map<String, dynamic>> roles) async {
    final response = await _apiClient.put('/organizations/$orgId/members/$userId/roles', body: {
        'roles': roles,
      });
    if (response.statusCode != 200) {
      throw Exception('Failed to assign roles: ${response.body}');
    }
  }
  Future<Organization> updateOrganization(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/organizations/$id', body: data);
    if (response.statusCode == 200) {
      return Organization.fromJson(jsonDecode(response.body)['organization']);
    }
    throw Exception('Failed to update organization: ${response.body}');
  }
}
