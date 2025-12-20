/// Dashboard Screen
/// 
/// Main dashboard untuk farm yang dipilih.
/// Menampilkan summary stats dan navigation ke features.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/farm_provider.dart';
import '../../../providers/housing_provider.dart';
import '../../../providers/livestock_provider.dart';
import '../../../models/livestock.dart';
import '../../housing/screens/housing_list_screen.dart';
import '../../livestock/screens/livestock_list_screen.dart';
import '../../offspring/screens/offspring_list_screen.dart';
import '../../breeding/screens/breeding_list_screen.dart';
import '../../finance/screens/finance_screen.dart';
import '../../inventory/screens/inventory_screen.dart';
import '../../health/screens/health_screen.dart';
import '../../reminder/screens/reminder_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../settings/screens/settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final String farmId;
  
  const DashboardScreen({
    super.key,
    required this.farmId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farm = ref.watch(currentFarmProvider);
    final housingsAsync = ref.watch(housingsProvider);
    final livestockCountAsync = ref.watch(livestockCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(farm?.name ?? 'Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/farms'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(housingsProvider);
          ref.invalidate(livestockCountProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Farm Info Card
              _buildFarmInfoCard(context, farm),
              const SizedBox(height: 24),

              // Stats Section
              const Text(
                'Ringkasan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatsRow(housingsAsync, livestockCountAsync),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmInfoCard(BuildContext context, dynamic farm) {
    if (farm == null) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  farm.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    farm.animalTypeName,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (farm.location != null)
                    Text(
                      '📍 ${farm.location}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    AsyncValue<dynamic> housingsAsync,
    AsyncValue<Map<Gender, int>> livestockCountAsync,
  ) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.home_work,
            label: 'Kandang',
            value: housingsAsync.when(
              loading: () => '...',
              error: (_, __) => '-',
              data: (housings) => '${housings.length}',
            ),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.female,
            label: 'Induk',
            value: livestockCountAsync.when(
              loading: () => '...',
              error: (_, __) => '-',
              data: (counts) => '${counts[Gender.female] ?? 0}',
            ),
            color: Colors.pink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.male,
            label: 'Pejantan',
            value: livestockCountAsync.when(
              loading: () => '...',
              error: (_, __) => '-',
              data: (counts) => '${counts[Gender.male] ?? 0}',
            ),
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menuItems = [
      _MenuItem(
        icon: Icons.home_work,
        label: 'Kandang',
        color: Colors.blue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HousingListScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.pets,
        label: 'Indukan',
        color: Colors.pink,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LivestockListScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.child_care,
        label: 'Anakan',
        color: Colors.orange,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OffspringListScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.favorite,
        label: 'Breeding',
        color: Colors.red,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BreedingListScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.account_balance_wallet,
        label: 'Keuangan',
        color: Colors.green,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FinanceScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.inventory,
        label: 'Inventaris',
        color: Colors.brown,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InventoryScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.medical_services,
        label: 'Kesehatan',
        color: Colors.teal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HealthScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.notifications,
        label: 'Pengingat',
        color: Colors.amber,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReminderScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.bar_chart,
        label: 'Laporan',
        color: Colors.indigo,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _buildMenuItem(context, item);
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: item.color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item.color.withAlpha(50)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: item.color, size: 28),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: item.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
