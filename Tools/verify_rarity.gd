extends SceneTree

# 验证：事件稀有度分级 + 文本着色
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
	var scene: Node = load("res://Main/main.tscn").instantiate()
	root.add_child(scene)
	await _frames(2)
	(scene.get_node("Timer") as Timer).stop()

	var cases := [
		[1, 1], [207, 1], [920, 3], [1200, 4], [2003, 3],
		[3001, 2], [4001, 2], [6001, 2], [7001, 3], [8001, 2],
	]
	var ok := true
	var out: Array = []
	for c in cases:
		var got: int = scene._event_rarity({"id": c[0]})
		if got != c[1]:
			ok = false
		out.append("%d→%d" % [c[0], got])
	print("[⑤] 自动稀有度：%s" % "｜".join(out))
	print("[⑤] 显式覆盖 rarity=4 → %d" % scene._event_rarity({"id": 1, "rarity": 4}))
	print("[⑤] 判定全部正确 = %s" % str(ok))

	# 着色：传 4 应写入金色
	scene.add_text_line("第100岁，测试传说事件。", 4)
	await _frames(2)
	var last: Node = scene.text_list.get_child(scene.text_list.get_child_count() - 1)
	var lab: Label = last.find_child("Label", true, false)
	print("[⑤] 传说文本颜色 = %s（应为 (1, 0.72, 0.25)）" % str(lab.get_theme_color("font_color")))
	scene.add_text_line("第101岁，普通事件不该着色。", 1)
	await _frames(2)
	var last2: Node = scene.text_list.get_child(scene.text_list.get_child_count() - 1)
	var lab2: Label = last2.find_child("Label", true, false)
	print("[⑤] 普通文本是否被覆盖 = %s（应为 false）" % str(lab2.has_theme_color_override("font_color")))
	quit()
