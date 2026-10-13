# Purr Orbit 场景资产清单与制图 Prompts v1

状态：制作提案，依据本次对话确认的概念方向；尺寸为首轮制作建议，不是现有工程参数。本文不修改玩法或工程。

## 1. 视觉基准

- 温馨的科幻猫咪生活舱：米灰、燕麦白、暖褐、低饱和深灰；琥珀色照明。避免大面积蓝绿色与暖橙对撞。
- 清晰勾线、整洁色块、少量受控的明暗。轮廓较强，内部结构线较弱；不使用纸张纹理、水彩、密集做旧、写实金属高光。
- 固定的正面浅透视镜头，完整地面占主要画幅；侧墙顶部可见，前景仅在两侧边缘点缀。
- 模块化在尺寸、接缝、接口上成立，不用粗黑网格或密集螺钉强调。
- 轨道回收接口是通向操作舱的门与控制台，接收密封回收舱；不画成垃圾回收机或售货机。
- 窗外宇宙面积较小。资产本身不带整幅房间的灯光：中央暖光、主要投影、局部发光由引擎组合。

视觉主参考：本轮最终米灰暖褐版本 `exec-935d3a80-f6a5-4f08-af71-51e6a782f898.png`。生成时应附上该图，指定“只参考画风、配色与细节密度，不复制构图，不把整间房画进资产”。

## 2. 尺寸与摆放约定

- 先以 1U 为一块地板边长；建议每 U 对应 256 像素有效贴图。U 是项目自定单位，不预设为米。
- 墙体高度暂定 2U，墙厚 0.18U；墙宽按 1U、2U 拼接。最终由镜头样板验证再锁定。
- 图表分辨率为建议交付画布。透明留白不计入物体世界尺寸；物体有效边界、接地点需要另外记录。
- 结构贴图采用正投影视图：墙是正面、地板和墙顶是俯视。相机负责透视，不能把已画好透视的整面墙再贴到斜面上。
- 家具和前景采用与游戏镜头一致的“正面、略见顶面”的插画；它们是单张或少量分层的立式贴片。
- 建议先将 1U 地板、1U 墙板、窗框、1 只猫、1 台设备放在同一画面验证线宽。可先试外轮廓约 3–4px / 256px、内线约 1–2px，最终以游戏缩放后的观感为准。
- 可平铺素材不留透明边；透明素材使用真实 Alpha，不把黑色、白色或棋盘格当透明。

## 3. Asset list

P0：先搭建样板；P1：完整概念场景；P2：展示或动画扩展。共 29 个资产条目，部分条目含变体或分层；不是 29 张最终图片。

