# Windows构建

引擎与模板：4.7.1.stable.official.a13da4feb。模板从Godot官方4.7.1发布包提取，逐文件CRC核验，使用项目内自定义模板路径；未覆盖用户全局模板。

资源内嵌，排除tests/reports/builds。headless和OpenGL图形启动退出码均为0，无运行错误。启动仅停留开始页，不写玩家存档。初次带--path的检查退出1，去除不适用于交付启动的路径参数后双模式通过。

EXE SHA256：`bb5af2fc4f0dabce197e031b5c669afbe076434551a40b013e098a81804abad3`
