extends SceneTree

# 验证 ⑨ 晋级物品表 + ⑩ 天劫劫重与成功率
const BI := preload("res://Data/BreakthroughItems.gd")

# 把物品名数组转成「已拥有」字典（与 main.gd 的 cult_items 同结构）
func _own(items: Array) -> Dictionary:
	var d: Dictionary = {}
	for it in items:
		d[str(it)] = true
	return d

# 自动选择时优先避开「主动结束修仙线」的选项（散功归隐等），否则测不出真实推进
func _non_ending_index(scene: Node) -> int:
	var arr: Array = scene.pending_choices
	for i in range(arr.size()):
		if not bool((arr[i] as Dictionary).get("ending", false)):
			return i
	return -1

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame

func _initialize() -> void:
	for n in ["PopupManager", "GlobalData", "RandomProbability", "TalentPool", "Progress"]:
		if not root.has_node(NodePath(n)):
			var s: Script = load("res://Auto_load/%s.gd" % n)
			var inst: Node = s.new()
			inst.name = n
			root.add_child(inst)
	await _frames(1)

	# ---------- ⑨ 物品表完整性 ----------
	var path_names := ["仙修", "魔修", "魂修"]
	var ok := true
	print("[⑨] 三线 × 9 阶段物品表（普通/核心/钥匙）：")
	for p in range(3):
		var line: Array = []
		for r in range(9):
			var st: Dictionary = BI.stage(p, r)
			var c: int = (st.common as Array).size()
			var o: int = (st.core as Array).size()
			var k: int = (st.key as Array).size()
			if c + o + k == 0 or int(st.base) != r + 1:
				ok = false
			line.append("%d+%d+%d" % [c, o, k])
		print("    %s：%s" % [path_names[p], "｜".join(line)])
	print("[⑨] 每阶段基础劫级 = 境界+1 且物品非空 = %s" % str(ok))

	# ---------- ⑩ 劫重计算 ----------
	print("[⑩] 劫重计算（练气→筑基，仙修）：")
	var st0: Dictionary = BI.stage(0, 0)
	var full := _own(st0.common + st0.core + st0.key)
	var t1: Dictionary = BI.tribulation(full, 0, 0, true)
	print("    物品齐全 → 劫重 %d【%s·%s】" % [t1.weight, t1.level, t1.type_name])
	var half := _own([st0.common[0], st0.common[1], st0.common[2], st0.core[0]])   # 3普通 + 小册子
	var t2: Dictionary = BI.tribulation(half, 0, 0, false)
	print("    3/5普通 + 小册子、无玉佩 → 劫重 %d【%s】，缺普通%d/核心%d/钥匙%d"
		% [t2.weight, t2.level, t2.miss_common, t2.miss_core, t2.miss_key])
	var t3: Dictionary = BI.tribulation({}, 0, 0, false)
	print("    什么都没有 → 劫重 %d【%s】绝劫=%s" % [t3.weight, t3.level, str(t3.absolute)])
	var t4: Dictionary = BI.tribulation({}, 0, 8, false)
	print("    渡劫→飞升、缺三钥 → 劫重 %d【%s】%s" % [t4.weight, t4.level, t4.type_name])
	var st_mo: Dictionary = BI.stage(1, 4)
	var t5: Dictionary = BI.tribulation(_own(st_mo.common + st_mo.core + st_mo.key), 1, 4, true)
	print("    魔修 化神→炼虚 齐全 → 劫重 %d【%s】%s" % [t5.weight, t5.level, t5.type_name])
	var t6: Dictionary = BI.tribulation({}, 2, 8, false)
	print("    魂修 缺魂劫九器 → 劫重 %d【%s】%s" % [t6.weight, t6.level, t6.type_name])
	var st_hun: Dictionary = BI.stage(2, 7)
	var t7: Dictionary = BI.tribulation(_own(st_hun.common + st_hun.core), 2, 7, true)
	print("    魂修 大乘魂→魂劫 齐全 → 劫重 %d【%s】%s" % [t7.weight, t7.level, t7.type_name])

	# ---------- ⑩ 实机：强制修仙，看天劫流程与成功率 ----------
	var gd: Node = root.get_node("GlobalData")
	var tp: Node = root.get_node("TalentPool")
	var enters := 0
	var ascends := 0
	var weight_samples: Array = []
	var realm_hist: Dictionary = {}
	var items_sum := 0
	var ending_hist: Dictionary = {}
	var trib_log_by_realm: Dictionary = {}
	var trials := 60
	for i in range(trials):
		gd.reset()
		gd.choose_talents.assign(tp.draw_auto(3))
		var scene: Node = load("res://Main/main.tscn").instantiate()
		root.add_child(scene)
		await _frames(1)
		(scene.get_node("Timer") as Timer).stop()
		scene._set_flag("mysterious_jade")
		scene._set_flag("mysterious_book")
		gd.age = 99
		scene._update_values()
		var steps := 0
		while not scene.is_dead and steps < 2000:
			steps += 1
			if scene.is_waiting_for_choice:
				scene.auto_pick_choice(_non_ending_index(scene))
			else:
				scene._emit_next_line()
		if bool(scene.cultivating) or str(scene.cultivation_ended) != "":
			enters += 1
			if str(scene.cultivation_ended).contains("飞升") or str(scene.cultivation_ended) in ["魔祖", "轮回之主"]:
				ascends += 1
			weight_samples.append(scene.realm)
			realm_hist[scene.realm] = int(realm_hist.get(scene.realm, 0)) + 1
			items_sum += scene.cult_items.size()
			var ek := str(scene.cultivation_ended)
			ending_hist[ek] = int(ending_hist.get(ek, 0)) + 1
		for e in scene.tribulation_log:
			var rr := int((e as Dictionary).realm)
			if not trib_log_by_realm.has(rr):
				trib_log_by_realm[rr] = []
			trib_log_by_realm[rr].append(e)
		root.remove_child(scene)
		scene.queue_free()
		await process_frame
	print("[⑩] 强制修仙 %d 局：进入 %d 局｜飞升 %d 局（%.0f%%）"
		% [trials, enters, ascends, 100.0 * float(ascends) / float(maxi(1, enters))])
	print("     终境分布 = %s" % str(realm_hist))
	print("     结局分布 = %s" % str(ending_hist))
	print("     平均持有晋级物品 = %.1f 件" % (float(items_sum) / float(maxi(1, enters))))

	# 渡劫日志汇总：各境界的劫重与成功率
	print("     渡劫尝试汇总:")
	for r in range(9):
		var rec: Array = trib_log_by_realm.get(r, [])
		if rec.is_empty():
			continue
		var w := 0.0
		var c := 0.0
		var m := 0.0
		for x in rec:
			w += float((x as Dictionary).weight)
			c += float((x as Dictionary).chance)
			m += float((x as Dictionary).miss)
		print("       境界%d：%d 次｜平均劫重 %.1f｜平均成功率 %.0f%%｜平均缺 %.1f 件"
			% [r, rec.size(), w / rec.size(), c / rec.size(), m / rec.size()])
	quit()
