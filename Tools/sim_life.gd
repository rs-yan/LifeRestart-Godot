extends SceneTree

# ============================================================
# 人生模拟器 —— 批量验收工具（headless）
#   用法：
#     godot --headless --path <工程目录> --script res://Tools/sim_life.gd -- 100 [随机种子] [jade]
#     参数 1：局数（默认 100）
#     参数 2：随机种子（可选，便于复现）
#     参数 jade：强制每局携带 T30 神秘玉佩，用于单独验证修仙触发链
#   统计：寿命分布 / 天赋抽取 / 事件覆盖率 / 恋爱线 / 家庭线 / 修仙线触发率
#
#   注意：--script 模式下脚本编译早于自动加载注册，因此这里一律用
#         root.get_node("GlobalData") 取单例，不使用全局标识符。
# ============================================================

const MAX_STEPS := 3200
const RUNS_DEFAULT := 100
# 与 main.gd 的 MaritalStatus 对齐（CRUSH/ENGAGED 追加在枚举末尾，不影响原有序号）
const MARITAL_DATING := 1
const MARITAL_MARRIED := 2
const MARITAL_DIVORCED := 3
const MARITAL_WIDOWED := 4
const MARITAL_CRUSH := 5
const MARITAL_ENGAGED := 6

var gd: Node
var tp: Node
var force_jade := false
var force_book := false
var alloc_mode := "random"

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var runs := RUNS_DEFAULT
	if args.size() > 0:
		runs = maxi(1, int(args[0]))
	if args.size() > 1:
		seed(int(args[1]))
	force_jade = args.has("jade")
	force_book = args.has("book")
	alloc_mode = "build" if args.has("build") else "random"

	for n in ["PopupManager", "GlobalData", "RandomProbability", "TalentPool"]:
		if not root.has_node(NodePath(n)):
			var s: Script = load("res://Auto_load/%s.gd" % n)
			var inst: Node = s.new()
			inst.name = n
			root.add_child(inst)
	await _frames(1)
	gd = root.get_node("GlobalData")
	tp = root.get_node("TalentPool")

	# 天赋表自检：任何 id 查不到名字都说明编号对不上
	var bad_talents: Array[int] = []
	for t in tp.TALENTS:
		if tp.name_of(int(t.id)) == "未知天赋":
			bad_talents.append(int(t.id))
	print("天赋表自检：共 %d 个，未登记 %s" % [tp.TALENTS.size(), str(bad_talents)])

	var sv := SubViewport.new()
	sv.size = Vector2i(1920, 1080)
	root.add_child(sv)

	var probe: Node = load("res://Main/main.tscn").instantiate()
	sv.add_child(probe)
	await _frames(2)
	var all_ids: Array[int] = []
	var cult_ids: Array[int] = []
	var cult_set: Dictionary = {}
	var id_text: Dictionary = {}
	for e in probe.event_pool:
		all_ids.append(int(e.id))
		id_text[int(e.id)] = str(e.text)
		if bool(e.get("cult", false)):
			cult_ids.append(int(e.id))
			cult_set[int(e.id)] = true
	sv.remove_child(probe)
	probe.queue_free()
	await process_frame

	print("事件总数：%d，开始跑 %d 局…\n" % [all_ids.size(), runs])

	# id 撞车自检：triggered_once / history 都按 id 索引，重复 id 会互相干扰
	var id_count: Dictionary = {}
	for id in all_ids:
		id_count[id] = int(id_count.get(id, 0)) + 1
	var dups: Array = []
	for id in id_count:
		if int(id_count[id]) > 1:
			dups.append(int(id))
	dups.sort()
	print("重复事件 id：%s\n" % ("无" if dups.is_empty() else str(dups)))

	var ages: Array[int] = []
	var talent_count: Dictionary = {}
	var rarity_count: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0}
	var fired_count: Dictionary = {}
	var death_cause: Dictionary = {}
	var dating_n := 0
	var crush_n := 0
	var engaged_n := 0
	var married_n := 0
	var divorced_n := 0
	var widowed_n := 0
	var children_n := 0
	var children_total := 0
	var grandchild_n := 0
	var rel_sum := 0
	var jade_n := 0
	var cult_n := 0
	var realm_sum := 0
	var endings: Dictionary = {}
	var path_counts: Dictionary = {0: 0, 1: 0, 2: 0}
	var mortal_age_sum := 0
	var mortal_n := 0
	var book_n := 0
	var loop_n := 0
	var stress_sum := 0
	var stress3_n := 0
	var stress8_n := 0
	var not_died := 0
	var talent_card_total := 0

	for g in range(runs):
		var r: Dictionary = await _run_once(sv)
		ages.append(int(r.age))
		talent_card_total += (r.talents as Array).size()
		for id in r.talents:
			talent_count[id] = int(talent_count.get(id, 0)) + 1
			var lv := int(tp.level_of(int(id)))
			rarity_count[lv] = int(rarity_count.get(lv, 0)) + 1
		for id in r.history:
			fired_count[id] = int(fired_count.get(id, 0)) + 1
		var d_id: int = int(r.death_id)
		if d_id >= 0:
			death_cause[d_id] = int(death_cause.get(d_id, 0)) + 1
		var seen: Dictionary = r.seen
		if seen[MARITAL_CRUSH]:
			crush_n += 1
		if seen[MARITAL_DATING] or seen[MARITAL_ENGAGED] or seen[MARITAL_MARRIED] or seen[MARITAL_WIDOWED]:
			dating_n += 1
		if seen[MARITAL_ENGAGED]:
			engaged_n += 1
		if seen[MARITAL_MARRIED]:
			married_n += 1
		if seen[MARITAL_DIVORCED]:
			divorced_n += 1
		if seen[MARITAL_WIDOWED]:
			widowed_n += 1
		if int(r.children) >= 1:
			children_n += 1
		children_total += int(r.children)
		if int(r.grandchildren) >= 1:
			grandchild_n += 1
		rel_sum += int(r.child_rel)
		if r.flags.get("mysterious_jade", false):
			jade_n += 1
		if bool(r.cult):
			cult_n += 1
			realm_sum += int(r.realm_max)
			path_counts[int(r.path)] = int(path_counts.get(int(r.path), 0)) + 1
			var endk: String = str(r.ending)
			if endk != "":
				endings[endk] = int(endings.get(endk, 0)) + 1
		else:
			mortal_age_sum += int(r.age)
			mortal_n += 1
		if r.flags.get("mysterious_book", false):
			book_n += 1
		if r.flags.get("time_loop_used", false):
			loop_n += 1
		stress_sum += int(r.stress)
		if int(r.stress) >= 3:
			stress3_n += 1
		if int(r.stress) >= 8:
			stress8_n += 1
		if not r.died:
			not_died += 1

	ages.sort()
	var avg_age := 0.0
	for a in ages:
		avg_age += a
	avg_age /= float(ages.size())

	print("========== 寿命 ==========")
	print("平均 %.1f 岁｜中位 %d 岁｜最短 %d｜最长 %d｜未死亡(超步数) %d"
		% [avg_age, ages[ages.size() / 2], ages[0], ages[ages.size() - 1], not_died])

	print("\n========== 天赋抽取（每局 3 张，共 %d 张）==========" % talent_card_total)
	print("稀有度分布：普通 %d（%.1f%%）｜稀有 %d（%.1f%%）｜史诗 %d（%.1f%%）｜传说 %d（%.1f%%）"
		% [rarity_count[1], 100.0 * rarity_count[1] / talent_card_total,
		   rarity_count[2], 100.0 * rarity_count[2] / talent_card_total,
		   rarity_count[3], 100.0 * rarity_count[3] / talent_card_total,
		   rarity_count[4], 100.0 * rarity_count[4] / talent_card_total])
	var tkeys := talent_count.keys()
	tkeys.sort_custom(func(a, b): return int(talent_count[a]) > int(talent_count[b]))
	print("出现次数：")
	for id in tkeys:
		print("  %-6s %3d 次" % [tp.name_of(int(id)), int(talent_count[id])])

	print("\n========== 事件覆盖率 ==========")
	print("触发过 %d / %d 个事件（%.1f%%）"
		% [fired_count.size(), all_ids.size(), 100.0 * fired_count.size() / all_ids.size()])
	var fired_mortal := 0
	var fired_cult := 0
	for id in all_ids:
		if not fired_count.has(id):
			continue
		if cult_set.has(id):
			fired_cult += 1
		else:
			fired_mortal += 1
	var mortal_all := all_ids.size() - cult_ids.size()
	print("  凡人线：%d / %d = %.1f%%" % [fired_mortal, mortal_all, 100.0 * fired_mortal / maxi(1, mortal_all)])
	print("  修仙线：%d / %d = %.1f%%（仅在修仙局触发）"
		% [fired_cult, cult_ids.size(), 100.0 * fired_cult / maxi(1, cult_ids.size())])
	var fkeys := fired_count.keys()
	fkeys.sort_custom(func(a, b): return int(fired_count[a]) > int(fired_count[b]))
	print("Top10：")
	for i in range(mini(10, fkeys.size())):
		var id: int = int(fkeys[i])
		print("  #%-5d %4d 次  %s" % [id, int(fired_count[id]), str(id_text.get(id, "?"))])

	print("\n========== 各条线触发率 ==========")
	print("恋爱线（交往或已婚）: %d/%d = %.1f%%" % [dating_n, runs, 100.0 * dating_n / runs])
	print("暗恋过            : %d/%d = %.1f%%" % [crush_n, runs, 100.0 * crush_n / runs])
	print("订婚过            : %d/%d = %.1f%%" % [engaged_n, runs, 100.0 * engaged_n / runs])
	print("已婚              : %d/%d = %.1f%%" % [married_n, runs, 100.0 * married_n / runs])
	print("离婚 / 丧偶        : %d / %d" % [divorced_n, widowed_n])
	print("家庭线（有子女）    : %d/%d = %.1f%%（平均 %.2f 个）"
		% [children_n, runs, 100.0 * children_n / runs, float(children_total) / runs])
	print("有孙辈            : %d/%d = %.1f%%" % [grandchild_n, runs, 100.0 * grandchild_n / runs])
	print("平均子女关系        : %.2f / 10" % [float(rel_sum) / runs])
	print("修仙线·玉佩        : %d/%d = %.2f%%" % [jade_n, runs, 100.0 * jade_n / runs])
	print("修仙线·小册子      : %d/%d = %.2f%%" % [book_n, runs, 100.0 * book_n / runs])
	print("时间循环触发        : %d/%d = %.2f%%" % [loop_n, runs, 100.0 * loop_n / runs])

	print("\n========== 修仙线 ==========")
	print("进入修仙线        : %d/%d = %.2f%%" % [cult_n, runs, 100.0 * cult_n / runs])
	if cult_n > 0:
		print("平均最高境界      : %.2f / 9（0=练气 … 9=飞升）" % [float(realm_sum) / cult_n])
	print("三线分布          : 仙修 %d ｜ 魔修 %d ｜ 魂修 %d"
		% [int(path_counts[0]), int(path_counts[1]), int(path_counts[2])])
	print("结局分布          : %s" % str(endings))
	if cult_n > 0:
		print("飞升率（修仙局内）: %d/%d = %.1f%%" % [int(endings.get("飞升", 0)), cult_n,
			100.0 * int(endings.get("飞升", 0)) / cult_n])
	if mortal_n > 0:
		print("未入修仙线平均寿命: %.1f 岁（%d 局）" % [float(mortal_age_sum) / mortal_n, mortal_n])

	print("\n========== 压力 ==========")
	print("平均终局压力 %.2f / 上限 10（抗压之王 13）" % [float(stress_sum) / runs])
	print("峰值压力≥3 的局：%d/%d = %.1f%%｜≥8 的局：%d/%d = %.1f%%"
		% [stress3_n, runs, 100.0 * stress3_n / runs, stress8_n, runs, 100.0 * stress8_n / runs])

	print("\n========== 未触发事件（覆盖率缺口）==========")
	var miss: Array = []
	for id in all_ids:
		if not fired_count.has(id):
			miss.append(id)
	miss.sort()
	for id in miss:
		var mtxt: String = str(id_text.get(id, "?"))
		if mtxt.length() > 24:
			mtxt = mtxt.substr(0, 24) + "…"
		print("  #%-5d %s" % [int(id), mtxt])
	print("未触发 %d / %d 个" % [miss.size(), all_ids.size()])

	print("\n========== 因果链关键事件 ==========")
	var chain_ids: Array[int] = [
		3001, 3003, 3004, 3010, 3012, 3015, 3021, 3022, 3031, 3033, 3034,
		3043, 3045, 3046, 3052, 3063, 3064, 3099,
		4001, 4002, 4003, 4004, 4005, 4011, 4024, 4030, 4040, 4044, 4045,
	]
	for id in chain_ids:
		print("  #%-5d %4d 次  %s" % [id, int(fired_count.get(id, 0)), str(id_text.get(id, "?"))])

	print("\n========== 死因 Top10 ==========")
	var dkeys := death_cause.keys()
	dkeys.sort_custom(func(a, b): return int(death_cause[a]) > int(death_cause[b]))
	for i in range(mini(10, dkeys.size())):
		var id: int = int(dkeys[i])
		var txt: String = str(id_text.get(id, "?"))
		if txt.length() > 20:
			txt = txt.substr(0, 20) + "…"
		print("  #%-5d %3d 次  %s" % [id, int(death_cause[id]), txt])

	quit()

