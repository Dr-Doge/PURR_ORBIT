# 《毛球计划》普通猫梳毛测试场景交接日志｜Agent移植版

日期：2026-10-17。来源：IMP-20261017-009，包含001—008未被替代的操作、反馈与手工布局。引擎：Godot **4.7.1.stable.official.a13da4feb**。

**交接任务：在新的场景中承载当前纯梳毛玩法，随后替换美术素材，并重新验证几何、工具判定和连续服务。本文是实施交接，不表示新场景或换图工作已经完成。**

## 1. 开始前先确定来源和范围

当前工作区根目录为`C:/Users/ruohaojing/Desktop/爽开`，Godot工程目录为`毛球满屋/`。下文`res://`均相对这个Godot工程，不相对工作区根目录。

先读根目录AGENTS.md、[18实装日志](../../摸猫增量策划案/18_实装变更日志.md)的009及[17参数总表](../../摸猫增量策划案/17_Demo数值总表与调参清单.md)第29.21，再核对实际代码。最新运行入口是`res://scenes/prototype_grooming/fur_demo.tscn`，**不是**`测试场景.tscn`、旧美容`main.tscn`或`robot_random_demo.tscn`。正式F5仍为原3D主场景。

本工作区有未提交的开发改动及用户的美术改动。接手先运行`git status --short`，保留现有工作，不用reset／clean／checkout恢复历史版本。原手工场景是用户保存结果，不运行生成工具覆盖它。历史报告目录及源PNG保持。

### 需要接手方补齐的实际输入

| 输入 | 本次状态 | 接手动作 |
|---|---|---|
| 新承载场景路径 | 未指定 | 同工程可建议使用`res://scenes/grooming_port/grooming_service.tscn`，先检查是否已有同名文件；这是建议，不是已创建文件 |
| 目标承载形式 | 未指定 | 先按2D全屏Control复制运行；若宿主是3D场景，按第4节做输入与显示桥接 |
| 新房间、台面、猫、工具及毛片 | 未在本次交接提供 | 定位项目已交付素材；缺少素材时可先用当前素材完成承载，换图保持待完成，不声称已经替换 |
| 主游戏顾客ID、收益及存档规则 | 未指定 | 使用明确的宿主接口；未提供时只保留本原型完成计数，不自行设计正式经济 |

不因缺少美术而停止“新场景原样承载”的独立步骤；不因准备好承载场景就把美术替换标完成。若目标工程或素材路径无法确定，可向用户询问这些具体输入。

### 本次必须保留的行为

- 只有普通猫纯梳毛，胸前／躯干／尾部；不恢复毛结、跳蚤、灰尘、修甲、痛感／评分、机器猫订单和旧岗位玩法。
- 按住左键，在操作区任意位置均可激活，再从左向右梳。齿边判定为竖向线段及窄带，不用梳子整张图或圆形刷子代替。
- 每片两遍有效顺梳。第一遍拉扯、恢复但保留；最后一遍只有恢复到原形时才脱落。松手保留已完成遍数；反向返回、微抖、纯点击不能额外计遍。
- 轮廓和普通毛片相同操作。轮廓在普通毛下面、整洁猫底图上面；颜色与Alpha公式相同，不恢复额外黑描边。
- 每片梳下毛都有唯一对应落毛，不使用旧“最多6片／总池16”限制丢弃真正掉落的毛。松散附加颗粒与真实落毛分开计数。
- 平台带猫升入，到顶猫接续单次轻微惯性；完成后停留、下降离屏，再准备下一只升入。没有重开／下一只按钮要求。
- 只有`cleaning`接受输入，暂停、失焦、UI遮挡、换顾客和转场清手势；暂停冻结模型、回弹、平台及粒子。

## 2. 代码与资源必须带齐

### 运行模块

