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
  
  // Available permissions mapped by group
  final Map<String, List<Map<String, String>>> _allPermissions = {
    'Organization': [
      {'key': 'org.view', 'label': 'View Organization'},
      {'key': 'org.edit', 'label': 'Edit Organization'},
    ],
    'Members': [
      {'key': 'member.invite', 'label': 'Invite Member'},
      {'key': 'member.remove', 'label': 'Remove Member'},
      {'key': 'member.assignRole', 'label': 'Assign Role'},
    ],
    'Roles': [
      {'key': 'role.create', 'label': 'Create Role'},
      {'key': 'role.edit', 'label': 'Edit Role'},
    ],
    'Chat': [
      {'key': 'chat.send', 'label': 'Send Chat'},
      {'key': 'chat.download', 'label': 'Download Chat'},
    ],
  };

  void _addRoleDialog() {
    String roleName = '';
    List<String> selectedPerms = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Add Custom Role'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Role Name'),
                    onChanged: (val) => roleName = val,
                  ),
                  const SizedBox(height: 16),
                  const Text('Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._allPermissions.entries.map((group) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(group.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ...group.value.map((perm) {
                          return CheckboxListTile(
                            title: Text(perm['label']!),
                            value: selectedPerms.contains(perm['key']),
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) selectedPerms.add(perm['key']!);
                                else selectedPerms.remove(perm['key']);
                              });
                            },
                          );
                        }).toList(),
                      ],
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
                child: const Text('Add Role'),
              ),
            ],
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
