import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../experiments/experiment_package.dart';

class ExperimentEntry {
  const ExperimentEntry({
    required this.package,
    required this.isBuiltIn,
    this.sourcePath,
  });

  final ExperimentPackage package;
  final bool isBuiltIn;
  final String? sourcePath;
}

class ExperimentRepository {
  ExperimentRepository({
    ExperimentPackageParser? parser,
    this.persistenceEnabled = true,
  }) : _parser = parser ?? const ExperimentPackageParser();

  final ExperimentPackageParser _parser;
  final bool persistenceEnabled;
  final List<ExperimentEntry> _imported = [];

  List<ExperimentEntry> get all => [
    ExperimentEntry(
      package: builtInCapillaryElectrophoresis(),
      isBuiltIn: true,
    ),
    ..._imported,
  ];

  Future<void> loadImportedPackages() async {
    _imported.clear();
    if (!persistenceEnabled) {
      return;
    }
    late final Directory directory;
    try {
      directory = await _importDirectory();
    } catch (_) {
      return;
    }
    if (!directory.existsSync()) {
      return;
    }
    final files = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.pexp'))
        .toList();
    for (final file in files) {
      try {
        final package = _parser.parsePexp(await file.readAsBytes());
        _imported.add(
          ExperimentEntry(
            package: package,
            isBuiltIn: false,
            sourcePath: file.path,
          ),
        );
      } catch (_) {
        // Broken packages are ignored on startup; the import screen reports errors.
      }
    }
  }

  Future<ExperimentEntry> importPackage(Uint8List bytes) async {
    final package = _parser.parsePexp(bytes);
    String? sourcePath;
    if (persistenceEnabled) {
      final directory = await _importDirectory();
      await directory.create(recursive: true);
      final fileName = _safeFileName('${package.id}_${package.version}.pexp');
      final file = File(p.join(directory.path, fileName));
      await file.writeAsBytes(bytes, flush: true);
      sourcePath = file.path;
    }
    final entry = ExperimentEntry(
      package: package,
      isBuiltIn: false,
      sourcePath: sourcePath,
    );
    _imported.removeWhere((item) => item.package.id == package.id);
    _imported.add(entry);
    return entry;
  }

