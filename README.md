# 物理实验竞赛虚仿平台

跨平台物理实验虚拟仿真平台。首个内置实验为“电场微流：药物离子毛细管电泳虚拟仿真实验”，面向全国大学生物理实验竞赛（创新）自选题2“教学资源和虚仿”方向。

## 功能

- 实验库：首页展示内置实验和导入实验。
- 实验详情：展示目标定位、物理原理、可调参数、预设场景和参考资料。
- 仿真工作台：实时调节毛细管电泳参数，可视化区带迁移、电泳图谱和定量指标。
- 实验包管理：导入 `.pexp` 内容包，为后续其他实验预留扩展接口。
- 数据导出：导出 CSV 信号表和 JSON 仿真配置。

## 首个竞赛实验

主题：电场微流：药物离子毛细管电泳虚拟仿真实验。

核心模型：

- 电场强度：`E = V / L`
- 净迁移速度：`v = (mu_ep + mu_eof) E`
- 一维对流-扩散：`dc/dt + v dc/dx = D d2c/dx2`

输出指标：

- 各组分迁移时间
- 峰宽
- 理论塔板数
- 相邻峰分离度
- 电流、功率和焦耳热风险

## 实验包接口

`.pexp` 是 zip 内容包，不包含可执行代码。v1 必须包含：

- `manifest.json`

可选包含：

- `lesson.md`
- `presets.json`
- `assets/`
- `report_template.md`
- `references.json`

当前支持的求解器：

- `advection_diffusion_1d`

示例包位于 `examples/sample_experiment_package`。

## 本地开发

```sh
flutter pub get
flutter test
flutter run -d macos
```

## 打包

macOS：

```sh
flutter build macos --release
./packaging/macos/create_dmg.sh
```

Android：

```sh
flutter build apk --release
flutter build appbundle --release
```

Windows 在 Windows 环境或 GitHub Actions 中构建：

```powershell
flutter build windows --release
iscc packaging/windows/installer.iss
```

## 竞赛合规

- 仓库和参赛材料不写入学校、指导教师、学生姓名等身份信息。
- 报告/PPT 应列出软件整体结构、自写代码、第三方依赖、参考文献和 AI 辅助内容。
- 本项目不会执行外部实验包中的任意代码，后续扩展通过“内容包 + 已注册求解器”完成。
