import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavamax/core/constants/app_dimensions.dart';
import 'package:lavamax/core/constants/app_strings.dart';
import 'package:lavamax/presentation/providers/service_provider.dart';
import 'package:lavamax/presentation/screens/slot_selection_screen.dart';
import 'package:lavamax/presentation/widgets/custom_app_bar.dart';
import 'package:lavamax/presentation/widgets/service_card.dart';
class ServiceSelectionScreen extends ConsumerWidget {
  const ServiceSelectionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);
    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.selectService,
        showBackButton: true,
      ),
      body: servicesAsync.when(
        data: (services) {
          if (services.isEmpty) {
            return Center(child: Text(AppStrings.noServicesAvailable));
          }
          // Ordena por sort_order; empate desempata por nome
          final sorted = [...services]
            ..sort((a, b) {
              final byOrder = a.sortOrder.compareTo(b.sortOrder);
              if (byOrder != 0) return byOrder;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });
          return ListView.builder(
            padding:
                const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final service = sorted[index];
              return Padding(
                padding: const EdgeInsets.only(
                    bottom: AppDimensions.paddingMedium),
                child: ServiceCard(
                  service: service,
                  onTap: () {
                    ref.read(selectedServiceProvider.notifier).state =
                        service;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SlotSelectionScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Erro: $error')),
      ),
    );
  }
}
