import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../providers/org_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/report_service.dart';
import '../../../../services/org_service.dart';
import '../../../../models/node.dart';
import '../../../../models/role.dart';

class CreateReportScreen extends StatefulWidget {
  final int orgId;
  const CreateReportScreen({super.key, required this.orgId});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class QuestionModel {
  String type;
  String title;
  bool isRequired;
  List<String> options;

  QuestionModel({
    required this.type,
    required this.title,
    this.isRequired = false,
    List<String>? options,
  }) : options = options ?? [];

  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'is_required': isRequired,
    'options': options.isNotEmpty ? options : null,
  };
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _deadline;
  
  List<QuestionModel> _questions = [
    QuestionModel(type: 'Short Answer', title: '')
  ];

  final List<Map<String, dynamic>> _selectedTargets = [];
  bool _isSaving = false;
  bool _isLoadingData = true;
  List<Node> _allNodes = [];
  List<Role> _allRoles = [];
  List<dynamic> _allMembers = [];

  final List<String> _questionTypes = [
    'Short Answer', 'Paragraph', 'Multiple Choice', 
    'Checkboxes', 'Drop-down', 'Linear Scale', 'File Upload'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    try {
      final token = context.read<AuthProvider>().token!;
      final orgService = OrgService(token);
      final futures = await Future.wait([
        orgService.getRoles(widget.orgId),
        orgService.getMembers(widget.orgId),
      ]);
      if (mounted) {
        setState(() {
          _allNodes = context.read<OrganizationProvider>().nodeTree;
          _allRoles = futures[0] as List<Role>;
          _allMembers = futures[1];
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null && mounted) {
        setState(() {
          _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a report title.')));
      return;
    }
    if (_selectedTargets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one target.')));
      return;
    }
    for (var q in _questions) {
      if (q.title.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All questions must have a title.')));
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final rs = ReportService(token);

      List<Map<String, dynamic>> targets = _selectedTargets.map((t) => {
        'target_type': t['type'],
        'target_id': t['id']
      }).toList();

      await rs.createReport(widget.orgId, {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'deadline': _deadline?.toIso8601String(),
        'questions': _questions.map((q) => q.toJson()).toList(),
        'targets': targets,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report Published!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create Report', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1967D2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Publish Report', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 24),
            _buildQuestionsSection(),
            const SizedBox(height: 24),
            _buildTargetsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: const Color(0xFF1967D2), width: 8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
            decoration: const InputDecoration(
              hintText: 'Report Title',
              border: InputBorder.none,
            ),
          ),
          TextField(
            controller: _descController,
            maxLines: null,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: const InputDecoration(
              hintText: 'Form description',
              border: InputBorder.none,
            ),
          ),
          const Divider(height: 32),
          Row(
            children: [
              const Icon(Icons.event, color: Colors.grey, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _deadline == null 
                    ? 'No deadline set' 
                    : 'Deadline: ${DateFormat('MMM dd, yyyy - hh:mm a').format(_deadline!)}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              TextButton(
                onPressed: _pickDeadline,
                child: Text(_deadline == null ? 'Set Deadline' : 'Change Limit'),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ..._questions.asMap().entries.map((entry) {
          final index = entry.key;
          final q = entry.value;
          return _buildQuestionCard(index, q);
        }),
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              _questions.add(QuestionModel(type: 'Short Answer', title: ''));
            });
          },
          label: const Text('Add Question'),
          icon: const Icon(Icons.add),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1967D2),
          elevation: 2,
        )
      ],
    );
  }

  Widget _buildQuestionCard(int index, QuestionModel q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
                  ),
                  child: TextField(
                    onChanged: (val) => q.title = val,
                    decoration: const InputDecoration(
                      hintText: 'Question',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: q.type,
                      isExpanded: true,
                      items: _questionTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        setState(() {
                          q.type = val!;
                          if (['Short Answer', 'Paragraph'].contains(val)) {
                            q.options.clear();
                          } else if (q.options.isEmpty) {
                            q.options.add('Option 1');
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildQuestionOptions(q),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: () {
                  setState(() => _questions.removeAt(index));
                },
              ),
              const SizedBox(width: 8),
              const Text('Required', style: TextStyle(color: Colors.black87)),
              Switch(
                value: q.isRequired,
                onChanged: (val) => setState(() => q.isRequired = val),
                activeColor: const Color(0xFF1967D2),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuestionOptions(QuestionModel q) {
    if (q.type == 'Short Answer') {
      return const Text('Short answer text', style: TextStyle(color: Colors.grey));
    } else if (q.type == 'Paragraph') {
      return const Text('Long answer text', style: TextStyle(color: Colors.grey));
    } else if (['Multiple Choice', 'Checkboxes', 'Drop-down'].contains(q.type)) {
      IconData icon = Icons.radio_button_unchecked;
      if (q.type == 'Checkboxes') icon = Icons.check_box_outline_blank;
      if (q.type == 'Drop-down') icon = Icons.looks_one_outlined;

      return Column(
        children: [
          ...q.options.asMap().entries.map((optEntry) {
            int optIdx = optEntry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(icon, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: optEntry.value)
                        ..selection = TextSelection.collapsed(offset: optEntry.value.length),
                      onChanged: (val) => q.options[optIdx] = val,
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => setState(() => q.options.removeAt(optIdx)),
                  )
                ],
              ),
            );
          }),
          Row(
            children: [
              Icon(icon, color: Colors.grey, size: 20),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => setState(() => q.options.add('Option ${q.options.length + 1}')),
                child: const Text('Add option'),
              )
            ],
          )
        ],
      );
    } else if (q.type == 'File Upload') {
      return const Text('File upload area', style: TextStyle(color: Colors.grey));
    }
    return const SizedBox.shrink();
  }

  Widget _buildTargetsSection() {
    if (_isLoadingData) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TARGET ASSIGNMENTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Target'),
                onPressed: () async {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => _TargetSelectionDialog(
                      allNodes: _allNodes,
                      allRoles: _allRoles,
                      allMembers: _allMembers,
                    ),
                  );
                  if (result != null && mounted) {
                    setState(() {
                      // Avoid duplicates
                      if (!_selectedTargets.any((t) => t['type'] == result['type'] && t['id'] == result['id'])) {
                        _selectedTargets.add(result);
                      }
                    });
                  }
                },
              )
            ],
          ),
          const SizedBox(height: 8),
          const Text('Select the nodes, roles, or specific users that must submit this report. Nodes apply to all active members inside them.', style: TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 16),
          if (_selectedTargets.isEmpty)
            const Text('No targets selected.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTargets.map((t) {
              IconData icon = Icons.person;
              Color color = Colors.grey;
              if (t['type'] == 'node') { icon = Icons.folder; color = Colors.blue; }
              if (t['type'] == 'role') { icon = Icons.shield; color = Colors.orange; }
              return Chip(
                avatar: Icon(icon, size: 16, color: color),
                label: Text(t['name']),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() => _selectedTargets.remove(t));
                },
              );
            }).toList(),
          )
        ],
      ),
    );
  }
}

