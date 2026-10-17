# 普通猫梳毛场景：移植与美术替换接口

**完整交接入口（2026-10-17）：**[团队阅读版](../../../开发汇报/2026-10-17_普通猫梳毛移植交接/01_交接日志_团队阅读版.md)说明当前玩法与移植目标；[Agent移植版](../../../开发汇报/2026-10-17_普通猫梳毛移植交接/02_交接日志_Agent移植版.md)按最新009源码列齐依赖、固定节点、坐标与宿主接口、换美术限制、步骤和验收。**移植接手优先读Agent版**，下面是已同步关键差异的接口摘要，不表示目标场景已创建。

**009素材修复补充：**身躯／轮廓resources/*.tres现在引用isolated_patches独立同尺寸纹理。atlas_index.json的region为原图集来源记录，不能绕过资源重新矩形裁原图，否则会恢复邻图碎角；assets.image已按资源读取。轮廓和身躯共用颜色／Alpha处理，不恢复黑描边绕过染色。当前手工场景包含锁定的身躯几何，Model一同读取以保留布局；空outline_layout仍允许程序铺排。源PNG和用户节点变换保持，参数29.21、证据fur_asset_cleanup_20261017。

当前入口`res://scenes/prototype_grooming/fur_demo.tscn`，Godot4.7.1；只迁移本独立原型，不改正式3D场景或机器猫。最新任务IMP-20261017-009；交互29.13、逐片落毛29.14／29.15、连续升降29.16、到顶衔接及落毛图替换29.17、三区身躯29.18、手工轮廓29.20、裁剪及统一处理29.21。最新证据reports/fur_asset_cleanup_20261017，旧报告作历史。

对应落毛通过source_id关联原片，**不要求texture相同**：现在使用fall_variants里的松散毛簇／碎毛，按来源框等比放大，保持对应数量、中心与Alpha=.38。新图集需要同时校准小颗粒和大落毛，不能因更换松散图又恢复复制密实描边毛片。平台到最高点不再反弹，猫惯性与上升同一连续时间轴。

## 可以直接复用的边界

| 模块 | 负责内容 | 接入主游戏时 |
|---|---|---|
| model.gd | 服务对象／毛块状态、两遍与回弹、连续服务状态机 | 不依赖HUD节点；由宿主订阅信号及提供下一顾客 |
| brush_config.gd | 交互、落毛与升降试玩参数 | 保持集中配置，后续正式数值另校准 |
| service_view.gd＋coat_cleaning.gdshader | 工具、真实毛块形变与落片；显示不改服务数据 | 保留model注入、logical坐标与显示变换分离 |
| ServiceView/PlatformRoot/Table | 持久平台节点，载着SubjectRoot、阴影和落毛移动 | 用同一平台坐标层移动，不能只移动底图或桌子 |
| presentation_profile.gd | 可替换房间／台面／猫底图、逻辑放置矩形、服务区UV | 复制默认Resource为新配置，在场景根presentation字段指定 |
| controller.gd | 本Demo输入／暂停／HUD和原型计数 | 主游戏可替换控制层，不应照搬原型结算到正式经济 |

房间和HUD不属于PlatformRoot。按住鼠标只在cleaning有效；切换阶段／顾客／暂停／失焦清空当前手势，上一只猫的残留按压不能作用于下一只。暂停同时冻结模型升降、惯性、毛块回弹和落毛。

## 顾客流程与宿主接口

`arrival → cleaning → reward → departure → arrival`。完成会保留短暂反馈，再载着猫下降至屏外；到屏外才重建下一只猫与毛块。完成次数／原型钱包保留，当前顾客的毛块、手势及落毛不跨顾客污染。

- `configure_presentation(profile)`：启动阶段校验并应用配置、重新准备顾客。非法配置返回false且不丢失现有顾客；不要在正在服务时调用来换猫。
- `queue_customer(profile, scale)`：只安排下一只；profile可为null表示不改变已排队的美术，scale为0表示保持或1／0.5选大小。美术、身体mask、毛色和GPU缓存只在旧猫完全降出后更新，不在屏上换皮。
- `automatic_cycle=true`：Demo默认，完成后无需按钮或退出界面自动继续。
- `automatic_cycle=false`：宿主可以在reward等待自己的结算／排队结果，然后调用`release_customer()`启动下降；此方法只接收一次有效离场。不是第二套结算。
- `customer_prepared(serial)`／`customer_ready(serial)`／`customer_completed(serial, amount)`／`customer_departed(serial)`：准备、可操作、完成、完全离屏。以serial校验回调归属；主游戏选择单一结算所有权，避免信号和自身逻辑重复付钱。amount是原型基类的试玩值，不是正式收益承诺。

当前猫是可重复的展示顾客，不增加存档或正式猫咪身份；移植时由主游戏提供顾客ID、外观与结算规则，本Demo不自动读写正式存档。

## 美术替换步骤

1. 复制`Art/grooming_environment_v1/grooming_presentation.tres`为新Resource，替换room_texture／table_texture／cat_texture及cat_name。
2. 背景可不透明；台面与猫必须保持正确透明边缘。表面、腿和底座若拆成多件，放到PlatformRoot同一父节点下；当前单张透明台面已有金属支撑。
3. 在1920×1080逻辑坐标中设置table_rect、cat_fit_rect。猫按源宽高比缩放、脚底放到fit区域底边，不因纹理分辨率变更而强行拉伸。
4. 用新猫的UV重新标定service_chest／service_body／service_tail、paw_exclusions与outline_paths。三服务区为0—1内至少3点的多边形；脚爪排除区独立，轮廓路线按胸／躯干／尾分段。身体服务区不自动推断“头”或“尾”；不正确区域可能让毛块落到脸上或脚上。
5. 更换身躯、轮廓和碎毛图集时，重新隔离单片主体，维护实际Texture资源及atlas_index.json／fall_variants.json语义key与来源记录，不能绕过009修复资源直接矩形截原图。当前身躯gray／cream／mixed三色组各4形，共12份，轮廓8份，碎毛12份；灰白落毛筛选与取色亮度阈值对新颜色还需适配。
6. 梳子替换必须同步tool_geometry.gd内的TOOTH_FIRST／TOOTH_LAST与抬起／激活方向。判定线和可见齿边必须共用元数据，任意不同梳子不能直接套旧585×398裁切坐标。
7. F6确认布局，再运行tests/run_grooming_fur.ps1。源PNG只读，运行时取色、透明mask和缓存从配置重建。

## 检查结果与尚需校准的部分

已有替换测试使用300×200不同宽高比的猫纹理与新的fit矩形，确认保持比例、清除旧CPU／GPU纹理缓存、重新生成服务对象；非法猫底图不清空当前顾客。平台、工具的坐标换算和两种16:9分辨率通过实际输入／渲染检查。

这不是任意图片一键适配。当前outline_layout指向手工场景，同时读取保存的身躯和轮廓几何，不自动重排；新体型需另做布局与脚爪标定。只有outline_layout为空时才使用profile的分区轮廓路线和程序铺排，不能混淆两条路径。FX仍有灰／乳白分类。Canvas、采样网格、梳齿和贴片尺寸仍是1920×1080约定，宿主换坐标尺度需统一换算。

model仍继承旧美容基类的通用字段、mask／结算辅助，使用旧config及素材加载器；本轮已跳过未使用修甲与旧灰尘／毛结／垃圾对象的准备，但不是完全独立的新框架。移植打包要带相应共享脚本与梳子图集；不要把机器猫或废弃小游戏逻辑重新加入纯梳毛。

场景EditorPreview为静态美术布局参考，运行时以presentation资源为准；换资源后编辑器预览引用也需同步，不能把旧预览当实际加载结果。正式主场景的3D输入、摄像机、顾客身份和存档接入尚未实施，不声称已完成移植。
# 2026-10-17手工轮廓补充（008）

当前普通猫profile的`outline_layout`指向轮廓毛发摆放.tscn；编辑节点不实例化到运行树，authored_outline静态读取其几何，Model建立对象和进度。轮廓层1、身躯层2、底图0，全部随PlatformRoot移动。008当时原身躯仍程序铺排，009已改同时读取锁定身躯参考；手工结果不自动吸附或缩小。

换猫美术时必须清空outline_layout后用程序回退，或为新猫制作匹配的手工布局，不能把当前灰白猫的UV和几何直接套到新猫。只有修改同一摆放场景时，保存并重启F6即可读取。NodePath／实际Texture为来源身份，复制后的source_id必须重编；可见性和父组区域决定是否使用，不采集素材区或标签。

当前手工原位有5片与脚爪禁区采样重叠，报告已列路径供美术复核，不擅自裁形或改位。当前验证reports/authored_outline_20261017，旧006程序切线和脚爪保护结论不能自动继承。无正式主游戏移植。
