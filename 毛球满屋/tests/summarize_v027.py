"""Summarize current harvest strategies without touching frozen historical reports."""
import hashlib
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / "reports/pacing_hover_008"
data = json.loads((FOLDER / "scenarios.json").read_text(encoding="utf-8"))
summary = []
for mode in ["full", "cats", "workers", "arcade", "layers", "single", "none"]:
    runs = [r for r in data["results"] if r["mode"] == mode]
    assert len(runs) == 3, f"Missing runs for {mode}"
    summary.append({"mode": mode, "completed": sum(r["completed"] for r in runs),
                    "min_minutes": round(min(r["seconds"] for r in runs) / 60, 2),
                    "max_minutes": round(max(r["seconds"] for r in runs) / 60, 2)})
full = summary[0]
target_met = full["completed"] == 3 and full["min_minutes"] >= 50 and full["max_minutes"] <= 70
hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT / "scripts").glob("*.gd")}
(FOLDER / "summary.json").write_text(json.dumps({"results": summary, "target_50_to_70_met": target_met,
    "source_sha256": hashes, "limitation": "Simulation, not human play time. Incomplete runs censored at 120 minutes."}, indent=2), encoding="utf-8")
print(f"21 scenarios summarized. Full route: {full['min_minutes']} to {full['max_minutes']} minutes; target met: {target_met}")
