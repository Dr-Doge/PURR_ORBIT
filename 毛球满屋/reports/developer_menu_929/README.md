# IMP-20260929-001｜左侧开发者菜单

Godot4.7.1，2026-09-29。最左侧提示按钮点击展开抽屉，数字0—9及小键盘不执行开发指令。正式3D、保留2D、独立测试均实例化同一保存的DeveloperDrawer场景；只在经营时显示，展开暂停并锁房间交互。

菜单包含10,000毛球、100标准粮、四类设施和帮手、五猫种、首批收藏补齐、虫害和黑屏。独立测试另有说明／原测试台、档案、存读档与预置重置。生成特殊猫仅开发路径，正常商店只卖短毛；种类、反应种类、ID、动画与存档按真实模型，lab身份沿原生成链。缺异常目标只提示，首批补齐重复调用不重发。

| 验证 | 通过 |
| --- | --- |
| test_developer_menu_929：三场景真实鼠标、旧键无效、全猫种／设施／资源／补货、暂停、防穿透、滚动、Esc、弹窗交接与重置 | 104 |
| test_cat_shortcuts：新版按键行为与招财动画 | 10 |
| test_demo：原模型／存档 | 125 |
| test_lab_004：原独立循环 | 90 |
| test_3d_scene：正式主场景 | 54 |
| 合计 | 383 |

对应test_*.log为最终输出。formal_1440／lab_1440与formal_960／lab_960显示1440×810／960×540实际抽屉；*_top显示资源区，已检查布局。正式／测试截图来源为测试对象，没有以正式档进行开发指令测试。test.log是早期99项初验，当前结果以test_developer_menu_929.log和result.json的104项为准。

复现主专项：Godot --path 毛球满屋 --script res://tests/test_developer_menu_929.gd。test_developer_004入口重定向新专项。其余普通测试从tests执行；lab和3D回归仅在.tools/developer_menu_929复制脚本重定向输出，lab隔离存档仍位于reports/lab_004/developer_menu_929，未覆盖历史证据。猫输入测试更新过时的固定第7帧断言，校验当前招财动画实际末帧；生产脚本未因测试调整数值。

实现：scripts/developer_drawer.gd、developer_tools.gd、main.gd及scenes/ui/developer_drawer.tscn。正常经济、模型和美术未主动修改；本轮开始时已存在的三张改动图集与v16构建元数据保留。原生在线AI／正式旧档岗位迁移仍不属于本次菜单任务。未build、未提交／push。