| ID | 资产 | 优先级 | 建议规格 / 画布 | 交付与复用方式 |
|---|---|---|---|---|
| A01 | 标准地板 | P0 | 1U×1U；256×256 | 不透明、可平铺；基础 1 张 |
| A02 | 检修地板变体 | P1 | 同 A01 | 1 张；边界与 A01 完全一致 |
| A03 | 地面周边收口直段 | P0 | 1U×0.25U；256×64 | 不透明；沿长度重复 |
| A04 | 地面周边转角 | P0 | 0.25U×0.25U；64×64 | 不透明；和 A03 配套 |
| A05 | 标准内墙板 | P0 | 1U×2U；256×512 | 不透明；后墙、左右墙共用 |
| A06 | 检修墙板变体 | P1 | 同 A05 | 不透明；通风口与检修盖整合在板内 |
| A07 | 墙顶封边 | P0 | 1U×0.18U；有效约256×46 | 不透明；水平面，沿长度重复 |
| A08 | 侧墙前端封边 | P0 | 0.18U×2U；有效约46×512 | 不透明；竖直封口 |
| A09 | 墙脚直段与转角 | P0 | 高0.15U，按1U重复 | 不透明窄条；直段与角件分别导出 |
| A10 | 墙板竖向连接条 | P1 | 0.12U×2U；有效约31×512 | 透明外轮廓；在墙板交界覆盖 |
| A11 | 舷窗框组件 | P0 | 外框约1.4U×0.85U；512×320 | 透明窗洞；外框与下窗台分层 |
| A12 | 宇宙背景 | P0 | 建议2048×2048 | 不透明单张；整间房共用，旋转/移动由引擎处理 |
| A13 | 回收接口门框 | P0 | 约1.8U×2U；512×576 | 透明门洞；轮廓克制，不做巨大拱门 |
| A14 | 双开舱门 | P0 | 按 A13 内洞精确配套 | 左右门叶独立 PNG，闭合可无缝对齐 |
| A15 | 接口门槛与接收托座 | P1 | 约1.5U×0.45U；512×256 | 透明；门槛/托座可分层 |
| A16 | 毛团交付与接驳控制台 | P0 | 约0.4U宽；256×384 | 外壳、屏幕底板、状态灯分层 |
| A17 | 密封回收舱 | P1 | 约0.6U宽；256×320 | 主体透明 PNG；P2 拆舱盖 |
| A18 | 条形舱灯 | P0 | 横向约0.4U×0.12U；256×96 | 外壳、灯罩、发光遮罩分开；横竖可复用 |
| A19 | 管线连接套件 | P1 | 外径约0.06–0.1U | 直管、弯头、T形接头、端帽、管夹分别导出 |
| A20 | 嵌入式猫窝 | P1 | 约1.5U宽；512×512 | 外壳前框、暗色内衬、软垫、搭毯分别导出 |
| A21 | 喂食设备 | P1 | 约1U宽；512×512 | 主体、粮仓玻璃/粮食、食盆可分层 |
| A22 | 梳毛设备 | P1 | 约1U宽；512×512 | 前框、内刷、踏板分开；内刷可动画 |
| A23 | 壁挂小搁板 | P1 | 约0.8U宽；256×128 | 透明；不附带植物和摆件 |
| A24 | 盆栽 | P1 | 小盆栽/垂吊植株各1款；256×384 | 透明；叶绿仅作少量自然点缀 |
| A25 | 猫形小摆件 | P2 | 约0.2U宽；128×128 | 透明；不与搁板合并 |
| A26 | 左右前景细框架 | P1 | 每侧最终覆盖画宽约2–3%；256×1024 | 左右各1款透明 PNG；同高、细节可不同 |
| A27 | 前景管线点缀 | P1 | 256×512 | 透明；细弯管/线缆各1款，无巨大管道团 |
| A28 | 操作舱后方暗色衬景 | P1 | 按 A13 内洞；512×576 | 门后浅层插画，不能包含另一套门框 |
| A29 | 回收接口状态标识 | P2 | 单图128×128 | 待机/可接驳/交付中/可领取4态；最终文字由 UI 绘制 |

不纳入本次静态场景制图：猫的动作 spritesheets、HUD、按钮文案、资源图标、真实灯光、碰撞与移动区域。现有猫先作为样板比例参考；需要统一画风时另立角色资产任务。

## 4. 制图 Prompt 使用方式

每次只生成一个明确资产。完整 prompt = 下方“共同前缀” + 对应“视图前缀” + 单项 prompt + “共同排除项”。有尺寸/接口依赖的项目，应附上已验收资产作为额外参考，不仅靠文字约束。

AI 出图不能保证像素级拼接、准确尺寸、Alpha 或一致的图集切片。下列 prompt 是美术制作起点；尺寸、抠图、接缝、锚点与遮罩须检查并整理后交付。

### 共同前缀

```text
Create a production art asset for Purr Orbit, a cozy illustrated science-fiction orbital station inhabited by cats. Use the attached approved scene ONLY as a reference for palette, outline hierarchy, shape language and detail density. Do not reproduce the whole room. Clean confident warm dark-brown ink contours, restrained thinner interior lines, smooth color fills, simple broad shadow shapes. Palette: oatmeal cream, light warm gray, mushroom taupe, subdued charcoal brown-gray, small muted bronze details. Amber light lenses are accents, not a global orange filter. Friendly rounded engineering, clear functional construction, tidy modular panel joints. Maintain a layered flat 2D cutout-game appearance. Neutral soft material presentation; keep environmental lighting separate.
```

### 视图前缀 S：结构表面

