import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lavamax/data/services/firebase_service.dart';
class AdminBranchesScreen extends StatelessWidget {
  const AdminBranchesScreen({super.key});
  @override
  Widget build(BuildContext context) => _BranchesScaffold();
}
class _BranchesScaffold extends StatefulWidget {
  @override
  State<_BranchesScaffold> createState() => _BranchesScaffoldState();
}
class _BranchesScaffoldState extends State<_BranchesScaffold> {
  final FirebaseFirestore _db = FirebaseService().firestore;
  void _showDialog({String? id, Map<String, dynamic>? data}) {
    final nameCtrl =
        TextEditingController(text: data?['name'] as String? ?? '');
    final addressCtrl =
        TextEditingController(text: data?['address'] as String? ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id == null ? 'Nova Filial' : 'Editar Filial'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Endereco'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final address = addressCtrl.text.trim();
              if (name.isEmpty) return;
              // UX 3: inclui timestamps em criação e edição
              if (id == null) {
                await _db.collection('branches').add({
                  'name': name,
                  'address': address,
                  'is_active': true,
                  'created_at': FieldValue.serverTimestamp(),
                  'updated_at': FieldValue.serverTimestamp(),
                });
              } else {
                await _db.collection('branches').doc(id).update({
                  'name': name,
                  'address': address,
                  'is_active': data?['is_active'] ?? true,
                  'updated_at': FieldValue.serverTimestamp(),
                });
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
  Future<void> _toggleActive(String id, bool current) async {
    await _db
        .collection('branches')
        .doc(id)
        .update({
      'is_active': !current,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
  Future<void> _delete(String id, String name) async {
    // Seg 3: verifica agendamentos ativos antes de excluir
    final activeSnap = await _db
        .collection('appointments')
        .where('branch_id', isEqualTo: id)
        .where('status', whereIn: ['pending', 'confirmed'])
        .limit(1)
        .get();
    if (activeSnap.docs.isNotEmpty) {
      if (!mounted) return;
      if (true) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Exclusao bloqueada'),
            content: Text(
              'A filial "$name" possui agendamentos ativos.\n\n'
              'Cancele ou conclua todos os agendamentos antes de excluir.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi'),
              ),
            ],
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir filial'),
        content: Text('Deseja excluir "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.collection('branches').doc(id).delete();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filiais')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('branches').orderBy('name').snapshots(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final d = doc.data() as Map<String, dynamic>;
              final name = d['name'] as String? ?? '';
              final address = d['address'] as String? ?? '';
              final isActive = d['is_active'] as bool? ?? true;
              return ListTile(
                leading: Icon(
                  isActive ? Icons.store : Icons.store_outlined,
                  color: isActive ? Colors.green : Colors.grey,
                ),
                title: Text(name),
                subtitle: Text(address),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: isActive,
                      onChanged: (_) => _toggleActive(doc.id, isActive),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showDialog(id: doc.id, data: d),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      onPressed: () => _delete(doc.id, name),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
