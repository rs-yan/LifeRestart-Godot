extends SceneTree

# 验证：②选项自适应 ①结算居中 ③lock_talent 空数据布局 ④重置后刷新 ⑦资源下限
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

	root.size = Vector2i(1920, 1080)

	# ---------- ② 选项自适应 ----------
	var main_scene: Node = load("res://Main/main.tscn").instantiate()
	root.add_child(main_scene)
	await _frames(2)
	(main_scene.get_node("Timer") as Timer).stop()

	main_scene.add_choose_line("结婚")
	main_scene.add_choose_line("分手")
	main_scene.add_choose_line("再想想")
	await _frames(3)
	var b0: Button = main_scene.choose_box.get_child(0).find_child("Button", true, false)
	print("[②] 3 个短选项 → 列数=%d｜字号=%d" % [main_scene.choose_box.columns, b0.get_theme_font_size("font_size")])

	main_scene._clear_choices()
	main_scene.add_choose_line("买下小册子（家境-3）")
	main_scene.add_choose_line("拒绝")
	await _frames(3)
	var b1: Button = main_scene.choose_box.get_child(0).find_child("Button", true, false)
	print("[②] 2 个中等选项 → 列数=%d｜字号=%d" % [main_scene.choose_box.columns, b1.get_theme_font_size("font_size")])

	main_scene._clear_choices()
	main_scene.add_choose_line("堕入魔道（耗15资源）")
	main_scene.add_choose_line("守住本心，我偏要与这天道争上一争")
	main_scene.add_choose_line("既不修魔，也不修魂，只做凡人")
	await _frames(3)
	var b2: Button = main_scene.choose_box.get_child(0).find_child("Button", true, false)
	print("[②] 3 个长选项 → 列数=%d｜字号=%d" % [main_scene.choose_box.columns, b2.get_theme_font_size("font_size")])

	# ---------- ⑦ 资源下限 ----------
	main_scene.cult_zi = 3
	main_scene.cult_zi -= 10
	print("[⑦] 资源 3 扣 10 → %d（应为 0，不能为负）" % main_scene.cult_zi)
	main_scene.cult_zi = 5
	print("[⑦] 赋值 5 → %d" % main_scene.cult_zi)
	root.remove_child(main_scene)
	main_scene.queue_free()
	await _frames(2)

	# ---------- ③ lock_talent 空数据 ----------
	gd.choose_talents.clear()
	var lock_empty: Node = load("res://Lock_talent/lock_talent.tscn").instantiate()
	root.add_child(lock_empty)
	await _frames(2)
	var vis := 0
	for c in lock_empty.cards:
		if c.visible:
			vis += 1
	var box: Control = lock_empty.get_node("VBoxContainer")
	print("[③] 空数据：可见卡片 %d/3｜盒子尺寸=%s｜Body=%s"
		% [vis, str(box.size), (lock_empty.body as Label).text])
	root.remove_child(lock_empty)
	lock_empty.queue_free()
	await _frames(2)

	# 有数据时
	gd.choose_talents.assign([55, 1, 41])
	var lock_full: Node = load("res://Lock_talent/lock_talent.tscn").instantiate()
	root.add_child(lock_full)
	await _frames(2)
	print("[③] 有数据：卡片1=%s" % (lock_full.cards[0].get_node("VBoxContainer/TitleLabel") as Label).text)
	root.remove_child(lock_full)
	lock_full.queue_free()
	await _frames(2)

	# ---------- ① 结算居中 ----------
	gd.age = 70
	var vals: Array[int] = [5, 5, 5, 5, 5, 5]
	gd.values = vals
	var settle: Node = load("res://Settlement/settlement.tscn").instantiate()
	root.add_child(settle)
	await _frames(4)
	var rb: Control = settle.get_node("VBoxContainer")
	var vp := root.get_viewport().get_visible_rect().size
	print("[①] 视口=%s｜盒子尺寸=%s｜位置=%s｜居中偏差=(%.0f, %.0f)"
		% [str(vp), str(rb.size), str(rb.position),
		   absf(rb.position.x - (vp.x - rb.size.x) * 0.5),
		   absf(rb.position.y - (vp.y - rb.size.y) * 0.5)])
	root.remove_child(settle)
	settle.queue_free()
	await _frames(2)

	# ---------- ④ 重置后刷新 ----------
	var menu: Node = load("res://Main_menu/main_menu.tscn").instantiate()
	root.add_child(menu)
	await _frames(1)
	pr.unlocked = {"first_run": true, "age60": true}
	pr.seen_events = {1: true, 2: true, 3: true}
	pr.event_total = 386
	var rec: Node = load("res://Record/record.tscn").instantiate()
	rec.mode = 0
	root.add_child(rec)
	await _frames(1)
	rec._on_reset()      # 第一次：进入确认
	rec._on_reset()      # 第二次：真正清空
	await _frames(1)
	rec._on_back()       # 返回主菜单
	await _frames(2)
	print("[④] 重置后主菜单：成就按钮=%s｜图鉴按钮=%s"
		% [(menu.ach_button as Button).text, (menu.evt_button as Button).text])
	quit()
