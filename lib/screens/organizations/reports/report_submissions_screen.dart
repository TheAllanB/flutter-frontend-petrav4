import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/report.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/org_provider.dart';
import '../../../services/report_service.dart';

class ReportSubmissionsScreen extends StatefulWidget {
  final int orgId;
  final int reportId;

  const ReportSubmissionsScreen({super.key, required this.orgId, required this.reportId});

  @override
  State<ReportSubmissionsScreen> createState() => _ReportSubmissionsScreenState();
}

class _ReportSubmissionsScreenState extends State<ReportSubmissionsScreen> {
  bool _isLoading = true;
  Report? _report;
  List<ReportSubmission> _submissions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      final currentRoleId = context.read<OrganizationProvider>().role?.id;
      final data = await ReportService(token!).getReportSubmissions(widget.orgId, widget.reportId, roleId: currentRoleId);
      
      setState(() {
        _report = Report.fromJson(data['report']);
        _submissions = (data['submissions'] as List).map((s) => ReportSubmission.fromJson(s)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildSubmissionCard(ReportSubmission submission) {
    final userName = submission.user?.name ?? 'Unknown User';
    final userEmail = submission.user?.email ?? '';
    final date = submission.submittedAt != null 
        ? DateFormat('MMM d, yyyy h:mm a').format(submission.submittedAt!.toLocal())
        : 'Unknown Time';

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1967D2),
                  foregroundColor: Colors.white,
                  child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(userEmail, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
            const Divider(height: 32),
            if (submission.answers == null || submission.answers!.isEmpty)
              const Text('No answers provided.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
            else
              ...submission.answers!.map((answer) {
                final questionTitle = answer.question?.title ?? 'Unknown Question';
                
                // Determine the displayed answer text based on backend schema
                String answerText = 'Unknown';
                if (answer.answerData.containsKey('text')) {
                  answerText = answer.answerData['text'].toString();
                } else if (answer.answerData.isNotEmpty) {
                  // Fallback to first scalar value if arbitrary json
                  answerText = answer.answerData.values.first.toString();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(questionTitle, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D253F), fontSize: 14)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!)
                        ),
                        child: Text(answerText, style: const TextStyle(fontSize: 15)),
                      )
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Text(_report?.title ?? 'Report Submissions', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load submissions: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchSubmissions, child: const Text('Retry'))
                    ],
                  ),
                )
              : _submissions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('No submissions received yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchSubmissions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _submissions.length,
                        itemBuilder: (context, index) {
                          return _buildSubmissionCard(_submissions[index]);
                        },
                      ),
                    ),
    );
  }
}
