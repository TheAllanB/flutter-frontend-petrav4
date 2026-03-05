import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/org_provider.dart';
import '../../../../services/org_service.dart';
import '../../../../models/role.dart';
import '../../../../models/node.dart';

class MembersTab extends StatefulWidget {
  const MembersTab({super.key});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  List<dynamic> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      final orgId = context.read<OrganizationProvider>().currentOrg!.id;

      if (token != null) {
        final members = await OrgService(token).getMembers(orgId);
        if (mounted) {
          setState(() {
            _members = members;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading members: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAssignRoleBottomSheet(Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AssignRolesSheet(
          member: member,
          onSave: _loadMembers,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final orgProvider = context.watch<OrganizationProvider>();
    final canEditMembers = orgProvider.hasPermission('org.members.edit');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          final handle = member['handle'] != null ? '@${member['handle']}' : 'No handle';
          final roles = (member['roles'] as List<dynamic>?) ?? [];

          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE8F0FE),
                    radius: 24,
                    child: Text(
                      member['name'][0].toUpperCase(),
                      style: const TextStyle(color: Color(0xFF1967D2), fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D253F))),
                        const SizedBox(height: 2),
                        Text(handle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: roles.isEmpty 
                            ? [const Text('No Role', style: TextStyle(color: Colors.grey, fontSize: 12))]
                            : roles.map((r) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F0FE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(r['name'], style: const TextStyle(color: Color(0xFF1967D2), fontSize: 11, fontWeight: FontWeight.w600)),
                              )).toList(),
                        ),
                      ],
                    ),
                  ),
                  if (canEditMembers)
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.grey),
                      onPressed: () => _showAssignRoleBottomSheet(member),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AssignRolesSheet extends StatefulWidget {
  final Map<String, dynamic> member;
  final VoidCallback onSave;

  const _AssignRolesSheet({required this.member, required this.onSave});

  @override
  State<_AssignRolesSheet> createState() => _AssignRolesSheetState();
}

class _AssignRolesSheetState extends State<_AssignRolesSheet> {
  List<Role> _allRoles = [];
  List<Node> _allNodes = [];
  
  // Maps role_id -> node_id (null means global)
  final Map<int, int?> _selectedRoles = {};
  
