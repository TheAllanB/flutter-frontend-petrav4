import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Name: ${user?.name ?? 'N/A'}', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text('Email: ${user?.email ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<AuthProvider>().logout(),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
