extends RefCounted

# ============================================================
# 修仙线事件表（按《修仙线完整体系表》）
#
#   注入：event_pool.append_array(CultivationEvents.build(self))
#   所有事件带 cult = true，只在进入修仙线后触发（main.gd 候选过滤）。
#
#   境界推进由引擎统一处理（main.gd 的 _cultivation_year / _try_breakthrough）：
#     · 每年静修自动补足离门槛最远的一项属性（_cultivate_year_gain）
#     · 同时满足「年龄下限 + 灵力/悟性/天道门槛 + 额外条件道具」→ 自动冲击瓶颈
#     · 成功率 = 基础 + 悟性×1.5% + 天道×2% + (灵力-要求)×1% - 超龄×0.1% + 修正
#     · 失败：年龄 +20、灵力 -2；连续失败 3 次 +10%（最多 +30%）
#   本文件负责修炼收益、丹药/机缘（额外条件）、氛围与互动、心魔与归隐。
#
#   id 段：70xx = 通用修炼 / 71xx = 各境界机缘与丹药 / 72xx = 氛围与互动
# ============================================================

static func _cev(h: Node, id: int, amin: int, amax: int, cond: Callable, w: Callable,
		text: String, effects: Dictionary, cat: String,
		require_flags: Array = [], set_flags: Array = [], clear_flags: Array = [],
		set_status: Dictionary = {}, once: bool = false) -> Dictionary:
	var e: Dictionary = h._make_event(id, amin, amax, cond, w, text, effects, false,
		require_flags, set_flags, clear_flags, 0, {}, set_status, once, cat)
	e["cult"] = true
	return e

static func _cchoice(h: Node, id: int, amin: int, amax: int, cond: Callable, w: Callable,
		text: String, choices: Array, once: bool = false) -> Dictionary:
	var e: Dictionary = h._make_choice_event(id, amin, amax, cond, w, text, choices, once)
	e["cult"] = true
	return e

# 各境界的「额外条件」机缘（任得其一即可突破）
static func _item_events(h: Node, ev: Array) -> void:
	var table := [
		[1, "筑基丹", "你求得一枚筑基丹，丹香扑鼻。"],
		[1, "地脉灵泉", "你寻到一处地脉灵泉，泉水汩汩，灵气逼人。"],
		[2, "破婴丹", "你耗费百年心血，终于炼成破婴丹。"],
		[2, "雷劫洗礼", "你主动引下一道雷霆洗礼肉身，痛楚之后是通体舒泰。"],
		[3, "化神机缘", "你在古洞中得遇前人遗蜕，抓住了化神的机缘。"],
		[3, "神识秘法", "你参透了一卷神识秘法，识海扩张数倍。"],
		[4, "虚空石", "你从虚空裂缝中取回一枚虚空石。"],
		[4, "空间感悟", "你静观潮起潮落，忽然悟得空间之理。"],
		[5, "合体秘法", "你得到一卷合体秘法，肉身与元神隐隐共鸣。"],
		[5, "阴阳调和", "你闭关调和阴阳二气，法体愈发圆融。"],
		[6, "大乘天劫", "你引来一场大乘天劫，硬抗之下道基更固。"],
		[6, "功德", "你施法救下一城百姓，冥冥中积下功德。"],
		[7, "渡劫台", "你寻到一处古渡劫台，台上雷痕犹在。"],
		[7, "避劫法宝", "你祭炼出一件避劫法宝，可挡一次死劫。"],
		[8, "九重天劫", "九重天劫的气息已在云端凝聚，飞升只在一步之遥。"],
	]
	var idx := 0
	for row in table:
		idx += 1
		var rid := 7100 + idx
		var rl := int(row[0])
		var item := str(row[1])
		var txt := str(row[2])
		var cond := func():
			return h.realm == rl and not h._has_cult_item(item)
		ev.append(_cev(h, rid, 16, 9999, cond, func(): return 30, txt,
			{}, "cult_item", [], [], [], {"cult_item": item}, true))

