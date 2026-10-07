extends Control

@onready var exit_button: Button = $ExitButton
@onready var start_button: Button = $VBoxContainer/Start

var MAX_USE = 20 
var sliders: Array[HSlider] = []
var num_texts: Array[Label] = []

func _ready() -> void:
	exit_button.pressed.connect(_on_exit_button)
	start_button.pressed.connect(_on_start_button)
	
	sliders = [
		$VBoxContainer/SetBox/VBoxContainer/Strong/VBoxContainer/HSlider,
		$VBoxContainer/SetBox/VBoxContainer/Beauty/VBoxContainer/HSlider,
		$VBoxContainer/SetBox/VBoxContainer/Cleverness/VBoxContainer/HSlider,
		$VBoxContainer/SetBox/VBoxContainer/Money/VBoxContainer/HSlider,
		$VBoxContainer/SetBox/VBoxContainer/luck/VBoxContainer/HSlider,
	]
	num_texts = [
		$VBoxContainer/SetBox/VBoxContainer/Strong/NumText,
		$VBoxContainer/SetBox/VBoxContainer/Beauty/NumText,
		$VBoxContainer/SetBox/VBoxContainer/Cleverness/NumText,
		$VBoxContainer/SetBox/VBoxContainer/Money/NumText,
		$VBoxContainer/SetBox/VBoxContainer/luck/NumText,
	]
	
	for sld in sliders:
		sld.value_changed.connect(_on_slider_value_changed.bind(sld))
	
	for id in GlobalData.choose_talents:
		if id == 1:
			MAX_USE += 1
		if id == 2:
			MAX_USE += 3
	var num_text = get_node("VBoxContainer/Text2")
	num_text.text = ("剩余%d点" % (MAX_USE))


func _process(delta: float) -> void:
	pass

func _on_exit_button() -> void:
	var talent = get_tree().get_first_node_in_group("talent_scene")
	if talent:
		talent.show()
		talent.process_mode = Node.PROCESS_MODE_INHERIT
	queue_free()
	
func _get_now_use() -> int:
	var sum := 0
	for sld in sliders:
		sum += int(sld.value)
	return sum
	
func _update_num_text() -> void:
	for i in range(sliders.size()):
		num_texts[i].text = ("%d/8" % int(sliders[i].value))

func _on_slider_value_changed(value: float, sld: Slider) -> void:
	var now := _get_now_use()
	if now > MAX_USE:
		sld.set_value_no_signal(sld.value - (now - MAX_USE))
		now = _get_now_use()
	var num_text = get_node("VBoxContainer/Text2")
	num_text.text = "剩余%d点" % (MAX_USE - now)
	_update_num_text() 

func _on_start_button() -> void:
	if _get_now_use() != MAX_USE:
		PopupManager.show_popup(("还有%d点属性未被分配" % (MAX_USE - _get_now_use())), Color(1, 1, 1), 1)
		return
	
	for i in range(0, 5):
		GlobalData.values[i] = int(sliders[i].value)
	GlobalData.values[5] = 5
	
	var talent = get_tree().get_first_node_in_group("talent_scene")
	if talent:
		talent.queue_free()
	
	get_tree().change_scene_to_file.call_deferred("uid://ceew1lnkae65u")
	
	queue_free()
