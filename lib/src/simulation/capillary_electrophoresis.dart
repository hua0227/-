import 'dart:convert';
import 'dart:math' as math;

class AnalyteSpec {
  const AnalyteSpec({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.electrophoreticMobility,
    required this.diffusionCoefficient,
    required this.relativeConcentration,
    this.note = '',
  });

  final String id;
  final String name;
  final String colorHex;
  final double electrophoreticMobility;
  final double diffusionCoefficient;
  final double relativeConcentration;
  final String note;

  factory AnalyteSpec.fromJson(Map<String, Object?> json) {
    return AnalyteSpec(
      id: json['id'] as String? ?? 'analyte',
      name: json['name'] as String? ?? '未知组分',
      colorHex: json['colorHex'] as String? ?? '#2563eb',
      electrophoreticMobility: _asDouble(
        json['electrophoreticMobility'],
        fallback: 2.2e-8,
      ),
      diffusionCoefficient: _asDouble(
        json['diffusionCoefficient'],
        fallback: 5.0e-10,
      ),
      relativeConcentration: _asDouble(
        json['relativeConcentration'],
        fallback: 1.0,
      ),
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'colorHex': colorHex,
    'electrophoreticMobility': electrophoreticMobility,
    'diffusionCoefficient': diffusionCoefficient,
    'relativeConcentration': relativeConcentration,
    'note': note,
  };

  AnalyteSpec copyWith({
    double? electrophoreticMobility,
    double? diffusionCoefficient,
    double? relativeConcentration,
  }) {
    return AnalyteSpec(
      id: id,
      name: name,
      colorHex: colorHex,
      electrophoreticMobility:
          electrophoreticMobility ?? this.electrophoreticMobility,
      diffusionCoefficient: diffusionCoefficient ?? this.diffusionCoefficient,
      relativeConcentration:
          relativeConcentration ?? this.relativeConcentration,
      note: note,
    );
  }
}

class CapillaryElectrophoresisConfig {
  const CapillaryElectrophoresisConfig({
    required this.voltageVolts,
    required this.capillaryLengthCm,
    required this.effectiveLengthCm,
    required this.innerDiameterUm,
    required this.electroosmoticMobility,
    required this.bufferViscosityMPaS,
    required this.bufferConductivitySm,
    required this.injectionWidthMm,
    required this.temperatureC,
    required this.analytes,
  });

  final double voltageVolts;
  final double capillaryLengthCm;
  final double effectiveLengthCm;
  final double innerDiameterUm;
  final double electroosmoticMobility;
  final double bufferViscosityMPaS;
  final double bufferConductivitySm;
  final double injectionWidthMm;
  final double temperatureC;
  final List<AnalyteSpec> analytes;

  double get capillaryLengthM => capillaryLengthCm / 100;
  double get effectiveLengthM => effectiveLengthCm / 100;
  double get injectionSigmaM => math.max(injectionWidthMm / 1000 / 2.355, 1e-5);
  double get electricFieldVm => voltageVolts / capillaryLengthM;
  double get radiusM => innerDiameterUm * 1e-6 / 2;
  double get crossSectionM2 => math.pi * radiusM * radiusM;

  factory CapillaryElectrophoresisConfig.defaults() {
    return const CapillaryElectrophoresisConfig(
      voltageVolts: 15000,
      capillaryLengthCm: 50,
      effectiveLengthCm: 40,
      innerDiameterUm: 50,
      electroosmoticMobility: 3.0e-8,
      bufferViscosityMPaS: 1.0,
      bufferConductivitySm: 0.08,
      injectionWidthMm: 1.2,
      temperatureC: 25,
      analytes: [
        AnalyteSpec(
          id: 'weak_acid',
          name: '弱酸性药物 A',
          colorHex: '#2563eb',
          electrophoreticMobility: -1.2e-8,
          diffusionCoefficient: 5.4e-10,
          relativeConcentration: 1.0,
          note: '模拟带负电的弱酸性药物，电泳方向与电渗流相反。',
        ),
        AnalyteSpec(
          id: 'basic_impurity',
          name: '碱性杂质 B',
          colorHex: '#d97706',
          electrophoreticMobility: 1.6e-8,
          diffusionCoefficient: 4.6e-10,
          relativeConcentration: 0.62,
          note: '模拟带正电杂质，迁移速度通常快于中性标记物。',
        ),
        AnalyteSpec(
          id: 'neutral_marker',
          name: '中性标记物 C',
          colorHex: '#059669',
          electrophoreticMobility: 0,
          diffusionCoefficient: 4.0e-10,
          relativeConcentration: 0.78,
          note: '中性组分仅随电渗流迁移，可用于观察电渗流贡献。',
        ),
      ],
    );
  }