```text
This is a flat surface texture, not an illustration of a 3D object. View perpendicular to the specified surface, orthographic, no perspective, no visible thickness or adjacent faces. Fill the usable texture area precisely. No cast shadow, light pool, vignette or background scene. Opaque surface unless an opening is explicitly requested.
```

### 视图前缀 C：透明立式贴片 / 分层组件

```text
Isolated 2D sprite artwork on a genuinely transparent background. Use a front-facing view with only a slight view of the top where appropriate, matching the approved fixed game camera. Complete uncropped silhouette with a small transparent safety margin. Keep the baseline/contact point stable. No painted floor, no cast shadow outside the object, no surrounding room. Subtle intrinsic shading is allowed; do not bake warm scene lighting into the sprite.
```

### 共同排除项

```text
Avoid photorealism, glossy 3D renders, thick beveled modeling, uniformly heavy black interior lines, pixel art, paper grain, watercolor, brush noise, dense scratches, distressed paint, high-contrast teal-and-orange color schemes, unnecessary bolts, captions, logos, UI, watermarks and baked checkerboard transparency. Do not add objects not requested.
```

## 5. 单项 Prompts

### A01 标准地板 · S

```text
One square modular spaceship floor plate, viewed straight down. Pale warm-gray enamel, calm nearly uniform center, very subtle narrow seam indication at the four edges. A restrained repeated small fastening detail near corners. No raised bevel or highlights around every edge. All four edges must connect identically to copies of this tile; avoid double-width seams when tiled. Square 1:1 texture. The floor must remain visually quieter than cats and equipment.
```

### A02 检修地板 · S

```text
Create a service-access variant of the attached approved A01 floor tile. Preserve its exact square boundary, corner fastening positions, edge colors and seam widths. Change only the interior: one shallow drawn access-panel outline and a small recessed latch, with a very slight warm-gray tonal difference. No green patch, warning stripes or added directional light. Square 1:1 texture.
```

### A03 地面收口直段 · S

```text
A top-down narrow straight perimeter trim texture for the approved floor. Warm graphite-gray outer strip and a subdued lighter inner lip indicated by flat colors. Aspect ratio 4:1. Repeat continuously along the long horizontal direction, with identical left and right end cross-sections. No corner, lamp, perspective, extra bordering floor or irregular wear.
```

### A04 地面收口转角 · S

```text
A square top-down 90-degree corner piece matching the attached approved A03 perimeter trim exactly. Continue the dark outer strip and lighter inner lip around the corner. Match connecting-edge widths and colors without gaps. No new ornament, extra bevel, lighting or perspective. This is one corner texture, not a set of four.
```

### A05 标准内墙板 · S

```text
One rectangular spaceship interior wall bay, width to height ratio 1:2, viewed straight on. Upper region oatmeal cream, lower service band muted warm taupe-gray at a consistent height. Thin precise panel joins, rounded panel corners and at most a few unobtrusive fastening marks. Simple functional sci-fi graphic design with generous quiet surfaces. No window, door, pipe, lamp, vertical post or floor. Adjacent bays must share the same edge colors and lower-band height.
```

### A06 检修墙板 · S

```text
A variation of the attached approved A05 wall bay, same exact size, perimeter and lower service-band height. Add one compact recessed ventilation grille and one simple maintenance access cover INSIDE the bay, leaving all connection edges unchanged. Warm neutral colors, flat outlined engineering detail, restrained contrast. No emissive lights or perspective.
```

### A07 墙顶封边 · S

```text
An overhead orthographic texture for a thin wall-top cap strip. Length to width ratio approximately 5.56:1. Warm medium-gray matte metal, one subtle lengthwise join, simple narrow edge contour. Repeat seamlessly along its length. It is ONLY the top surface: no visible wall side, no perspective, no rounded extrusion, lamp or cast shadow.
```

### A08 侧墙前端封边 · S

```text
A front-facing narrow vertical texture that closes the exposed end of a thin spaceship wall. Width to height ratio approximately 0.09:1. Match the attached wall-top cap and wall panel palette. Quiet warm graphite-gray center with a restrained thin edge line. No neighboring wall faces, no perspective or pre-painted thickness. One clean vertical surface.
```

### A09 墙脚 · S

