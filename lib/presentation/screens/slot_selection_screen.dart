import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lavamax/core/constants/app_dimensions.dart';
import 'package:lavamax/core/constants/app_strings.dart';
import 'package:lavamax/presentation/providers/branch_provider.dart';
import 'package:lavamax/presentation/providers/slot_provider.dart';
import 'package:lavamax/presentation/screens/appointment_confirmation_screen.dart';
import 'package:lavamax/presentation/widgets/custom_app_bar.dart';
import 'package:lavamax/presentation/widgets/slot_card.dart';
class SlotSelectionScreen extends ConsumerStatefulWidget {
  const SlotSelectionScreen({super.key});
  @override
  ConsumerState<SlotSelectionScreen> createState() =>
      _SlotSelectionScreenState();
}
class _SlotSelectionScreenState extends ConsumerState<SlotSelectionScreen> {
  late DateTime _selectedDate;
  final _nextButtonKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }
  @override
  Widget build(BuildContext context) {
    final selectedBranch = ref.watch(selectedBranchProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final dateToUse = selectedDate ?? _selectedDate;
    // ref.watch do slot selecionado fica AQUI, fora do itemBuilder,
    // para evitar rebuild desnecessário de toda a grid a cada seleção.
    final selectedSlot = ref.watch(selectedSlotProvider);
    if (selectedBranch == null) {
      return Scaffold(
        appBar: CustomAppBar(title: AppStrings.selectDateTime),
        body: const Center(child: Text('Erro: Filial não selecionada')),
      );
    }
    final slotsAsync = ref.watch(
      availableSlotsProvider((selectedBranch.id, dateToUse)),
    );
    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.selectDateTime,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimensions.paddingMedium),
              Text(
                'Selecione a Data',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              ElevatedButton.icon(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: dateToUse,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 60)),
                  );
                  if (pickedDate != null) {
                    ref.read(selectedDateProvider.notifier).state =
                        pickedDate;
                    // Limpa o slot selecionado ao trocar de data
                    ref.read(selectedSlotProvider.notifier).state = null;
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat('dd/MM/yyyy').format(dateToUse)),
              ),
              const SizedBox(height: AppDimensions.paddingLarge),
              Text(
                AppStrings.availableSlots,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              slotsAsync.when(
                data: (slots) {
                  if (slots.isEmpty) {
                    return Center(
                      child: Text(AppStrings.noSlotsAvailable),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: AppDimensions.paddingSmall,
                      mainAxisSpacing: AppDimensions.paddingSmall,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slot = slots[index];
                      // selectedSlot já foi obtido acima — sem watch aqui
                      final isSelected = selectedSlot?.id == slot.id;
                      return SlotCard(
                        slot: slot,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(selectedSlotProvider.notifier)
                              .state = slot;
                          // Rola até o botão "Próximo" após selecionar
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final ctx = _nextButtonKey.currentContext;
                            if (ctx != null) {
                              Scrollable.ensureVisible(
                                ctx,
                                duration:
                                    const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                alignment: 1.0,
                              );
                            }
                          });
                        },
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text('Erro: $error')),
              ),
              const SizedBox(height: AppDimensions.paddingLarge),
              ElevatedButton(
                key: _nextButtonKey,
                onPressed: () {
                  if (selectedSlot != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const AppointmentConfirmationScreen(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Selecione um horário')),
                    );
                  }
                },
                child: const Text(AppStrings.next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
