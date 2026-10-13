# 游戏调研

这里保存给《Purr Orbit／毛球计划》策划Agent使用的游戏研究。每次包含两部分：**参考游戏自身的玩法拆解**，以及**结合本项目当前开发情况的借鉴判断与融入建议**。

| 游戏 | 参考游戏分析 | 项目借鉴与融入判断 | Agent输入 | 项目快照 |
|---|---|---|---|---|
| ForgeTax／铸剑纳贡（锻剑／断剑模拟器） | [完整拆解](ForgeTax/ForgeTax_玩法拆解.md) | [融入建议与优先级](ForgeTax/项目适配与融入建议.md) | [agent_input.json](ForgeTax/agent_input.json) | [2026-10-13快照](2026-10-13_项目开发快照.md) |
| 深空当铺／Probably Stolen | [玩法拆解](ProbablyStolen/深空当铺_玩法拆解.md) | [融入建议与优先级](ProbablyStolen/项目适配与融入建议.md) | [agent_input.json](ProbablyStolen/agent_input.json) | main `b156a051`，2026-10-13重新核对，见报告与证据记录 |
| 2026-08-13—10-13新增量游戏名单（多游戏初筛） | [热度、日期与循环清单](2026-10-13_近期增量游戏清单/近两个月新增量游戏_调研清单.md) | [项目适配与优先研究](2026-10-13_近期增量游戏清单/项目适配与优先研究建议.md) | [agent_input.json](2026-10-13_近期增量游戏清单/agent_input.json) | main `2cfde7cf`，未实玩，见报告 |
| 猫主题增量／放置游戏筛选 | [近期、旧作与待发售清单](2026-10-13_猫主题增量游戏清单/猫主题游戏_筛选清单.md) | [项目适配与研究建议](2026-10-13_猫主题增量游戏清单/项目适配与研究建议.md) | [agent_input.json](2026-10-13_猫主题增量游戏清单/agent_input.json) | main `e0bf4769`，2026-10-13核对，未实玩 |

## 工作流与技能

- [gameplay-research技能](skill/gameplay-research/SKILL.md)：可复制到个人或团队技能目录，使用`$gameplay-research`调用。
- [详细调研Prompt与JSON 1.1模板](skill/gameplay-research/references/research-prompt.md)：统一原生分析、项目状态核对、借鉴判断、建议及验证。
- 本仓库的`游戏调研/skill/gameplay-research`是版本管理的技能源；个人安装副本从这里同步。
- 每次报告校验完成后自动提交报告、证据与本索引并push；执行[发布脚本](skill/gameplay-research/scripts/publish_report.py)，明确指定本次路径。成功交付Git链接与提交号；遇到冲突或推送失败保留成果，在HTalk来源群发起ask。

新增游戏沿用独立子目录，并更新本索引。至少交付原生拆解、项目融入判断和JSON；有价值的建议写引入位置、前后区别、可复用能力、新增工作、代价与验证。没有好的融入方向也记录判断，不能为了凑建议强行推荐。

项目状态按当次读取的Git提交和证据归档，下一次研究要重新核对。正式Demo、独立原型、已确认待实现和讨论方案分开；调研建议是候选，不自动成为正式规则或实装待办。

2026-10-13归档：首轮ForgeTax研究从工作区复制，保留原报告与证据，补充对`9679a7bc`项目状态的适配复核。今后以本目录为研究交接入口。
