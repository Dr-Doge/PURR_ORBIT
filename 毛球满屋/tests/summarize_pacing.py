"""Read-only analysis of archived dc data and the live-model audit.
Writes only reports/pacing_2h. Budget schedules are design assumptions, not simulations.
"""
from pathlib import Path
import json, statistics, hashlib, math

PROJECT=Path(__file__).resolve().parents[1]
WORKSPACE=PROJECT.parent
OUT=PROJECT/'reports'/'pacing_2h'
ARCHIVE=WORKSPACE/'策划归档'/'2026-09-18_旧方案与文档集归档'/'摸猫增量策划案'/'参考研究'/'DirtClicker'
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
audit=read(OUT/'current_audit.json')
summary=[]
for name in dict.fromkeys(r['plan']['name'] for r in audit['results']):
    rows=[r for r in audit['results'] if r['plan']['name']==name]
    totals=[sum(x['seconds'] for x in row['runs'])/60 for row in rows]
    summary.append({'plan':name,'round_medians_seconds':[statistics.median(row['runs'][i]['seconds'] for row in rows) for i in range(3)],'total_median_minutes':round(statistics.median(totals),2),'total_min_minutes':round(min(totals),2),'total_max_minutes':round(max(totals),2)})
topology=read(ARCHIVE/'节点研究'/'逐节点拓扑.json')
accessible=[n for n in topology['nodes'] if n['status']=='无Demo锁阻挡']
reference={'scope':'Static supplied demo, not all releases or measured play time','source_sha256':hashlib.sha256((ARCHIVE/'sheets.source.json').read_bytes()).hexdigest(),'tree_nodes':len(topology['nodes']),'not_demo_blocked_nodes':len(accessible),'level_purchases_theoretical':sum(n['levels']-n['level_start'] for n in accessible),'price_examples':[]}
for node in accessible:
    if node['key'] in ['SPOON.DIRT_GAIN.0','SPOON.ANIMATION_SCALE.0','MUSHROOM_GUY.IDLE_TIME.0','MUSHROOM_GUY.DIRT_MULTIPLY.0']:
        reference['price_examples'].append({k:node[k] for k in ['id','key','cost_base','cost_growth','levels','value_init','value_inc']})
# Hypothetical gross production rate profiles, in value/second. NOT measured game rates.
profiles=[[(0,3,2),(3,8,4),(8,15,10),(15,23,24),(23,30,40)],[(0,5,8),(5,12,25),(12,22,60),(22,32,120),(32,40,200)],[(0,6,20),(6,14,70),(14,25,180),(25,38,380),(38,50,700)]]
moments=[[1,4,7,10,13,16,19,22,26,30],[1]+[round(4+i*(36/13),3) for i in range(14)],[1]+[round(4+i*(46/18),3) for i in range(19)]]
def contribution(t,profile):
    return round(sum(max(0,min(t,end)-start)*60*rate for start,end,rate in profile))
budgets=[]
for i,(profile,times) in enumerate(zip(profiles,moments),1):
    thresholds=[contribution(t,profile) for t in times]
    budgets.append({'round':i,'target_minutes':profile[-1][1],'new_series':i+1,'items_per_series':5,'gross_rate_profile':profile,'draw_moments_minutes':times,'cumulative_contribution_thresholds':thresholds,'incremental_thresholds':[value-(thresholds[j-1] if j else 0) for j,value in enumerate(thresholds)],'warning':'Reverse budget from target income/time; not validated, not applied to gameplay'})
    assert len(times)==(i+1)*5
    assert all(a<b for a,b in zip(thresholds,thresholds[1:]))
result={'simulation_summary':summary,'dc_static':reference,'design_budgets':budgets,'target_total_minutes':120,'current_gameplay_modified':False}
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'analysis_summary.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'audit':summary,'design_contribution_budgets':[b['cumulative_contribution_thresholds'][-1] for b in budgets]},ensure_ascii=False,indent=2))
