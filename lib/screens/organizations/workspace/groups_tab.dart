import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/org_provider.dart';
import '../../../services/org_service.dart';
import '../../../widgets/recursive_node_tree.dart';

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  void _showCreateRootDialog(BuildContext context, OrganizationProvider provider) {
    NodeDialog.show(
      context,
      parentNode: null,
      editingNode: null,
      orgId: provider.currentOrg!.id,
      onNodesUpdated: (nodes) {
        context.read<OrganizationProvider>().setNodes(nodes);
      },
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
