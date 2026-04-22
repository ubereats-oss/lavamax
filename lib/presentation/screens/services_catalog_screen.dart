import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavamax/core/constants/app_colors.dart';
import 'package:lavamax/core/constants/app_dimensions.dart';
import 'package:lavamax/data/models/service_model.dart';
import 'package:lavamax/presentation/providers/service_provider.dart';
import 'package:lavamax/presentation/screens/service_detail_screen.dart';
import 'package:lavamax/presentation/widgets/sprite_icon.dart';

class ServicesCatalogScreen extends ConsumerWidget {
  const ServicesCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Image.asset(
          'assets/images/lavamax_logo.png',
          height: 36,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Erro ao carregar serviços: $e',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(servicesProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (services) {
          if (services.isEmpty) {
            return const Center(child: Text('Nenhum serviço disponível.'));
          }
          final sorted = [...services]
            ..sort((a, b) {
              final byOrder = a.sortOrder.compareTo(b.sortOrder);
              if (byOrder != 0) return byOrder;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });
          return GridView.builder(
            padding:
                const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppDimensions.paddingMedium,
              mainAxisSpacing: AppDimensions.paddingMedium,
              childAspectRatio: 1.4,
            ),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              return _ServiceCard(service: sorted[index]);
            },
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: BorderSide(
          color: AppColors.accent.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServiceDetailScreen(service: service),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpriteIcon(iconKey: service.iconUrl, size: 40),
              const SizedBox(height: 6),
              Text(
                service.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.3,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
