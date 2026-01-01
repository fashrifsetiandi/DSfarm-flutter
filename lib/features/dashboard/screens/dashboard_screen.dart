/// Dashboard Screen
/// 
/// Main dashboard matching reference design with:
/// - 4 Summary Cards (Total Asset, Livestock, Offspring, Health Index)
/// - Financial Performance Chart + Quick Actions + Recent Activity
/// - Breeding Efficiency + Population Distribution

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/dashboard_shell.dart';
import '../../../providers/farm_provider.dart';
import '../../../providers/livestock_provider.dart';
import '../../../providers/offspring_provider.dart';
import '../../../providers/breeding_provider.dart';
import '../../../providers/finance_provider.dart';
import '../../../models/livestock.dart';
import '../../../models/offspring.dart' hide Gender;

class DashboardScreen extends ConsumerWidget {
  final String farmId;
  
  const DashboardScreen({
    super.key,
    required this.farmId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farm = ref.watch(currentFarmProvider);

    if (farm == null) {
      final farmAsync = ref.watch(farmByIdProvider(farmId));
      return farmAsync.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Error loading farm: $e'))),
        data: (loadedFarm) {
          if (loadedFarm != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(currentFarmProvider.notifier).state = loadedFarm;
            });
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      );
    }

    return DashboardShell(
      selectedIndex: 0,
      child: _DashboardContent(farm: farm),
    );
  }
}

class _DashboardContent extends ConsumerStatefulWidget {
  final dynamic farm;

  const _DashboardContent({required this.farm});

