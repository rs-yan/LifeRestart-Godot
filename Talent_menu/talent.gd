extends Control

@onready var exit_button: Button = $ExitButton
@onready var start_button: Button = $Center/StartMargin/Start
@onready var hint: Label = $Center/Text2

const RARITY_NAME := ["", "普通", "稀有", "史诗", "传说"]

var candidate_ids: Array[int] = []

func _ready() -> void:
	add_to_group("talent_scene")
	exit_button.pressed.connect(_on_exit_button)
	start_button.pressed.connect(_on_start_button)

	GlobalData.choose_talents.clear()

	# ==================== 种子系统 ====================
	# 本局种子在这里确定：填了种子就用它，否则随机生成一个
	#   之后本局所有随机（天赋抽取、事件、判定）都从这一个随机序列派生，
	#   所以同一个种子 = 同样的天赋、同样的属性、同样的事件线
	if GlobalData.run_seed == 0:
		GlobalData.run_seed = GlobalData.seed_input if GlobalData.seed_input != 0 else randi()
		if GlobalData.run_seed == 0:
			GlobalData.run_seed = 1
	seed(GlobalData.run_seed)

	candidate_ids = TalentPool.draw_candidates(6)

	for i in range(1, 7):
		var title_pos = get_node("Center/TalentsBox/Talents/Talent%d/VBoxContainer/TitleLabel" % i)
		var body_pos = get_node("Center/TalentsBox/Talents/Talent%d/VBoxContainer/BodyLabel" % i)
		var btn = get_node("Center/TalentsBox/Talents/Talent%d/Button" % i) as Button

		if i - 1 >= candidate_ids.size():
			# 兜底：候选不足时隐藏多余卡位
			title_pos.text = ""
			body_pos.text = ""
			btn.disabled = true
			continue

		var id: int = candidate_ids[i - 1]
		var level := TalentPool.level_of(id)
		var color := TalentPool.rarity_color(level)
		title_pos.text = TalentPool.name_of(id)
		body_pos.text = "【%s】%s" % [RARITY_NAME[level], TalentPool.desc_of(id)]
		# 卡片固定 400x250，描述带「代价」后较长，缩字号避免被裁切
		title_pos.add_theme_font_size_override("font_size", 52)
		body_pos.add_theme_font_size_override("font_size", 26)
		title_pos.add_theme_color_override("font_color", color)
		body_pos.add_theme_color_override("font_color", color)

		btn.set_pressed_no_signal(false)
		btn.toggled.connect(_on_talent_toggled.bind(btn, id))

	_update_hint()

func _update_hint() -> void:
	hint.text = "（六选三　已选 %d/3）" % GlobalData.choose_talents.size()

func _on_talent_toggled(toggled_on: bool, btn: Button, talent_id: int) -> void:
	if toggled_on:
		if GlobalData.choose_talents.size() >= 3:
			btn.set_pressed_no_signal(false)
			PopupManager.show_popup("最多选择3个天赋", Color(1, 1, 1), 1)
			return
		GlobalData.choose_talents.append(talent_id)

		var style := StyleBoxFlat.new()
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3

		style.border_color = Color(1, 0.8, 0)

		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6

		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("pressed", style)
	else:
		GlobalData.choose_talents.erase(talent_id)
		btn.remove_theme_stylebox_override("normal")
		btn.remove_theme_stylebox_override("pressed")

	_update_hint()

func _process(delta: float) -> void:
	pass

func _on_exit_button() -> void:
	get_tree().change_scene_to_file.call_deferred("uid://bkjvvsfp415lg")

func _on_start_button() -> void:
	if GlobalData.choose_talents.size() < 3:
		PopupManager.show_popup("请选择3个天赋", Color(1, 1, 1), 1)
	else:
		hide()
		process_mode = Node.PROCESS_MODE_DISABLED
		var next_scene = load("uid://c3hfqpgef8vrg").instantiate()
		get_tree().root.add_child(next_scene)
