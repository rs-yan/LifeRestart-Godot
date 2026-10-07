extends RefCounted

# ============================================================
# 性别专属事件（GlobalData.gender：0 = 女，1 = 男）
#   注入：event_pool.append_array(GenderEvents.build(self))
#   id 段：80xx 女性 / 82xx 男性 / 84xx 修仙期间的性别专属
# ============================================================

static func _ev(h: Node, id: int, amin: int, amax: int, cond: Callable, w: Callable,
		text: String, effects: Dictionary, cat: String,
		require_flags: Array = [], set_flags: Array = [], clear_flags: Array = [],
		set_status: Dictionary = {}, once: bool = false, stress_delta: int = 0) -> Dictionary:
	return h._make_event(id, amin, amax, cond, w, text, effects, false,
		require_flags, set_flags, clear_flags, stress_delta, {}, set_status, once, cat)

static func _cev(h: Node, id: int, amin: int, amax: int, cond: Callable, w: Callable,
		text: String, effects: Dictionary, cat: String,
		set_status: Dictionary = {}, once: bool = false) -> Dictionary:
	var e: Dictionary = h._make_event(id, amin, amax, cond, w, text, effects, false,
		[], [], [], 0, {}, set_status, once, cat)
	e["cult"] = true
	return e

static func build(h: Node) -> Array[Dictionary]:
	var ev: Array[Dictionary] = []

	# ==================== 女性 ====================
	ev.append(_ev(h, 8001, 0, 3,
		func(): return GlobalData.gender == 0, func(): return 22,
		"奶奶听说又是个女娃，脸上的笑淡了几分。",
		{"emotion": -1}, "female", [], [], [], {}, true))

	ev.append(_ev(h, 8002, 7, 12,
		func(): return GlobalData.gender == 0, func(): return 20,
		"家里人说，女孩子读那么多书没用，不如早点学门手艺。",
		{"cleverness": -1, "emotion": -1}, "female", [], [], [], {}, true))

	ev.append(_ev(h, 8003, 11, 15,
		func(): return GlobalData.gender == 0, func(): return 24,
		"你第一次经历初潮，慌乱得不知道该怎么办，只能把校服裹紧。",
		{"strong": -1, "emotion": 1}, "female", [], [], [], {}, true))

	ev.append(_ev(h, 8004, 13, 18,
		func(): return GlobalData.gender == 0, func(): return 22,
		"你和几个女生成了无话不谈的朋友，一起分享秘密和心事。",
		{"emotion": 2}, "female", [], [], [], {}, true))

	ev.append(_ev(h, 8005, 10, 18,
		func(): return GlobalData.gender == 0, func(): return 18,
		"母亲教你和面、缝补，说女孩子要学会照顾自己。",
		{"cleverness": 1, "emotion": 1}, "female", [], [], [], {}, true))

	ev.append(_ev(h, 8006, 19, 32,
		func(): return GlobalData.gender == 0 and h._get_stat("money") <= 4,
		func(): return 20,
		"你在流水线上站了一整夜，回到出租屋时天已经亮了。",
		{"strong": -1, "money": 1}, "female"))

	ev.append(_ev(h, 8007, 22, 38,
		func(): return GlobalData.gender == 0 and h.job_status != 0,
		func(): return 20,
		"同样的活，你的薪水比同期的男同事低了一截。",
		{"money": -1, "emotion": -1}, "female"))

	ev.append(_ev(h, 8008, 25, 40,
		func(): return GlobalData.gender == 0 and h.marital_status == 0,
		func(): return 22,
		"七大姑八大姨把你围在中间：「还不结婚，再挑就没人要了。」",
		{"emotion": -1}, "female", [], [], [], {}, false, 1))

	ev.append(_ev(h, 8009, 26, 40,
		func(): return GlobalData.gender == 0 and h.marital_status == 2 \
			and h.children_count == 0,
		func(): return 20,
		"怀孕和生产几乎耗尽了你的力气，但你还是笑了。",
		{"strong": -1, "emotion": 2}, "female", [], [], [], {}, true))

	# ==================== 男性 ====================
	ev.append(_ev(h, 8201, 0, 3,
		func(): return GlobalData.gender == 1, func(): return 22,
		"家里人说：是男娃，好！",
		{"emotion": 1}, "male", [], [], [], {}, true))

	ev.append(_ev(h, 8202, 7, 12,
		func(): return GlobalData.gender == 1, func(): return 20,
		"你摔破了膝盖哭出声，父亲说：「男子汉不许哭。」",
		{"emotion": -1, "strong": 1}, "male", [], [], [], {}, true))

	ev.append(_ev(h, 8203, 10, 16,
		func(): return GlobalData.gender == 1, func(): return 22,
		"为了保护同桌，你在操场上和几个高年级的男生打了一架。",
		{"strong": 1, "emotion": -1}, "male", [], [], [], {}, true))

	ev.append(_ev(h, 8204, 10, 16,
		func(): return GlobalData.gender == 1, func(): return 18,
		"父亲带你干活，教你看图纸、使工具，说这是吃饭的本事。",
		{"money": 1, "cleverness": 1}, "male", [], [], [], {}, true))

	ev.append(_ev(h, 8205, 18, 22,
		func(): return GlobalData.gender == 1 and h._get_stat("strong") >= 5,
		func(): return 24,
		"你参了军。两年后回来时，腰板挺得笔直。",
		{"strong": 2, "emotion": 1}, "male", [], [], [], {}, true))

	ev.append(_ev(h, 8206, 25, 45,
		func(): return GlobalData.gender == 1 and h.job_status != 0,
		func(): return 20,
		"为了签下那单生意，你陪客户喝到胃里翻江倒海。",
		{"money": 1, "strong": -1}, "male", [], [], [], {}, false, 1))

	ev.append(_ev(h, 8207, 30, 50,
		func(): return GlobalData.gender == 1 and h.marital_status == 2,
		func(): return 20,
		"全家都指着你，你不敢倒下，也不敢喊累。",
		{"emotion": -1}, "male", [], [], [], {}, false, 2))

	ev.append(_ev(h, 8208, 35, 50,
		func(): return GlobalData.gender == 1, func(): return 18,
		"皮带又松了两个扣，你摸着肚子叹了口气。",
		{"beauty": -1, "emotion": -1}, "male"))

	# ==================== 修仙期间的性别专属 ====================
	ev.append(_cev(h, 8401, 16, 9999,
		func(): return GlobalData.gender == 0 and h.cult_face >= 12, func(): return 22,
		"一位女修士见你根骨清奇，愿意收你为记名弟子。",
		{"emotion": 1}, "cult_female", {"face_add": 2}, true))

	ev.append(_cev(h, 8402, 16, 9999,
		func(): return GlobalData.gender == 1 and h.cult_ling >= 12, func(): return 22,
		"你与同门斗法，一招制敌，围观者议论纷纷。",
		{}, "cult_male", {"spirit_add": 2}, true))

	return ev
