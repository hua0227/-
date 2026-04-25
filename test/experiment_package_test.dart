import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_experiment_platform/src/experiments/experiment_package.dart';

void main() {
  test('parses and validates a pexp package', () {
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'manifest.json',
          jsonEncode({
            'schemaVersion': 1,
            'id': 'demo',
            'title': '示例实验',
            'version': '0.1.0',
            'solverId': 'advection_diffusion_1d',
            'summary': '用于测试的实验包。',
            'authorLabel': '匿名',
            'model': {
              'voltageVolts': 12000,
              'analytes': [
                {
                  'id': 'a',
                  'name': '组分 A',
                  'colorHex': '#2563eb',
                  'electrophoreticMobility': 1.1e-8,
                  'diffusionCoefficient': 4.0e-10,
                  'relativeConcentration': 1.0,
                },
              ],
            },
          }),
        ),
      )
      ..addFile(ArchiveFile.string('lesson.md', '# 示例'));

    final bytes = ZipEncoder().encodeBytes(archive);
    final package = const ExperimentPackageParser().parsePexp(bytes);

    expect(package.id, 'demo');
    expect(package.solverId, 'advection_diffusion_1d');
    expect(package.lessonMarkdown, contains('示例'));
  });

  test('rejects unsupported solvers', () {
    final parser = const ExperimentPackageParser();
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'manifest.json',
          jsonEncode({
            'schemaVersion': 1,
            'id': 'bad',
            'title': '不支持实验',
            'version': '0.1.0',
            'solverId': 'external_code',
            'model': {'voltageVolts': 12000},
          }),
        ),
      );
    final bytes = ZipEncoder().encodeBytes(archive);

    expect(() => parser.parsePexp(bytes), throwsFormatException);
  });
}
