extends Node

# ============================================================
# 天赋总表（单一数据源）
#   策划案 30 个（T01-T30）+ 项目原有独有 9 个 = 39 个
#   level: 1 普通(绿) / 2 稀有(蓝) / 3 史诗(紫) / 4 传说(橙)
#   id 按稀有度分段：1-7 普通 / 11-25 稀有 / 31-42 史诗 / 51-55 传说
# ============================================================

# 策划案稀有度概率：普通 40% / 稀有 30% / 史诗 20% / 传说 10%
const RARITY_CHANCE := [0.0, 40.0, 30.0, 20.0, 10.0]

# 策划案互斥表：[早熟 vs 大器晚成] [书香门第 vs 寒门贵子]
#               [社交达人 vs 天煞孤星] [天命之子 vs 时间循环]
const MUTEX_GROUPS := [[18, 31], [35, 39], [21, 36], [51, 53]]

const TALENTS := [
	# ==================== 普通（60%） ====================
	{"id": 1,  "level": 1, "name": "铁骨",     "desc": "出生时体质+1"},
	{"id": 2,  "level": 1, "name": "清秀",     "desc": "出生时颜值+1"},
	{"id": 3,  "level": 1, "name": "聪慧",     "desc": "出生时智力+1"},
	{"id": 4,  "level": 1, "name": "小康",     "desc": "出生时家境+1"},
	{"id": 5,  "level": 1, "name": "小幸运",   "desc": "出生时运气+1"},
	{"id": 6,  "level": 1, "name": "开朗",     "desc": "出生时快乐+1"},
	{"id": 7,  "level": 1, "name": "玻璃心",   "desc": "快乐增加的事件效果额外+1"},

	# ==================== 稀有（30%） ====================
	{"id": 11, "level": 2, "name": "强健体魄", "desc": "出生时体质+2，最低3"},
	{"id": 12, "level": 2, "name": "天生丽质", "desc": "出生时颜值+2，最低3"},
	{"id": 13, "level": 2, "name": "智慧之光", "desc": "出生时智力+2，最低3"},
	{"id": 14, "level": 2, "name": "家财万贯", "desc": "出生时家境+2，最低3"},
	{"id": 15, "level": 2, "name": "锦鲤附体", "desc": "出生时运气+2，最低3"},
	{"id": 16, "level": 2, "name": "乐天派",   "desc": "出生时快乐+2，最低3"},
	{"id": 17, "level": 2, "name": "运动细胞", "desc": "开局自带运动习惯｜代价：智力-1"},
	{"id": 18, "level": 2, "name": "早熟",     "desc": "18岁前正面事件效果+1｜代价：19岁后正面事件效果-1"},
	{"id": 19, "level": 2, "name": "独生子女", "desc": "父母健康+3"},
	{"id": 20, "level": 2, "name": "贵人相助", "desc": "被欺负后反而会变强"},
	{"id": 21, "level": 2, "name": "社交达人", "desc": "恋爱/婚姻事件权重+30%｜代价：学业事件权重-20%"},
	{"id": 22, "level": 2, "name": "学霸",     "desc": "学术事件权重+50%"},
	{"id": 23, "level": 2, "name": "佛系",     "desc": "压力衰减+1/年｜代价：所有正面事件效果-1"},
	{"id": 24, "level": 2, "name": "铁人",     "desc": "压力相关死亡事件权重减半"},
	{"id": 25, "level": 2, "name": "劳碌命",   "desc": "工作事件家境额外+1"},

	# ==================== 史诗（8%） ====================
	{"id": 31, "level": 3, "name": "大器晚成", "desc": "40岁后正面事件效果+1｜代价：40岁前正面事件效果-1"},
	{"id": 32, "level": 3, "name": "过目不忘", "desc": "智力增加的事件额外+1｜代价：快乐减少的事件额外-1"},
	{"id": 33, "level": 3, "name": "抗压之王", "desc": "压力上限+3，每年衰减+1"},
	{"id": 34, "level": 3, "name": "白手起家", "desc": "创业收益翻倍，创业链权重+50%｜代价：家境-2"},
	{"id": 35, "level": 3, "name": "书香门第", "desc": "开局学历=小学，学业事件权重+50%｜代价：家境-1"},
	{"id": 36, "level": 3, "name": "天煞孤星", "desc": "死亡事件权重减半｜代价：运气-2，无法恋爱/结婚"},
	{"id": 37, "level": 3, "name": "青梅竹马", "desc": "开局自带恋人（交往中）｜代价：13-18岁无法触发其他恋爱事件"},
	{"id": 38, "level": 3, "name": "世家子弟", "desc": "开局已就业、收入等级2｜代价：快乐-2"},
	{"id": 39, "level": 3, "name": "寒门贵子", "desc": "开局学历=高中，学业事件权重+30%｜代价：家境-2，父母健康-2"},
	{"id": 40, "level": 3, "name": "孤儿",     "desc": "父母不在，运气+3"},
	{"id": 41, "level": 3, "name": "创业狂",   "desc": "创业链权重+50%"},
	{"id": 42, "level": 3, "name": "工作狂",   "desc": "工作事件家境+1"},

	# ==================== 传说（2%） ====================
	{"id": 51, "level": 4, "name": "天命之子", "desc": "死亡事件权重减半，正面事件权重翻倍"},
	{"id": 52, "level": 4, "name": "逆天改命", "desc": "每10年可重新分配3点属性｜代价：所有事件权重-20%"},
	{"id": 53, "level": 4, "name": "时间循环", "desc": "死亡时回到10年前，属性保留｜代价：所有事件权重-30%，压力继承"},
	{"id": 54, "level": 4, "name": "龙脉传承", "desc": "所有属性下限为5｜代价：无法通过事件获得运气"},
	{"id": 55, "level": 4, "name": "神秘玉佩", "desc": "神秘"},
]

