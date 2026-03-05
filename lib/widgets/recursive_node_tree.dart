import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/node.dart';
import '../../providers/auth_provider.dart';
import '../../providers/org_provider.dart';
import '../../services/org_service.dart';

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

  void _showNodeDialog(BuildContext context, {bool isEdit = false}) {
    final nameCtrl = TextEditingController(text: isEdit ? widget.node.name : '');
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
                final orgId = context.read<OrganizationProvider>().currentOrg!.id;
                
                if (isEdit) {
                  await OrgService(token).updateNode(orgId, widget.node.id, nameCtrl.text);
                } else {
                  await OrgService(token).createNode(orgId, nameCtrl.text, 'folder', parentId: widget.node.id);
                }
                
                // Reload nodes array
                final flatNodes = await OrgService(token).getNodes(orgId);
                if (ctx.mounted) {
                  ctx.read<OrganizationProvider>().setNodes(flatNodes);
                  Navigator.pop(ctx);
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      )
    );
  }

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
            trailing: widget.canEdit ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  onPressed: () => _showNodeDialog(context, isEdit: true),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
                const SizedBox(width: 12),
                if (widget.node.children.isNotEmpty || true)
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more, 
                      size: 20, 
                      color: const Color(0xFF1967D2),
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
              ],
            ) : null,
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
