extends Control

# 锁定天赋界面：从本局抽到的 3 个天赋里选一个锁定，下局六选三必定刷到它
#   入口：结算界面的「锁定天赋」按钮
#   返回：清空本局数据并回到主菜单

const RARITY_NAME := ["", "普通", "稀有", "史诗", "传说"]

@onready var title: Label = find_child("Title", true, false)
@onready var body: Label = find_child("Body", true, false)
@onready var copy_seed: Button = find_child("CopySeed", true, false)
@onready var back_button: Button = $VBoxContainer/MarginContainer2/Button

var cards: Array = []

func _ready() -> void:
	cards.clear()
	_collect_cards(self, cards)
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	if copy_seed != null:
		copy_seed.pressed.connect(_on_copy_seed)
		copy_seed.text = "复制种子：%d" % GlobalData.run_seed
	_setup()

# 复制本局种子：别人拿这个种子开局，天赋/属性/事件线都和你这局一样
func _on_copy_seed() -> void:
	DisplayServer.clipboard_set(str(GlobalData.run_seed))
	if copy_seed != null:
		copy_seed.text = "已复制种子：%d（发给朋友可复现本局）" % GlobalData.run_seed

# 递归收集所有名为 Talent 的卡片（不依赖具体层级，你外面再套容器也不影响）
func _collect_cards(node: Node, out: Array) -> void:
	for c in node.get_children():
		if c.name == "Talent":
			out.append(c)
		_collect_cards(c, out)

func _setup() -> void:
	var talents: Array = GlobalData.choose_talents

	# 没有本局数据（例如直接在编辑器里单跑这个场景）时，保持原样不动：
	# 千万不要隐藏卡片，否则整个 VBox 会塌缩、看起来"居中和大小都不对了"。
	if talents.is_empty():
		if title != null:
			title.text = "请选择一个天赋"
		if body != null:
			body.text = "（预览模式：从结算界面进入可看到本局抽到的天赋）"
		for card in cards:
			var btn: Button = card.get_node("Button")
			btn.disabled = true
		return

	for i in range(cards.size()):
		var card: MarginContainer = cards[i]
		var btn: Button = card.get_node("Button")
		var title_label: Label = card.get_node("VBoxContainer/TitleLabel")
		var body_label: Label = card.get_node("VBoxContainer/BodyLabel")

		if i >= talents.size():
			card.visible = false
			continue

		var id := int(talents[i])
		var level := TalentPool.level_of(id)
		var color := TalentPool.rarity_color(level)
		title_label.text = "%s【%s】" % [TalentPool.name_of(id), RARITY_NAME[clampi(level, 0, 4)]]
		body_label.text = TalentPool.desc_of(id)
		title_label.add_theme_color_override("font_color", color)
		body_label.add_theme_color_override("font_color", color)

		var chosen := Progress.locked_talent == id
		btn.set_pressed_no_signal(chosen)
		_apply_selected(btn, chosen)
		btn.toggled.connect(_on_card_toggled.bind(btn, id))

	if body != null and Progress.locked_talent != 0:
		body.text = "已锁定：%s —— 下局六选三必定出现" % TalentPool.name_of(Progress.locked_talent)

func _on_card_toggled(toggled_on: bool, btn: Button, id: int) -> void:
	if toggled_on:
		Progress.locked_talent = id
		Progress.save()
		# 同时只能锁一个：其余卡片取消选中
		for card in cards:
			var other: Button = card.get_node("Button")
			if other != btn:
				other.set_pressed_no_signal(false)
				_apply_selected(other, false)
		_apply_selected(btn, true)
		if body != null:
			body.text = "已锁定：%s —— 下局六选三必定出现" % TalentPool.name_of(id)
	else:
		# 取消选中即解除锁定
		if Progress.locked_talent == id:
			Progress.locked_talent = 0
			Progress.save()
			if body != null:
				body.text = "已解除锁定，下局随机抽取"
		_apply_selected(btn, false)

func _apply_selected(btn: Button, selected: bool) -> void:
	if btn == null:
		return
	if selected:
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
		btn.remove_theme_stylebox_override("normal")
		btn.remove_theme_stylebox_override("pressed")

func _on_back_pressed() -> void:
	# 一局彻底结束，这里才清空本局数据
	GlobalData.reset()
	get_tree().change_scene_to_file.call_deferred("res://Main_menu/main_menu.tscn")