| 路径（res://前缀省略） | 职责及耦合点 |
|---|---|
| `scenes/prototype_grooming/fur_demo.tscn` | 当前可玩Control场景；保存HUD、ServiceView及PlatformRoot/Table节点 |
| `scripts/prototype_grooming_fur/controller.gd` | 输入、每帧更新、声音及HUD；硬引用第3节列出的节点路径 |
| `scripts/prototype_grooming_fur/model.gd` | 毛片进度、拉扯／回弹、完成结算和连续顾客状态机；继承旧共用model |
| `scripts/prototype_grooming_fur/service_view.gd` | 按模型创建Sprite2D、Shader、粒子和工具；与model共享逻辑坐标 |
| `scripts/prototype_grooming_fur/coat_cleaning.gdshader` | 同一颜色／Alpha处理、真实拉扯形变和镜像支持 |
| `scripts/prototype_grooming_fur/brush_config.gd` | 两遍、回弹、落毛、升降等当前试玩值 |
| `scripts/prototype_grooming_fur/tool_geometry.gd` | 梳齿两端、朝向、贴图位置与有效接触线 |
| `scripts/prototype_grooming_fur/assets.gd` | 原图／独立切片读取、毛色场与CPU／GPU缓存 |
| `scripts/prototype_grooming_fur/presentation_profile.gd` | 房间、台面、猫、摆放矩形、服务区UV和手工布局配置 |
| `scripts/prototype_grooming_fur/authored_outline.gd` | 离树读取保存的身躯／轮廓几何，不运行编辑摆放脚本 |
| `scripts/prototype_grooming_fur/platform_shadow.gd` | 随平台及猫变化的接触阴影 |

**仍有共用依赖，不能只拷贝以上几个文件：**`scripts/prototype_grooming/model.gd`、`assets.gd`、`config.gd`、`foreground.gd`。Fur model／assets继承旧基类，配置提供Canvas、采样网格及方向判断；foreground转发前景绘制。旧config中的疼痛、修甲、订单交替等常量不代表当前启用。

同工程移植保留这些路径即可。跨工程建议先携带`scripts/prototype_grooming_fur/`与所需共用文件，再核对全部extends／preload／load引用。旧assets初始化需要`Art/grooming_demo_v1/atlas_index.json`，当前梳子也回退读取该目录的源图集；为避免遗漏，先带齐`Art/grooming_demo_v1/`，验证后才考虑裁减未使用资源。不用复制机器猫独立控制器来补依赖。

### 美术、配置和作者数据

| 路径 | 用途 |
|---|---|
| `Art/grooming_environment_v1/grooming_presentation.tres` | 当前默认配置，引用已交回的手工场景 |
| `Art/grooming_environment_v1/room_background.png`、`grooming_table.png`、`manifest.json` | 当前背景、透明台面及环境资源读取信息 |
| `Art/grooming_fur_v1/resources/cat_clean.tres`及其源图 | 当前整洁猫底图 |
| `Art/grooming_fur_v1/resources/*.tres` | 当前12身躯／8轮廓切片入口，仍为AtlasTexture |
| `Art/grooming_fur_v1/isolated_patches/*.res`、`isolated_patches.json` | 009已修复的独立同尺寸切片及来源记录，**必须携带** |
| `Art/grooming_fur_v1/atlas_index.json` | 语义key和原图来源；region不是当前毛片直接提取入口 |
| `Art/grooming_fur_v1/fall_variants.json`、`fall_variants/*.tres`、`fur_fall_fx.png` | 12种灰／乳白松散落毛资源及索引 |
| `scenes/prototype_grooming/轮廓毛发摆放.tscn` | 用户手工几何；009同时读取其中锁定的身躯参考 |
| `scripts/prototype_grooming_fur/editor_outline_piece.gd`、`Art/grooming_fur_v1/editor_placement/*.res` | 手工场景的编辑预览依赖，虽然不进入运行树仍需能加载 |

`tools/build_clean_fur_assets.gd`可复现当前图集的隔离切片；`tools/create_outline_placement.gd`是历史首次生成器，**不要针对用户原场景再运行或绕过拒绝覆盖**。构建清理工具也不能盲目用于全新的不同版式图集。

当前controller和assets会预载旧默认profile，Model构造也先准备默认顾客，随后才在_ready应用新配置。**跨工程不能只携带新profile、删掉旧默认配置及其资源链。** 先保留完整依赖使模块可启动，或者明确完成默认依赖／构造注入重构，再验证新入口；未做重构时，Inspector指定新配置不等于旧预载依赖已消失。

## 3. 原样移入新场景的第一步

先复制`fur_demo.tscn`到目标场景，保留脚本和节点路径，用当前素材完成一次F6运行。不改正式project.godot主入口，不覆盖原测试场景。需要自定义UI时，在这一步验证后再调整。