static func build(h: Node) -> Array[Dictionary]:
	var ev: Array[Dictionary] = []

	# ==================== 70xx：通用修炼收益 ====================
	ev.append(_cev(h, 7001, 16, 9999,
		func(): return true, func(): return 70,
		"你盘膝入定，引天地灵气缓缓淬炼经脉。",
		{}, "cult", [], [], [], {"spirit_add": 1, "insight_add": 1}))

	ev.append(_cev(h, 7002, 16, 9999,
		func(): return true, func(): return 60,
		"你反复参详小册子上的功法，对其中关窍似有所悟。",
		{}, "cult", [], [], [], {"insight_add": 2}))

	ev.append(_cev(h, 7003, 16, 9999,
		func(): return true, func(): return 60,
		"你夜观星象，感应到冥冥中的天地气运。",
		{}, "cult", [], [], [], {"dao_add": 1}))

	ev.append(_cev(h, 7004, 16, 9999,
		func(): return true, func(): return 50,
		"你服下一株灵草，灵力在体内涨了一圈。",
		{}, "cult", [], [], [], {"spirit_add": 2}))

	ev.append(_cev(h, 7005, 16, 9999,
		func(): return true, func(): return 45,
		"你枯坐溪畔三月，把心里的杂念一件件放下。",
		{}, "cult", [], [], [], {"dao_add": 2}))

	ev.append(_cev(h, 7006, 16, 9999,
		func(): return true, func(): return 50,
		"你与同道切磋法术，打得山石崩碎，各自都有收获。",
		{}, "cult", [], [], [], {"spirit_add": 1, "insight_add": 1}))

	ev.append(_cev(h, 7007, 16, 9999,
		func(): return h._get_stat("cleverness") >= 6, func(): return 35,
		"你忽然顿悟，识海中一片清明。",
		{}, "cult", [], [], [], {"spirit_add": 1, "insight_add": 1, "dao_add": 1}))

	ev.append(_cev(h, 7008, 16, 9999,
		func(): return h.cult_dao < 10, func(): return 20,
		"你的心境不稳，修炼时气血逆冲，受了些内伤。",
		{}, "cult", [], [], [], {"spirit_add": -1}))

	# ==================== 71xx：各境界丹药与机缘（额外条件） ====================
	_item_events(h, ev)

	# ==================== 72xx：氛围、互动、心魔与归隐 ====================
	ev.append(_cev(h, 7201, 16, 9999,
		func(): return h._get_stat("luck") >= 5, func(): return 22,
		"你救下一只受伤的灵狐，它化作少女向你一拜而去。",
		{"emotion": 1}, "cult", [], [], [], {"spirit_add": 1}))

	ev.append(_cev(h, 7202, 16, 9999,
		func(): return h._get_stat("luck") >= 6, func(): return 18,
		"你在古墓深处发现一株千年灵芝，服下后神清气爽。",
		{}, "cult", [], [], [], {"dao_add": 1}))

	ev.append(_cev(h, 7203, 16, 9999,
		func(): return true, func(): return 20,
		"你与一位山中老友对弈半日，胜负未分，天色已晚。",
		{}, "cult", [], [], [], {"insight_add": 1}))

	ev.append(_cev(h, 7204, 16, 9999,
		func(): return h._get_stat("emotion") >= 6, func(): return 18,
		"你路过村庄，被凡人当成神仙跪拜，哭笑不得。",
		{"emotion": 1}, "cult"))

	ev.append(_cev(h, 7205, 16, 9999,
		func(): return h.realm >= 2, func(): return 18,
		"你收下一名资质不错的少年为徒，把毕生所学倾囊相授。",
		{"emotion": 2}, "cult", [], ["disciple"], [], {"insight_add": 1}, true))

	ev.append(_cev(h, 7206, 16, 9999,
		func(): return h._has_flag("disciple") and h._get_stat("luck") <= 3,
		func(): return 16,
		"你的徒弟起了异心，偷走半卷功法后不知所踪。",
		{"emotion": -3}, "cult", [], [], [], {"spirit_add": -1}))

	ev.append(_cev(h, 7207, 16, 9999,
		func(): return true, func(): return 20,
		"你花了几十年炼制一炉丹药，成色出乎意料地好。",
		{}, "cult", [], [], [], {"spirit_add": 1, "insight_add": 1}))

	ev.append(_cev(h, 7208, 16, 9999,
		func(): return h._get_stat("cleverness") >= 8, func(): return 16,
		"你在论道大会上与诸位大能谈玄论道，受益匪浅。",
		{}, "cult", [], [], [], {"insight_add": 2}))

	# ---- 互动事件：修仙线与凡尘家庭/恋爱线的羁绊 ----
	ev.append(_cev(h, 7211, 16, 9999,
		func(): return h.children_count >= 1, func(): return 22,
		"你以神念遥望人间，看着子孙在坟前为你烧纸，久久无言。",
		{"emotion": 1}, "cult", [], [], [], {"dao_add": 1}))

	ev.append(_cev(h, 7212, 16, 9999,
		func(): return h.marital_status == 0 and h._get_stat("emotion") >= 6,
		func(): return 18,
		"你在山下遇见一位凡间女子，她笑起来的样子像极了记忆中的人。你终究没有停下脚步。",
		{"emotion": 1}, "cult", [], [], [], {"insight_add": 1}))

	# ---- 心魔劫 ----
	ev.append(_cchoice(h, 7213, 16, 9999,
		func(): return h.cult_wu >= 10 and not h._has_flag("heart_demon_done"),
		func(): return 40,
		"你冲击瓶颈时，心中突然浮现出凡尘往事——父母的容颜、爱人的笑靥、子女的哭声。心神动摇，几近走火入魔。",
		[
			{"text": "斩断情丝", "result": "你一剑斩去心中最后的牵挂，道心前所未有的通透。",
			 "effects": {"emotion": -3}, "set_status": {"dao_add": 2},
			 "set_flags": ["heart_demon_done"],
			 "clear_flags": ["in_love", "crush", "quarrel", "suspicion", "met_parents", "betrayed"]},
			{"text": "保留记忆", "result": "你把往事细细收好，可心口那道裂缝再也合不上了。",
			 "effects": {"emotion": 2}, "set_flags": ["heart_demon_done", "keep_memory"]},
		], true))

	# ---- 归隐（主动结束修仙线） ----
	ev.append(_cchoice(h, 7214, 16, 9999,
		func(): return h.realm >= 1, func(): return 15,
		"长生路上你已独行许久。某个黄昏，你忽然想念起人间的炊烟。",
		[
			{"text": "继续修行", "result": "你压下心头的涟漪，重新入定。",
			 "set_status": {"dao_add": 1}},
			{"text": "散功归隐", "result": "你散去一身修为，回到了人间。",
			 "ending": true, "func": func(): h._end_cultivation("归隐")},
		], true))

	# ==================== 75xx：支线转修（魔修 / 魂修，三线互斥） ====================
	# 血月之夜 → 可堕入魔道
	ev.append(_cchoice(h, 7501, 16, 9999,
		func(): return h.cult_path == 0 and h.realm <= 1 and GlobalData.age >= 120 \
			and h.cult_zi >= 15 \
			and (h.cult_dao <= 10 or (h.cult_ling >= 15 and h.cult_wu >= 12)),
		func(): return 45,
		"血月当空，天地间的灵气骤然变得粘稠腥甜。一个声音在你心底低语：「天道不公，何不自立一道？」",
		[
			{"text": "堕入魔道（耗15资源）", "result": "你握住那缕血色气机，从此与天道分道扬镳。",
			 "effects": {"emotion": -1},
			 "func": func(): h.cult_zi = maxi(0, h.cult_zi - 15); h._switch_path(1)},
			{"text": "守住本心", "result": "你咬破舌尖，硬生生压下了那股躁动。",
			 "set_status": {"dao_add": 1}},
		], true))

	# 幽冥魂匣 → 可转修魂道
	ev.append(_cchoice(h, 7502, 16, 9999,
		func(): return h.cult_path == 0 and h.realm <= 1 and GlobalData.age >= 120 \
			and h.cult_zi >= 20 and h.cult_wu >= 15 and h.cult_dao >= 10,
		func(): return 45,
		"你在乱葬岗挖到一只刻满符文的魂匣，匣中有一盏不灭的魂灯，正微微跳动。",
		[
			{"text": "转修魂道（耗20资源）", "result": "你以魂灯引路，将神识沉入幽冥。",
			 "func": func(): h.cult_zi = maxi(0, h.cult_zi - 20); h._switch_path(2)},
			{"text": "不做理会", "result": "你把魂匣重新埋回土里，转身离开。",
			 "set_status": {"insight_add": 1}},
		], true))

	# ---- 魔修专属事件 ----
	ev.append(_cev(h, 7511, 16, 9999,
		func(): return h.cult_path == 1, func(): return 35,
		"又一个血月之夜。你借着月华淬炼魔元，胸口一片滚烫。",
		{}, "cult", [], [], [], {"spirit_add": 3, "dao_add": 5, "extra_add": 3}))

	ev.append(_cev(h, 7512, 16, 9999,
		func(): return h.cult_path == 1, func(): return 25,
		"你吞噬了一名同道毕生的修为，魔元暴涨，心底却空了一块。",
		{"emotion": -1}, "cult", [], [], [], {"spirit_add": 4, "extra_add": 5, "dao_add": 8}))

	ev.append(_cev(h, 7513, 16, 9999,
		func(): return h.cult_path == 1 and not h._has_cult_item("魔功"),
		func(): return 30,
		"你从一具古尸的识海里，翻出了一卷残缺的魔功。",
		{}, "cult", [], [], [], {"insight_add": 2, "cult_item": "魔功"}, true))

	ev.append(_cev(h, 7514, 16, 9999,
		func(): return h.cult_path == 1, func(): return 25,
		"夜深人静时，你听见自己心里有个声音在笑。",
		{}, "cult", [], [], [], {"heart_demon_add": 1}))

	ev.append(_cchoice(h, 7515, 16, 9999,
		func(): return h.cult_path == 1 and h.cult_dao >= 50, func(): return 30,
		"正道修士寻到了你的洞府，为首者厉声道：「魔头，受死！」",
		[
			{"text": "以煞气迎战", "result": "你把来犯者尽数斩杀，煞气冲天。",
			 "set_status": {"extra_add": 5, "dao_add": 3}},
			{"text": "遁走", "result": "你且战且退，虽保住了性命，却也受了不轻的伤。",
			 "set_status": {"spirit_add": -2}},
		]))

	ev.append(_cchoice(h, 7516, 16, 9999,
		func(): return h.cult_path == 1 and h.cult_dao >= 100 and GlobalData.age >= 500,
		func(): return 999,
		"业力滔天，正道七大宗门联手围剿。你立于山巅，四面皆是剑光。",
		[
			{"text": "血战到底", "result": "你力战而亡，魔气消散于天地之间。",
			 "ending": true, "func": func(): h._end_cultivation("正道围剿")},
		], true))

	# ---- 魂修专属事件 ----
	ev.append(_cev(h, 7521, 16, 9999,
		func(): return h.cult_path == 2, func(): return 35,
		"你以魂灯引路，在幽冥与人间的夹缝中走了一遭。",
		{}, "cult", [], [], [], {"extra_add": 1, "dao_add": 3}))

	ev.append(_cev(h, 7522, 16, 9999,
		func(): return h.cult_path == 2, func(): return 28,
		"你看着人间一代人出生又死去，忽然懂了什么叫轮回。",
		{}, "cult", [], [], [], {"insight_add": 3, "dao_add": 5}))

	ev.append(_cev(h, 7523, 16, 9999,
		func(): return h.cult_path == 2, func(): return 25,
		"幽冥深处传来一缕赐福，你的魂力与魂火同时壮大。",
		{}, "cult", [], [], [], {"spirit_add": 3, "extra_add": 1}))

	ev.append(_cev(h, 7524, 16, 9999,
		func(): return h.cult_path == 2 and not h._has_cult_item("魂器"),
		func(): return 30,
		"你以自身一缕魂火祭炼出一件魂器，从此魂体有了凭依。",
		{}, "cult", [], [], [], {"cult_item": "魂器"}, true))

	ev.append(_cev(h, 7525, 16, 9999,
		func(): return h.cult_path == 2 and h.cult_extra <= 1, func(): return 22,
		"魂火将熄时，你强行从一具新亡的躯壳中醒来，堪堪续住了这一世。",
		{"emotion": -1}, "cult", [], [], [], {"extra_add": 1}))

	return ev
