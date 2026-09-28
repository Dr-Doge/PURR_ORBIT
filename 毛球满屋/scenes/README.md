# 场景编辑入口（2026-09-28）

用Godot4.7.1打开项目。左上“场景”显示当前场景节点，左下“文件系统”显示资源；运行中的动态实例可切到“远程”。

## 应该打开哪些文件

- `main.tscn`：实际启动场景。包含Cursor、Room实例、HUD、Overlay／Center／Card／Body。HUD的文字、按钮、容器、样式为真实保存节点。Room已设为可编辑子节点；也可打开原场景。
- `room.tscn`：舱室本体，含Backdrop TextureRect、Cats／StarterCat1／2、Facilities、Workers、StaticOutlines、HarvestEffects／GachaMachine、TokenLayer。初始两猫的场景坐标和kind用于新游戏；加载已有存档仍以存档为准。不要删除约定命名的必需层。
- `art_library.tscn`：猫、喂食器、日光浴、娱乐、祭坛、工人、扭蛋机素材总览。实例与运行时同源，仅作编辑预览，不会给玩家免费生成物品。
- `cats/*_cat.tscn`：每猫种独立场景，选中Animation（AnimatedSprite2D）后展开SpriteFrames，可查看idle／walk／produce和原帧文件。直接打开.tres修改动画，运行时模型及显示共用这些资源。
- `facilities/*.tscn`：喂食器和日光浴有Artwork Sprite2D；扭蛋机本身是Sprite2D。娱乐、祭坛和工人没有新的导入贴图，暂用可在编辑器预览的@tool绘制脚本，不伪装成已有美术。
- `ui/start_menu.tscn`：实际开始菜单模板，含NewGame、Continue、RestoreBackup、Settings。main只负责信号绑定、是否有存档及备份可见性。

## 猫咪美术绑定

| 游戏猫种 | 场景 | 原始动画 |
| --- | --- | --- |
| short短毛 | cats/short_cat.tscn | Art/cat1_animations.tres |
| giant巨型 | cats/giant_cat.tscn | Art/cat5_animations.tres |
| static静电 | cats/static_cat.tscn | Art/cat8_animations.tres |
| lucky招财 | cats/lucky_cat.tscn | Art/cat10_animations.tres |
| alien外星 | cats/alien_cat.tscn | 暂复用Cat1；工程没有第五套原始序列帧 |

移除了后来增加的统一染色和临时项圈覆盖，前四类modulate为白色，显示原图颜色。外星猫仍为明确标注的绿色占位及运行时触角，不能宣称已有独立完整动画。variant存档字段仍兼容，但不再覆盖四套素材原色。

## 运行结构与限制

main.gd绑定静态HUD／菜单；room.gd同步模型与Cats／Facilities／Workers中的场景实例；cat_actor.gd驱动Animation帧及位置；facility_view.gd支持编辑器预览和运行状态。动画时钟仍由模型及cat_visuals共享，produce禁收、固定脚底、3像素转身过滤不变。

库存、商店、升级图的列表项及数量变化的游戏对象继续由数据驱动；运行时在“远程”场景树检查。主场景本地树代表初始布局，不能显示尚未加载的玩家存档。新猫数量由经济模型决定，复制初始猫节点不会额外赠送猫；当前读取前两只初始猫的布局与种类。

不要重新运行历史bake/extract脚本覆盖场景，它们已冻结。新增测试需instantiate room.tscn，不能再Room.new()；独立测试窗口需自行设置尺寸锚点，修改模型后调用room.step(0)同步精灵。
