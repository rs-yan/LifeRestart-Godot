extends Node

# ============================================================
# 全局进度（跨局持久化）：成就 / 事件图鉴 / 锁定天赋
#   存档位置：user://dsh_progress.cfg
#   由 Main/main.gd 在开局写入事件目录、在死亡结算时调用 finish_run() 结算
# ============================================================

const SAVE_PATH := "user://dsh_progress.cfg"

# 成就等级：1 青铜 / 2 白银 / 3 黄金 / 4 钻石
const TIER_NAMES := ["", "青铜", "白银", "黄金", "钻石"]
const TIER_COLORS := [
	Color(1, 1, 1),
	Color(0.72, 0.45, 0.20),
	Color(0.75, 0.75, 0.80),
	Color(1.00, 0.84, 0.25),
	Color(0.45, 0.85, 1.00),
]

# 成就表（id / 名称 / 说明 / 等级）
const ACHIEVEMENTS := [
	# ---------- 青铜 ----------
	{"id": "first_run",  "name": "初次重开", "desc": "完成第一局人生", "tier": 1},
	{"id": "age60",      "name": "花甲之年", "desc": "活到 60 岁", "tier": 1},
	{"id": "age100",     "name": "百岁人瑞", "desc": "活到 100 岁", "tier": 1},
	{"id": "strong8",    "name": "天生神力", "desc": "体质达到 8", "tier": 1},
	{"id": "beauty8",    "name": "容颜如玉", "desc": "颜值达到 8", "tier": 1},
	{"id": "clever8",    "name": "学富五车", "desc": "智商达到 8", "tier": 1},
	{"id": "money8",     "name": "家财万贯", "desc": "家境达到 8", "tier": 1},
	{"id": "luck8",      "name": "时来运转", "desc": "运气达到 8", "tier": 1},
	{"id": "emotion8",   "name": "心宽体胖", "desc": "心情达到 8", "tier": 1},
	{"id": "early_death","name": "英年早逝", "desc": "10 岁前就离世", "tier": 1},
	# ---------- 白银 ----------
	{"id": "married",    "name": "执子之手", "desc": "结婚", "tier": 2},
	{"id": "widow30",    "name": "白头偕老", "desc": "婚龄满 30 年后丧偶", "tier": 2},
	{"id": "single80",   "name": "钻石单身", "desc": "终身未婚并活到 80 岁", "tier": 2},
	{"id": "children2",  "name": "儿女双全", "desc": "养育 2 个以上子女", "tier": 2},
	{"id": "grandchild", "name": "含饴弄孙", "desc": "拥有孙辈", "tier": 2},
	{"id": "stress8",    "name": "铁人",     "desc": "压力达到 8 以上还活着", "tier": 2},
	{"id": "scholar",    "name": "状元之才", "desc": "智商达到 10", "tier": 2},
	{"id": "rich",       "name": "富甲一方", "desc": "家境达到 10", "tier": 2},
	{"id": "legendary",  "name": "天赋异禀", "desc": "抽到传说级天赋", "tier": 2},
	{"id": "balanced",   "name": "六边形人生", "desc": "六维全部达到 6 以上", "tier": 2},
	{"id": "poor_family","name": "寒门",     "desc": "家境 ≤ 2 却活过 60 岁", "tier": 2},
	# ---------- 黄金 ----------
	{"id": "cultivation","name": "踏入仙途", "desc": "从凡人进入修仙线", "tier": 3},
	{"id": "realm1",     "name": "筑基有成", "desc": "达到筑基期", "tier": 3},
	{"id": "realm2",     "name": "金丹大道", "desc": "达到金丹期", "tier": 3},
	{"id": "realm3",     "name": "元婴出窍", "desc": "达到元婴期", "tier": 3},
	{"id": "realm4",     "name": "化神之境", "desc": "达到化神期", "tier": 3},
	{"id": "ascend",     "name": "飞升仙界", "desc": "渡劫成功飞升", "tier": 3},
	{"id": "mo_path",    "name": "堕入魔道", "desc": "转修魔修支线", "tier": 3},
	{"id": "hun_path",   "name": "转修魂道", "desc": "转修魂修支线", "tier": 3},
	{"id": "mo_zu",      "name": "一代魔祖", "desc": "达成魔祖结局", "tier": 3},
	{"id": "lunhui",     "name": "轮回之主", "desc": "达成轮回之主结局", "tier": 3},
	{"id": "rich_cult",  "name": "富甲修真界", "desc": "达成富甲修真界结局", "tier": 3},
	{"id": "bankrupt",   "name": "破产坐化", "desc": "达成破产坐化结局", "tier": 3},
	{"id": "xiuxian100", "name": "长生久视", "desc": "修仙后寿数超过 1000 岁", "tier": 3},
	# ---------- 钻石 ----------
	{"id": "realm6",     "name": "合体大成", "desc": "达到合体期", "tier": 4},
	{"id": "realm8",     "name": "渡劫在即", "desc": "达到渡劫期", "tier": 4},
	{"id": "double_legend", "name": "天命所归", "desc": "单局抽到 2 个传说级天赋", "tier": 4},
	{"id": "time_loop",  "name": "时间循环", "desc": "触发天赋「时间循环」", "tier": 4},
	{"id": "event100",   "name": "见多识广", "desc": "累计经历 100 个事件", "tier": 4},
	{"id": "event250",   "name": "阅历丰富", "desc": "累计经历 250 个事件", "tier": 4},
	{"id": "runs20",     "name": "重开二十次", "desc": "累计完成 20 局人生", "tier": 4},
	# ---------- 青铜（补充） ----------
	{"id": "toddler",    "name": "蹒跚学步", "desc": "活到 3 岁", "tier": 1},
	{"id": "student",    "name": "上学堂", "desc": "活到 12 岁", "tier": 1},
	{"id": "crush",      "name": "情窦初开", "desc": "有过一段交往", "tier": 1},
	{"id": "worker",     "name": "打工人", "desc": "进入职场", "tier": 1},
	{"id": "weak40",     "name": "病秧子", "desc": "体质 ≤2 却活过 40 岁", "tier": 1},
	{"id": "bookworm",   "name": "书呆子", "desc": "智商达到 6", "tier": 1},
	{"id": "pretty6",    "name": "万人瞩目", "desc": "颜值达到 6", "tier": 1},
	{"id": "poor40",     "name": "贫贱不移", "desc": "家境 ≤2 活到 40 岁", "tier": 1},
	# ---------- 白银（补充） ----------
	{"id": "children3",  "name": "人丁兴旺", "desc": "养育 3 个以上子女", "tier": 2},
	{"id": "grand2",     "name": "四世同堂", "desc": "拥有 2 个以上孙辈", "tier": 2},
	{"id": "age90",      "name": "鲐背之年", "desc": "活到 90 岁", "tier": 2},
	{"id": "age110",     "name": "期颐之寿", "desc": "活到 110 岁", "tier": 2},
	{"id": "money12",    "name": "富可敌国", "desc": "家境达到 12", "tier": 2},
	{"id": "clever12",   "name": "绝世天才", "desc": "智商达到 12", "tier": 2},
	{"id": "strong12",   "name": "铜皮铁骨", "desc": "体质达到 12", "tier": 2},
	{"id": "beauty12",   "name": "倾国倾城", "desc": "颜值达到 12", "tier": 2},
	{"id": "boss",       "name": "自己当老板", "desc": "自主创业", "tier": 2},
	{"id": "after_div",  "name": "一别两宽", "desc": "离婚后仍活到 60 岁", "tier": 2},
	# ---------- 黄金（补充） ----------
	{"id": "item_dongfu", "name": "洞府之主", "desc": "开辟一座洞府", "tier": 3},
	{"id": "item_lingmai", "name": "灵脉在手", "desc": "买下一条灵脉", "tier": 3},
	{"id": "item_fabao", "name": "法宝在身", "desc": "炼成一件法宝", "tier": 3},
	{"id": "item_fu",    "name": "留一手", "desc": "获得一张保命符箓", "tier": 3},
	{"id": "heart5",     "name": "心魔缠身", "desc": "心魔达到 5 层", "tier": 3},
	{"id": "heart_clean", "name": "道心稳固", "desc": "境界 ≥4 且心魔为 0", "tier": 3},
	{"id": "karma80",    "name": "业力深重", "desc": "业力达到 80", "tier": 3},
	{"id": "soulfire5",  "name": "魂火不灭", "desc": "魂火达到 5", "tier": 3},
	{"id": "res100",     "name": "富甲修真界·小成", "desc": "修仙资源达到 100", "tier": 3},
	{"id": "realm5",     "name": "炼虚之境", "desc": "达到炼虚期", "tier": 3},
	# ---------- 钻石（补充） ----------
	{"id": "realm7",     "name": "大乘圆满", "desc": "达到大乘期", "tier": 4},
	{"id": "ascend_mo",  "name": "飞升魔界", "desc": "魔修飞升", "tier": 4},
	{"id": "ascend_hun", "name": "飞升幽冥", "desc": "魂修飞升", "tier": 4},
	{"id": "juedie",     "name": "绝劫余生", "desc": "在绝劫中活下来", "tier": 4},
	{"id": "dujie_zhe",  "name": "渡劫者", "desc": "超劫硬抗成功", "tier": 4},
	{"id": "runs100",    "name": "百世轮回", "desc": "累计完成 100 局人生", "tier": 4},
	{"id": "coverage50", "name": "博闻强识", "desc": "事件图鉴收集过半", "tier": 4},
	# ---------- 隐藏成就（未解锁时显示为 ？？？） ----------
	{"id": "h_hanmen",   "name": "寒门贵子", "desc": "家境 ≤2 起家却成为巨富", "tier": 3, "hidden": true},
	{"id": "h_guy",      "name": "孤儿成才", "desc": "以孤儿之身活到 80 岁且家境 ≥10", "tier": 3, "hidden": true},
	{"id": "h_bingjie",  "name": "兵解转世", "desc": "以兵解转世收场", "tier": 4, "hidden": true},
	{"id": "h_xinmo",    "name": "心魔爆体", "desc": "死于心魔爆体", "tier": 3, "hidden": true},
	{"id": "h_hunfei",   "name": "魂飞魄散", "desc": "魂火燃尽而亡", "tier": 3, "hidden": true},
	{"id": "h_poor_end", "name": "穷困潦倒", "desc": "死时资源为 0", "tier": 2, "hidden": true},
	{"id": "h_single100", "name": "百年孤独", "desc": "终身未婚并活到 100 岁", "tier": 3, "hidden": true},
	{"id": "h_three",    "name": "三界飞升", "desc": "仙、魔、魂三条线都飞升过", "tier": 4, "hidden": true},
]

