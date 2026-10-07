extends Control

# 成就 / 事件图鉴 查看界面
#   mode: 0 = 成就，1 = 事件图鉴（由 Main_menu 在实例化后设置）

var mode := 0
var _reset_armed := false

@onready var title: Label = $Title
@onready var list: VBoxContainer = $Scroll/List
@onready var reset_btn: Button = $ResetBtn

func _ready() -> void:
	$TabBox/AchTab.pressed.connect(func() -> void:
		mode = 0
		_refresh())
	$TabBox/EvtTab.pressed.connect(func() -> void:
		mode = 1
		_refresh())
	$Back.pressed.connect(_on_back)
	reset_btn.pressed.connect(_on_reset)
	_refresh()

func _on_reset() -> void:
	# 两段式：第一次点变成确认，第二次才真清空
	if not _reset_armed:
		_reset_armed = true
		reset_btn.text = "再点一次确认清空"
		return
	Progress.clear_all()
	_reset_armed = false
	reset_btn.text = "重置全部进度"
	_refresh()

func _on_back() -> void:
	# 主菜单只是被隐藏，这里恢复它并销毁自己
	var menu := get_tree().get_first_node_in_group("main_menu")
	if menu != null:
		menu.show()
		if menu.has_method("refresh_labels"):
			menu.refresh_labels()      # 重置过进度的话，按钮上的百分比要立刻更新
	queue_free()

func _refresh() -> void:
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	if mode == 0:
		_build_achievements()
	else:
		_build_events()

func _build_achievements() -> void:
	var total: int = Progress.ACHIEVEMENTS.size()
	title.text = "成就　%d / %d（%.1f%%）" % [Progress.unlocked_count(), total,
		100.0 * float(Progress.unlocked_count()) / maxi(1, total)]
	_add_line("等级：钻石 > 黄金 > 白银 > 青铜　｜　【已解锁】= 达成，【未解锁】= 尚未达成",
		Color(0.82, 0.82, 0.82), 30)
	for tier in [4, 3, 2, 1]:
		_add_line("──────── %s ────────" % Progress.tier_name(tier),
			Progress.tier_color(tier), 44)
		for a in Progress.ACHIEVEMENTS:
			if int(a.tier) != tier:
				continue
			var got: bool = Progress.is_unlocked(str(a.id))
			var hidden: bool = bool((a as Dictionary).get("hidden", false))
			var txt := ""
			if hidden and not got:
				# 隐藏成就：未解锁时不剧透
				txt = "【未解锁】？？？　——　隐藏成就"
			else:
				txt = "【%s】%s　——　%s" % ["已解锁" if got else "未解锁", str(a.name), str(a.desc)]
			_add_line(txt, Progress.tier_color(tier) if got else Color(0.58, 0.58, 0.58), 34)

func _build_events() -> void:
	var seen: Array = Progress.seen_event_list()
	title.text = "事件图鉴　%d / %d（%.1f%%）" % [seen.size(), Progress.event_total,
		Progress.event_coverage()]
	_add_line("只显示已经历过的事件，按 id 排序（同一事件多次触发只算一次）。",
		Color(0.82, 0.82, 0.82), 30)
	if seen.is_empty():
		_add_line("还没有经历过任何事件，先开始一局人生吧。", Color(0.75, 0.75, 0.75), 34)
		return
	for item in seen:
		_add_line("#%d　%s" % [int(item.id), str(item.text)], Color(0.90, 0.90, 0.90), 32)

func _add_line(text: String, color: Color, size: int) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	list.add_child(l)
