# 📈 Scalability (Skalabilitas)

> **Keyword:** Scalability, Scaling, Load Handling  
> **Dipelajari:** Week 0 - Planning Phase  
> **Relevansi:** DSFarm harus bisa melayani peternak kecil sampai besar

---

## 👶 Level 1: Penjelasan untuk Anak-anak

### 🍕 Analogi: Warung Pizza

Bayangkan kamu punya **warung pizza kecil** di rumah.

**Awalnya:**
- Kamu masak sendiri
- Bisa buat 5 pizza/hari
- Pelanggan: tetangga sekitar

**Warung makin ramai:**
- Pelanggan banyak, kamu kewalahan!
- **Pilihan 1:** Beli oven lebih besar (ini namanya "Scale Up")
- **Pilihan 2:** Ajak teman bantu masak dengan oven masing-masing (ini namanya "Scale Out")

**DSFarm seperti warung pizza:**
- Awalnya: 1 peternak, 50 kelinci
- Berkembang: 1000 peternak, 50.000 hewan
- Sistem harus tetap cepat dan tidak error!

```
🍕 Warung Kecil     →     🍕🍕🍕 Warung Besar
   (5 pizza)                  (500 pizza)
   
📱 App Kecil        →     📱📱📱 App Besar  
   (50 user)                  (5000 user)
```

---

## 🎓 Level 2: Penjelasan Akademis

### Definisi Formal

**Scalability** adalah kemampuan sistem untuk menangani peningkatan beban kerja (workload) dengan menambahkan sumber daya, tanpa mengubah arsitektur dasar sistem.

### Jenis Scalability

#### 1. Vertical Scaling (Scale Up)
- **Definisi:** Meningkatkan kapasitas satu mesin (CPU, RAM, Storage)
- **Karakteristik:** 
  - Lebih sederhana implementasinya
  - Ada batas maksimum (hardware limit)
  - Single point of failure

```
Before:  [Server 4GB RAM]
After:   [Server 32GB RAM]
```

#### 2. Horizontal Scaling (Scale Out)
- **Definisi:** Menambahkan lebih banyak mesin ke dalam pool
- **Karakteristik:**
  - Teoritis tidak ada batas
  - Membutuhkan load balancer
  - Lebih kompleks (distributed system)

```
Before:  [Server 1]
After:   [Server 1] [Server 2] [Server 3]
              ↑          ↑          ↑
           [Load Balancer]
```

### Metrics Scalability

| Metric | Definisi | Target |
|--------|----------|--------|
| **Throughput** | Requests per second | > 1000 RPS |
| **Latency** | Response time | < 200ms |
| **Availability** | Uptime percentage | > 99.9% |
| **Elasticity** | Kemampuan auto-scale | Menit |

### Referensi Akademik
- "Designing Data-Intensive Applications" - Martin Kleppmann
- CAP Theorem (Consistency, Availability, Partition Tolerance)
- Amdahl's Law untuk parallel processing

---

## 💼 Level 3: Penjelasan Profesional

### Bagaimana Industri Mengimplementasikan

#### Pattern 1: Database Scaling

```sql
-- Supabase/PostgreSQL sudah handle ini:

-- Connection Pooling (handle banyak koneksi)
-- Read Replicas (untuk query-heavy apps)
-- Row Level Security (isolasi data per tenant)

-- Contoh RLS di DSFarm:
CREATE POLICY "users_see_own_data" ON livestocks
  FOR ALL
  USING (user_id = auth.uid());
```

#### Pattern 2: Caching Layer

```dart
// Profesional selalu pakai caching
class LivestockRepository {
  final _cache = <String, Livestock>{};
  
  Future<Livestock?> getById(String id) async {
    // Check cache first
    if (_cache.containsKey(id)) {
      return _cache[id];
    }
    
    // If not cached, fetch from DB
    final data = await supabase
        .from('livestocks')
        .select()
        .eq('id', id)
        .single();
    
    final livestock = Livestock.fromJson(data);
    _cache[id] = livestock; // Cache it
    return livestock;
  }
}
```

#### Pattern 3: Pagination

```dart
// JANGAN: Load semua data sekaligus
final allLivestock = await supabase
    .from('livestocks')
    .select();  // ❌ 10.000 rows = SLOW!

// HARUS: Pagination
final page1 = await supabase
    .from('livestocks')
    .select()
    .range(0, 49);  // ✅ 50 rows only
```

### Best Practices di DSFarm

| Practice | Implementation |
|----------|----------------|
| **Lazy Loading** | Load data saat dibutuhkan |
| **Pagination** | 50 items per page |
| **Caching** | Cache frequently accessed data |
| **Indexing** | Index on user_id, farm_id |
| **Connection Pooling** | Supabase handles this |

### Real-World Example

```
Shopify (e-commerce platform):
- 1.7 million+ merchants
- Handles Black Friday traffic spikes
- Uses horizontal scaling + caching

DSFarm Target:
- 10,000+ peternak
- Scales with Supabase auto-scaling
- Tier-based resource allocation
```

---

## 🔗 Implementasi di DSFarm

### Sekarang (MVP)
```
┌─────────────────┐     ┌─────────────────┐
│  Flutter App    │ ──→ │  Supabase       │
│  (Client)       │     │  (Free Tier)    │
└─────────────────┘     └─────────────────┘
```

### Nanti (Scale)
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Flutter App    │ ──→ │  Supabase Pro   │ ──→ │  Read Replicas  │
│  (Client)       │     │  + Edge Funcs   │     │  (if needed)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## ✅ Quiz Time!

**Pertanyaan:** Jika DSFarm punya 10.000 user dan masing-masing ada 100 ternak, mana yang lebih baik?

A. Load semua 1.000.000 data ternak sekaligus  
B. Load 50 data per halaman dengan pagination  
C. Tidak pakai database, simpan di file  

<details>
<summary>Lihat Jawaban</summary>

**Jawaban: B**

Alasan:
- A: Memory overflow, app crash
- B: Efisien, user experience tetap baik
- C: Tidak scalable, tidak aman

</details>

---

**📅 Last Updated:** 2025-12-20
