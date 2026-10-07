extends RefCounted

# ============================================================
# 跨线互动事件（天赋 × 恋爱 × 家庭 × 职业 × 健康）
#
#   注入：event_pool.append_array(InteractionEvents.build(self, MaritalStatus, LivingStatus, JobStatus))
#   作用：让各条线互相影响，避免"恋爱线事件扎堆、其它线孤立"。
#   全部为凡人线事件（不带 cult 标记），带 once 的居多以控制事件密度。
#   id 段：60xx
# ============================================================

static func _ev(h: Node, id: int, amin: int, amax: int, cond: Callable, w: Callable,
		text: String, effects: Dictionary, cat: String,
		require_flags: Array = [], set_flags: Array = [], clear_flags: Array = [],
		set_status: Dictionary = {}, once: bool = false) -> Dictionary:
	return h._make_event(id, amin, amax, cond, w, text, effects, false,
		require_flags, set_flags, clear_flags, 0, {}, set_status, once, cat)

static func _choice(h: Node, id: int, amin: int, amax: int, cond: Callable, w: Callable,
		text: String, choices: Array, once: bool = false) -> Dictionary:
	return h._make_choice_event(id, amin, amax, cond, w, text, choices, once)

static func build(h: Node, MS: Dictionary, LS: Dictionary, JS: Dictionary) -> Array[Dictionary]:
	var ev: Array[Dictionary] = []

	# 天赋 T23 青梅竹马 × 恋爱线：从小一起长大的人，最终成了家人
	ev.append(_ev(h, 6001, 22, 40,
		func(): return h._has_talent(37) and h.marital_status == MS.DATING,
		func(): return 40,
		"那个从小和你一起长大的人，终于成了你的家人。",
		{"emotion": 3}, "marry", [], ["in_love"], [],
		{"marital": MS.MARRIED, "living": LS.WITH_PARTNER}, true))

	# 恋爱 × 家庭：婆媳/翁婿矛盾
	ev.append(_ev(h, 6002, 25, 60,
		func(): return h.marital_status == MS.MARRIED and h.parents_alive \
			and h._get_stat("emotion") <= 6,
		func(): return 22,
		"你的父母和伴侣为了一点小事闹得不可开交，你夹在中间两头受气。",
		{"emotion": -1}, "family", [], [], [], {}, true))

	# 恋爱 × 家境：彩礼压力
	ev.append(_ev(h, 6003, 22, 35,
		func(): return h.marital_status == MS.DATING and h._get_stat("money") <= 4,
		func(): return 20,
		"谈婚论嫁时，双方家里为了彩礼的事争执不下。",
		{"emotion": -1}, "dating", [], [], [], {}, true))

	# 恋爱 × 学业：早恋影响成绩
	ev.append(_ev(h, 6004, 16, 18,
		func(): return h.marital_status == MS.DATING,
		func(): return 24,
		"你满脑子都是对方的样子，课本上的字一个也看不进去。",
		{"cleverness": -1, "emotion": 1}, "dating"))

	# 家庭 × 职业：为孩子的教育放弃升职
	ev.append(_choice(h, 6005, 26, 50,
		func(): return h.children_count >= 1 and h.job_status == JS.EMPLOYED,
		func(): return 20,
		"公司要派你去外地任职，可孩子正处在关键时期。",
		[
			{"text": "放弃机会，留在孩子身边",
			 "result": "你错过了升职，却没错过孩子的成长。",
			 "effects": {"money": -1, "emotion": 2}, "set_status": {"children_rel_add": 1}},
			{"text": "接受调任",
			 "result": "你的事业更上一层楼，孩子却和你生分了。",
			 "effects": {"money": 2, "emotion": -1}, "set_status": {"children_rel_add": -1}},
		], true))

	# 健康 × 家庭：生病时子女照料
	ev.append(_ev(h, 6006, 40, 100,
		func(): return h.health_status != 0 and h.children_count >= 1,
		func(): return 22,
		"你住院那段日子，子女轮流守在床边，你心里踏实了不少。",
		{"emotion": 2}, "family", [], [], [], {"children_rel_add": 1}))

	# 压力 × 婚姻：把工作的火气带回家
	ev.append(_ev(h, 6007, 25, 60,
		func(): return h.marital_status == MS.MARRIED and h.stress >= 3,
		func(): return 20,
		"你把工作上的火气带回了家，伴侣沉默着收拾了碗筷。",
		{"emotion": -1}, "marriage", [], [], [], {}, false))

	# 天赋 T20 白手起家 × 职业：创业第一桶金
	ev.append(_ev(h, 6008, 20, 45,
		func(): return h._has_talent(34) and h.job_status == JS.SELF_EMPLOYED,
		func(): return 35,
		"你靠着一股狠劲，把第一笔生意做成了。",
		{"money": 2, "emotion": 1}, "startup", [], [], [], {}, true))

	# 天赋 T42 工作狂 × 健康：加班的代价
	ev.append(_ev(h, 6009, 25, 55,
		func(): return h._has_talent(42) and h.job_status == JS.EMPLOYED,
		func(): return 22,
		"你又连续熬了几个通宵，胃疼得直不起腰。",
		{"strong": -1, "money": 1}, "work"))

	# 三代 × 家庭：孩子继承了你的天赋
	ev.append(_ev(h, 6010, 30, 70,
		func(): return h.children_count >= 1 and h._get_stat("cleverness") >= 7,
		func(): return 20,
		"老师说这孩子聪明得不像话，你在家长会上笑得合不拢嘴。",
		{"emotion": 2}, "family", [], [], [], {"children_rel_add": 1}, true))

	# 职业 × 压力：过劳链的持续加压（让压力能真正爬到 8+，触发压力猝死事件）
	ev.append(h._make_event(6011, 25, 60,
		func(): return h._has_flag("overwork") and h.job_status != 0,
		func(): return 20,
		"又是一个通宵。你在办公室的玻璃上，看见了自己发青的脸。",
		{"emotion": -1}, false, [], [], [], 2, {}, {}, false, "work"))

	# 职业 × 健康：过劳引发的身体警报（累积压力后的显性代价）
	ev.append(h._make_event(6012, 30, 60,
		func(): return h._has_flag("overwork") and h.stress >= 5,
		func(): return 16,
		"你的手在签字时开始发抖，体检单上多了三个箭头。",
		{"strong": -1, "emotion": -1}, false, [], [], [], 1, {}, {}, false, "work"))

	# ==================== 扩展互动（天赋 × 恋爱 × 家庭 × 职业 × 修仙） ====================
	# 恋爱 × 健康：有人惦记着，身体也好了起来
	ev.append(_ev(h, 6013, 19, 45,
		func(): return h.marital_status == MS.DATING and h._get_stat("strong") <= 4,
		func(): return 18,
		"对方每天逼你早睡、拉着你散步，你的气色肉眼可见地好了起来。",
		{"strong": 1, "emotion": 1}, "dating"))

	# 天赋 T13 运动细胞 × 家庭：带着孩子一起锻炼
	ev.append(_ev(h, 6014, 28, 55,
		func(): return h._has_talent(17) and h.children_count >= 1,
		func(): return 20,
		"你带着孩子晨跑，一路上他叽叽喳喳说个不停。",
		{"strong": 1, "emotion": 1}, "family", [], [], [], {"children_rel_add": 1}))

	# 天赋 T14 家财万贯 × 家庭：亲戚上门借钱
	ev.append(_ev(h, 6015, 25, 60,
		func(): return h._has_talent(14) and h._get_stat("money") >= 8,
		func(): return 20,
		"远房亲戚接二连三上门借钱，借出去的钱再也没回来。",
		{"money": -1, "emotion": -1}, "family"))

	# 天赋 T19 抗压之王 × 压力：自己把压力消化掉
	ev.append(h._make_event(6016, 26, 60,
		func(): return h._has_talent(33) and h.stress >= 3,
		func(): return 22,
		"你在阳台上站了很久，把那股烦躁一点点咽了回去。",
		{"emotion": 1}, false, [], [], [], -2, {}, {}, false, "work"))

	# 职业 × 学业：高学历带来的晋升
	ev.append(_ev(h, 6017, 26, 50,
		func(): return h._get_stat("cleverness") >= 7 and h.job_status == JS.EMPLOYED,
		func(): return 18,
		"你凭一纸文凭和一身本事，在评职称时一路过关。",
		{"money": 1}, "work", [], [], [], {}, true))

	# 运气 × 意外：命大
	ev.append(_ev(h, 6018, 20, 70,
		func(): return h._get_stat("luck") >= 8,
		func(): return 16,
		"车祸现场一片狼藉，你只是擦破了皮，司机说你命真大。",
		{"strong": -1, "emotion": 1}, "life", [], [], [], {}, true))

	# 修仙 × 家庭：给子孙留下一点东西
	ev.append(_cev_if_cult(h, 6019, 16, 9999,
		func(): return h.cultivating and h.children_count >= 1,
		func(): return 20,
		"你把一缕灵气封进玉牌，托人送回了凡间的家。",
		{"emotion": 1}, "cult_family", {"mind_add": 1}))

	# 修仙 × 恋爱：道侣同行
	ev.append(_cev_if_cult(h, 6020, 16, 9999,
		func(): return h.cultivating and h.marital_status == 2,
		func(): return 20,
		"道侣为你护法七日七夜，你出关时，她/他还坐在洞口。",
		{"emotion": 2}, "cult_family", {"mind_add": 1, "face_add": 1}))

	# 天赋 × 修仙：传说血脉觉醒
	ev.append(_cev_if_cult(h, 6021, 16, 9999,
		func(): return h.cultivating and h._has_talent(51),
		func(): return 20,
		"你掌心的血脉忽然亮起，冥冥中似有天意加持。",
		{}, "cult_family", {"dao_add": 2}))

	# 凡尘职业 × 修仙：旧日人脉换来资源
	ev.append(_cev_if_cult(h, 6022, 16, 9999,
		func(): return h.cultivating and h.job_status == JS.EMPLOYED,
		func(): return 18,
		"当年的老同事托人送来一箱灵石，说是还你当年的人情。",
		{"emotion": 1}, "cult_family", {"res_add": 6}, true))

	return ev

# 带 cult 标记的互动事件（只在修仙期间触发）
static func _cev_if_cult(h: Node, id: int, amin: int, amax: int, cond: Callable, w: Callable,
		text: String, effects: Dictionary, cat: String, set_status: Dictionary,
		once: bool = false) -> Dictionary:
	var e: Dictionary = h._make_event(id, amin, amax, cond, w, text, effects, false,
		[], [], [], 0, {}, set_status, once, cat)
	e["cult"] = true
	return e
