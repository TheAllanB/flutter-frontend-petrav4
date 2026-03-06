import 'package:flutter/material.dart';
import '../models/organization.dart';
import '../models/role.dart';
import '../models/node.dart';
import '../utils/type_utils.dart';

class OrganizationProvider extends ChangeNotifier {
  Organization? _currentOrg;
  Role? _role;
  List<String> _permissions = [];
  List<Role> _allRoles = [];

  // Phase 3.5 properties
  List<Node> _nodeTree = [];
  List<dynamic> _members = [];

  Organization? get currentOrg => _currentOrg;
  Role? get role => _role;
  List<String> get permissions => _permissions;
  List<Role> get allRoles => _allRoles;
  List<Node> get nodeTree => _nodeTree;
  List<dynamic> get members => _members;

  void setContext(Map<String, dynamic> contextData) {
    _currentOrg = Organization.fromJson(contextData['organization']);
    _role = contextData['role'] != null ? Role.fromJson(contextData['role']) : null;
    _permissions = List<String>.from(contextData['permissions'] ?? []);
    _allRoles = (contextData['all_roles'] as List? ?? []).map((r) => Role.fromJson(r)).toList();
    notifyListeners();
  }

  void setNodes(List<Node> flatNodes) {
    _nodeTree = _buildTree(flatNodes, null);
    notifyListeners();
  }

  List<Node> _buildTree(List<Node> nodes, int? parentId) {
    return nodes
        .where((n) => n.parentId == parentId)
        .map((n) {
          return Node(
            id: n.id,
            organizationId: n.organizationId,
            parentId: n.parentId,
            name: n.name,
            description: n.description,
            children: _buildTree(nodes, n.id), // Recursive structure
          );
        })
        .toList();
  }

  void setMembers(List<dynamic> membersList) {
    _members = membersList;
    notifyListeners();
  }

  bool hasPermission(String key) {
    return _permissions.contains(key);
  }

  void updateOrg(Organization newOrgData) {
    _currentOrg = newOrgData;
    notifyListeners();
  }

  void clear() {
    _currentOrg = null;
    _role = null;
    _permissions = [];
    _allRoles = [];
    _nodeTree = [];
    _members = [];
    notifyListeners();
  }
}
