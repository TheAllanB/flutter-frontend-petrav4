import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/node.dart';
import '../../providers/auth_provider.dart';
import '../../providers/org_provider.dart';
import '../../services/org_service.dart';
import '../screens/organizations/workspace/node_view_screen.dart';

class RecursiveNodeTree extends StatefulWidget {
  final Node node;
  final bool canEdit;

  const RecursiveNodeTree({
    super.key,
    required this.node,
    required this.canEdit,
  });

  @override
  State<RecursiveNodeTree> createState() => _RecursiveNodeTreeState();
}

class _RecursiveNodeTreeState extends State<RecursiveNodeTree> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NodeViewScreen(
                    node: widget.node,
                    orgId: context.read<OrganizationProvider>().currentOrg!.id,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              dense: true,
              leading: const Icon(Icons.folder, color: Color(0xFF1967D2), size: 22),
              title: Text(
                widget.node.name, 
                style: const TextStyle(
                  fontWeight: FontWeight.w600, 
                  color: Color(0xFF0D253F),
                  fontSize: 14,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.canEdit) ...[
                    IconButton(
                      icon: const Icon(Icons.shield_outlined, size: 18, color: Colors.grey),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                      onPressed: () => NodeDialog.show(
                        context, 
                        parentNode: null, 
                        editingNode: widget.node, 
                        orgId: context.read<OrganizationProvider>().currentOrg!.id,
                        onNodesUpdated: (nodes) => context.read<OrganizationProvider>().setNodes(nodes),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                    const SizedBox(width: 12),
                  ],
                  InkWell(
                    onTap: () {
                      if (widget.node.children.isNotEmpty) {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      }
                    },
                    child: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more, 
                      size: 24, 
                      color: widget.node.children.isNotEmpty ? const Color(0xFF1967D2) : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isExpanded && widget.node.children.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 22.0, bottom: 8.0),
            padding: const EdgeInsets.only(left: 16.0),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFFE2E8F0), width: 2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.node.children.map((child) => RecursiveNodeTree(
                node: child, 
                canEdit: widget.canEdit,
              )).toList(),
            ),
          ),
      ],
    );
  }
}

class NodeDialog {
  static void show(BuildContext context, {
    required Node? parentNode,
    required Node? editingNode,
    required int orgId,
    required Function(List<Node>) onNodesUpdated,
  }) {
    final isEdit = editingNode != null;
    final nameCtrl = TextEditingController(text: isEdit ? editingNode.name : '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Node' : 'Add Child Node'),
        content: TextField(
          controller: nameCtrl, 
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              try {
                final token = context.read<AuthProvider>().token;
                
                if (isEdit) {
                  await OrgService(token).updateNode(orgId, editingNode.id, nameCtrl.text);
                } else {
                  await OrgService(token).createNode(orgId, nameCtrl.text, 'folder', parentId: parentNode?.id);
                }
                
                // Reload ALL nodes array to rebuild tree correctly
                final flatNodes = await OrgService(token).getNodes(orgId, parentId: 'all');
                onNodesUpdated(flatNodes);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                String errorMsg = e.toString();
                // Try to parse Laravel's JSON error response
                if (errorMsg.contains('{')) {
                  try {
                    final startIndex = errorMsg.indexOf('{');
                    final jsonStr = errorMsg.substring(startIndex);
                    final data = jsonDecode(jsonStr);
                    if (data['errors'] != null && data['errors']['name'] != null) {
                      errorMsg = data['errors']['name'][0];
                    } else if (data['message'] != null) {
                      errorMsg = data['message'];
                    }
                  } catch (_) {}
                }
                
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(errorMsg.replaceFirst('Exception: ', '')),
                      backgroundColor: Colors.redAccent,
                    )
                  );
                }
              }
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      )
    );
  }
}
