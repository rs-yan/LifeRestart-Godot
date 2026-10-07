extends RefCounted

# ============================================================
# 家庭线 F01-F45（策划案第三节）
#
#   注入方式（Main/main.gd 的 _init_event_pool）：
#     event_pool.append_array(FamilyEvents.build(self, MaritalStatus, LivingStatus))
#
#   家庭状态：children_count / child_ages[]（每年+1）/ children_relationship(0-10) / grandchildren_count
#   id 规则：4000 + 策划案编号（F01 → 4001）
#
#   与策划案的偏差（策划案未定义对应字段）：
#     · F31「子女已婚」→ 以「长子/长女年龄 ≥ 25」近似
#     · F40「子女已婚」→ 以「长子女年龄 ≥ 28」近似
# ============================================================

static func _ev(h: Node, id: int, amin: int, amax: int, cond: Callable, w: Callable,
		text: String, effects: Dictionary, cat: String,
		require_flags: Array = [], set_flags: Array = [], clear_flags: Array = [],
		set_status: Dictionary = {}, once: bool = false) -> Dictionary:
	return h._make_event(id, amin, amax, cond, w, text, effects, false,
		require_flags, set_flags, clear_flags, 0, {}, set_status, once, cat)

static func build(h: Node, MS: Dictionary, LS: Dictionary) -> Array[Dictionary]:
	var ev: Array[Dictionary] = []

	# ==================== 阶段 1：生育（26-35 岁） ====================
	# F01 你迎来了第一个孩子
	ev.append(_ev(h, 4001, 22, 50,
		func(): return h.marital_status == MS.MARRIED and h.children_count == 0,
		func(): return 115,
		"你迎来了自己的第一个孩子，整夜守在襁褓边舍不得睡。",
		{"emotion": 3, "money": -1}, "family", [], [], [],
		{"children_add": 1, "living": LS.WITH_CHILDREN}, true))

	# F02 你迎来了第二个孩子
	ev.append(_ev(h, 4002, 26, 42,
		func(): return h.marital_status == MS.MARRIED and h.children_count == 1 \
			and h._get_stat("money") >= 5,
		func(): return 22,
		"家里又添了一个孩子，日子更热闹，也更拮据了。",
		{"emotion": 2, "money": -1}, "family", [], [], [],
		{"children_add": 1}, true))

	# F03 你们选择丁克
	ev.append(_ev(h, 4003, 26, 40,
		func(): return h.marital_status == MS.MARRIED and h.children_count == 0 \
			and h._get_stat("emotion") >= 6,
		func(): return 18,
		"你们商量后决定不要孩子，把生活过成自己想要的样子。",
		{"emotion": 1}, "family", [], ["dink"], [], {}, true))

	# F04 生育困难
	ev.append(_ev(h, 4004, 26, 42,
		func(): return h.marital_status == MS.MARRIED and h.children_count == 0 \
			and h._get_stat("strong") <= 3,
		func(): return 20,
		"你们努力了很久，却始终没能怀上孩子，心里空落落的。",
		{"emotion": -2}, "family", [], [], [], {}, true))

	# F05 意外怀孕
	ev.append(_ev(h, 4005, 26, 42,
		func(): return h.marital_status == MS.MARRIED and h.children_count >= 1 \
			and h._get_stat("luck") <= 4,
		func(): return 15,
		"一次意外让你们又多了个孩子，手忙脚乱地重新适应。",
		{"emotion": -1, "money": -1}, "family", [], [], [], {"children_add": 1}))

	# ==================== 阶段 2：子女婴幼儿期（0-6 岁） ====================
	ev.append(_ev(h, 4010, 22, 60,
		func(): return h.children_count >= 1 and h.youngest_child_age() >= 0 \
			and h.youngest_child_age() <= 6,
		func(): return 22,
		"孩子半夜哭闹不止，你抱着他在屋里来回走了一整夜。",
		{"strong": -1, "emotion": -1}, "family"))

	ev.append(_ev(h, 4011, 22, 60,
		func(): return h.children_count >= 1 and h.youngest_child_age() >= 0 \
			and h.youngest_child_age() <= 6,
		func(): return 20,
		"孩子第一次含糊地叫出「爸爸妈妈」，你激动得眼眶发热。",
		{"emotion": 2}, "family", [], [], [], {}, true))

	ev.append(_ev(h, 4012, 22, 60,
		func(): return h.children_count >= 1 and h.youngest_child_age() >= 0 \
			and h.youngest_child_age() <= 6,
		func(): return 20,
		"孩子半夜发起高烧，你抱着他冲进急诊室。",
		{"emotion": -1, "money": -1}, "family"))

	ev.append(_ev(h, 4013, 22, 60,
		func(): return h.children_count >= 1 and h.youngest_child_age() >= 0 \
			and h.youngest_child_age() <= 6 and h._get_stat("money") >= 4,
		func(): return 18,
		"你带孩子去了游乐园，他笑得停不下来。",
		{"emotion": 1, "money": -1}, "family"))

	# ==================== 阶段 3：子女教育期（7-18 岁） ====================
	ev.append(_ev(h, 4020, 26, 70,
		func(): return h.children_count >= 1 and h.oldest_child_age() >= 7 \
			and h._get_stat("cleverness") >= 6,
		func(): return 20,
		"孩子成绩优异，家长会上你被老师点名表扬。",
		{"emotion": 2}, "family", [], [], [], {"children_rel_add": 1}))

	ev.append(_ev(h, 4021, 30, 70,
		func(): return h.children_count >= 1 and h.oldest_child_age() >= 13,
		func(): return 20,
		"孩子进入叛逆期，一句话不对就摔门而去。",
		{"emotion": -2}, "family", [], [], [], {"children_rel_add": -1}))

	ev.append(_ev(h, 4022, 28, 70,
		func(): return h.children_count >= 1 and h.oldest_child_age() >= 7 \
			and h._get_stat("money") >= 5,
		func(): return 18,
		"你给孩子报了补习班，希望他别输在起跑线上。",
		{"money": -1, "cleverness": 1}, "family", [], [], [], {"children_rel_add": 1}))

	ev.append(_ev(h, 4023, 32, 70,
		func(): return h.children_count >= 1 and h.oldest_child_age() >= 15,
		func(): return 16,
		"你发现孩子早恋了，一时间不知该怎么开口。",
		{"emotion": -1}, "family"))

	ev.append(_ev(h, 4024, 36, 70,
		func(): return h.children_count >= 1 and h.oldest_child_age() >= 18 \
			and h._get_stat("cleverness") >= 6,
		func(): return 20,
		"孩子考上了理想的大学，你摆了几桌酒席。",
		{"emotion": 3}, "family", [], [], [], {"children_rel_add": 1}, true))

	ev.append(_ev(h, 4025, 36, 70,
		func(): return h.children_count >= 1 and h.oldest_child_age() >= 18 \
			and h._get_stat("cleverness") <= 4,
		func(): return 18,
		"孩子高考失利，把自己关在房间里不吃不喝。",
		{"emotion": -2}, "family", [], [], [], {"children_rel_add": -1}, true))

	# ==================== 阶段 4：子女成年期（19-35 岁） ====================
	ev.append(_ev(h, 4030, 40, 90,
		func(): return h.children_count >= 1 and h.oldest_child_age() >= 22,
		func(): return 18,
		"孩子找到了不错的工作，第一次请你吃饭。",
		{"emotion": 2}, "family", [], [], [], {"children_rel_add": 1}, true))

	ev.append(_ev(h, 4031, 45, 95,
		func(): return h.children_count >= 1 and h.oldest_child_age() >= 25,
		func(): return 18,
		"孩子成家了，你在婚礼上偷偷抹了把眼泪。",
		{"emotion": 2, "money": -2}, "family", [], [], [], {}, true))

	ev.append(_ev(h, 4032, 45, 95,
		func(): return h.children_count >= 1 and h.oldest_child_age() >= 25 \
			and h.children_relationship <= 4,
		func(): return 16,
		"孩子一直待在家里不肯出去工作，你既生气又无奈。",
		{"emotion": -2, "money": -1}, "family", [], [], [], {"children_rel_add": -1}))

	ev.append(_ev(h, 4033, 45, 95,
		func(): return h.children_count >= 1 and h.oldest_child_age() >= 25,
		func(): return 16,
		"孩子去了很远的城市工作，一年也回不来几次。",
		{"emotion": -1}, "family"))

	# ==================== 阶段 5：孙辈与晚年（51+ 岁） ====================
	# F40 孙辈出生（策划案的「子女已婚」以长子女年龄近似）
	ev.append(_ev(h, 4040, 48, 110,
		func(): return h.children_count >= 1 and h.grandchildren_count == 0 \
			and h.oldest_child_age() >= 28,
		func(): return 20,
		"孙辈出生了，你升级成了祖辈，抱着孩子的手都在抖。",
		{"emotion": 3}, "family", [], [], [], {"grandchildren_add": 1}, true))

	ev.append(_ev(h, 4041, 50, 110,
		func(): return h.grandchildren_count >= 1,
		func(): return 18,
		"你帮忙带孙辈，累得腰酸背痛，却乐在其中。",
		{"strong": -1, "emotion": 1}, "family"))

	ev.append(_ev(h, 4042, 50, 110,
		func(): return h.grandchildren_count >= 1 and h.children_relationship >= 6,
		func(): return 18,
		"孙辈跟你格外亲近，一见你就往怀里扑。",
		{"emotion": 2}, "family"))

	ev.append(_ev(h, 4043, 50, 110,
		func(): return h.children_count >= 1 and h.children_relationship <= 4,
		func(): return 18,
		"子女很少回家，电话也总是匆匆几句。",
		{"emotion": -2}, "family"))

	ev.append(_ev(h, 4044, 50, 110,
		func(): return h.children_count >= 1 and h.children_relationship >= 7,
		func(): return 18,
		"子女时常回来看你，还带来你爱吃的东西。",
		{"emotion": 2}, "family"))

	ev.append(_ev(h, 4045, 60, 120,
		func(): return h.children_count >= 1 and GlobalData.age >= 60,
		func(): return 15,
		"你请律师立下了遗嘱，把一切都安排妥当。",
		{"emotion": 1}, "family", [], [], [], {}, true))

	return ev
