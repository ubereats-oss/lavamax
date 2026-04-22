import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lavamax/core/constants/app_colors.dart';
import 'package:lavamax/data/models/credit_model.dart';
import 'package:lavamax/data/repositories/credit_repository.dart';
import 'package:lavamax/data/services/firebase_service.dart';
class AdminCreditsScreen extends StatefulWidget {
  const AdminCreditsScreen({super.key});
  @override
  State<AdminCreditsScreen> createState() => _AdminCreditsScreenState();
}
class _AdminCreditsScreenState extends State<AdminCreditsScreen> {
  final _repo = CreditRepository(FirebaseService().firestore);
  List<CreditModel> _credits = [];
  bool _loading = true;
  int _maxCredits = 1;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.getAllCredits(),
        _repo.getMaxCredits(),
      ]);
      if (mounted) {
        setState(() {
          _credits = results[0] as List<CreditModel>;
          _maxCredits = results[1] as int;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  Future<void> _editMaxCredits() async {
    final ctrl =
        TextEditingController(text: _maxCredits.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limite de creditos por cliente'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Maximo de creditos ativos',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null && v > 0) Navigator.pop(context, v);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _repo.setMaxCredits(result);
      if (mounted) setState(() => _maxCredits = result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Limite atualizado para $result.')),
        );
      }
    }
  }
  Future<void> _toggleCredit(CreditModel credit) async {
    final isActive = credit.status == 'active';
    final action = isActive ? 'cancelar' : 'reativar';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${isActive ? 'Cancelar' : 'Reativar'} credito'),
        content: Text(
            'Deseja $action o credito de ${credit.customerName.isNotEmpty ? credit.customerName : 'este cliente'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isActive ? 'Cancelar credito' : 'Reativar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (isActive) {
        await _repo.cancelCredit(credit.id);
      } else {
        await _repo.reactivateCredit(credit.id);
      }
      _load();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creditos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Configurar limite',
            onPressed: _editMaxCredits,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erro: $_error'))
              : Column(
                  children: [
                    // Banner de configuração
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: AppColors.grey100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 16, color: AppColors.grey600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Limite atual: $_maxCredits credito(s) ativo(s) por cliente',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.grey600),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: _editMaxCredits,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Editar limite'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _credits.isEmpty
                          ? const Center(
                              child: Text('Nenhum credito encontrado.'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _credits.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) => _CreditTile(
                                credit: _credits[i],
                                onToggle: () =>
                                    _toggleCredit(_credits[i]),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
class _CreditTile extends StatelessWidget {
  const _CreditTile({
    required this.credit,
    required this.onToggle,
  });
  final CreditModel credit;
  final VoidCallback onToggle;
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final statusInfo = _statusInfo(credit.status);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusInfo.$2.withValues(alpha: 0.15),
          child: Icon(Icons.card_giftcard,
              color: statusInfo.$2, size: 20),
        ),
        title: Text(
          credit.customerName.isNotEmpty
              ? credit.customerName
              : 'Cliente',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(credit.branchName.isNotEmpty
                ? credit.branchName
                : 'Filial'),
            Text(
              'Gerado em ${dateFormat.format(credit.createdAt)}'
              '${credit.serviceName.isNotEmpty ? ' • ${credit.serviceName}' : ''}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.grey500),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusInfo.$2.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusInfo.$1,
                style: TextStyle(
                  color: statusInfo.$2,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (credit.status != 'used') ...[
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  credit.status == 'active'
                      ? Icons.block_outlined
                      : Icons.restore_outlined,
                  size: 20,
                  color: credit.status == 'active'
                      ? AppColors.error
                      : AppColors.success,
                ),
                tooltip: credit.status == 'active'
                    ? 'Cancelar credito'
                    : 'Reativar credito',
                onPressed: onToggle,
              ),
            ],
          ],
        ),
      ),
    );
  }
  (String, Color) _statusInfo(String status) {
    return switch (status) {
      'active' => ('Ativo', AppColors.success),
      'used' => ('Usado', AppColors.info),
      _ => ('Cancelado', AppColors.error),
    };
  }
}
