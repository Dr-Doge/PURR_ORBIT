"""Summarize current paired September23 scenarios; historical reports remain frozen."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
FOLDER=ROOT/"reports/september23"
data=json.loads((FOLDER/"pacing.json").read_text(encoding="utf-8"))
summary=[]
for mode in ["full","layers","single","arcade"]:
    old=[r for r in data["results"] if r["legacy"] and r["mode"]==mode]
    new=[r for r in data["results"] if not r["legacy"] and r["mode"]==mode]
    assert len(old)==len(new)==3
    assert all(r["completed"] for r in old+new)
    speeds=[a["marks"]["complete"]/b["marks"]["complete"] for a,b in zip(old,new)]
    summary.append({"mode":mode,"old_minutes":[round(r["marks"]["complete"]/60,2) for r in old],"new_minutes":[round(r["marks"]["complete"]/60,2) for r in new],"speed_ratios":speeds,"restock_minutes":[round(r["marks"]["restock"]/60,2) for r in new],"altar_minutes":[round(r["marks"].get("altar",0)/60,2) for r in new]})
hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/"scripts").glob("*.gd")}
(FOLDER/"summary.json").write_text(json.dumps({"results":summary,"source_sha256":hashes,"limitation":"24 policy simulations; not human play. Nodes/affordability recorded at 50,60,70 minutes. Actual completion uses marks.complete, not observation-end seconds."},ensure_ascii=False,indent=2),encoding="utf-8")
print(json.dumps(summary,ensure_ascii=False,indent=2))
