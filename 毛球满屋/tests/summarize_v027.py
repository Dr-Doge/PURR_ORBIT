"""Summarize deterministic strategy audits; never writes saves or changes balance."""
import hashlib
import json
import statistics
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / "reports/pacing_v027"
data = json.loads((FOLDER / "scenarios.json").read_text(encoding="utf-8"))
labels = {"full": "完整经营", "cats": "只买猫", "workers": "优先工人", "arcade": "增加娱乐设施", "layers": "攒8层", "single": "只收1层", "none": "不购买"}
summary = {}
for mode, label in labels.items():
    runs = [r for r in data["results"] if r["mode"] == mode]
    summary[mode] = {
        "label": label,
        "completed": sum(r["completed"] for r in runs),
        "min_minutes": round(min(r["seconds"] for r in runs) / 60, 2),
        "median_minutes": round(statistics.median(r["seconds"] for r in runs) / 60, 2),
        "max_minutes": round(max(r["seconds"] for r in runs) / 60, 2),
        "median_marks_minutes": {
            key: round(statistics.median(r["marks"][key] for r in runs if key in r["marks"]) / 60, 2)
            for key in sorted(set().union(*(r["marks"] for r in runs)))
        },
    }
assert summary["full"]["completed"] == 3
assert 50 <= summary["full"]["min_minutes"] <= summary["full"]["max_minutes"] <= 70
assert summary["full"]["max_minutes"] < summary["cats"]["min_minutes"]
assert summary["layers"]["max_minutes"] < summary["single"]["min_minutes"]
hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT / "scripts").glob("*.gd")}
(FOLDER / "summary.json").write_text(json.dumps({"engine": data["engine"], "strategy_summary": summary, "source_sha256": hashes, "limitation": "Simulated strategies, not human playtime. Failed-to-finish routes are right-censored at 120 minutes."}, ensure_ascii=False, indent=2), encoding="utf-8")
lines = ["# v0.27-N2 节奏验证", "", "Godot 4.7.1；7种策略×3种子＝21组。模型以0.1秒步进，每3秒至多手动收一只猫，每10秒一次采购／研究决策与出售；正常调用模型，无免费资产、不读写正式存档。工人按实际路程与工时运行。", "", "**不是真人时长。**不包含阅读、鼠标走位、犹豫和菜单演出。120分钟未完成按截尾报告，不当作通关。", "", "| 策略 | 完成组数 | 最快—最慢（分钟） | 中位（分钟） |", "| --- | ---: | --- | ---: |"]
for row in summary.values():
    lines.append(f"| {row['label']} | {row['completed']}/3 | {row['min_minutes']}—{row['max_minutes']} | {row['median_minutes']} |")
lines += ["", "## 完整经营的关键时点（中位分钟）", "", "| 事件 | 时点 |", "| --- | ---: |"]
for key, value in summary["full"]["median_marks_minutes"].items():
    lines.append(f"| {key} | {value} |")
lines += ["", "## 调参依据与边界", "", "- 以17号文档为依据：三角叠层收益、同类系列加成相加、主要产出贡献只记一次，固定累计阈值取代毛层个数。", "- calibration.json 是初轮离线参考轨迹，用于生成固定阈值的起点；后续只修改设施费用并复测，当前最终运行值以 balance.json 为准。游戏运行时不读取参考时刻，也不按实时收入调整费用或门槛。", "- 主流经营符合50—70分钟试算观察区间；首阶段补货约19—24分钟，部分早于25分钟提案，第二段约38—42分钟；不通过计时锁强行对齐。日光浴约8—11分钟，部分早于10—18分钟提案。", "- 攒层路线更快；纯买猫和只收第一层更慢。全部价格与工人数仍可自主选择，不设房间猫数硬上限。", "- 基础娱乐期望产值0.55×90/5＝9.9毛球/秒；适合让普通猫入场，不能承诺胜过高层、满粮、满buff巨型猫。出售才结算现金，中奖入库已计贡献。", "- 首批后固定代币结余完整带入，不强制消费，不清币；极端囤币可随后连抽，是保留玩家收益的已知结果。", "- 模拟自动及时补粮／清虫，不代表真实管理成本；UI提供100份手动采购以减少重复点击，不增加自动采购。", "", "125项模型检查及真实视口输入检查见 tests/test_demo.gd、tests/render_demo.gd；截图在 ../v027/。"]
(FOLDER / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
print("21 scenarios summarized; all pacing assertions passed.")
