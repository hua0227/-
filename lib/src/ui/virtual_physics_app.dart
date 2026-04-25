import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../experiments/experiment_package.dart';
import '../repository/experiment_repository.dart';
import '../simulation/capillary_electrophoresis.dart';

class VirtualPhysicsApp extends StatefulWidget {
  const VirtualPhysicsApp({super.key, this.repository});

  final ExperimentRepository? repository;

  @override
  State<VirtualPhysicsApp> createState() => _VirtualPhysicsAppState();
}

class _VirtualPhysicsAppState extends State<VirtualPhysicsApp> {
  late final ExperimentRepository _repository;
  var _screen = _Screen.library;
  ExperimentEntry? _selected;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ExperimentRepository();
    _load();
  }

  Future<void> _load() async {
    await _repository.loadImportedPackages();
    if (!mounted) {
      return;
    }
    setState(() {
      _selected = _repository.all.first;
      _isLoading = false;
    });
  }

  void _select(ExperimentEntry entry, _Screen screen) {
    setState(() {
      _selected = entry;
      _screen = screen;
    });
  }

  Future<void> _importPackage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pexp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.single;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) {
      _showMessage('无法读取实验包内容。');
      return;
    }
    try {
      final entry = await _repository.importPackage(bytes);
      if (!mounted) {
        return;
      }
      setState(() {
        _selected = entry;
        _screen = _Screen.detail;
      });
      _showMessage('已导入：${entry.package.title}');
    } catch (error) {
      _showMessage('导入失败：$error');
    }
  }

  Future<void> _removeImported(ExperimentEntry entry) async {
    await _repository.removeImported(entry);
    if (!mounted) {
      return;
    }
    setState(() {
      _selected = _repository.all.first;
    });
    _showMessage('已移除实验包。');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '物理实验竞赛虚仿平台',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0f766e),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff7f8fa),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: Color(0xffe1e6eb)),
          ),
        ),
      ),
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 980;
                final content = _MainContent(
                  screen: _screen,
                  selected: _selected ?? _repository.all.first,
                  entries: _repository.all,
                  repository: _repository,
                  onSelect: _select,
                  onImport: _importPackage,
                  onRemove: _removeImported,
                  onMessage: _showMessage,
                );
                if (isWide) {
                  return Scaffold(
                    body: Row(
                      children: [
                        _AppRail(
                          screen: _screen,
                          onChanged: (screen) =>
                              setState(() => _screen = screen),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: content),
                      ],
                    ),
                  );
                }
                return Scaffold(
                  body: content,
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: _screen.index,
                    onDestinationSelected: (index) {
                      setState(() => _screen = _Screen.values[index]);
                    },
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.science_outlined),
                        selectedIcon: Icon(Icons.science),
                        label: '实验库',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.article_outlined),
                        selectedIcon: Icon(Icons.article),
                        label: '详情',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.show_chart),
                        selectedIcon: Icon(Icons.show_chart),
                        label: '仿真',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.inventory_2_outlined),
                        selectedIcon: Icon(Icons.inventory_2),
                        label: '实验包',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

enum _Screen { library, detail, workbench, packages }

class _AppRail extends StatelessWidget {
  const _AppRail({required this.screen, required this.onChanged});

