/// Rabbit Config
/// 
/// Configuration untuk kelinci (rabbit).
/// Berisi semua konstanta dan terminologi spesifik kelinci.

library;

import '../base/animal_config.dart';

class RabbitConfig extends AnimalConfig {
  // Singleton pattern
  static final RabbitConfig _instance = RabbitConfig._internal();
  factory RabbitConfig() => _instance;
  RabbitConfig._internal();

  // ═══════════════════════════════════════════════════════════
  // IDENTITY
  // ═══════════════════════════════════════════════════════════

  @override
  String get animalType => 'rabbit';

  @override
  String get displayName => 'Kelinci';

  @override
  String get icon => '🐰';

  // ═══════════════════════════════════════════════════════════
  // BREEDING LIFECYCLE
  // ═══════════════════════════════════════════════════════════

  @override
  int get gestationDays => 31; // Masa hamil ~31 hari

  @override
  int get weaningDays => 35; // Sapih di umur 35 hari

  @override
  int get maturityDays => 150; // Dewasa/siap kawin ~5 bulan

  @override
  int get readySellDays => 90; // Siap jual ~3 bulan

  // ═══════════════════════════════════════════════════════════
  // TERMINOLOGY
  // ═══════════════════════════════════════════════════════════

  @override
  Map<String, String> get terminology => const {
    'offspring': 'Anak Kelinci',
    'housing': 'Kandang',
    'dam': 'Induk Betina',
    'sire': 'Pejantan',
    'mating': 'Kawin',
    'palpation': 'Palpasi',
    'weaning': 'Sapih',

  };

  // ═══════════════════════════════════════════════════════════
  // GROWTH STAGES
  // ═══════════════════════════════════════════════════════════

  @override
  List<GrowthStage> get growthStages => const [
    GrowthStage(name: 'Anakan', minDays: 0, maxDays: 35),
    GrowthStage(name: 'Lepas Sapih', minDays: 36, maxDays: 60),
    GrowthStage(name: 'Remaja', minDays: 61, maxDays: 90),
    GrowthStage(name: 'Siap Jual', minDays: 91, maxDays: 150),
    GrowthStage(name: 'Dewasa', minDays: 151),
  ];
}