当前controller直接查找以下路径，重命名或删除时必须同步修改脚本：

```text
<Control 根>
├─ EditorPreview                         # 运行时隐藏，可选；换图要同步静态预览
├─ ServiceView                          # service_view.gd，铺满操作区
│  └─ PlatformRoot
│     └─ Table                          # 必须存在，Sprite2D
└─ HUD
   ├─ Top/{Title, Money, Pause, Sound, Size}
   ├─ Bottom/{Requirements, Hint, Progress}
   └─ PausePanel/VBox/Continue
```

运行时View建立ContactShadow、SubjectRoot/CleanSubject、RemovableDirt、粒子、ToolCursor和InteractionGuides。不要把手工摆放场景整个加入游戏显示树，否则参考猫、素材区、标签会重复出现。它仅作为数据来源。

**本地显示层次：**猫底图0、轮廓Sprite1、身躯Sprite2；猫整体在平台SubjectRoot内，活动落毛属于PlatformRoot并位于附着毛上方；工具和前景提示位于操作视图上层。台面、猫、毛片和落毛跟随平台，房间／HUD不跟随。不要只移动台面图而让猫和毛停在原位。

复制默认profile到新资源后，在新场景根节点的`presentation`字段指定它。该值在controller._ready中调用configure_presentation生效；只替换EditorPreview图片不会改运行素材。若暂时只换房间／台面、猫和工具不变，可以继续使用旧猫布局。

## 4. 宿主接入、坐标和输入

当前模块是**2D Control＋Sprite2D**，不是3D猫或3D梳子。所有物理／绘制规则基于1920×1080逻辑画布；视图使用`size / C.CANVAS`换算。当前已验证1920×1080和1440×810，不能把任意宽高比或相机缩放当作已验证。

推荐先让新场景提供16:9操作区域。其它窗口比例用留边或等比容器保持它；直接拉成非16:9会按X／Y分别缩放，工具和猫可能变形。若宿主是3D船舱，可用CanvasLayer承载本2D操作界面，或SubViewport显示到3D表面；后者必须把射线命中的显示区域映射为SubViewport像素，再交给ServiceView，不能直接传世界坐标。

输入只走一条路径：`ServiceView._gui_input → controller.surface_input → pending_paths → model.stroke`。宿主转发事件时先转成ServiceView局部像素，随后调用现有`to_logical`／`model_point`；不要对已是局部坐标的GUI事件再重复减偏移。`model_point`还会逆变换平台偏移和猫惯性，不能在升降／惯性时直接用屏幕坐标碰撞。

新HUD整屏容器应合理设置mouse_filter，装饰容器使用IGNORE，真实按钮拦截输入。不要让一个透明、铺满屏幕的Control持续挡住ServiceView。抬起／激活姿态、齿边线和碰撞必须共用Tool数据。

若保留controller，它已经每帧执行model.tick和view.animate，**宿主不能再更新同一模型一次**。如果改为宿主驱动，需要替代其完整输入清理、暂停、声音／粒子节流及帧更新，不是仅调用stroke。View.game需要提供`dragging`和`surface_input`等当前接口；不能随意指向一个空Node。

### 现有顾客接口

| 接口 | 实际行为及接手要求 |
|---|---|
| `configure_presentation(profile)` | 校验、切缓存并重新准备顾客；用于启动配置，不在正在梳理时换皮 |
| `queue_customer(profile=null, scale=0)` | 排下一只配置／大小；scale只接收0保持、1或.5。它是一个“下一只”槽位，不是完整FIFO队列 |
| `automatic_cycle=true` | 默认自动连续服务 |
| `automatic_cycle=false` | 到reward等待宿主，宿主处理后调用release_customer |
| `release_customer()` | 只在reward且settled时有效，重复调用返回false；启动下降 |
| `customer_prepared(serial)` | 下一顾客已重建；初始化和configure时也可能发出，连接时机需核对 |
| `customer_ready(serial)` | 升降／惯性结束，可以操作 |
| `customer_completed(serial, amount)` | 该顾客完成一次；amount是旧基类试玩值，不代表主游戏正式收益 |
| `customer_departed(serial)` | 当前顾客已完全离屏，此后重建下一只 |

