# 2026-10-17 轮廓毛发编辑摆放场景

任务：IMP-20261017-007。Godot 4.7.1，编辑入口 `scenes/prototype_grooming/轮廓毛发摆放.tscn`。

007当时491项自动检查通过：场景及裁剪资源可加载，初始94个轮廓独立可编辑，413个身躯参考保留且锁定；复制、移动、旋转、缩放、翻转后保存／重开不丢数据，各节点颜色材质独立，素材复制到小猫后使用小猫坐标匹配。这是用户手工改动前的历史结果，不代表当前数量。

初始图形渲染见“大猫摆放区.png”及“小猫摆放区.png”。008初次探针因旧检查固定43／51数量而失败，539项／4项失败的JSON及其保存副本已移至`../authored_outline_20261017/legacy_fixed_count_probe/`，不与007混记。旧原始JSON已被该次探针替换，当前验收使用008的独立输出，勿把历史数值作为重跑结果。

复现：

```powershell
.\.tools\godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe --path 毛球满屋 --script res://tests/test_outline_placement.gd
```

上段007当时用户尚未完成手工摆放。现008已交回并接入，当前104片轮廓及541项编辑检查见`../authored_outline_20261017/editor_round_trip/checks.json`；运行验证见该报告README。当前测试脚本已改独立008输出，不再覆盖本目录。机器猫、正式入口或玩家存档保持，没有生成EXE或推送Git。
