import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../providers/org_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/report_service.dart';
import '../../../../services/org_service.dart';
import '../../../../models/node.dart';
import '../../../../models/role.dart';
import '../../../../widgets/recursive_node_tree.dart';

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
      final currentRoleId = context.read<OrganizationProvider>().role?.id;
      final targets = await ReportService(token).getReportTargets(widget.orgId, roleId: currentRoleId);
      
      if (mounted) {
        setState(() {
          final flatNodes = (targets['nodes'] as List?)?.map((n) => Node.fromJson(n)).toList() ?? [];
          final roles = (targets['roles'] as List?)?.map((r) => Role.fromJson(r)).toList() ?? [];
          final members = (targets['members'] as List?) ?? [];

          // Re-nest the flat nodes strictly within the allowed scope
          _allNodes = _buildTree(flatNodes);
          _allRoles = roles;
          _allMembers = members;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  List<Node> _buildTree(List<Node> nodes, {bool isRoot = true, int? parentId}) {
    Iterable<Node> currentNodes;
    if (isRoot) {
      final allIds = nodes.map((n) => n.id).toSet();
      currentNodes = nodes.where((n) => n.parentId == null || !allIds.contains(n.parentId));
    } else {
      currentNodes = nodes.where((n) => n.parentId == parentId);
    }
    
    return currentNodes.map((n) {
      return Node(
        id: n.id,
        organizationId: n.organizationId,
        parentId: n.parentId,
        name: n.name,
        description: n.description,
        children: _buildTree(nodes, isRoot: false, parentId: n.id),
      );
    }).toList();
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
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Create Report', style: TextStyle(color: Color(0xFF0D253F), fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF0D253F)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.withOpacity(0.2), height: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1967D2),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Publish', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 24),
            _buildQuestionsSection(),
            const SizedBox(height: 24),
            _buildTargetsSection(),
            const SizedBox(height: 48),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D253F)),
            decoration: const InputDecoration(
              hintText: 'Form Title',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _descController,
            maxLines: null,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
            decoration: const InputDecoration(
              hintText: 'Add a description or instructions...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1),
          ),
          InkWell(
            onTap: _pickDeadline,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1967D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.event_note_rounded, color: Color(0xFF1967D2), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Submission Deadline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          _deadline == null 
                            ? 'No deadline set' 
                            : DateFormat('EEEE, MMM dd • hh:mm a').format(_deadline!),
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.w500,
                            color: _deadline == null ? Colors.black38 : const Color(0xFF0D253F)
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('QUESTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
        ),
        ..._questions.asMap().entries.map((entry) {
          final index = entry.key;
          final q = entry.value;
          return _buildQuestionCard(index, q);
        }),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _questions.add(QuestionModel(type: 'Short Answer', title: ''));
              });
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add New Question', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: const Color(0xFF1967D2),
              side: const BorderSide(color: Color(0xFF1967D2), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildQuestionCard(int index, QuestionModel q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: (val) => q.title = val,
                  decoration: const InputDecoration(
                    hintText: 'Enter question title',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1967D2), width: 1.5)),
                  ),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF0D253F)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50], 
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: q.type,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1967D2)),
                      items: _questionTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14)))).toList(),
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
          const SizedBox(height: 20),
          _buildQuestionOptions(q),
          const SizedBox(height: 12),
          const Divider(),
          Row(
            children: [
              const Text('Required', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: q.isRequired,
                  onChanged: (val) => setState(() => q.isRequired = val),
                  activeColor: const Color(0xFF1967D2),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                onPressed: () {
                  setState(() => _questions.removeAt(index));
                },
                tooltip: 'Remove',
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuestionOptions(QuestionModel q) {
    if (q.type == 'Short Answer') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: const Text('Short answer text', style: TextStyle(color: Colors.black26, fontSize: 13, fontStyle: FontStyle.italic)),
      );
    } else if (q.type == 'Paragraph') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: const Text('Long answer text', style: TextStyle(color: Colors.black26, fontSize: 13, fontStyle: FontStyle.italic)),
      );
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
                  Icon(icon, color: Colors.grey[400], size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: optEntry.value)
                        ..selection = TextSelection.collapsed(offset: optEntry.value.length),
                      onChanged: (val) => q.options[optIdx] = val,
                      decoration: const InputDecoration(
                        border: InputBorder.none, 
                        isDense: true,
                        hintText: 'Option text',
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey[400]),
                    onPressed: () => setState(() => q.options.removeAt(optIdx)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, color: Colors.grey[300], size: 18),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => setState(() => q.options.add('Option ${q.options.length + 1}')),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('Add option', style: TextStyle(fontSize: 14, color: Color(0xFF1967D2))),
              )
            ],
          )
        ],
      );
    } else if (q.type == 'File Upload') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_upload_outlined, color: Colors.grey[400]),
            const SizedBox(width: 12),
            const Text('User will be able to upload files', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TARGET ASSIGNMENTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
              TextButton.icon(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('Manage Targets', style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF1967D2)),
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
          const Text('Select who must submit this report. Nodes apply to all members within.', style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 20),
          if (_selectedTargets.isEmpty)
             Container(
               width: double.infinity,
               padding: const EdgeInsets.symmetric(vertical: 24),
               decoration: BoxDecoration(
                 color: Colors.grey[50],
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.grey.withOpacity(0.1)),
               ),
               child: Column(
                 children: [
                   Icon(Icons.groups_outlined, color: Colors.grey[300], size: 32),
                   const SizedBox(height: 8),
                   const Text('No targets assigned yet', style: TextStyle(color: Colors.grey, fontSize: 13)),
                 ],
               ),
             ),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _selectedTargets.map((t) {
              IconData icon = Icons.person_rounded;
              Color color = Colors.grey;
              if (t['type'] == 'node') { icon = Icons.folder_rounded; color = const Color(0xFF1967D2); }
              if (t['type'] == 'role') { icon = Icons.shield_rounded; color = Colors.orange; }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 8),
                    Text(t['name'], style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => setState(() => _selectedTargets.remove(t)),
                      child: Icon(Icons.close_rounded, size: 16, color: color.withOpacity(0.6)),
                    ),
                  ],
                ),
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
  int? _filterNodeId;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
              ),
              child: Row(
                children: [
                  const Text('Select Target', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D253F))),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: active ? const Color(0xFF1967D2) : Colors.transparent, width: 2.5)),
          ),
          child: Text(
            title, 
            textAlign: TextAlign.center, 
            style: TextStyle(
              fontWeight: active ? FontWeight.bold : FontWeight.w500, 
              color: active ? const Color(0xFF1967D2) : Colors.black38,
              fontSize: 14,
            )
          ),
        ),
      ),
    );
  }

  Widget _buildNodesView() {
    if (widget.allNodes.isEmpty) return const Center(child: Text('No nodes found.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.allNodes.length,
      itemBuilder: (ctx, i) {
        final node = widget.allNodes[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: RecursiveNodeTree(
            node: node, 
            canEdit: false,
            onNodeTap: (selectedNode) => Navigator.pop(context, {'type': 'node', 'id': selectedNode.id, 'name': selectedNode.name}),
          ),
        );
      },
    );
  }

  Widget _buildRolesView() {
    if (widget.allRoles.isEmpty) return const Center(child: Text('No roles found.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.allRoles.length,
      itemBuilder: (context, i) {
        final r = widget.allRoles[i];
        return Card(
          elevation: 0,
          color: Colors.grey[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.shield_rounded, color: Colors.orange),
            title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(context, {'type': 'role', 'id': r.id, 'name': r.name}),
            trailing: const Icon(Icons.chevron_right, size: 18),
          ),
        );
      },
    );
  }

  Widget _buildUsersView() {
    List<dynamic> filteredMembers = widget.allMembers;
    
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
            decoration: InputDecoration(
              labelText: 'Filter by Node',
              labelStyle: const TextStyle(fontSize: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            ? const Center(child: Text('No users found.'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredMembers.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 48),
                itemBuilder: (context, i) {
                  final u = filteredMembers[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF1967D2).withOpacity(0.1),
                      child: const Icon(Icons.person_rounded, size: 20, color: Color(0xFF1967D2))
                    ),
                    title: Text(u['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(u['handle'] != null ? '@${u['handle']}' : u['email'], style: const TextStyle(fontSize: 12)),
                    onTap: () => Navigator.pop(context, {'type': 'user', 'id': u['id'], 'name': u['name']}),
                  );
                },
              ),
        )
      ],
    );
  }
}
