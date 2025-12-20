# 🎯 Auto-Generate Code Pattern

## Konsep

Saat farm bertambah besar, kode hewan harus **unik, informatif, dan otomatis**.

---

## Format Kode Indukan

```
[BREED]-[J/B][SEQUENCE]

Contoh:
NZW-B01   = New Zealand White, Betina, nomor 01
REX-J05   = Rex, Jantan, nomor 05
```

### Implementasi

```dart
// lib/repositories/livestock_repository.dart

Future<String> getNextCode({
  required String farmId,
  required String breedCode,
  required Gender gender,
}) async {
  final genderPrefix = gender == Gender.male ? 'J' : 'B';
  final pattern = '$breedCode-$genderPrefix%';

  // Get existing codes with this pattern
  final response = await SupabaseService.client
      .from(_tableName)
      .select('code')
      .eq('farm_id', farmId)
      .ilike('code', pattern);  // ILIKE = case-insensitive LIKE

  final codes = (response as List).map((e) => e['code'] as String).toList();

  // Find max sequence number
  int maxSeq = 0;
  for (final code in codes) {
    final parts = code.split('-');
    if (parts.length >= 2) {
      final seqStr = parts.last.replaceAll(RegExp(r'[^0-9]'), '');
      final seq = int.tryParse(seqStr) ?? 0;
      if (seq > maxSeq) maxSeq = seq;
    }
  }

  // Generate next code with 2+ digits
  final nextSeq = maxSeq + 1;
  final seqStr = nextSeq.toString().padLeft(2, '0');
  return '$breedCode-$genderPrefix$seqStr';
}
```

---

## Format Kode Anakan

```
[DAM_BREED]-[SIRE_SEQ].[DAM_SEQ]-[YYMMDD]-[SEQ]

Contoh:
NZW-J01.B04-251202-01

Artinya:
├── NZW     = Ras anakan (ikut induk)
├── J01    = Pejantan sequence 01
├── B04    = Induk sequence 04
├── 251202 = Lahir 2 Desember 2025
└── 01     = Anakan pertama dari litter ini
```

### Implementasi

```dart
// lib/providers/breeding_provider.dart

// Saat catat kelahiran
for (int i = 1; i <= aliveCount; i++) {
  final code = '$damBreedCode-J$sireSeq.B$damSeq-$dateStr-${i.toString().padLeft(2, '0')}';
  
  await _offspringRepo.create(
    farmId: _farmId,
    breedingRecordId: id,
    code: code,
    birthDate: actualBirthDate,
    status: OffspringStatus.infarm,
  );
}
```

---

## Tips

1. **Gunakan ILIKE** untuk pattern matching case-insensitive
2. **Extract digits** dengan RegExp untuk parsing sequence
3. **padLeft(2, '0')** untuk format 01, 02, dst
4. **Prefix by context** - J/B, breed code, date code

---

## SQL Pattern

```sql
-- Supabase query untuk find similar codes
SELECT code FROM livestocks 
WHERE farm_id = $1 
AND code ILIKE 'NZW-J%';  -- Semua NZW jantan
```
