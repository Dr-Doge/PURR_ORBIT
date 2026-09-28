# 2026-09-28 cat1new2与独立测试场景整合

本地保护提交27e82e94＋远端983468c4（59cf15be）；原共同基线404099a5。用户授权拉取合并并push。本报告记录源码整合，不包含新EXE或新节奏结论。

## 保留与修复

- 组员cat1new2全部九图集、动画资源及room_3d引用完整接入；源图／tres与远端一致。旧cat1new和cat1new1按远端删除，不恢复失效引用。
- 本地model/balance/data/tree/build/软避让/模型动画时钟、lab_model/lab_scene/cat_personas及人设JSON保持27e82e94。数值不改，正式入口与独立存档边界保持。
- 上行待机与行走均额外×0.88，produce以1.5倍视觉速度在约0.733秒播完并保持末帧，原1.1秒反应禁收未缩短。
- 唯一Git冲突为侧面idle的.import，保留新路径／UID与本地3D纹理压缩配置。修复压缩AtlasTexture.get_image直接裁切失败：先读取图集、解压CPU副本，再裁切idle首帧计算固定脚底锚点；每套缓存一次。
- 更新test_room/test_actors到新图集，并刷新22个持久化预览卡片；F5运行正式3D，测试场景F6直接进入12猫／2工人的独立经营预置。

## 验证

Godot4.7.1.stable.a13da4feb；图形回归Compatibility／RTX5060。

| 检查 | 断言 |
| --- | --- |
| 原模型 test_demo | 125 |
| 独立测试真实循环 test_lab_004 | 90 |
| 原统一树与机制 test_september23 | 74 |
| 正式3D鼠标／投影／窗口 test_3d_scene | 54 |
| 保存节点／素材／编辑器场景 test_merged_structure | 38 |
| 新三花动画／图集／压缩锚点 test_cat1new | 39 |
| 产毛反应／禁收 test_reaction_007 | 58 |
| 软避让 test_overlap_924 | 19 |
| 总计 | 497 |

全部通过，无引擎错误；test_*.log保留结果，integrity.json记录模型和美术核对。已查看新运行截图，保留00_authored、01_runtime、03_identity等测试预置图，以及正式白盒、窗口和素材图。未重跑长期经营，不宣称新时长；不覆盖旧报告。

复现：用Godot --path 毛球满屋 --script运行上述tests脚本。带固定报告目录的5份脚本仅在.tools/merge_cat1new2_928中复制并把输出改为本目录；测试存档改到reports/lab_004/merge_cat1new2_928，符合独立模型的目录限制；其余脚本未重定向。原测试脚本与旧证据保留。源码中的test_lab_004结果source字段表示预置最初来源404099a5，本次合并双方见integrity.json。

正式存档没有被此合并读写／迁移；回归使用testing=true和隔离测试档。用户已有编辑器游戏可能独立自动保存，本次不声称其文件哈希恒定，不停止或回滚用户运行。历史未跟踪builds保留本地，未作为本次源码发布内容。在线AI、正式岗位／身份迁移与退款仍属于004明确保留边界。