  final _Screen screen;
  final ValueChanged<_Screen> onChanged;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: screen.index,
      onDestinationSelected: (index) => onChanged(_Screen.values[index]),
      labelType: NavigationRailLabelType.all,
      minWidth: 92,
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Icon(Icons.hub_outlined, size: 30),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.science_outlined),
          selectedIcon: Icon(Icons.science),
          label: Text('实验库'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.article_outlined),
          selectedIcon: Icon(Icons.article),
          label: Text('详情'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.show_chart),
          selectedIcon: Icon(Icons.show_chart),
          label: Text('仿真'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: Text('实验包'),
        ),
      ],
    );
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent({
    required this.screen,
    required this.selected,
    required this.entries,
    required this.repository,
    required this.onSelect,
    required this.onImport,
    required this.onRemove,
    required this.onMessage,
  });

  final _Screen screen;
  final ExperimentEntry selected;
  final List<ExperimentEntry> entries;
  final ExperimentRepository repository;
  final void Function(ExperimentEntry entry, _Screen screen) onSelect;
  final VoidCallback onImport;
  final Future<void> Function(ExperimentEntry entry) onRemove;
  final ValueChanged<String> onMessage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: switch (screen) {
        _Screen.library => _LibraryScreen(
          entries: entries,
          selected: selected,
          onSelect: (entry) => onSelect(entry, _Screen.detail),
          onOpenWorkbench: (entry) => onSelect(entry, _Screen.workbench),
          onImport: onImport,
        ),
        _Screen.detail => _ExperimentDetailScreen(
          entry: selected,
          onOpenWorkbench: () => onSelect(selected, _Screen.workbench),
        ),
        _Screen.workbench => _WorkbenchScreen(
          key: ValueKey(selected.package.id),
          entry: selected,
          repository: repository,
          onMessage: onMessage,
        ),
        _Screen.packages => _PackageManagerScreen(
          entries: entries,
          onImport: onImport,
          onRemove: onRemove,
          onSelect: (entry) => onSelect(entry, _Screen.detail),
        ),
      },
    );
  }
}

class _PageShell extends StatelessWidget {
  const _PageShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            runSpacing: 12,
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _LibraryScreen extends StatelessWidget {
  const _LibraryScreen({
    required this.entries,
    required this.selected,
    required this.onSelect,
    required this.onOpenWorkbench,
    required this.onImport,
  });

  final List<ExperimentEntry> entries;
  final ExperimentEntry selected;
  final ValueChanged<ExperimentEntry> onSelect;
  final ValueChanged<ExperimentEntry> onOpenWorkbench;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      title: '物理实验虚仿平台',
      subtitle: '内置毛细管电泳竞赛实验，并为后续光学、力学、热学、电磁学等实验包预留入口。',
      trailing: FilledButton.icon(
        onPressed: onImport,
        icon: const Icon(Icons.upload_file),
        label: const Text('导入 .pexp'),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 1180
              ? 3
              : constraints.maxWidth > 760
              ? 2
              : 1;
          return GridView.builder(
            itemCount: entries.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 244,
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _ExperimentCard(
                entry: entry,
                isSelected: entry.package.id == selected.package.id,
                onSelect: () => onSelect(entry),
                onOpenWorkbench: () => onOpenWorkbench(entry),
              );
            },
          );
        },
      ),
    );
  }
}

class _ExperimentCard extends StatelessWidget {
  const _ExperimentCard({
    required this.entry,
    required this.isSelected,
    required this.onSelect,
    required this.onOpenWorkbench,
  });

  final ExperimentEntry entry;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onOpenWorkbench;

