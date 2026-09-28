# Purr Orbit / 毛球计划 · v0.27连续经营Demo

Godot **4.7.1**。已按最新策划落地一小时目标、两阶段经营和12＋24件收藏。当前已合并队友的猫咪动画、空间站、设施和特效美术；经济与玩法保持v0.27-N2。

## 启动

双击[启动Demo.cmd](启动Demo.cmd)，或用Godot4.7.1导入[project.godot](project.godot)后按F5。本机引擎在工作空间`.tools/godot-4.7.1/`，不纳入Git；其他机器可使用`launch.ps1 -Engine 'Godot4.7.1可执行文件路径'`。

## 怎么玩

- 不按键，在猫身上来回移动鼠标收毛球，行走途中也能收割。随机走动后会停留播放idle，不锁收割；新增毛层短暂膨胀后恢复，毛层越多仍越蓬松。等多层再收更赚，也更快获得代币。
- 按住拖动搬猫，松在日光浴或娱乐设施上即可送入。点击设施补粮、清虫和移动设备。
- **成长**研究能力 → **补给**买实体 → 点击空地摆放，右键取消。升级显示当前与下级效果；不要求旁支满级。
- 招募小帮手接手劳动，默认等6层收割；第二阶段解锁职责帽分工。工人不替你买粮或出售。猫粮支持10/100份等价采购。
- 获得首枚代币时收到神秘仪器；每次投1币，得到一个不重复收藏。第12件后自动补入24件，经营进度不清零。36件后可继续经营。
- 娱乐奖品自动入**仓库**，同类合并展示，玩家点击出售后才得到毛球。收藏不能卖。
- **Esc**暂停、保存、设置或查看帮助；开始菜单提供新游戏、继续、备份恢复和设置。

第一阶段工人/喂食/日光浴，第二阶段虫害/职责帽/娱乐。祭坛、外星猫和维修保留作后续，本Demo不开放。

## 数值和代码入口

[策划索引](../摸猫增量策划案/00_索引.md)是规则入口；[17号文档第12节](../摸猫增量策划案/17_Demo数值总表与调参清单.md)维护当前运行参数、旧值、目的与验证。[DEMO_RULES](DEMO_RULES.md)区分试玩选择与正式待定。

| 文件 | 负责内容 |
| --- | --- |
| `scripts/balance.gd` | 生产、工人、设施、贡献阈值等常量 |
| `scripts/data.gd` | 阶段、研究树、价格、六个6件系列及升级说明 |
| `scripts/model.gd` | 生产/岗位/贡献结算、不重置补货、原子存档与校验 |
| `scripts/main.gd` | 休闲风菜单、紧凑HUD、成长/补给/仓库/收藏面板 |
| `scripts/room.gd` | 场景坐标映射、鼠标收割/拖放、贴图与膨胀反馈 |

## 存档

`%APPDATA%/PurrOrbitDemo/space_cats_v27.save`，备份`.bak`。每10秒、交易及退出时保存。旧`space_cats_v26.save`原件保留，界面提示可用旧工程读取；新版不静默覆盖或猜测迁移。不计算离线收益。

## 验证

```powershell
$engine = '.tools/godot-4.7.1/Godot_v4.7.1-stable_win64_console.exe'
& $engine --headless --path '毛球满屋' --script res://tests/test_demo.gd
& $engine --headless --path '毛球满屋' --script res://tests/test_progression.gd
& $engine --path '毛球满屋' --script res://tests/render_demo.gd
& $engine --headless --path '毛球满屋' --script res://tests/export_balance.gd
python '毛球满屋/tests/summarize_v027.py'
```

125项模型断言、真实输入与1440×900/1280×800界面检查通过。21组策略模拟完整经营57—66分钟，攒8层50—53分钟；不是真人通关时长。首阶段约19—24分钟仍早于25分钟建议。证据与限制见[报告](reports/pacing_v027/README.md)。测试只用隔离测试档，不覆盖玩家进度。

`reports/v026`、`reports/pacing_2h`保留历史，不是新版验收。`analyze_pacing.gd`现在只提示历史入口，当前分析用`pacing_v027.gd`。`--calibrate`只写离线参考，不修改游戏参数。

![当前舱室](reports/v027/07_populated_room.png)

### 行走与长毛反馈专项验证

运行`--script res://tests/test_cat_feedback.gd`（使用图形模式）。17项检查覆盖移动中真实鼠标收割、抚摸不停止/改道、无行走冷却、旧档兼容，以及实际像素膨胀/脚底固定/保留毛层体型。截图在reports/cat_feedback。此前21组时长记录是这次移动改动前的基线。

### 2026-09-21 队友美术合并

已合并远端`04006a9d`；合并前本地快照为`771ad2f3`。全部371个`Art/`文件保持远端内容，当前数值配置与导出保持本地版本。`cat_visuals.gd`维护纯显示动画，`station_backdrop.gd`/`station_hud.gd`维护空间站与右侧控制台，`harvest_art.gd`/`token_effect.gd`维护收获特效。动画不会阻止移动或收割；数字键不会免费添加猫。