  Future<void> removeImported(ExperimentEntry entry) async {
    if (entry.isBuiltIn) {
      return;
    }
    _imported.removeWhere((item) => item.package.id == entry.package.id);
    final sourcePath = entry.sourcePath;
    if (sourcePath != null) {
      final file = File(sourcePath);
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

  Future<File> exportText({
    required String fileName,
    required String content,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory(p.join(directory.path, 'exports'));
    await exportDirectory.create(recursive: true);
    final file = File(p.join(exportDirectory.path, _safeFileName(fileName)));
    await file.writeAsString(content, flush: true);
    return file;
  }

  Future<Directory> _importDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return Directory(p.join(directory.path, 'imported_experiments'));
  }
}

ExperimentPackage builtInCapillaryElectrophoresis() {
  const manifest = {
    'schemaVersion': 1,
    'id': 'capillary_electrophoresis_drug_ions',
    'title': '电场微流：药物离子毛细管电泳虚拟仿真实验',
    'version': '1.0.0',
    'solverId': 'advection_diffusion_1d',
    'summary': '通过一维对流-扩散模型展示电泳迁移、电渗流、扩散展宽和药物离子分离，适合大学物理、物理化学与药学分析教学。',
    'authorLabel': '匿名参赛团队',
    'tags': ['自选题2', '虚拟仿真', '毛细管电泳', '药学物理实验'],
    'parameters': [
      {
        'id': 'voltageVolts',
        'label': '分离电压',
        'unit': 'V',
        'min': 5000,
        'max': 30000,
        'defaultValue': 15000,
        'description': '电压越高迁移越快，但焦耳热风险也会升高。',
      },
      {
        'id': 'capillaryLengthCm',
        'label': '毛细管总长',
        'unit': 'cm',
        'min': 30,
        'max': 80,
        'defaultValue': 50,
        'description': '总长决定电场强度和电阻。',
      },
      {
        'id': 'effectiveLengthCm',
        'label': '检测有效长度',
        'unit': 'cm',
        'min': 20,
        'max': 70,
        'defaultValue': 40,
        'description': '样品从入口到检测窗口的迁移距离。',
      },
      {
        'id': 'electroosmoticMobility',
        'label': '电渗迁移率',
        'unit': 'm2/(V s)',
        'min': 0.5e-8,
        'max': 6.0e-8,
        'defaultValue': 3.0e-8,
        'description': '体现毛细管壁面电荷和缓冲液 pH 对整体流动的影响。',
      },
      {
        'id': 'injectionWidthMm',
        'label': '进样区带宽度',
        'unit': 'mm',
        'min': 0.2,
        'max': 3.0,
        'defaultValue': 1.2,
        'description': '进样区越宽，检测峰越容易展宽。',
      },
    ],
    'presets': [
      {
        'name': '平衡分离',
        'description': '默认参数，三种组分均能到达检测窗口。',
        'values': {
          'voltageVolts': 15000,
          'effectiveLengthCm': 40,
          'electroosmoticMobility': 3.0e-8,
          'injectionWidthMm': 1.2,
        },
      },
      {
        'name': '快速但发热',
        'description': '提高电压观察迁移时间缩短和焦耳热风险。',
        'values': {
          'voltageVolts': 26000,
          'bufferConductivitySm': 0.12,
          'innerDiameterUm': 75,
        },
      },
      {
        'name': '高分辨率',
        'description': '增加有效长度并减小进样区带，观察峰分离改善。',
        'values': {
          'voltageVolts': 13000,
          'effectiveLengthCm': 55,
          'injectionWidthMm': 0.55,
        },
      },
    ],
    'references': [
      {
        'title':
            'Capillary Electrophoresis and Capillary Electrochromatography',
        'source': 'Chemistry LibreTexts',
        'url':
            'https://chem.libretexts.org/Courses/Sewanee%3A_The_University_of_the_South/Instrumental_Analysis_%28CHEM_311%29/10%3A_Chromatographic_and_Electrophoretic_Methods/10.05%3A_Capillary_Electrophoresis_and_Capillary_Electrochromatography/10.5.03%3A_Capillary_Electrophoresis',
      },
      {
        'title': 'Capillary electrophoresis in pharmaceutical analysis review',
        'source': 'RSC Analytical Methods, 2024',
        'url':
            'https://pubs.rsc.org/en/content/articlelanding/2024/ay/d4ay00860j/unauth',
      },
    ],
    'assets': [],
    'model': {
      'voltageVolts': 15000,
      'capillaryLengthCm': 50,
      'effectiveLengthCm': 40,
      'innerDiameterUm': 50,
      'electroosmoticMobility': 3.0e-8,
      'bufferViscosityMPaS': 1.0,
      'bufferConductivitySm': 0.08,
      'injectionWidthMm': 1.2,
      'temperatureC': 25,
      'analytes': [
        {
          'id': 'weak_acid',
          'name': '弱酸性药物 A',
          'colorHex': '#2563eb',
          'electrophoreticMobility': -1.2e-8,
          'diffusionCoefficient': 5.4e-10,
          'relativeConcentration': 1.0,
          'note': '电泳方向与电渗流相反，适合观察净迁移速度的叠加。',
        },
        {
          'id': 'basic_impurity',
          'name': '碱性杂质 B',
          'colorHex': '#d97706',
          'electrophoreticMobility': 1.6e-8,
          'diffusionCoefficient': 4.6e-10,
          'relativeConcentration': 0.62,
          'note': '正迁移率组分，模拟药物制剂中的带电杂质。',
        },
        {
          'id': 'neutral_marker',
          'name': '中性标记物 C',
          'colorHex': '#059669',
          'electrophoreticMobility': 0,
          'diffusionCoefficient': 4.0e-10,
          'relativeConcentration': 0.78,
          'note': '仅随电渗流迁移，可作为电渗流的教学参照。',
        },
      ],
    },
  };
  return ExperimentPackage.fromManifest(
    Map<String, Object?>.from(jsonDecode(jsonEncode(manifest)) as Map),
    lessonMarkdown: _builtInLesson,
    reportTemplate: _builtInReportTemplate,
  );
}

const _builtInLesson = '''
# 电场微流：药物离子毛细管电泳虚拟仿真实验

## 目标
观察电场强度、电渗流、扩散系数和进样宽度如何共同决定药物离子的迁移时间、峰宽和分离度。

## 物理模型
程序采用一维对流-扩散方程描述样品区带：

dc/dt + v dc/dx = D d2c/dx2

其中 v = (mu_ep + mu_eof) E，E = V / L。检测器信号由检测窗口处的浓度随时间变化给出。

## 教学任务
1. 增大电压，观察迁移时间和焦耳热风险。
2. 调整电渗迁移率，比较负迁移率药物与中性标记物的迁移顺序。
3. 减小进样区带宽度，观察峰宽和分离度变化。
4. 讨论真实实验中 pH、缓冲液浓度、毛细管内径和温控的限制。
''';

const _builtInReportTemplate = '''
# 仿真实验记录

## 参数
- 分离电压：
- 毛细管总长：
- 检测有效长度：
- 电渗迁移率：
- 进样区带宽度：

## 观察结果
- 各组分迁移时间：
- 峰宽与理论塔板数：
- 相邻峰分离度：
- 焦耳热风险：

## 分析
说明参数改变对迁移、扩散和分离度的影响，并指出模型局限。
''';

String _safeFileName(String input) {
  return input.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
}
