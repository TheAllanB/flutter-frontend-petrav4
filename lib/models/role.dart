import '../utils/type_utils.dart';

class Role {
  final int id;
  final int? organizationId;
  final int? nodeId; // Nullable for global roles
  final String name;
  final String? description;
  final bool isOwner;
  final int permissionsCount;
  final List<dynamic> permissions;

  Role({
    required this.id,
    this.organizationId,
    this.nodeId,
    required this.name,
    this.description,
    this.isOwner = false,
    this.permissionsCount = 0,
    List<dynamic>? permissions,
  }) : permissions = permissions ?? [];

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: TypeUtils.parseIntRequired(json['id']),
      organizationId: TypeUtils.parseInt(json['organization_id']),
      nodeId: TypeUtils.parseInt(json['node_id']),
      name: json['name'],
      description: json['description'],
      isOwner: json['is_owner'] == true,
      permissionsCount: TypeUtils.parseIntRequired(json['permissions_count']),
      permissions: json['permissions'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'node_id': nodeId,
      'name': name,
      'description': description,
      'is_owner': isOwner,
      'permissions_count': permissionsCount,
      'permissions': permissions,
    };
  }
}
