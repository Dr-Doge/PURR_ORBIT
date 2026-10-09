# Concept Whitebox｜面片场景

打开 res://scenes/Concept Whitebox.tscn，按 F6 运行。

素材位于 Asset：Floor_01.png、Wall_Base_01.png、Wall_Column_01.png。
场景保持用户最新保存的墙高、地面尺寸、窗洞、前后柱子位置及墙顶面片。当前门和装饰占位已由用户移除，以实际场景为准。

## 最新相机取景：竖线平行
本轮仅更换 GameCamera 参数，用户最新墙体、地面、柱子、材质与灯光保持原样。
采用水平相机及偏轴透视，取消俯仰造成的竖线收拢。仍保留前后纵深及物体随距离缩小，不是完全正交。
位置 (0,14,24)，旋转 (0,0,0)，projection=FRUSTUM，size=0.84，frustum_offset=(0,-0.54)，near=1，far=100，keep_aspect=KEEP_WIDTH。
日后上下调整构图优先使用 frustum_offset.y，不要倾斜相机，否则竖线会重新汇聚。size 调整取景范围。
三组偏轴参数运行比较，最终 1440×810、1280×800 均截图检查通过。投影数值检查：同一竖线上两个高度的屏幕 X 相同。
参考 Godot Camera3D：https://docs.godotengine.org/en/stable/classes/class_camera3d.html
预览 reports/concept_whitebox/preview.png、preview_16_10.png。
## 墙顶厚度与暗角
墙顶面片宽度从0.3加到0.5，向外加宽，后墙顶部同步延长以闭合转角。
GameCamera/CameraEffects/Vignette 为全屏柔和暗角，鼠标穿透；材质 strength=0.30、inner_radius=0.45、outer_radius=1.4，可在编辑器调整。中央无暗角覆盖，边缘渐暗。
已运行截图检查，退出码0。

## 2026-10-09 入库前用户微调
当前相机与灯光已由用户继续修改：相机约(0,13.195523,20.795734)、俯角约1.847度，主光能量3.158。上文零旋转相机为历史校正基准，不是本次最终参数。最终状态以tscn和最新preview截图为准。
完整制作与迭代记录见 ../../美术日志/07_2026-10-09_场景美术与面片搭建.md。
