# Cat1new3 与猫专用补光
- 新版九张 spritesheet 每帧 960×960，原有动画速度及屏幕尺寸保留；编辑器预览同步。
- 用户选择 B：CatFillLight 使用 DirectionalLight3D，强度 0.35，色彩 (1, 0.97, 0.93)，只照层 2、不投额外阴影。猫保留层 1 并加入层 2；地面、墙体、设施不变。
- test_cat1new 36 项、test_merged_structure 38 项通过。
- test_cat_fill 开关补光渲染对照：5968 个采样猫像素明显变亮，猫矩形外变化为 0。截图 fill_off.png / fill_on.png；原主光投影保留。
