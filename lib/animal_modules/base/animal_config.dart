/// Animal Config Base Class
/// 
/// Abstract class yang mendefinisikan perilaku dan konstanta
/// untuk setiap jenis hewan. Ini adalah inti dari config-driven architecture.

library;

/// Growth stage untuk tracking perkembangan hewan
class GrowthStage {
  final String name;
  final int minDays;
  final int? maxDays; // null = unlimited (dewasa)

  const GrowthStage({
    required this.name,
    required this.minDays,
    this.maxDays,
  });

  /// Check apakah umur (dalam hari) masuk ke stage ini
  bool matches(int ageDays) {
    if (ageDays < minDays) return false;
    if (maxDays == null) return true;
    return ageDays <= maxDays!;
  }
}

/// Abstract base class untuk animal configuration
abstract class AnimalConfig {
  // ═══════════════════════════════════════════════════════════
  // IDENTITY
  // ═══════════════════════════════════════════════════════════
  
  /// Type identifier (e.g., 'rabbit', 'goat')
  String get animalType;
  
  /// Display name in Indonesian
  String get displayName;
  
  /// Emoji icon
  String get icon;

  // ═══════════════════════════════════════════════════════════
  // BREEDING LIFECYCLE (in days)
  // ═══════════════════════════════════════════════════════════
  
  /// Gestation period - masa hamil
  int get gestationDays;
  
  /// Weaning period from birth - masa sapih dari lahir
  int get weaningDays;
  
  /// Maturity age - umur dewasa/siap kawin
  int get maturityDays;
  
  /// Ready to sell age - umur siap jual
  int get readySellDays;

  // ═══════════════════════════════════════════════════════════
  // TERMINOLOGY
  // ═══════════════════════════════════════════════════════════
  
  /// Terms used for this animal type
  /// Keys: offspring, housing, dam, sire, mating, palpation
  Map<String, String> get terminology;

  /// Get term with fallback
  String getTerm(String key, [String fallback = '']) {
    return terminology[key] ?? fallback;
  }

  /// Common term accessors
  String get offspringTerm => getTerm('offspring', 'Anak');
  String get housingTerm => getTerm('housing', 'Kandang');
  String get damTerm => getTerm('dam', 'Induk Betina');
  String get sireTerm => getTerm('sire', 'Pejantan');
  String get matingTerm => getTerm('mating', 'Kawin');

  // ═══════════════════════════════════════════════════════════
  // GROWTH STAGES
  // ═══════════════════════════════════════════════════════════
  
  /// List of growth stages for this animal
  List<GrowthStage> get growthStages;

  /// Get current stage based on age in days
  GrowthStage? getStageForAge(int ageDays) {
    for (final stage in growthStages) {
      if (stage.matches(ageDays)) {
        return stage;
      }
    }
    return null;
  }

  /// Get stage name for age
  String getStageName(int ageDays) {
    return getStageForAge(ageDays)?.name ?? 'Unknown';
  }

  // ═══════════════════════════════════════════════════════════
  // CALCULATED DATES
  // ═══════════════════════════════════════════════════════════

  /// Calculate expected birth date from mating date
  DateTime calculateExpectedBirth(DateTime matingDate) {
    return matingDate.add(Duration(days: gestationDays));
  }

  /// Calculate weaning date from birth date
  DateTime calculateWeaningDate(DateTime birthDate) {
    return birthDate.add(Duration(days: weaningDays));
  }

  /// Calculate maturity date from birth date
  DateTime calculateMaturityDate(DateTime birthDate) {
    return birthDate.add(Duration(days: maturityDays));
  }

  /// Calculate ready-to-sell date from birth date
  DateTime calculateReadySellDate(DateTime birthDate) {
    return birthDate.add(Duration(days: readySellDays));
  }

  // ═══════════════════════════════════════════════════════════
  // STATUS HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Check if animal is ready to mate based on age
  bool isReadyToMate(int ageDays) {
    return ageDays >= maturityDays;
  }

  /// Check if offspring is ready to sell
  bool isReadyToSell(int ageDays) {
    return ageDays >= readySellDays;
  }

  /// Check if offspring should be weaned
  bool shouldBeWeaned(int ageDays) {
    return ageDays >= weaningDays;
  }
}
