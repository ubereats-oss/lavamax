import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lavamax/core/constants/app_colors.dart';
import 'package:lavamax/core/constants/app_dimensions.dart';
import 'package:lavamax/core/utils/formatters.dart';
import 'package:lavamax/data/models/appointment_model.dart';
import 'package:lavamax/data/models/branch_model.dart';
import 'package:lavamax/data/models/service_model.dart';
import 'package:lavamax/data/models/vehicle_model.dart';
import 'package:lavamax/presentation/providers/appointment_provider.dart';
import 'package:lavamax/presentation/providers/branch_provider.dart';
import 'package:lavamax/presentation/providers/connectivity_provider.dart';
import 'package:lavamax/presentation/providers/service_provider.dart';
import 'package:lavamax/presentation/providers/user_provider.dart';
import 'package:lavamax/presentation/providers/vehicle_provider.dart';
import 'package:lavamax/presentation/screens/appointment_detail_screen.dart';
import 'package:lavamax/presentation/widgets/custom_app_bar.dart';
class MyAppointmentsScreen extends ConsumerWidget {
  const MyAppointmentsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Meus Agendamentos',
          showBackButton: true,
        ),
        body: const Center(
          child: Text('Usuario nao autenticado.'),
        ),
      );
    }
    final isOnline = ref.watch(isOnlineProvider);
    final appointmentsAsync =
        ref.watch(customerAppointmentsProvider(currentUser.uid));
    final userAsync = ref.watch(userRoleProvider);
    final customerName = userAsync.when(
      data: (u) => u?.name ?? '',
      loading: () => '',
      error: (_, _) => '',
    );
    final branchesAsync = ref.watch(branchesProvider);
    final servicesAsync = ref.watch(servicesProvider);
    final vehiclesAsync = ref.watch(userVehiclesProvider);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Meus Agendamentos',
        showBackButton: true,
      ),
      body: Column(
        children: [
          if (!isOnline)
            Container(
              width: double.infinity,
              color: Colors.orange.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Modo offline — exibindo dados salvos. '
                      'Cancelamentos requerem internet.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: appointmentsAsync.when(
              data: (appointments) {
                if (appointments.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: AppColors.grey400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum agendamento encontrado.',
                          style: TextStyle(color: AppColors.grey600),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(
                    AppDimensions.screenPaddingHorizontal,
                  ),
                  itemCount: appointments.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppDimensions.paddingSmall),
                  itemBuilder: (context, index) {
                    return _AppointmentCard(
                      appointment: appointments[index],
                      customerName: customerName,
                      branches: branchesAsync.valueOrNull ?? [],
                      services: servicesAsync.valueOrNull ?? [],
                      vehicles: vehiclesAsync.valueOrNull ?? [],
                      isOnline: isOnline,
                      onChanged: () => ref.invalidate(
                        customerAppointmentsProvider(currentUser.uid),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isOnline
                          ? 'Erro ao carregar agendamentos.'
                          : 'Sem conexão. Não há dados salvos localmente.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.grey600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.customerName,
    required this.branches,
    required this.services,
    required this.vehicles,
    required this.isOnline,
    required this.onChanged,
  });
  final AppointmentModel appointment;
  final String customerName;
  final List<BranchModel> branches;
  final List<ServiceModel> services;
  final List<VehicleModel> vehicles;
  final bool isOnline;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final statusInfo = _statusInfo(appointment.status);
    final branchName = appointment.branchName.isNotEmpty
        ? appointment.branchName
        : _resolveName(
            branches,
            appointment.branchId,
            fallback: appointment.branchId,
          );
    final serviceName = appointment.serviceName.isNotEmpty
        ? appointment.serviceName
        : _resolveName(
            services,
            appointment.serviceId,
            fallback: appointment.serviceId,
          );
    final vehicle = _resolveVehicle(appointment.vehicleId);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusMedium,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusMedium,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppointmentDetailScreen(
              appointment: appointment,
              customerName: customerName,
              resolvedBranchName: branchName,
              resolvedServiceName: serviceName,
              isOnline: isOnline,
              onCanceled: onChanged,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            AppDimensions.paddingMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormat.format(
                            appointment.appointmentDate,
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          timeFormat.format(
                            appointment.appointmentDate,
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.grey600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusInfo.$2.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusInfo.$1,
                      style: TextStyle(
                        color: statusInfo.$2,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(
                height: AppDimensions.paddingLarge,
              ),
              _infoRow(
                context,
                Icons.store_outlined,
                'Filial: $branchName',
              ),
              const SizedBox(height: 6),
              _infoRow(
                context,
                Icons.local_car_wash_outlined,
                'Serviço: $serviceName',
              ),
              if (appointment.consultantName.isNotEmpty) ...[
                const SizedBox(height: 6),
                _infoRow(
                  context,
                  Icons.person_outline,
                  'Consultor: ${appointment.consultantName}',
                ),
              ],
              if (vehicle != null) ...[
                const SizedBox(height: 6),
                _infoRow(
                  context,
                  Icons.pin_outlined,
                  'Placa: ${formatPlate(vehicle.plate)}',
                ),
              ],
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Ver detalhes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  VehicleModel? _resolveVehicle(String vehicleId) {
    try {
      return vehicles.firstWhere((e) => e.id == vehicleId);
    } catch (_) {
      return null;
    }
  }
  String _resolveName<T>(
    List<T> items,
    String id, {
    required String fallback,
  }) {
    try {
      final item = (items as List).firstWhere(
        (e) => (e as dynamic).id == id,
      );
      return (item as dynamic).name as String;
    } catch (_) {
      return fallback;
    }
  }
  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
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
