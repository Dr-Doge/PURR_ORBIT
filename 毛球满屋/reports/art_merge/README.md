# 2026-09-21 美术合并验证

合并来源：远端 `04006a9d`（猫咪动画、空间站与视觉反馈）；本地合并前快照 `771ad2f3`（v0.27-N2数值与连续行走）。本次为真正的双父合并，未覆盖队友历史。

## 合并取舍

- `Art/`全部371个受版本控制文件与远端一致，包含原始序列帧、动画资源、场景/标题、设施、光标、特效贴图与shader。
- 接入四种猫的idle/walk/produce、空间站窗外旋转、设施贴图、毛层图标、收获飞行与代币特效。produce只改变画面，不暂停模拟或锁定收割。
- `data.gd`、`balance.gd`、`project.godot`以及重新运行export_balance得到的`reports/pacing_v027/balance.json`与本地快照一致。model仅新增特效事件元数据及首币显示事件；收入、发币、CD、升级、存档与行走公式未改。
- 保留12＋24件、连续两阶段、有效贡献代币与新版存档。没有并入免费生成猫的1—5快捷键或收割停步计时。
- 场景坐标映射仅用于显示和鼠标反投影，设施范围、速度与模型位置仍使用原数值。
- 毛层常驻增大、0.35秒/16%膨胀、巨型1.35体型继续保留。贴图与静电轮廓共享脚底锚点；新美术尺寸下测试按像素面积检验常驻增大，允许单一轴向像素取整。
- 主界面采用队友空间站右侧控制台，保留按进度出现的导航、代币进度和本地简洁弹窗。开始页保留开始/读取/设置及备份入口；原始标题图不改动，通过运行时标题牌统一为Purr Orbit／毛球计划。

## Godot 4.7.1实测

| 检查 | 结果 |
| --- | --- |
| headless editor import | 全部资产可导入 |
| tests/test_demo.gd | 125 checks, 0 failures |
| tests/export_balance.gd | 导出与合并前JSON完全一致 |
| tests/test_cat_feedback.gd | 17 checks, 0 failures；真实鼠标移动收割、无停步/改道、老v27兼容、实际像素膨胀/脚底/常驻大小 |
| tests/test_cat_visuals.gd | 0 failures；四种动画资源与无模型副作用 |
| tests/test_cat_shortcuts.gd | 0 failures；正式游戏忽略免费生成快捷键、招财动画绑定 |
| tests/test_fur_badges.gd | 0 failures；每层一个毛球图标、同数量飞行、结算不变、清理 |
| tests/test_token_effect.gd | 0 failures；首币/固定贡献阈值发币、特效飞入HUD并清理 |
| tests/test_station_art.gd | 0 failures；真实收割/拖放、缩放坐标逆映射、窗口遮罩、300秒旋转循环；1440×900和1280×720 |
| tests/render_demo.gd | 0 failures；购买/拖入日光浴/遮挡/补货/暂停/动态购买条件；1440×900和1280×800 |

当前目录截图为本次合并后的新证据，历史`reports/v027`、`reports/cat_feedback`原截图保留。所有游戏场景测试使用testing模式，模型存档测试仅用隔离档，不写正式玩家存档。图像回归已人工查看开始页、完整舱室和小尺寸商店。

本次不重新声称一小时真人节奏已校准，也未重跑21组策略模拟；旧策略报告仍为上次连续行走改动前的基线。
