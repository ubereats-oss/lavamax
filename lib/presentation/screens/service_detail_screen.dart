import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavamax/core/constants/app_colors.dart';
import 'package:lavamax/core/constants/app_dimensions.dart';
import 'package:lavamax/core/utils/formatters.dart';
import 'package:lavamax/data/models/service_model.dart';
import 'package:lavamax/presentation/providers/service_provider.dart';
import 'package:lavamax/presentation/providers/branch_provider.dart';
import 'package:lavamax/presentation/providers/consultant_provider.dart';
import 'package:lavamax/presentation/providers/slot_provider.dart';
import 'package:lavamax/presentation/screens/vehicle_selection_screen.dart';
import 'package:lavamax/presentation/widgets/sprite_icon.dart';

class ServiceDetailScreen extends ConsumerWidget {
  final ServiceModel service;
  final bool isGuestMode;

  const ServiceDetailScreen({
    super.key,
    required this.service,
    this.isGuestMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fotos: usa imageUrls se disponível no futuro; por ora usa iconUrl como preview único
    final hasPhoto = service.iconUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: CustomScrollView(
        slivers: [
          // ── AppBar com imagem/ícone ──────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _ServiceHero(service: service, hasPhoto: hasPhoto),
            ),
          ),

          // ── Conteúdo ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome
                  Text(
                    service.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),

                  // Preço e duração
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.attach_money,
                        label: formatBrl(service.price),
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppDimensions.paddingSmall),
                      _InfoChip(
                        icon: Icons.timer_outlined,
                        label: _formatDuration(service.durationMinutes),
                        color: AppColors.accentDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.paddingLarge),

                  // Descrição
                  Text(
                    'Sobre o serviço',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    service.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey700,
                          height: 1.6,
                        ),
                  ),

                  const SizedBox(height: AppDimensions.paddingXLarge),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Botão fixo no rodapé ──────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingLarge,
            AppDimensions.paddingSmall,
            AppDimensions.paddingLarge,
            AppDimensions.paddingMedium,
          ),
          child: FilledButton.icon(
            onPressed: () => _agendar(context, ref),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Agendar este serviço'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
              backgroundColor: AppColors.accentDark,
              foregroundColor: AppColors.white,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _agendar(BuildContext context, WidgetRef ref) {
    if (isGuestMode || FirebaseAuth.instance.currentUser == null) {
      _showLoginRequired(context);
      return;
    }

    ref.read(selectedServiceProvider.notifier).state = service;
    ref.read(selectedBranchProvider.notifier).state = null;
    ref.read(selectedDateProvider.notifier).state = null;
    ref.read(selectedSlotProvider.notifier).state = null;
    ref.read(selectedConsultantProvider.notifier).state = null;
    ref.read(consultantHasConflictProvider.notifier).state = false;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const VehicleSelectionScreen(isFromBooking: true),
      ),
    );
  }

  void _showLoginRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login necessário'),
        content: const Text(
          'Para agendar um serviço, você precisa entrar na sua conta ou criar uma gratuitamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Entrar / Cadastrar'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}

// ── Hero: imagem grande ou ícone sprite centralizado ──────────
class _ServiceHero extends StatelessWidget {
  final ServiceModel service;
  final bool hasPhoto;

  const _ServiceHero({required this.service, required this.hasPhoto});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryLight,
            AppColors.primary,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48), // espaço abaixo da status bar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SpriteIcon(iconKey: service.iconUrl, size: 96),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip de info (preço / duração) ────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
