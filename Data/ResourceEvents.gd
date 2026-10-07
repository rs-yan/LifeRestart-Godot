extends RefCounted

# ============================================================
# 修仙线资源系统（《修仙线资源系统完整策划案》）
#
#   注入：event_pool.append_array(ResourceEvents.build(self))
#   全部带 cult 标记，只在修仙期间触发。
#   资源 = 家境÷5（钳制到当前境界上限）；用途：突破固定消耗 + 额外投入、购买丹药法宝、渡劫准备。
#   突破额外投入：每 10 点资源 +2% 成功率（最多 +10%），失败时固定消耗全扣、额外投入退还 50%（main.gd）。
#
#   id 段：77xx
# ============================================================

static func _cev(h: Node, id: int, amin: int, amax: int, cond: Callable, w: Callable,
		text: String, effects: Dictionary, cat: String,
		require_flags: Array = [], set_flags: Array = [], clear_flags: Array = [],
		set_status: Dictionary = {}, once: bool = false) -> Dictionary:
	var e: Dictionary = h._make_event(id, amin, amax, cond, w, text, effects, false,
		require_flags, set_flags, clear_flags, 0, {}, set_status, once, cat)
	e["cult"] = true
	return e

static func _cbranch(h: Node, id: int, amin: int, amax: int, cond: Callable, w: Callable,
		prompt: String, chance, ok_side: Dictionary, ng_side: Dictionary,
		cat: String, once: bool = false) -> Dictionary:
	var e: Dictionary = h._make_branch_event(id, amin, amax, cond, w, prompt, chance,
		ok_side, ng_side, once, cat)
	e["cult"] = true
	return e

static func _cchoice(h: Node, id: int, amin: int, amax: int, cond: Callable, w: Callable,
		text: String, choices: Array, once: bool = false) -> Dictionary:
	var e: Dictionary = h._make_choice_event(id, amin, amax, cond, w, text, choices, once)
	e["cult"] = true
	return e