# ---------- 持久化数据 ----------
var unlocked: Dictionary = {}        # 成就 id -> true
var seen_events: Dictionary = {}     # 事件 id -> true（天然去重）
var event_catalog: Dictionary = {}   # 事件 id -> 文本
var event_total: int = 0
var locked_talent: int = 0           # 锁定的天赋 id（0 = 未锁定）
var total_runs: int = 0
var best_age: int = 0
var ascended: Dictionary = {}        # 飞升过的路线（隐藏成就「三界飞升」）

func _ready() -> void:
	load_data()

# ==================== 存档 ====================
func save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("data", "unlocked", unlocked)
	cf.set_value("data", "seen_events", seen_events)
	cf.set_value("data", "event_catalog", event_catalog)
	cf.set_value("data", "event_total", event_total)
	cf.set_value("data", "locked_talent", locked_talent)
	cf.set_value("data", "total_runs", total_runs)
	cf.set_value("data", "best_age", best_age)
	cf.set_value("data", "ascended", ascended)
	cf.save(SAVE_PATH)

func load_data() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	unlocked = cf.get_value("data", "unlocked", {})
	seen_events = cf.get_value("data", "seen_events", {})
	event_catalog = cf.get_value("data", "event_catalog", {})
	event_total = int(cf.get_value("data", "event_total", 0))
	locked_talent = int(cf.get_value("data", "locked_talent", 0))
	total_runs = int(cf.get_value("data", "total_runs", 0))
	best_age = int(cf.get_value("data", "best_age", 0))
	ascended = cf.get_value("data", "ascended", {})