鼠标测试通过`room.screen_position()`把模拟坐标转为画面坐标；不可将显示用`ART_FLOOR`覆盖经济模型中的`D.FLOOR`。新增贴图时维持这种分离。标题原图含旧文字，通过运行时标题牌使用正式名称，原图完整保留。

[合并取舍、完整验证与截图](reports/art_merge/README.md)。历史节奏数据不作为本次新增节奏结论。

### 2026-09-21 自动觅食与随机活动

猫主动寻找有粮喂食器，到场吃1秒耗1份，获得11秒增产，到期再找粮；缺粮重选、无粮正常闲逛。自由活动随机走2—6秒/停1—3.5秒播放idle，长毛与收割不被停留锁住。扭蛋机右上贴右栏、机身在猫下层。旧v27存档兼容。

当前参数见17第12.8节。[交互验证](reports/feeding/README.md)；[新21组策略报告](reports/pacing_feeding/README.md)。完整经营模拟42—51分钟，已偏快；未擅自改价/代币门槛，不将旧57—66分钟当当前结论。

## 2026-09-21 收割系统实装日志完成

18号IMP-20260921-001—005已实装并验证：首层常驻、按层数延长真实互动、付费逐级收割门槛、单工人产出后CD及独立缩减。保留觅食与随机走停，旧搬运投入返款而不强升门槛。001—005当时的参数与报告保留历史；006当时参数更新为110像素首层、渐近3倍的操作量曲线、10秒自然长毛。详见策划17第13.4.2节。273项断言和真实鼠标UI回归通过，21组策略中完整经营52.92—59.13分钟；数值仍待真人校准，未提交或推送。

006证据：[机制与交互](reports/harvest_006/README.md)、[21组策略](reports/pacing_harvest_006/README.md)、[参数导出](reports/harvest_006/balance.json)。运行test_harvest_006.gd复测操作量、趋平和长毛边界；test_progression.gd、summarize_v027.py与export_balance.gd006时写入006报告目录，不覆盖旧报告。

## 007收割调整（2026-09-21）

首层165有效像素、单事件45，多层渐近495。每猫produce约1.1秒作为人工／工人共同禁收期，期间不缓存手势；cat_animation_data.gd统一动画资源时长，model计时，cat_visuals读取。暂停和读档保留剩余反应，旧v27缺字段默认0；自然长毛、工人首层2秒与自身CD保持。331项断言和真实UI／表现回归通过；完整经营模拟48.48—53.58分钟，仍待真人校准。未提交或推送。

当前测试入口test_reaction_007.gd覆盖新反应规则；test_harvest_006.gd维护当前基准的曲线回归，并非冻结旧参数。render_demo、export_balance、test_progression与summarize_v027当前写入007目录，旧报告保留。[实装验证](reports/harvest_007/README.md)、[21组策略](reports/pacing_harvest_007/README.md)、[参数](reports/harvest_007/balance.json)。数值入口17第13.5.1，状态见18的007。

## 当前008悬停停步（2026-09-21）

悬停猫立即停止自主行动、播放idle，移开后恢复原路线／活动计时；produce优先，长毛和冷却继续。临时输入不入档，UI遮挡／失焦／拖放／读档清理。进食活动随悬停暂挂属试玩实施选择。model管理hovered_cat_id，room刷新显示命中与UI遮挡，cat_visuals保持动画优先级；数值沿用007。

370项断言与双尺寸实际输入／动画回归通过。完整经营50.37—56.38分钟，补货23.25—27.73分钟；攒层47.15—52.12分钟，单层73.33—78.25分钟，模拟不等于真人一小时验收。当前输出为reports/hover_008及pacing_hover_008，旧报告保持历史。新增test_hover_008.gd验证悬停；策略脚本包含操作期间悬停、完成后移开。[验收](reports/hover_008/README.md)、[策略](reports/pacing_hover_008/README.md)、[参数](reports/hover_008/balance.json)。17第13.6.1与18的008已同步；未提交或推送。

009已修复idle滑动：model记录每个模拟步实际位移，cat_visuals在该步保持移动判定；没有位移才idle，produce仍优先。记录非持久，数值不变。256项断言及实际UI／动画回归通过，[证据](reports/idle_009/README.md)。交互截图当前写idle_009，008策略留作基线；未提交或推送。


## 2026-09-22｜16:9显示

默认窗口与视口改为1440×810，最小960×540；背景、遮罩与HUD共用16:9画布，消除原默认尺寸的上下留边。非16:9窗口继续等比居中；美术原件、模拟坐标、经济与存档格式保持兼容。`tests/render_demo.gd`已切换1440×810／1280×720验证，结果见`reports/display_16_9/README.md`。
