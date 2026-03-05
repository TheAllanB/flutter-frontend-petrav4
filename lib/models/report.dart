class Report {
  final int id;
  final int organizationId;
  final int creatorId;
  final String title;
  final String? description;

  Report({
    required this.id,
    required this.organizationId,
    required this.creatorId,
    required this.title,
    this.description,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      organizationId: json['organization_id'],
      creatorId: json['creator_id'],
      title: json['title'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'creator_id': creatorId,
      'title': title,
      'description': description,
    };
  }
}