func clear_all() -> void:
	unlocked.clear()
	seen_events.clear()
	event_catalog.clear()
	event_total = 0
	locked_talent = 0
	total_runs = 0
	best_age = 0
	save()

# ==================== 事件目录 / 图鉴 ====================
func set_catalog(catalog: Dictionary, total: int) -> void:
	event_catalog = catalog
	event_total = total

func event_coverage() -> float:
	if event_total <= 0:
		return 0.0
	return 100.0 * float(seen_events.size()) / float(event_total)

# 只返回「经历过」的事件（按 id 排序，天然去重）
func seen_event_list() -> Array:
	var ids: Array = seen_events.keys()
	ids.sort()
	var out: Array = []
	for id in ids:
		out.append({"id": int(id), "text": str(event_catalog.get(id, "（文本未记录）"))})
	return out

# ==================== 成就 ====================
func is_unlocked(id: String) -> bool:
	return bool(unlocked.get(id, false))

func tier_name(t: int) -> String:
	return TIER_NAMES[clampi(t, 0, 4)]

func tier_color(t: int) -> Color:
	return TIER_COLORS[clampi(t, 0, 4)]

func unlocked_count() -> int:
	return unlocked.size()

func achievement_name(id: String) -> String:
	for a in ACHIEVEMENTS:
		if str(a.id) == id:
			return str(a.name)
	return id

