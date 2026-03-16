import 'package:flutter/material.dart';
import 'create_org_step_3.dart';

class CreateOrgStep2 extends StatefulWidget {
  final Map<String, dynamic> orgData;

  const CreateOrgStep2({super.key, required this.orgData});

  @override
  State<CreateOrgStep2> createState() => _CreateOrgStep2State();
}

class _CreateOrgStep2State extends State<CreateOrgStep2> {
  final List<Map<String, dynamic>> _customRoles = [];
  
  // Available permissions mapped by group (Matches the 18 permissions used in the app)
  final Map<String, List<Map<String, String>>> _allPermissions = {
    'Organization Settings': [
      {'key': 'org.settings.view', 'label': 'View Settings'},
      {'key': 'org.profile.edit', 'label': 'Edit Org Profile'},
      {'key': 'org.roles.create', 'label': 'Create Roles'},
      {'key': 'org.roles.edit', 'label': 'Edit Role Permissions'},
      {'key': 'org.members.edit', 'label': 'Edit Members'},
    ],
    'Chat & Communications': [
      {'key': 'chat.messages.send', 'label': 'Send Messages'},
      {'key': 'chat.media.download', 'label': 'Download Media'},
    ],
    'Nodes & Channels': [
      {'key': 'node.main.create', 'label': 'Create Main Nodes'},
      {'key': 'node.sub.create', 'label': 'Create Sub Nodes / Channels'},
      {'key': 'node.name.edit', 'label': 'Edit Node Name'},
      {'key': 'node.delete', 'label': 'Delete Node or Channel'},
      {'key': 'node.members.remove', 'label': 'Remove Member from Channel'},
      {'key': 'node.join.request', 'label': 'Request to Join'},
      {'key': 'node.join.auto', 'label': 'Join Without Request'},
      {'key': 'node.join.accept', 'label': 'Accept Join Requests'},
    ],
    'Hierarchical Reports': [
      {'key': 'report.node.view', 'label': 'View Node'},
      {'key': 'report.send', 'label': 'Send Report'},
      {'key': 'report.ask', 'label': 'Ask for Report'},
    ],
  };

  void _addRoleDialog() {
    String roleName = '';
    List<String> selectedPerms = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: const Color(0xFFF4F7FC),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      Text('Add Custom Role', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Role Name',
                          prefixIcon: const Icon(Icons.assignment_ind_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (val) => roleName = val,
                      ),
                      const SizedBox(height: 16),
                      ..._allPermissions.entries.map((group) {
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            title: Text(group.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            children: group.value.map((perm) {
                              return CheckboxListTile(
                                title: Text(perm['label']!, style: const TextStyle(fontSize: 14)),
                                value: selectedPerms.contains(perm['key']),
                                activeColor: const Color(0xFF1967D2),
                                controlAffinity: ListTileControlAffinity.leading,
                                dense: true,
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) selectedPerms.add(perm['key']!);
                                    else selectedPerms.remove(perm['key']);
                                  });
                                },
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
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (roleName.isNotEmpty) {
                            setState(() {
                              _customRoles.add({
                                'name': roleName,
                                'permissions': selectedPerms,
                              });
                            });
                            Navigator.pop(ctx);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1967D2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Add Role'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _next() {
    final updatedData = Map<String, dynamic>.from(widget.orgData);
    updatedData['roles'] = _customRoles;
    
    Navigator.push(context, MaterialPageRoute(builder: (_) => CreateOrgStep3(orgData: updatedData)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Org - Step 2')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Owner role is automatically created with full permissions.', style: TextStyle(fontStyle: FontStyle.italic)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _customRoles.length,
              itemBuilder: (context, index) {
                final role = _customRoles[index];
                return ListTile(
                  title: Text(role['name']),
                  subtitle: Text('${role['permissions'].length} permissions'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => _customRoles.removeAt(index));
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _addRoleDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Role'),
                ),
                ElevatedButton(onPressed: _next, child: const Text('Next: Review')),
              ],
            ),
          )
        ],
      ),
    );
  }
}
