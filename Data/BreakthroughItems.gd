extends RefCounted

# ============================================================
# 三线 × 9 阶段晋级物品表 + 天劫强度计算
#
#   普通件 common：每缺 1 件 → 天劫 +1 重
#   核心件 core  ：每缺 1 件 → 天劫 +2 重
#   钥匙件 key   ：每缺 1 件 → 天劫 +3 重（缺钥匙件无法正常飞升）
#   前置   pre   ：前置事件未完成 → 视作缺 1 件核心件（+2 重）
#
#   天劫总重 = 基础劫级 + 缺普通×1 + 缺核心×2 + 缺钥匙×3
#              + 缺失过半(+1) + 全缺(+物品总数) - 高阶替代(最多3)
#   1~3 小天劫 / 4~6 中天劫 / 7~9 大天劫 / 10~12 超劫 / 13+ 绝劫
# ============================================================

# 索引 = 境界（0 练气→筑基 … 8 渡劫→飞升），与 main.gd 的 realm 一致
const STAGES := [
	# ==================== 仙修（path 0） ====================
	[
		{"base": 1, "pre": "玉佩共鸣",
		 "common": ["金灵砂", "木灵芽", "水灵露", "火灵晶", "土灵壤"],
		 "core": ["小册子"], "key": ["玉佩共鸣"]},
		{"base": 2, "pre": "道基稳固",
		 "common": ["地脉灵泉", "千年灵药"], "core": ["金丹辅料"], "key": []},
		{"base": 3, "pre": "心魔试炼",
		 "common": ["破婴丹", "雷劫洗礼"], "core": ["元婴秘法", "护魂法器"], "key": []},
		{"base": 4, "pre": "神识出窍",
		 "common": ["神识秘法", "化神机缘", "养神木"], "core": ["虚空石", "悟道茶"], "key": []},
		{"base": 5, "pre": "空间裂缝",
		 "common": ["空间感悟", "炼虚秘法", "星辰砂"], "core": ["虚空石", "界石", "破界符"], "key": []},
		{"base": 6, "pre": "法体合一",
		 "common": ["日精", "月华", "星辉", "阴阳二气"],
		 "core": ["五行本源", "合体秘法", "法体合一"], "key": []},
		{"base": 7, "pre": "大乘天劫",
		 "common": ["功德", "天劫", "渡劫台", "避劫法宝"],
		 "core": ["大乘秘法", "大乘天劫", "天地认可", "道心圆满"], "key": []},
		{"base": 8, "pre": "渡劫准备",
		 "common": ["渡劫台", "避劫法宝", "渡劫丹", "雷劫木", "定风珠"],
		 "core": ["护道阵法", "替死符", "避水珠", "避火珠"], "key": []},
		{"base": 9, "pre": "九重天劫",
		 "common": [], "core": [], "key": ["仙界接引符", "九重天劫令", "飞升台"]},
	],
	# ==================== 魔修（path 1） ====================
	[
		{"base": 1, "pre": "魔血共鸣",
		 "common": ["血煞", "怨煞", "阴煞", "尸煞", "魔煞"],
		 "core": ["魔基稳固"], "key": ["魔血共鸣"]},
		{"base": 2, "pre": "魔基稳固",
		 "common": ["贪毒", "嗔毒"], "core": ["痴毒"], "key": []},
		{"base": 3, "pre": "心魔试炼",
		 "common": ["心魔", "身魔"], "core": ["口魔", "意魔"], "key": []},
		{"base": 4, "pre": "魔蕴出窍",
		 "common": ["色蕴", "受蕴", "想蕴"], "core": ["行蕴", "识蕴"], "key": []},
		{"base": 5, "pre": "魔道裂缝",
		 "common": ["天道", "人道", "修罗道"], "core": ["畜生道", "饿鬼道", "地狱道"], "key": []},
		{"base": 6, "pre": "魔情合一",
		 "common": ["喜", "怒", "哀", "惧"], "core": ["爱", "恶", "欲"], "key": []},
		{"base": 7, "pre": "魔乘天劫",
		 "common": ["东荒", "南荒", "西荒", "北荒"],
		 "core": ["天荒", "地荒", "玄荒", "黄荒"], "key": []},
		{"base": 8, "pre": "魔劫准备",
		 "common": ["魔渡劫台", "避劫魔器", "魔劫丹", "雷劫魔木", "定风魔珠"],
		 "core": ["护道魔阵", "替死魔符", "避水魔珠", "避火魔珠"], "key": []},
		{"base": 9, "pre": "九重魔劫",
		 "common": [], "core": [], "key": ["魔界接引符", "九重魔劫令", "魔升台"]},
	],
	# ==================== 魂修（path 2） ====================
	[
		{"base": 1, "pre": "魂灯共鸣",
		 "common": ["喜魄", "怒魄", "哀魄", "惧魄", "爱魄"],
		 "core": ["凝魂稳固"], "key": ["魂灯共鸣"]},
		{"base": 2, "pre": "凝魂稳固",
		 "common": ["胎光", "爽灵"], "core": ["幽精"], "key": []},
		{"base": 3, "pre": "魂心试炼",
		 "common": ["青龙魂", "白虎魂"], "core": ["朱雀魂", "玄武魂"], "key": []},
		{"base": 4, "pre": "魂神出窍",
		 "common": ["天眼通", "天耳通", "他心通"], "core": ["宿命通", "神足通"], "key": []},
		{"base": 5, "pre": "魂道裂缝",
		 "common": ["天道", "人道", "修罗道"], "core": ["畜生道", "饿鬼道", "地狱道"], "key": []},
		{"base": 6, "pre": "魂情合一",
		 "common": ["喜", "怒", "哀", "惧"], "core": ["爱", "恶", "欲"], "key": []},
		{"base": 7, "pre": "大乘魂劫",
		 "common": ["功德", "魂劫", "魂劫台", "避劫魂器"],
		 "core": ["大乘魂法", "大乘魂劫", "天地认可", "魂心圆满"], "key": []},
		{"base": 8, "pre": "魂劫准备",
		 "common": ["魂劫台", "避劫魂器", "魂劫丹", "雷劫魂木", "定风魂珠"],
		 "core": ["护道魂阵", "替死魂符", "避水魂珠", "避火魂珠"], "key": []},
		{"base": 9, "pre": "九重魂劫",
		 "common": [], "core": [], "key": ["幽冥接引符", "九重魂劫令", "魂升台"]},
	],
]

