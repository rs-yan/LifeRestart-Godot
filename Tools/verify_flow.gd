extends SceneTree

# 场景流转验证：结算 →（锁定天赋）→ 锁定界面 →（返回）→ 主菜单
#   重点验证我改过的 GlobalData 重置时机：进锁定时不能重置，返回时才重置
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

	# 造一局结束后的数据
	gd.age = 88
	var vals: Array[int] = [7, 6, 8, 5, 4, 6]
	gd.values = vals
	gd.choose_talents.assign([55, 11, 31])
	gd.ending_summary = "修仙线·仙修｜终境：金丹期｜结局：寿尽"

	# 1) 进入结算界面（作为当前场景）
	var settle: Node = load("res://Settlement/settlement.tscn").instantiate()
	root.add_child(settle)
	current_scene = settle
	await _frames(6)
	var rb: Control = settle.get_node("VBoxContainer")
	var vp := root.get_viewport().get_visible_rect().size
	print("[流转] 结算居中偏差 = (%.0f, %.0f)" % [
		absf(rb.position.x - (vp.x - rb.size.x) * 0.5),
		absf(rb.position.y - (vp.y - rb.size.y) * 0.5)])
	print("[流转] 结算按钮文字 = %s" % (settle.get_node("VBoxContainer/MarginContainer2/Back") as Button).text)

	# 2) 按「锁定天赋」→ 应切到锁定界面，且本局天赋必须还在
	settle._on_lock_pressed()
	await _frames(6)
	var cur := current_scene
	print("[流转] 当前场景 = %s（应为 LockTalent）" % (cur.name if cur != null else "null"))
	if cur != null and cur.has_method("_collect_cards"):
		print("[流转] 锁定界面读到的天赋数 = %d（必须 >0，否则就是重置时机错了）" % cur.cards.size())
		var t1: Label = cur.cards[0].get_node("VBoxContainer/TitleLabel")
		print("[流转] 卡片1 = %s" % t1.text)
		# 3) 点第一张卡 → 锁定
		(cur.cards[0].get_node("Button") as Button).button_pressed = true
		await _frames(2)
		print("[流转] 锁定后 Progress.locked_talent = %d" % int(root.get_node("Progress").locked_talent))
		# 4) 返回 → 应回主菜单并清空本局数据
		cur._on_back_pressed()
		await _frames(8)
		var cur2 := current_scene
		print("[流转] 返回后当前场景 = %s（应为 MainMenu）" % (cur2.name if cur2 != null else "null"))
		print("[流转] 返回后本局天赋数 = %d（应为 0）｜年龄 = %d（应为 0）"
			% [gd.choose_talents.size(), int(gd.age)])
		if cur2 != null and cur2.has_method("refresh_labels"):
			print("[流转] 主菜单按钮 = %s / %s" % [
				(cur2.ach_button as Button).text, (cur2.evt_button as Button).text])
	quit()
