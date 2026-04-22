import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lavamax/core/constants/app_colors.dart';
import 'package:lavamax/data/models/appointment_model.dart';
import 'package:lavamax/data/models/branch_model.dart';
import 'package:lavamax/data/models/service_model.dart';
import 'package:lavamax/data/repositories/appointment_repository.dart';
import 'package:lavamax/data/repositories/branch_repository.dart';
import 'package:lavamax/data/repositories/service_repository.dart';
import 'package:lavamax/data/services/firebase_service.dart';
class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});
  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}
class _AdminAppointmentsScreenState
    extends State<AdminAppointmentsScreen> {
  final _repo = AppointmentRepository(FirebaseService().firestore);
  final _branchRepo = BranchRepository(FirebaseService().firestore);
  final _serviceRepo = ServiceRepository(FirebaseService().firestore);
  List<AppointmentModel> _all = [];
  List<BranchModel> _branches = [];
  List<ServiceModel> _services = [];
  bool _loading = true;
  String? _error;
  String _statusFilter = 'all';
  String? _branchFilter;
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
        _repo.getAllAppointments(),
        _branchRepo.getAllBranches(),
        _serviceRepo.getAllServices(),
      ]);
      if (mounted) {
        setState(() {
          _all = results[0] as List<AppointmentModel>;
          _branches = results[1] as List<BranchModel>;
          _services = results[2] as List<ServiceModel>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  List<AppointmentModel> get _filtered {
    return _all.where((a) {
      final statusOk =
          _statusFilter == 'all' || a.status == _statusFilter;
      final branchOk =
          _branchFilter == null || a.branchId == _branchFilter;
      return statusOk && branchOk;
    }).toList()
      ..sort((a, b) =>
          b.appointmentDate.compareTo(a.appointmentDate));
  }
  Future<void> _delete(AppointmentModel appointment) async {
    final code = appointment.id.substring(0, 8).toUpperCase();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir agendamento'),
        content: Text(
          'Excluir agendamento #$code?\n\n'
          'Esta acao nao pode ser desfeita. '
          'O slot sera liberado automaticamente se necessario.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _repo.deleteAppointment(appointment.id);
        if (mounted) {
          setState(
              () => _all.removeWhere((a) => a.id == appointment.id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendamento excluido.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos'),
        actions: [
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erro: $_error',
                          style:
                              const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load,
                          child: const Text('Tentar novamente')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filtros
                    _FilterBar(
                      statusFilter: _statusFilter,
                      branchFilter: _branchFilter,
                      branches: _branches,
                      onStatusChanged: (v) =>
                          setState(() => _statusFilter = v),
                      onBranchChanged: (v) =>
                          setState(() => _branchFilter = v),
                    ),
                    // Contador
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            '${filtered.length} agendamento(s)',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.grey500),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                  'Nenhum agendamento encontrado.'))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 0, 16, 16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) => _AppointmentRow(
                                appointment: filtered[i],
                                services: _services,
                                onDelete: () => _delete(filtered[i]),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
// ─────────────────────────────────────────
// Barra de filtros
// ─────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final String statusFilter;
  final String? branchFilter;
  final List<BranchModel> branches;
  final void Function(String) onStatusChanged;
  final void Function(String?) onBranchChanged;
  const _FilterBar({
    required this.statusFilter,
    required this.branchFilter,
    required this.branches,
    required this.onStatusChanged,
    required this.onBranchChanged,
  });
  @override
  Widget build(BuildContext context) {
    final statuses = [
      ('all', 'Todos'),
      ('pending', 'Pendente'),
      ('confirmed', 'Confirmado'),
      ('completed', 'Concluido'),
      ('canceled', 'Cancelado'),
    ];
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chips de status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statuses
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(s.$2),
                        selected: statusFilter == s.$1,
                        onSelected: (_) => onStatusChanged(s.$1),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          // Dropdown de filial
          if (branches.isNotEmpty) ...[
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              initialValue: branchFilter,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'Filial',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Todas as filiais')),
                ...branches.map(
                  (b) => DropdownMenuItem(
                      value: b.id, child: Text(b.name)),
                ),
              ],
              onChanged: onBranchChanged,
            ),
          ],
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────
// Row de agendamento
// ─────────────────────────────────────────
class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({
    required this.appointment,
    required this.services,
    required this.onDelete,
  });
  final AppointmentModel appointment;
  final List<ServiceModel> services;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final statusInfo = _statusInfo(appointment.status);
    // Preço: busca no ServiceModel; fallback para "—"
    final service = services.cast<ServiceModel?>().firstWhere(
          (s) => s?.id == appointment.serviceId,
          orElse: () => null,
        );
    final priceLabel = service != null
        ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
            .format(service.price)
        : '—';
    return Card(
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: statusInfo.$2,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          '${appointment.serviceName.isNotEmpty ? appointment.serviceName : 'Servico'} — ${appointment.branchName.isNotEmpty ? appointment.branchName : 'Filial'}',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(appointment.appointmentDate)),
            if (appointment.consultantName.isNotEmpty)
              Text(
                'Consultor: ${appointment.consultantName}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.grey600),
              ),
            Text(
              priceLabel,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grey700,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
  (String, Color) _statusInfo(String status) {
    return switch (status) {
      'confirmed' => ('Confirmado', AppColors.success),
      'completed' => ('Concluido', AppColors.info),
      'canceled' => ('Cancelado', AppColors.error),
      _ => ('Pendente', AppColors.warning),
    };
  }
}
