# 10｜Godot 技术方案

## 技术基线

- 引擎：Godot 4.7.1 stable。
- 渲染：GL Compatibility，优先保证 Game Jam 设备兼容性。
- 语言：GDScript。
- 目标平台：Windows 桌面端。
- 主输入：鼠标；键盘仅用于暂停和调试。

## 目录约定

```text
assets/
  audio/ fonts/ models/ textures/ ui/
data/
  box_series/ collectibles/ market_events/ orders/
docs/
  策划案/
scenes/
  entities/ levels/ main/ ui/
scripts/
  autoload/ components/ systems/ ui/
```

## 计划场景

| 场景 | 路径 | 职责 |
|---|---|---|
| 主场景 | `res://scenes/main/main.tscn` | 组合系统、桌面与 UI |
| 桌面 | `res://scenes/levels/desk.tscn` | 灯光、相机、功能区和生成点 |
| 快递箱 | `res://scenes/entities/parcel_box.tscn` | 基础工作拆箱与回收 |
| 盲盒 | `res://scenes/entities/blind_box.tscn` | 系列外观、封条与内容实例 |
| 藏品 | `res://scenes/entities/collectible.tscn` | 揭晓展示与物品数据绑定 |
| HUD | `res://scenes/ui/hud.tscn` | 日期、现金、提示与订单摘要 |
| 市场面板 | `res://scenes/ui/market_panel.tscn` | 买卖、趋势与新闻 |
| 订单面板 | `res://scenes/ui/order_panel.tscn` | 接单、匹配和交付 |
| 日终面板 | `res://scenes/ui/day_summary.tscn` | 收支、估值与日切 |

## 主场景树草案

```text
Main (Node)
├── Systems (Node)
├── DeskWorld (Node3D)
│   ├── WorldEnvironment
│   ├── KeyLight
│   ├── FillLight
│   ├── CameraRig (Node3D)
│   │   └── Camera3D
│   ├── Desk
│   ├── ActiveBoxAnchor
│   └── RevealAnchor
└── UI (CanvasLayer)
    ├── HUD
    ├── MarketPanel
    ├── OrderPanel
    ├── CollectionPanel
    ├── DaySummary
    └── PauseMenu
```

## Autoload 服务

- `GameState.gd`：日期、64 位现金、累计经营收入、流程状态和单局种子。
- `LootService.gd`：校验概率池、按整数权重抽取内容，并在购买时锁定结果。
- `InventoryService.gd`：未拆盒与藏品实例，提供原子化增删与配对合成接口。
- `MarketService.gd`：新闻、稀有度限幅、报价和相对期望值盒价传导。
- `OrderService.gd`：订单生成、报价快照、匹配、交付和到期。
- `SaveService.gd`：版本化存档、自动保存和恢复。
- `AudioService.gd`：音乐、环境与交互音量总线。

系统间通过信号通信，UI 不直接修改现金或库存。所有货币结果先完成倍率计算，再统一四舍五入为 Godot 64 位 `int`。合成由 `InventoryService` 在单次调用内完成组件扣除与合成款生成，保证原子性。

## 交互组件

`UnboxController` 负责统一状态机：

- 使用 `Camera3D.project_ray_origin()` 与 `project_ray_normal()` 做鼠标射线。
- 封条和抓取热点放在专用物理层。
- 拖动进度使用屏幕空间累计位移并经过 `Curve` 映射。
- 模型通过 `AnimationPlayer` 或属性插值响应归一化进度。
- 完成后由控制器发送 `box_opened(content_id)`，不直接处理经济。
- 揭晓事件同时携带稀有度、公开概率、基础价值、今日价值和相对盒价倍率。

`InteractableBox` 通过导出属性配置系列 ID、封条轨迹、撕开距离、取物距离和动画资源，避免为每种盒型复制脚本。

## 数据设计

优先使用自定义 `Resource`：

- `BoxSeriesData`：基准盒价、解锁收入、内容 ID 数组、整数概率权重数组（长度随系列 4—8 变化）和外观资源。
- `CollectibleData`：名称、稀有度档、标签、64 位基础价值、市场上下限、模型与图标，以及配对关系字段。
- `PairSetData`：配对定义（AB／ABC）、组件 ID 列表、合成款 ID、合成倍率与合成演出资源。
- `MarketEventData`：目标、系列指数、单品热度、供货指数、持续时间和新闻文本。
- `OrderTemplateData`：条件类型、期限、各稀有度与合成款倍率、生成权重。

每个系列的权重数组长度等于内容物数量，加载数据时必须验证权重总和为 10,000 且与内容 ID 一一对应。抽取时使用 `randi_range(1, 10000)` 和累计区间，禁止使用四舍五入后的浮点百分比。

运行时实例只保存 ID、价格、日期和状态，不复制静态资源。合成款实例额外记录组件来源 ID。数值格式化由独立函数处理：界面可显示 `K／M／B／T`，工具提示和结算保留完整整数。

## 存档

- 路径：`user://save_v1.json`。
- 自动保存点：购买后、拆封结果确定后、订单交付后、合成完成后、日切后。
- 保存版本号、随机种子、当前日、现金、累计经营收入、库存、合成款来源记录、订单报价快照和完整市场状态。
- 加载时先校验版本、必需字段、各系列权重总和与数值范围；失败则保留损坏文件并开启新局。
- 拆封结果在购买时确定并写入存档，阻止重新读档刷新传说与配对组件结果。
- MVP 无概率保底，不保存或修改动态稀有度权重。

## 输入映射

| Action | 默认输入 |
|---|---|
| `interact_primary` | 鼠标左键 |
| `rotate_object` | 鼠标右键 |
| `cancel` | `Esc` |
| `toggle_help` | `F1` |
| `debug_advance_day` | 仅调试构建启用 |

## 性能预算

- 桌面同时只保留一个高细节活动箱体。
- 藏品展示模型建议每件低于 20k 三角面。
- 灯光以 1 个主阴影灯配合无阴影补光为主。
- 粒子池化或控制在少量一次性效果。
- 目标：1080p 下稳定 60 FPS，最低 30 FPS 不影响拖动判定。

## 实现顺序

1. 灰盒桌面与相机。
2. 通用拆箱状态机。
3. 数据资源与库存。
4. 现金、买卖与日切。
5. 市场、订单、存档。
6. UI、美术替换与音频。
