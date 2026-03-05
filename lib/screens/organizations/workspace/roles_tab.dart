import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/org_provider.dart';
import '../../../../services/org_service.dart';
import '../../../../models/role.dart';

class RolesTab extends StatefulWidget {
  const RolesTab({super.key});

  @override
  State<RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends State<RolesTab> {
  List<Role> _roles = [];
  Map<String, dynamic> _permissionsData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      final orgId = context.read<OrganizationProvider>().currentOrg!.id;

      if (token != null) {
        final orgService = OrgService(token);
        final rolesFuture = orgService.getRoles(orgId);
        final permsFuture = orgService.getPermissions();

        final results = await Future.wait([rolesFuture, permsFuture]);
        if (mounted) {
          setState(() {
            _roles = results[0] as List<Role>;
            _permissionsData = results[1] as Map<String, dynamic>;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading roles: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRoleDialog(Role? role) {
    showDialog(
      context: context,
      builder: (context) {
        return _EditRoleDialog(
          role: role,
          permissionsData: _permissionsData,
          onSave: _loadData,
        );
      },
    );
  }

  void _deleteRole(int roleId) async {
    // Scaffold UI logic for phase 1.9 or confirm deletion
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete role not yet implemented UI-wise')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final orgProvider = context.watch<OrganizationProvider>();
    final canEdit = orgProvider.hasPermission('org.roles.create') || orgProvider.hasPermission('org.roles.edit');

    // Make sure we have a scaffold context or similar to stack the FAB if needed, but we are inside TabBarView.
    // We can use a Stack here.
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
              child: Row(
                children: [
                  Icon(Icons.business, size: 14, color: Color(0xFF1967D2)),
                  SizedBox(width: 4),
                  Text('ORGANIZATION ROLES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1967D2))),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: _roles.length,
                itemBuilder: (context, index) {
                  final role = _roles[index];
                  final isOwner = role.isOwner == true;
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE8F0FE),
                        child: Icon(Icons.shield, color: Color(0xFF1967D2)),
                      ),
                      title: Text(role.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D253F))),
                      subtitle: Text('${role.permissionsCount} active permissions', style: const TextStyle(fontSize: 12)),
                      trailing: (!isOwner && canEdit) 
                        ? PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (val) {
                              if (val == 'edit') _showRoleDialog(role);
                              if (val == 'delete') _deleteRole(role.id);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          )
                        : (isOwner && canEdit ? IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () => _showRoleDialog(role),
                          ) : null),
                      onTap: () {
                        if (canEdit) _showRoleDialog(role);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (canEdit)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'add_role',
              backgroundColor: const Color(0xFF1967D2),
              foregroundColor: Colors.white,
              onPressed: () => _showRoleDialog(null),
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }
}

class _EditRoleDialog extends StatefulWidget {
  final Role? role;
  final Map<String, dynamic> permissionsData;
  final VoidCallback onSave;

  const _EditRoleDialog({
    this.role,
    required this.permissionsData,
    required this.onSave,
  });

  @override
  State<_EditRoleDialog> createState() => _EditRoleDialogState();
}

class _EditRoleDialogState extends State<_EditRoleDialog> {
  final _nameCtrl = TextEditingController();
  final Set<String> _selectedPermissions = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.role != null) {
      _nameCtrl.text = widget.role!.name;
      final perms = widget.role!.permissions;
      _selectedPermissions.addAll(perms.map((p) {
        if (p is Map) return p['key'].toString();
        return p.toString();
      }));
    }
  }

  void _togglePermission(String key) {
    if (widget.role != null && widget.role!.isOwner) {
      return; // Cannot edit owner permissions
    }
    setState(() {
      if (_selectedPermissions.contains(key)) {
        _selectedPermissions.remove(key);
      } else {
        _selectedPermissions.add(key);
      }
    });
  }

  Future<void> _saveRole() async {
    if (_nameCtrl.text.isEmpty) return;
    final isOwner = widget.role != null && widget.role!.isOwner;
    
    if (isOwner) {
      Navigator.pop(context); // Nothing to save for Owner role
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final token = context.read<AuthProvider>().token!;
      final orgId = context.read<OrganizationProvider>().currentOrg!.id;
      final service = OrgService(token);

      if (widget.role == null) {
        await service.createRole(orgId, _nameCtrl.text, _selectedPermissions.toList());
      } else {
        await service.updateRole(orgId, widget.role!.id, _nameCtrl.text, _selectedPermissions.toList());
      }

      if (mounted) {
        widget.onSave();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role saved successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save role: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.role != null && widget.role!.isOwner;

    return Dialog(
      backgroundColor: const Color(0xFFF4F7FC), // Match background of dialog
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1967D2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield, color: Colors.white),
                SizedBox(width: 8),
                Text('Edit Role Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Role Name Input
                TextField(
                  controller: _nameCtrl,
                  enabled: !isOwner,
                  decoration: InputDecoration(
                    labelText: 'Role Name',
                    prefixIcon: const Icon(Icons.assignment_ind_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1967D2)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 24),
                const Text('PERMISSIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1967D2))),
                const SizedBox(height: 8),

                // Permissions list grouped
                ...widget.permissionsData.entries.map((group) {
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      shape: const RoundedRectangleBorder(side: BorderSide(color: Colors.transparent)),
                      title: Text(group.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      children: (group.value as List<dynamic>).map((perm) {
                        return CheckboxListTile(
                          title: Text(perm['label'], style: const TextStyle(fontSize: 14, color: Color(0xFF0D253F))),
                          value: _selectedPermissions.contains(perm['key']),
                          onChanged: isOwner ? null : (val) => _togglePermission(perm['key']),
                          activeColor: const Color(0xFF1967D2),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveRole,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1967D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving 
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
