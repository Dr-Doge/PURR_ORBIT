extends SceneTree
const M=preload("res://scripts/model.gd")
const V=preload("res://scripts/cat_visuals.gd")
var failures=0
var checks=0
func check(ok: bool,msg: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:
 var m=M.new();var c: Dictionary=m.cats[0];var v=V.new()
 m.reset_activity(c);c.idle_left=100
 m.tick(0.1)
 check(is_equal_approx(c.groom_wait,(9.0+float(c.id%7))*0.5-0.1),"First wait halved")
 c.groom_wait=0;m.tick(0.01);v.step(m,0)
 check(m.grooming(c) and v.states[c.id].clip=="groom","Model starts grooming")
 check(is_equal_approx(c.groom_wait,(12.0+float(c.id%9))*0.5),"Repeat wait halved")
 var at: Vector2=c.pos;var duration: float=c.groom_left;var growth: float=c.growth
 c.idle_left=0;c.walk_left=10;c.dest+=Vector2(150,0)
 m.cat_escape_targets[c.id]=c.dest
 m.tick(0.2);v.step(m,0.2)
 check(c.pos==at and m.grooming(c),"Walking cannot move grooming cat")
 check(c.growth>growth,"Growth continues")
 m.move_cat(c.id,at+Vector2(100,0));check(c.pos==at,"Dragging API cannot move grooming cat")
 var ticket=m.harvest_ticket(c);ticket.progress=10000
 check(not m.harvest(c.id,ticket),"Automatic harvest cannot interrupt")
 var w={"id":999,"role":"harvest","pos":at,"cooldown":0.0,"clock":0.0,"job":{}}
 check(m.choose_job(w,{"cat:"+str(m.cats[1].id):true}).is_empty(),"Worker skips grooming cat")
 w.job={"kind":"harvest","target":c.id,"cat":c.id,"revision":m.c_revision(c)}
 m.tick_worker(w,0.1,{})
 check(w.job.is_empty() and m.grooming(c),"Existing worker job yields")
 m.set_hovered_cat(c.id);m.tick(0.2);v.step(m,0.2)
 check(m.grooming(c) and v.states[c.id].clip=="groom","Hover does not interrupt")
 m.pet(c.id,0);check(m.grooming(c),"No motion is not petting")
 var left: float=c.groom_left;v.step(m,10)
 check(c.groom_left==left and v.states[c.id].clip=="groom","Render clock cannot finish grooming")
 m.pet(c.id,1);v.step(m,0)
 check(not m.grooming(c) and v.states[c.id].clip=="pet","Petting immediately interrupts")
 m.cancel_pet(c);m.set_hovered_cat(-1);m.reset_activity(c);c.idle_left=100;c.groom_wait=0
 m.tick(0.01);m.tick(duration-0.01);v.step(m,0)
 check(m.grooming(c) and c.pos==at,"Full clip remains stationary until completion")
 m.tick(0.02);v.step(m,0)
 check(not m.grooming(c) and v.states[c.id].clip.begins_with("idle"),"Clip completes normally")
 c.idle_left=0;c.walk_left=10;c.dest=at+Vector2(100,0);m.tick(0.1)
 check(c.pos!=at,"Walking resumes after completion")
 var other: Dictionary=m.cats[1];other.kind="giant";other.groom_wait=0;other.idle_left=100
 m.tick(0.1);check(not m.grooming(other),"Other cat types unchanged")
 print("GROOMING: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
