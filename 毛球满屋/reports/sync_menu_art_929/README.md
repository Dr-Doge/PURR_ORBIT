# 2026-09-29菜单与美术源码同步

本轮git fetch与git pull --ff-only origin main确认远端仍为18e1e0e9，Already up to date；Jomin为9月10日旧分支，experiment为独立实验，均未混入。没有虚构新的远端美术提交或强造merge commit。

发布本地尚未提交内容：左侧开发者菜单、五猫种生成、独立测试功能及文档；三张cat1new2侧面待机／产毛／被抚摸图集和对应alt备用资源完整保留。图集尺寸与既有Atlas切帧一致，SHA256与alt比对见art_integrity.json。正式3D背景和所有既有场景美术保持；模型、balance、data、lab_model与project.godot相对18e1e0e9无差异。

Godot4.7.1，真实图形与鼠标检查通过：菜单104、猫输入10、模型125、三花素材动画39、独立循环90、正式3D54，总计422项，全部0失败。test_*.log、summary.json与双尺寸截图保留结果，已查看正式菜单与猫咪显示。未重跑长期节奏、不改正式存档；测试使用testing=true和隔离测试档。

复现普通测试位于tests；菜单、lab、3D检查为.tools/sync_menu_art_929中的只改输出路径的副本。当前报告不覆盖旧证据；lab测试写reports/lab_004/sync_menu_art_929。原规则见17第26节，001完成记录见18。

本轮发布源码与美术，没有新build。export_presets中的0.27.0.16与对应说明来自先前构建；其EXE尚不含菜单改动，旧未跟踪builds继续保留本地。

2026-09-29发布确认：b2d47eba已push至origin/main，包含开发菜单与当前本地美术；422项验证，未新build。
