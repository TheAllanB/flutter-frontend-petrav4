class Organization {
  final int id;
  final String name;
  final String? description;
  final String? slug;
  final String? uid;

  Organization({
    required this.id,
    required this.name,
    this.description,
    this.slug,
    this.uid,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      slug: json['slug'],
      uid: json['uid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'slug': slug,
      'uid': uid,
    };
  }
}
