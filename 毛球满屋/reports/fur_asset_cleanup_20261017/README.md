# 裁剪碎角清理与统一着色：IMP-20261017-009

Godot4.7.1；运行scenes/prototype_grooming/fur_demo.tscn，F6。

**8888项自动检查通过：**665素材／实际着色、4213模型、1806双尺寸真实输入／GUI／GPU、2204手工位置与显示层级。各集合含重复回归，不能当独立功能数量。

## 修复结果

- 20份贴片（12身躯、8轮廓）重新隔离主体。4份灰色轮廓的矩形原裁剪包含邻近素材：shoulder341、back1782、flank5221、tail4493个不属于主体的较高Alpha像素，合计11837；另清理所有贴片的透明背景低Alpha碎噪。
- 只保留每片最大的连续主体和原有一像素柔边，不扩张主体、不给边缘加不透明色块。20份各只有一个Alpha>32/255的连续主体，保留像素RGBA与原素材完全一致。
- 原画布尺寸、中心锚点、资源文件名均不变；资源仍为AtlasTexture，改为引用独立同尺寸ImageTexture.res的整个画布，不再矩形引用包含邻图的原图集。原body_tufts.png、contour_tufts.png哈希保持。
- 编辑器和运行／接触判定都读取同一份清理后资源；不只隐藏渲染中的碎角而留下不可见判定。
- 删除轮廓黑色描边绕过毛色染色的特例。轮廓和普通毛片均使用同一RGB毛色／明暗公式，以及同一原Alpha×顶点Alpha×遮罩×有效区×loosen公式。没有单独压低轮廓Alpha或硬化普通毛片。
- 相同素材用身躯／轮廓材质绘制，实际GPU输出RGBA逐字节一致；17920可见像素中5043保留柔边／半透明，轮廓不再保留近黑色的额外描边。
- 当前大猫337＋52、小猫76＋52，轮廓层1＜身躯层2保持。为避免更干净的Alpha改变程序铺排，当前同时读取用户场景中锁定的身躯参考几何；所有位置、角度和尺寸与交回文件一致。新美术若不使用手工场景，空outline_layout仍支持程序铺排。
- 两遍梳理、拉扯、恢复后脱落、逐片松散毛、连续升降换猫和暂停通过。12种落毛粒子素材、透明度／速度未改。

## 证据

asset_manifest.json／Art/grooming_fur_v1/isolated_patches.json记录每片旧源区域、画布、保留与剔除数量及原PNG哈希。cleanup.json记录素材及GPU检查，model.json／ui.json／integration.json记录完整回归。clean_runtime_1.0.png及0.5.png为实际画面；same_asset_body_material.png与same_asset_contour_material.png为RGBA一致性证据。

生成工具tools/build_clean_fur_assets.gd只根据原图集重做独立切片，不生成或改写手工场景。保留一像素原柔边属于抗锯齿，不等于悬浮碎角。手摆脚爪附近原有重叠仍在model.json记录，本轮不擅自移位；真人观感待验。

当前复现tests/run_grooming_fur.ps1、test_fur_asset_cleanup.gd、test_authored_outline.gd；报告输出已切本目录，008历史报告不覆盖。机器猫、正式入口／存档与原PNG保持，用户另有动画改动保留；无新EXE或push。