```text
A straight front-facing baseboard strip for the approved wall system, width to height ratio approximately 6.67:1. Dark warm-gray lower band with a thin muted beige upper edge. Seamlessly repeating horizontally. No lamp, floor, perspective or projected shadow. Match the standard wall's bottom edge. Generate the straight strip first; a matching corner component is a separate follow-up after approval.
```

### A10 竖向连接条 · C

```text
One very slim straight vertical wall-panel connector, orthographic front view. Width to height ratio approximately 0.06:1. Flat warm-gray metal silhouette, two small muted bronze fastening collars, minimal interior detail. No tube bundle, thick pillar, floor, perspective or bright lamp. Transparent outside the connector silhouette.
```

### A11 舷窗框 · C（需改用严格正面）

```text
One rounded rectangular spaceship window frame in STRICT front orthographic view. Overall ratio approximately 1.65:1. Cream enamel outer frame, narrow warm-gray gasket, thin secondary rim suggesting shallow layered construction. Completely transparent central window opening and transparent exterior. No glass, stars, planet, reflections, wall or room. Keep the bottom sill visually simple; provide the sill as a separate matching layer in a follow-up rather than fusing a deep ledge into the frame.
```

### A12 宇宙背景 · 不使用 S/C

```text
One square illustrated deep-space background texture for viewing through small space-station windows. Quiet near-black navy space, sparse stars with a few very subtle warm points, one softly shaded partial distant planet off-center and a few small distant rocky silhouettes. Low visual density and restrained contrast. Clean smooth illustrated shapes, no photographic nebula noise, no bright galaxy, no spaceship, window frame, room, lens flare or text. Opaque full square image. Leave broad quiet regions so multiple small windows can reveal different parts of this SAME image.
```

### A13 回收接口门框 · C（严格正面）

```text
One slim rounded rectangular orbital recovery airlock frame, STRICT front view, width to height ratio approximately 0.9:1. Cream outer surround, muted warm-gray inner seal, a few simple segmented joints. Door opening and outside silhouette completely transparent. This is a restrained functional doorway, not a huge heroic arch. No door leaves, console, lamp, tunnel, floor, capsule, text or warning stripes. Clear inner opening boundary for separately fitted sliding door panels.
```

### A14 双开舱门 · C（严格正面）

```text
Design a CLOSED pair of flat sliding airlock door leaves fitted exactly to the opening of the attached approved A13 frame. Strict orthographic front view. Oatmeal cream panels, vertical center seam, small restrained warm-gray observation disc across the center, simple handles and minimal warm-gray lower reinforcement. No frame, console, perspective, tunnel or floor. Transparent outside the fitted door silhouette. This master image will be split into separate left and right leaves afterward; maintain a precise straight center split and continuous closed-door alignment.
```

### A15 门槛与托座 · C

```text
A low compact illustrated receiving threshold and cradle for the orbital recovery hatch, aligned to the attached approved doorway. Front view with only a slight top surface visible, broad low silhouette. Muted warm-gray metal, a few shallow guide grooves, discreet bronze clamps. Shallow layered 2D construction, no long railway, deep tunnel, giant platform, capsule or hazard stripes. Transparent background; keep the approach area visually unobstructed.
```

### A16 接驳控制台 · C

```text
One compact wall-mounted orbital recovery control console, slightly tilted screen face toward the viewer, matching the approved doorway scale. Rounded cream housing, muted warm-gray inset display, simple ivory signal arcs and a small capsule symbol, one small amber status lens, discreet energy-input socket beneath screen. No readable text, currency, numbers, teal glow, giant hologram or vending-machine opening. Transparent background. Keep display and lamp regions simple so separate masks can be prepared afterward.
```

### A17 密封回收舱 · C

```text
One small sealed orbital recovery capsule designed to fit the approved receiving cradle. Friendly compact rounded container, cream shell, warm charcoal seam, small bronze locking tabs and a simple carry recess. A distinct lid seam clearly separates lid and body. No window containing a cat, no limbs, face, exhaust, text, icon reward or glowing aura. Shallow illustrated volume, not a glossy modeled sphere. Transparent background. It should read as a delivered collectible cargo capsule.
```

### A18 条形舱灯 · C（严格正面）

