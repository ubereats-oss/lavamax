import 'package:flutter/material.dart';
import 'admin_brands_screen.dart';
import 'admin_services_screen.dart';
import 'admin_branches_screen.dart';
import 'admin_users_screen.dart';
import 'admin_consultants_screen.dart';
import 'admin_appointments_screen.dart';
import 'admin_credits_screen.dart';
class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final items = [
      _PanelItem(
        icon: Icons.directions_car_outlined,
        label: 'Marcas e Modelos',
        screen: const AdminBrandsScreen(),
      ),
      _PanelItem(
        icon: Icons.local_car_wash_outlined,
        label: 'Serviços',
        screen: const AdminServicesScreen(),
      ),
      _PanelItem(
        icon: Icons.store_outlined,
        label: 'Filiais',
        screen: const AdminBranchesScreen(),
      ),
      _PanelItem(
        icon: Icons.person_outline,
        label: 'Consultores',
        screen: const AdminConsultantsScreen(),
      ),
      _PanelItem(
        icon: Icons.people_outline,
        label: 'Usuários',
        screen: const AdminUsersScreen(),
      ),
      _PanelItem(
        icon: Icons.calendar_month_outlined,
        label: 'Agendamentos',
        screen: const AdminAppointmentsScreen(),
      ),
      _PanelItem(
        icon: Icons.card_giftcard_outlined,
        label: 'Créditos',
        screen: const AdminCreditsScreen(),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Painel Admin')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: items
            .map(
              (item) => Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item.screen),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
class _PanelItem {
  final IconData icon;
  final String label;
  final Widget screen;
  const _PanelItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
}