宿主用serial绑定真实customer_id，去重结算。model.wallet、served是测试计数，不能同时把wallet变化和completed信号都换成正式货币。正式身份、收益、库存和存档由宿主负责，本原型不提供迁移实现。

## 5. 换美术按两种情况处理

### 5.1 只换房间和台面

复制profile，替换room_texture、table_texture并调整table_rect。背景可不透明；台面要有透明外缘，主体与金属支撑可用一张图或多个同属PlatformRoot的节点。保留旧猫／工具／布局即可先验证新环境。更新EditorPreview相应引用，避免编辑器看到旧图、运行看到新图。

### 5.2 换猫底图、毛片、轮廓和工具

必须复制profile与手工场景为新文件，再对新副本工作。当前outline_layout绑定旧灰白猫和其身躯参考，**只换cat_texture不会把几百片旧毛自动移到新猫身上**。

| 更换项 | 具体操作／限制 |
|---|---|
| 猫底图 | 透明底，裁掉无关背景及过大留白；cat_texture决定实际图像尺寸。当前保持左→右操作，先选头在左、尾在右的姿态；若反向，需一起适配底图、布局与方向，不只翻一张图。当前kind强制calico，是普通猫操作规则，不能仅为改名字设置成robot |
| 猫摆放 | cat_fit_rect是1920逻辑坐标内的容纳框；按图片宽高比缩放、底边对齐。实际脚底是否落在台面还需看透明留白，不能只算纹理矩形 |
| 服务区 | service_chest／body／tail为相对实际裁剪猫图的0—1 UV多边形；重新标定头脸排除、四脚排除与尾部，不直接沿用旧坐标 |
| 手工版布局 | 调整新副本body_rect／cat_scale、底图和所有普通／轮廓节点；当前reader按区域相对变换读取，不能只移动整洁猫底图而保留旧毛片 |
| 程序版回退 | 明确设置新profile.outline_layout=null，重新校准outline_paths与服务区；结果不保证与手摆相同，仍需实际检查 |
| 新毛片资源 | 每种Sprite引用可保存、带resource_path的Texture2D／AtlasTexture资源；轮廓文件basename必须以edge_开头。同一布局中不同图形使用不同basename，避免缓存按type合并后显示成同一张图。内嵌无稳定路径的纹理可能不能识别 |
| 手工分组 | 保留大猫摆放区／小猫摆放区、参考底层_请勿移动/当前身躯毛片_锁定、可编辑轮廓及其分区结构，或者同步修改reader。父分区service_region决定轮廓区域，身躯Sprite元数据提供区域 |
| 小猫坐标 | 当前小猫区仅为编辑方便右移2240px；reader去掉此区偏移，不能把2240带进运行。大小1／.5目前是接口约定，不自行扩成任意大小而不改接口 |
| 身躯尺寸 | 当前两种猫身上的普通毛片均96×72逻辑px，新素材分辨率变化不能直接变成更大的交互单位；新体型需要重新决定铺密度，不强行凑337／76片 |
| 裁剪 | 单片只含自己的完整主体及柔边。009独立切片保持原画布／中心；新图若改裁剪框宽高或偏移，必须同步摆放和锚点，不是仅改纹理路径 |
| 毛色 | 普通毛与轮廓使用同Shader、同Alpha公式；保持轻微色差与体积明暗，不恢复近黑描边绕过染色 |
| 深色或新色猫 | coat_reference目前用Alpha>.75、RGB最大通道>.46判定有效颜色，再向外延伸；纯黑／深色猫可能被当作描边过滤。需要按新素材调整取色规则或提供明确毛色场，不默认任意颜色已支持 |
| 落毛 | 当前gray／cream两套共12资源，type的cream或edge_cream前缀决定落毛色组，其余默认gray；新颜色需同步改语义和fall_variants索引／筛选，不能让蓝猫掉灰白毛 |
| 梳子 | 当前裁剪图为585×398，TOOTH_FIRST=(80,377)、TOOTH_LAST=(431,240)。新图必须重新标定齿边两端，核对flip_h、旋转和中心偏移，保证头向上柄向下、齿侧向右 |
| 有效齿边 | 当前竖向长度110px、窄带半宽6px；同一tool_geometry生成绘制和接触线。不是整张梳子矩形，也不是圆半径 |
| 阴影与视角 | platform_shadow按现有猫与台面参数绘制；换猫脚位和台面视角后复核落地阴影。整体3D视觉不等于模型已支持3D坐标 |

