extends SceneTree

# 验证种子相关 UI：输入框场景 + 锁定界面的「复制种子」
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

	# ---------- Choose_seed 场景 ----------
	var cs: Node = load("res://Choose_seed/choose_seed.tscn").instantiate()
	root.add_child(cs)
	await _frames(2)
	print("[UI] 种子界面节点：返回=%s｜输入框=%s｜开始=%s"
		% [str(cs.exit_button != null), str(cs.line_edit != null), str(cs.start_button != null)])
	cs.line_edit.text = "12345"
	gd.seed_input = 0
	gd.run_seed = 0
	cs._on_start()
	await _frames(2)
	print("[UI] 输入 12345 → seed_input=%d｜run_seed=%d（应为 0，交给天赋界面初始化）"
		% [int(gd.seed_input), int(gd.run_seed)])
	# 非数字口令也要能用
	cs.line_edit.text = "baobao"
	cs._on_start()
	await _frames(2)
	print("[UI] 输入口令「baobao」→ seed_input=%d（非 0 即可用）" % int(gd.seed_input))
	root.remove_child(cs)
	cs.queue_free()
	await _frames(2)

	# ---------- 锁定界面的种子按钮 ----------
	gd.run_seed = 987654321
	gd.choose_talents.assign([55, 11, 31])
	var lock: Node = load("res://Lock_talent/lock_talent.tscn").instantiate()
	root.add_child(lock)
	await _frames(2)
	print("[UI] 锁定界面种子按钮文字 = %s" % (lock.copy_seed as Button).text)
	lock._on_copy_seed()
	await _frames(2)
	print("[UI] 点击后按钮文字 = %s" % (lock.copy_seed as Button).text)
	print("[UI] 系统剪贴板 = %s" % DisplayServer.clipboard_get())
	root.remove_child(lock)
	lock.queue_free()
	quit()
