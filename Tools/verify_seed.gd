extends SceneTree

# 验证：种子可复现性 + 修仙购买保护
func _frames(n: int) -> void:
	for i in range(n):
		await process_frame

# 用给定种子走一遍「天赋抽取 → 开局 → 前 N 年事件」，返回可比较的结果
func _run_with_seed(s: int, steps: int) -> Dictionary:
	var gd: Node = root.get_node("GlobalData")
	var tp: Node = root.get_node("TalentPool")
	gd.reset()
	gd.seed_input = s
	gd.run_seed = 0

	# 复刻天赋界面的播种逻辑（talent.gd 的 _ready 前两段）
	if gd.run_seed == 0:
		gd.run_seed = gd.seed_input if gd.seed_input != 0 else randi()
		if gd.run_seed == 0:
			gd.run_seed = 1
	seed(int(gd.run_seed))
	var cands: Array = tp.draw_candidates(6)
	gd.choose_talents.assign([cands[0], cands[1], cands[2]])

	var scene: Node = load("res://Main/main.tscn").instantiate()
	root.add_child(scene)
	await _frames(1)
	(scene.get_node("Timer") as Timer).stop()
	var n := 0
	while not scene.is_dead and n < steps:
		n += 1
		if scene.is_waiting_for_choice:
			scene.auto_pick_choice()
		else:
			scene._emit_next_line()
	var hist: Array = scene.history.duplicate()
	var res := {
		"seed": int(gd.run_seed),
		"cands": cands.duplicate(),
		"talents": gd.choose_talents.duplicate(),
		"values": gd.values.duplicate(),
		"age": gd.age,
		"gender": gd.gender,
		"history": hist,
	}
	root.remove_child(scene)
	scene.queue_free()
	return res

func _initialize() -> void:
	for n in ["PopupManager", "GlobalData", "RandomProbability", "TalentPool", "Progress"]:
		if not root.has_node(NodePath(n)):
			var s: Script = load("res://Auto_load/%s.gd" % n)
			var inst: Node = s.new()
			inst.name = n
			root.add_child(inst)
	await _frames(1)
	var gd: Node = root.get_node("GlobalData")

	# ---------- 种子可复现 ----------
	var a: Dictionary = await _run_with_seed(20261007, 120)
	await _frames(1)
	var b: Dictionary = await _run_with_seed(20261007, 120)
	await _frames(1)
	var c: Dictionary = await _run_with_seed(20261008, 120)
	await _frames(1)

	print("[种子] 同种子 20261007 跑两次：")
	print("   天赋候选 %s vs %s → %s" % [str(a.cands), str(b.cands), "一致" if a.cands == b.cands else "不一致"])
	print("   初始六维 %s vs %s → %s" % [str(a.values), str(b.values), "一致" if a.values == b.values else "不一致"])
	print("   性别/年龄 %d/%d vs %d/%d" % [a.gender, a.age, b.gender, b.age])
	print("   前120年事件序列（%d 个 vs %d 个）→ %s"
		% [a.history.size(), b.history.size(), "完全一致" if a.history == b.history else "不一致"])
	print("   事件序列前12个：%s" % str((a.history as Array).slice(0, 12)))
	print("[种子] 换种子 20261008 → 事件序列是否不同 = %s" % str(c.history != a.history))
	print("[种子] run_seed 记录 = %d / %d / %d" % [a.seed, b.seed, c.seed])

	# ---------- 修仙购买保护 ----------
	var scene: Node = load("res://Main/main.tscn").instantiate()
	root.add_child(scene)
	await _frames(1)
	(scene.get_node("Timer") as Timer).stop()
	scene.cultivating = true
	scene.cult_path = 0
	scene.realm = 0
	scene.cult_zi = 3
	scene.is_waiting_for_choice = true
	scene.pending_choices = [{"text": "灵脉（30资源）", "cost": 30, "func": func(): scene.cult_zi -= 30}]
	var before: int = int(scene.cult_zi)
	scene._on_choice_selected(scene.pending_choices[0])
	await _frames(2)
	print("[⑦] 只有 3 资源却点 30 资源的商品：资源 %d → %d（必须不变）｜仍在等待选择 = %s"
		% [before, scene.cult_zi, str(scene.is_waiting_for_choice)])
	# 够钱时应当扣款成功
	scene.cult_zi = 50
	scene.is_waiting_for_choice = true
	scene._on_choice_selected({"text": "灵脉（30资源）", "cost": 30, "func": func(): scene.cult_zi -= 30})
	await _frames(2)
	print("[⑦] 有 50 资源点 30 资源商品：资源 → %d（应为 20）" % scene.cult_zi)
	quit()
