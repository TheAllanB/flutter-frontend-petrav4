import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/org_provider.dart';
import '../../../services/org_service.dart';
import 'groups_tab.dart';
import 'members_tab.dart';
import 'reports_tab.dart';
import 'roles_tab.dart';
import 'settings_tab.dart';

class OrganizationScreen extends StatefulWidget {
  final int orgId;

  const OrganizationScreen({super.key, required this.orgId});

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext({int? activeRoleId}) async {
    if (mounted && !_isLoading) setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      
      final orgService = OrgService(token);
      final contextData = await orgService.getContext(widget.orgId, activeRoleId: activeRoleId);
      
      if (mounted) {
        final provider = context.read<OrganizationProvider>();
        provider.setContext(contextData);
        
        // Phase 3.5: Pre-cache Nodes and Members
        final flatNodes = await orgService.getNodes(widget.orgId);
        provider.setNodes(flatNodes);

        try {
          final membersData = await orgService.getMembers(widget.orgId);
          provider.setMembers(membersData);
        } catch (e) {
          debugPrint('Failed to load members optionally during context: $e');
        }

        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        if (activeRoleId == null) {
          Navigator.pop(context); // Go back if we can't load initial context
        } else {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final orgProvider = context.watch<OrganizationProvider>();
    final org = orgProvider.currentOrg;

    if (org == null) {
      return const Scaffold(body: Center(child: Text('Failed to load.')));
    }

    final tabs = [
      const GroupsTab(),
      const MembersTab(),
      const ReportsTab(),
      const RolesTab(),
      const SettingsTab()
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                org.name[0].toUpperCase(), 
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(width: 12),
            Text(org.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: PopupMenuButton<int>(
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (roleId) {
                  if (roleId != orgProvider.role?.id) {
                    _loadContext(activeRoleId: roleId);
                  }
                },
                itemBuilder: (context) {
                  return orgProvider.allRoles.map((role) {
                    final isCurrent = role.id == orgProvider.role?.id;
                    return PopupMenuItem<int>(
                      value: role.id,
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield,
                            size: 16,
                            color: isCurrent ? const Color(0xFF1967D2) : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            role.name,
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? const Color(0xFF1967D2) : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        orgProvider.role?.name ?? 'Member',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Members',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Roles',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
