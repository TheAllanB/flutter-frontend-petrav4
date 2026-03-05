import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/org_provider.dart';
import '../../../../services/org_service.dart';
import '../../auth/logout_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final org = context.read<OrganizationProvider>().currentOrg;
    if (org != null) {
      _nameController.text = org.name;
      _descController.text = org.description ?? '';
    }
  }

  Future<void> _saveSettings() async {
    final orgProvider = context.read<OrganizationProvider>();
    final org = orgProvider.currentOrg;
    if (org == null) return;

    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final updatedOrg = await OrgService(token).updateOrganization(org.id, {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
      });
      orgProvider.updateOrg(updatedOrg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgProvider = context.watch<OrganizationProvider>();
    final org = orgProvider.currentOrg;
    final canEdit = orgProvider.hasPermission('org.settings.edit');

    if (org == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Organization Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D253F))),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          enabled: canEdit,
          decoration: const InputDecoration(
            labelText: 'Organization Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descController,
          enabled: canEdit,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: TextEditingController(text: org.uid ?? ''),
          enabled: false,
          decoration: const InputDecoration(
            labelText: 'Unique ID (Read-only)',
            border: OutlineInputBorder(),
            filled: true,
          ),
        ),
        const SizedBox(height: 24),
        if (canEdit)
          ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1967D2),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        const Divider(height: 48),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LogoutScreen()),
            );
          },
        ),
      ],
    );
  }
}
