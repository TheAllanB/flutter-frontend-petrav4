import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/org_service.dart';

class CreateOrgStep3 extends StatefulWidget {
  final Map<String, dynamic> orgData;

  const CreateOrgStep3({super.key, required this.orgData});

  @override
  State<CreateOrgStep3> createState() => _CreateOrgStep3State();
}

class _CreateOrgStep3State extends State<CreateOrgStep3> {
  bool _isCreating = false;

  Future<void> _submit() async {
    setState(() => _isCreating = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        await OrgService(token).createOrg(widget.orgData);
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Organization created successfully!')));
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if(mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Org - Step 3 Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Organization Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(title: const Text('Name'), subtitle: Text(widget.orgData['name'])),
            ListTile(title: const Text('UID'), subtitle: Text(widget.orgData['uid'])),
            ListTile(title: const Text('Website'), subtitle: Text(widget.orgData['website'] ?? 'N/A')),
            ListTile(title: const Text('Location'), subtitle: Text(widget.orgData['location'] ?? 'N/A')),
            
            const Divider(),
            const Text('Roles Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const ListTile(title: Text('Owner'), subtitle: Text('Full Permissions (Auto-assigned)')),
            ...List.generate(
              (widget.orgData['roles'] as List).length,
              (index) {
                final role = widget.orgData['roles'][index];
                return ListTile(
                  title: Text(role['name']),
                  subtitle: Text('Permissions: ${role['permissions'].join(', ')}'),
                );
              }
            ),
            
            const SizedBox(height: 32),
            Center(
              child: _isCreating
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
                      child: const Text('Confirm & Create', style: TextStyle(fontSize: 16)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
