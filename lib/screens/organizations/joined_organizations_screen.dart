import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/org_service.dart';
import '../../models/organization.dart';
import 'create/create_org_step_1.dart';
import 'workspace/organization_screen.dart';
import 'join_organization_screen.dart';
import '../../widgets/expandable_fab.dart';

class JoinedOrganizationsScreen extends StatefulWidget {
  const JoinedOrganizationsScreen({super.key});

  @override
  State<JoinedOrganizationsScreen> createState() => _JoinedOrganizationsScreenState();
}

class _JoinedOrganizationsScreenState extends State<JoinedOrganizationsScreen> {
  List<Organization> _orgs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrgs();
  }

  Future<void> _loadOrgs() async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        final orgService = OrgService(token);
        final orgs = await orgService.getJoinedOrgs();
        if(mounted) setState(() => _orgs = orgs);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizations', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search organizations...',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _orgs.isEmpty
                  ? const Center(child: Text('No organizations found.'))
                  : ListView.separated(
                      itemCount: _orgs.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      itemBuilder: (context, index) {
                        final org = _orgs[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1967D2),
                            foregroundColor: Colors.white,
                            child: Text(org.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          title: Text(org.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D253F))),
                          subtitle: Text(org.description ?? 'No description provided', style: const TextStyle(color: Colors.grey)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrganizationScreen(orgId: org.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
          Positioned(
            bottom: 16,
            right: 16,
            child: ExpandableFab(
              children: [
                ActionButton(
                  label: 'Join',
                  icon: const Icon(Icons.person_add),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinOrganizationScreen())),
                ),
                ActionButton(
                  label: 'Create',
                  icon: const Icon(Icons.domain_add),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateOrgStep1())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