# 模拟「理性玩家」的选项策略：优先规避会直接终结游戏的选项（ending=true）
func _choose_index(choices: Array) -> int:
	if choices.is_empty():
		return 0
	var safe: Array[int] = []
	for i in range(choices.size()):
		if not bool((choices[i] as Dictionary).get("ending", false)):
			safe.append(i)
	if safe.is_empty():
		return randi() % choices.size()
	return safe[randi() % safe.size()]

func _random_values() -> Array[int]:
	if alloc_mode == "build":
		return _build_values()
	# 复刻 skill.gd：20 点随机平摊到 5 项，每项 0-8，快乐固定 5
	var vals: Array[int] = [0, 0, 0, 0, 0, 5]
	var budget := 20
	var guard := 0
	while budget > 0 and guard < 5000:
		guard += 1
		var i := randi() % 5
		if vals[i] >= 8:
			continue
		vals[i] += 1
		budget -= 1
	return vals

# 「会玩的玩家」加点策略：20 点集中投在 2-3 项上（每项上限 8）
# 用于对照随机平摊，判断验收指标是设计问题还是测量口径问题
func _build_values() -> Array[int]:
	var order := ["strong", "beauty", "cleverness", "money", "luck"]
	var builds: Array = [
		{"beauty": 8, "emotion": 0, "cleverness": 4, "strong": 2, "money": 6},   # 恋爱流
		{"money": 8, "cleverness": 8, "strong": 4},                              # 事业流
		{"strong": 8, "luck": 8, "cleverness": 4},                               # 长寿流
		{"cleverness": 8, "money": 6, "beauty": 6},                              # 学霸流
		{"strong": 6, "beauty": 6, "money": 8},                                  # 均衡流
	]
	var b: Dictionary = builds[randi() % builds.size()]
	var vals: Array[int] = [0, 0, 0, 0, 0, 5]
	for i in range(5):
		vals[i] = int(b.get(order[i], 0))
	# 补齐未指定的点数（保持总量 20）
	var used := 0
	for i in range(5):
		used += vals[i]
	var i2 := 0
	while used < 20 and i2 < 200:
		i2 += 1
		var k := randi() % 5
		if vals[k] >= 8:
			continue
		vals[k] += 1
		used += 1
	return vals

