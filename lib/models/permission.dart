import '../utils/type_utils.dart';

class Permission {
  final int id;
  final String name;
  final String key;
  final String module;
  final String? description;

  Permission({
    required this.id,
    required this.name,
    required this.key,
    required this.module,
    this.description,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: TypeUtils.parseIntRequired(json['id']),
      name: json['name'],
      key: json['key'],
      module: json['module'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'key': key,
      'module': module,
      'description': description,
    };
  }
}
