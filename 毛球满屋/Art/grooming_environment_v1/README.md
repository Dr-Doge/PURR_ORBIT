# 船舱房间与美容台独立资产

内置imagegen生成，2026-10-15；已用于scenes/prototype_grooming/fur_demo.tscn。

- room_background.png：1672×941，完整不透明船舱背景，无猫、无桌。保留行星舷窗、左右透视墙面、暖色灯和空地。
- grooming_table.png：1672×941，透明背景。宽皮质台面、金属前沿、支柱和基座全部独立；Demo采用近景，桌腿大部分位于镜头外。
- grey_paw.png：1254×1254，透明灰白猫爪，四趾布局与v2相匹配；指甲仍由独立资产放在它后面。

PNG为生成原图字节，无程序修色或抠图。manifest.json含真实Alpha范围、可见边界、SHA256；resources内有3份AtlasTexture。tools/prepare_grooming_environment.py只读图片生成这些资源，不修改像素。

房间原图比例接近16:9，游戏内按1920×1080逻辑画布使用；不将1672×941误报为1920×1080生成图片。Prompt与来源路径记录见生成Prompt.md。