func _run_once(sv: SubViewport) -> Dictionary:
	gd.reset()
	gd.choose_talents.assign(tp.draw_auto(3))
	if force_jade:
		# 用于单独验证修仙触发链：强行让每局都带 T30 神秘玉佩
		var ids: Array[int] = [55]
		for id in gd.choose_talents:
			if int(id) != 55 and ids.size() < 3:
				ids.append(int(id))
		gd.choose_talents.assign(ids)
	gd.values = _random_values()

	var scene: Node = load("res://Main/main.tscn").instantiate()
	sv.add_child(scene)
	await _frames(1)
	(scene.get_node("Timer") as Timer).stop()
	if force_book:
		# 直接注入修仙线钥匙，用于单独验证修仙系统
		scene._set_flag("mysterious_jade")
		scene._set_flag("mysterious_book")

	var married_max := 0
	var ever := {MARITAL_CRUSH: false, MARITAL_DATING: false, MARITAL_ENGAGED: false,
		MARITAL_MARRIED: false, MARITAL_DIVORCED: false, MARITAL_WIDOWED: false}
	var ever_cult := false
	var realm_max := 0
	var path_seen := 0
	var max_children := 0
	var max_stress := 0
	var steps := 0
	while not scene.is_dead and steps < MAX_STEPS:
		steps += 1
		if scene.is_waiting_for_choice:
			scene.auto_pick_choice(_choose_index(scene.pending_choices))
		else:
			scene._emit_next_line()
		var ms := int(scene.marital_status)
		if ever.has(ms):
			ever[ms] = true
		if bool(scene.cultivating):
			ever_cult = true
			realm_max = maxi(realm_max, int(scene.realm))
			path_seen = int(scene.cult_path)
		married_max = maxi(married_max, ms if ms <= MARITAL_WIDOWED else 0)
		max_children = maxi(max_children, int(scene.children_count))
		max_stress = maxi(max_stress, int(scene.stress))
		if steps % 20 == 0:
			await process_frame

	var hist: Array = scene.history.duplicate()
	var result := {
		"age": int(gd.age),
		"talents": (gd.choose_talents as Array).duplicate(),
		"history": hist,
		"died": bool(scene.is_dead),
		"steps": steps,
		"marital": int(scene.marital_status),
		"seen": ever,
		"cult": ever_cult,
		"realm_max": realm_max,
		"path": path_seen,
		"ending": str(scene.cultivation_ended),
		"children": max_children,
		"grandchildren": int(scene.grandchildren_count),
		"child_rel": int(scene.children_relationship),
		"stress": max_stress,
		"flags": (scene.flags as Dictionary).duplicate(),
		"death_id": int(hist[hist.size() - 1]) if hist.size() > 0 else -1,
	}
	sv.remove_child(scene)
	scene.queue_free()
	await process_frame
	return result
