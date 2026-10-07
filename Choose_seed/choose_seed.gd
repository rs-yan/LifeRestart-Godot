extends Control

# 种子输入界面：用指定种子开始一局（同种子 = 同天赋、同属性、同事件线）

const TALENT_SCENE := "uid://dnfeofw56iee8"      # res://Talent_menu/Talent.tscn
const MENU_SCENE := "uid://bkjvvsfp415lg"        # res://Main_menu/main_menu.tscn

@onready var exit_button: Button = $ExitButton
@onready var start_button: Button = $Center/StartMargin/Start
@onready var line_edit: LineEdit = $Center/MarginContainer/LineEdit
@onready var title_label: Label = $Center/Text

func _ready() -> void:
	exit_button.pressed.connect(_on_exit)
	start_button.pressed.connect(_on_start)
	line_edit.text_submitted.connect(func(_text: String) -> void: _on_start())
	line_edit.placeholder_text = "留空则随机"
	line_edit.grab_focus()

# 种子解析：纯数字直接用；其它文本（比如一句口令）取哈希当种子
func _parse_seed(raw: String) -> int:
	var s := raw.strip_edges()
	if s.is_valid_int():
		return int(s)
	if s == "":
		return 0
	var h: int = absi(s.hash())
	return h if h != 0 else 1

func _on_start() -> void:
	var v := _parse_seed(line_edit.text)
	if v == 0:
		v = randi()                                   # 留空 = 随机种子
		if v == 0:
			v = 1
	GlobalData.seed_input = v
	GlobalData.run_seed = 0                           # 交给天赋界面初始化
	get_tree().change_scene_to_file.call_deferred(TALENT_SCENE)

func _on_exit() -> void:
	get_tree().change_scene_to_file.call_deferred(MENU_SCENE)