```text
One small horizontal rounded rectangular spaceship wall lamp in strict front view. Thin warm-gray housing and clean pale amber inner lens. Roughly 4:1 overall proportion. No bloom, halo, light rays or illuminated wall around it. Transparent outside the lamp silhouette. The lens is a clearly separable simple region for an emission mask. No extra controls or text.
```

### A19 管线套件 · C（严格正面，每次单件）

```text
One [straight pipe / 90-degree elbow / T-junction / end cap / mounting clip] for a modular illustrated spaceship conduit kit, strict front orthographic view. Uniform diameter and identical connection ends matching the attached approved straight pipe. Warm dark-gray tubing, understated muted bronze collar, simple two-tone shading and restrained contour. No glowing fluid, extra bundled cables, dramatic perspective, rust or background. Render only the single requested component with transparent exterior.
```

### A20 嵌入式猫窝 · C

```text
One cozy built-in cat sleeping nook for the approved space station. Front-facing illustration with slightly visible cushion top. Rounded cream shallow shell, warm-gray interior recess, soft dusty-apricot cushion and one simple oatmeal blanket draped over lower lip. Friendly clean contour and broad simple shading. No cat, plant, surrounding wall or floor. No heavy texture or deep 3D cavity. Design clear separable boundaries between front shell, dark backing, cushion and blanket for later layer extraction.
```

### A21 喂食设备 · C

```text
One compact futuristic cat feeding station, front view with slight top visibility matching the room camera. Rounded cream base, muted warm-gray inset panels, two shallow bowls, one upright transparent food reservoir containing a modest amount of brown kibble. Functional tiny amber lens, simple housing seams. No lettering, pipe extending out of frame, cat, floor or cast shadow. Clean illustrated cutout, restrained flat shading. Reservoir, food fill and bowls have clear boundaries for optional animation layers.
```

### A22 梳毛设备 · C

```text
One compact cat grooming arch, front view with slight top visibility matching the room camera. Cream rounded casing with warm-gray panel inserts, dark soft brush opening, low entry step, one small amber indicator. No cat, steam, floor, cast shadow or long tunnel. Keep the arch shell, inner brushes and step visually separable so the brush layer can animate. Friendly useful sci-fi device, clean 2D illustration with shallow volume and no teal casing.
```

### A23 壁挂搁板 · C

```text
One short wall-mounted shelf, front view with a slight top surface. Matte warm-gray supporting brackets and a thin muted warm-brown enamel shelf surface. Simple clean sci-fi construction, no rustic wood grain, objects, plants, wall, external cast shadow or text. Transparent exterior and complete silhouette.
```

### A24 盆栽 · C（两款分别生成）

```text
One [small upright potted plant / trailing potted plant with a short hanging vine] for the cozy station. Small muted terracotta pot, rounded desaturated natural green leaves, clean warm dark outlines and minimal interior detail. Front view with a slight view of pot top. No shelf, wall, floor, background shadow, flowers or additional pots. Keep the plant compact and secondary to game characters. Transparent background.
```

### A25 猫形摆件 · C

```text
One tiny cream cat-shaped desk ornament with a simple rounded silhouette, two ears and a minimal sleepy face. Warm brown tiny facial marks, restrained shallow shading. Front view with only slight top visibility. No platform, shelf, text, plant, shadow or accessories. Transparent background, readable at small game size.
```

### A26 前景细框架 · C（左右分别生成）

```text
One tall SLIM foreground mechanical structural rib for the [left / right] extreme edge of a cozy spaceship game view. Front-facing flat illustrated cutout, muted dark warm graphite-gray, few broad simple connector plates, restrained bronze fasteners. Very narrow silhouette, approximately 1:8 width to height, minimal projecting parts. No giant column, arch, diagonal brace, huge pipe elbow, bright lamp or floor. Transparent exterior, complete uncropped source asset with clean top and bottom; final cropping will happen in the game camera. It must remain a subtle framing accent, occupying only about 2–3 percent of the final scene width.
```

### A27 前景管线 · C（两款分别生成）

