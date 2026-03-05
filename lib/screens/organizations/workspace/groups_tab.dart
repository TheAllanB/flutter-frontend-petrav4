import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/org_provider.dart';
import '../../../services/org_service.dart';
import '../../../widgets/recursive_node_tree.dart';

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  void _showCreateRootDialog(BuildContext context, OrganizationProvider provider) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Root Group'),
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
                final orgId = provider.currentOrg!.id;
                await OrgService(token).createNode(orgId, nameCtrl.text, 'organization');
                
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
            child: const Text('Create'),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgProvider = context.watch<OrganizationProvider>();
    final canCreate = orgProvider.hasPermission('node.main.create');
    final nodes = orgProvider.nodeTree;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: nodes.isEmpty
          ? const Center(child: Text('No groups found.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: nodes.length,
              itemBuilder: (context, index) {
                return RecursiveNodeTree(
                  node: nodes[index],
                  canEdit: canCreate,
                );
              },
            ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => _showCreateRootDialog(context, orgProvider),
              backgroundColor: const Color(0xFF1967D2),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