  @override
  Widget build(BuildContext context) {
    final package = entry.package;
    return Card(
      color: isSelected ? const Color(0xffedfdf8) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    entry.isBuiltIn ? Icons.verified_outlined : Icons.extension,
                    color: entry.isBuiltIn
                        ? const Color(0xff0f766e)
                        : const Color(0xff7c3aed),
                  ),
                  const SizedBox(width: 8),
                  Text(entry.isBuiltIn ? '内置实验' : '导入实验'),
                  const Spacer(),
                  Text('v${package.version}'),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                package.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  package.summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: package.tags
                    .take(3)
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onOpenWorkbench,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('运行'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExperimentDetailScreen extends StatelessWidget {
  const _ExperimentDetailScreen({
    required this.entry,
    required this.onOpenWorkbench,
  });

  final ExperimentEntry entry;
  final VoidCallback onOpenWorkbench;

  @override
  Widget build(BuildContext context) {
    final package = entry.package;
    return _PageShell(
      title: package.title,
      subtitle: package.summary,
      trailing: FilledButton.icon(
        onPressed: onOpenWorkbench,
        icon: const Icon(Icons.play_circle),
        label: const Text('进入仿真'),
      ),
      child: ListView(
        children: [
          _InfoBand(
            children: [
              _InfoTile(label: '求解器', value: package.solverId),
              _InfoTile(label: '版本', value: package.version),
              _InfoTile(label: '来源', value: entry.isBuiltIn ? '内置' : '导入'),
              _InfoTile(label: '作者标识', value: package.authorLabel),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: '教学目标与原理',
            child: SelectableText(
              package.lessonMarkdown.isEmpty
                  ? '该实验包未提供 lesson.md。'
                  : package.lessonMarkdown,
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: '可调参数',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: package.parameters.map((parameter) {
                return _ParameterChip(parameter: parameter);
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: '预设场景',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: package.presets
                  .map(
                    (preset) => Chip(
                      avatar: const Icon(Icons.tune, size: 18),
                      label: Text(preset.name),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: '参考资料',
            child: Column(
              children: package.references.map((reference) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link),
                  title: Text(reference.title),
                  subtitle: Text(reference.source),
                  trailing: reference.url.isEmpty
                      ? null
                      : const Icon(Icons.open_in_new),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkbenchScreen extends StatefulWidget {
  const _WorkbenchScreen({
    super.key,
    required this.entry,
    required this.repository,
    required this.onMessage,
  });

  final ExperimentEntry entry;
  final ExperimentRepository repository;
  final ValueChanged<String> onMessage;

  @override
  State<_WorkbenchScreen> createState() => _WorkbenchScreenState();
}

class _WorkbenchScreenState extends State<_WorkbenchScreen> {
  final _solver = const CapillaryElectrophoresisSolver();
  Timer? _timer;
  late CapillaryElectrophoresisConfig _config;
  late SimulationResult _result;
  var _snapshotIndex = 0;

  @override
  void initState() {
    super.initState();
    _resetFromPackage();
    _timer = Timer.periodic(const Duration(milliseconds: 520), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshotIndex = (_snapshotIndex + 1) % _result.snapshots.length;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _WorkbenchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.package.id != widget.entry.package.id) {
      _resetFromPackage();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetFromPackage() {
    _config = CapillaryElectrophoresisConfig.fromModelJson(
      widget.entry.package.model,
    );
    _result = _solver.run(_config);
    _snapshotIndex = 0;
  }

  void _update(CapillaryElectrophoresisConfig config) {
    setState(() {
      _config = config;
      _result = _solver.run(_config);
      _snapshotIndex = math.min(_snapshotIndex, _result.snapshots.length - 1);
    });
  }

  Future<void> _exportCsv() async {
    final file = await widget.repository.exportText(
      fileName: '${widget.entry.package.id}_signals.csv',
      content: _result.toCsv(),
    );
    await Clipboard.setData(ClipboardData(text: file.path));
    widget.onMessage('CSV 已导出，路径已复制：${file.path}');
  }

  Future<void> _exportJson() async {
    final file = await widget.repository.exportText(
      fileName: '${widget.entry.package.id}_config.json',
      content: _config.toPrettyJson(),
    );
    await Clipboard.setData(ClipboardData(text: file.path));
    widget.onMessage('配置 JSON 已导出，路径已复制：${file.path}');
  }

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      title: '仿真工作台',
      subtitle: widget.entry.package.title,
      trailing: Wrap(
        spacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: _exportJson,
            icon: const Icon(Icons.data_object),
            label: const Text('导出 JSON'),
          ),
          FilledButton.icon(
            onPressed: _exportCsv,
            icon: const Icon(Icons.table_chart),
            label: const Text('导出 CSV'),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1050;
          final controls = _ParameterPanel(config: _config, onChanged: _update);
          final visual = _SimulationVisuals(
            result: _result,
            snapshotIndex: _snapshotIndex,
          );
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 360, child: controls),
                const SizedBox(width: 18),
                Expanded(child: visual),
              ],
            );
          }
          return ListView(
            children: [
              controls,
              const SizedBox(height: 16),
              SizedBox(height: 720, child: visual),
            ],
          );
        },
      ),
    );
  }
}

class _ParameterPanel extends StatelessWidget {
  const _ParameterPanel({required this.config, required this.onChanged});

  final CapillaryElectrophoresisConfig config;
  final ValueChanged<CapillaryElectrophoresisConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _Section(
          title: '实验参数',
          child: Column(
            children: [
              _SliderField(
                label: '分离电压',
                value: config.voltageVolts,
                min: 5000,
                max: 30000,
                divisions: 50,
                unit: 'V',
                onChanged: (value) =>
                    onChanged(config.copyWith(voltageVolts: value)),
              ),
              _SliderField(
                label: '毛细管总长',
                value: config.capillaryLengthCm,
                min: 30,
                max: 80,
                divisions: 50,
                unit: 'cm',
                onChanged: (value) =>
                    onChanged(config.copyWith(capillaryLengthCm: value)),
              ),
              _SliderField(
                label: '检测有效长度',
                value: config.effectiveLengthCm,
                min: 20,
                max: math.max(21, config.capillaryLengthCm - 2),
                divisions: 50,
                unit: 'cm',
                onChanged: (value) =>
                    onChanged(config.copyWith(effectiveLengthCm: value)),
              ),
              _SliderField(
                label: '毛细管内径',
                value: config.innerDiameterUm,
                min: 25,
                max: 100,
                divisions: 30,
                unit: 'um',
                onChanged: (value) =>
                    onChanged(config.copyWith(innerDiameterUm: value)),
              ),
              _SliderField(
                label: '电渗迁移率',
                value: config.electroosmoticMobility * 1e8,
                min: 0.5,
                max: 6,
                divisions: 55,
                unit: 'x10^-8',
                onChanged: (value) => onChanged(
                  config.copyWith(electroosmoticMobility: value * 1e-8),
                ),
              ),
              _SliderField(
                label: '进样区带宽度',
                value: config.injectionWidthMm,
                min: 0.2,
                max: 3,
                divisions: 56,
                unit: 'mm',
                onChanged: (value) =>
                    onChanged(config.copyWith(injectionWidthMm: value)),
              ),
              _SliderField(
                label: '缓冲液电导率',
                value: config.bufferConductivitySm,
                min: 0.02,
                max: 0.2,
                divisions: 36,
                unit: 'S/m',
                onChanged: (value) =>
                    onChanged(config.copyWith(bufferConductivitySm: value)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Section(
          title: '药物/杂质迁移率',
          child: Column(
            children: config.analytes.map((analyte) {
              return _SliderField(
                label: analyte.name,
                value: analyte.electrophoreticMobility * 1e8,
                min: -3,
                max: 3,
                divisions: 60,
                unit: 'x10^-8',
                onChanged: (value) {
                  final nextAnalytes = config.analytes.map((item) {
                    if (item.id != analyte.id) {
                      return item;
                    }
                    return item.copyWith(electrophoreticMobility: value * 1e-8);
                  }).toList();
                  onChanged(config.copyWith(analytes: nextAnalytes));
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SimulationVisuals extends StatelessWidget {
  const _SimulationVisuals({required this.result, required this.snapshotIndex});

  final SimulationResult result;
  final int snapshotIndex;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _InfoBand(
          children: [
            _InfoTile(
              label: '电场强度',
              value: '${result.config.electricFieldVm.toStringAsFixed(0)} V/m',
            ),
            _InfoTile(
              label: '电流',
              value: '${(result.currentAmp * 1e6).toStringAsFixed(2)} uA',
            ),
            _InfoTile(label: '焦耳热风险', value: result.riskLevel),
            _InfoTile(
              label: '功率',
              value: '${(result.powerWatt * 1000).toStringAsFixed(2)} mW',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: '毛细管区带迁移',
          child: SizedBox(
            height: 210,
            child: CustomPaint(
              painter: _CapillaryPainter(
                result: result,
                snapshotIndex: snapshotIndex,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '检测器电泳图谱',
          child: SizedBox(
            height: 260,
            child: CustomPaint(
              painter: _ElectropherogramPainter(result: result),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '定量结果',
          child: _MetricsTable(result: result),
        ),
        const SizedBox(height: 16),
        _Section(
          title: '合理性与局限',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: result.notes
                .map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(note)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _MetricsTable extends StatelessWidget {
  const _MetricsTable({required this.result});

  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('组分')),
              DataColumn(label: Text('迁移时间/s')),
              DataColumn(label: Text('峰宽/s')),
              DataColumn(label: Text('理论塔板数')),
              DataColumn(label: Text('速度/mm/s')),
            ],
            rows: result.peaks.map((peak) {
              return DataRow(
                cells: [
                  DataCell(Text(peak.analyteName)),
                  DataCell(Text(_fmt(peak.migrationTimeSec))),
                  DataCell(Text(_fmt(peak.baseWidthSec))),
                  DataCell(Text(peak.theoreticalPlates.toStringAsFixed(0))),
                  DataCell(Text((peak.velocityMs * 1000).toStringAsFixed(3))),
                ],
              );
            }).toList(),
          ),
        ),
        if (result.resolutions.isNotEmpty) const Divider(height: 24),
        ...result.resolutions.map((item) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.compare_arrows),
            title: Text('${item.leftName} / ${item.rightName}'),
            trailing: Text('Rs ${item.resolution.toStringAsFixed(2)}'),
          );
        }),
      ],
    );
  }
}

class _PackageManagerScreen extends StatelessWidget {
  const _PackageManagerScreen({
    required this.entries,
    required this.onImport,
    required this.onRemove,
    required this.onSelect,
  });

  final List<ExperimentEntry> entries;
  final VoidCallback onImport;
  final Future<void> Function(ExperimentEntry entry) onRemove;
  final ValueChanged<ExperimentEntry> onSelect;

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      title: '实验包管理',
      subtitle: '.pexp 是 zip 格式内容包，可携带 manifest、教学文本、预设、资源和报告模板。',
      trailing: FilledButton.icon(
        onPressed: onImport,
        icon: const Icon(Icons.upload_file),
        label: const Text('导入实验包'),
      ),
      child: ListView.separated(
        itemCount: entries.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Card(
            child: ListTile(
              leading: Icon(
                entry.isBuiltIn ? Icons.lock_outline : Icons.extension,
              ),
              title: Text(entry.package.title),
              subtitle: Text(
                '${entry.package.solverId} · v${entry.package.version} · ${entry.isBuiltIn ? '内置' : entry.sourcePath ?? '导入'}',
              ),
              onTap: () => onSelect(entry),
              trailing: entry.isBuiltIn
                  ? const Icon(Icons.verified_outlined)
                  : IconButton(
                      tooltip: '移除',
                      onPressed: () => onRemove(entry),
                      icon: const Icon(Icons.delete_outline),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoBand extends StatelessWidget {
  const _InfoBand({required this.children});

  final List<_InfoTile> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 10, runSpacing: 10, children: children);
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffe1e6eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ParameterChip extends StatelessWidget {
  const _ParameterChip({required this.parameter});

  final ExperimentParameter parameter;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: parameter.description,
      child: Chip(
        label: Text(
          '${parameter.label} ${parameter.min.g}-${parameter.max.g} ${parameter.unit}',
        ),
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String unit;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(min, max).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('${safeValue.toStringAsPrecision(3)} $unit'),
            ],
          ),
          Slider(
            value: safeValue,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _CapillaryPainter extends CustomPainter {
  const _CapillaryPainter({required this.result, required this.snapshotIndex});

  final SimulationResult result;
  final int snapshotIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final snapshot = result.snapshots[snapshotIndex % result.snapshots.length];
    final axis = Rect.fromLTWH(30, size.height * 0.42, size.width - 60, 30);
    final tubePaint = Paint()
      ..color = const Color(0xffdbeafe)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xff64748b)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(axis, const Radius.circular(15)),
      tubePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(axis, const Radius.circular(15)),
      borderPaint,
    );

    final detectorX =
        axis.left +
        axis.width *
            result.config.effectiveLengthM /
            result.config.capillaryLengthM;
    final detectorPaint = Paint()
      ..color = const Color(0xff111827)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(detectorX, axis.top - 28),
      Offset(detectorX, axis.bottom + 28),
      detectorPaint,
    );
    _drawText(canvas, '检测窗口', Offset(detectorX - 28, axis.top - 48), 12);
    _drawText(
      canvas,
      't = ${snapshot.timeSec.toStringAsFixed(1)} s',
      Offset(axis.left, axis.bottom + 34),
      13,
    );

    for (final analyte in result.config.analytes) {
      final profile = snapshot.profiles[analyte.id] ?? const <double>[];
      if (profile.isEmpty) {
        continue;
      }
      final maxProfile = profile.reduce(math.max);
      if (maxProfile <= 0) {
        continue;
      }
      final path = Path();
      for (var i = 0; i < profile.length; i++) {
        final x = axis.left + axis.width * i / (profile.length - 1);
        final y = axis.center.dy - 42 * profile[i] / maxProfile;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      final paint = Paint()
        ..color = _colorFromHex(analyte.colorHex)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }

    var legendY = 14.0;
    for (final analyte in result.config.analytes) {
      final color = _colorFromHex(analyte.colorHex);
      canvas.drawCircle(
        Offset(size.width - 180, legendY + 7),
        5,
        Paint()..color = color,
      );
      _drawText(canvas, analyte.name, Offset(size.width - 168, legendY), 12);
      legendY += 20;
    }
  }

  @override
  bool shouldRepaint(covariant _CapillaryPainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.snapshotIndex != snapshotIndex;
  }
}

class _ElectropherogramPainter extends CustomPainter {
  const _ElectropherogramPainter({required this.result});

  final SimulationResult result;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(48, 22, size.width - 70, size.height - 58);
    final axisPaint = Paint()
      ..color = const Color(0xff374151)
      ..strokeWidth = 1.3;
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axisPaint);
    canvas.drawLine(plot.bottomLeft, plot.topLeft, axisPaint);
    _drawText(
      canvas,
      '时间 / s',
      Offset(plot.center.dx - 28, size.height - 24),
      12,
    );
    _drawText(canvas, '信号', Offset(10, plot.top + 4), 12);

    final maxSignal = math.max(result.maxSignal, 1);
    for (final analyte in result.config.analytes) {
      final path = Path();
      for (var i = 0; i < result.points.length; i++) {
        final point = result.points[i];
        final x = plot.left + plot.width * i / (result.points.length - 1);
        final signal = point.analyteSignals[analyte.id] ?? 0;
        final y = plot.bottom - plot.height * signal / maxSignal;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = _colorFromHex(analyte.colorHex)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    final totalPath = Path();
    for (var i = 0; i < result.points.length; i++) {
      final point = result.points[i];
      final x = plot.left + plot.width * i / (result.points.length - 1);
      final y = plot.bottom - plot.height * point.totalSignal / maxSignal;
      if (i == 0) {
        totalPath.moveTo(x, y);
      } else {
        totalPath.lineTo(x, y);
      }
    }
    canvas.drawPath(
      totalPath,
      Paint()
        ..color = const Color(0xff111827)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    final lastTime = result.points.last.timeSec;
    for (var i = 0; i <= 4; i++) {
      final x = plot.left + plot.width * i / 4;
      final label = (lastTime * i / 4).toStringAsFixed(0);
      _drawText(canvas, label, Offset(x - 10, plot.bottom + 8), 11);
    }
  }

  @override
  bool shouldRepaint(covariant _ElectropherogramPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}

void _drawText(Canvas canvas, String text, Offset offset, double fontSize) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: const Color(0xff111827), fontSize: fontSize),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 210);
  painter.paint(canvas, offset);
}

Color _colorFromHex(String hex) {
  final normalized = hex.replaceFirst('#', '');
  final value = int.tryParse(
    normalized.length == 6 ? 'ff$normalized' : normalized,
    radix: 16,
  );
  return Color(value ?? 0xff2563eb);
}

String _fmt(double value) {
  if (!value.isFinite) {
    return '未到达';
  }
  if (value.abs() >= 100) {
    return value.toStringAsFixed(1);
  }
  return value.toStringAsFixed(2);
}

extension _CompactDouble on double {
  String get g {
    if ((abs() >= 100 || abs() < 0.01) && this != 0) {
      return toStringAsExponential(1);
    }
    return toStringAsPrecision(3);
  }
}
