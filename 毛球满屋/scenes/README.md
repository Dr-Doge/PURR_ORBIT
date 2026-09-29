# 场景编辑入口（2026-09-28）

用Godot4.7.1打开项目。左上“场景”显示当前场景节点，左下“文件系统”显示资源；运行中的动态实例可切到“远程”。

## 应该打开哪些文件

- `3D scene.tscn`：当前实际启动场景。绑定`room_3d.tscn`和`ui/hud_3d.tscn`实例，包含已保存的Cursor、Room、HUD及Overlay。F5启动此场景。
- `room_3d.tscn`：展开WhiteboxViewport／World3D／WhiteboxRoom查看组员舱室、Camera、MainLamp、ActorLighting／Cat_1／Cat_2。whitebox_room.tscn为原场景，编辑其网格、贴图、灯光；运行时room_3d按窗口调整宽度和投影，actor_lighting按模型坐标更新角色卡片。不要把3D卡片的运行位置当模拟坐标。初始两猫布局仍编辑Cats／StarterCat1／2的2D模型坐标与kind；加载存档不覆盖存档位置。
- `ui/hud_3d.tscn`：状态栏、右上入口、功能抽屉及全部按钮均为保存节点；hud_3d只绑定与适配布局。
- `main.tscn`：保留的2D回归场景。包含Cursor、Room实例、HUD、Overlay／Center／Card／Body。HUD的文字、按钮、容器、样式为真实保存节点。Room已设为可编辑子节点；也可打开原场景。
- `room.tscn`：舱室本体，含Backdrop TextureRect、Cats／StarterCat1／2、Facilities、Workers、StaticOutlines、HarvestEffects／GachaMachine、TokenLayer。初始两猫的场景坐标和kind用于新游戏；加载已有存档仍以存档为准。不要删除约定命名的必需层。
- `art_library.tscn`：猫、喂食器、日光浴、娱乐、祭坛、工人、扭蛋机素材总览。实例与运行时同源，仅作编辑预览，不会给玩家免费生成物品。
- `cats/*_cat.tscn`：每猫种独立场景，选中Animation（AnimatedSprite2D）后展开SpriteFrames，可查看idle／walk／produce和原帧文件。直接打开.tres修改动画，运行时模型及显示共用这些资源。
- `facilities/*.tscn`：喂食器和日光浴有Artwork Sprite2D；扭蛋机本身是Sprite2D。娱乐、祭坛和工人没有新的导入贴图，暂用可在编辑器预览的@tool绘制脚本，不伪装成已有美术。
- `ui/start_menu.tscn`：实际开始菜单模板，含NewGame、Continue、RestoreBackup、Settings。main只负责信号绑定、是否有存档及备份可见性。

## 猫咪美术绑定

| 游戏猫种 | 场景 | 原始动画 |
| --- | --- | --- |
| short短毛 | cats/short_cat.tscn | Art/cat1new_animations.tres → Art/cat1new2/九张图集 |
| giant巨型 | cats/giant_cat.tscn | Art/cat5_animations.tres |
| static静电 | cats/static_cat.tscn | Art/cat8_animations.tres |
| lucky招财 | cats/lucky_cat.tscn | Art/cat10_animations.tres |
| alien外星 | cats/alien_cat.tscn | Art/cat14_animations.tres；idle／lift／hover／land／produce |

移除了后来增加的统一染色和临时项圈覆盖，五类modulate为白色，显示原图颜色。外星猫接入Cat14原色及独立起飞／悬浮／落地动画，取消旧绿色染色与程序触角。variant存档字段仍兼容，但不再覆盖四套素材原色。

## 运行结构与限制

main.gd绑定静态HUD／菜单；room.gd同步模型与Cats／Facilities／Workers中的场景实例；cat_actor.gd驱动Animation帧及位置；facility_view.gd支持编辑器预览和运行状态。当前3D入口由room_3d与actor_lighting同步同一模型，将猫／设施渲染为受光Sprite3D并投影；原2D实例层隐藏，避免重复。动画时钟仍由模型及cat_visuals共享，produce禁收、固定脚底、3像素转身过滤不变；Cat14视觉17帧压到原1.1秒模型时钟内。

库存、商店、升级图的列表项及数量变化的游戏对象继续由数据驱动；运行时在“远程”场景树检查。主场景本地树代表初始布局，不能显示尚未加载的玩家存档。新猫数量由经济模型决定，复制初始猫节点不会额外赠送猫；当前读取前两只初始猫的布局与种类。

不要重新运行历史bake/extract脚本覆盖场景，它们已冻结。新增测试需instantiate room.tscn，不能再Room.new()；独立测试窗口需自行设置尺寸锚点，修改模型后调用room.step(0)同步精灵。


2026-09-28第二次同步：short_cat的Animation与room_3d的两个初始Sprite3D均绑定新版图集。短毛资源包含idle/walk上下方向、pet、groom、produce，256×256切片；旧cat1_animations仍作为1.1秒模型冷却基准保留，不是当前短毛显示素材。预览与运行核对见reports/merge_cat1new_928。

## 独立“测试场景”（004）

打开`测试场景.tscn`按F6；F5仍是正式3D入口。展开Room / WhiteboxViewport / World3D / WhiteboxRoom / ActorLighting，或直接打开`test_actors.tscn`，可查看12猫、7设施、2工人和仪器的22个保存Sprite3D。`test_whitebox.tscn`独立网格／材质，`ui/test_hud.tscn`独立UI样式；共有美术原件保持引用。

真实模型的位置、猫种与毛层来自根下TestSetup的Marker2D与元数据。直接移动ActorLighting卡片只改静态预览，运行时会按模型同步；要改变实际预置，请改TestSetup。新模型由lab_model.configure构造，不受正式场景只读取两只初始猫的限制。

改TestSetup后需要刷新静态预览时，仅用本次`tests/refresh_lab_preview.gd`：先带`-- --textures`生成占位PNG，经编辑器导入后再带`-- --actors`保存test_actors。这是仅针对测试场景的预览工具，不运行冻结的历史bake、不覆盖room_3d或whitebox_room。正式与测试的屏幕投影和动画仍共用运行逻辑。

人设／存档／操作及343项验证见`../reports/lab_004/README.md`。

2026-09-28第三次同步（005）：正式room_3d与独立test_room/test_actors均已改引用cat1new2；静态卡片重新刷新。图集压缩时先解压CPU副本再裁切，保持固定脚底锚点。旧cat1new/cat1new1已由组员删除，历史Git中可追溯；不得恢复活动资源对它们的引用。

2026-09-29开发菜单：main、3D scene、测试场景均有持久化DeveloperDrawer实例。打开ui/developer_drawer.tscn编辑Tab、Panel、Header、Feedback与Scroll；命令列表由developer_tools.COMMANDS生成，菜单脚本developer_drawer.gd负责绑定。数字开发键已取消，悬停最左侧按钮看提示、点击展开。
