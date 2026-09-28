# 2026-09-28 编辑器场景与动画原色

任务IMP-20260928-001，Godot4.7.1。当前未提交工作区。

原因：旧main.tscn只保存根Control，HUD动态new，猫与设施直接_draw。四套.tres仍存在，并未被删成同一套；后来variant染色／项圈让原色改变，alien一直缺独立素材。

结果：main.tscn真实HUD／弹窗骨架，room.tscn真实场景层和初始猫，start_menu.tscn真实菜单模板；5个猫场景、6个设施／工人／扭蛋机场景、art_library总览。运行节点复用这些场景，Cat.kind变化替换为对应类型实例，AnimatedSprite2D显式引用原SpriteFrames；四类modulate为白色，无统一染色。原始Art未编辑。外星、娱乐／祭坛／工人占位来源在scenes/README.md明示。

202项最终检查通过：test_editor_92842、反馈17、反应58、悬停39、idle17、软拖放UI7、统一树UI22；render_demo双尺寸UI购买／升级等另通过。editor_import.log无解析错误。实际检查01_authored_main（禁用main/room游戏脚本后的保存节点预览）、02_art_library、03_runtime_original_cats及游戏双尺寸图。42项包含运行前持久节点、重复新局无重复节点、4套3动画完整性、原色、produce资源、猫种转化场景替换和隔离快照读取。

回归脚本使用真实新场景。最初独立Room.new缺子节点；改为instantiate后，原测试预设size叠加场景anchors导致越界，改为独立窗口top-left锚点；随后补room.step(0)同步Sprite再测渲染。失败迭代在regression.log／final_regression.log保留（重复越界已压缩），最终对应测试全部通过。

编辑指南scenes/README.md。库存／商店／升级图的条目和运行购买实例仍按数据生成，在远程树查看；本地树是初始布局，不自动读写正式档。新局按原两猫数量读取初始场景的位置和kind。没有调整经济、收割、软避让和存档版本，没有重跑长期节奏。
