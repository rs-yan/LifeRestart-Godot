extends SceneTree

# 临时验证：结算评语 + 锁定天赋界面
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

	root.size = Vector2i(1920, 1080)
	# 造一局结束后的数据
	gd.age = 87
	var vals: Array[int] = [8, 6, 9, 4, 3, 7]
	gd.values = vals
	gd.choose_talents.assign([55, 1, 41])
	gd.ending_summary = "修仙线·仙修｜终境：金丹期｜结局：寿尽"
	gd.new_achievements = [
		{"id": "age60", "name": "花甲之年", "desc": "活到 60 岁", "tier": 1},
		{"id": "cultivation", "name": "踏入仙途", "desc": "从凡人进入修仙线", "tier": 3},
	]
	gd.run_history = [1, 2, 3, 4, 5]
	pr.event_total = 386
	pr.seen_events = {1: true, 2: true, 3: true}

	# ---- 结算界面 ----
	var settle: Node = load("res://Settlement/settlement.tscn").instantiate()
	root.add_child(settle)
	await _frames(4)
	var grid: Node = settle.get_node("VBoxContainer/MarginContainer/GridContainer")
	var out: Array = []
	for k in ["Age", "Strong", "Beauty", "Cleverness", "Money", "Emotion"]:
		var c: Label = grid.find_child("%sComment" % k, true, false)
		out.append("%s=%s" % [k, c.text if c != null else "缺失"])
	print("[结算] 评语：%s" % "｜".join(out))
	print("[结算] 格子供 %d｜按钮文字=%s" % [grid.get_child_count(),
		(settle.get_node("VBoxContainer/MarginContainer2/Back") as Button).text])
	await create_timer(4.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("D:/yrs/deepseek/_settle.png")
	print("[结算] 截图 D:/yrs/deepseek/_settle.png")
	root.remove_child(settle)
	settle.queue_free()
	await _frames(2)

	# ---- 锁定天赋界面 ----
	pr.locked_talent = 0
	var lock: Node = load("res://Lock_talent/lock_talent.tscn").instantiate()
	root.add_child(lock)
	await _frames(3)
	print("[锁定] 收集到卡片 %d 张" % lock.cards.size())
	for i in range(lock.cards.size()):
		var card: Node = lock.cards[i]
		var tl: Label = card.get_node("VBoxContainer/TitleLabel")
		var bl: Label = card.get_node("VBoxContainer/BodyLabel")
		print("   卡%d visible=%s｜%s｜%s" % [i + 1, str(card.visible), tl.text, bl.text])
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("D:/yrs/deepseek/_lock.png")
	print("[锁定] 截图 D:/yrs/deepseek/_lock.png")

	# 点第一张卡（玉佩）
	var first: Button = lock.cards[0].get_node("Button")
	first.button_pressed = true
	await _frames(2)
	print("[锁定] 点击后 Progress.locked_talent = %d（应为 55）" % pr.locked_talent)
	print("[锁定] Body 文本 = %s" % (lock.body as Label).text)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("D:/yrs/deepseek/_lock_picked.png")

	# 下局抽卡是否必出
	var hit := 0
	for i in range(20):
		if tp.draw_candidates(6).has(55):
			hit += 1
	print("[锁定] 抽卡 20 次包含玉佩 %d 次" % hit)
	pr.locked_talent = 0
	pr.save()
	quit()
