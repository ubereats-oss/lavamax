import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavamax/core/constants/app_dimensions.dart';
import 'package:lavamax/core/constants/app_strings.dart';
import 'package:lavamax/presentation/providers/branch_provider.dart';
import 'package:lavamax/presentation/providers/consultant_provider.dart';
import 'package:lavamax/presentation/providers/service_provider.dart';
import 'package:lavamax/presentation/providers/slot_provider.dart';
import 'package:lavamax/presentation/providers/vehicle_provider.dart';
import 'package:lavamax/presentation/screens/service_selection_screen.dart';
import 'package:lavamax/presentation/widgets/branch_card.dart';
import 'package:lavamax/presentation/widgets/custom_app_bar.dart';
class BranchSelectionScreen extends ConsumerWidget {
  const BranchSelectionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);
    final selectedVehicle = ref.watch(selectedVehicleProvider);
    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.selectBranch,
        showBackButton: true,
      ),
      body: branchesAsync.when(
        data: (branches) {
          // Filtra filiais pela marca do veículo selecionado.
          // Regra: se a filial tem `allowedBrand`, só aparece se o veículo
          // for daquela marca. Filiais sem restrição aparecem sempre.
          final vehicleBrand = selectedVehicle?.brand.toLowerCase() ?? '';
          final filtered = branches.where((b) {
            if (b.allowedBrand == null) return true;
            return vehicleBrand == b.allowedBrand!.toLowerCase();
          }).toList();
          if (filtered.isEmpty) {
            return const Center(
              child: Text('Nenhuma filial disponível para este veículo.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final branch = filtered[index];
              return Padding(
                padding: const EdgeInsets.only(
                    bottom: AppDimensions.paddingMedium),
                child: BranchCard(
                  branch: branch,
                  onTap: () {
                    ref.read(selectedBranchProvider.notifier).state = branch;
                    // Reseta apenas serviço/slot/consultor — veículo já foi escolhido
                    ref.read(selectedServiceProvider.notifier).state = null;
                    ref.read(selectedDateProvider.notifier).state = null;
                    ref.read(selectedSlotProvider.notifier).state = null;
                    ref.read(selectedConsultantProvider.notifier).state = null;
                    ref.read(consultantHasConflictProvider.notifier).state =
                        false;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ServiceSelectionScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Erro: $error')),
      ),
    );
  }
}
