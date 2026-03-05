// lib/screens/organizations/workspace/reports_tab.dart
import 'package:flutter/material.dart';
import '../reports/my_reports_screen.dart';

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Simple navigation to the “My Reports” screen you already have
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.analytics_outlined),
        label: const Text('My Reports'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1967D2),
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MyReportsScreen(),
            ),
          );
        },
      ),
    );
  }
}