class _TargetSelectionDialog extends StatefulWidget {
  final List<Node> allNodes;
  final List<Role> allRoles;
  final List<dynamic> allMembers;

  const _TargetSelectionDialog({
    required this.allNodes,
    required this.allRoles,
    required this.allMembers,
  });

  @override
  State<_TargetSelectionDialog> createState() => _TargetSelectionDialogState();
}

class _TargetSelectionDialogState extends State<_TargetSelectionDialog> {
  int _tabIndex = 0;
  final Map<int?, List<Node>> _childrenMap = {};
  int? _filterNodeId;

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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        height: 600,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  const Text('Select Target', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ],
              ),
            ),
            Row(
              children: [
                _buildTab(0, 'Nodes'),
                _buildTab(1, 'Roles'),
                _buildTab(2, 'Users'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: _tabIndex == 0 
                ? _buildNodesView() 
                : _tabIndex == 1
                  ? _buildRolesView()
                  : _buildUsersView(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final active = _tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: active ? const Color(0xFF1967D2) : Colors.transparent, width: 2)),
          ),
          child: Text(
            title, 
            textAlign: TextAlign.center, 
            style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? const Color(0xFF1967D2) : Colors.grey)
          ),
        ),
      ),
    );
  }

  Widget _buildNodesView() {
    var rootNodes = _childrenMap[null] ?? [];
    if (rootNodes.isEmpty) return const Center(child: Text('No nodes found.'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: rootNodes.map((n) => _NodeTreeItem(
        node: n,
        childrenMap: _childrenMap,
        level: 0,
        onSelect: (id, name) => Navigator.pop(context, {'type': 'node', 'id': id, 'name': name}),
      )).toList(),
    );
  }

  Widget _buildRolesView() {
    if (widget.allRoles.isEmpty) return const Center(child: Text('No roles found.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.allRoles.length,
      itemBuilder: (context, i) {
        final r = widget.allRoles[i];
        return ListTile(
          leading: const Icon(Icons.shield, color: Colors.orange),
          title: Text(r.name),
          onTap: () => Navigator.pop(context, {'type': 'role', 'id': r.id, 'name': r.name}),
        );
      },
    );
  }

  Widget _buildUsersView() {
    List<dynamic> filteredMembers = widget.allMembers;
    
    // Filter members by selected node
    if (_filterNodeId != null) {
      filteredMembers = widget.allMembers.where((m) {
        final roles = m['roles'] as List<dynamic>? ?? [];
        return roles.any((r) => r['node_id'] == _filterNodeId);
      }).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<int?>(
            decoration: const InputDecoration(
              labelText: 'Filter by Node',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            value: _filterNodeId,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Nodes')),
              ...widget.allNodes.map((n) => DropdownMenuItem(value: n.id, child: Text(n.name))),
            ],
            onChanged: (val) => setState(() => _filterNodeId = val),
          ),
        ),
        Expanded(
          child: filteredMembers.isEmpty 
            ? const Center(child: Text('No users found in this node.'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredMembers.length,
                itemBuilder: (context, i) {
                  final u = filteredMembers[i];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person, size: 18)),
                    title: Text(u['name']),
                    subtitle: Text(u['handle'] != null ? '@${u['handle']}' : u['email']),
                    onTap: () => Navigator.pop(context, {'type': 'user', 'id': u['id'], 'name': u['name']}),
                  );
                },
              ),
        )
      ],
    );
  }
}

class _NodeTreeItem extends StatefulWidget {
  final Node node;
  final Map<int?, List<Node>> childrenMap;
  final int level;
  final Function(int, String) onSelect;

  const _NodeTreeItem({
    required this.node,
    required this.childrenMap,
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
    final isFolder = true; // Use simple visual default

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: widget.level * 16.0, bottom: 4.0),
          child: ListTile(
            dense: true,
            leading: Icon(isFolder ? Icons.folder : Icons.tag, color: const Color(0xFF1967D2), size: 20),
            title: Text(widget.node.name, style: const TextStyle(fontWeight: FontWeight.normal, color: Color(0xFF0D253F))),
            onTap: () => widget.onSelect(widget.node.id, widget.node.name),
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
            level: widget.level + 1,
            onSelect: widget.onSelect,
          )),
      ],
    );
  }
}
