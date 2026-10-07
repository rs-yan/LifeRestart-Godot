extends RefCounted

# ============================================================
# 修仙线：晋级物品获取（⑨）+ 修仙期间多样化事件（⑥）
#   id 段：78xx
#   设计：晋级物品不直接告诉玩家清单，而是通过这些机缘事件"潜移默化"地拿到
# ============================================================

static func _cev(h: Node, id: int, amin: int, amax: int, cond: Callable, w: Callable,
		text: String, effects: Dictionary, cat: String, set_status: Dictionary = {},
		once: bool = false, stress_delta: int = 0) -> Dictionary:
	var e: Dictionary = h._make_event(id, amin, amax, cond, w, text, effects, false,
		[], [], [], stress_delta, {}, set_status, once, cat)
	e["cult"] = true
	return e

static func _cbranch(h: Node, id: int, amin: int, amax: int, cond: Callable, w: Callable,
		text: String, chance: Callable, ok: Dictionary, ng: Dictionary, cat: String) -> Dictionary:
	var e: Dictionary = h._make_branch_event(id, amin, amax, cond, w, text, chance, ok, ng, cat)
	e["cult"] = true
	return e

static func build(h: Node) -> Array[Dictionary]:
	var ev: Array[Dictionary] = []

	# ==================== ⑨ 晋级物品获取 ====================
	ev.append(_cev(h, 7801, 16, 9999,
		func(): return true, func(): return 26,
		"你探入一座上古遗迹。断壁残垣之间，灵光一闪，似有什么在等着你。",
		{"emotion": 1}, "cult_item", {"grant_common": 1}))

	ev.append(_cev(h, 7802, 16, 9999,
		func(): return true, func(): return 24,
		"宗门任务挂在石壁上。你挑了最远的那一条，回来时怀里多了一样东西。",
		{}, "cult_item", {"grant_common": 1, "res_add": 3}))

	ev.append(_cev(h, 7803, 16, 9999,
		func(): return h.cult_zi >= 12, func(): return 22,
		"坊市深处有个不起眼的小摊，摊主眯着眼打量你：「有件你正缺的东西。」",
		{}, "cult_item", {"grant_common": 1, "res_add": -12}))

	ev.append(_cev(h, 7804, 16, 9999,
		func(): return h.realm >= 1, func(): return 22,
		"你与几位同道论道七日，讲到紧要处，其中一个忽然起身朝你深深一揖。",
		{"emotion": 1}, "cult_item", {"grant_core": 1, "insight_add": 1}))

	ev.append(_cev(h, 7805, 16, 9999,
		func(): return h.realm >= 2, func(): return 20,
		"你以肉身受了一遭雷池淬体，皮开肉绽之后，气息反倒凝实了几分。",
		{}, "cult_item", {"grant_core": 1, "spirit_add": 2}))

	ev.append(_cev(h, 7806, 16, 9999,
		func(): return h.realm >= 3, func(): return 20,
		"夜半星移，一道异光自天穹垂落，落进你洞府前的深潭。",
		{}, "cult_item", {"grant_core": 1, "dao_add": 1}))

	ev.append(_cev(h, 7807, 16, 9999,
		func(): return true, func(): return 18,
		"一位多年未见的故人忽然来访，临走时把一样东西塞进你手里：「当年欠你的。」",
		{"emotion": 2}, "cult_item", {"grant_common": 1}))

	ev.append(_cev(h, 7808, 16, 9999,
		func(): return h.realm >= 6, func(): return 22,
		"天边传来一声钟鸣，一物自云中落下，恰好落在你掌心。",
		{}, "cult_item", {"grant_core": 1}))

	ev.append(_cev(h, 7809, 16, 9999,
		func(): return true, func(): return 16,
		"你在石壁上静坐三日三夜，忽然把一桩旧事想通了。",
		{"emotion": 1}, "cult_item", {"grant_pre": 1, "mind_add": 1}, false))

	ev.append(_cev(h, 7810, 16, 9999,
		func(): return h.realm >= 8 and h.cult_zi >= 40, func(): return 24,
		"飞升在即，一位老者拦住你：「此物与你有缘，四十块灵石，不二价。」",
		{}, "cult_item", {"grant_key": 1, "res_add": -40}))

	# ==================== ⑥ 修仙期间多样化事件 ====================
	ev.append(_cev(h, 7820, 16, 9999,
		func(): return true, func(): return 22,
		"你与山中一位散修对坐论道，从日出说到月落。",
		{"emotion": 1}, "cult_life", {"insight_add": 1}))

	ev.append(_cev(h, 7821, 16, 9999,
		func(): return true, func(): return 20,
		"你化作凡人模样，回到山下的集市走了一圈，看了很久的烟火。",
		{"emotion": 2}, "cult_life", {"mind_add": 1}))

	ev.append(_cev(h, 7822, 16, 9999,
		func(): return h.realm >= 2, func(): return 18,
		"一个少年跪在你洞府外三日，求你做他的师父。",
		{"emotion": 2}, "cult_life", {"mind_add": 1}, true))

	ev.append(_cev(h, 7823, 16, 9999,
		func(): return h.realm >= 1, func(): return 20,
		"宗门大比，你在演武台上连胜七场，直到再无人敢上来。",
		{"emotion": 2}, "cult_life", {"spirit_add": 2}, true))

	ev.append(_cev(h, 7824, 16, 9999,
		func(): return true, func(): return 18,
		"你闭了三年死关，出关时鬓边多了一缕白，眼神却比从前亮。",
		{}, "cult_life", {"insight_add": 2}, true))

	ev.append(_cev(h, 7825, 16, 9999,
		func(): return true, func(): return 20,
		"一伙妖修在凡间作乱，你顺手斩了，连名字都没问。",
		{"emotion": 1}, "cult_life", {"spirit_add": 1, "res_add": 3}))

	ev.append(_cev(h, 7826, 16, 9999,
		func(): return true, func(): return 20,
		"夜深人静，你听见心底有个声音在说话。它说的每一句，都像是你自己想说却不敢说的。",
		{"emotion": -1}, "cult_life", {"mind_add": 1}, false, 1))

	ev.append(_cev(h, 7827, 16, 9999,
		func(): return true, func(): return 16,
		"你在旧居的废墟里找到一只缺了口的碗——那是你小时候用过的。",
		{"emotion": 2}, "cult_life", {"mind_add": 2}, true))

	ev.append(_cev(h, 7828, 16, 9999,
		func(): return true, func(): return 18,
		"古碑立在荒原上，字迹被风磨平了大半。你盯着看了一整夜。",
		{}, "cult_life", {"insight_add": 1, "dao_add": 1}))

	ev.append(_cev(h, 7829, 16, 9999,
		func(): return true, func(): return 16,
		"一只通体雪白的小兽赖在你洞府门口不走，赶了几次又跑回来。",
		{"emotion": 2}, "cult_life", {"face_add": 1}, true))

	ev.append(_cev(h, 7830, 16, 9999,
		func(): return h.realm >= 2, func(): return 16,
		"你在山门讲道三日，台下听者越来越多，最后连长老都来了。",
		{"emotion": 1}, "cult_life", {"dao_add": 1, "mind_add": 1}, true))

	# 坐死关：赌一把
	ev.append(_cbranch(h, 7831, 16, 9999,
		func(): return true, func(): return 18,
		"你盘坐于灵穴之上，打算坐一次死关——要么一日千里，要么形销骨立。",
		func(): return clampf(0.35 + float(h.cult_xin) / 60.0, 0.3, 0.85),
		{"text": "出关时你周身气息暴涨，境界虽未动，根骨却已不同。",
		 "set_status": {"spirit_add": 3, "insight_add": 2}},
		{"text": "三年后你被人抬出关房，形容枯槁。",
		 "set_status": {"res_add": -5}},
		"cult_life"))

	ev.append(_cev(h, 7832, 16, 9999,
		func(): return h.realm >= 3, func(): return 16,
		"星河倒悬，你在这一刻看见了某种庞大的、无法言说的东西。",
		{}, "cult_life", {"dao_add": 2}, true))

	ev.append(_cev(h, 7833, 16, 9999,
		func(): return true, func(): return 18,
		"同门为了几株灵药与你起了争执，最后不欢而散。",
		{"emotion": -1}, "cult_life", {"spirit_add": 1}))

	ev.append(_cev(h, 7834, 16, 9999,
		func(): return h.marital_status == 2, func(): return 20,
		"道侣陪你走了一趟远门，路上什么也没做成，却都很高兴。",
		{"emotion": 2}, "cult_life", {"mind_add": 1}))

	return ev
