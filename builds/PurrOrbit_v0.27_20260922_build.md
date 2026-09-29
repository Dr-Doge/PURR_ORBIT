# Purr Orbit Windows构建 · 2026-09-22

- 当前工作区构建，包含未提交改动；基础HEAD `498082819401883f5611303eb093a1339f46c27d`，不是干净提交的发布包。
- 引擎4.7.1.stable.official.a13da4feb；Windows Desktop release，x86_64，内嵌PCK，文件版本0.27.0.9。
- 当前实现包含16:9画布、idle停留及无开关数字1—9开发工具；仅打包现有实现，不实施新的待办策划。
- 导出退出码0，无ERROR/WARNING；独立EXE实际OpenGL启动120帧后退出码0，stderr为空。启动检查停留在开始菜单，不修改玩家存档。
- ZIP完整性检查通过，解压数据的EXE SHA256与原件一致；tests/reports/builds已排除导出。
- EXE SHA256：`b0f6b48610db6a5f31872f6db15b510d0884b715e8d3abfe5ad206b7ef426b68`
- ZIP SHA256：`8aa9dc94a840fdffa2ea6cbd7b7be9bb507c3a37d1ea645c5de4e4df181cd661`
- EXE字节数：139921096；ZIP字节数：68518510。
- 日志：同目录下PurrOrbit_v0.27_20260922_export.log及graphics_stdout/graphics_stderr.log。