  bool _isLoadingRoles = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final userRoles = (widget.member['roles'] as List<dynamic>?) ?? [];
    for (var r in userRoles) {
      _selectedRoles[r['id']] = r['node_id'];
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final token = context.read<AuthProvider>().token!;
      final orgId = context.read<OrganizationProvider>().currentOrg!.id;
      
      final roles = await OrgService(token).getRoles(orgId);
      final nodes = await OrgService(token).getNodes(orgId, parentId: 'all');
      
      if (mounted) {
        setState(() {
          _allRoles = roles;
          _allNodes = nodes;
          
          if (_allNodes.isNotEmpty) {
            for (var key in _selectedRoles.keys.toList()) {
              if (_selectedRoles[key] == null) {
                _selectedRoles[key] = _allNodes.first.id;
              }
            }
          }

          _isLoadingRoles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoles = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  Future<void> _saveAssignments() async {
    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final orgId = context.read<OrganizationProvider>().currentOrg!.id;
      
      final payload = _selectedRoles.entries.map((e) => {
        'role_id': e.key,
        'node_id': e.value,
      }).toList();

      await OrgService(token).assignRoles(orgId, widget.member['id'], payload);

      if (mounted) {
        widget.onSave();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Roles updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to assign roles: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1967D2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_add_alt_1, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ROLE ASSIGNMENT', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      Text('Roles for ${widget.member['name']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoadingRoles
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('ORGANIZATION ROLES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      ..._allRoles.map((role) {
                        final isSelected = _selectedRoles.containsKey(role.id);
                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              children: [
                                CheckboxListTile(
                                  title: Row(
                                    children: [
                                      const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF1967D2)),
                                      const SizedBox(width: 12),
                                      Text(role.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D253F))),
                                    ],
                                  ),
                                  activeColor: const Color(0xFF1967D2),
                                  value: isSelected,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedRoles[role.id] = _allNodes.isNotEmpty ? _allNodes.first.id : null;
                                      } else {
                                        _selectedRoles.remove(role.id);
                                      }
                                    });
                                  },
                                ),
                                if (isSelected)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.share_outlined, size: 14, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        const Text('Scope: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () async {
                                              if (_allNodes.isEmpty) return;
                                              final selectedId = await showDialog<int>(
                                                context: context,
                                                builder: (context) => NodeSelectionDialog(
                                                  allNodes: _allNodes,
                                                  selectedNodeId: _selectedRoles[role.id],
                                                ),
                                              );
                                              if (selectedId != null && mounted) {
                                                setState(() {
                                                  _selectedRoles[role.id] = selectedId;
                                                });
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _allNodes.firstWhere((n) => n.id == _selectedRoles[role.id], orElse: () => Node(id: -1, organizationId: -1, name: 'Select Node')).name,
                                                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
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
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveAssignments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1967D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Assignments'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NodeSelectionDialog extends StatefulWidget {
  final List<Node> allNodes;
  final int? selectedNodeId;

  const NodeSelectionDialog({super.key, required this.allNodes, this.selectedNodeId});

  @override
  State<NodeSelectionDialog> createState() => _NodeSelectionDialogState();
}

class _NodeSelectionDialogState extends State<NodeSelectionDialog> {
  final Map<int?, List<Node>> _childrenMap = {};

  @override
  void initState() {
    super.initState();
    for (var node in widget.allNodes) {
      final parentId = node.parentId;
      if (!_childrenMap.containsKey(parentId)) {
        _childrenMap[parentId] = [];
      }
      _childrenMap[parentId]!.add(node);
    }
  }

  @override
  Widget build(BuildContext context) {
    var rootNodes = _childrenMap[null] ?? [];
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Select Scope', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: rootNodes.isEmpty 
          ? const Center(child: Text('No nodes available'))
          : ListView(
              children: rootNodes.map((n) => _NodeTreeItem(
                node: n,
                childrenMap: _childrenMap,
                selectedNodeId: widget.selectedNodeId,
                level: 0,
                onSelect: (id) => Navigator.pop(context, id),
              )).toList(),
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        )
      ],
    );
  }
}

class _NodeTreeItem extends StatefulWidget {
  final Node node;
  final Map<int?, List<Node>> childrenMap;
  final int? selectedNodeId;
  final int level;
  final Function(int) onSelect;

  const _NodeTreeItem({
    required this.node,
    required this.childrenMap,
    required this.selectedNodeId,
    required this.level,
    required this.onSelect,
  });

  @override
  State<_NodeTreeItem> createState() => _NodeTreeItemState();
}

class _NodeTreeItemState extends State<_NodeTreeItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final children = widget.childrenMap[widget.node.id] ?? [];
    final hasChildren = children.isNotEmpty;
    final isSelected = widget.selectedNodeId == widget.node.id;
    // Assuming Node has 'type' logic? Wait, Node model doesn't have isFolder. Standardize to Icons.folder.
    final isFolder = true; // Let's simplify since Node model currently just has description

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: widget.level * 16.0, bottom: 4.0),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F0FE) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: const Color(0xFF1967D2).withOpacity(0.5)) : Border.all(color: Colors.transparent),
          ),
          child: ListTile(
            dense: true,
            leading: Icon(isFolder ? Icons.folder : Icons.tag, color: const Color(0xFF1967D2), size: 20),
            title: Text(widget.node.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF0D253F))),
            onTap: () => widget.onSelect(widget.node.id),
            trailing: hasChildren 
              ? IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
          ),
        ),
        if (_isExpanded && hasChildren)
          ...children.map((c) => _NodeTreeItem(
            node: c,
            childrenMap: widget.childrenMap,
            selectedNodeId: widget.selectedNodeId,
            level: widget.level + 1,
            onSelect: widget.onSelect,
          )),
      ],
    );
  }
}