const TYPE_NAMES := [
	["雷劫", "五行劫", "风火劫", "心魔劫"],
	["魔劫", "业火劫", "心魔劫", "血煞劫"],
	["魂劫", "幽冥劫", "轮回劫", "魂飞魄散劫"],
]

static func stage(path: int, realm: int) -> Dictionary:
	return STAGES[clampi(path, 0, 2)][clampi(realm, 0, 8)]

static func stage_name(path: int, realm: int) -> String:
	return str(stage(path, realm).get("pre", ""))

# 某阶段需要的全部物品（用于展示/统计）
static func all_items(path: int, realm: int) -> Array:
	var st: Dictionary = stage(path, realm)
	return st.common + st.core + st.key

static func level_name(weight: int) -> String:
	if weight <= 3:
		return "小天劫"
	if weight <= 6:
		return "中天劫"
	if weight <= 9:
		return "大天劫"
	if weight <= 12:
		return "超劫"
	return "绝劫"

static func type_name(path: int, weight: int) -> String:
	var pool: Array = TYPE_NAMES[clampi(path, 0, 2)]
	if weight <= 3:
		return str(pool[0])
	if weight <= 6:
		return str(pool[1])
	if weight <= 9:
		return str(pool[2])
	return str(pool[3])

# 核心计算：给定已拥有的物品（Dictionary 或 Array，用 has 判断）与前置是否完成，算出天劫总重等信息
static func tribulation(owned: Dictionary, path: int, realm: int, pre_done: bool) -> Dictionary:
	var st: Dictionary = stage(path, realm)
	var base := int(st.base)
	var miss_common := 0
	var miss_core := 0
	var miss_key := 0
	var total := 0
	for it in st.common:
		total += 1
		if not owned.has(it):
			miss_common += 1
	for it in st.core:
		total += 1
		if not owned.has(it):
			miss_core += 1
	for it in st.key:
		total += 1
		if not owned.has(it):
			miss_key += 1
	# 前置未完成视作缺 1 件核心件；但若前置本身就是本阶段的一件物品
	#（例如练气→筑基的「玉佩共鸣」同时是钥匙件），就不重复计数
	if not pre_done:
		var pre_is_item: bool = (st.common + st.core + st.key).has(str(st.get("pre", "")))
		if not pre_is_item:
			miss_core += 1
			total += 1

	# 高阶替代：持有下一阶段的物品，每件抵消 1 重，最多抵消 3 重
	var alt := 0
	if realm < 8:
		var nxt: Dictionary = stage(path, realm + 1)
		for it in nxt.common + nxt.core:
			if owned.has(it):
				alt += 1
	alt = mini(alt, 3)

	var missing_total: int = miss_common + miss_core + miss_key
	var extra := 0
	var all_missing := total > 0 and missing_total >= total
	if total > 0 and missing_total * 2 >= total:
		extra += 1                      # 缺失过半：天劫变异 +1 重
	if all_missing:
		extra += total                  # 全缺：绝劫
	var weight: int = maxi(1, base + miss_common * 1 + miss_core * 2 + miss_key * 3 + extra - alt)

	return {
		"base": base,
		"weight": weight,
		"miss_common": miss_common,
		"miss_core": miss_core,
		"miss_key": miss_key,
		"missing_total": missing_total,
		"total": total,
		"alt": alt,
		"extra": extra,
		"complete": missing_total == 0,
		"all_missing": all_missing,
		"over": weight > 9,
		"absolute": weight >= 13,
		"level": level_name(weight),
		"type_name": type_name(path, weight),
		"pre": str(st.get("pre", "")),
		"pre_done": pre_done,
	}
