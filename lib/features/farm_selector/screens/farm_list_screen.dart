/// Farm List Screen
/// 
/// Screen untuk melihat dan memilih farm.
/// User bisa punya multiple farms dengan jenis hewan berbeda.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/farm.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/farm_provider.dart';
import 'create_farm_screen.dart';

class FarmListScreen extends ConsumerWidget {
  const FarmListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsAsync = ref.watch(farmNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Farm'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: farmsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading farms',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(farmNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (farms) {
          if (farms.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildFarmList(context, ref, farms);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateFarm(context),
        icon: const Icon(Icons.add),
        label: const Text('Farm Baru'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.agriculture,
                size: 64,
                color: Colors.green[300],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Selamat Datang di DSFarm!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Mulai kelola peternakan Anda dengan membuat farm pertama.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateFarm(context),
              icon: const Icon(Icons.add),
              label: const Text('Buat Farm Pertama'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmList(BuildContext context, WidgetRef ref, List<Farm> farms) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: farms.length,
      itemBuilder: (context, index) {
        final farm = farms[index];
        return _FarmCard(
          farm: farm,
          onTap: () => _selectFarm(context, ref, farm),
        );
      },
    );
  }

  void _navigateToCreateFarm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateFarmScreen(),
      ),
    );
  }

  void _selectFarm(BuildContext context, WidgetRef ref, Farm farm) {
    // Set current farm
    ref.read(currentFarmProvider.notifier).state = farm;
    
    // Navigate to dashboard
    context.goNamed('dashboard', pathParameters: {'farmId': farm.id});
  }
}

class _FarmCard extends StatelessWidget {
  final Farm farm;
  final VoidCallback onTap;

  const _FarmCard({
    required this.farm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Animal icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getAnimalColor().withOpacity(0.1),
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
              
              // Farm info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getAnimalColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            farm.animalTypeName,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getAnimalColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (farm.location != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              farm.location!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAnimalColor() {
    switch (farm.animalType) {
      case 'rabbit':
        return Colors.pink;
      case 'goat':
        return Colors.brown;
      case 'fish':
        return Colors.blue;
      case 'poultry':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}
