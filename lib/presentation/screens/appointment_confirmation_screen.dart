import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:lavamax/core/utils/formatters.dart';
import 'package:lavamax/core/constants/app_colors.dart';
import 'package:lavamax/core/constants/app_dimensions.dart';
import 'package:lavamax/core/constants/app_strings.dart';
import 'package:lavamax/data/models/appointment_model.dart';
import 'package:lavamax/data/models/credit_model.dart';
import 'package:lavamax/presentation/providers/appointment_provider.dart';
import 'package:lavamax/presentation/providers/branch_provider.dart';
import 'package:lavamax/presentation/providers/consultant_provider.dart';
import 'package:lavamax/presentation/providers/credit_provider.dart';
import 'package:lavamax/presentation/providers/service_provider.dart';
import 'package:lavamax/presentation/providers/slot_provider.dart';
import 'package:lavamax/presentation/providers/vehicle_provider.dart';
import 'package:lavamax/presentation/screens/booking_receipt_screen.dart';
import 'package:lavamax/presentation/widgets/custom_app_bar.dart';
class AppointmentConfirmationScreen extends ConsumerStatefulWidget {
  const AppointmentConfirmationScreen({super.key});
  @override
  ConsumerState<AppointmentConfirmationScreen> createState() =>
      _AppointmentConfirmationScreenState();
}
class _AppointmentConfirmationScreenState
    extends ConsumerState<AppointmentConfirmationScreen> {
  bool _isLoading = false;
  bool _consultantsLoading = true;
  CreditModel? _availableCredit;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadConsultantAndCredit(),
    );
  }
  Future<void> _loadConsultantAndCredit() async {
    try {
      final branch = ref.read(selectedBranchProvider);
      final slot = ref.read(selectedSlotProvider);
      if (branch == null || slot == null) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      // Carrega consultor e crédito em paralelo via providers
      final consultantRepo = ref.read(consultantRepositoryProvider);
      final creditRepo = ref.read(creditRepositoryProvider);
      final futures = await Future.wait([
        consultantRepo.getMostAvailable(branch.id, slot.startTime),
        if (uid != null)
          creditRepo.getActiveCredits(uid, branch.id)
        else
          Future.value(<CreditModel>[]),
      ]);
      if (!mounted) return;
      final best = futures[0] as dynamic;
      final credits = futures[1] as List<CreditModel>;
      ref.read(selectedConsultantProvider.notifier).state = best;
      if (best != null) {
        final conflict = await consultantRepo.hasConflictAtSlot(
          best.id,
          slot.startTime,
        );
        if (mounted) {
          ref.read(consultantHasConflictProvider.notifier).state = conflict;
        }
      }
      if (mounted) {
        setState(() {
          _availableCredit = credits.isNotEmpty ? credits.first : null;
        });
      }
    } finally {
      if (mounted) setState(() => _consultantsLoading = false);
    }
  }
  Future<void> _onConsultantChanged(
    String consultantId,
    List<dynamic> consultants,
  ) async {
    final slot = ref.read(selectedSlotProvider);
    if (slot == null) return;
    // Reutiliza a lista já carregada no provider — sem nova query ao Firestore
    final selected = consultants.firstWhere(
      (c) => c.id == consultantId,
      orElse: () => null,
    );
    if (selected == null) return;
    ref.read(selectedConsultantProvider.notifier).state = selected;
    final conflict = await ref
        .read(consultantRepositoryProvider)
        .hasConflictAtSlot(selected.id, slot.startTime);
    if (mounted) {
      ref.read(consultantHasConflictProvider.notifier).state = conflict;
    }
  }
  @override
  Widget build(BuildContext context) {
    final selectedBranch = ref.watch(selectedBranchProvider);
    final selectedService = ref.watch(selectedServiceProvider);
    final selectedSlot = ref.watch(selectedSlotProvider);
    final selectedVehicle = ref.watch(selectedVehicleProvider);
    final selectedConsultant = ref.watch(selectedConsultantProvider);
    final hasConflict = ref.watch(consultantHasConflictProvider);
    if (selectedBranch == null ||
        selectedService == null ||
        selectedSlot == null ||
        selectedVehicle == null) {
      return Scaffold(
        appBar: CustomAppBar(title: AppStrings.appointmentDetails),
        body: const Center(child: Text('Erro: Dados incompletos')),
      );
    }
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final consultantsAsync = ref.watch(
      branchConsultantsProvider(selectedBranch.id),
    );
    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.appointmentDetails,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimensions.paddingLarge),
              // Banner de crédito disponível
              if (_availableCredit != null && !_consultantsLoading)
                Container(
                  margin: const EdgeInsets.only(
                    bottom: AppDimensions.paddingMedium,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Voce tem 1 credito disponivel nesta filial. '
                          'Este agendamento sera realizado sem cobrança.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Resumo do agendamento (inclui veículo — sem card duplicado)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumo do Agendamento',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),
                      _row(context, 'Filial', selectedBranch.name),
                      _row(context, 'Servico', selectedService.name),
                      _row(
                        context,
                        'Data e Hora',
                        dateFormat.format(selectedSlot.startTime),
                      ),
                      _row(
                        context,
                        'Duracao',
                        '${selectedService.durationMinutes} minutos',
                      ),
                      _row(
                        context,
                        'Preco',
                        _availableCredit != null
                            ? 'Gratis (credito)'
                            : formatBrl(selectedService.price),
                      ),
                      const Divider(height: AppDimensions.paddingLarge),
                      _row(
                        context,
                        'Veiculo',
                        '${selectedVehicle.brand} ${selectedVehicle.model}',
                      ),
                      _row(context, 'Ano', '${selectedVehicle.year}'),
                      _row(
                        context,
                        'Placa',
                        formatPlate(selectedVehicle.plate),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              // Seletor de consultor (com telefone)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consultor',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      _consultantsLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : consultantsAsync.when(
                              loading: () => const CircularProgressIndicator(),
                              error: (e, _) =>
                                  Text('Erro ao carregar consultores: $e'),
                              data: (consultants) {
                                if (consultants.isEmpty) {
                                  return const Text(
                                    'Nenhum consultor disponivel nesta filial.',
                                    style: TextStyle(color: AppColors.grey600),
                                  );
                                }
                                return DropdownButtonFormField<String>(
                                  initialValue: selectedConsultant?.id,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.person_outline),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: consultants
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c.id,
                                          child: Text(c.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (id) {
                                    if (id != null) {
                                      _onConsultantChanged(id, consultants);
                                    }
                                  },
                                );
                              },
                            ),
                      if (selectedConsultant != null &&
                          selectedConsultant.phone.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.paddingSmall),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: AppColors.grey600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formatPhone(selectedConsultant.phone),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (hasConflict) ...[
                        const SizedBox(height: AppDimensions.paddingSmall),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning,
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warning,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Este consultor ja tem um atendimento neste horario. '
                                  'Isso pode causar atraso no seu atendimento.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingLarge),
              ElevatedButton(
                onPressed: _isLoading ? null : _confirm,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                      )
                    : const Text(AppStrings.confirmAppointment),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text(AppStrings.cancel),
              ),
              const SizedBox(height: AppDimensions.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }
  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.paddingSmall / 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    try {
      final selectedBranch = ref.read(selectedBranchProvider);
      final selectedService = ref.read(selectedServiceProvider);
      final selectedSlot = ref.read(selectedSlotProvider);
      final selectedVehicle = ref.read(selectedVehicleProvider);
      final selectedConsultant = ref.read(selectedConsultantProvider);
      final hasConflict = ref.read(consultantHasConflictProvider);
      if (selectedBranch == null ||
          selectedService == null ||
          selectedSlot == null ||
          selectedVehicle == null) {
        throw Exception('Dados incompletos');
      }
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario nao autenticado');
      }
      final appointment = AppointmentModel(
        id: const Uuid().v4(),
        customerId: currentUser.uid,
        branchId: selectedBranch.id,
        branchName: selectedBranch.name,
        serviceId: selectedService.id,
        serviceName: selectedService.name,
        slotId: selectedSlot.id,
        vehicleId: selectedVehicle.id,
        consultantId: selectedConsultant?.id ?? '',
        consultantName: selectedConsultant?.name ?? '',
        consultantPhone: selectedConsultant?.phone ?? '',
        consultantConflict: hasConflict,
        appointmentDate: selectedSlot.startTime,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      // Cria agendamento e — se houver crédito — consome-o atomicamente
      await ref
          .read(appointmentRepositoryProvider)
          .createAppointmentAndReserveSlot(
            appointment,
            useCreditId: _availableCredit?.id,
          );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => BookingReceiptScreen(
              appointment: appointment,
              branch: selectedBranch,
              service: selectedService,
              vehicle: selectedVehicle,
              usedCredit: _availableCredit != null,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