static func build(h: Node) -> Array[Dictionary]:
	var ev: Array[Dictionary] = []

	# ==================== 资源获取 ====================
	ev.append(_cev(h, 7701, 16, 9999,
		func(): return true, func(): return 35,
		"你在后山发现一条废弃的灵石矿脉，挖了整整三个月。",
		{}, "cult", [], [], [], {"res_add": 7}))

	ev.append(_cev(h, 7702, 16, 9999,
		func(): return h.realm <= 1, func(): return 30,
		"你接下宗门任务，替一位长老采摘灵草，报酬还算丰厚。",
		{}, "cult", [], [], [], {"res_add": 3, "spirit_add": 1}))

	ev.append(_cev(h, 7703, 16, 9999,
		func(): return h.realm >= 1, func(): return 28,
		"你孤身探入一处秘境，从坍塌的洞窟里带回了大批灵材。",
		{}, "cult", [], [], [], {"res_add": 8, "dao_add": 1}))

	ev.append(_cev(h, 7704, 16, 9999,
		func(): return h.realm >= 2, func(): return 25,
		"你名下的灵田喜获丰收，灵石堆了半间屋。",
		{}, "cult", [], [], [], {"res_add": 3}))

	ev.append(_cev(h, 7705, 16, 9999,
		func(): return h.cult_dao >= 20, func(): return 22,
		"拍卖会上，你一眼看出那枚蒙尘的旧玉是件好东西。",
		{}, "cult", [], [], [], {"res_add": 5, "dao_add": 1}))

	ev.append(_cev(h, 7706, 16, 9999,
		func(): return h.cult_face >= 15, func(): return 22,
		"道侣把积攒多年的灵石塞进你手里，说：「拿着，别硬撑。」",
		{"emotion": 1}, "cult", [], [], [], {"res_add": 5, "face_add": 1}))

	ev.append(_cev(h, 7707, 16, 9999,
		func(): return h.cult_dao >= 20, func(): return 20,
		"天降横财：你在一场雷雨后的山谷里，捡到了雷击木中凝结的灵石。",
		{}, "cult", [], [], [], {"res_add": 10, "dao_add": -2}))

	# 炼丹 / 炼器：消耗资源换取收益
	ev.append(_cbranch(h, 7708, 16, 9999,
		func(): return h.cult_wu >= 15 and h.cult_zi >= 5, func(): return 26,
		"你开炉炼丹，火候全凭悟性拿捏。",
		func(): return clampf(float(h.cult_wu) / 40.0, 0.25, 0.9),
		{"text": "丹成九转，你服下后灵力大涨。", "set_status": {"res_add": -5, "spirit_add": 2}},
		{"text": "丹炉炸开，材料尽毁。", "set_status": {"res_add": -5}},
		"cult"))

	ev.append(_cbranch(h, 7709, 16, 9999,
		func(): return h.cult_ling >= 15 and h.cult_zi >= 8, func(): return 24,
		"你闭关炼器，锤声在洞府里响了一整年。",
		func(): return clampf(float(h.cult_ling) / 50.0, 0.2, 0.85),
		{"text": "法宝出炉，灵光内敛。", "set_status": {"res_add": -8}, "set_flags": ["法宝"]},
		{"text": "器胚碎裂，灵气四散。", "set_status": {"res_add": -8}},
		"cult"))

	# ==================== 资源损失 ====================
	ev.append(_cev(h, 7710, 16, 9999,
		func(): return h.cult_zi >= 20 and h.cult_xin < 40, func(): return 24,
		"你被一伙散修盯上，斗法之后虽保住性命，储物袋却被抢去大半。",
		{}, "cult", [], [], [], {"res_pct": 50}))

	ev.append(_cev(h, 7711, 16, 9999,
		func(): return h.cult_path == 2 and h.cult_zi >= 10, func(): return 20,
		"你以一缕魂火替一具新亡的躯壳续命，从中取走了它生前的积蓄。",
		{}, "cult", [], [], [], {"res_add": -10, "extra_add": -1}))

	# ==================== 支线资源 ====================
	ev.append(_cev(h, 7712, 16, 9999,
		func(): return h.cult_path == 1, func(): return 30,
		"你血祭了一座凡城。魔资暴涨，天边却隐约传来钟声。",
		{"emotion": -2}, "cult", [], [], [], {"res_add": 20, "dao_add": 20, "extra_add": 10}))

	ev.append(_cev(h, 7713, 16, 9999,
		func(): return h.cult_path == 1, func(): return 25,
		"你掠夺了另一名魔修的洞府，连人带宝一并吞下。",
		{}, "cult", [], [], [], {"res_add": 12, "dao_add": 8, "extra_add": 5}))

	ev.append(_cbranch(h, 7714, 16, 9999,
		func(): return h.cult_path == 2, func(): return 28,
		"你在幽冥矿脉中养魂，魂资与魂火一同滋长。",
		0.5,
		{"text": "矿脉深处，一点幽蓝的魂火被你收进识海。", "set_status": {"res_add": 5, "extra_add": 1}},
		{"text": "矿脉塌陷，你只带回了少量魂资。", "set_status": {"res_add": 5}},
		"cult"))

	# ==================== 丹药坊市（消耗资源换属性） ====================
	ev.append(_cchoice(h, 7720, 16, 9999,
		func(): return h.cult_zi >= 5, func(): return 40,
		"坊市大开，丹药铺的伙计隔着柜台朝你招手：「道友，来看看？」",
		[
			{"text": "淬体丹（灵力+2，5资源）", "result": "灵力凝实了几分。", "cost": 5,
			 "cond": func(): return h.cult_zi >= 5,
			 "func": func(): h.cult_zi -= 5; h.cult_ling = clampi(h.cult_ling + 2, 1, h._cult_cap())},
			{"text": "开慧丹（悟性+2，5资源）", "result": "识海一片清凉。", "cost": 5,
			 "cond": func(): return h.cult_zi >= 5,
			 "func": func(): h.cult_zi -= 5; h.cult_wu = clampi(h.cult_wu + 2, 1, h._cult_cap())},
			{"text": "气运丹（天道+2，8资源）", "result": "你隐约觉得身边的风都顺了几分。", "cost": 8,
			 "cond": func(): return h.cult_zi >= 8,
			 "func": func(): h.cult_zi -= 8; h.cult_dao = clampi(h.cult_dao + 2, 1, h._cult_cap())},
			{"text": "静心丹（心智+2，6资源）", "result": "心湖不起一丝波澜。", "cost": 6,
			 "cond": func(): return h.cult_zi >= 6,
			 "func": func(): h.cult_zi -= 6; h.cult_xin = clampi(h.cult_xin + 2, 1, h._cult_cap())},
			{"text": "驻颜丹（面相+2，6资源）", "result": "镜中的自己仿佛年轻了十岁。", "cost": 6,
			 "cond": func(): return h.cult_zi >= 6,
			 "func": func(): h.cult_zi -= 6; h.cult_face = clampi(h.cult_face + 2, 1, h._cult_cap())},
			{"text": "补灵丹（灵力+3，8资源，筑基以上）", "result": "灵力气机凝实如实质。", "cost": 8,
			 "cond": func(): return h.cult_zi >= 8 and h.realm >= 1,
			 "func": func(): h.cult_zi -= 8; h.cult_ling = clampi(h.cult_ling + 3, 1, h._cult_cap())},
			{"text": "悟道丹（悟性+3，12资源，金丹以上）", "result": "你闭目静坐三日，忽觉天地开阔。", "cost": 12,
			 "cond": func(): return h.cult_zi >= 12 and h.realm >= 2,
			 "func": func(): h.cult_zi -= 12; h.cult_wu = clampi(h.cult_wu + 3, 1, h._cult_cap())},
			{"text": "延寿丹（年龄-10，15资源，每境界限1次）", "result": "一股暖流游遍四肢百骸。", "cost": 15,
			 "cond": func(): return h.cult_zi >= 15 and not h._has_flag("pill_yanshou_%d" % h.realm),
			 "func": func(): h.cult_zi -= 15; GlobalData.age = maxi(0, GlobalData.age - 10); h._set_flag("pill_yanshou_%d" % h.realm)},
		], false))

	# ==================== 资源不足时的抉择：强行突破 ====================
	ev.append(_cchoice(h, 7721, 16, 9999,
		func(): return h.cult_zi < h._req_res_cost() and h.cult_ling >= h._req_core(0) \
			and h.cult_wu >= h._req_core(1) and h.cult_dao >= h._req_core(2) \
			and h.cult_xin >= h._req_mind() and GlobalData.age >= h._req_age(),
		func(): return 50,
		"瓶颈已在眼前，可你的储物袋空了。强行冲击，九死一生。",
		[
			{"text": "强行突破", "result": "你赌上了全部身家，硬撼天关。",
			 "func": func(): h._force_breakthrough()},
			{"text": "再等等", "result": "你按下了心头的躁动，决定先去攒些资源。",
			 "set_status": {"mind_add": 1}},
		], true))

	# ==================== 富甲修真界（资源≥100 且未飞升） ====================
	ev.append(_cchoice(h, 7722, 16, 9999,
		func(): return h.cult_zi >= 100 and GlobalData.age >= 800, func(): return 60,
		"你的灵石堆成了山，够买下半座修真界。有人劝你：「道友，何必再去争那缥缈仙途？」",
		[
			{"text": "做个富家翁", "result": "你把洞府改成了坊市，从此再没出过关。",
			 "ending": true, "func": func(): h._end_cultivation("富甲修真界")},
			{"text": "继续修行", "result": "你把灵石尽数投入丹炉，只留下一句话：「仙途无价。」",
			 "set_status": {"res_add": -20, "mind_add": 2}},
		], true))

	# ==================== 拍卖会（资源换丹药 / 法宝 / 灵脉 / 洞府） ====================
	ev.append(_cchoice(h, 7730, 16, 9999,
		func(): return h.cult_zi >= 8, func(): return 45,
		"十年一度的拍卖会开场，楼上雅座里坐满了各宗长老。",
		[
			{"text": "破境丹（10资源，本次突破 +5%，每境界限1次）", "result": "丹药入手，瓶颈似乎松动了一线。", "cost": 10,
			 "cond": func(): return h.cult_zi >= 10 and not h._has_flag("pill_pojing_%d" % h.realm),
			 "func": func(): h.cult_zi -= 10; h._grant_cult_item("破境丹"); h._set_flag("pill_pojing_%d" % h.realm)},
			{"text": "渡劫丹（20资源，渡劫飞升 +5%，每境界限1次）", "result": "丹药封在玉盒里，隐隐有雷光流转。", "cost": 20,
			 "cond": func(): return h.cult_zi >= 20 and h.realm == 8 and not h._has_flag("pill_dujie_%d" % h.realm),
			 "func": func(): h.cult_zi -= 20; h._grant_cult_item("渡劫丹"); h._set_flag("pill_dujie_%d" % h.realm)},
			{"text": "保命符箓（8资源，可挡一次死劫）", "result": "符纸入手微烫，据说能替主人死一次。", "cost": 8,
			 "cond": func(): return h.cult_zi >= 8,
			 "func": func(): h.cult_zi -= 8; h._grant_cult_item("符箓")},
			{"text": "灵脉（30资源，每10年 +2资源）", "result": "一条细小的灵脉被牵进了你的洞府。", "cost": 30,
			 "cond": func(): return h.cult_zi >= 30,
			 "func": func(): h.cult_zi -= 30; h._grant_cult_item("灵脉")},
			{"text": "开辟洞府（15资源，下次突破 +5%）", "result": "你在灵眼之上开出一座洞府，聚灵阵日夜不休。", "cost": 15,
			 "cond": func(): return h.cult_zi >= 15,
			 "func": func(): h.cult_zi -= 15; h._grant_cult_item("洞府")},
			{"text": "囊中羞涩，看看就好", "result": "你摸了摸空空的储物袋，默默退场。",
			 "effects": {}},
		], false))

	# ==================== 赌石（资源 ±50%，看心智） ====================
	ev.append(_cbranch(h, 7731, 16, 9999,
		func(): return h.cult_zi >= 10, func(): return 26,
		"坊市角落有人摆摊卖原石，说是从上古矿场里挖出来的。",
		func(): return clampf(float(h.cult_xin) / 100.0, 0.2, 0.85),
		{"text": "石皮破开，里面是一块成色极好的灵石。",
		 "func": func(): h.cult_zi = mini(h._cult_cap(), int(float(h.cult_zi) * 1.5))},
		{"text": "石头里什么也没有，摊主早没了踪影。",
		 "func": func(): h.cult_zi = int(float(h.cult_zi) * 0.5)},
		"cult"))

	# ==================== 黑市（资源换保命符，代价是天道） ====================
	ev.append(_cchoice(h, 7732, 16, 9999,
		func(): return h.cult_zi >= 10, func(): return 20,
		"黑市深处，一个戴着兜帽的人掀开木匣：「这是禁物，敢不敢要？」",
		[
			{"text": "买下（10资源，天道-5，得符箓）", "result": "你把木匣收进袖中，身后似乎有人盯了你一眼。", "cost": 10,
			 "cond": func(): return h.cult_zi >= 10,
			 "func": func(): h.cult_zi -= 10; h.cult_dao = maxi(1, h.cult_dao - 5); h._grant_cult_item("符箓")},
			{"text": "转身就走", "result": "你快步离开，没敢回头。",
			 "set_status": {"dao_add": 1}},
		], false))

	# ==================== 治疗心魔（魔修专属） ====================
	ev.append(_cchoice(h, 7733, 16, 9999,
		func(): return h.cult_path == 1 and h.heart_demon >= 1 and h.cult_zi >= 10,
		func(): return 40,
		"你请来一位游方术士，他看了看你的眉心：「心魔已生，再拖就来不及了。」",
		[
			{"text": "花10资源压制（心魔-1）", "result": "术士在你眉心画下一道镇魔纹，耳边的低语终于安静了。", "cost": 10,
			 "cond": func(): return h.cult_zi >= 10,
			 "func": func(): h.cult_zi -= 10; h.heart_demon = maxi(0, h.heart_demon - 1)},
			{"text": "不治，我自有分寸", "result": "你挥手把术士赶了出去。",
			 "set_status": {"extra_add": 3}},
		], false))

	# ==================== 资源负面 / 中立事件 ====================
	ev.append(_cev(h, 7734, 16, 9999,
		func(): return h.cult_zi >= 20 and h.cult_xin < 50, func(): return 20,
		"你把大半灵石投给了同门的「稳赚不赔」的生意，血本无归。",
		{}, "cult", [], [], [], {"res_pct": 70}))

	ev.append(_cev(h, 7735, 16, 9999,
		func(): return true, func(): return 18,
		"丹药铺的掌柜笑呵呵地说：「近来灵材涨得厉害，这价钱……得加。」",
		{}, "cult", [], [], [], {"res_add": -5}))

	ev.append(_cev(h, 7736, 16, 9999,
		func(): return h.realm >= 2 and h.cult_zi >= 20, func(): return 16,
		"宗门查账，你名下的一处灵田被罚没充公。",
		{}, "cult", [], [], [], {"res_add": -20}))

	ev.append(_cchoice(h, 7737, 16, 9999,
		func(): return h.cult_zi <= 5, func(): return 22,
		"一位故交找上门来：「手头紧？我可以先借你一批灵石。」",
		[
			{"text": "借10资源（日后或加息偿还）", "result": "灵石到手，你却没敢看他的眼睛。",
			 "func": func(): h._borrow_resource(),
			 "set_flags": ["debt"]},
			{"text": "婉拒", "result": "你说自己还撑得住。",
			 "set_status": {"mind_add": 1}},
		], false))

	return ev
