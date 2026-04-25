# .pexp 实验包规范 v1

`.pexp` 是 zip 文件。平台只读取内容，不执行外部代码。

## 必需文件

`manifest.json`

```json
{
  "schemaVersion": 1,
  "id": "experiment_id",
  "title": "实验名称",
  "version": "0.1.0",
  "solverId": "advection_diffusion_1d",
  "summary": "实验简介",
  "authorLabel": "匿名作者",
  "tags": ["虚拟仿真"],
  "parameters": [],
  "presets": [],
  "references": [],
  "assets": [],
  "model": {}
}
```

## 可选文件

- `lesson.md`：教学目标、原理和任务。
- `report_template.md`：实验报告模板。
- `assets/`：图片、数据表等资源。
- `references.json`：外部参考资料。

## 求解器

v1 内置 `advection_diffusion_1d`。该求解器接受毛细管电泳参数和分析物列表，输出迁移过程、检测器图谱和峰参数。

后续新增实验时，优先新增平台内注册求解器，再用 `.pexp` 提供参数、预设和教学材料。
