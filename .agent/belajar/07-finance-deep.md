# 07 - Finance Deep: Auto-Income & Charts

> **Topik:** Integrasi fitur penjualan dengan finance dan visualisasi data  
> **Tanggal:** 2025-12-21

---

## 🎯 Tujuan

Mempelajari cara:
1. Auto-create transaction saat event terjadi
2. Aggregasi data untuk chart
3. Menggunakan fl_chart untuk visualisasi

---

## 📘 Konsep Utama

### 1. Auto-Income Pattern

```dart
// Di offspring_provider.dart
Future<void> sellOffspring({
  required String offspringId,
  required double salePrice,
}) async {
  // 1. Update offspring status
  await _repository.updateStatus(offspringId, OffspringStatus.sold);
  
  // 2. Get/create category
  final category = await _financeRepository.getOrCreateSaleCategory(farmId);
  
  // 3. Create income transaction
  await _financeRepository.createTransaction(
    farmId: farmId,
    type: TransactionType.income,
    categoryId: category.id,
    amount: salePrice,
    referenceId: offspringId,
    referenceType: 'offspring',
  );
}
```

### 2. Monthly Aggregation

```dart
class MonthlyTrendData {
  final String month;
  final double income;
  final double expense;
  
  double get balance => income - expense;
}

final monthlyTrendProvider = FutureProvider<List<MonthlyTrendData>>((ref) async {
  // Loop 6 bulan terakhir
  for (int i = 5; i >= 0; i--) {
    final monthStart = DateTime(now.year, now.month - i, 1);
    final summary = await repository.getSummary(farmId, startDate: monthStart);
    // Aggregate...
  }
});
```

### 3. fl_chart Bar Chart

```dart
BarChart(
  BarChartData(
    barGroups: data.map((d) => BarChartGroupData(
      barRods: [
        BarChartRodData(toY: d.income, color: Colors.green),
        BarChartRodData(toY: d.expense, color: Colors.red),
      ],
    )).toList(),
  ),
)
```

---

## 🔧 Yang Dibuat

| File | Fungsi |
|------|--------|
| `sell_offspring_dialog.dart` | Dialog jual dengan input harga |
| `finance_dashboard_screen.dart` | Dashboard dengan chart |
| `finance_provider.dart` | MonthlyTrendData provider |

---

## ✅ Checklist Belajar

- [ ] Pahami pattern auto-create linked data
- [ ] Coba modifikasi chart (line chart, pie chart)
- [ ] Tambah filter periode di dashboard
