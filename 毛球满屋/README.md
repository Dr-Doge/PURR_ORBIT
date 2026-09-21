# Purr Orbit / 毛球计划 · v0.27连续经营Demo

Godot **4.7.1**。已按最新策划落地一小时目标、两阶段经营和12＋24件收藏。当前是程序绘制像素美术的可玩Demo。

## 启动

双击[启动Demo.cmd](启动Demo.cmd)，或用Godot4.7.1导入[project.godot](project.godot)后按F5。本机引擎在工作空间`.tools/godot-4.7.1/`，不纳入Git；其他机器可使用`launch.ps1 -Engine 'Godot4.7.1可执行文件路径'`。

## 怎么玩

- 不按键，在猫身上来回移动鼠标收毛球，行走途中也能收割。没有行走CD；新增毛层短暂膨胀后恢复，毛层越多仍越蓬松。等多层再收更赚，也更快获得代币。
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
| `scripts/room.gd` | 像素场景、鼠标收割/拖放、实体反馈 |

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
