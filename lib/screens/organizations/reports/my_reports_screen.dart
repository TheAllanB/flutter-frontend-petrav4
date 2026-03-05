import 'package:flutter/material.dart';

class MyReportsScreen extends StatelessWidget {
  final int? orgId;

  const MyReportsScreen({super.key, this.orgId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
      ),
      body: const Center(
        child: Text('My Reports Screen Placeholder'),
      ),
    );
  }
}
