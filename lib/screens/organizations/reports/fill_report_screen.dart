import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/report.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/org_provider.dart';
import '../../../services/report_service.dart';

class FillReportScreen extends StatefulWidget {
  final int orgId;
  final Report report;

  const FillReportScreen({super.key, required this.orgId, required this.report});

  @override
  State<FillReportScreen> createState() => _FillReportScreenState();
}

class _FillReportScreenState extends State<FillReportScreen> {
  // Map of questionId to answer value (String for Short Answer, int for Linear Scale)
  final Map<int, dynamic> _answers = {};
  bool _isSubmitting = false;

  void _submit() async {
    // Basic validation
    final questions = widget.report.questions ?? [];
    for (var q in questions) {
      if (q.isRequired && (!_answers.containsKey(q.id) || _answers[q.id] == null || _answers[q.id].toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please answer all required questions (${q.title}).')));
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final token = context.read<AuthProvider>().token;
      final currentRoleId = context.read<OrganizationProvider>().role?.id;
      
      final answersList = _answers.entries.map((e) => {
        'question_id': e.key,
        'value': e.value,
      }).toList();

      await ReportService(token!).submitReport(widget.orgId, widget.report.id, answersList, roleId: currentRoleId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildQuestionForm(ReportQuestion q, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${index + 1}. ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  q.title, 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF0D253F))
                ),
              ),
              if (q.isRequired)
                const Text('*', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          
          if (q.type == 'Short Answer')
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'Your answer',
                border: UnderlineInputBorder(),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1967D2), width: 2)),
              ),
              onChanged: (val) {
                _answers[q.id] = val;
              },
            )
          else if (q.type == 'Linear Scale')
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (i) {
                    int val = i + 1;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _answers[q.id] = val;
                        });
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _answers[q.id] == val ? const Color(0xFF1967D2).withOpacity(0.1) : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _answers[q.id] == val ? const Color(0xFF1967D2) : Colors.grey[300]!,
                            width: 2
                          )
                        ),
                        child: Text('$val', style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: _answers[q.id] == val ? const Color(0xFF1967D2) : Colors.grey[600],
                        )),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 (Lowest)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('5 (Highest)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                )
              ],
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.report.questions ?? [];
    
    // Sort just in case backend didn't sort by order_index
    final sortedQs = List<ReportQuestion>.from(questions)..sort((a,b) => a.orderIndex.compareTo(b.orderIndex));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Fill Report', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1967D2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: const Border(top: BorderSide(color: Color(0xFF1967D2), width: 8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.report.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D253F))),
                  if (widget.report.description != null && widget.report.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(widget.report.description!, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5)),
                  ],
                  if (widget.report.deadline != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(16)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 16, color: Colors.red[700]),
                          const SizedBox(width: 6),
                          Text('Due: ${widget.report.deadline!.toLocal().toString().split(".")[0]}', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    )
                  ]
                ],
              ),
            ),
            
            // Questions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: sortedQs.asMap().entries.map((entry) => _buildQuestionForm(entry.value, entry.key)).toList(),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
