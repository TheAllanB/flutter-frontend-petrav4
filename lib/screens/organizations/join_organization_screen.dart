import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/org_service.dart';
import '../../models/organization.dart';
import 'dart:async';

class JoinOrganizationScreen extends StatefulWidget {
  const JoinOrganizationScreen({super.key});

  @override
  State<JoinOrganizationScreen> createState() => _JoinOrganizationScreenState();
}

class _JoinOrganizationScreenState extends State<JoinOrganizationScreen> {
  final _searchController = TextEditingController();
  List<Organization> _orgs = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchOrgs('');
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _searchOrgs(query));
  }

  Future<void> _searchOrgs(String query) async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        final orgs = await OrgService(token).searchOrgs(query);
        if(mounted) setState(() => _orgs = orgs);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinOrg(int id) async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        await OrgService(token).joinOrg(id);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined successfully')));
        _searchOrgs(_searchController.text);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Organization'),
        backgroundColor: const Color(0xFF1967D2),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF4F7FC),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textCapitalization: TextCapitalization.characters,
              maxLength: 12, // Enforce 12 chars visually
              decoration: InputDecoration(
                labelText: 'Organization UID',
                hintText: 'Enter 12-character ID (e.g. ABC123XYZ789)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orgs.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.length == 12 
                            ? 'No organization found with this UID.' 
                            : 'Enter a valid 12-character Organization UID.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _orgs.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final org = _orgs[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE8F0FE),
                                child: Icon(Icons.business, color: Color(0xFF1967D2)),
                              ),
                              title: Text(org.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('UID: ${org.uid}'),
                              trailing: ElevatedButton(
                                onPressed: () => _joinOrg(org.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1967D2),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Join'),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
