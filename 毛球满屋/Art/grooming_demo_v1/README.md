# Purr Orbit grooming demo asset kit v1

2026-10-15。美术生成使用内置image_gen，PNG为游戏分层使用，不是带UI的整幅效果图。

精确16:9背景：[background_1920x1080.png](background_1920x1080.png)。源台面背景另保留background_leather.png。两种猫底图、猫爪、状态图集、污物／粒子／工具图集均在本目录。

- [asset_manifest.json](asset_manifest.json)：全部Prompt、生成来源、修正记录与引擎导出说明。
- [atlas_index.json](atlas_index.json)：实际尺寸、Alpha、SHA256、每格区域与锚点建议。
- resources/：37份AtlasTexture，可引用，不必重新切PNG。
- [接入说明](../../../玩法方案讨论/2026-10-15_美容Demo开发准备/03_素材规格与接入说明.md)：图层与状态使用边界。

重要：状态图不是逐像素对齐的动画。持续清理用干净底图＋独立污物＋运行遮罩；脏态格只参考，不是可擦除污物层。背景、文字、UI、鼠标与收益不烘焙到角色PNG里。

素材预览场景在scenes/prototype_grooming/，属于组装检查，不包含服务评分和结算。正式游戏入口与存档不修改。
