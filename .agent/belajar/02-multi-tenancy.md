# 🏢 Multi-tenancy (Multi-Penyewa)

> **Keyword:** Multi-tenancy, Tenant Isolation, SaaS Architecture  
> **Dipelajari:** Week 0 - Planning Phase  
> **Relevansi:** Satu app DSFarm dipakai banyak peternak dengan data terpisah

---

## 👶 Level 1: Penjelasan untuk Anak-anak

### 🏨 Analogi: Hotel

Bayangkan **DSFarm itu seperti hotel** besar:

**Satu Hotel, Banyak Tamu:**
- Ada 100 kamar di hotel
- Setiap kamar ditempati tamu berbeda
- Tamu kamar 101 tidak bisa masuk kamar 102
- Tapi semua tamu pakai lift, lobby, dan kolam renang yang sama!

**DSFarm sama seperti itu:**
- Satu aplikasi (hotel)
- Banyak peternak (tamu)
- Setiap peternak hanya bisa lihat data ternaknya sendiri (kamar sendiri)
- Tapi semua pakai fitur yang sama (lift, lobby)

```
🏨 Hotel DSFarm
├── 🚪 Kamar 101: Pak Budi (50 kelinci)
├── 🚪 Kamar 102: Bu Siti (30 kambing)
├── 🚪 Kamar 103: Mas Agus (1000 ikan)
└── 🏊 Kolam Renang: Semua boleh pakai (shared features)

Pak Budi tidak bisa lihat kambing Bu Siti!
```

---

## 🎓 Level 2: Penjelasan Akademis

### Definisi Formal

**Multi-tenancy** adalah arsitektur software di mana satu instance aplikasi melayani banyak tenant (penyewa/customer), dengan setiap tenant memiliki data dan konfigurasi yang terisolasi satu sama lain.

### Model Multi-tenancy

#### 1. Database per Tenant
```
┌─────────┐  ┌─────────┐  ┌─────────┐
│ DB User1│  │ DB User2│  │ DB User3│
└─────────┘  └─────────┘  └─────────┘
     ↑            ↑            ↑
     └────────────┼────────────┘
                  │
            [Application]
```
- **Pro:** Isolasi maksimal
- **Con:** Maintenance kompleks, mahal

#### 2. Schema per Tenant
```
┌─────────────────────────────────────┐
│           Single Database           │
├───────────┬───────────┬────────────┤
│ Schema A  │ Schema B  │ Schema C   │
│ (User 1)  │ (User 2)  │ (User 3)   │
└───────────┴───────────┴────────────┘
```
- **Pro:** Isolasi bagus, lebih efisien
- **Con:** Migrasi schema kompleks

#### 3. Shared Schema (Row-Level Isolation) ⭐ **DSFarm pakai ini**
```
┌─────────────────────────────────────┐
│           Single Database           │
│           Single Schema             │
├─────────────────────────────────────┤
│ livestocks table:                   │
│ ├── id: 1, user_id: A, name: "Rex" │
│ ├── id: 2, user_id: B, name: "Max" │
│ └── id: 3, user_id: A, name: "Mia" │
└─────────────────────────────────────┘

User A query → Hanya lihat id 1 & 3
User B query → Hanya lihat id 2
```
- **Pro:** Paling efisien, mudah di-scale
- **Con:** Perlu RLS (Row Level Security) yang benar

### Isolation Levels

| Level | Isolasi | Cost | Complexity |
|-------|---------|------|------------|
| Database/tenant | 🔒🔒🔒 | $$$  | High |
| Schema/tenant | 🔒🔒 | $$ | Medium |
| Row/tenant | 🔒 | $ | Low |

### Referensi Akademik
- "Building Multi-Tenant SaaS Applications" - Todd Kerpelman
- Database Normalization & Foreign Keys
- RBAC (Role-Based Access Control)

---

## 💼 Level 3: Penjelasan Profesional

### Implementasi dengan Supabase RLS

