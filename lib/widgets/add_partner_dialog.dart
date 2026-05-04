import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class AddPartnerDialog extends StatefulWidget {
  const AddPartnerDialog({super.key});

  @override
  State<AddPartnerDialog> createState() => _AddPartnerDialogState();
}

class _AddPartnerDialogState extends State<AddPartnerDialog> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _foundUser;
  bool _isLoading = false;
  bool _requestSent = false;

  void _performSearch() async {
    setState(() {
      _isLoading = true;
      _foundUser = null;
      _requestSent = false;
    });

    final currentUserId = AuthService().currentUser!.uid;
    final user = await DatabaseService(userId: currentUserId).searchUser(_searchController.text);

    setState(() {
      _foundUser = user;
      _isLoading = false;
    });
  }

  void _sendRequest() async {
    if (_foundUser == null) return;
    
    setState(() => _isLoading = true);
    
    final currentUserId = AuthService().currentUser!.uid;
    await DatabaseService(userId: currentUserId).sendPartnerRequest(_foundUser!['uid'], _foundUser!);
    
    setState(() {
      _isLoading = false;
      _requestSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Find a Partner"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Search by Username, Email, or 6-digit Code.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Enter search term...",
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _performSearch,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => _performSearch(),
          ),
          
          if (_isLoading) 
            const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
            
          if (_foundUser != null && !_requestSent) ...[
            const Divider(height: 32),
            ListTile(
              leading: CircleAvatar(child: Text(_foundUser!['displayName'][0].toUpperCase())),
              title: Text(_foundUser!['displayName'], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: ElevatedButton(
                onPressed: _sendRequest,
                child: const Text("Add"),
              ),
            ),
          ],

          if (_requestSent) ...[
            const Divider(height: 32),
            const Text("Request Sent!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ]
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
      ],
    );
  }
}