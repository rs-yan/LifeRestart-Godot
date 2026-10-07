extends SceneTree

# 回归测试：玉佩 + 小册子 + 活到 120 岁 → 必须进入修仙线（而不是被自然死亡规则直接结算）

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame

func _initialize() -> void:
	for n in ["PopupManager", "GlobalData", "RandomProbability", "TalentPool"]:
		if not root.has_node(NodePath(n)):
			var s: Script = load("res://Auto_load/%s.gd" % n)
			var inst: Node = s.new()
			inst.name = n
			root.add_child(inst)
	await _frames(1)
	var gd: Node = root.get_node("GlobalData")

	var trials := 20
	var entered := 0
	var failed := 0
	for t in range(trials):
		gd.reset()
		gd.choose_talents.assign([55, 1, 2])
		var vals: Array[int] = [5, 5, 5, 5, 5, 5]
		gd.values = vals
		var scene: Node = load("res://Main/main.tscn").instantiate()
		root.add_child(scene)
		await _frames(1)
		(scene.get_node("Timer") as Timer).stop()
		scene._set_flag("mysterious_jade")
		scene._set_flag("mysterious_book")
		gd.age = 119
		scene._refresh_panel_titles()
		scene._update_values()

		var steps := 0
		while not scene.is_dead and not bool(scene.cultivating) and steps < 80:
			steps += 1
			if scene.is_waiting_for_choice:
				scene.auto_pick_choice()
			else:
				scene._emit_next_line()

		if bool(scene.cultivating):
			entered += 1
		else:
			failed += 1
			print("  第%d次未进入修仙：is_dead=%s age=%d" % [t + 1, str(scene.is_dead), int(gd.age)])
		root.remove_child(scene)
		scene.queue_free()
		await process_frame

	print("玉佩+小册子、119 岁起步：进入修仙 %d/%d（失败 %d）" % [entered, trials, failed])
	quit()
