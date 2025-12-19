# ⚙️ Config-Driven Architecture

> **Keyword:** Configuration over Code, Polymorphism, Abstraction  
> **Dipelajari:** Week 0 - Planning Phase  
> **Relevansi:** DSFarm support multi-hewan dengan satu codebase

---

## 👶 Level 1: Penjelasan untuk Anak-anak

### 🎮 Analogi: Remote Control Universal

Bayangkan kamu punya **remote universal** yang bisa kontrol:
- 📺 TV
- 🔊 Sound System
- 💿 DVD Player

**Bagaimana remote ini tahu cara kontrol semua device?**
Dia punya **"setting mode"** untuk setiap device!

```
Remote Mode: TV
├── Volume: Channel TV
├── Power: Nyalakan TV
└── Menu: Menu TV

Remote Mode: Sound System
├── Volume: Bass/Treble
├── Power: Nyalakan Speaker
└── Menu: Equalizer
```

**Satu remote, banyak device. Tinggal ganti mode!**

**DSFarm sama seperti itu:**
- Satu app
- Banyak jenis hewan (kelinci, kambing, ikan)
- Tinggal pilih "mode" yang mana!

```
DSFarm Mode: Kelinci 🐰
├── Masa hamil: 31 hari
├── Masa sapih: 35 hari
└── Istilah anak: "Anak Kelinci"

DSFarm Mode: Kambing 🐐
├── Masa hamil: 150 hari
├── Masa sapih: 90 hari
└── Istilah anak: "Cempe"

Satu app, beda setting, fitur sama!
```

---

## 🎓 Level 2: Penjelasan Akademis

### Definisi Formal

**Config-Driven Architecture** (atau Configuration over Code) adalah pola desain di mana perilaku aplikasi ditentukan oleh konfigurasi eksternal, bukan hardcoded di dalam source code.

### Prinsip Utama

#### 1. Abstraction (Abstraksi)
Menyembunyikan detail implementasi di balik interface umum.

```dart
// Abstract class = blueprint umum
abstract class Animal {
  String get name;
  int get gestationDays;
  void makeSound();
}

// Concrete class = implementasi spesifik
class Rabbit extends Animal {
  @override
  String get name => "Kelinci";
  
  @override
  int get gestationDays => 31;
  
  @override
  void makeSound() => print("🐰 *squeak*");
}
```

#### 2. Polymorphism (Polimorfisme)
Satu interface, banyak bentuk implementasi.

```dart
void printAnimalInfo(Animal animal) {
  // Fungsi ini tidak peduli animal apa
  // Yang penting punya method yang sama
  print("Nama: ${animal.name}");
  print("Masa hamil: ${animal.gestationDays} hari");
  animal.makeSound();
}

// Bisa dipanggil dengan hewan apapun!
printAnimalInfo(Rabbit());  // ✅ Works
printAnimalInfo(Goat());    // ✅ Works
printAnimalInfo(Fish());    // ✅ Works
```

#### 3. Open-Closed Principle
"Open for extension, closed for modification"
- Bisa tambah hewan baru tanpa ubah kode existing

### Design Patterns Terkait

| Pattern | Deskripsi | Dipakai di DSFarm |
|---------|-----------|-------------------|
| Strategy | Swap algorithm at runtime | AnimalConfig |
| Factory | Create objects without specifying class | AnimalFactory |
| Template Method | Define skeleton, defer details | BaseRepository |

### Referensi Akademik
- SOLID Principles (Robert C. Martin)
- "Design Patterns" - Gang of Four
- Dependency Injection & Inversion of Control

---

## 💼 Level 3: Penjelasan Profesional

### Implementasi di DSFarm

#### 1. Base Config Class

```dart
// lib/animal_modules/base/animal_config.dart

abstract class AnimalConfig {
  // Identitas
  String get animalType;
  String get displayName;
  String get icon;
  
  // Breeding lifecycle
  int get gestationDays;      // Masa hamil
  int get weaningDays;        // Masa sapih
  int get maturityDays;       // Dewasa
  int get readySellDays;      // Siap jual
  
  // Terminology
  Map<String, String> get terminology;
  
  // Growth stages
  List<GrowthStage> get growthStages;
  
  // Calculated properties
  DateTime calculateExpectedBirth(DateTime matingDate) {
    return matingDate.add(Duration(days: gestationDays));
  }
  
  DateTime calculateWeaningDate(DateTime birthDate) {
    return birthDate.add(Duration(days: weaningDays));
  }
  
  String getOffspringTerm() {
    return terminology['offspring'] ?? 'Anak';
  }
  
  String getHousingTerm() {
    return terminology['housing'] ?? 'Kandang';
  }
}
```

#### 2. Specific Implementations

```dart
// lib/animal_modules/rabbit/rabbit_config.dart

class RabbitConfig extends AnimalConfig {
  @override
  String get animalType => 'rabbit';
  
  @override
  String get displayName => 'Kelinci';
  
  @override
  String get icon => '🐰';
  
  @override
  int get gestationDays => 31;
  
  @override
  int get weaningDays => 35;
  
  @override
  int get maturityDays => 150;
  
  @override
  int get readySellDays => 90;
  
  @override
  Map<String, String> get terminology => {
    'offspring': 'Anak Kelinci',
    'housing': 'Kandang',
    'dam': 'Induk Betina',
    'sire': 'Pejantan',
    'mating': 'Kawin',
  };
  
  @override
  List<GrowthStage> get growthStages => [
    GrowthStage('Anakan', 0, 35),
    GrowthStage('Lepas Sapih', 36, 60),
    GrowthStage('Remaja', 61, 90),
    GrowthStage('Siap Jual', 91, 150),
    GrowthStage('Dewasa', 151, null),
  ];
}
```

