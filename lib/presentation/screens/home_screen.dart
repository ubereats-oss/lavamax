import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavamax/data/services/firebase_service.dart';
import 'package:lavamax/core/constants/app_colors.dart';
import 'package:lavamax/presentation/providers/connectivity_provider.dart';
import '../providers/user_provider.dart';
import 'admin/admin_panel_screen.dart';
import 'my_appointments_screen.dart';
import 'profile_screen.dart';
import 'services_catalog_screen.dart';
import 'vehicle_selection_screen.dart';
/// Provider Riverpod para créditos ativos do usuário atual.
/// Evita o FutureBuilder inline que disparava nova query a cada rebuild.
final _activeCreditsProvider = FutureProvider.autoDispose<int>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return 0;
  final snap = await FirebaseService().firestore
      .collection('credits')
      .where('customer_id', isEqualTo: uid)
      .where('status', isEqualTo: 'active')
      .get();
  return snap.docs.length;
});
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  void _showOfflineSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sem conexão com a internet. '
                'Esta função requer acesso à rede.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[850],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userRoleProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final isMaster = userAsync.when(
      data: (u) => u?.isMaster ?? false,
      loading: () => false,
      error: (e, _) => false,
    );
    final userName = userAsync.when(
      data: (u) => u?.name ?? '',
      loading: () => '',
      error: (e, _) => '',
    );
    final creditsAsync = ref.watch(_activeCreditsProvider);
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (isMaster)
            IconButton(
              tooltip: 'Painel Admin',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () {
                if (!isOnline) {
                  _showOfflineSnack(context);
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                );
              },
            ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Image.asset('assets/images/lavamax_logo.png', height: 100),
              const SizedBox(height: 6),
              if (userName.isNotEmpty)
                Text(
                  'Olá, $userName!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              const SizedBox(height: 4),
              // Banner offline
              if (!isOnline)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sem internet. Apenas "Meus Agendamentos" '
                          'está disponível no momento.',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              // Banner de créditos ativos
              if (!isMaster && isOnline)
                creditsAsync.when(
                  data: (count) {
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.green.shade400, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              count == 1
                                  ? 'Voce tem 1 credito disponivel para reagendamento.'
                                  : 'Voce tem $count creditos disponiveis para reagendamento.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              const SizedBox(height: 4),
              // ── Botão destaque "Serviços" ─────────────────────
              Opacity(
                opacity: isOnline ? 1.0 : 0.4,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (!isOnline) {
                        _showOfflineSnack(context);
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServicesCatalogScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_car_wash_outlined,
                            size: 44,
                            color: AppColors.accentDark,
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Serviços',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ── Grid de ações secundárias ─────────────────────
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                  children: [
                    _MenuCard(
                      icon: Icons.calendar_month_outlined,
                      label: 'Realizar\nAgendamento',
                      enabled: isOnline,
                      onTap: () {
                        if (!isOnline) {
                          _showOfflineSnack(context);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VehicleSelectionScreen(
                              isFromBooking: true,
                            ),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.list_alt_outlined,
                      label: 'Meus\nAgendamentos',
                      enabled: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyAppointmentsScreen(),
                        ),
                      ),
                    ),
                    _MenuCard(
                      icon: Icons.directions_car_outlined,
                      label: 'Meus\nCarros',
                      enabled: isOnline,
                      onTap: () {
                        if (!isOnline) {
                          _showOfflineSnack(context);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VehicleSelectionScreen(
                              isFromBooking: false,
                            ),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.person_outline,
                      label: 'Meu\nPerfil',
                      enabled: isOnline,
                      onTap: () {
                        if (!isOnline) {
                          _showOfflineSnack(context);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                    if (isMaster)
                      _MenuCard(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Administração',
                        enabled: isOnline,
                        onTap: () {
                          if (!isOnline) {
                            _showOfflineSnack(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminPanelScreen(),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  const _MenuCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.enabled,
  });
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: AppColors.accentDark),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
