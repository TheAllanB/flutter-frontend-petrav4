import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/report.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/report_service.dart';
import 'report_submissions_screen.dart';

class CreatedReportsScreen extends StatefulWidget {
  final int orgId;

  const CreatedReportsScreen({super.key, required this.orgId});

  @override
  State<CreatedReportsScreen> createState() => _CreatedReportsScreenState();
}

class _CreatedReportsScreenState extends State<CreatedReportsScreen> {
  bool _isLoading = true;
  List<Report> _createdReports = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      final rawReports = await ReportService(token!).getCreatedReports(widget.orgId);
      
      setState(() {
        _createdReports = rawReports.map((r) => Report.fromJson(r)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('My Created Reports', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
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
                      Text('Failed to load reports: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchReports, child: const Text('Retry'))
                    ],
                  ),
                )
              : _createdReports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_shared_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('You have not created any reports yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _createdReports.length,
                        itemBuilder: (context, index) {
                          final report = _createdReports[index];
                          final formattedDate = report.createdAt != null 
                              ? DateFormat('MMM d, yyyy').format(report.createdAt!) 
                              : 'Unknown Date';
                          
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1967D2).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.analytics_outlined, color: Color(0xFF1967D2)),
                              ),
                              title: Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('Created: $formattedDate', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ReportSubmissionsScreen(orgId: widget.orgId, reportId: report.id)),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
