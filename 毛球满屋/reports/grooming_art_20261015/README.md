# 2026-10-15 grooming art assembly verification

引擎：Godot 4.7.1.stable.official.a13da4feb，真实GL Compatibility图形渲染。

## 本次通过的检查

- 10张image_gen源图可读取，其中9张要求透明的图有真实Alpha透明像素，非画出来的黑底／棋盘底。
- 已生成图集区域索引和37份AtlasTexture；其中32格图集单元，5份整图资源。
- 额外精确背景及16张组装输出均为1920×1080，包括背景和三种预览的五类状态。
- render_stdout.txt最终记录GROOMING_ART_CAPTURE failures=0 images=16，最终render_stderr.txt无渲染错误。
- 已查看三花猫局部、机器猫局部和修甲画面，确认主体、工具、覆盖物和粉红／白色指甲组件可读。

背景使用生成台面，在独立SubViewport中输出；AI源图保持原始尺寸和像素。首次尝试直接读取项目窗口时得到1440×810，尺寸断言失败；随后改为显式1920×1080 SubViewport，重新运行，最终16张均符合尺寸。旧失败结果没有当作通过证据。

## 复现

```powershell
python 毛球满屋/tools/prepare_grooming_resources.py
```

随后以真实图形渲染器运行res://tests/render_grooming_assets.gd，参数--path指向毛球满屋。需先导入新PNG；引擎可执行文件位于本地.tools/godot-4.7.1，不入Git。运行辅助进程时使用隐藏窗口，不读取正式／旧测试存档。

## 已知限制

这里验证的是**美术资源与静态组装**。未验证顾客订单、鼠标拖动擦除、修甲切线、评价、奖励去重、真人手感或长期经济。预览中的半清比例和指甲线只是构图参数，不能冒充真实完成度和判定。

状态图有AI产生的细微几何差异，锚点目前自动来自Alpha边界，仍待人工校准；不能宣称各帧逐像素对齐。预览污物采用安全内侧摆放，正式实现仍需要身体／非服务区遮罩与裁切，不能依赖预览位置保证所有对象不越界。素材没有声音和真实动画。

正式project.godot默认场景未修改，旧prototype_harvest场景与脚本未修改。当前输出仅新增独立美术预览资源。
