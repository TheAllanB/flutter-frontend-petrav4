import 'user.dart';
import '../utils/type_utils.dart';

class Report {
  final int id;
  final int organizationId;
  final int creatorId;
  final String title;
  final String? description;
  final DateTime? deadline;
  final DateTime? createdAt;
  final List<ReportQuestion>? questions;

  Report({
    required this.id,
    required this.organizationId,
    required this.creatorId,
    required this.title,
    this.description,
    this.deadline,
    this.createdAt,
    this.questions,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: TypeUtils.parseIntRequired(json['id']),
      organizationId: TypeUtils.parseIntRequired(json['organization_id']),
      creatorId: TypeUtils.parseIntRequired(json['creator_id']),
      title: json['title'],
      description: json['description'],
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      questions: json['questions'] != null
          ? (json['questions'] as List).map((q) => ReportQuestion.fromJson(q)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
    };
  }
}

class ReportQuestion {
  final int id;
  final int reportId;
  final String type; // e.g., 'Linear Scale', 'Short Answer'
  final String title;
  final bool isRequired;
  final List<String>? options;
  final int orderIndex;

  ReportQuestion({
    required this.id,
    required this.reportId,
    required this.type,
    required this.title,
    this.isRequired = false,
    this.options,
    required this.orderIndex,
  });

  factory ReportQuestion.fromJson(Map<String, dynamic> json) {
    return ReportQuestion(
      id: TypeUtils.parseIntRequired(json['id']),
      reportId: TypeUtils.parseIntRequired(json['report_id']),
      type: json['type'],
      title: json['title'],
      isRequired: json['is_required'] ?? false,
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      orderIndex: TypeUtils.parseIntRequired(json['order_index']),
    );
  }
}

class ReportSubmission {
  final int id;
  final int reportId;
  final int userId;
  final DateTime? submittedAt;
  final User? user; // For the 'With user' relationship
  final List<ReportAnswer>? answers;

  ReportSubmission({
    required this.id,
    required this.reportId,
    required this.userId,
    this.submittedAt,
    this.user,
    this.answers,
  });

  factory ReportSubmission.fromJson(Map<String, dynamic> json) {
    return ReportSubmission(
      id: TypeUtils.parseIntRequired(json['id']),
      reportId: TypeUtils.parseIntRequired(json['report_id']),
      userId: TypeUtils.parseIntRequired(json['user_id']),
      submittedAt: json['submitted_at'] != null ? DateTime.tryParse(json['submitted_at']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      answers: json['answers'] != null 
          ? (json['answers'] as List).map((a) => ReportAnswer.fromJson(a)).toList() 
          : null,
    );
  }
}

class ReportAnswer {
  final int id;
  final int submissionId;
  final int questionId;
  final Map<String, dynamic> answerData;
  final ReportQuestion? question;

  ReportAnswer({
    required this.id,
    required this.submissionId,
    required this.questionId,
    required this.answerData,
    this.question,
  });

  factory ReportAnswer.fromJson(Map<String, dynamic> json) {
    return ReportAnswer(
      id: TypeUtils.parseIntRequired(json['id']),
      submissionId: TypeUtils.parseIntRequired(json['submission_id']),
      questionId: TypeUtils.parseIntRequired(json['question_id']),
      answerData: json['answer_data'] ?? {},
      question: json['question'] != null ? ReportQuestion.fromJson(json['question']) : null,
    );
  }
}
