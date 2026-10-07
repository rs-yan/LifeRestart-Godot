extends Control

var talent_scene: PackedScene = preload("uid://dnfeofw56iee8")
var record_scene: PackedScene = preload("res://Record/record.tscn")
const CHOOSE_SEED_SCENE := "res://Choose_seed/choose_seed.tscn"

# 用 find_child 按名字查找，节点层级改动（外面再包几层容器）都不影响
@onready var start_button: Button = find_child("Start", true, false)
@onready var seed_button: Button = find_child("StartWithSeed", true, false)
@onready var ach_button: Button = find_child("AchBtn", true, false)
@onready var evt_button: Button = find_child("EvtBtn", true, false)

func _ready() -> void:
	add_to_group("main_menu")
	if start_button != null:
		start_button.pressed.connect(_on_start_button)
	if seed_button != null:
		seed_button.pressed.connect(_on_start_with_seed)
	if ach_button != null:
		ach_button.pressed.connect(_open_record.bind(0))
	if evt_button != null:
		evt_button.pressed.connect(_open_record.bind(1))
	refresh_labels()

# 刷新按钮上的进度文案（重置进度、从图鉴/成就界面返回时都要调用）
func refresh_labels() -> void:
	if ach_button != null:
		ach_button.text = "成就（%d/%d）" % [Progress.unlocked_count(), Progress.ACHIEVEMENTS.size()]
	if evt_button != null:
		evt_button.text = "事件图鉴（%.1f%%）" % Progress.event_coverage()

func _open_record(mode: int) -> void:
	var r := record_scene.instantiate()
	r.mode = mode
	get_tree().root.add_child(r)
	hide()

# 普通开始：清掉上一局的种子，走随机
func _on_start_button() -> void:
	GlobalData.seed_input = 0
	GlobalData.run_seed = 0
	get_tree().change_scene_to_packed(talent_scene)

# 通过种子开始：进种子输入界面
func _on_start_with_seed() -> void:
	get_tree().change_scene_to_file.call_deferred(CHOOSE_SEED_SCENE)
