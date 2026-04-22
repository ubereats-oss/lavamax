import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavamax/core/constants/app_colors.dart';
import 'package:lavamax/core/constants/app_dimensions.dart';
import 'package:lavamax/core/utils/formatters.dart';
import 'package:lavamax/data/models/vehicle_model.dart';
import 'package:lavamax/presentation/providers/branch_provider.dart';
import 'package:lavamax/presentation/providers/consultant_provider.dart';
import 'package:lavamax/presentation/providers/service_provider.dart';
import 'package:lavamax/presentation/providers/slot_provider.dart';
import 'package:lavamax/presentation/providers/vehicle_provider.dart';
import 'package:lavamax/presentation/screens/add_vehicle_screen.dart';
import 'package:lavamax/presentation/screens/branch_selection_screen.dart';
import 'package:lavamax/presentation/widgets/custom_app_bar.dart';
class VehicleSelectionScreen extends ConsumerWidget {
  /// [isFromBooking] = true  → exibe botão "Próximo" e avança para filiais.
  /// [isFromBooking] = false → modo gerenciamento (Meus Carros da home).
  final bool isFromBooking;
  const VehicleSelectionScreen({
    super.key,
    this.isFromBooking = true,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(userVehiclesProvider);
    final selectedVehicle = ref.watch(selectedVehicleProvider);
    return Scaffold(
      appBar: CustomAppBar(
        title: isFromBooking ? 'Selecione o Veiculo' : 'Meus Carros',
        showBackButton: true,
      ),
      body: vehiclesAsync.when(
        data: (vehicles) {
          return Column(
            children: [
              Expanded(
                child: vehicles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_car_outlined,
                                size: 64, color: AppColors.grey400),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhum veiculo cadastrado.',
                              style: TextStyle(color: AppColors.grey600),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _goToAddVehicle(context, ref),
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar Veiculo'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(
                            AppDimensions.screenPaddingHorizontal),
                        itemCount: vehicles.length,
                        separatorBuilder: (_, _) => const SizedBox(
                            height: AppDimensions.paddingSmall),
                        itemBuilder: (context, index) {
                          final vehicle = vehicles[index];
                          final isSelected =
                              selectedVehicle?.id == vehicle.id;
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMedium),
                              side: BorderSide(
                                color: isSelected && isFromBooking
                                    ? AppColors.accent
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.directions_car,
                                color: isSelected && isFromBooking
                                    ? AppColors.accent
                                    : AppColors.grey500,
                              ),
                              title: Text(
                                '${vehicle.brand} ${vehicle.model}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  '${vehicle.year} — ${formatPlate(vehicle.plate)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected && isFromBooking)
                                    const Icon(Icons.check_circle,
                                        color: AppColors.accent),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.error),
                                    onPressed: () async {
                                      final confirmed =
                                          await _confirmDelete(
                                              context, vehicle);
                                      if (!context.mounted) return;
                                      if (confirmed) {
                                        _deleteVehicle(
                                            context, ref, vehicle);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: isFromBooking
                                  ? () {
                                      ref
                                          .read(selectedVehicleProvider
                                              .notifier)
                                          .state = vehicle;
                                    }
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
              if (vehicles.isNotEmpty || isFromBooking)
                Padding(
                  padding: const EdgeInsets.all(
                      AppDimensions.screenPaddingHorizontal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _goToAddVehicle(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar outro veiculo'),
                      ),
                      if (isFromBooking) ...[
                        const SizedBox(
                            height: AppDimensions.paddingSmall),
                        ElevatedButton(
                          onPressed: selectedVehicle == null
                              ? null
                              : () => _advance(context, ref),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                                AppDimensions.buttonHeight),
                          ),
                          child: const Text('Proximo'),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Erro: $e')),
      ),
    );
  }
  /// Reseta filial/serviço/slot/consultor e avança para seleção de filial.
  void _advance(BuildContext context, WidgetRef ref) {
    ref.read(selectedBranchProvider.notifier).state = null;
    ref.read(selectedServiceProvider.notifier).state = null;
    ref.read(selectedDateProvider.notifier).state = null;
    ref.read(selectedSlotProvider.notifier).state = null;
    ref.read(selectedConsultantProvider.notifier).state = null;
    ref.read(consultantHasConflictProvider.notifier).state = false;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BranchSelectionScreen(),
      ),
    );
  }
  Future<bool> _confirmDelete(
      BuildContext context, VehicleModel vehicle) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Excluir veiculo'),
            content: Text(
              'Deseja excluir ${vehicle.brand} ${vehicle.model} (${formatPlate(vehicle.plate)})?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;
  }
  void _deleteVehicle(
      BuildContext context, WidgetRef ref, VehicleModel vehicle) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    ref
        .read(vehicleRepositoryProvider)
        .deleteVehicle(uid, vehicle.id);
    ref.invalidate(userVehiclesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('${vehicle.brand} ${vehicle.model} removido.')),
    );
  }
  void _goToAddVehicle(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
    );
  }
}