`presentation.validation_errors()`只检查基本纹理／矩形／多边形有效性，不证明毛片位置、工具齿边和新猫完全适配。`authored_outline_errors`必须为空，同时确认预期对象确实存在；空场景或错误fallback不能作为成功。

当前手工优先分支会同时读取锁定身躯和轮廓，普通毛也因此固定。若新场景希望按程序生成新身躯但仍用手摆轮廓，需要显式修改这一分支并单独验收，不可误以为现在已经这样工作。

## 6. 必须保持的状态和资源约定

对象使用rect、draw_angle、flip、left／mask、passes、counted、stroke_travel、pull_amount、returning、return_left、detach_pending和done等字段。所有绘制和接触使用同一形变坐标。首次拉扯结束不清毛；最后回弹归零的同一步才clear_object。

`counted`避免一次连续滑动按多个鼠标事件计成两遍；透明缝也不能把一次顺梳拆成多遍。复制来的source_id只是作者快照，运行id必须重新生成且与对象数组／view.object_sprites对应，不能让两片共用落毛身份。

切顾客靠model.version重建视图，并清旧落毛；切阶段／版本后controller清输入。不要跳过version更新去直接替换某张Sprite，造成判定仍使用旧图、显示换了新图。

assets.configure_presentation清images／textures／authored_sources／pigment，换图必须走配置或顾客队列接口。相同实际资源共享GPU纹理；别在每帧或每片毛重建大图。

`atlas_index.json.region`是原图来源记录，009当前资源已指向isolated_patches独立图。绕过资源重新get_region原图会把悬浮邻图碎角带回来。清理后的Alpha也用于接触，不能只在Shader里视觉隐藏。

## 7. 当前参数基线（试玩值，不是新场景最终定稿）

完整数值唯一维护于17第29.13—29.21；以下是交接时从代码核对的工作基线。

| 项目 | 当前值 |
|---|---|
| 画布／采样 | 1920×1080；猫mask256×128，每片接触网格32×32 |
| 正向约束 | delta.x/delta.length≥.70；左右返回不扣评，没有当前速度惩罚 |
| 单片 | 2遍，每遍有效行程12px；静止／3px微抖不能替代 |
| 拉扯 | 最大18px，每移动px拉扯系数.45，离触.08s后恢复；恢复.28s |
| 附着片Alpha | 原Alpha×顶点Alpha×mask×valid×loosen，当前loosen=1；不额外给轮廓一套透明度 |
| 真实落毛 | Alpha=.38，每片对应，寿命2.2s，先保持.2s再渐隐；池初始16但按需扩容复用 |
| 附加碎毛 | Alpha=.65，上限10，发射间隔.20s；与真正落毛分开 |
| 下落 | 初速向下68—88px/s，重力26px/s²，最大130px/s，横漂±10px/s；不朝上喷射 |
| 大落毛尺寸 | 使用松散毛图等比放入原片目标框的.9—1.1倍，不要求纹理等于附着贴片 |
| 升降 | 行程1200px，升入1.15s；前72%升到顶，后段猫单次9px惯性，平台到顶保持固定 |
| 接续 | 完成停留.55s，下降.85s，完全出屏再重置下一只 |

tool_geometry中SPEED_LIMIT等字段和旧config的疼痛／订单常量是历史或共用定义，**不是当前纯梳毛惩罚规则**。改移植参数后同步17与18，区分试玩选择与用户确认。

## 8. 实施步骤和交付检查

