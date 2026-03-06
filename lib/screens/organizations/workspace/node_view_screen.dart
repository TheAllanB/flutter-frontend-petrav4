import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/node.dart';
import '../../../providers/org_provider.dart';
import '../../../widgets/recursive_node_tree.dart';

class NodeViewScreen extends StatefulWidget {
  final Node node;
  final int orgId;

  const NodeViewScreen({
    super.key,
    required this.node,
    required this.orgId,
  });

  @override
  State<NodeViewScreen> createState() => _NodeViewScreenState();
}

class _NodeViewScreenState extends State<NodeViewScreen> {
  bool _isFabExpanded = false;

  @override
  Widget build(BuildContext context) {
    final orgProvider = context.watch<OrganizationProvider>();
    // Find the current node in the provider's tree to get latest state (after edits/additions)
    final currentNode = _findNode(orgProvider.nodeTree, widget.node.id) ?? widget.node;
    final canCreate = orgProvider.hasPermission('node.sub.create');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          currentNode.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1967D2),
        foregroundColor: Colors.white,
      ),
      body: currentNode.children.isEmpty
          ? const Center(
              child: Text(
                'No sub-nodes found.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: currentNode.children.length,
              itemBuilder: (context, index) {
                return RecursiveNodeTree(
                  node: currentNode.children[index],
                  canEdit: canCreate,
                );
              },
            ),
      floatingActionButton: canCreate ? _buildExpandableFab(orgProvider, currentNode) : null,
    );
  }

  Node? _findNode(List<Node> nodes, int id) {
    for (var n in nodes) {
      if (n.id == id) return n;
      final found = _findNode(n.children, id);
      if (found != null) return found;
    }
    return null;
  }

  Widget _buildExpandableFab(OrganizationProvider provider, Node currentNode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isFabExpanded) ...[
          _buildFabOption(
            icon: Icons.account_tree_outlined,
            label: 'Structure',
            onTap: () {
              setState(() => _isFabExpanded = false);
              NodeDialog.show(
                context,
                parentNode: currentNode,
                editingNode: null,
                orgId: widget.orgId,
                onNodesUpdated: (nodes) => provider.setNodes(nodes),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildFabOption(
            icon: Icons.shield_outlined,
            label: 'Role',
            onTap: () {
              setState(() => _isFabExpanded = false);
              // Placeholder for role management within node
            },
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          onPressed: () => setState(() => _isFabExpanded = !_isFabExpanded),
          backgroundColor: const Color(0xFF1967D2),
          child: Icon(_isFabExpanded ? Icons.close : Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildFabOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D253F)),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          onPressed: onTap,
          backgroundColor: Colors.white,
          child: Icon(icon, color: const Color(0xFF1967D2), size: 20),
        ),
      ],
    );
  }
}
