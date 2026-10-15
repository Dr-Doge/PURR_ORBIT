# 双猫美容可玩Demo实施与验证

2026-10-15｜任务IMP-20261014-001｜Godot **4.7.1.stable.official.a13da4feb**。

打开[main.tscn](../../scenes/prototype_grooming/main.tscn)后按F6。操作与代码入口见[场景说明](../../scenes/prototype_grooming/README.md)。本报告对应真正可玩的服务循环，之前的素材预览报告保持历史用途。

## 本次交付

三花猫梳理→机器猫擦拭→三花猫梳理＋修甲，随后循环。按住拖动处理普通污物、慢梳毛结／积灰、往复清除粘附物；松手保留局部进度。修甲横向划过两侧，浅剪改变剩余长度并可补剪、完美完成、深剪扣评后完成该根。订单全部完成才按评价一次入账，收益图标与数字直接出现，无领取窗口。

顶部提供示范订单、修甲练习、重试、暂停和静音，Esc也能暂停；正常三单无需使用菜单即可完成。两猫共享一个表面判定模型。碎屑、甲片只是表现，不要求拾取、不提前发最终报酬。纯内存钱包，退出不保留。

## 验证结果

| 检查 | 结果 | 证据 |
|---|---|---|
| 新模型 | **34项通过、0失败** | [model_results.json](model_results.json) |
| 图形GUI输入与截图 | **40项通过、0失败** | [ui_results.json](ui_results.json)、[引擎输出](ui_stdout.txt)；错误日志为空 |
| 原正式模型回归 | **125项通过、0失败** | [formal_model_stdout.txt](formal_model_stdout.txt) |
| 独立场景直接图形启动 | 退出码0，无脚本／Shader错误 | [scene_startup.json](scene_startup.json)、[输出](scene_stdout.txt) |
| 双尺寸 | 1440×810及1920×1080，14张引擎截图 | 下表与ui_results文件清单 |
| 隔离 | 正式入口、旧测试和两模型均无工作树改动 | [受保护文件SHA256](protected_files_sha256.json)；原型没有存档读写代码 |

GUI通过SubViewport向Control发送InputEventMouseButton／InputEventMouseMotion，实际经过_gui_input与控制器，未直接调用清空模型或切预览状态来伪装完成。首笔慢扫用真实时钟，批量扫线设置可重复的事件时间戳，不是人工鼠标试玩或录屏。画面由Windows OpenGL Compatibility／RTX5060渲染，未使用空渲染器。

模型检查涵盖：静止不推进、局部遮罩／松手保留、慢对象速度条件、过速不清理与限频、背景不扣评、小抖动不能清粘附物、浅剪真实变短与补剪、剪已移除尖端无效、稀疏斜线不绕过角度限制、完美／深剪、全部要求完成才入账、重复调用不重复结算、三单自动循环与暂停。同一条路1段与6段采样处理量一致；这不等于完整人工低／高帧率对照。

GUI走完三单，验证满分梳理100、满分擦拭120、一次深剪的组合单128，合计348测试金钱。另验证修甲参考线可见、UI断触、失焦／丢失释放后取消未提交手势、Esc、暂停继续、重试、静音及两尺寸命中。自动检查不能证明玩家愿意反复服务。

## 画面证据

| 展示 | 截图 |
|---|---|
| 三花猫待梳理 | [1440×810](calico_dirty_1440x810.png) |
| 局部清理与保留 | [1440×810](calico_partial_1440x810.png) |
| 过速即时降评 | [1440×810](calico_pain_1440x810.png) |
| 完成自动发钱 | [1440×810](calico_paid_1440x810.png) |
| 机器猫油污／完成 | [待处理](robot_dirty_1440x810.png)、[已结算](robot_paid_1440x810.png) |
| 修甲前／浅剪／深剪／完成 | [开始](nails_before_1440x810.png)、[浅剪](nail_shallow_1440x810.png)、[深剪](nail_deep_1440x810.png)、[完成](nails_paid_1440x810.png) |
| 大分辨率修甲 | [修甲前](nails_before_1920x1080.png)、[剪完一根](nail_one_done_1920x1080.png) |
| 大分辨率机器擦拭 | [待处理](robot_dirty_1920x1080.png)、[局部](robot_partial_1920x1080.png) |

## 复现与参数

工作空间根目录执行：

```powershell
& '毛球满屋/tests/run_grooming_demo.ps1'
```

只跑模型可加`-SkipGraphics`。脚本采用本地`.tools/godot-4.7.1`，图形验证后台启动并写出日志，最长3分钟超时退出。原模型单独执行：

```powershell
& '.tools/godot-4.7.1/Godot_v4.7.1-stable_win64_console.exe' --headless --path '毛球满屋' --script res://tests/test_demo.gd
```

当前试玩值：[config.json](config.json)，对应scripts/prototype_grooming/config.gd与策划17第29节。修甲粉红上缘由当前长甲素材扫描获得，约距根117.304逻辑像素。源码运行不改变原始PNG；资源经导入纹理读取，污物只改运行时遮罩。

## 待验证与限制

- D01—D07已完成；D08自动化部分已完成，**真人连续服务、实际操作录屏和手感评价仍待验收**。
- 清理时使用稳定中性底图，不适为短震动／浅红，满意图结算切换；没有连续的最终表情动画。生成状态图有轮廓微差。
- 身体有效范围采用Alpha＋横向保守裁切，尚非精细部位分区；工具热点、刷宽与服务区仍需真人调试。当前污物布局预设，不代表最终关卡。
- 程序合成短音提供临时刷、剪、错误与收益反馈，可静音；图形测试使用Dummy音频，未验收扬声器听感或最终猫叫。
- 未做长期性能、完整经营经济、工具成长或玩家趣味性结论；未引入正式升级树、工人、旧毛层、锻造／收藏。
- 本轮交付编辑器F6场景，没有新EXE。未来单独打包时须将Art/grooming_demo_v1/atlas_index.json纳入该构建的非资源包含规则；本次未改正式export_presets.cfg。

正式project.godot、3D主场景、旧测试场景与旧模型保持；不读写／迁移玩家存档。本报告发布状态由Git提交记录核对。
