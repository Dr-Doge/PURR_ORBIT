# 2026-09-28 新四向三花猫总版本

对应IMP-20260928-003。本地bc6b681d总版本与组员81cd50e6（含2e3718a1）合并；本地6项3D纹理导入设置先由efd493a保护。原cat1new及最新cat1new1图集、动画资源和whitebox原场景与组员提交一致；model、balance、data、tree_specs、build_rules、cat_space、cat_animation_data与上一总版本一致，详见verification.json。

短毛猫使用cat1new1九张256×256分帧图集，支持上下独立、左右侧面镜像、抚摸、舔爪及产毛。沿用3像素转向过滤、0.8显示倍率，向上walk额外乘0.88；保留固定脚底、模型1.1秒produce时钟及禁收。其他猫及经济规则不变。

补齐short_cat.tscn、room_3d已保存Sprite3D和素材总览的新版预览，解决运行时显示新猫、编辑器仍显示旧猫的问题。运行和编辑预览都使用最新原色图集；模型反应时长继续引用旧cat1资源，不把它作为显示资源。

## 验证

Godot4.7.1、Windows／RTX5060 Compatibility。15组测试合计710项通过：

- test_3d_scene：54项。
- test_alien_visuals：51项。
- test_cat1new：36项。
- test_cat_visuals：112项。
- test_demo：125项。
- test_developer_004：28项。
- test_editor_928：42项。
- test_hover_008：39项。
- test_idle_009：17项。
- test_lighting_3d：10项。
- test_merged_structure：38项。
- test_overlap_924：19项。
- test_overlap_ui_924：7项。
- test_reaction_007：58项。
- test_september23：74项。

3D实际鼠标收割／悬停／拖放／设施、数字键工具、阴影像素测量、四向和产毛动画、编辑器已保存节点、读档、统一树与软避让均通过。idle观察847个静止样本、2665个移动样本；无idle带位移违规。

迭代说明：首次快速启动的悬停测试出现8项失败，独立复现与正式重跑39项通过，未为此修改游戏逻辑；属于窗口焦点／输入时序疑点，保留此限制，勿称已证实根因。原纹理测试无法直接读取压缩图像，增加解压后的透明像素检查；未修改原美术。旧2D编辑测试更新为新SpriteFrames预期，42项通过。

未修改正式玩家存档，隔离开发档仅在本目录。未重跑长期经营模拟；历史时长不作为本轮节奏证据。截图均为本轮实际渲染，旧reports/merge_3d_928和reports/cat1new保留历史。

## 构建

0.27.0.15导出、编辑器导入与执行文件120帧开始菜单启动成功，退出码0；editor/export/export_smoke日志均无引擎错误。二进制与哈希在builds/PurrOrbit_v0.27_20260928_3D_v15，通过Git LFS发布。
