import '../utils/type_utils.dart';

class Node {
  final int id;
  final int organizationId;
  final int? parentId;
  final String name;
  final String? description;
  final List<Node> children;

  Node({
    required this.id,
    required this.organizationId,
    this.parentId,
    required this.name,
    this.description,
    List<Node>? children,
  }) : children = children ?? [];

  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      id: TypeUtils.parseIntRequired(json['id']),
      organizationId: TypeUtils.parseIntRequired(json['organization_id']),
      parentId: TypeUtils.parseInt(json['parent_id']),
      name: json['name'],
      description: json['description'],
      children: json['children'] != null
          ? (json['children'] as List).map((child) => Node.fromJson(child)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'parent_id': parentId,
      'name': name,
      'description': description,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }
}