var _by_id: Dictionary = {}

func _ready() -> void:
	for t in TALENTS:
		_by_id[int(t.id)] = t

func _ensure() -> void:
	if _by_id.is_empty():
		for t in TALENTS:
			_by_id[int(t.id)] = t

func get_def(id: int) -> Dictionary:
	_ensure()
	return _by_id.get(id, {})

func name_of(id: int) -> String:
	return str(get_def(id).get("name", "未知天赋"))

func desc_of(id: int) -> String:
	return str(get_def(id).get("desc", ""))

func level_of(id: int) -> int:
	return int(get_def(id).get("level", 1))

func rarity_color(level: int) -> Color:
	match level:
		1: return Color(0.12, 1.0, 0.0)      # 绿
		2: return Color(0.0, 0.44, 0.87)     # 蓝
		3: return Color(0.64, 0.21, 0.93)    # 紫
		4: return Color(1.0, 0.5, 0.0)       # 橙
	return Color(1, 1, 1)

func _roll_level() -> int:
	var r := randf() * 100.0
	var acc := 0.0
	for level in range(1, 5):
		acc += RARITY_CHANCE[level]
		if r < acc:
			return level
	return 1

func conflicts(id: int, picked: Array) -> bool:
	for group in MUTEX_GROUPS:
		if not group.has(id):
			continue
		for other in group:
			if other != id and picked.has(other):
				return true
	return false

# 按策划案稀有度概率抽 count 张不重复、不互斥的候选卡
func draw_candidates(count: int = 6) -> Array[int]:
	var picked: Array[int] = []
	# 结算画面锁定的天赋，下局必定出现在候选里
	var p := get_node_or_null("/root/Progress")
	if p != null:
		var lock_id := int(p.locked_talent)
		if lock_id > 0 and not get_def(lock_id).is_empty():
			picked.append(lock_id)
	var guard := 0
	while picked.size() < count and guard < 1000:
		guard += 1
		var level := _roll_level()
		var pool: Array[int] = []
		for t in TALENTS:
			var id := int(t.id)
			if int(t.level) != level:
				continue
			if picked.has(id) or conflicts(id, picked):
				continue
			pool.append(id)
		if pool.is_empty():
			continue
		picked.append(pool[randi() % pool.size()])

	# 兜底：稀有度池被互斥规则抽空时，从剩余任意天赋补齐
	if picked.size() < count:
		for t in TALENTS:
			var id := int(t.id)
			if picked.has(id) or conflicts(id, picked):
				continue
			picked.append(id)
			if picked.size() >= count:
				break
	return picked

# 模拟玩家「六选三」：从 6 张候选里随机选 3 张
func draw_auto(count: int = 3) -> Array[int]:
	var cands := draw_candidates(6)
	cands.shuffle()
	var out: Array[int] = []
	for i in range(mini(count, cands.size())):
		out.append(cands[i])
	return out