```sql
-- Row Level Security di Supabase
-- Ini yang melindungi data antar tenant

-- Enable RLS pada table
ALTER TABLE livestocks ENABLE ROW LEVEL SECURITY;

-- Policy: User hanya lihat data miliknya
CREATE POLICY "Users can view own livestocks"
  ON livestocks
  FOR SELECT
  USING (user_id = auth.uid());

-- Policy: User hanya bisa insert ke data miliknya
CREATE POLICY "Users can insert own livestocks"
  ON livestocks
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Policy: User hanya bisa update data miliknya
CREATE POLICY "Users can update own livestocks"
  ON livestocks
  FOR UPDATE
  USING (user_id = auth.uid());

-- Policy: User hanya bisa delete data miliknya
CREATE POLICY "Users can delete own livestocks"
  ON livestocks
  FOR DELETE
  USING (user_id = auth.uid());
```

### DSFarm: Multi-Farm per User

```sql
-- DSFarm lebih kompleks: User → Farms → Livestocks

-- farms table
CREATE TABLE farms (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  name TEXT NOT NULL,
  animal_type TEXT NOT NULL
);

-- RLS: User hanya lihat farms miliknya
CREATE POLICY "Users can view own farms"
  ON farms FOR SELECT
  USING (user_id = auth.uid());

-- livestocks table
CREATE TABLE livestocks (
  id UUID PRIMARY KEY,
  farm_id UUID REFERENCES farms(id),
  code TEXT NOT NULL
);

-- RLS: User hanya lihat livestock di farm miliknya
CREATE POLICY "Users can view own livestocks"
  ON livestocks FOR SELECT
  USING (
    farm_id IN (
      SELECT id FROM farms WHERE user_id = auth.uid()
    )
  );
```

### Flutter Implementation

```dart
// Repository dengan tenant context
class LivestockRepository {
  final SupabaseClient supabase;
  
  // Supabase RLS otomatis filter berdasarkan auth.uid()
  // Kita tidak perlu manually add WHERE user_id = ...
  
  Future<List<Livestock>> getByFarm(String farmId) async {
    // RLS sudah protect: user tidak bisa akses farm orang lain
    final data = await supabase
        .from('livestocks')
        .select()
        .eq('farm_id', farmId);
    
    return data.map((e) => Livestock.fromJson(e)).toList();
  }
  
  Future<void> create(Livestock livestock) async {
    // RLS akan reject jika farm_id bukan milik user
    await supabase
        .from('livestocks')
        .insert(livestock.toJson());
  }
}
```

### Security Checklist

| Check | Description | DSFarm |
|-------|-------------|--------|
| ✅ | RLS enabled on all tables | Yes |
| ✅ | No SELECT * without WHERE | Via RLS |
| ✅ | Foreign key constraints | Yes |
| ✅ | Input validation | Flutter + DB |
| ✅ | Audit logging | Future |

### Real-World Examples

```
Slack:
- 1 platform, jutaan workspace
- Setiap workspace data terpisah
- Pakai tenant_id di setiap table

Shopify:
- 1 platform, jutaan toko
- Setiap toko punya data sendiri
- Pakai shop_id untuk isolasi

DSFarm:
- 1 platform, banyak peternak
- Setiap peternak bisa punya banyak farm
- Pakai user_id → farm_id → livestock
```

---

## 🔗 Implementasi di DSFarm

### Data Hierarchy

```
User (Peternak)
└── Farm 1 (Kelinci)
│   ├── Kandang A
│   │   └── Livestock 1, 2, 3...
│   └── Kandang B
│       └── Livestock 4, 5, 6...
│
└── Farm 2 (Kambing)
    ├── Kandang X
    │   └── Livestock 7, 8, 9...
    └── Kandang Y
        └── Livestock 10, 11, 12...
```

### Tenant Context Provider (Riverpod)

```dart
// Current farm context
final currentFarmProvider = StateProvider<Farm?>((ref) => null);

// Livestock filtered by current farm
final livestocksProvider = FutureProvider<List<Livestock>>((ref) {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  return ref.read(livestockRepositoryProvider).getByFarm(farm.id);
});
```

---

## ✅ Quiz Time!

**Pertanyaan:** Mengapa kita pakai Row Level Security (RLS) di Supabase?

A. Supaya query lebih cepat  
B. Supaya user A tidak bisa lihat data user B  
C. Supaya database tidak penuh  

<details>
<summary>Lihat Jawaban</summary>

**Jawaban: B**

Alasan:
- RLS adalah mekanisme keamanan di level database
- Setiap query otomatis difilter berdasarkan user yang login
- Ini mencegah data leak antar tenant

</details>

---

**📅 Last Updated:** 2025-12-20