```dart
// lib/animal_modules/goat/goat_config.dart

class GoatConfig extends AnimalConfig {
  @override
  String get animalType => 'goat';
  
  @override
  String get displayName => 'Kambing';
  
  @override
  String get icon => '🐐';
  
  @override
  int get gestationDays => 150;  // 5 bulan!
  
  @override
  int get weaningDays => 90;     // 3 bulan
  
  @override
  int get maturityDays => 365;   // 1 tahun
  
  @override
  int get readySellDays => 180;  // 6 bulan
  
  @override
  Map<String, String> get terminology => {
    'offspring': 'Cempe',        // Beda dengan kelinci!
    'housing': 'Kandang',
    'dam': 'Induk Betina',
    'sire': 'Pejantan',
    'mating': 'Kawin',
  };
  
  @override
  List<GrowthStage> get growthStages => [
    GrowthStage('Cempe', 0, 90),
    GrowthStage('Lepas Sapih', 91, 180),
    GrowthStage('Dara/Muda', 181, 365),
    GrowthStage('Dewasa', 366, null),
  ];
}
```

#### 3. Factory untuk Create Config

```dart
// lib/animal_modules/base/animal_factory.dart

class AnimalConfigFactory {
  static AnimalConfig create(String animalType) {
    switch (animalType) {
      case 'rabbit':
        return RabbitConfig();
      case 'goat':
        return GoatConfig();
      case 'fish':
        return FishConfig();
      case 'poultry':
        return PoultryConfig();
      default:
        throw Exception('Unknown animal type: $animalType');
    }
  }
}

// Usage
final config = AnimalConfigFactory.create('rabbit');
print(config.gestationDays);  // 31
```

#### 4. UI yang Adaptive

```dart
// lib/features/breeding/screens/breeding_form.dart

class BreedingForm extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farm = ref.watch(currentFarmProvider);
    final config = AnimalConfigFactory.create(farm.animalType);
    
    return Column(
      children: [
        Text('Tambah Record ${config.terminology['mating']}'),
        
        DatePickerField(
          label: 'Tanggal ${config.terminology['mating']}',
          onChanged: (date) {
            // Auto-calculate expected birth
            final expectedBirth = config.calculateExpectedBirth(date);
            setState(() => _expectedBirth = expectedBirth);
          },
        ),
        
        Text(
          'Perkiraan lahir: ${DateFormat('dd/MM/yyyy').format(_expectedBirth)}'
          '\n(${config.gestationDays} hari)',
        ),
        
        // Terminology otomatis sesuai hewan!
        Text('Jumlah ${config.getOffspringTerm()} lahir hidup:'),
        NumberField(...),
      ],
    );
  }
}
```

### Benefits

| Benefit | Tanpa Config-Driven | Dengan Config-Driven |
|---------|---------------------|----------------------|
| Tambah hewan baru | Edit banyak file | Buat 1 config file |
| Bug di 1 hewan | Mungkin affect lain | Terisolasi |
| Testing | Test per hewan | Test base + configs |
| Maintenance | Sulit (duplicate code) | Mudah (DRY) |

### Real-World Examples

```
WordPress:
- Satu CMS, ribuan theme/plugin
- Perilaku ditentukan config di wp-config.php

Kubernetes:
- Satu orchestrator
- App behavior dari YAML configs

DSFarm:
- Satu app
- Animal behavior dari AnimalConfig classes
```

---

## 🔗 Implementasi di DSFarm

### Perbandingan: Hardcoded vs Config-Driven

**❌ Hardcoded (BAD):**
```dart
// Harus duplicate logic untuk setiap hewan
if (farm.type == 'rabbit') {
  expectedBirth = matingDate.add(Duration(days: 31));
  offspringLabel = 'Anak Kelinci';
} else if (farm.type == 'goat') {
  expectedBirth = matingDate.add(Duration(days: 150));
  offspringLabel = 'Cempe';
} else if (farm.type == 'fish') {
  // ... another condition
}
```

**✅ Config-Driven (GOOD):**
```dart
// Satu logic, behavior dari config
final config = AnimalConfigFactory.create(farm.type);
final expectedBirth = config.calculateExpectedBirth(matingDate);
final offspringLabel = config.getOffspringTerm();
```

---

## ✅ Quiz Time!

**Pertanyaan:** Apa keuntungan utama Config-Driven Architecture?

A. Aplikasi jadi lebih cepat  
B. Bisa tambah fitur baru tanpa ubah kode existing  
C. Database jadi lebih kecil  

<details>
<summary>Lihat Jawaban</summary>

**Jawaban: B**

Alasan:
- Open-Closed Principle: "Open for extension, closed for modification"
- Tambah GoatConfig tidak perlu ubah RabbitConfig
- Tambah hewan baru = buat 1 file config baru saja

</details>

---

**📅 Last Updated:** 2025-12-20
