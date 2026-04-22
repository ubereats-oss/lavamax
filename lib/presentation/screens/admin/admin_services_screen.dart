import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lavamax/core/utils/formatters.dart';
import 'package:lavamax/data/services/firebase_service.dart';
import 'package:uuid/uuid.dart';
class AdminServicesScreen extends StatelessWidget {
  const AdminServicesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const _AdminServicesView();
  }
}
class _AdminServicesView extends StatefulWidget {
  const _AdminServicesView();
  @override
  State<_AdminServicesView> createState() => _AdminServicesViewState();
}
class _AdminServicesViewState extends State<_AdminServicesView> {
  final FirebaseFirestore _db = FirebaseService().firestore;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final _uuid = const Uuid();
  // ── Diálogo de criação / edição ────────────────────────────────────────────
  void _showDialog({String? id, Map<String, dynamic>? data}) {
    final nameCtrl =
        TextEditingController(text: data?['name'] as String? ?? '');
    final descCtrl =
        TextEditingController(text: data?['description'] as String? ?? '');
    final urlCtrl =
        TextEditingController(text: data?['icon_url'] as String? ?? '');
    final priceCtrl = TextEditingController(
      text: data != null
          ? NumberFormat('#,##0.00', 'pt_BR')
              .format((data['price'] as num).toDouble())
          : '',
    );
    final durationCtrl = TextEditingController(
      text: data != null ? (data['duration_minutes'] as num).toString() : '',
    );
    final sortOrderCtrl = TextEditingController(
      text: data != null
          ? ((data['sort_order'] as int?) ?? 0).toString()
          : '',
    );
    XFile? pickedFile;
    bool uploading = false;
    String? uploadError;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(id == null ? 'Novo Serviço' : 'Editar Serviço'),
        content: StatefulBuilder(
          builder: (context, setInner) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Ordem ──
                TextField(
                  controller: sortOrderCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Ordem de exibição',
                    hintText: 'Ex: 1, 2, 3...',
                    prefixIcon: Icon(Icons.swap_vert),
                  ),
                ),
                const SizedBox(height: 12),
                // ── Nome ──
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                // ── Descrição ──
                TextField(
                  controller: descCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: 16),
                // ── Seção ícone ──
                Text(
                  'Ícone do serviço',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                _IconPreview(
                  networkUrl: urlCtrl.text,
                  localFile: pickedFile,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(pickedFile == null
                      ? 'Escolher imagem do dispositivo'
                      : 'Trocar imagem (${pickedFile!.name})'),
                  onPressed: uploading
                      ? null
                      : () async {
                          final file = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                            maxWidth: 256,
                            maxHeight: 256,
                          );
                          if (file != null) {
                            setInner(() {
                              pickedFile = file;
                              urlCtrl.text = '';
                              uploadError = null;
                            });
                          }
                        },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ou cole uma URL de imagem',
                    hintText: 'https://...',
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty && pickedFile != null) {
                      setInner(() => pickedFile = null);
                    }
                  },
                ),
                if (uploadError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    uploadError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                // ── Preço ──
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_BrlCurrencyFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Preço (R\$)',
                    prefixText: 'R\$ ',
                  ),
                ),
                const SizedBox(height: 12),
                // ── Duração ──
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Duração (minutos)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: uploading ? null : () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          StatefulBuilder(
            builder: (context, setSave) => FilledButton(
              onPressed: uploading
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      setSave(() => uploading = true);
                      try {
                        String finalUrl = urlCtrl.text.trim();
                        if (pickedFile != null) {
                          final ext = pickedFile!.name.split('.').last;
                          final storagePath =
                              'services/icons/${_uuid.v4()}.$ext';
                          final ref = _storage.ref(storagePath);
                          await ref.putFile(
                            File(pickedFile!.path),
                            SettableMetadata(
                              contentType: 'image/$ext',
                              customMetadata: {
                                'cacheControl': 'public, max-age=31536000',
                              },
                            ),
                          );
                          finalUrl = await ref.getDownloadURL();
                        }
                        final payload = <String, dynamic>{
                          'name': name,
                          'description': descCtrl.text.trim(),
                          'icon_url': finalUrl,
                          'price': _parseBrl(priceCtrl.text),
                          'duration_minutes':
                              int.tryParse(durationCtrl.text.trim()) ?? 0,
                          'sort_order':
                              int.tryParse(sortOrderCtrl.text.trim()) ?? 0,
                          'updated_at': FieldValue.serverTimestamp(),
                        };
                        if (id == null) {
                          payload['is_active'] = true;
                          payload['created_at'] =
                              FieldValue.serverTimestamp();
                          await _db.collection('services').add(payload);
                        } else {
                          payload['is_active'] = data?['is_active'] ?? true;
                          await _db
                              .collection('services')
                              .doc(id)
                              .update(payload);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setSave(() {
                          uploading = false;
                          uploadError = 'Erro ao salvar: $e';
                        });
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Erro ao salvar: $e')),
                          );
                        }
                      }
                    },
              child: uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
  }
  // ── Toggle ativo/inativo ───────────────────────────────────────────────────
  Future<void> _toggleActive(String id, bool current) async {
    await _db.collection('services').doc(id).update({
      'is_active': !current,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
  // ── Exclusão ──────────────────────────────────────────────────────────────
  Future<void> _delete(String id, String name) async {
    final activeSnap = await _db
        .collection('appointments')
        .where('service_id', isEqualTo: id)
        .where('status', whereIn: ['pending', 'confirmed'])
        .limit(1)
        .get();
    if (activeSnap.docs.isNotEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Exclusão bloqueada'),
            content: Text(
              'O serviço "$name" possui agendamentos ativos.\n\n'
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
        title: const Text('Excluir serviço'),
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
      await _db.collection('services').doc(id).delete();
    }
  }
  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Serviços')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('services')
            .orderBy('sort_order')
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
              final d = doc.data() as Map<String, dynamic>;
              final name = d['name'] as String? ?? '';
              final price = d['price'] as num? ?? 0;
              final duration = d['duration_minutes'] as num? ?? 0;
              final isActive = d['is_active'] as bool? ?? true;
              final iconUrl = d['icon_url'] as String? ?? '';
              final sortOrder = d['sort_order'] as int? ?? 0;
              return ListTile(
                leading: _ListIcon(iconUrl: iconUrl, isActive: isActive),
                title: Text(name),
                subtitle: Text(
                  '#$sortOrder — ${formatBrl(price.toDouble())} — ${duration}min',
                ),
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
// ── Widgets auxiliares ────────────────────────────────────────────────────────
class _IconPreview extends StatelessWidget {
  final String networkUrl;
  final XFile? localFile;
  const _IconPreview({required this.networkUrl, this.localFile});
  @override
  Widget build(BuildContext context) {
    Widget image;
    if (localFile != null) {
      image = Image.file(
        File(localFile!.path),
        width: 64,
        height: 64,
        fit: BoxFit.contain,
      );
    } else if (networkUrl.isNotEmpty) {
      image = Image.network(
        networkUrl,
        width: 64,
        height: 64,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.broken_image_outlined, size: 48),
      );
    } else {
      image = const Icon(Icons.image_outlined, size: 48, color: Colors.grey);
    }
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: image,
        ),
      ),
    );
  }
}
class _ListIcon extends StatelessWidget {
  final String iconUrl;
  final bool isActive;
  const _ListIcon({required this.iconUrl, required this.isActive});
  @override
  Widget build(BuildContext context) {
    if (iconUrl.isNotEmpty) {
      return Image.network(
        iconUrl,
        width: 32,
        height: 32,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.car_repair, size: 32),
      );
    }
    return Icon(
      isActive ? Icons.local_car_wash : Icons.local_car_wash_outlined,
      color: isActive ? Colors.green : Colors.grey,
    );
  }
}
// ── Helpers BRL ───────────────────────────────────────────────────────────────
double _parseBrl(String text) {
  final clean = text.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(clean) ?? 0.0;
}
class _BrlCurrencyFormatter extends TextInputFormatter {
  final _fmt = NumberFormat('#,##0.00', 'pt_BR');
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final cents = int.tryParse(digits) ?? 0;
    final formatted = _fmt.format(cents / 100);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
