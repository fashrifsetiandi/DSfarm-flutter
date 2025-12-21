# DSFarm Documentation

> Dokumentasi pengembangan & pembelajaran Flutter

## Quick Links

| Fase | Topik | Status |
|------|-------|--------|
| [01](#fase-1-foundation) | Auth, Multi-Farm | ✅ |
| [02](#fase-2-core) | Kandang, Livestock, Breeding | ✅ |
| [03](#fase-3-finance) | Finance, Inventory | ✅ |
| [04](#fase-4-advanced) | Block, Level, Charts | ✅ |

---

## Fase 1: Foundation

### Yang Dibuat
- Login/Register dengan Supabase Auth
- Multi-farm architecture
- GoRouter navigation
- Riverpod state management

### Key Learning
```dart
// Riverpod StateNotifier pattern
class FarmNotifier extends StateNotifier<AsyncValue<List<Farm>>> {
  Future<void> loadFarms() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await repository.getAll());
  }
}
```

---

## Fase 2: Core Features

### Yang Dibuat
- Housing CRUD dengan type & status
- Livestock dengan auto-code: `[BREED]-[J/B][SEQ]`
- BreedingRecord: Mating → Palpation → Birth → Weaning
- Offspring dengan status progression

### Key Learning
```dart
// Auto-generate code pattern
String generateCode(String breed, Gender gender, int seq) {
  final prefix = gender == Gender.male ? 'J' : 'B';
  return '$breed-$prefix${seq.toString().padLeft(2, '0')}';
}
```

---

## Fase 3: Finance & Inventory

### Yang Dibuat
- Finance transactions (income/expense)
- Finance categories dengan CRUD
- Inventory items & stock

### Key Learning
```dart
// Aggregasi data
Future<Map<String, double>> getSummary(String farmId) async {
  final transactions = await getTransactions(farmId);
  return {
    'income': transactions.where((t) => t.isIncome).sum(),
    'expense': transactions.where((t) => t.isExpense).sum(),
  };
}
```

---

## Fase 4: Advanced (Current)

### Session 2025-12-21

**Block & Level System:**
- Block model untuk grouping kandang
- Level: Atas, Tengah, Bawah
- Position format: `BLOCK-COL-LEVEL`

**Finance Deep:**
- `sellOffspring()` dengan auto-income
- MonthlyTrendData provider (6 bulan)
- fl_chart bar chart

### Key Learning
```dart
// Auto-create related data
Future<void> sellOffspring(String id, double price) async {
  await updateStatus(id, OffspringStatus.sold);
  await financeRepo.createTransaction(
    type: TransactionType.income,
    amount: price,
    referenceId: id,
  );
}
```

---

## Commits Hari Ini
```
f5f5b9f docs: reorganize devlog
c398264 chore: add seed dummy data
7750aff feat: Finance Deep implementation
9c7100f feat: kandang level system
```

---

## Next Features
- [ ] Offspring Batch Sell
- [ ] Reports Export PDF
- [ ] Health Auto-Reminder
