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
      id: json['id'],
      organizationId: json['organization_id'],
      nodeId: json['node_id'],
      name: json['name'],
      description: json['description'],
      isOwner: json['is_owner'] == true,
      permissionsCount: json['permissions_count'] ?? 0,
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