  @override
  ConsumerState<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<_DashboardContent> {
  String _chartPeriod = '6M'; // 1M, 3M, 6M

  @override
  Widget build(BuildContext context) {
    final livestockAsync = ref.watch(livestockNotifierProvider);
    final offspringAsync = ref.watch(offspringNotifierProvider);
    final breedingAsync = ref.watch(breedingNotifierProvider);
    final financeAsync = ref.watch(financeNotifierProvider);
    final trendAsync = ref.watch(monthlyTrendProvider);
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(livestockNotifierProvider);
        ref.invalidate(offspringNotifierProvider);
        ref.invalidate(breedingNotifierProvider);
        ref.invalidate(financeNotifierProvider);
        ref.invalidate(monthlyTrendProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════
            // 4 SUMMARY CARDS
            // ═══════════════════════════════════════════
            _buildSummaryCards(context, livestockAsync, offspringAsync, financeAsync),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════
            // MIDDLE SECTION: Chart + Quick Actions + Activity
            // ═══════════════════════════════════════════
            isLargeScreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Financial Chart (larger, left)
                      Expanded(
                        flex: 2,
                        child: _buildFinancialChart(context, trendAsync, financeAsync),
                      ),
                      const SizedBox(width: 16),
                      // Quick Actions + Recent Activity (right)
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildQuickActions(context),
                            const SizedBox(height: 16),
                            _buildRecentActivity(context, financeAsync),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildFinancialChart(context, trendAsync, financeAsync),
                      const SizedBox(height: 16),
                      _buildQuickActions(context),
                      const SizedBox(height: 16),
                      _buildRecentActivity(context, financeAsync),
                    ],
                  ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════
            // BOTTOM SECTION: Breeding Efficiency + Population
            // ═══════════════════════════════════════════
            isLargeScreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildBreedingEfficiency(context, breedingAsync)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPopulationDistribution(context, livestockAsync, offspringAsync)),
                    ],
                  )
                : Column(
                    children: [
                      _buildBreedingEfficiency(context, breedingAsync),
                      const SizedBox(height: 16),
                      _buildPopulationDistribution(context, livestockAsync, offspringAsync),
                    ],
                  ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4 SUMMARY CARDS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSummaryCards(BuildContext context, AsyncValue livestockAsync, AsyncValue offspringAsync, AsyncValue financeAsync) {
    double totalAsset = 0;
    int livestockCount = 0;
    int offspringCount = 0;
    
    financeAsync.whenData((transactions) {
      for (final tx in transactions) {
        totalAsset += tx.isIncome ? tx.amount : -tx.amount;
      }
    });
    
    livestockAsync.whenData((list) => livestockCount = list.length);
    offspringAsync.whenData((list) => offspringCount = list.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        
        if (isWide) {
          return Row(
            children: [
              Expanded(child: _SummaryCard(
                icon: Icons.attach_money_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: 'Total Asset Value',
                value: _formatCurrency(totalAsset),
                trend: 8.5,
                trendLabel: '',
              )),
              const SizedBox(width: 16),
              Expanded(child: _SummaryCard(
                icon: Icons.pets_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Livestock Count',
                value: '$livestockCount',
                valueLabel: ' Indukan',
                trend: 2.1,
                trendLabel: '',
              )),
              const SizedBox(width: 16),
              Expanded(child: _SummaryCard(
                icon: Icons.child_care_rounded,
                iconColor: const Color(0xFFEC4899),
                title: 'Offspring Count',
                value: '$offspringCount',
                valueLabel: ' Anakan',
                trend: -0.5,
                trendLabel: '',
              )),
              const SizedBox(width: 16),
              Expanded(child: _SummaryCard(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Health Index',
                value: '96',
                valueLabel: '/100',
                trendLabel: 'Stable',
                isStable: true,
              )),
            ],
          );
        }
        
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _SummaryCard(
                  icon: Icons.attach_money_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Total Asset',
                  value: _formatCurrency(totalAsset),
                  trend: 8.5,
                )),
                const SizedBox(width: 12),
                Expanded(child: _SummaryCard(
                  icon: Icons.pets_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Livestock',
                  value: '$livestockCount',
                  valueLabel: ' Indukan',
                  trend: 2.1,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _SummaryCard(
                  icon: Icons.child_care_rounded,
                  iconColor: const Color(0xFFEC4899),
                  title: 'Offspring',
                  value: '$offspringCount',
                  valueLabel: ' Anakan',
                  trend: -0.5,
                )),
                const SizedBox(width: 12),
                Expanded(child: _SummaryCard(
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Health Index',
                  value: '96',
                  valueLabel: '/100',
                  trendLabel: 'Stable',
                  isStable: true,
                )),
              ],
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FINANCIAL PERFORMANCE CHART
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFinancialChart(BuildContext context, AsyncValue trendAsync, AsyncValue financeAsync) {
    final colorScheme = Theme.of(context).colorScheme;
    
    double totalRevenue = 0;
    financeAsync.whenData((transactions) {
      for (final tx in transactions) {
        if (tx.isIncome) totalRevenue += tx.amount;
      }
    });

    // Get period label
    String periodLabel;
    switch (_chartPeriod) {
      case '1M': periodLabel = '1-Month';
      case '3M': periodLabel = '3-Month';
      case '6M': periodLabel = '6-Month';
      default: periodLabel = '12-Month';
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Financial Performance & Yield', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('$periodLabel Revenue vs. Operational Costs', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                // Period Toggle Buttons
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: ['1M', '3M', '6M'].map((p) => _periodChip(p)).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Revenue summary
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(_formatCurrency(totalRevenue), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(width: 8),
                const Icon(Icons.trending_up, size: 12, color: Color(0xFF10B981)),
                const SizedBox(width: 2),
                const Text('+12% YoY', style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: trendAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (data) {
                  if (data.isEmpty) {
                    return Center(child: Text('Belum ada data', style: TextStyle(color: colorScheme.onSurfaceVariant)));
                  }
                  // Filter data based on period
                  final filteredData = _filterChartData(data);
                  return _buildAreaChart(context, filteredData);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(String label) {
    final active = _chartPeriod == label;
    return GestureDetector(
      onTap: () => setState(() => _chartPeriod = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  List _filterChartData(List data) {
    switch (_chartPeriod) {
      case '1M': return data.length > 1 ? data.sublist(data.length - 1) : data;
      case '3M': return data.length > 3 ? data.sublist(data.length - 3) : data;
      case '6M': return data.length > 6 ? data.sublist(data.length - 6) : data;
      default: return data;
    }
  }

  Widget _buildAreaChart(BuildContext context, List data) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxVal = data.fold<double>(0, (m, d) => [m, d.income, d.expense].reduce((a, b) => a > b ? a : b));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal > 0 ? maxVal / 4 : 1000000,
          getDrawingHorizontalLine: (v) => FlLine(
            color: colorScheme.outlineVariant.withAlpha(50),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                return Text(
                  data[idx].month,
                  style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxVal * 1.3,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final idx = spot.barIndex;
              final label = idx == 0 ? 'revenue' : 'cost';
              return LineTooltipItem(
                '$label: ${_formatCurrency(spot.y)}',
                TextStyle(color: idx == 0 ? const Color(0xFF10B981) : colorScheme.onSurfaceVariant, fontSize: 11),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          // Revenue line (green with area fill)
          LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.income)).toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF10B981),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                if (index == data.length - 1) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: const Color(0xFF10B981),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                }
                return FlDotCirclePainter(radius: 0, color: Colors.transparent);
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF10B981).withAlpha(60),
                  const Color(0xFF10B981).withAlpha(5),
                ],
              ),
            ),
          ),
          // Cost line (gray, thin)
          LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.expense)).toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: colorScheme.outlineVariant,
            barWidth: 1.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildQuickActions(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('QUICK ACTIONS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _QuickActionButton(
                  icon: Icons.pets_rounded,
                  label: 'Tambah Livestock',
                  color: const Color(0xFF10B981),
                  onTap: () => context.go('/dashboard/${widget.farm.id}/livestock'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _QuickActionButton(
                  icon: Icons.favorite_rounded,
                  label: 'Breeding',
                  color: const Color(0xFFEC4899),
                  onTap: () {},
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _QuickActionButton(
                  icon: Icons.attach_money_rounded,
                  label: 'Tambah Keuangan',
                  color: const Color(0xFFF59E0B),
                  onTap: () => context.go('/dashboard/${widget.farm.id}/finance'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _QuickActionButton(
                  icon: Icons.medical_services_rounded,
                  label: 'Kesehatan',
                  color: const Color(0xFFEF4444),
                  onTap: () => context.go('/dashboard/${widget.farm.id}/health'),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECENT ACTIVITY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRecentActivity(BuildContext context, AsyncValue financeAsync) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RECENT ACTIVITY', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5)),
            const SizedBox(height: 16),
            financeAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('Belum ada aktivitas', style: TextStyle(color: colorScheme.onSurfaceVariant))),
                  );
                }
                
                final recent = transactions.take(3).toList();
                return Column(
                  children: [
                    ...recent.map((tx) => _ActivityItem(
                      icon: tx.isIncome ? Icons.attach_money_rounded : Icons.shopping_cart_rounded,
                      iconColor: tx.isIncome ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      title: tx.categoryName ?? 'Transaksi',
                      subtitle: tx.description ?? '${tx.isIncome ? "Received" : "Spent"} ${_formatCurrency(tx.amount)}',
                      time: _formatTimeAgo(tx.transactionDate),
                    )),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/dashboard/${widget.farm.id}/finance'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('View All Transactions', style: TextStyle(fontSize: 12, color: colorScheme.primary)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14, color: colorScheme.primary),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BREEDING EFFICIENCY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBreedingEfficiency(BuildContext context, AsyncValue breedingAsync) {
    final colorScheme = Theme.of(context).colorScheme;
    
    int totalBreedings = 0;
    int successfulBreedings = 0;
    double avgLitterSize = 6.5; // Default
    
    breedingAsync.whenData((list) {
      totalBreedings = list.length;
      successfulBreedings = list.where((b) => b.status == 'completed' || b.status == 'pregnant' || b.litterSize != null).length;
      final withLitter = list.where((b) => b.litterSize != null && b.litterSize > 0);
      if (withLitter.isNotEmpty) {
        avgLitterSize = withLitter.fold<double>(0, (s, b) => s + b.litterSize!) / withLitter.length;
      }
    });
    
    final conceptionRate = totalBreedings > 0 ? (successfulBreedings / totalBreedings * 100).round() : 0;
    final successRate = totalBreedings > 0 ? (successfulBreedings / totalBreedings * 100).round() : 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('BREEDING EFFICIENCY', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5)),
                Icon(Icons.info_outline, size: 18, color: colorScheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Circular Progress
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: successRate / 100,
                          strokeWidth: 10,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$successRate%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                          Text('SUCCESS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Stats
                Expanded(
                  child: Column(
                    children: [
                      _BreedingStat(label: 'Conception Rate', value: '$conceptionRate%', progress: conceptionRate / 100, color: const Color(0xFF3B82F6)),
                      const SizedBox(height: 16),
                      _BreedingStat(label: 'Avg. Litter Size', value: avgLitterSize.toStringAsFixed(1), progress: avgLitterSize / 10, color: const Color(0xFF10B981)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // POPULATION DISTRIBUTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPopulationDistribution(BuildContext context, AsyncValue livestockAsync, AsyncValue offspringAsync) {
    int females = 0;
    int males = 0;
    int pregnant = 0;
    int offspring = 0;
    
    livestockAsync.whenData((list) {
      females = list.where((l) => l.gender == Gender.female).length;
      males = list.where((l) => l.gender == Gender.male).length;
      pregnant = list.where((l) => l.status == 'bunting').length;
    });
    
    offspringAsync.whenData((list) => offspring = list.length);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('POPULATION DISTRIBUTION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _PopulationCard(label: 'Betina', value: females, color: const Color(0xFFEC4899))),
                const SizedBox(width: 12),
                Expanded(child: _PopulationCard(label: 'Jantan', value: males, color: const Color(0xFF3B82F6))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _PopulationCard(label: 'Bunting', value: pregnant, color: const Color(0xFF8B5CF6))),
                const SizedBox(width: 12),
                Expanded(child: _PopulationCard(label: 'Anakan', value: offspring, color: const Color(0xFFF59E0B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  String _formatCurrency(double v) {
    if (v.abs() >= 1000000000) return 'Rp ${(v / 1000000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt';
    if (v.abs() >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${v.toStringAsFixed(0)}';
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String? valueLabel;
  final double? trend;
  final String? trendLabel;
  final bool isStable;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.valueLabel,
    this.trend,
    this.trendLabel,
    this.isStable = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPositive = (trend ?? 0) >= 0;
    final trendColor = isStable ? colorScheme.onSurfaceVariant : (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444));

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trend != null || trendLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trendColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trendLabel ?? '${isPositive ? '+' : ''}${trend!.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: trendColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                        if (valueLabel != null)
                          TextSpan(text: valueLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(time, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _BreedingStat extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _BreedingStat({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _PopulationCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _PopulationCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
