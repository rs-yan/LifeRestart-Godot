extends SceneTree

# 截图：天劫播报 + 修仙六维面板（⑨⑩ 的视觉证据）
const BI := preload("res://Data/BreakthroughItems.gd")

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
	root.size = Vector2i(1920, 1080)

	gd.reset()
	var vals: Array[int] = [8, 7, 9, 6, 5, 7]
	gd.values = vals
	gd.choose_talents.assign([55, 12, 32])
	var scene: Node = load("res://Main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(3)
	(scene.get_node("Timer") as Timer).stop()
	scene._set_flag("mysterious_jade")
	scene._set_flag("mysterious_book")
	scene._enter_cultivation()
	await _frames(2)

	# 造一个合体期角色：持有部分大乘八德（缺 3 件）+ 前置未完成
	scene.realm = 6
	scene.cult_ling = 30
	scene.cult_wu = 28
	scene.cult_dao = 26
	scene.cult_xin = 24
	scene.cult_face = 20
	scene.cult_zi = 60
	var st: Dictionary = BI.stage(0, 6)
	scene.cult_items.clear()
	for it in st.common:
		scene._grant_cult_item(str(it))
	scene._grant_cult_item("渡劫台")
	scene._refresh_panel_titles()
	scene._update_values()
	var tb: Dictionary = scene._tribulation()
	print("状态：境界=%d｜劫重=%d【%s·%s】｜缺普通%d 核心%d 钥匙%d｜成功率 %.0f%%"
		% [scene.realm, tb.weight, tb.level, tb.type_name, tb.miss_common, tb.miss_core, tb.miss_key,
		   scene._breakthrough_chance()])
	# 真渡一次，让天劫播报出现在日志里
	scene._try_breakthrough()
	await _frames(6)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("D:/yrs/deepseek/_tribulation.png")
	print("截图 D:/yrs/deepseek/_tribulation.png")
	quit()
