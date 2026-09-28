extends RefCounted
## Completed-action fixture for payout/art tests. Real input timing is tested separately.
static func settle(model,id: int) -> bool:
 var c: Dictionary=model.cat(id)
 if c.is_empty():return false
 var action: Dictionary=model.harvest_ticket(c)
 action.progress=model.harvest_time(action.layers)
 return model.harvest(id,action)
static func rub(model,id: int) -> void:
 var c: Dictionary=model.cat(id)
 var revision: int=model.c_revision(c)
 for i in range(120):
  model.pet(id,20);model.tick(0.05)
  if model.c_revision(c)!=revision:return

static func wait_ready(model,c: Dictionary) -> void:
 while model.reacting(c):model.tick(minf(0.05,c.reaction_left))