  factory CapillaryElectrophoresisConfig.fromModelJson(
    Map<String, Object?> json,
  ) {
    final defaults = CapillaryElectrophoresisConfig.defaults();
    final analytesJson = json['analytes'];
    final analytes = analytesJson is List
        ? analytesJson
              .whereType<Map>()
              .map(
                (item) => AnalyteSpec.fromJson(Map<String, Object?>.from(item)),
              )
              .toList()
        : defaults.analytes;
    return defaults.copyWith(
      voltageVolts: _asDouble(
        json['voltageVolts'],
        fallback: defaults.voltageVolts,
      ),
      capillaryLengthCm: _asDouble(
        json['capillaryLengthCm'],
        fallback: defaults.capillaryLengthCm,
      ),
      effectiveLengthCm: _asDouble(
        json['effectiveLengthCm'],
        fallback: defaults.effectiveLengthCm,
      ),
      innerDiameterUm: _asDouble(
        json['innerDiameterUm'],
        fallback: defaults.innerDiameterUm,
      ),
      electroosmoticMobility: _asDouble(
        json['electroosmoticMobility'],
        fallback: defaults.electroosmoticMobility,
      ),
      bufferViscosityMPaS: _asDouble(
        json['bufferViscosityMPaS'],
        fallback: defaults.bufferViscosityMPaS,
      ),
      bufferConductivitySm: _asDouble(
        json['bufferConductivitySm'],
        fallback: defaults.bufferConductivitySm,
      ),
      injectionWidthMm: _asDouble(
        json['injectionWidthMm'],
        fallback: defaults.injectionWidthMm,
      ),
      temperatureC: _asDouble(
        json['temperatureC'],
        fallback: defaults.temperatureC,
      ),
      analytes: analytes.isEmpty ? defaults.analytes : analytes,
    );
  }

  Map<String, Object?> toJson() => {
    'voltageVolts': voltageVolts,
    'capillaryLengthCm': capillaryLengthCm,
    'effectiveLengthCm': effectiveLengthCm,
    'innerDiameterUm': innerDiameterUm,
    'electroosmoticMobility': electroosmoticMobility,
    'bufferViscosityMPaS': bufferViscosityMPaS,
    'bufferConductivitySm': bufferConductivitySm,
    'injectionWidthMm': injectionWidthMm,
    'temperatureC': temperatureC,
    'analytes': analytes.map((item) => item.toJson()).toList(),
  };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  CapillaryElectrophoresisConfig copyWith({
    double? voltageVolts,
    double? capillaryLengthCm,
    double? effectiveLengthCm,
    double? innerDiameterUm,
    double? electroosmoticMobility,
    double? bufferViscosityMPaS,
    double? bufferConductivitySm,
    double? injectionWidthMm,
    double? temperatureC,
    List<AnalyteSpec>? analytes,
  }) {
    final nextLength = capillaryLengthCm ?? this.capillaryLengthCm;
    final nextEffective = effectiveLengthCm ?? this.effectiveLengthCm;
    return CapillaryElectrophoresisConfig(
      voltageVolts: voltageVolts ?? this.voltageVolts,
      capillaryLengthCm: nextLength,
      effectiveLengthCm: math.min(nextEffective, nextLength - 1),
      innerDiameterUm: innerDiameterUm ?? this.innerDiameterUm,
      electroosmoticMobility:
          electroosmoticMobility ?? this.electroosmoticMobility,
      bufferViscosityMPaS: bufferViscosityMPaS ?? this.bufferViscosityMPaS,
      bufferConductivitySm: bufferConductivitySm ?? this.bufferConductivitySm,
      injectionWidthMm: injectionWidthMm ?? this.injectionWidthMm,
      temperatureC: temperatureC ?? this.temperatureC,
      analytes: analytes ?? this.analytes,
    );
  }

  CapillaryElectrophoresisConfig applyPreset(Map<String, Object?> values) {
    return copyWith(
      voltageVolts: _asDouble(values['voltageVolts'], fallback: voltageVolts),
      capillaryLengthCm: _asDouble(
        values['capillaryLengthCm'],
        fallback: capillaryLengthCm,
      ),
      effectiveLengthCm: _asDouble(
        values['effectiveLengthCm'],
        fallback: effectiveLengthCm,
      ),
      innerDiameterUm: _asDouble(
        values['innerDiameterUm'],
        fallback: innerDiameterUm,
      ),
      electroosmoticMobility: _asDouble(
        values['electroosmoticMobility'],
        fallback: electroosmoticMobility,
      ),
      bufferViscosityMPaS: _asDouble(
        values['bufferViscosityMPaS'],
        fallback: bufferViscosityMPaS,
      ),
      bufferConductivitySm: _asDouble(
        values['bufferConductivitySm'],
        fallback: bufferConductivitySm,
      ),
      injectionWidthMm: _asDouble(
        values['injectionWidthMm'],
        fallback: injectionWidthMm,
      ),
      temperatureC: _asDouble(values['temperatureC'], fallback: temperatureC),
    );
  }
}

class PeakMetrics {
  const PeakMetrics({
    required this.analyteId,
    required this.analyteName,
    required this.velocityMs,
    required this.migrationTimeSec,
    required this.temporalSigmaSec,
    required this.baseWidthSec,
    required this.theoreticalPlates,
    required this.peakSignal,
  });

