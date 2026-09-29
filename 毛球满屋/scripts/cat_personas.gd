extends RefCounted
## Offline, authored AI cache. No network calls or effect on gameplay RNG.
const PATH="res://data/cat_personas.json"
const CATEGORIES=["origin","past","trait","habit","contrast","naming"]
static func library() -> Dictionary:
 if not FileAccess.file_exists(PATH):return {}
 var parsed=JSON.parse_string(FileAccess.get_file_as_string(PATH))
 return parsed if parsed is Dictionary else {}
static func matches(word: Dictionary,tags: Dictionary) -> bool:
 for key in word.get("requires",{}):
  if word.requires[key]!=tags.get(key,""):return false
 return true
static func valid_tags(book: Dictionary,tags: Dictionary,kind: String) -> bool:
 if tags.size()!=CATEGORIES.size():return false
 for category in CATEGORIES:
  var found: bool=false
  for word in book.get("words",{}).get(category,[]):
   if word.id==tags.get(category,"") and kind in word.kinds and matches(word,tags):found=true;break
  if not found:return false
 for pair in book.get("conflicts",[]):
  if tags.values().has(pair[0]) and tags.values().has(pair[1]):return false
 return true
static func valid_text(entry: Dictionary) -> bool:
 if not entry.get("name",null) is String or not entry.get("bio",null) is String:return false
 return entry.name.length()>=2 and entry.name.length()<=5 and entry.bio.length()>=40 and entry.bio.length()<=80
static func generate(id: int,kind: String,seed_value: int,used: Array=[],book: Dictionary={}) -> Dictionary:
 if book.is_empty():book=library()
 var random=RandomNumberGenerator.new();random.seed=seed_value
 var candidates: Array=[]
 for entry in book.get("profiles",[]):
  if entry is Dictionary and entry.get("tags",null) is Dictionary and valid_text(entry) and valid_tags(book,entry.tags,kind):candidates.append(entry)
 var fresh: Array=candidates.filter(func(e):return not used.has(e.name))
 if not fresh.is_empty():candidates=fresh
 var tags: Dictionary={}
 # Conditional category draws keep the sampled prompt compatible with cached prose.
 for category in CATEGORIES:
  var options: Array=[]
  for entry in candidates:
   if not options.has(entry.tags[category]):options.append(entry.tags[category])
  if options.is_empty():break
  tags[category]=options[random.randi_range(0,options.size()-1)]
  candidates=candidates.filter(func(e):return e.tags[category]==tags[category])
 var result: Dictionary
 if candidates.is_empty():
  # Still sample real category IDs if the service/cache is unavailable.
  tags.clear()
  for category in CATEGORIES:
   var options: Array=book.get("words",{}).get(category,[]).filter(func(w):return kind in w.kinds and matches(w,tags))
   if not options.is_empty():tags[category]=options[random.randi_range(0,options.size()-1)].id
  if not valid_tags(book,tags,kind):tags.clear()
  result={"name":"访客"+str(id),"bio":"它的个人档案暂时没有送达。现在能确定的是，它已经找到一个舒服的位置，准备等登记员睡醒再补办手续。","source":"模板回退（非在线AI生成）","cache_key":""}
 else:
  var entry: Dictionary=candidates[0]
  result={"name":entry.name,"bio":entry.bio,"source":book.get("source","AI预生成缓存（离线）"),"cache_key":entry.key}
  if used.has(result.name):result.name=result.name.left(2)+str(id)
 result["version"]=book.get("version","unavailable");result["seed"]=seed_value;result["tags"]=tags;result["id"]=id
 return result
static func valid_saved(value,cat_id: int) -> bool:
 if not value is Dictionary:return false
 if not value.has_all(["id","name","bio","source","version","seed","tags","cache_key"]):return false
 if value.id!=cat_id or not value.seed is int or not value.tags is Dictionary:return false
 for key in ["name","bio","source","version","cache_key"]:
  if not value[key] is String:return false
 return value.name.length()>0 and value.name.length()<=24 and value.bio.length()>0 and value.bio.length()<=400
