import 'package:flutter_test/flutter_test.dart';
import 'package:physics_experiment_platform/src/simulation/capillary_electrophoresis.dart';

void main() {
  test('solver returns finite peaks and signal traces', () {
    final config = CapillaryElectrophoresisConfig.defaults();
    final result = const CapillaryElectrophoresisSolver().run(config);

    expect(result.points, hasLength(280));
    expect(result.snapshots, hasLength(18));
    expect(result.peaks, hasLength(config.analytes.length));
    expect(
      result.peaks.every((peak) => peak.migrationTimeSec.isFinite),
      isTrue,
    );
    expect(result.maxSignal, greaterThan(0));
  });

  test('higher voltage shortens migration time for reachable analytes', () {
    final solver = const CapillaryElectrophoresisSolver();
    final base = CapillaryElectrophoresisConfig.defaults();
    final faster = base.copyWith(voltageVolts: base.voltageVolts * 1.6);

    final baseResult = solver.run(base);
    final fasterResult = solver.run(faster);

    for (var i = 0; i < base.analytes.length; i++) {
      expect(
        fasterResult.peaks[i].migrationTimeSec,
        lessThan(baseResult.peaks[i].migrationTimeSec),
      );
    }
  });

  test('narrower injection band improves theoretical plates', () {
    final solver = const CapillaryElectrophoresisSolver();
    final wide = CapillaryElectrophoresisConfig.defaults().copyWith(
      injectionWidthMm: 2.4,
    );
    final narrow = wide.copyWith(injectionWidthMm: 0.4);

    final wideResult = solver.run(wide);
    final narrowResult = solver.run(narrow);

    expect(
      narrowResult.peaks.first.theoreticalPlates,
      greaterThan(wideResult.peaks.first.theoreticalPlates),
    );
  });
}