  final String analyteId;
  final String analyteName;
  final double velocityMs;
  final double migrationTimeSec;
  final double temporalSigmaSec;
  final double baseWidthSec;
  final double theoreticalPlates;
  final double peakSignal;
}

class ResolutionMetrics {
  const ResolutionMetrics({
    required this.leftName,
    required this.rightName,
    required this.resolution,
  });

  final String leftName;
  final String rightName;
  final double resolution;
}

class SimulationPoint {
  const SimulationPoint({
    required this.timeSec,
    required this.totalSignal,
    required this.analyteSignals,
  });

  final double timeSec;
  final double totalSignal;
  final Map<String, double> analyteSignals;
}

class SpatialSnapshot {
  const SpatialSnapshot({
    required this.timeSec,
    required this.positionsM,
    required this.profiles,
  });

  final double timeSec;
  final List<double> positionsM;
  final Map<String, List<double>> profiles;
}

class SimulationResult {
  const SimulationResult({
    required this.config,
    required this.points,
    required this.snapshots,
    required this.peaks,
    required this.resolutions,
    required this.currentAmp,
    required this.powerWatt,
    required this.riskLevel,
    required this.notes,
  });

  final CapillaryElectrophoresisConfig config;
  final List<SimulationPoint> points;
  final List<SpatialSnapshot> snapshots;
  final List<PeakMetrics> peaks;
  final List<ResolutionMetrics> resolutions;
  final double currentAmp;
  final double powerWatt;
  final String riskLevel;
  final List<String> notes;

  double get maxSignal => points.fold(0, (maxValue, point) {
    return math.max(maxValue, point.totalSignal);
  });

  String toCsv() {
    final analyteIds = config.analytes.map((item) => item.id).toList();
    final buffer = StringBuffer('time_s,total_signal,');
    buffer.writeln(analyteIds.map((id) => 'signal_$id').join(','));
    for (final point in points) {
      final values = [
        point.timeSec.toStringAsFixed(3),
        point.totalSignal.toStringAsExponential(6),
        ...analyteIds.map(
          (id) => (point.analyteSignals[id] ?? 0).toStringAsExponential(6),
        ),
      ];
      buffer.writeln(values.join(','));
    }
    return buffer.toString();
  }
}

class CapillaryElectrophoresisSolver {
  const CapillaryElectrophoresisSolver();

