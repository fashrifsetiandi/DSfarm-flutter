/// Animal Config Factory
/// 
/// Factory untuk membuat instance AnimalConfig berdasarkan animal type.
/// Ini adalah entry point untuk mendapatkan config yang tepat.

library;

import 'animal_config.dart';
import '../rabbit/rabbit_config.dart';

class AnimalConfigFactory {
  // Private constructor - tidak perlu instantiate
  AnimalConfigFactory._();

  /// Cache untuk config instances
  static final Map<String, AnimalConfig> _cache = {};

  /// Get config untuk animal type tertentu
  static AnimalConfig getConfig(String animalType) {
    // Return dari cache jika sudah ada
    if (_cache.containsKey(animalType)) {
      return _cache[animalType]!;
    }

    // Create new config
    final config = _createConfig(animalType);
    _cache[animalType] = config;
    return config;
  }

  /// Create config based on animal type
  static AnimalConfig _createConfig(String animalType) {
    switch (animalType) {
      case 'rabbit':
        return RabbitConfig();
      
      // TODO: Add more animal types as we implement them
      // case 'goat':
      //   return GoatConfig();
      // case 'fish':
      //   return FishConfig();
      // case 'poultry':
      //   return PoultryConfig();
      
      default:
        // Default to rabbit for now
        return RabbitConfig();
    }
  }

  /// Get all available animal types
  static List<String> get availableTypes => [
    'rabbit',
    // 'goat',  // Coming soon
    // 'fish',  // Coming soon
    // 'poultry', // Coming soon
  ];

  /// Check if animal type is supported
  static bool isSupported(String animalType) {
    return availableTypes.contains(animalType);
  }
}
