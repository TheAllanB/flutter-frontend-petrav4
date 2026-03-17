import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/report.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/org_provider.dart';
import '../../../services/report_service.dart';
import 'fill_report_screen.dart';

class MyAssignmentsScreen extends StatefulWidget {
  final int orgId;

  const MyAssignmentsScreen({super.key, required this.orgId});

  @override
  State<MyAssignmentsScreen> createState() => _MyAssignmentsScreenState();
}

class _MyAssignmentsScreenState extends State<MyAssignmentsScreen> {
  bool _isLoading = true;
  List<Report> _pendingReports = [];
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
      final currentRoleId = context.read<OrganizationProvider>().role?.id;
      final rawReports = await ReportService(token!).getPendingReports(widget.orgId, roleId: currentRoleId);
      
      setState(() {
        _pendingReports = rawReports.map((r) => Report.fromJson(r)).toList();
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
        title: const Text('My Pending Reports', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
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
              : _pendingReports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
                          const SizedBox(height: 16),
                          const Text('You have no pending reports!', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingReports.length,
                        itemBuilder: (context, index) {
                          final report = _pendingReports[index];
                          final formattedDate = report.deadline != null 
                              ? DateFormat('MMM d, yyyy h:mm a').format(report.deadline!) 
                              : 'No deadline';
                          
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
                                child: const Icon(Icons.assignment_outlined, color: Color(0xFF1967D2)),
                              ),
                              title: Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('Due: $formattedDate', style: TextStyle(color: Colors.red[700], fontSize: 13)),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => FillReportScreen(orgId: widget.orgId, report: report)),
                                  ).then((_) => _fetchReports()); // Refresh when returning
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1967D2),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Fill out'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
