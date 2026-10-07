extends RefCounted

# ============================================================
# 恋爱线 L01-L64（策划案第二节）
#
#   注入方式（Main/main.gd 的 _init_event_pool）：
#     event_pool.append_array(RomanceEvents.build(self, MaritalStatus, LivingStatus))
#
#   状态机：SINGLE → CRUSH(暗恋) → DATING(交往) → ENGAGED(订婚) → MARRIED(已婚) → WIDOWED(丧偶)
#          MARRIED → DIVORCED(离婚) → 可再婚
#   因果标记：crush / quarrel / suspicion / met_parents / rejected / betrayed / in_love
#   id 规则：3000 + 策划案编号（L03 → 3003；L02 复用既有事件 2002「匿名情书」）
# ============================================================

# 普通事件包装
static func _ev(h: Node, id: int, amin: int, amax: int, cond: Callable, w: Callable,
		text: String, effects: Dictionary, cat: String,
		require_flags: Array = [], set_flags: Array = [], clear_flags: Array = [],
		set_status: Dictionary = {}, once: bool = false) -> Dictionary:
	return h._make_event(id, amin, amax, cond, w, text, effects, false,
		require_flags, set_flags, clear_flags, 0, {}, set_status, once, cat)

# 随机分支事件包装（表白成功率 / 求婚成功率）
static func _branch(h: Node, id: int, amin: int, amax: int, cond: Callable, w: Callable,
		prompt: String, chance: float, ok_side: Dictionary, ng_side: Dictionary,
		cat: String, once: bool = false) -> Dictionary:
	return h._make_branch_event(id, amin, amax, cond, w, prompt, chance, ok_side, ng_side, once, cat)

