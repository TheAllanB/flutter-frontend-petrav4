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
  List<dynamic> _requests = [];
  List<Node> _allNodes = [];
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
      final orgProvider = context.read<OrganizationProvider>();
      final orgId = orgProvider.currentOrg!.id;
      final canEditMembers = orgProvider.hasPermission('org.members.edit');

      if (token != null) {
        final activeRoleId = orgProvider.role?.id;
        final members = await OrgService(token).getMembers(orgId, roleId: activeRoleId);
        final nodes = await OrgService(token).getNodes(orgId, parentId: 'all');
        List<dynamic> requests = [];
        if (canEditMembers) {
          try {
            final rawRequests = await OrgService(token).getJoinRequests(orgId);
            requests = List<dynamic>.from(rawRequests);
            print('SUCCESS fetching join requests: ${requests.length}');
          } catch (e, stacktrace) {
            print('Error fetching join requests: $e\n$stacktrace');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('DEBUG_REQ_ERR: $e', maxLines: 5),
                  duration: const Duration(seconds: 10),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
        if (mounted) {
          setState(() {
            _members = members;
            _requests = requests;
            _allNodes = nodes;
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
          allNodes: _allNodes,
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
      body: Column(
        children: [
          if (canEditMembers)
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: _requests.isEmpty ? Colors.grey.shade200 : const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _requests.isEmpty ? Colors.grey.shade300 : const Color(0xFFFFEEBA)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _requests.isEmpty ? Colors.grey.shade600 : const Color(0xFF856404)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_requests.length} pending join requests',
                      style: TextStyle(color: _requests.isEmpty ? Colors.grey.shade700 : const Color(0xFF856404), fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _requests.isEmpty ? null : () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => _JoinRequestsSheet(
                          requests: _requests,
                          onRefresh: _loadMembers,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _requests.isEmpty ? Colors.grey.shade400 : const Color(0xFF856404),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('Review'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
                top: canEditMembers ? 0 : 16.0,
              ),
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
                            : roles.map((r) {
                                final nodePath = _getRoleNodePath(r['node_id']);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F0FE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    r['node_id'] == null ? r['name'] : "${r['name']} ($nodePath)",
                                    style: const TextStyle(color: Color(0xFF1967D2), fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                );
                              }).toList(),
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
     ),
    ],
   ),
  );
 }

 String _getRoleNodePath(int? nodeId) {
    if (nodeId == null || _allNodes.isEmpty) return 'Global';

    List<String> path = [];
    int? currentId = nodeId;

    while (currentId != null) {
      final node = _allNodes.firstWhere((n) => n.id == currentId, orElse: () => Node(id: -1, organizationId: -1, name: 'Unknown'));
      if (node.id == -1) break;
      path.insert(0, node.name);
      currentId = node.parentId;
    }

    return path.join(' > ');
  }
}

class _AssignRolesSheet extends StatefulWidget {
  final Map<String, dynamic> member;
  final List<Node> allNodes;
  final VoidCallback onSave;

  const _AssignRolesSheet({required this.member, required this.allNodes, required this.onSave});

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
    _allRoles = [];
    _allNodes = widget.allNodes;
    _fetchRoles();
  }

  String _getFullNodePath(int? nodeId) {
    if (nodeId == null || _allNodes.isEmpty) return 'Select Node';
    
    List<String> path = [];
    int? currentId = nodeId;
    
    while (currentId != null) {
      final node = _allNodes.firstWhere((n) => n.id == currentId, orElse: () => Node(id: -1, organizationId: -1, name: 'Unknown'));
      if (node.id == -1) break;
      path.insert(0, node.name);
      currentId = node.parentId;
    }
    
    return path.join(' > ');
  }

  Future<void> _fetchRoles() async {
    try {
      final token = context.read<AuthProvider>().token!;
      final orgId = context.read<OrganizationProvider>().currentOrg!.id;
      final roles = await OrgService(token).getRoles(orgId);
      if (mounted) {
        setState(() {
          _allRoles = roles;
          _isLoadingRoles = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRoles = false);
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
                                                      _getFullNodePath(_selectedRoles[role.id]),
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

class _JoinRequestsSheet extends StatefulWidget {
  final List<dynamic> requests;
  final VoidCallback onRefresh;

  const _JoinRequestsSheet({required this.requests, required this.onRefresh});

  @override
  State<_JoinRequestsSheet> createState() => _JoinRequestsSheetState();
}

class _JoinRequestsSheetState extends State<_JoinRequestsSheet> {
  List<Role> _allRoles = [];
  bool _isLoadingRoles = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    try {
      final token = context.read<AuthProvider>().token!;
      final orgId = context.read<OrganizationProvider>().currentOrg!.id;
      final roles = await OrgService(token).getRoles(orgId);
      if (mounted) {
        setState(() {
          _allRoles = roles;
          _isLoadingRoles = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRoles = false);
    }
  }

  Future<void> _acceptRequest(int requestId, int roleId) async {
    setState(() => _isProcessing = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final orgId = context.read<OrganizationProvider>().currentOrg!.id;
      await OrgService(token).acceptJoinRequest(orgId, requestId, roleId);
      if (mounted) {
        widget.onRefresh();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request accepted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    setState(() => _isProcessing = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final orgId = context.read<OrganizationProvider>().currentOrg!.id;
      await OrgService(token).rejectJoinRequest(orgId, requestId);
      if (mounted) {
        widget.onRefresh();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF856404),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_add, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Pending Join Requests', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          Expanded(
            child: _isLoadingRoles
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.requests.length,
                  itemBuilder: (context, index) {
                    final req = widget.requests[index];
                    return _RequestItem(
                      request: req,
                      allRoles: _allRoles,
                      isProcessing: _isProcessing,
                      onAccept: _acceptRequest,
                      onReject: _rejectRequest,
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _RequestItem extends StatefulWidget {
  final Map<String, dynamic> request;
  final List<Role> allRoles;
  final bool isProcessing;
  final Function(int, int) onAccept;
  final Function(int) onReject;

  const _RequestItem({
    required this.request,
    required this.allRoles,
    required this.isProcessing,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_RequestItem> createState() => _RequestItemState();
}

class _RequestItemState extends State<_RequestItem> {
  int? _selectedRole;

  @override
  void initState() {
    super.initState();
    if (widget.allRoles.isNotEmpty) {
      _selectedRole = widget.allRoles.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.request['user'];
    final handle = user['handle'] != null ? '@${user['handle']}' : 'No handle';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFFF3CD),
                  child: Text(user['name'][0].toUpperCase(), style: const TextStyle(color: Color(0xFF856404), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(handle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.allRoles.isNotEmpty)
              Row(
                children: [
                  const Text('Assign Role: ', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedRole,
                        isExpanded: true,
                        onChanged: (val) {
                          setState(() => _selectedRole = val);
                        },
                        items: widget.allRoles.map((r) => DropdownMenuItem<int>(
                          value: r.id,
                          child: Text(r.name, style: const TextStyle(fontSize: 14)),
                        )).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.isProcessing ? null : () => widget.onReject(widget.request['id']),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: widget.isProcessing || _selectedRole == null 
                    ? null 
                    : () => widget.onAccept(widget.request['id'], _selectedRole!),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1967D2), foregroundColor: Colors.white),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

