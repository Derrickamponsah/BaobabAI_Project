/// Data models mirroring the backend JSON payloads.

class Categories {
  final List<String> geographicZones;
  final List<String> treeGrowthHabitats;
  final List<String> topographies;
  final List<String> soilTextures;
  final List<String> farmCultivatedOptions;

  Categories({
    required this.geographicZones,
    required this.treeGrowthHabitats,
    required this.topographies,
    required this.soilTextures,
    required this.farmCultivatedOptions,
  });

  factory Categories.fromJson(Map<String, dynamic> j) => Categories(
        geographicZones: List<String>.from(j['geographic_zones'] ?? []),
        treeGrowthHabitats: List<String>.from(j['tree_growth_habitats'] ?? []),
        topographies: List<String>.from(j['topographies'] ?? []),
        soilTextures: List<String>.from(j['soil_textures'] ?? []),
        farmCultivatedOptions: List<String>.from(j['farm_cultivated_options'] ?? []),
      );
}

/// The raw feature set collected from the user (manual or image-assisted).
class BaobabInput {
  double? heightM;
  double? crownDiameterM;
  double? trunkDiameterM;
  double? altitudeM;
  String? geographicZone;
  String? treeGrowthHabitat;
  String? topography;
  String? soilTexture;
  String? farmCultivated;
  String source; // 'manual' | 'image'

  BaobabInput({this.source = 'manual'});

  Map<String, dynamic> toJson() => {
        'height_m': heightM,
        'crown_diameter_m': crownDiameterM,
        'trunk_diameter_m': trunkDiameterM,
        'altitude_m': altitudeM,
        'geographic_zone': geographicZone,
        'tree_growth_habitat': treeGrowthHabitat,
        'topography': topography,
        'soil_texture': soilTexture,
        'farm_cultivated': farmCultivated,
        'source': source,
      };

  bool get isComplete =>
      heightM != null &&
      crownDiameterM != null &&
      trunkDiameterM != null &&
      altitudeM != null &&
      geographicZone != null &&
      treeGrowthHabitat != null &&
      topography != null &&
      soilTexture != null &&
      farmCultivated != null;
}

class TaskPrediction {
  final int prediction;
  final bool? suitable;
  final double probability;
  final String confidenceLevel;
  final List<double> classProbabilities;
  final double modelAccuracy;
  final String algorithm;

  TaskPrediction({
    required this.prediction,
    required this.suitable,
    required this.probability,
    required this.confidenceLevel,
    required this.classProbabilities,
    required this.modelAccuracy,
    required this.algorithm,
  });

  factory TaskPrediction.fromJson(Map<String, dynamic> j) => TaskPrediction(
        prediction: j['prediction'],
        suitable: j['suitable'],
        probability: (j['probability'] as num).toDouble(),
        confidenceLevel: j['confidence_level'],
        classProbabilities:
            (j['class_probabilities'] as List).map((e) => (e as num).toDouble()).toList(),
        modelAccuracy: (j['model_accuracy'] as num).toDouble(),
        algorithm: j['algorithm'],
      );
}

class PredictionResult {
  final Map<String, TaskPrediction> predictions;
  final List<String> recommendations;
  final int? recordId;

  PredictionResult({
    required this.predictions,
    required this.recommendations,
    this.recordId,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> j) {
    final preds = <String, TaskPrediction>{};
    (j['predictions'] as Map<String, dynamic>).forEach((k, v) {
      preds[k] = TaskPrediction.fromJson(v);
    });
    return PredictionResult(
      predictions: preds,
      recommendations: List<String>.from(j['recommendations'] ?? []),
      recordId: j['record_id'],
    );
  }
}

class ImageEstimate {
  final double heightM;
  final double crownDiameterM;
  final double trunkDiameterM;
  final double dbhMm;
  final String confidence;
  final List<String> notes;

  ImageEstimate({
    required this.heightM,
    required this.crownDiameterM,
    required this.trunkDiameterM,
    required this.dbhMm,
    required this.confidence,
    required this.notes,
  });

  factory ImageEstimate.fromJson(Map<String, dynamic> j) {
    final e = j['estimated_features'];
    return ImageEstimate(
      heightM: (e['height_m'] as num).toDouble(),
      crownDiameterM: (e['crown_diameter_m'] as num).toDouble(),
      trunkDiameterM: (e['trunk_diameter_m'] as num).toDouble(),
      dbhMm: (e['dbh_mm'] as num).toDouble(),
      confidence: j['confidence'] ?? 'low',
      notes: List<String>.from(j['notes'] ?? []),
    );
  }
}
