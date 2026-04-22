import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/consultant_model.dart';
import '../../../data/repositories/consultant_repository.dart';
import 'package:lavamax/core/utils/formatters.dart';
class AdminConsultantsScreen extends StatefulWidget {
  const AdminConsultantsScreen({super.key});
  @override
  State<AdminConsultantsScreen> createState() => _AdminConsultantsScreenState();
}
class _AdminConsultantsScreenState extends State<AdminConsultantsScreen> {
  final _repo = ConsultantRepository(FirebaseFirestore.instance);
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  void _openForm({ConsultantModel? consultant}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ConsultantFormScreen(
          consultant: consultant,
          repo: _repo,
          db: _db,
        ),
      ),
    );
  }
  Future<void> _toggleActive(ConsultantModel c) async {
    await _repo.update(c.id, {'is_active': !c.isActive});
  }
  Future<void> _delete(ConsultantModel c) async {
    final nav = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir consultor'),
        content: Text('Deseja excluir "${c.name}"?'),
        actions: [
          TextButton(
            onPressed: () => nav.pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => nav.pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm == true) await _repo.delete(c.id);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultores')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('consultants').orderBy('name').snapshots(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Nenhum consultor cadastrado.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final c = ConsultantModel.fromFirestore(docs[i]);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: c.isActive
                      ? Colors.blue.shade100
                      : Colors.grey.shade200,
                  child: Icon(
                    Icons.person_outline,
                    color: c.isActive ? Colors.blue : Colors.grey,
                  ),
                ),
                title: Text(c.name),
                subtitle: Text(
                  c.phone.isNotEmpty
                      ? '${formatPhone(c.phone)} · Limite: ${c.dailyLimit} atend./dia'
                      : 'Limite: ${c.dailyLimit} atend./dia',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: c.isActive,
                      onChanged: (_) => _toggleActive(c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openForm(consultant: c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      onPressed: () => _delete(c),
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
// ── Formatter de telefone: (XX)XXXXX-XXXX ──────────────────────
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final d = digits.length > 11 ? digits.substring(0, 11) : digits;
    String formatted;
    if (d.length <= 2) {
      formatted = '($d';
    } else if (d.length <= 7) {
      formatted = '(${d.substring(0, 2)})${d.substring(2)}';
    } else {
      formatted =
          '(${d.substring(0, 2)})${d.substring(2, 7)}-${d.substring(7)}';
    }
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
class _ConsultantFormScreen extends StatefulWidget {
  final ConsultantModel? consultant;
  final ConsultantRepository repo;
  final FirebaseFirestore db;
  const _ConsultantFormScreen({
    required this.consultant,
    required this.repo,
    required this.db,
  });
  @override
  State<_ConsultantFormScreen> createState() => _ConsultantFormScreenState();
}
class _ConsultantFormScreenState extends State<_ConsultantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _limitCtrl;
  String? _selectedBranchId;
  List<QueryDocumentSnapshot> _branchDocs = [];
  bool _branchesLoading = true;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.consultant?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.consultant?.phone ?? '');
    _limitCtrl = TextEditingController(
      text: (widget.consultant?.dailyLimit ?? 16).toString(),
    );
    _selectedBranchId = widget.consultant?.branchId;
    _loadBranches();
  }
  Future<void> _loadBranches() async {
    try {
      final snap = await widget.db
          .collection('branches')
          .where('is_active', isEqualTo: true)
          .get();
      if (mounted) {
        final sorted = snap.docs.toList()
          ..sort((a, b) =>
              (a['name'] as String).compareTo(b['name'] as String));
        setState(() => _branchDocs = sorted);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar filiais: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _branchesLoading = false);
    }
  }
  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a filial')),
      );
      return;
    }
    final nav = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final limit = int.tryParse(_limitCtrl.text.trim()) ?? 16;
      if (widget.consultant == null) {
        await widget.repo.create(
          ConsultantModel(
            id: '',
            name: name,
            phone: phone,
            branchId: _selectedBranchId!,
            dailyLimit: limit,
            isActive: true,
          ),
        );
      } else {
        await widget.repo.update(widget.consultant!.id, {
          'name': name,
          'phone': phone,
          'branch_id': _selectedBranchId,
          'daily_limit': limit,
        });
      }
      nav.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final isNew = widget.consultant == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Novo Consultor' : 'Editar Consultor'),
      ),
      body: _branchesLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o nome'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_PhoneFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Telefone de contato',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '(71)99999-9999',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _limitCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Limite de atendimentos por dia',
                        prefixIcon: Icon(Icons.event_available_outlined),
                      ),
                      validator: (v) => (int.tryParse(v ?? '') == null)
                          ? 'Informe um numero valido'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Filial',
                        prefixIcon: Icon(Icons.store_outlined),
                      ),
                      initialValue: _selectedBranchId,
                      items: _branchDocs
                          .map((d) => DropdownMenuItem<String>(
                                value: d.id,
                                child: Text(d['name'] as String),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedBranchId = v),
                      validator: (v) =>
                          v == null ? 'Selecione a filial' : null,
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Salvar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