```text
One isolated slender [bent coolant pipe / gently curving cable] as a near-camera edge decoration. Dark desaturated warm gray, a couple understated collars, simple confident silhouette and very restrained shading. Flat illustrated cutout, no giant elbow assembly, coils filling the image, bright highlights, lamps, background or supporting wall. Complete source silhouette on transparency; in-game it will be mostly cropped at the extreme screen edge.
```

### A28 操作舱衬景 · S

```text
A quiet shallow illustrated interior backing visible BEHIND the approved orbital recovery hatch when its doors open. Match the attached doorway opening proportions, straight-on view. Desaturated warm dark-gray service-panel wall, one subtle simple vertical panel seam and a low receiving alcove. Very low contrast, limited depth suggestion, no additional doorframe, control console, capsule, readable text, distant tunnel or dramatic light. Opaque image extending beyond the opening for safe masking. It must remain subordinate to the main room.
```

### A29 状态标识 · C（四态分别生成）

```text
One small clean monochrome control-screen icon representing [standby: a simple unfilled status circle / docking available: two approaching connector halves / energy transfer: a simple energy arrow entering a port / capsule ready: a sealed capsule with a small check mark]. Warm ivory linework, consistent restrained stroke weight, no lettering, numbers, surrounding screen, gradient or glow. Transparent background. Use simple readable geometry appropriate for a small sci-fi console. Match the approved icon's line weight across states.
```

## 6. 分层与交付规则

### 窗户

墙板不要包含画死的宇宙。窗框的洞为真实透明，后方通过独立背景层显示同一张宇宙图。窗洞区域的墙体需拆成周围面片或使用遮罩，不能让不透明墙板堵住透明窗口。星空的窗口对齐、旋转中心和遮罩由工程处理。

### 三面墙壳

A05/A06 放在内墙竖直面；A07 放在水平墙顶面；A08 封住靠近玩家的墙端。它们共用尺寸与颜色接口。地面 A01 水平铺设，A03/A04 收口，A09 连接墙脚。墙角细缝优先靠精确定位和连接条遮住，不画成每张图都有一圈黑边。

### 回收接口

后方到前方：A28 衬景 → A17 回收舱及 A15 托座 → A14 门叶 → A13 门框 → A16 控制台。实际接收动画时，回收舱位置可调整。A29 是状态显示，暂不把数值或玩法文案写死进图片。

### 发光与阴影

基础色 PNG 不烘焙周围暖光。A18 灯罩以及控制台指示灯可另外制作黑白发光遮罩：白色为灯源，黑色为其他区域；遮罩必须与原图逐像素对应。该遮罩由已确认图片提取/绘制，不重新生成一张近似版本。猫、设备与墙脚的主要投影交给引擎；素材允许少量固有遮挡明暗，但不能把地面阴影画进透明精灵。

### 文件与元数据

建议命名：`PO_A01_floor_base_v01.png`、`PO_A14_door_left_v01.png`、`PO_A18_lamp_emission_v01.png`。每项附记录：像素尺寸、有效边界、世界尺寸、锚点、面朝方向、是否平铺、平铺方向、透明方式、是否受光、是否投影、关联分层。生成母图与整理后的游戏 PNG 分目录保留。

## 7. 推荐制作批次及验收

1. **风格与比例样板**：A01、A05、A07、A08、A11、A18，加现有猫做镜头测试。先确认透视、线宽、角色尺寸、暖光，之后锁定材质风格。
2. **建筑外壳**：A02–A04、A06、A09–A10、A12。检查 3×3 地板重复，连续 3 块墙板、墙角与墙顶接缝；不同窗口宽高下不拉伸纹样。
3. **轨道回收入口**：A13–A17、A28；闭门、开门、回收舱抵达三个状态检查遮挡。A29 可随后加。
4. **生活设施**：A19–A24；核对猫的体型、地面接地点、设备占地和通道宽度。
5. **前景与装饰**：A25–A27；仅补视觉层次，不能遮住猫或有效操作区域。

验收不能只看单张大图：必须放入最终镜头尺寸检查。重点包括无黑/白抠图边、地板接缝不过重、墙顶与墙面颜色衔接、所有灯关闭后基础色仍正常、所有精灵接地点稳定、前景不抢眼、宇宙不抢主体，以及生成模型没有擅自加上文字、额外零件或不同视角。