| 步骤 | 工作 | 完成条件 |
|---|---|---|
| MIG01 | 核对源码、009报告、目标场景和素材，记录本轮实际范围 | 明确同／跨工程、目标路径；保留已有改动和手摆原件 |
| MIG02 | 复制当前场景到新入口，保留当前素材和节点契约 | 新入口可F6；至少三只连续完整处理，原测试仍可运行 |
| MIG03 | 复制新profile，接房间／台面／宿主UI及坐标 | 新画面与台面升降正确，工具操作区及UI不冲突 |
| MIG04 | 准备新猫／毛片／轮廓／工具／落毛，标定服务区和新手工布局 | 没有邻图碎角，头脸脚位符合目标；颜色、尺寸和梳齿都匹配 |
| MIG05 | 需要时接顾客ID和单一收益入口 | serial归属正确，不重复付钱，不修改正式档做测试 |
| MIG06 | 做新场景针对性自动输入／截图和真人手感检查 | 满足下方验收；新结果不冒充旧8888项 |
| MIG07 | 回写18和17实际入口／差异／证据，给出新场景交付说明 | 可以从新文档直接打开新入口，说明仍未完成的美术／主游戏部分 |

### 新入口最低验收

- 新场景可以单独打开，profile实际生效，旧原型和机器猫场景未被误改。
- 大小猫分别有预期可处理对象；NodePath唯一、纹理资源可加载、区域／脚爪／尾部标定合理。新猫片数以新布局为准，不固定旧52轮廓。
- 梳子未按住抬起、按住激活；从背景按住移入也有效，齿线与实际接触一致。至少在两种16:9尺寸、宿主有偏移时用真实鼠标事件验证。
- 每片两遍，第一遍恢复后保留，最后恢复后掉落；回退和密集事件不增加遍数，松手不清已完成进度；附着图、形变判定和透明区一致。
- 身躯和轮廓均能梳完，轮廓在下；没有悬浮邻图碎角或不同材质的强烈黑边；替换颜色后附着毛与落毛一致。
- 每个源片有唯一落毛，贴片多时不漏、不重复；旧片隐藏之后，随机松散毛下落与渐隐，未梳区域仍可辨认。
- 全部完成只结算一次；连续三轮上升／惯性／梳理／下降无残留输入、毛片或旧粒子；暂停冻结所有环节、恢复不跳阶段。
- 下一只的美术、mask和缓存到离屏后才切；当前猫不被排队操作中途换皮。非法配置不能丢失正在服务的顾客。
- 在替代素材后重新看脚爪、边缘和新色取样，完成真人观感确认；旧版的自动通过不能替代新美术验收。

### 当前可用复测入口

以下PowerShell从工作区根目录执行，路径和空格需按实际目标改。默认测试仍加载原fur_demo，**复制场景后要另写／复制测试用例加载新入口**，不能只跑这些便声称新场景通过。

```powershell
& '.\毛球满屋\tests\run_grooming_fur.ps1'
& '.\.tools\godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe' --path '毛球满屋' --script res://tests/test_fur_asset_cleanup.gd
& '.\.tools\godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe' --path '毛球满屋' --script res://tests/test_authored_outline.gd
```

新测试复制后把报告出口改到新的独立reports目录，保留009历史结果。GUI进程如用Start-Process启动，使用WindowStyle Hidden。只写独立测试档或纯内存，不覆盖正式存档。

## 9. 基线证据、已知限制及回写格式

最新证据：[fur_asset_cleanup_20261017/README](../../毛球满屋/reports/fur_asset_cleanup_20261017/README.md)及scope.json：665素材／GPU、4213模型、1806GUI、2204手摆／层级，共8888项，重复回归不能当独立功能数。当前已验证的是旧猫素材和本测试入口，未生成最新EXE，未执行此次新场景移植。

当前大猫337＋52，小猫76＋52；5片手工轮廓在最大拉扯范围与原脚爪参考禁区重叠，路径见model.json.manual_foot_overlaps。原位保留，不能写成“脚爪美术已全部验收”。改用新猫时重新摆放复核，不擅自覆盖用户原布局。

现有实现仍继承旧基类，并有固定命名、灰／乳白色组和默认profile依赖；不是任意资产一键接入、任意3D视角均已适配的通用框架。新场景、美术文件和正式顾客规则尚未指定，不补造完成记录。

交付时回写：`目标工程与场景路径 / 来源009 / 新profile和布局路径 / 替换素材清单 / 实际保留或改变参数 / 新验收脚本与报告 / 真人待验项 / 主游戏与存档接入状态 / 是否导出或推送`。使用真实提交号，没有提交就注明未提交，不因旧版本有EXE便声称新入口已发布。

本次交接文档核对了实际源码和009证据；只整理移植说明，没有创建目标场景、接收新美术、改玩法代码或执行移植。
