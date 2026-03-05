import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/org_provider.dart';
import 'create_report_screen.dart';
import 'my_assignments_screen.dart';
import 'created_reports_screen.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1967D2).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF1967D2), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D253F))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgProvider = context.watch<OrganizationProvider>();
    final canAsk = orgProvider.hasPermission('report.ask');
    final canSend = orgProvider.hasPermission('report.send');
    final orgId = orgProvider.currentOrg?.id;

    if (orgId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Reports Dashboard', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reports Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D253F))),
            const SizedBox(height: 8),
            const Text('Select an option below to manage or view reports.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 32),
            
            if (canAsk)
              _buildCard(
                context: context,
                title: 'Create Report',
                subtitle: 'Author a new form and assign it to users or roles.',
                icon: Icons.add_chart_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CreateReportScreen(orgId: orgId)));
                },
              ),

            if (canSend)
              _buildCard(
                context: context,
                title: 'My Pending Reports',
                subtitle: 'View and fill out reports assigned to you.',
                icon: Icons.pending_actions_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MyAssignmentsScreen(orgId: orgId)));
                },
              ),

            if (canAsk)
              _buildCard(
                context: context,
                title: 'View Submissions',
                subtitle: 'Review answers for reports you have authored.',
                icon: Icons.reviews_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CreatedReportsScreen(orgId: orgId)));
                },
              ),

            if (!canAsk && !canSend)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('You do not have permission to view or create reports.', style: TextStyle(color: Colors.grey)),
                ),
              )
          ],
        ),
      ),
    );
  }
}
