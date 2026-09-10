# Opus 5 × Astra 对照实验

本目录用于保存 Opus 5（CodeBuddy）复现实验的输入、基线、记录、验收结果与截图。

## 实验范围

仅覆盖原综合报告的第 05—08 部分，与 Astra 结果对照：

| 实验 | 名称 | 对应工程 |
| --- | --- | --- |
| 05 | 策划需求理解 | 地球盲盒考古/考古刮地皮 |
| 06 | 策划到可玩原型 | 地球盲盒考古/考古刮地皮 |
| 07 | 界面布局与复杂展示（议价、库存、手机商品页面） | blind-box-market |
| 08 | 现有美术资源组合（主菜单、物品展示面板） | blind-box-market |

**明确排除**：原报告 01—04 的 3D 建模内容；不执行 Blender 建模、Computer Use 建模、Visvise 对比；不为此实验新建或修改 3D 资产。

## 全局基线

- 原仓库：`C:\Users\ruohaojing\Desktop\爽开`
- 实验 worktree：`C:\Users\ruohaojing\Desktop\爽开-opus5-reproduction`
- 实验分支：`experiment/opus5-reproduction`
- 基线 commit：`1d66a79de054a80e0f3e8b11a64fe4f4a2141247`（docs: add combined evaluation report and captures）
- 不 push、不合并 main；只在独立 worktree 内执行。

## 模型要求

- 本次策划、编码、调试、修订必须使用 CodeBuddy 中的 **Opus 5**。
- 模型名称以 CodeBuddy 界面实际显示为准，并记录到各实验 `baseline.md`。
- 不得仅凭提示词声称使用 Opus 5；运行中发生模型切换需记录切换位置，受影响结果不计入纯 Opus 5 结果。
- 当前模型确认状态：**待用户在 CodeBuddy 界面确认**。

## 目录结构

```
experiments/opus5/
├── README.md
├── _templates/            # 记录模板（brief/baseline/decisions/run-log/acceptance）
├── 05_策划需求理解/
├── 06_策划到可玩原型/
├── 07_界面布局与复杂展示/
└── 08_现有美术资源组合/
```

每个实验目录包含：`brief.md`、`baseline.md`、`decisions.md`、`run-log.md`、`acceptance.md` 与 `captures/round-0`、`captures/round-1`、`captures/round-2`。

## 工程内实验目录

两个 Godot 工程内各建有 `experiments/opus5/`，用于保存实验场景、专用脚本与测试数据（不替换原默认场景、不覆盖正式存档）。
