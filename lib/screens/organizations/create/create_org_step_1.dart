import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/org_service.dart';
import 'create_org_step_2.dart';

class CreateOrgStep1 extends StatefulWidget {
  const CreateOrgStep1({super.key});

  @override
  State<CreateOrgStep1> createState() => _CreateOrgStep1State();
}

class _CreateOrgStep1State extends State<CreateOrgStep1> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generateUid());
  }

  final _name = TextEditingController();
  final _uid = TextEditingController();
  final _website = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();

  bool _isCheckingUid = false;
  bool _uidAvailable = false;
  String? _uidError;

  Future<void> _checkUid(String uid) async {
    if (uid.length != 12) return;
    setState(() => _isCheckingUid = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        final available = await OrgService(token).checkUid(uid);
        setState(() {
          _uidAvailable = available;
          _uidError = available ? null : 'UID is already taken.';
        });
      }
    } catch (e) {
      setState(() => _uidError = 'Error checking UID');
    } finally {
      setState(() => _isCheckingUid = false);
    }
  }

  Future<void> _generateUid() async {
    setState(() => _isCheckingUid = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        final generated = await OrgService(token).generateUid();
        setState(() {
          _uid.text = generated;
          _uidAvailable = true;
          _uidError = null;
        });
      }
    } catch (e) {
      setState(() => _uidError = 'Failed to generate UID');
    } finally {
      setState(() => _isCheckingUid = false);
    }
  }

  void _next() {
    if (_name.text.isEmpty || _uid.text.length != 12 || !_uidAvailable) return;

    final data = {
      'name': _name.text,
      'uid': _uid.text,
      'website': _website.text,
      'location': _location.text,
      'description': _description.text,
      'roles': [], // to be populated
    };

    Navigator.push(context, MaterialPageRoute(builder: (_) => CreateOrgStep2(orgData: data)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Org - Step 1')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name (required)')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _uid,
                    readOnly: true,
                    maxLength: 12,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'UID (12 chars required)',
                      errorText: _uidError,
                      suffixIcon: _isCheckingUid
                          ? const CircularProgressIndicator()
                          : _uidAvailable ? const Icon(Icons.check, color: Colors.green) : null,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Auto-generate',
                  child: IconButton(icon: const Icon(Icons.refresh), onPressed: _generateUid),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _website, decoration: const InputDecoration(labelText: 'Website (optional)')),
            const SizedBox(height: 16),
            TextField(controller: _location, decoration: const InputDecoration(labelText: 'Location (optional)')),
            const SizedBox(height: 16),
            TextField(controller: _description, decoration: const InputDecoration(labelText: 'Description (optional)'), maxLines: 3),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _next, child: const Text('Next: Define Roles')),
          ],
        ),
      ),
    );
  }
}
