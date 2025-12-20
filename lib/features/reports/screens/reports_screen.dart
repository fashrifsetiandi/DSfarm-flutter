/// Reports Screen
/// 
/// Screen untuk melihat laporan dan statistik farm.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/livestock_provider.dart';
import '../../../providers/breeding_provider.dart';
import '../../../providers/offspring_provider.dart';
import '../../../providers/finance_provider.dart';
import '../../../models/livestock.dart';
import '../../../models/offspring.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Populasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _PopulationCard(ref: ref),
            const SizedBox(height: 24),

            const Text(
              'Performa Breeding',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _BreedingPerformanceCard(ref: ref),
            const SizedBox(height: 24),

            const Text(
              'Penjualan Anakan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _SalesCard(ref: ref),
            const SizedBox(height: 24),

            const Text(
              'Keuangan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _FinanceCard(ref: ref),
          ],
        ),
      ),
    );
  }
}

class _PopulationCard extends StatelessWidget {
  final WidgetRef ref;

  const _PopulationCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    final livestockCountAsync = ref.watch(livestockCountProvider);
    final offspringCountAsync = ref.watch(offspringCountProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: livestockCountAsync.when(
                    loading: () => _StatItem(label: 'Induk Betina', value: '...'),
                    error: (_, __) => _StatItem(label: 'Induk Betina', value: '-'),
                    data: (counts) => _StatItem(
                      label: 'Induk Betina',
                      value: '${counts[Gender.female] ?? 0}',
                      icon: '♀️',
                      color: Colors.pink,
                    ),
                  ),
                ),
                Expanded(
                  child: livestockCountAsync.when(
                    loading: () => _StatItem(label: 'Pejantan', value: '...'),
                    error: (_, __) => _StatItem(label: 'Pejantan', value: '-'),
                    data: (counts) => _StatItem(
                      label: 'Pejantan',
                      value: '${counts[Gender.male] ?? 0}',
                      icon: '♂️',
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: offspringCountAsync.when(
                    loading: () => _StatItem(label: 'Di Farm', value: '...'),
                    error: (_, __) => _StatItem(label: 'Di Farm', value: '-'),
                    data: (counts) => _StatItem(
                      label: 'Anakan Di Farm',
                      value: '${counts[OffspringStatus.infarm] ?? 0}',
                      icon: '🐰',
                      color: Colors.orange,
                    ),
                  ),
                ),
                Expanded(
                  child: offspringCountAsync.when(
                    loading: () => _StatItem(label: 'Siap Jual', value: '...'),
                    error: (_, __) => _StatItem(label: 'Siap Jual', value: '-'),
                    data: (counts) => _StatItem(
                      label: 'Siap Jual',
                      value: '${counts[OffspringStatus.readySell] ?? 0}',
                      icon: '💰',
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BreedingPerformanceCard extends StatelessWidget {
  final WidgetRef ref;

  const _BreedingPerformanceCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    final breedingAsync = ref.watch(breedingNotifierProvider);

    return breedingAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e'))),
      data: (records) {
        final totalBreedings = records.length;
        final successful = records.where((r) => r.actualBirthDate != null).length;
        final totalBorn = records.fold(0, (sum, r) => sum + (r.aliveCount ?? 0));
        final totalWeaned = records.fold(0, (sum, r) => sum + (r.weanedCount ?? 0));

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _StatItem(
                      label: 'Total Breeding',
                      value: '$totalBreedings',
                      icon: '❤️',
                    )),
                    Expanded(child: _StatItem(
                      label: 'Berhasil Lahir',
                      value: '$successful',
                      icon: '🐣',
                      color: Colors.green,
                    )),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(child: _StatItem(
                      label: 'Total Lahir Hidup',
                      value: '$totalBorn',
                      icon: '🐰',
                    )),
                    Expanded(child: _StatItem(
                      label: 'Total Disapih',
                      value: '$totalWeaned',
                      icon: '🍼',
                    )),
                  ],
                ),
                if (totalBorn > 0) ...[
                  const Divider(),
                  _StatItem(
                    label: 'Tingkat Keberhasilan Sapih',
                    value: '${(totalWeaned / totalBorn * 100).toStringAsFixed(1)}%',
                    icon: '📊',
                    color: Colors.teal,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SalesCard extends StatelessWidget {
  final WidgetRef ref;

  const _SalesCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    final offspringAsync = ref.watch(offspringNotifierProvider);

    return offspringAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e'))),
      data: (offsprings) {
        final sold = offsprings.where((o) => o.status == OffspringStatus.sold).toList();
        final totalSold = sold.length;
        final totalRevenue = sold.fold(0.0, (sum, o) => sum + (o.salePrice ?? 0));
        final avgPrice = totalSold > 0 ? totalRevenue / totalSold : 0.0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _StatItem(
                      label: 'Total Terjual',
                      value: '$totalSold ekor',
                      icon: '📦',
                    )),
                    Expanded(child: _StatItem(
                      label: 'Total Pendapatan',
                      value: _formatCurrency(totalRevenue),
                      icon: '💵',
                      color: Colors.green,
                    )),
                  ],
                ),
                if (totalSold > 0) ...[
                  const Divider(),
                  _StatItem(
                    label: 'Rata-rata Harga',
                    value: _formatCurrency(avgPrice),
                    icon: '📈',
                    color: Colors.blue,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }
}

class _FinanceCard extends StatelessWidget {
  final WidgetRef ref;

  const _FinanceCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(financeSummaryProvider);

    return summaryAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e'))),
      data: (summary) {
        final income = summary['income'] ?? 0;
        final expense = summary['expense'] ?? 0;
        final balance = summary['balance'] ?? 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _StatItem(
                      label: 'Pemasukan',
                      value: _formatCurrency(income),
                      icon: '📈',
                      color: Colors.green,
                    )),
                    Expanded(child: _StatItem(
                      label: 'Pengeluaran',
                      value: _formatCurrency(expense),
                      icon: '📉',
                      color: Colors.red,
                    )),
                  ],
                ),
                const Divider(),
                _StatItem(
                  label: 'Saldo',
                  value: _formatCurrency(balance),
                  icon: balance >= 0 ? '✅' : '⚠️',
                  color: balance >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    final formatted = amount.abs().toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String? icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          if (icon != null)
            Text(icon!, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