# ==================== 单局结算 ====================
# state 需要包含：age, values, talents, history, marital, children, grandchildren,
#               stress, cultivating, path, realm, ending, flags
# 返回本局新解锁的成就列表（[{id, name, desc, tier}]）
func finish_run(state: Dictionary) -> Array:
	total_runs += 1
	# 合并本局经历过的事件（去重）
	for id in state.get("history", []):
		seen_events[int(id)] = true
	best_age = maxi(best_age, int(state.get("age", 0)))

	# 记录飞升路线（隐藏成就「三界飞升」）
	var end_now := str(state.get("ending", ""))
	if end_now == "飞升" or end_now == "飞升魔界" or end_now == "飞升幽冥":
		ascended[end_now] = true

	var newly: Array = []
	for a in ACHIEVEMENTS:
		var id := str(a.id)
		if unlocked.get(id, false):
			continue
		if _check(id, state):
			unlocked[id] = true
			newly.append(a)
	save()
	return newly

func _check(id: String, s: Dictionary) -> bool:
	var age := int(s.get("age", 0))
	var v: Array = s.get("values", [0, 0, 0, 0, 0, 0])
	var talents: Array = s.get("talents", [])
	var stress := int(s.get("stress", 0))
	var children := int(s.get("children", 0))
	var grandchildren := int(s.get("grandchildren", 0))
	var marital := int(s.get("marital", 0))          # 0单 1交往 2已婚 3离婚 4丧偶 5暗恋 6订婚
	var cultivating := bool(s.get("cultivating", false))
	var realm := int(s.get("realm", 0))
	var path := int(s.get("path", 0))
	var ending := str(s.get("ending", ""))
	var flags: Dictionary = s.get("flags", {})
	var legend := 0
	for t in talents:
		if TalentPool.level_of(int(t)) == 4:
			legend += 1

	match id:
		"first_run":    return total_runs >= 1
		"age60":        return age >= 60
		"age100":       return age >= 100
		"strong8":      return int(v[0]) >= 8
		"beauty8":      return int(v[1]) >= 8
		"clever8":      return int(v[2]) >= 8
		"money8":       return int(v[3]) >= 8
		"luck8":        return int(v[4]) >= 8
		"emotion8":     return int(v[5]) >= 8
		"early_death":  return age < 10
		"married":      return marital == 2 or marital == 3 or marital == 4 or flags.get("widowed", false)
		"widow30":      return flags.get("widow_after_30", false)
		"single80":     return age >= 80 and not flags.get("ever_married", false)
		"children2":    return children >= 2
		"grandchild":   return grandchildren >= 1
		"stress8":      return stress >= 8
		"scholar":      return int(v[2]) >= 10
		"rich":         return int(v[3]) >= 10
		"legendary":    return legend >= 1
		"balanced":     return int(v[0]) >= 6 and int(v[1]) >= 6 and int(v[2]) >= 6 \
			and int(v[3]) >= 6 and int(v[4]) >= 6 and int(v[5]) >= 6
		"poor_family":  return int(v[3]) <= 2 and age >= 60
		"cultivation":  return cultivating
		"realm1":       return realm >= 1
		"realm2":       return realm >= 2
		"realm3":       return realm >= 3
		"realm4":       return realm >= 4
		"realm6":       return realm >= 6
		"realm8":       return realm >= 8
		"ascend":       return ending == "飞升"
		"mo_path":      return cultivating and path == 1
		"hun_path":     return cultivating and path == 2
		"mo_zu":        return ending == "魔祖"
		"lunhui":       return ending == "轮回之主"
		"rich_cult":    return ending == "富甲修真界"
		"bankrupt":     return ending == "破产坐化"
		"xiuxian100":   return cultivating and age >= 1000
		"double_legend":return legend >= 2
		"time_loop":    return flags.get("time_loop_used", false)
		"event100":     return seen_events.size() >= 100
		"event250":     return seen_events.size() >= 250
		"runs20":       return total_runs >= 20

		# ---------- 补充成就 ----------
		"toddler":      return age >= 3
		"student":      return age >= 12
		"crush":        return marital == 1 or marital == 6 or flags.get("ever_dated", false) \
			or flags.get("ever_married", false)
		"worker":       return int(s.get("job", 0)) >= 2
		"weak40":       return int(v[0]) <= 2 and age >= 40
		"bookworm":     return int(v[2]) >= 6
		"pretty6":      return int(v[1]) >= 6
		"poor40":       return int(v[3]) <= 2 and age >= 40
		"children3":    return children >= 3
		"grand2":       return grandchildren >= 2
		"age90":        return age >= 90
		"age110":       return age >= 110
		"money12":      return int(v[3]) >= 12
		"clever12":     return int(v[2]) >= 12
		"strong12":     return int(v[0]) >= 12
		"beauty12":     return int(v[1]) >= 12
		"boss":         return int(s.get("job", 0)) == 3
		"after_div":    return marital == 3 and age >= 60
		"item_dongfu":  return s.get("items", []).has("洞府")
		"item_lingmai": return s.get("items", []).has("灵脉")
		"item_fabao":   return bool(flags.get("法宝", false)) \
			or s.get("items", []).has("法宝")
		"item_fu":      return s.get("items", []).has("符箓")
		"heart5":       return int(s.get("heart_demon", 0)) >= 5
		"heart_clean":  return realm >= 4 and int(s.get("heart_demon", 0)) == 0
		"karma80":      return cultivating and path == 1 and int(s.get("dao", 0)) >= 80
		"soulfire5":    return cultivating and path == 2 and int(s.get("extra", 0)) >= 5
		"res100":       return cultivating and int(s.get("res", 0)) >= 100
		"realm5":       return realm >= 5
		"realm7":       return realm >= 7
		"ascend_mo":    return ending == "飞升魔界"
		"ascend_hun":   return ending == "飞升幽冥"
		"juedie":       return bool(flags.get("juedie_survived", false))
		"dujie_zhe":    return bool(flags.get("渡劫者", false))
		"runs100":      return total_runs >= 100
		"coverage50":   return event_total > 0 and seen_events.size() * 2 >= event_total
		# ---------- 隐藏成就 ----------
		"h_hanmen":     return int(v[3]) <= 2 and int(s.get("res", 0)) >= 50
		"h_guy":        return talents.has(40) and age >= 80 and int(v[3]) >= 10
		"h_bingjie":    return ending == "兵解转世"
		"h_xinmo":      return ending == "心魔爆体"
		"h_hunfei":     return ending == "魂飞魄散"
		"h_poor_end":   return cultivating and int(s.get("res", 0)) <= 0
		"h_single100":  return age >= 100 and not flags.get("ever_married", false)
		"h_three":      return ascended.size() >= 3
	return false
