extends SceneTree

# 元系统验证：成就 / 事件图鉴 / 锁定天赋 / 结算与图鉴界面
# 用法：godot --headless --path <工程> --script res://Tools/verify_meta.gd

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
	var gd: Node = root.get_node("GlobalData")
	var pr: Node = root.get_node("Progress")
	var tp: Node = root.get_node("TalentPool")

	# ---- 1) 跑一局到死，检查成就/图鉴是否落盘 ----
	var runs_before := int(pr.total_runs)
	var seen_before := int(pr.seen_events.size())
	var scene: Node = load("res://Main/main.tscn").instantiate()
	root.add_child(scene)
	await _frames(1)
	(scene.get_node("Timer") as Timer).stop()
	var steps := 0
	while not scene.is_dead and steps < 400:
		steps += 1
		if scene.is_waiting_for_choice:
			scene.auto_pick_choice()
		else:
			scene._emit_next_line()
	print("[1] 一局跑完：死亡=%s 享年=%d 本局事件=%d" % [str(scene.is_dead), int(gd.age), scene.history.size()])
	print("    成就新增：%s" % str(gd.new_achievements.map(func(a): return str(a.name))))
	print("    总局数 %d→%d｜图鉴 %d→%d｜事件总数 %d"
		% [runs_before, int(pr.total_runs), seen_before, int(pr.seen_events.size()), int(pr.event_total)])

	# ---- 2) 结算界面 ----
	var settle: Node = load("res://Settlement/settlement.tscn").instantiate()
	root.add_child(settle)
	await _frames(6)
	var grid: Node = settle.get_node("VBoxContainer/MarginContainer/GridContainer")
	print("[2] 结算表格格子数 = %d（应为 18 = 6 标题 + 6 数值 + 6 评语）" % grid.get_child_count())
	var cmt: Label = grid.find_child("EmotionComment", true, false)
	print("    心情评语 = %s（不应是占位符「阿巴阿巴」）" % (cmt.text if cmt != null else "缺失"))

	# ---- 3) 锁定天赋：设为玉佩(55)，检查抽卡必出 ----
	pr.locked_talent = 55
	var found := 0
	var rounds := 20
	for i in range(rounds):
		if tp.draw_candidates(6).has(55):
			found += 1
	print("[3] 锁定 T30 神秘玉佩后，%d/%d 次抽卡均包含它" % [found, rounds])
	pr.locked_talent = 0

	# ---- 4) 成就 / 图鉴界面 ----
	var rec: Node = load("res://Record/record.tscn").instantiate()
	rec.mode = 0
	root.add_child(rec)
	await _frames(2)
	var list: Node = rec.get_node("Scroll/List")
	print("[4] 成就界面：标题=%s｜条目=%d" % [(rec.get_node("Title") as Label).text, list.get_child_count()])
	rec.mode = 1
	rec._refresh()
	await _frames(2)
	print("    图鉴界面：标题=%s｜条目=%d" % [(rec.get_node("Title") as Label).text, list.get_child_count()])

	# ---- 5) 存档文件 ----
	print("[5] 存档文件存在 = %s（%s）" % [str(FileAccess.file_exists("user://dsh_progress.cfg")), "user://dsh_progress.cfg"])
	quit()
