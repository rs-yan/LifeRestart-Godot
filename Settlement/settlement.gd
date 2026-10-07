extends Control

# 结算界面：填数值 + 属性评语，并跳转到「锁定天赋」界面

const SettlementPanels := preload("res://Settlement/settlement_panels.gd")

const LOCK_SCENE := "res://Lock_talent/lock_talent.tscn"
const SHOW_RUN_SUMMARY := true          # 是否在下方显示「本局解锁成就 + 事件图鉴进度」（不需要就改 false）

const KEYS := ["Age", "Strong", "Beauty", "Cleverness", "Money", "Emotion"]

@onready var title: Label = $VBoxContainer/Label
@onready var lock_button: Button = $VBoxContainer/MarginContainer2/Back
@onready var grid: GridContainer = $VBoxContainer/MarginContainer/GridContainer
@onready var root_box: VBoxContainer = $VBoxContainer

func _ready() -> void:
	var values := [
		int(GlobalData.age),
		int(GlobalData.strong), int(GlobalData.beauty), int(GlobalData.cleverness),
		int(GlobalData.money), int(GlobalData.emotion),
	]
	var keys := ["age", "strong", "beauty", "cleverness", "money", "emotion"]

	# 收集文本 / 数值 / 评语三种 Label
	var texts: Array = []
	var nums: Array = []
	var comments: Array = []
	for i in range(6):
		texts.append(grid.find_child("%sText" % KEYS[i], true, false))
		nums.append(grid.find_child("%sNum" % KEYS[i], true, false))
		comments.append(grid.find_child("%sComment" % KEYS[i], true, false))

	# 初始隐藏
	title.modulate.a = 0.0
	lock_button.modulate.a = 0.0
	lock_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(6):
		if texts[i] != null:
			texts[i].modulate.a = 0.0
		if nums[i] != null:
			nums[i].modulate.a = 0.0
		if comments[i] != null:
			comments[i].modulate.a = 0.0
			comments[i].text = SettlementPanels.evaluate(keys[i], values[i])

	# 修仙线结局摘要（在场景切换前由 main.gd 写入 GlobalData）
	if GlobalData.ending_summary != "":
		title.text = title.text + "\n" + GlobalData.ending_summary
		title.add_theme_font_size_override("font_size", 40)

	if lock_button != null:
		lock_button.pressed.connect(_on_lock_pressed)

	var summary: Control = null
	if SHOW_RUN_SUMMARY:
		summary = _build_run_summary()
		summary.modulate.a = 0.0

	# 等布局算完，按实际内容尺寸把整个盒子居中
	await get_tree().process_frame
	await get_tree().process_frame
	_center_box()

	# 1. 标题淡入
	var t = create_tween()
	t.tween_property(title, "modulate:a", 1.0, 0.35)
	await t.finished
	await get_tree().create_timer(0.12).timeout

	# 2. 每列「标题 + 数值 + 评语」一起淡入
	for i in range(6):
		var tw := create_tween()
		tw.set_parallel(true)
		if texts[i] != null:
			tw.tween_property(texts[i], "modulate:a", 1.0, 0.35)
		if nums[i] != null:
			nums[i].text = str(values[i])
			tw.tween_property(nums[i], "modulate:a", 1.0, 0.35)
		if comments[i] != null:
			tw.tween_property(comments[i], "modulate:a", 1.0, 0.35)
		await tw.finished
		await get_tree().create_timer(0.12).timeout

	# 3. 汇总 + 按钮最后淡入
	if summary != null:
		var ts := create_tween()
		ts.tween_property(summary, "modulate:a", 1.0, 0.35)
		await ts.finished
	var tb := create_tween()
	tb.tween_property(lock_button, "modulate:a", 1.0, 0.4)
	await tb.finished
	lock_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_center_box()

# 按实际内容尺寸把盒子在屏幕里居中
func _center_box() -> void:
	var vp := get_viewport_rect().size
	var s := root_box.size
	root_box.global_position = Vector2(
		roundf((vp.x - s.x) * 0.5),
		roundf((vp.y - s.y) * 0.5))

# 本局解锁的成就 + 事件图鉴进度（两行紧凑版，避免把内容顶出屏幕）
func _build_run_summary() -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_left", 200)
	root_box.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)

	if GlobalData.new_achievements.is_empty():
		box.add_child(_line("本局解锁成就：（无）", Color(0.62, 0.62, 0.62), 32))
	else:
		var parts: Array[String] = []
		var best := 1
		for a in GlobalData.new_achievements:
			var tier := int((a as Dictionary).get("tier", 1))
			best = maxi(best, tier)
			parts.append("【%s】%s" % [Progress.tier_name(tier), str(a.name)])
		box.add_child(_line("本局解锁成就：" + "、".join(parts), Progress.tier_color(best), 32))

	box.add_child(_line("事件图鉴：本局经历 %d 个事件｜累计 %d / %d（%.1f%%）"
		% [GlobalData.run_history.size(), Progress.seen_events.size(),
		   Progress.event_total, Progress.event_coverage()], Color(0.72, 0.90, 0.72), 32))
	return margin

func _line(text: String, color: Color, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _on_lock_pressed() -> void:
	# 注意：这里不能 reset GlobalData —— 锁定界面要读本局的 3 个天赋
	get_tree().change_scene_to_file.call_deferred(LOCK_SCENE)
