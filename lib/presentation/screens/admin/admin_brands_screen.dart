import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class AdminBrandsScreen extends StatefulWidget {
  const AdminBrandsScreen({super.key});
  @override
  State<AdminBrandsScreen> createState() => _AdminBrandsScreenState();
}
class _AdminBrandsScreenState extends State<AdminBrandsScreen> {
  final _db = FirebaseFirestore.instance;
  String? _selectedBrandId;
  String? _selectedBrandName;
  List<String> _currentModels = [];
  // ---------- MARCA ----------
  void _showBrandDialog({String? id, String? current}) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id == null ? 'Nova Marca' : 'Editar Marca'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome da marca'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              if (id == null) {
                await _db
                    .collection('vehicle_brands')
                    .add({'name': name, 'models': []});
              } else {
                await _db
                    .collection('vehicle_brands')
                    .doc(id)
                    .update({'name': name});
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
  Future<void> _deleteBrand(String id) async {
    final confirm = await _confirmDelete('esta marca e todos os seus modelos');
    if (!confirm) return;
    await _db.collection('vehicle_brands').doc(id).delete();
    setState(() {
      _selectedBrandId = null;
      _selectedBrandName = null;
    });
  }
  // ---------- MODELO ----------
  void _showModelDialog({
    required String brandId,
    required List<String> models,
    int? index,
  }) {
    final ctrl =
        TextEditingController(text: index != null ? models[index] : '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(index == null ? 'Novo Modelo' : 'Editar Modelo'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome do modelo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              final updated = List<String>.from(models);
              if (index == null) {
                updated.add(name);
              } else {
                updated[index] = name;
              }
              await _db
                  .collection('vehicle_brands')
                  .doc(brandId)
                  .update({'models': updated});
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
  Future<void> _deleteModel(
      String brandId, List<String> models, int index) async {
    final confirm = await _confirmDelete('o modelo "${models[index]}"');
    if (!confirm) return;
    final updated = List<String>.from(models)..removeAt(index);
    await _db
        .collection('vehicle_brands')
        .doc(brandId)
        .update({'models': updated});
  }
  // ---------- UTIL ----------
  Future<bool> _confirmDelete(String target) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirmar exclusao'),
            content: Text('Deseja excluir $target?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;
  }
  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedBrandId == null
            ? 'Marcas'
            : 'Modelos — $_selectedBrandName'),
        leading: _selectedBrandId != null
            ? BackButton(
                onPressed: () => setState(() {
                  _selectedBrandId = null;
                  _selectedBrandName = null;
                }),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedBrandId == null
            ? () => _showBrandDialog()
            : () => _showModelDialog(
                brandId: _selectedBrandId!,
                models: _currentModels,
              ),
        child: const Icon(Icons.add),
      ),
      body: _selectedBrandId == null
          ? _buildBrandList()
          : _buildModelList(_selectedBrandId!),
    );
  }
  Widget _buildBrandList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('vehicle_brands')
          .orderBy('name')
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final name = doc['name'] as String;
            final models =
                (doc['models'] as List?)?.cast<String>() ?? [];
            return ListTile(
              title: Text(name),
              subtitle: Text('${models.length} modelos'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        _showBrandDialog(id: doc.id, current: name),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red),
                    onPressed: () => _deleteBrand(doc.id),
                  ),
                ],
              ),
              onTap: () => setState(() {
                _selectedBrandId = doc.id;
                _selectedBrandName = name;
              }),
            );
          },
        );
      },
    );
  }
  Widget _buildModelList(String brandId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('vehicle_brands').doc(brandId).snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data?.data() as Map<String, dynamic>?;
        final models =
            (data?['models'] as List?)?.cast<String>() ?? [];
        // UX 5: _currentModels atualizado dentro de setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentModels != models) {
            setState(() => _currentModels = models);
          }
        });
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: models.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(models[i]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showModelDialog(
                          brandId: brandId,
                          models: models,
                          index: i,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () =>
                            _deleteModel(brandId, models, i),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Modelo'),
                  onPressed: () =>
                      _showModelDialog(brandId: brandId, models: models),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
