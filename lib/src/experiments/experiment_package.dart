import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

class ExperimentParameter {
  const ExperimentParameter({
    required this.id,
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.description,
  });

  final String id;
  final String label;
  final String unit;
  final double min;
  final double max;
  final double defaultValue;
  final String description;

  factory ExperimentParameter.fromJson(Map<String, Object?> json) {
    return ExperimentParameter(
      id: json['id'] as String? ?? 'parameter',
      label: json['label'] as String? ?? '参数',
      unit: json['unit'] as String? ?? '',
      min: _asDouble(json['min'], fallback: 0),
      max: _asDouble(json['max'], fallback: 1),
      defaultValue: _asDouble(json['defaultValue'], fallback: 0),
      description: json['description'] as String? ?? '',
    );
  }
}

class ExperimentPreset {
  const ExperimentPreset({
    required this.name,
    required this.description,
    required this.values,
  });

  final String name;
  final String description;
  final Map<String, Object?> values;

  factory ExperimentPreset.fromJson(Map<String, Object?> json) {
    final rawValues = json['values'];
    return ExperimentPreset(
      name: json['name'] as String? ?? '预设',
      description: json['description'] as String? ?? '',
      values: rawValues is Map ? Map<String, Object?>.from(rawValues) : {},
    );
  }
}

class ExperimentReference {
  const ExperimentReference({
    required this.title,
    required this.source,
    required this.url,
  });

  final String title;
  final String source;
  final String url;

  factory ExperimentReference.fromJson(Map<String, Object?> json) {
    return ExperimentReference(
      title: json['title'] as String? ?? '参考资料',
      source: json['source'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}

class ExperimentPackage {
  const ExperimentPackage({
    required this.schemaVersion,
    required this.id,
    required this.title,
    required this.version,
    required this.solverId,
    required this.summary,
    required this.authorLabel,
    required this.tags,
    required this.parameters,
    required this.presets,
    required this.references,
    required this.model,
    required this.lessonMarkdown,
    required this.reportTemplate,
    required this.assetNames,
  });

  final int schemaVersion;
  final String id;
  final String title;
  final String version;
  final String solverId;
  final String summary;
  final String authorLabel;
  final List<String> tags;
  final List<ExperimentParameter> parameters;
  final List<ExperimentPreset> presets;
  final List<ExperimentReference> references;
  final Map<String, Object?> model;
  final String lessonMarkdown;
  final String reportTemplate;
  final List<String> assetNames;

  factory ExperimentPackage.fromManifest(
    Map<String, Object?> manifest, {
    String lessonMarkdown = '',
    String reportTemplate = '',
  }) {
    final parametersJson = manifest['parameters'];
    final presetsJson = manifest['presets'];
    final referencesJson = manifest['references'];
    final tagsJson = manifest['tags'];
    final assetsJson = manifest['assets'];
    final modelJson = manifest['model'];
    return ExperimentPackage(
      schemaVersion: (manifest['schemaVersion'] as num?)?.toInt() ?? 1,
      id: manifest['id'] as String? ?? 'experiment',
      title: manifest['title'] as String? ?? '未命名实验',
      version: manifest['version'] as String? ?? '0.1.0',
      solverId: manifest['solverId'] as String? ?? '',
      summary: manifest['summary'] as String? ?? '',
      authorLabel: manifest['authorLabel'] as String? ?? '匿名开发者',
      tags: tagsJson is List ? tagsJson.whereType<String>().toList() : const [],
      parameters: parametersJson is List
          ? parametersJson
                .whereType<Map>()
                .map(
                  (item) => ExperimentParameter.fromJson(
                    Map<String, Object?>.from(item),
                  ),
                )
                .toList()
          : const [],
      presets: presetsJson is List
          ? presetsJson
                .whereType<Map>()
                .map(
                  (item) => ExperimentPreset.fromJson(
                    Map<String, Object?>.from(item),
                  ),
                )
                .toList()
          : const [],
      references: referencesJson is List
          ? referencesJson
                .whereType<Map>()
                .map(
                  (item) => ExperimentReference.fromJson(
                    Map<String, Object?>.from(item),
                  ),
                )
                .toList()
          : const [],
      model: modelJson is Map ? Map<String, Object?>.from(modelJson) : {},
      lessonMarkdown: lessonMarkdown,
      reportTemplate: reportTemplate,
      assetNames: assetsJson is List
          ? assetsJson.whereType<String>().toList()
          : const [],
    );
  }

  List<String> validate() {
    final errors = <String>[];
    if (schemaVersion != 1) {
      errors.add('仅支持 schemaVersion = 1 的实验包。');
    }
    if (id.trim().isEmpty) {
      errors.add('manifest.json 缺少 id。');
    }
    if (title.trim().isEmpty) {
      errors.add('manifest.json 缺少 title。');
    }
    if (solverId != 'advection_diffusion_1d') {
      errors.add('当前版本仅支持 solverId = advection_diffusion_1d。');
    }
    if (model.isEmpty) {
      errors.add('manifest.json 缺少 model，无法运行仿真。');
    }
    return errors;
  }
}

class ExperimentPackageParser {
  const ExperimentPackageParser();

  ExperimentPackage parseManifestText(String manifestText) {
    final decoded = jsonDecode(manifestText);
    if (decoded is! Map) {
      throw const FormatException('manifest.json 必须是 JSON 对象。');
    }
    return ExperimentPackage.fromManifest(Map<String, Object?>.from(decoded));
  }

  ExperimentPackage parsePexp(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    String? readText(String name) {
      final file = archive.findFile(name);
      if (file == null || !file.isFile) {
        return null;
      }
      return utf8.decode(file.readBytes() ?? const []);
    }

    final manifestText = readText('manifest.json');
    if (manifestText == null) {
      throw const FormatException('实验包缺少 manifest.json。');
    }
    final decoded = jsonDecode(manifestText);
    if (decoded is! Map) {
      throw const FormatException('manifest.json 必须是 JSON 对象。');
    }
    final package = ExperimentPackage.fromManifest(
      Map<String, Object?>.from(decoded),
      lessonMarkdown: readText('lesson.md') ?? '',
      reportTemplate: readText('report_template.md') ?? '',
    );
    final errors = package.validate();
    if (errors.isNotEmpty) {
      throw FormatException(errors.join('\n'));
    }
    return package;
  }
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
