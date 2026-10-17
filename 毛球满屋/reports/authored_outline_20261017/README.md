# 用户手摆轮廓接入实机：IMP-20261017-008

运行 `scenes/prototype_grooming/fur_demo.tscn`，Godot 4.7.1。

8764 项自动检查通过：4213模型、1806双尺寸实际输入／GUI／GPU、2204手工布局与显示层级专项、541编辑保存重开。各集合含重复回归，不能当作独立功能数量。

- 大猫337片身躯＋52片手工轮廓，共389；小猫76＋52，共128。原位转入躯干组的7片素材复制件记录在handoff.json。
- source用户文件原样保存在user_handoff_original.txt。每片当前变换与原文件对应比较；不重新吸附、缩小或按切线纠偏。测试不覆盖用户场景。
- 实机层级：底图0、轮廓1、身躯2。实际GPU切换到错误前景顺序后，大／小猫6821／1388个探点改变；恢复后画面逐像素一致。见runtime_under_body_*.png、layer_comparison_above_*.png和integration.json。
- 两种尺寸全部毛片可用两遍顺梳完成；真实鼠标操作手工轮廓，第一遍保留、第二遍回弹结束后消失并生成对应松散落毛。每片仍唯一运行ID，整猫389／128片逐片掉落，不漏、不重复。
- 连续升降换猫、暂停、大小预选、材质拉扯／恢复、透明和重量保持。实际资源使用已切纹理的CPU图像转为局部UV纹理，保留真实AtlasTexture资源路径作为身份，避免把整页图集UV错误用于梳理Shader。
- 父组决定区域，NodePath决定手工身份；复制带来的旧source_id不作运行编号，普通素材区和参考图不参与收割。编辑脚本不在运行树执行。

**美术复核边界：**为保留用户手摆结果，本轮没有用旧程序规则自动移位、缩放、剪裁或限角。采样发现大猫2片、小猫3片手工轮廓与原脚爪禁区有重叠（含最大拉扯）；具体路径见model.json的manual_foot_overlaps。功能检查均可完成，这项记录不等于脚爪美术已经验收。轮廓是否自然仍需真人看图确认，不把006的0°／脚爪全避让结论继承到手工版。

复现：tests/run_grooming_fur.ps1；Godot运行tests/test_authored_outline.gd和tests/test_outline_placement.gd。当前结果分别见model.json、ui.json、integration.json、editor_round_trip/checks.json。

机器猫、正式主游戏与存档未改；用户已有动画资源变化保留。无新EXE、无提交／push。