  SimulationResult run(CapillaryElectrophoresisConfig config) {
    final peaks = config.analytes.map((analyte) {
      final velocity =
          (analyte.electrophoreticMobility + config.electroosmoticMobility) *
          config.electricFieldVm;
      final migrationTime = velocity > 1e-9
          ? config.effectiveLengthM / velocity
          : double.infinity;
      final detectorSigmaM = migrationTime.isFinite
          ? math.sqrt(
              config.injectionSigmaM * config.injectionSigmaM +
                  2 * analyte.diffusionCoefficient * migrationTime,
            )
          : double.infinity;
      final temporalSigma = migrationTime.isFinite
          ? detectorSigmaM / velocity.abs()
          : double.infinity;
      final baseWidth = temporalSigma.isFinite
          ? 4 * temporalSigma
          : double.infinity;
      final plates = migrationTime.isFinite && baseWidth > 0
          ? 16 * math.pow(migrationTime / baseWidth, 2).toDouble()
          : 0.0;
      final peakSignal = migrationTime.isFinite
          ? _gaussianAt(
              config.effectiveLengthM,
              config.effectiveLengthM,
              detectorSigmaM,
              analyte.relativeConcentration,
            )
          : 0.0;
      return PeakMetrics(
        analyteId: analyte.id,
        analyteName: analyte.name,
        velocityMs: velocity,
        migrationTimeSec: migrationTime,
        temporalSigmaSec: temporalSigma,
        baseWidthSec: baseWidth,
        theoreticalPlates: plates,
        peakSignal: peakSignal,
      );
    }).toList();

    final finitePeaks = peaks.where((peak) => peak.migrationTimeSec.isFinite);
    final lastPeak = finitePeaks.isEmpty
        ? 240.0
        : finitePeaks
              .map((peak) => peak.migrationTimeSec + 3 * peak.baseWidthSec)
              .reduce(math.max);
    final totalTime = math.max(120.0, math.min(lastPeak * 1.05, 1800.0));
    final points = <SimulationPoint>[];
    const pointCount = 280;
    for (var i = 0; i < pointCount; i++) {
      final time = totalTime * i / (pointCount - 1);
      final signals = <String, double>{};
      var total = 0.0;
      for (final analyte in config.analytes) {
        final signal = _detectorSignal(config, analyte, time);
        signals[analyte.id] = signal;
        total += signal;
      }
      points.add(
        SimulationPoint(
          timeSec: time,
          totalSignal: total,
          analyteSignals: signals,
        ),
      );
    }

    final snapshots = <SpatialSnapshot>[];
    const gridPoints = 140;
    final positions = List<double>.generate(
      gridPoints,
      (index) => config.capillaryLengthM * index / (gridPoints - 1),
      growable: false,
    );
    for (var i = 0; i < 18; i++) {
      final time = totalTime * i / 17;
      snapshots.add(
        SpatialSnapshot(
          timeSec: time,
          positionsM: positions,
          profiles: {
            for (final analyte in config.analytes)
              analyte.id: positions
                  .map(
                    (position) =>
                        _spatialConcentration(config, analyte, time, position),
                  )
                  .toList(growable: false),
          },
        ),
      );
    }

    final sortedPeaks =
        peaks.where((peak) => peak.migrationTimeSec.isFinite).toList()
          ..sort((a, b) => a.migrationTimeSec.compareTo(b.migrationTimeSec));
    final resolutions = <ResolutionMetrics>[];
    for (var i = 0; i < sortedPeaks.length - 1; i++) {
      final left = sortedPeaks[i];
      final right = sortedPeaks[i + 1];
      final resolution =
          2 *
          (right.migrationTimeSec - left.migrationTimeSec).abs() /
          (left.baseWidthSec + right.baseWidthSec);
      resolutions.add(
        ResolutionMetrics(
          leftName: left.analyteName,
          rightName: right.analyteName,
          resolution: resolution,
        ),
      );
    }

    final conductance =
        config.bufferConductivitySm *
        config.crossSectionM2 /
        config.capillaryLengthM;
    final current = config.voltageVolts * conductance;
    final power = current * config.voltageVolts;
    final notes = <String>['模型使用一维对流-扩散方程的高斯解析解进行离散采样，适合教学演示迁移、扩散和检测峰形成。'];
    if (peaks.any((peak) => !peak.migrationTimeSec.isFinite)) {
      notes.add('存在净迁移速度小于等于 0 的组分，当前设置下该组分不会到达检测窗口。');
    }
    if (resolutions.any((item) => item.resolution < 1.5)) {
      notes.add('至少一组相邻峰分离度 Rs < 1.5，可尝试提高有效长度或调整电渗流/电压。');
    }
    if (power > 0.08) {
      notes.add('焦耳热偏高，真实实验中需要控制缓冲液电导率、毛细管内径或电压。');
    }

    return SimulationResult(
      config: config,
      points: points,
      snapshots: snapshots,
      peaks: peaks,
      resolutions: resolutions,
      currentAmp: current,
      powerWatt: power,
      riskLevel: _riskLevel(power),
      notes: notes,
    );
  }

  double _detectorSignal(
    CapillaryElectrophoresisConfig config,
    AnalyteSpec analyte,
    double timeSec,
  ) {
    return _spatialConcentration(
      config,
      analyte,
      timeSec,
      config.effectiveLengthM,
    );
  }

  double _spatialConcentration(
    CapillaryElectrophoresisConfig config,
    AnalyteSpec analyte,
    double timeSec,
    double positionM,
  ) {
    final velocity =
        (analyte.electrophoreticMobility + config.electroosmoticMobility) *
        config.electricFieldVm;
    final center = config.injectionSigmaM + velocity * timeSec;
    final sigma = math.sqrt(
      config.injectionSigmaM * config.injectionSigmaM +
          2 * analyte.diffusionCoefficient * math.max(timeSec, 0),
    );
    return _gaussianAt(positionM, center, sigma, analyte.relativeConcentration);
  }
}

double _gaussianAt(double x, double center, double sigma, double amplitude) {
  if (!sigma.isFinite || sigma <= 0) {
    return 0;
  }
  final normalized = (x - center) / sigma;
  return amplitude * math.exp(-0.5 * normalized * normalized) / sigma;
}

String _riskLevel(double powerWatt) {
  if (powerWatt < 0.03) {
    return '低';
  }
  if (powerWatt < 0.08) {
    return '中';
  }
  return '高';
}

double _asDouble(Object? value, {required double fallback}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}