static func build(h: Node, MS: Dictionary, LS: Dictionary) -> Array[Dictionary]:
	var ev: Array[Dictionary] = []

	# ==================== 阶段 1：暗恋（13-18 岁） ====================
	# L01 你偷偷喜欢上了同桌
	ev.append(_ev(h, 3001, 13, 18,
		func(): return h.marital_status == MS.SINGLE and h._get_stat("emotion") >= 4,
		func(): return 90,
		"你偷偷喜欢上了同桌，每次对视都会心跳加速。",
		{"emotion": 1}, "crush", [], ["crush"], [], {"marital": MS.CRUSH}))

	# L03 你鼓起勇气表白（50% 成功 → DATING）
	ev.append(_branch(h, 3003, 13, 25,
		func(): return h.marital_status == MS.CRUSH and h._get_stat("emotion") >= 5,
		func(): return 90,
		"你决定不再藏着心事，鼓起勇气向对方表白。",
		0.5,
		{"text": "对方红着脸答应了，你们开始正式交往。",
		 "effects": {"emotion": 2}, "set_status": {"marital": MS.DATING},
		 "set_flags": ["in_love"], "clear_flags": ["crush"]},
		{"text": "对方婉言拒绝了你，只当是句玩笑。",
		 "effects": {"emotion": -2}, "clear_flags": ["crush"],
		 "set_status": {"marital": MS.SINGLE}},
		"crush"))

	# L04 你被拒绝了（情绪低落时暗恋自然消散）
	ev.append(_ev(h, 3004, 13, 25,
		func(): return h.marital_status == MS.CRUSH and h._get_stat("emotion") <= 4,
		func(): return 30,
		"你终于明白，这份心意不会有回应，只能悄悄收起来。",
		{"emotion": -2}, "crush", [], [], ["crush"], {"marital": MS.SINGLE}))

	# ==================== 阶段 2：交往（19-25 岁） ====================
	# 补充事件（非策划案原表）：成年单身入口
	#   策划案的成年入口只有「颜值≥7」的 L/72，实测恋爱线触发率仅 39%，
	#   与验收标准（≥70%）差距过大，故补一条低门槛的成年社交入口。
	ev.append(_branch(h, 3099, 18, 48,
		func(): return h.marital_status == MS.SINGLE and h._get_stat("emotion") >= 2,
		func(): return 100,
		"朋友说要给你介绍个对象，问你有没有兴趣见一面。",
		0.6,
		{"text": "你们聊得出乎意料地投缘，开始交往。",
		 "effects": {"emotion": 2}, "set_status": {"marital": MS.DATING},
		 "set_flags": ["in_love"]},
		{"text": "见面后彼此都觉得不太合适，就没有下文了。",
		 "effects": {"emotion": -1}},
		"dating"))

	ev.append(_ev(h, 3010, 19, 30,
		func(): return h.marital_status == MS.DATING,
		func(): return 25,
		"你们一起去看电影，散场后沿着路灯走了很久。",
		{"emotion": 2}, "dating"))

	ev.append(_ev(h, 3011, 19, 30,
		func(): return h.marital_status == MS.DATING and h._get_stat("emotion") <= 5,
		func(): return 25,
		"你们因为一件小事吵架，谁也不肯先低头。",
		{"emotion": -1}, "dating", [], ["quarrel"]))

	ev.append(_ev(h, 3012, 19, 30,
		func(): return h.marital_status == MS.DATING and h._get_stat("emotion") >= 6,
		func(): return 30,
		"冷战几天后，你们还是和好如初了。",
		{"emotion": 2}, "dating", ["quarrel"], [], ["quarrel"]))

	ev.append(_ev(h, 3013, 19, 30,
		func(): return h.marital_status == MS.DATING and h._get_stat("luck") <= 4,
		func(): return 22,
		"你发现对方和一个异性走得很近，心里很不是滋味。",
		{"emotion": -2}, "dating", [], ["suspicion"]))

	ev.append(_ev(h, 3014, 19, 30,
		func(): return h._get_stat("emotion") >= 5,
		func(): return 30,
		"你选择相信对方，把疑虑压在了心底。",
		{"emotion": 1}, "dating", ["suspicion"], [], ["suspicion"]))

	ev.append(_ev(h, 3015, 19, 30,
		func(): return h._get_stat("emotion") <= 3,
		func(): return 28,
		"猜疑最终压垮了这段感情，你选择了分手。",
		{"emotion": -1}, "dating", ["suspicion"], [], ["suspicion", "in_love"],
		{"marital": MS.SINGLE}))

	# ==================== 阶段 3：热恋（19-30 岁） ====================
	ev.append(_ev(h, 3020, 19, 30,
		func(): return h.marital_status == MS.DATING and h._get_stat("money") >= 5,
		func(): return 22,
		"你们一起去旅行，在海边看了日出。",
		{"emotion": 2, "money": -1}, "dating"))

	ev.append(_ev(h, 3021, 19, 30,
		func(): return h.marital_status == MS.DATING and h._get_stat("emotion") >= 6,
		func(): return 35,
		"对方带你回家见了家长，饭桌上气氛融洽。",
		{"emotion": 1}, "dating", [], ["met_parents"]))

	# L22 你决定求婚（90% 成功 → ENGAGED）
	#   策划案要求家境>=6，实测 100 局该事件 0 次触发、订婚链整条死掉，
	#   故放宽到家境>=3，让 L30-L33 订婚/婚礼事件重新可达。
	ev.append(_branch(h, 3022, 22, 35,
		func(): return h.marital_status == MS.DATING and h._has_flag("met_parents") \
			and h._get_stat("money") >= 3,
		func(): return 45,
		"你觉得时机成熟了，准备向对方求婚。",
		0.9,
		{"text": "你单膝跪地，对方含着泪点了头——你们订婚了。",
		 "effects": {"emotion": 2}, "set_status": {"marital": MS.ENGAGED}},
		{"text": "对方说还没准备好，婉拒了你的求婚。",
		 "effects": {"emotion": -3}, "set_flags": ["rejected"]},
		"engage", true))

	# L23 求婚被拒（家境不足，谈婚论嫁遥遥无期）
	ev.append(_ev(h, 3023, 22, 35,
		func(): return h.marital_status == MS.DATING and h._has_flag("met_parents") \
			and h._get_stat("money") <= 4,
		func(): return 20,
		"你提起结婚的事，对方沉默了很久，只说家里还不同意。",
		{"emotion": -3}, "engage", [], ["rejected"]))

	# ==================== 阶段 4：订婚与结婚（26-35 岁） ====================
	ev.append(_ev(h, 3030, 22, 35,
		func(): return h.marital_status == MS.ENGAGED,
		func(): return 30,
		"你们开始筹备婚礼，从请柬到酒店，忙得不可开交。",
		{"money": -1, "emotion": 2}, "engage"))

	ev.append(_ev(h, 3031, 22, 40,
		func(): return h.marital_status == MS.ENGAGED,
		func(): return 70,
		"你们在亲友的祝福中步入婚姻的殿堂。",
		{"emotion": 3}, "marry", [], ["in_love"], ["met_parents", "rejected"],
		{"marital": MS.MARRIED, "living": LS.WITH_PARTNER}, true))

	ev.append(_ev(h, 3032, 22, 35,
		func(): return h.marital_status == MS.ENGAGED and h._get_stat("luck") <= 3,
		func(): return 18,
		"婚礼当天出了意外，场面一度十分混乱。",
		{"emotion": -2, "money": -1}, "engage"))

	ev.append(_ev(h, 3033, 22, 35,
		func(): return h.marital_status == MS.ENGAGED and h._get_stat("money") <= 3,
		func(): return 40,
		"你们选择了裸婚，没有排场，只有一句郑重的承诺。",
		{"emotion": 1}, "engage", [], ["in_love"], [],
		{"marital": MS.MARRIED, "living": LS.WITH_PARTNER}, true))

	# 补充事件（非策划案原表）：领证结婚
	#   策划案的结婚必经「见家长(money>=6) → 求婚」，
	#   实测已婚率仅 32%、家庭线仅 26%，无法达到验收标准（恋爱 ≥70%、家庭 ≥60%）。
	#   故补一条不受家境门槛限制的登记结婚入口。
	ev.append(_ev(h, 3034, 24, 45,
		func(): return h.marital_status == MS.DATING and h._get_stat("emotion") >= 5,
		func(): return 175,
		"你们挑了个好日子去领了证，从此有了一个家。",
		{"emotion": 2}, "marry", [], ["in_love"], [],
		{"marital": MS.MARRIED, "living": LS.WITH_PARTNER}, true))

	# ==================== 阶段 5：婚姻生活（26-50 岁） ====================
	ev.append(_ev(h, 3040, 26, 50,
		func(): return h.marital_status == MS.MARRIED and h._get_stat("money") >= 5,
		func(): return 20,
		"你们一起装修新房，为墙纸的颜色争论了半天。",
		{"money": -1, "emotion": 1}, "marriage"))

	ev.append(_ev(h, 3041, 26, 50,
		func(): return h.marital_status == MS.MARRIED and h._get_stat("emotion") <= 5,
		func(): return 22,
		"你们为了谁做家务又吵了一架。",
		{"emotion": -1}, "marriage"))

	ev.append(_ev(h, 3042, 26, 60,
		func(): return h.marital_status == MS.MARRIED and h._get_stat("emotion") >= 6,
		func(): return 22,
		"你们一起度过了结婚纪念日，还翻出了当年的照片。",
		{"emotion": 2}, "marriage"))

	ev.append(_ev(h, 3043, 26, 50,
		func(): return h.marital_status == MS.MARRIED and h._get_stat("luck") <= 4 \
			and h._get_stat("emotion") <= 5,
		func(): return 18,
		"你发现对方出轨了，整个世界仿佛塌了下来。",
		{"emotion": -4}, "marriage", [], ["betrayed"]))

	ev.append(_ev(h, 3044, 26, 60,
		func(): return h._has_flag("betrayed") and h._get_stat("emotion") >= 6,
		func(): return 30,
		"你最终选择了原谅，为了这个家，也为了自己。",
		{"emotion": -1}, "marriage", ["betrayed"], [], ["betrayed"]))

	ev.append(_ev(h, 3045, 26, 60,
		func(): return h._has_flag("betrayed") and h._get_stat("emotion") <= 3,
		func(): return 30,
		"你选择了离婚，从此一别两宽。",
		{"emotion": -2}, "marriage", ["betrayed"], [], ["betrayed", "in_love"],
		{"marital": MS.DIVORCED}))

	ev.append(_ev(h, 3046, 26, 60,
		func(): return h.marital_status == MS.MARRIED and h.marriage_years() >= 7,
		func(): return 20,
		"日子过成了白开水，你们之间的话越来越少。",
		{"emotion": -1}, "marriage"))

	ev.append(_ev(h, 3047, 26, 60,
		func(): return h.marital_status == MS.MARRIED and h._get_stat("emotion") >= 7,
		func(): return 20,
		"你们重新找回了恋爱的感觉，像年轻时那样牵手散步。",
		{"emotion": 2}, "marriage"))

	# ==================== 阶段 6：中年婚姻（36-50 岁） ====================
	ev.append(_ev(h, 3050, 36, 60,
		func(): return h.marital_status == MS.MARRIED and h.parents_alive,
		func(): return 18,
		"双方父母年事已高，你们轮流照顾，累得直不起腰。",
		{"emotion": -1, "strong": -1}, "marriage"))

	ev.append(_ev(h, 3051, 36, 60,
		func(): return h.marital_status == MS.MARRIED and h.children_count >= 1,
		func(): return 18,
		"你们一起为孩子的学业和前途操心。",
		{"emotion": -1}, "marriage"))

	ev.append(_ev(h, 3052, 36, 80,
		func(): return h.marital_status == MS.MARRIED and h.marriage_years() >= 25,
		func(): return 25,
		"你们一起庆祝银婚，儿孙都来道贺。",
		{"emotion": 2}, "marriage"))

	ev.append(_ev(h, 3053, 36, 70,
		func(): return h.marital_status == MS.MARRIED and h._get_stat("emotion") <= 4,
		func(): return 18,
		"你们开始分房睡，同一屋檐下像两个房客。",
		{"emotion": -1}, "marriage"))

	# ==================== 阶段 7：空巢与丧偶（51-80 岁） ====================
	ev.append(_ev(h, 3060, 51, 80,
		func(): return h.marital_status == MS.MARRIED and h.children_count >= 1,
		func(): return 18,
		"子女离家后，家里一下子安静下来，你们重归二人世界。",
		{"emotion": 1}, "marriage"))

	ev.append(_ev(h, 3061, 51, 90,
		func(): return h.marital_status == MS.MARRIED and h._get_stat("money") >= 6,
		func(): return 18,
		"你们一起去了年轻时约定过的地方。",
		{"emotion": 2, "money": -1}, "marriage"))

	ev.append(_ev(h, 3062, 51, 90,
		func(): return h.marital_status == MS.MARRIED and h._get_stat("strong") <= 4,
		func(): return 18,
		"老伴病倒了，你日夜守在床边。",
		{"strong": -1, "emotion": -1}, "marriage"))

	# L63 老伴去世（缺失的 WIDOWED 入口）
	ev.append(_ev(h, 3063, 65, 110,
		func(): return h.marital_status == MS.MARRIED and GlobalData.age >= 65,
		func(): return 20,
		"老伴走了。你在灵前坐了一整夜，一句话也没说。",
		{"emotion": -3}, "marriage", [], [], ["in_love"],
		{"marital": MS.WIDOWED}, true))

	# L64 你慢慢走出悲伤
	ev.append(_ev(h, 3064, 66, 120,
		func(): return h.marital_status == MS.WIDOWED and h._get_stat("emotion") >= 5,
		func(): return 20,
		"你开始整理老伴的遗物，也慢慢学会了独自生活。",
		{"emotion": 1}, "marriage"))

	return ev
