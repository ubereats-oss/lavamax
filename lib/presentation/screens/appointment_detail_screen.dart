import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lavamax/core/constants/app_colors.dart';
import 'package:lavamax/core/constants/app_dimensions.dart';
import 'package:lavamax/core/utils/formatters.dart';
import 'package:lavamax/data/models/appointment_model.dart';
import 'package:lavamax/data/repositories/appointment_repository.dart';
import 'package:lavamax/data/repositories/credit_repository.dart';
import 'package:lavamax/data/services/firebase_service.dart';
import 'package:lavamax/presentation/providers/service_provider.dart';
import 'package:lavamax/presentation/providers/vehicle_provider.dart';
import 'package:lavamax/presentation/widgets/custom_app_bar.dart';
class AppointmentDetailScreen extends ConsumerWidget {
  final AppointmentModel appointment;
  final String customerName;
  final String resolvedBranchName;
  final String resolvedServiceName;
  final bool isOnline;
  final VoidCallback onCanceled;
  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
    required this.customerName,
    required this.resolvedBranchName,
    required this.resolvedServiceName,
    required this.isOnline,
    required this.onCanceled,
  });
  bool get _canCancel =>
      appointment.status == 'pending' ||
      appointment.status == 'confirmed';
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final statusInfo = _statusInfo(appointment.status);
    final code = appointment.id.substring(0, 8).toUpperCase();
    // Resolve serviço e veículo diretamente na tela — sem depender do pai
    final servicesAsync = ref.watch(servicesProvider);
    final vehiclesAsync = ref.watch(userVehiclesProvider);
    // Preço: busca na lista de serviços pelo serviceId
    final servicePrice = servicesAsync.whenOrNull(
      data: (list) {
        try {
          return list.firstWhere((s) => s.id == appointment.serviceId).price;
        } catch (_) {
          return null;
        }
      },
    );
    // Placa: busca na lista de veículos pelo vehicleId
    final vehiclePlate = vehiclesAsync.whenOrNull(
      data: (list) {
        try {
          return list.firstWhere((v) => v.id == appointment.vehicleId).plate;
        } catch (_) {
          return null;
        }
      },
    );
    // Verifica se o usuário atual é o dono — para mostrar veículos
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid == appointment.customerId;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Detalhes do Agendamento',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
            AppDimensions.screenPaddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppDimensions.paddingLarge),
            // Banner de modo offline
            if (!isOnline)
              Container(
                margin: const EdgeInsets.only(
                    bottom: AppDimensions.paddingMedium),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off,
                        color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Modo offline — cancelamento indisponível.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            // Badge de status centralizado
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: statusInfo.$2.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusInfo.$1,
                  style: TextStyle(
                    color: statusInfo.$2,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Serviço ──────────────────────────────────
                    _sectionTitle('Serviço'),
                    const Divider(),
                    _row(context, 'Filial', resolvedBranchName),
                    _row(context, 'Serviço', resolvedServiceName),
                    _row(context, 'Data',
                        dateFormat.format(appointment.appointmentDate)),
                    _row(context, 'Horário',
                        timeFormat.format(appointment.appointmentDate)),
                    _row(
                      context,
                      'Valor',
                      servicePrice != null
                          ? formatBrl(servicePrice)
                          : '—',
                    ),
                    // ── Veículo ───────────────────────────────────
                    if (isOwner) ...[
                      const SizedBox(
                          height: AppDimensions.paddingMedium),
                      _sectionTitle('Veículo'),
                      const Divider(),
                      _row(
                        context,
                        'Placa',
                        vehiclePlate != null
                            ? formatPlate(vehiclePlate)
                            : '—',
                      ),
                    ],
                    // ── Consultor ─────────────────────────────────
                    if (appointment.consultantName.isNotEmpty) ...[
                      const SizedBox(
                          height: AppDimensions.paddingMedium),
                      _sectionTitle('Consultor'),
                      const Divider(),
                      _row(context, 'Nome',
                          appointment.consultantName),
                      _row(
                        context,
                        'Telefone',
                        appointment.consultantPhone.isNotEmpty
                            ? formatPhone(appointment.consultantPhone)
                            : '—',
                      ),
                    ],
                    // ── Identificação ─────────────────────────────
                    const SizedBox(
                        height: AppDimensions.paddingMedium),
                    _sectionTitle('Identificação'),
                    const Divider(),
                    _row(context, 'Código', '#$code'),
                  ],
                ),
              ),
            ),
            if (_canCancel) ...[
              const SizedBox(height: AppDimensions.paddingLarge),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isOnline ? AppColors.error : AppColors.grey400,
                  side: BorderSide(
                      color: isOnline
                          ? AppColors.error
                          : AppColors.grey400),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.cancel_outlined),
                label: Text(isOnline
                    ? 'Cancelar agendamento'
                    : 'Cancelar agendamento (requer internet)'),
                onPressed: isOnline ? () => _tryCancel(context) : null,
              ),
            ],
            const SizedBox(height: AppDimensions.paddingLarge),
          ],
        ),
      ),
    );
  }
  Widget _sectionTitle(String title) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingSmall / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.grey600)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _tryCancel(BuildContext context) async {
    final creditRepo =
        CreditRepository(FirebaseService().firestore);
    bool limitReached = false;
    int maxCredits = 2;
    maxCredits = await creditRepo.getMaxCredits();
    limitReached =
        await creditRepo.hasReachedLimit(appointment.customerId);
    if (limitReached) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Cancelamento bloqueado'),
            content: Text(
              'Voce ja tem $maxCredits credito(s) ativo(s) — '
              'limite maximo atingido.\n\n'
              'Use seus creditos em novos agendamentos antes de '
              'cancelar este.',
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
    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar agendamento'),
        content: const Text(
          'Tem certeza? Um credito sera gerado automaticamente '
          'para uso em novo agendamento nesta filial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar agendamento'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AppointmentRepository(FirebaseService().firestore)
            .cancelAppointment(appointment, customerName);
        onCanceled();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Agendamento cancelado. Credito gerado para novo agendamento.',
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao cancelar: $e')),
          );
        }
      }
    }
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
