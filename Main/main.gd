extends Control

# ==================== 常量 ====================
const STAT_KEYS := ["strong", "beauty", "cleverness", "money", "luck", "emotion"]
const STAT_MIN := 0
const STAT_MAX := 10
const STAT_MAX_CULTIVATION := 20   # 进入修仙线后属性上限

# ==================== 修仙线境界表（《修仙线完整体系表》） ====================
const REALM_CAP := [20, 30, 40, 50, 60, 70, 80, 90, 100, 100]                  # 全属性上限（三线共用）
const REALM_LIFESPAN := [200, 300, 400, 500, 600, 700, 800, 900, 1000, 99999]  # 寿元上限（三线共用）
const REALM_AGE := [150, 220, 300, 380, 460, 540, 620, 700, 850, 0]            # 突破年龄下限（三线共用）

# ==================== 修仙三线：仙修 / 魔修 / 魂修（互斥） ====================
const CULT_PATHS := ["仙修", "魔修", "魂修"]
# 三线核心属性名 + 修仙六维面板名（灵力、悟性、天道、心智、资源、面相）
const PATH_ATTR_NAMES := [
	["灵力", "悟性", "天道", "心智", "资源", "面相"],
	["魔元", "魔悟", "业力", "心智", "资源", "面相"],
	["魂力", "魂悟", "魂道", "心智", "资源", "面相"],
]
# 三线境界名称（沿用主线大境界等级，只改名称）
const PATH_REALM_NAMES := [
	["练气期", "筑基期", "金丹期", "元婴期", "化神期", "炼虚期", "合体期", "大乘期", "渡劫期", "飞升仙界"],
	["魔徒", "魔基", "魔丹", "魔婴", "魔化神", "魔炼虚", "魔合体", "魔大乘", "魔渡劫", "飞升魔界"],
	["炼魂", "凝魂", "魂丹", "魂婴", "魂神", "炼魂虚", "合魂", "大乘魂", "魂劫", "飞升幽冥"],
]
# 各线突破基础成功率（练气→筑基 … 渡劫→飞升）
const PATH_BASE := [
	[50, 45, 40, 35, 30, 25, 20, 15, 10],
	[55, 50, 45, 40, 35, 30, 25, 20, 15],
	[50, 45, 40, 35, 30, 25, 20, 15, 10],
]
# 各线三维门槛：[a, b, c] × 9 个突破
const PATH_REQ := [
	[[18, 27, 36, 45, 54, 63, 72, 81, 90], [16, 24, 32, 40, 48, 56, 64, 72, 80], [12, 18, 24, 30, 36, 42, 48, 54, 60]],
	[[17, 25, 34, 43, 52, 61, 70, 79, 88], [14, 22, 30, 38, 46, 54, 62, 70, 78], [10, 15, 20, 25, 30, 35, 40, 45, 50]],
	[[16, 24, 32, 40, 48, 56, 64, 72, 80], [17, 25, 33, 41, 49, 57, 65, 73, 81], [12, 18, 24, 30, 36, 42, 48, 54, 60]],
]
# 副属性门槛：仙修无 / 魔修煞气 / 魂修魂火
const PATH_REQ_EXTRA := [
	[0, 0, 0, 0, 0, 0, 0, 0, 0],
	[5, 10, 15, 20, 25, 30, 35, 40, 45],
	[1, 2, 3, 4, 5, 6, 7, 8, 9],
]
# 三线共用的心智门槛 / 资源消耗 / 面相建议（按境界）
const REQ_MIND := [8, 12, 16, 20, 24, 28, 32, 36, 60]
const REQ_RESOURCE_COST := [10, 15, 20, 25, 30, 35, 40, 45, 50]
const REQ_FACE := [10, 15, 20, 25, 30, 35, 40, 45, 60]
# 各条线的数据表（注入 event_pool）
const RomanceEvents := preload("res://Data/RomanceEvents.gd")
const FamilyEvents := preload("res://Data/FamilyEvents.gd")
const CultivationEvents := preload("res://Data/CultivationEvents.gd")
const InteractionEvents := preload("res://Data/InteractionEvents.gd")
const ResourceEvents := preload("res://Data/ResourceEvents.gd")
const GenderEvents := preload("res://Data/GenderEvents.gd")
const BreakthroughItems := preload("res://Data/BreakthroughItems.gd")
const AdvanceEvents := preload("res://Data/AdvanceEvents.gd")

enum MaritalStatus { SINGLE, DATING, MARRIED, DIVORCED, WIDOWED, CRUSH, ENGAGED }
enum JobStatus { STUDENT, UNEMPLOYED, EMPLOYED, SELF_EMPLOYED, RETIRED }
enum EducationStatus { PRESCHOOL, PRIMARY, MIDDLE, HIGH, UNIVERSITY, GRADUATED, DROPPED_OUT }
enum HealthStatus { HEALTHY, CHRONIC, SERIOUS, BEDRIDDEN }
enum LivingStatus { WITH_PARENTS, ALONE, WITH_PARTNER, WITH_CHILDREN, NURSING_HOME }

# ==================== 变量 ====================
var value_texts: Array[Label] = []
var value_titles: Array[Label] = []
var wait_time: float = 1.5
var is_dead := false
var is_waiting_for_choice := false
var event_pool: Array[Dictionary] = []
var flags: Dictionary = {}
var triggered_once: Dictionary = {}
var stress: int = 0
var history: Array[int] = []             # 本局触发过的事件 id（供模拟统计用）
var pending_choices: Array = []          # 当前待选选项
var current_choice_event: Dictionary = {}

var talents: Array = []        # 本局天赋 id 列表

var marital_status: int = MaritalStatus.SINGLE
var marriage_age: int = -1
var engagement_age: int = -1
var divorce_age: int = -1
var job_status: int = JobStatus.STUDENT
var income_level: int = 0
var education_status: int = EducationStatus.PRESCHOOL
var is_top_school := false
var is_baosong := false
var children_count := 0
var children_relationship := 5
var child_ages: Array[int] = []      # 每个孩子的年龄（每年 +1）
var grandchildren_count := 0

# ---------- 修仙线状态（《修仙线完整体系表》+ 六维 + 魔修/魂修支线） ----------
var cultivating := false             # 是否已进入修仙线
var cult_path := 0                   # 0=仙修 1=魔修 2=魂修（三线互斥）
var realm := 0                       # 0=练气 … 8=渡劫（9=飞升）
var cult_ling := 1                   # 灵力 / 魔元 / 魂力
var cult_wu := 1                     # 悟性 / 魔悟 / 魂悟
var cult_dao := 1                    # 天道 / 业力 / 魂道
var cult_xin := 1                    # 心智（道心、抗心魔、减免失败惩罚）
var _res_value := 1                  # 资源内部值
var cult_zi := 1:                    # 资源（灵石、丹药、法宝、突破消耗）
	set(value):
		_res_value = maxi(0, int(value))   # 兜底：任何扣减都不会变成负数
	get:
		return _res_value
var cult_face := 1                   # 面相（仙缘、道侣、拜师、天劫留手）
var cult_extra := 0                  # 副属性：仙修无 / 魔修煞气 / 魂修魂火
var heart_demon := 0                 # 魔修心魔层数
var lifespan := 200                  # 当前寿元上限
var fail_streak := 0                 # 连续突破失败次数
var cult_items: Dictionary = {}      # 已获得的道具/机缘
var cultivation_ended := ""          # 结局
var tribulation_log: Array = []      # 统计：每次渡劫的劫重/成功率/缺失件数
var _run_recorded := false           # 本局是否已结算过成就/事件图鉴：飞升/寿尽/身死道消/归隐
var living_status: int = LivingStatus.WITH_PARENTS
var health_status: int = HealthStatus.HEALTHY
var parents_alive := true
var parents_divorced := false
var parents_health := 5

# ==================== 节点引用 ====================
@onready var text_list: VBoxContainer = $CenterBox/ScrollContainer/TextList
@onready var choose_box: GridContainer = $CenterBox/ChooseBox
@onready var scroll_container: ScrollContainer = $CenterBox/ScrollContainer
@onready var Speed_Text := $RightOperationBox/HBoxContainer/SpeedNum
@onready var Speed_Slider: HSlider = $RightOperationBox/HBoxContainer/VBoxContainer/SpeedSlider
@onready var timer: Timer = $Timer

var text_line_scene: PackedScene = preload("uid://cu1lv5awepvta")
var choose_line_scene: PackedScene = preload("uid://ccjpl64kay6kk")

# ==================== 生命周期 ====================
func _ready() -> void:
	talents = GlobalData.choose_talents.duplicate()
	value_texts = [
		$Values/Strong/MarginContainer/VBoxContainer/BodyText,
		$Values/Beauty/MarginContainer/VBoxContainer/BodyText,
		$Values/Cleverness/MarginContainer/VBoxContainer/BodyText,
		$Values/Money/MarginContainer/VBoxContainer/BodyText,
		$Values/Luck/MarginContainer/VBoxContainer/BodyText,
		$Values/Emotion/MarginContainer/VBoxContainer/BodyText
	]
	value_titles = [
		$Values/Strong/MarginContainer/VBoxContainer/TitleText,
		$Values/Beauty/MarginContainer/VBoxContainer/TitleText,
		$Values/Cleverness/MarginContainer/VBoxContainer/TitleText,
		$Values/Money/MarginContainer/VBoxContainer/TitleText,
		$Values/Luck/MarginContainer/VBoxContainer/TitleText,
		$Values/Emotion/MarginContainer/VBoxContainer/TitleText
	]
	_init_event_pool()
	_apply_talent_initial_effects()
	_update_values()
	_broadcast_talents()

	timer.timeout.connect(start_text_sequence)
	Speed_Slider.value_changed.connect(_on_speed_slider_value_changed)
	start_text_sequence()

# ==================== 天赋 ====================
func _has_talent(id: int) -> bool:
	return talents.has(id)

func _talent_name(id: int) -> String:
	return TalentPool.name_of(id)

func _apply_talent_initial_effects() -> void:
	# 普通
	if _has_talent(1): _set_stat("strong", _get_stat("strong") + 1)
	if _has_talent(2): _set_stat("beauty", _get_stat("beauty") + 1)
	if _has_talent(3): _set_stat("cleverness", _get_stat("cleverness") + 1)
	if _has_talent(4): _set_stat("money", _get_stat("money") + 1)
	if _has_talent(5): _set_stat("luck", _get_stat("luck") + 1)
	if _has_talent(6): _set_stat("emotion", _get_stat("emotion") + 1)
	# 稀有
	if _has_talent(11): _set_stat("strong", maxi(3, _get_stat("strong") + 2))
	if _has_talent(12): _set_stat("beauty", maxi(3, _get_stat("beauty") + 2))
	if _has_talent(13): _set_stat("cleverness", maxi(3, _get_stat("cleverness") + 2))
	if _has_talent(14): _set_stat("money", maxi(3, _get_stat("money") + 2))
	if _has_talent(15): _set_stat("luck", maxi(3, _get_stat("luck") + 2))
	if _has_talent(16): _set_stat("emotion", maxi(3, _get_stat("emotion") + 2))
	if _has_talent(17):   # 运动细胞 T13：自带运动习惯，代价 智力-1
		_set_flag("sporty")
		_set_stat("cleverness", _get_stat("cleverness") - 1)
	if _has_talent(19): parents_health += 3
	# 史诗
	if _has_talent(35):   # 书香门第 T21：开局小学，代价 家境-1
		education_status = EducationStatus.PRIMARY
		_set_stat("money", _get_stat("money") - 1)
	if _has_talent(34):   # 白手起家 T20：代价 家境-2
		_set_stat("money", _get_stat("money") - 2)
	if _has_talent(37):   # 青梅竹马 T23：开局自带恋人（交往中）
		_set_flag("in_love")
		marital_status = MaritalStatus.DATING
	if _has_talent(40):   # 孤儿
		parents_alive = false
		_set_stat("luck", _get_stat("luck") + 3)
	if _has_talent(38):   # 世家子弟 T24：开局就业，代价 快乐-2
		job_status = JobStatus.EMPLOYED
		income_level = 2
		_set_stat("emotion", _get_stat("emotion") - 2)
	if _has_talent(39):   # 寒门贵子 T25：开局高中，代价 家境-2、父母健康-2
		education_status = EducationStatus.HIGH
		_set_stat("money", _get_stat("money") - 2)
		parents_health = maxi(0, parents_health - 2)
	if _has_talent(36):   # 天煞孤星 T22：代价 运气-2
		_set_stat("luck", _get_stat("luck") - 2)
	# 传说
	if _has_talent(55):   # 神秘玉佩 T30：修仙线钥匙
		_set_flag("mysterious_jade")

func _broadcast_talents() -> void:
	if talents.is_empty():
		add_text_line("你没有携带任何天赋。")
		return
	var parts: Array[String] = []
	for id in talents:
		parts.append("%s（%s）" % [_talent_name(id), TalentPool.desc_of(id)])
	add_text_line("【本局天赋】" + "；".join(parts))

# ==================== 属性读写 ====================
func _get_stat(key: String) -> int:
	match key:
		"strong":     return int(GlobalData.strong)
		"beauty":     return int(GlobalData.beauty)
		"cleverness": return int(GlobalData.cleverness)
		"money":      return int(GlobalData.money)
		"luck":       return int(GlobalData.luck)
		"emotion":    return int(GlobalData.emotion)
	return 0

func _stat_max() -> int:
	return STAT_MAX_CULTIVATION if cultivating else STAT_MAX

func _set_stat(key: String, value: int) -> void:
	value = clampi(value, STAT_MIN, _stat_max())
	match key:
		"strong":     GlobalData.strong = value
		"beauty":     GlobalData.beauty = value
		"cleverness": GlobalData.cleverness = value
		"money":      GlobalData.money = value
		"luck":       GlobalData.luck = value
		"emotion":    GlobalData.emotion = value

	var idx := STAT_KEYS.find(key)
	if idx >= 0 and idx < GlobalData.values.size():
		GlobalData.values[idx] = value

# 带天赋修正的属性应用，返回触发消息
func _apply_effects(effects: Dictionary) -> Array:
	var msgs: Array = []
	for key in effects:
		var v := int(effects[key])
		var label := _stat_label(key)

		# 过目不忘 T18：智力增加额外+1｜快乐减少额外-1
		if _has_talent(32):
			if key == "cleverness" and v > 0:
				v += 1
				msgs.append("%s：智力+1" % _talent_name(32))
			elif key == "emotion" and v < 0:
				v -= 1

		if v > 0:
			# 早熟 T14：18岁前 +1，19岁后反而 -1
			if _has_talent(18):
				if GlobalData.age <= 18:
					v += 1
					msgs.append("%s：%s+1" % [_talent_name(18), label])
				else:
					v -= 1
					msgs.append("%s（代价）：%s-1" % [_talent_name(18), label])

			# 大器晚成 T17：40岁后 +1，40岁前 -1
			if _has_talent(31):
				if GlobalData.age >= 40:
					v += 1
					msgs.append("%s：%s+1" % [_talent_name(31), label])
				else:
					v -= 1
					msgs.append("%s（代价）：%s-1" % [_talent_name(31), label])

			# 玻璃心：快乐恢复效果 +1
			if _has_talent(7) and key == "emotion":
				v += 1
				msgs.append("%s：快乐+1" % _talent_name(7))

			# 佛系 T16 代价：所有正面事件效果 -1
			if _has_talent(23):
				v -= 1

		# 龙脉传承 T29：无法通过事件获得运气
		if _has_talent(54) and key == "luck" and v > 0:
			v = 0
			msgs.append("%s：运气不增" % _talent_name(54))

		var new_val := _get_stat(key) + v
		if _has_talent(54):
			new_val = maxi(5, new_val)
		_set_stat(key, new_val)

	return msgs

func _update_values() -> void:
	if cultivating:
		# 修仙后六格全显修仙六维（面板顺序：体质/颜值/智商/家境/运气/心情 → 灵力/面相/悟性/资源/天道/心智）
		value_texts[0].text = str(cult_ling)
		value_texts[1].text = str(cult_face)
		value_texts[2].text = str(cult_wu)
		value_texts[3].text = str(cult_zi)
		value_texts[4].text = str(cult_dao)
		value_texts[5].text = str(cult_xin)
		return
	for i in range(0, 6):
		value_texts[i].text = ("%d" % GlobalData.values[i])

# 进入修仙线后把六格标题换成当前线的六维属性名
func _refresh_panel_titles() -> void:
	if value_titles.size() < 6:
		return
	var names := ["体质", "颜值", "智商", "家境", "运气", "心情"]
	if cultivating:
		var a: Array = PATH_ATTR_NAMES[clampi(cult_path, 0, 2)]
		names = [a[0], a[5], a[1], a[4], a[2], a[3]]
	for i in range(6):
		value_titles[i].text = names[i]

# ==================== 标记与压力 ====================
func _has_flag(name: String) -> bool:
	return flags.get(name, false)

func _set_flag(name: String) -> void:
	flags[name] = true

func _clear_flag(name: String) -> void:
	flags.erase(name)

func _stress_max() -> int:
	# 抗压之王 T19：压力上限+3
	return 10 + (3 if _has_talent(33) else 0)

func _add_stress(n: int) -> void:
	stress = clampi(stress + n, 0, _stress_max())

func _yearly_stress_decay() -> void:
	# 基础不再自动衰减（否则压力永远为 0，过劳链/压力猝死事件全部不可达）
	# 衰减只来自：佛系 T16、抗压之王 T19、高情绪
	var decay := 0
	if _has_talent(23): decay += 1
	if _has_talent(33): decay += 1
	if _get_stat("emotion") >= 7: decay += 1
	if decay > 0:
		stress = maxi(0, stress - decay)

# 凡人寿元耗尽的自然死亡
func _die_natural() -> void:
	add_text_line("第%d岁，你的身体机能终于走到了尽头，在睡梦中安然长逝。你死了。" % GlobalData.age)
	_finish_run()
	add_choose_line("结算")
	timer.stop()
	Speed_Slider.editable = false
	is_dead = true

# 结算前：解锁成就、并入事件图鉴、把本局状态交给结算画面
func _finish_run() -> void:
	if _run_recorded:
		return
	_run_recorded = true
	var state := {
		"age": GlobalData.age,
		"values": GlobalData.values.duplicate(),
		"talents": talents.duplicate(),
		"history": history.duplicate(),
		"marital": marital_status,
		"children": children_count,
		"grandchildren": grandchildren_count,
		"stress": stress,
		"cultivating": cultivating,
		"path": cult_path,
		"realm": realm,
		"ending": cultivation_ended,
		"flags": flags.duplicate(),
		# 成就判定需要的扩展状态
		"job": job_status,
		"items": cult_items.duplicate(),
		"heart_demon": heart_demon,
		"extra": cult_extra,          # 魔修煞气 / 魂修魂火
		"ling": cult_ling, "wu": cult_wu, "dao": cult_dao,
		"xin": cult_xin, "face": cult_face, "res": cult_zi,
		"event_count": history.size(),
	}
	GlobalData.new_achievements = Progress.finish_run(state)
	GlobalData.run_history = history.duplicate()

# ==================== 状态检查与变更 ====================
func _check_status(require: Dictionary) -> bool:
	for key in require:
		match key:
			"marital":
				if marital_status != require[key]:
					return false
			"job":
				if job_status != require[key]:
					return false
			"education":
				if education_status != require[key]:
					return false
			"health":
				if health_status != require[key]:
					return false
			"living":
				if living_status != require[key]:
					return false
			"children_min":
				if children_count < int(require[key]):
					return false
			"children_max":
				if children_count > int(require[key]):
					return false
			"parents_alive":
				if parents_alive != require[key]:
					return false
	return true

func _apply_status(set_status: Dictionary) -> void:
	for key in set_status:
		match key:
			"marital":
				var new_marital: int = int(set_status[key])
				# 天煞孤星 T22：无法暗恋/交往/订婚/结婚
				if _has_talent(36) and new_marital in [MaritalStatus.CRUSH, MaritalStatus.DATING,
						MaritalStatus.ENGAGED, MaritalStatus.MARRIED]:
					continue
				marital_status = new_marital
				match marital_status:
					MaritalStatus.ENGAGED:
						engagement_age = GlobalData.age
					MaritalStatus.MARRIED:
						marriage_age = GlobalData.age
						_set_flag("ever_married")
					MaritalStatus.WIDOWED:
						if marriage_years() >= 30:
							_set_flag("widow_after_30")
					MaritalStatus.DIVORCED:
						divorce_age = GlobalData.age
			"job":
				job_status = set_status[key]
			"education":
				education_status = set_status[key]
			"health":
				health_status = set_status[key]
			"living":
				living_status = set_status[key]
			"children_add":
				var born := int(set_status[key])
				children_count += born
				for i in range(born):
					child_ages.append(0)
			"children_rel_add":
				children_relationship = clampi(children_relationship + int(set_status[key]), 0, 10)
			"grandchildren_add":
				grandchildren_count += int(set_status[key])
			"spirit_add":
				cult_ling = clampi(cult_ling + int(set_status[key]), 1, _cult_cap())
			"insight_add":
				cult_wu = clampi(cult_wu + int(set_status[key]), 1, _cult_cap())
			"dao_add":
				cult_dao = clampi(cult_dao + int(set_status[key]), 1, _cult_cap())
			"mind_add":
				cult_xin = clampi(cult_xin + int(set_status[key]), 1, _cult_cap())
			"res_add":
				cult_zi = clampi(cult_zi + int(set_status[key]), 1, _cult_cap())
			"res_pct":
				cult_zi = maxi(0, int(float(cult_zi) * float(set_status[key]) / 100.0))
			"face_add":
				cult_face = clampi(cult_face + int(set_status[key]), 1, _cult_cap())
			"extra_add":
				cult_extra = clampi(cult_extra + int(set_status[key]), 0, 100)
			"heart_demon_add":
				heart_demon = maxi(0, heart_demon + int(set_status[key]))
			"cult_item":
				_grant_cult_item(str(set_status[key]))
			"grant_common":
				_grant_missing_item("common")
			"grant_core":
				_grant_missing_item("core")
			"grant_key":
				_grant_missing_item("key")
			"grant_pre":
				_grant_pre_event()
			"income_add":
				income_level = clampi(income_level + int(set_status[key]), 0, 5)
			"is_baosong":
				is_baosong = set_status[key]
			"parents_alive":
				parents_alive = set_status[key]

# ==================== 属性变化文本 ====================
func _stat_label(key: String) -> String:
	match key:
		"strong":     return "体质"
		"beauty":     return "颜值"
		"cleverness": return "智力"
		"money":      return "家境"
		"luck":       return "运气"
		"emotion":    return "快乐"
	return key

func _format_effects(effects: Dictionary) -> String:
	if effects.is_empty():
		return ""
	var parts: Array[String] = []
	for key in effects:
		var v := int(effects[key])
		if v == 0:
			continue
		var label := _stat_label(key)
		var sign := "+" if v > 0 else ""
		parts.append("%s%s%d" % [label, sign, v])
	if parts.is_empty():
		return ""
	return "（%s）" % "，".join(parts)

# ==================== UI 输出 ====================
# 事件稀有度：1 普通 / 2 稀有 / 3 史诗 / 4 传说
const EVENT_RARITY_COLORS := [
	Color(1.00, 1.00, 1.00),
	Color(0.88, 0.88, 0.88),
	Color(0.45, 0.72, 1.00),
	Color(0.78, 0.55, 1.00),
	Color(1.00, 0.72, 0.25),
]

# 事件稀有度：数据表里写 "rarity" 就用手写的，否则按 id 段/类别自动判定
func _event_rarity(e: Dictionary) -> int:
	if e.has("rarity"):
		return clampi(int(e.rarity), 1, 4)
	if bool(e.get("death", false)):
		return 3
	var id := int(e.get("id", 0))
	if id >= 8000:
		return 2      # 性别专属
	if id >= 7000:
		return 3      # 修仙线（资源/机缘/天劫）
	if id >= 6000:
		return 2      # 跨线互动
	if id >= 5000:
		return 3
	if id >= 3000:
		return 2      # 恋爱线 / 家庭线
	if id >= 2000:
		return 3      # 命运抉择
	if id >= 1100:
		return 4      # 修仙钥匙链 / 逆天改命
	if id >= 900:
		return 3      # 压力与寿元
	return 1

func add_text_line(content: String, rarity: int = -1) -> void:
	var new_line = text_line_scene.instantiate()
	var label = new_line.find_child("Label", true, false) as Label
	if label:
		label.text = content
		var r := rarity
		# 结局类文本自动提升为传说色
		if r < 0 and content.contains("【") and (
				content.contains("飞升") or content.contains("魔祖")
				or content.contains("轮回之主") or content.contains("坐化")
				or content.contains("天劫") or content.contains("心魔爆体")
				or content.contains("魂飞魄散") or content.contains("归隐")):
			r = 4
		if r >= 2:
			label.add_theme_color_override("font_color", EVENT_RARITY_COLORS[clampi(r, 1, 4)])
	text_list.add_child(new_line)
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func add_choose_line(content: String) -> void:
	var new_line = choose_line_scene.instantiate()
	var btn = new_line.find_child("Button", true, false) as Button
	if btn:
		btn.text = content
		btn.pressed.connect(func() -> void: _on_choose_button_pressed(btn, content))
	choose_box.add_child(new_line)
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
	_apply_choose_layout()

# 选项框自适应：按选项数量 + 文本长度决定列数与字号，避免长选项被截断
const CHOOSE_BOX_WIDTH := 880.0

func _apply_choose_layout() -> void:
	var children := choose_box.get_children()
	var n := children.size()
	if n == 0:
		return
	var max_len := 0
	for c in children:
		var b := c.find_child("Button", true, false) as Button
		if b != null:
			max_len = maxi(max_len, b.text.length())

	# 1) 列数：短文本最多 3 列，中等 2 列，长文本独占 1 列
	var cols := 1
	if max_len <= 6:
		cols = mini(n, 3)
	elif max_len <= 11:
		cols = mini(n, 2)
	choose_box.columns = maxi(1, cols)

	# 2) 字号：让最长的一条在一行内放得下（中文字宽 ≈ 字号）
	var cell_w := CHOOSE_BOX_WIDTH / float(maxi(1, cols)) - 24.0
	var fs := 40
	if max_len > 0:
		fs = clampi(int(cell_w / float(max_len)), 22, 40)
	for c in children:
		var b := c.find_child("Button", true, false) as Button
		if b == null:
			continue
		b.add_theme_font_size_override("font_size", fs)
		# 字号已到下限仍放不下时允许换行
		if max_len * fs > int(cell_w):
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _add_choice_option(text: String, choice: Dictionary) -> void:
	var new_line = choose_line_scene.instantiate()
	var btn = new_line.find_child("Button", true, false) as Button
	if btn:
		btn.text = text
		btn.pressed.connect(_on_choice_selected.bind(choice))
	choose_box.add_child(new_line)

func _clear_choices() -> void:
	for child in choose_box.get_children():
		choose_box.remove_child(child)
		child.queue_free()

# ==================== 事件权重（含天赋修正） ====================
const LOVE_CATEGORIES := ["first_love", "fall_in_love", "marry", "long_marry",
	"crush", "date", "dating", "engage", "romance", "marriage"]
const STUDY_CATEGORIES := ["baosong", "top_school", "postgrad", "dropout", "gaokao_fail", "study"]

func _get_event_weight(e: Dictionary) -> int:
	var w := int((e.weight as Callable).call())
	var cat: String = e.get("category", "")
	var is_love := LOVE_CATEGORIES.has(cat)
	var is_study := STUDY_CATEGORIES.has(cat)

	# 社交达人 T15：恋爱/婚姻事件权重 +30%，代价 学业事件权重 -20%
	if _has_talent(21):
		if is_love: w = int(w * 1.3)
		if is_study: w = int(w * 0.8)

	# 学霸 T22：学术事件权重 +50%
	if _has_talent(22) and is_study:
		w = int(w * 1.5)

	# 书香门第 T21：学业事件权重 +50%
	if _has_talent(35) and is_study:
		w = int(w * 1.5)

	# 寒门贵子 T25：学业事件权重 +30%
	if _has_talent(39) and is_study:
		w = int(w * 1.3)

	# 创业狂 T40 / 白手起家 T20：创业链权重 +50%
	if (cat == "startup" or cat == "ipo") and (_has_talent(41) or _has_talent(34)):
		w = int(w * 1.5)

	# 天煞孤星 T22：死亡权重减半，且无法触发恋爱/婚姻事件
	if _has_talent(36):
		if is_love:
			return 0
		if e.get("death", false):
			w = int(w * 0.5)

	# 铁人 / 天命之子：死亡权重减半
	if e.get("death", false):
		if _has_talent(24): w = int(w * 0.5)
		if _has_talent(51): w = int(w * 0.5)
	else:
		# 天命之子 T26：正面事件权重翻倍
		if _has_talent(51):
			var is_pos := false
			for k in e.effects:
				if int(e.effects[k]) > 0:
					is_pos = true
					break
			if is_pos:
				w = int(w * 2.0)

	# 逆天改命 T27：所有事件权重 -20%
	if _has_talent(52): w = int(w * 0.8)
	# 时间循环 T28：所有事件权重 -30%
	if _has_talent(53): w = int(w * 0.7)

	return maxi(0, w)

# ==================== 事件池 ====================
func _make_event(id, age_min, age_max, cond, weight, text, effects = {}, death = false,
		require_flags = [], set_flags = [], clear_flags = [], stress_delta = 0,
		require_status = {}, set_status = {}, once = false, category = "") -> Dictionary:
	return {
		"id": id, "age_min": age_min, "age_max": age_max,
		"cond": cond, "weight": weight, "text": text,
		"effects": effects, "death": death,
		"require_flags": require_flags,
		"set_flags": set_flags,
		"clear_flags": clear_flags,
		"stress_delta": stress_delta,
		"require_status": require_status,
		"set_status": set_status,
		"once": once,
		"category": category,
	}

func _make_choice_event(id, age_min, age_max, cond, weight, text, choices, once = false) -> Dictionary:
	return {
		"id": id, "age_min": age_min, "age_max": age_max,
		"cond": cond, "weight": weight, "text": text,
		"choices": choices, "effects": {}, "death": false,
		"require_flags": [], "set_flags": [], "clear_flags": [],
		"stress_delta": 0, "require_status": {}, "set_status": {},
		"once": once, "category": "choice",
	}

# 带随机分支的事件：chance 概率走 ok 分支，否则走 ng 分支
#   用于「表白成功率」「求婚成功率」「突破成功率」这类判定
func _make_branch_event(id, age_min, age_max, cond, weight, prompt, chance, ok_side,
		ng_side, once = false, category = "") -> Dictionary:
	var e := _make_event(id, age_min, age_max, cond, weight, prompt, {}, false,
		[], [], [], 0, {}, {}, once, category)
	e["branch"] = {"chance": chance, "ok": ok_side, "ng": ng_side}
	return e

# 结算 branch，返回带最终文本/效果/状态/标记的普通事件字典
func _apply_branch(e: Dictionary) -> Dictionary:
	var b: Dictionary = e.get("branch", {})
	var raw = b.get("chance", 0.5)
	var ch := float(raw.call()) if raw is Callable else float(raw)
	var ok := randf() < ch
	var side: Dictionary = b.get("ok" if ok else "ng", {})
	var out := e.duplicate()
	out["text"] = str(e.text) + str(side.get("text", ""))
	out["effects"] = side.get("effects", {})
	out["death"] = bool(side.get("death", false))
	out["set_flags"] = side.get("set_flags", [])
	out["clear_flags"] = side.get("clear_flags", [])
	out["set_status"] = side.get("set_status", {})
	out["stress_delta"] = int(side.get("stress", 0))
	out["func"] = side.get("func", Callable())
	out.erase("branch")
	return out

# 婚龄（用于「结婚N年」类判定）
func marriage_years() -> int:
	if marriage_age < 0:
		return 0
	return maxi(0, GlobalData.age - marriage_age)

# 子女年龄辅助（家庭线用）
func oldest_child_age() -> int:
	var m := -1
	for a in child_ages:
		m = maxi(m, int(a))
	return m

func youngest_child_age() -> int:
	if child_ages.is_empty():
		return -1
	var m := 9999
	for a in child_ages:
		m = mini(m, int(a))
	return m

# 条件辅助函数
func _cond_age_zero_low_all() -> bool:
	return (_get_stat("strong") <= 3) or (_get_stat("beauty") <= 3) or (_get_stat("money") <= 3)

func _cond_child_edu() -> bool:
	return children_count >= 1

func _cond_parents_alive() -> bool:
	return parents_alive

func _cond_startup() -> bool:
	return job_status == JobStatus.SELF_EMPLOYED

func _cond_overwork() -> bool:
	return _has_flag("overwork")

func _cond_dating_in_love() -> bool:
	return marital_status == MaritalStatus.DATING

func _cond_studious() -> bool:
	return _has_flag("studious")

func _cond_birth() -> bool:
	return (marital_status == MaritalStatus.MARRIED) and (children_count < 3)

func _cond_baosong() -> bool:
	return (_get_stat("cleverness") >= 8) and (not is_baosong) and (education_status == EducationStatus.HIGH)

func _cond_first_love_teen() -> bool:
	return (_get_stat("beauty") >= 7) and (_get_stat("emotion") >= 5) and (marital_status == MaritalStatus.SINGLE)

func _cond_dropout() -> bool:
	return (_get_stat("money") <= 2) and (education_status == EducationStatus.HIGH)

func _cond_gaokao_fail() -> bool:
	return (_get_stat("cleverness") <= 3) and (education_status == EducationStatus.HIGH) and (not is_baosong)

func _cond_top_school() -> bool:
	return (_get_stat("cleverness") >= 8) and (education_status != EducationStatus.DROPPED_OUT) and (education_status != EducationStatus.UNIVERSITY)

func _cond_fall_in_love() -> bool:
	return (_get_stat("beauty") >= 7) and (marital_status == MaritalStatus.SINGLE)

func _cond_postgrad() -> bool:
	return (_get_stat("cleverness") >= 7) and (education_status == EducationStatus.UNIVERSITY)

func _cond_unemployed_after_grad() -> bool:
	return (_get_stat("money") <= 4) and (job_status == JobStatus.STUDENT) and (education_status != EducationStatus.UNIVERSITY)

func _cond_marry() -> bool:
	return (marital_status == MaritalStatus.DATING) and (_get_stat("emotion") >= 6)

func _cond_divorce() -> bool:
	return (marital_status == MaritalStatus.MARRIED) and (_get_stat("emotion") <= 3)

func _cond_ipo() -> bool:
	return (_get_stat("money") >= 8) and (_get_stat("luck") >= 7) and (job_status == JobStatus.SELF_EMPLOYED)

func _cond_lose_job() -> bool:
	return (_get_stat("money") <= 4) and (job_status == JobStatus.EMPLOYED)

func _cond_rehire() -> bool:
	return job_status == JobStatus.UNEMPLOYED

func _cond_promote() -> bool:
	return (_get_stat("money") >= 6) and (_get_stat("cleverness") >= 6) and (job_status == JobStatus.EMPLOYED)

func _cond_chronic() -> bool:
	return (_get_stat("strong") <= 4) and (health_status == HealthStatus.HEALTHY)

func _cond_industry_leader() -> bool:
	return (_get_stat("cleverness") >= 8) and (_get_stat("money") >= 7)

func _cond_cancer() -> bool:
	return (health_status == HealthStatus.CHRONIC) and (_get_stat("strong") <= 3)

func _cond_chronic_old() -> bool:
	return health_status == HealthStatus.HEALTHY

func _cond_serious_ill() -> bool:
	return (health_status == HealthStatus.CHRONIC) and (_get_stat("strong") <= 3)

func _cond_fall_old() -> bool:
	return (health_status == HealthStatus.CHRONIC) and (_get_stat("strong") <= 2)

func _cond_travel_retire() -> bool:
	return (_get_stat("money") >= 7) and (_get_stat("emotion") >= 7)

func _cond_grandchild() -> bool:
	return children_count >= 1

func _cond_child_leave() -> bool:
	return children_count >= 1

func _cond_peaceful_death() -> bool:
	return (GlobalData.age >= 80) and (_get_stat("strong") <= 3)

func _cond_longevity() -> bool:
	return (GlobalData.age >= 90) and (_get_stat("strong") >= 7) and (_get_stat("luck") >= 7)

func _cond_centenarian() -> bool:
	return GlobalData.age >= 100

func _cond_stress_warn() -> bool:
	return (stress >= 4) and (stress < 8)

func _cond_stress_checkup() -> bool:
	return stress >= 6

func _cond_stress_collapse_old() -> bool:
	return (stress >= 7) and (_get_stat("strong") <= 3)

func _cond_stress_collapse_mid() -> bool:
	return (stress >= 8) and (_get_stat("strong") <= 4)

func _cond_overwork_hospital() -> bool:
	return stress >= 5

func _cond_parents_death() -> bool:
	return parents_alive and (GlobalData.age >= 50)

func _cond_low_luck_teen() -> bool:
	return _get_stat("luck") <= 0

func _cond_low_luck_strong() -> bool:
	return (_get_stat("luck") <= 0) and (_get_stat("strong") <= 2)

func _cond_weak_or_ugly() -> bool:
	return (_get_stat("strong") <= 3) or (_get_stat("beauty") <= 3)

func _cond_parents_conflict_divorce() -> bool:
	return (_get_stat("emotion") <= 3) and (not parents_divorced) and _has_flag("parents_conflict")

func _cond_wealth_free() -> bool:
	return _get_stat("money") >= 9

func _cond_fraud_old() -> bool:
	return (_get_stat("luck") <= 2) and (_get_stat("money") <= 4)

func _cond_poor_stuck() -> bool:
	return (_get_stat("money") <= 3) and (_get_stat("luck") <= 3)

func _cond_teen_depress() -> bool:
	return _get_stat("emotion") <= 2

func _cond_midlife_crisis() -> bool:
	return _get_stat("emotion") <= 4

func _cond_marriage_cold() -> bool:
	return marital_status == MaritalStatus.MARRIED

func _init_event_pool() -> void:
	event_pool = [
		# ==================== 0 岁 ====================
		_make_event(0, 0, 0, func(): return true, func(): return 20, "你出生了。"),
		_make_event(1, 0, 0, func(): return _get_stat("strong") <= 2,
			func(): return maxi(1, int(15 - 4 * sqrt(_get_stat("strong") + _get_stat("luck") * 1.0 / 5))),
			"你天生体质不佳，胎死腹中。你死了。", {}, true),
		_make_event(2, 0, 0, func(): return _get_stat("beauty") <= 2,
			func(): return maxi(1, int(15 - 4 * sqrt(_get_stat("beauty") + _get_stat("luck") * 1.0 / 5))),
			"你长得太丑，被父母遗弃了。你死了。", {}, true),
		_make_event(3, 0, 0, func(): return _get_stat("money") <= 2,
			func(): return maxi(1, int(15 - 4 * sqrt(_get_stat("money") + _get_stat("luck") * 1.0 / 5))),
			"你家太穷了，将你弃养了。你死了。", {}, true),
		_make_event(4, 0, 0, func(): return _get_stat("money") >= 8,
			func(): return 20 + _get_stat("money") * 2,
			"你出生在富贵家庭，父母对你寄予厚望。",
			{"money": 1, "emotion": 1}),
		_make_event(5, 0, 0, func(): return _get_stat("emotion") >= 8,
			func(): return 15 + _get_stat("emotion"),
			"你出生在一个和睦的家庭，童年会很幸福。", {"emotion": 1}),
		_make_event(6, 0, 0, func(): return _get_stat("beauty") >= 8,
			func(): return 15 + _get_stat("beauty") * 2,
			"你天生漂亮，邻居都夸你像瓷娃娃。", {"beauty": 1}),
		_make_event(7, 0, 0, func(): return _get_stat("cleverness") >= 8,
			func(): return 15 + _get_stat("cleverness") * 2,
			"你从小就眼神灵动，学东西很快。", {"cleverness": 1}),
		_make_event(8, 0, 0, func(): return _get_stat("luck") >= 8,
			func(): return 12 + _get_stat("luck"),
			"你出生时天降异象，似乎被命运眷顾。", {"luck": 1}),
		_make_event(9, 0, 0, _cond_age_zero_low_all,
			func(): return 25,
			"父母虽然条件不好，但依然竭尽全力保护你。", {"emotion": 1}),
		_make_event(109, 0, 0, func(): return true, func(): return 15,
			"你出生在一个普通家庭。", {"emotion": 1}),

		# ==================== 1-3 岁 ====================
		_make_event(100, 1, 3, func(): return true, func(): return 25, "你在父母的照顾下慢慢长大。"),
		_make_event(101, 1, 3, func(): return true, func(): return 18,
			"你开始咿呀学语，跌跌撞撞地学走路。", {"strong": 1},
			false, [], [], [], 0, {}, {}, true),
		_make_event(102, 1, 3, func(): return true, func(): return 20,
			"你半夜哭闹不止，父母疲惫不堪，冲你发了火。", {"emotion": -1}),
		_make_event(103, 1, 3, func(): return true, func(): return 18,
			"你摔了一跤，磕破了膝盖。", {"strong": -1}),
		_make_event(104, 1, 3, func(): return true, func(): return 15,
			"你学会了叫爸爸妈妈，家人十分开心。", {"emotion": 1},
			false, [], [], [], 0, {}, {}, true),
		_make_event(105, 1, 3, func(): return true, func(): return 18,
			"你经常生病发烧，父母带你去医院打针。", {"strong": -1, "emotion": -1}),
		_make_event(106, 1, 3, func(): return _get_stat("strong") <= 4, func(): return 22,
			"父母带你去医院做了调理，体质慢慢好转。", {"strong": 1}),
		_make_event(107, 1, 3, func(): return _get_stat("luck") <= 3, func(): return 14,
			"你在路边捡到一枚亮晶晶的硬币，觉得很幸运。", {"luck": 1}),
		_make_event(108, 1, 3, func(): return _get_stat("emotion") <= 4, func(): return 20,
			"父母给你买了一个小玩具，你开心极了。", {"emotion": 1}),
		_make_event(10, 1, 3, func(): return _get_stat("strong") <= 3,
			func(): return maxi(1, 20 - _get_stat("strong") * 4),
			"你体弱多病，经常往医院跑。", {"strong": -1, "emotion": -1}),
		_make_event(11, 1, 3, func(): return _get_stat("cleverness") >= 7,
			func(): return maxi(1, _get_stat("cleverness") * 2),
			"你开口说话很早，能背下不少古诗。", {"cleverness": 1}),
		_make_event(12, 1, 3, func(): return _get_stat("beauty") >= 7,
			func(): return maxi(1, _get_stat("beauty") * 2),
			"你长得可爱，亲戚们都很喜欢你。", {"beauty": 1}),
		_make_event(13, 1, 3, func(): return _get_stat("money") <= 2, func(): return 15,
			"家里条件不好，你经常吃不饱。", {"strong": -1, "emotion": -1}),
		_make_event(14, 1, 3, func(): return true, func(): return 12,
			"父母经常争吵，你变得沉默。", {"emotion": -1},
			false, [], [], [], 0, {}, {}, false, "parents_conflict"),
		_make_event(15, 1, 3, _cond_low_luck_teen, func(): return 4,
			"你意外走失，再也没有回来。你死了。", {}, true),
		_make_event(16, 1, 3, func(): return _get_stat("luck") >= 7,
			func(): return maxi(1, _get_stat("luck") * 2),
			"你在路边捡到一笔钱，父母给你买了玩具。", {"money": 1}),
		_make_event(17, 1, 3, func(): return true, func(): return 15,
			"你被父母严厉地打骂了一顿。", {"emotion": -1}),

		# ==================== 4-6 岁 ====================
		_make_event(110, 4, 6, func(): return true, func(): return 25, "你上了幼儿园，每天和小伙伴一起玩耍。"),
		_make_event(111, 4, 6, func(): return true, func(): return 18,
			"你开始学写字、学数数，慢慢长大。", {"cleverness": 1},
			false, [], [], [], 0, {}, {}, true),
		_make_event(112, 4, 6, func(): return true, func(): return 20,
			"你在幼儿园被小朋友抢走了玩具，哭了一下午。", {"emotion": -1}),
		_make_event(113, 4, 6, func(): return true, func(): return 18,
			"你挑食被父母逼着吃饭，委屈极了。", {"emotion": -1, "strong": -1}),
		_make_event(114, 4, 6, func(): return true, func(): return 15,
			"你迷上了动画片，每天准时守在电视机前。", {"emotion": 1}),
		_make_event(115, 4, 6, func(): return true, func(): return 16,
			"你从滑梯上摔了下来，磕破了头。", {"strong": -1}),
		_make_event(116, 4, 6, func(): return _get_stat("strong") <= 4, func(): return 20,
			"父母带你去乡下玩，你每天跑跑跳跳，身体好了不少。", {"strong": 1}),
		_make_event(117, 4, 6, func(): return _get_stat("luck") <= 3, func(): return 14,
			"你在公园里捡到一只四叶草，据说能带来好运。", {"luck": 1}),
		_make_event(118, 4, 6, func(): return _get_stat("cleverness") >= 7, func(): return 15,
			"你光顾着玩，把幼儿园学的东西都忘了。", {"cleverness": -1}),
		_make_event(119, 4, 6, func(): return _get_stat("beauty") >= 7, func(): return 15,
			"你在外面疯玩，晒黑了不少。", {"beauty": -1}),
		_make_event(20, 4, 6, func(): return _get_stat("cleverness") >= 7,
			func(): return maxi(1, _get_stat("cleverness") * 2),
			"你已经能独立阅读儿童读物。", {"cleverness": 1}),
		_make_event(21, 4, 6, func(): return _get_stat("strong") <= 3, func(): return 18,
			"你免疫力很差，三天两头感冒。", {"strong": -1, "emotion": -1}),
		_make_event(22, 4, 6, func(): return _get_stat("money") >= 7,
			func(): return maxi(1, _get_stat("money") * 2),
			"你进入了一所昂贵的幼儿园。", {"cleverness": 1}),
		_make_event(23, 4, 6, func(): return _get_stat("beauty") >= 8,
			func(): return maxi(1, _get_stat("beauty") * 2),
			"你被星探看中，拍了人生第一支广告。", {"money": 1, "beauty": 1}),
		_make_event(24, 4, 6, _cond_parents_conflict_divorce, func(): return 15,
			"父母离婚了，你跟着其中一方生活。", {"emotion": -1},
			false, [], ["parents_divorced_real"], [], 0, {}, {}, true, "parents_divorce"),
		_make_event(25, 4, 6, _cond_low_luck_strong, func(): return 4,
			"你偷偷去水边玩，不幸溺水。你死了。", {}, true),
		_make_event(26, 4, 6, func(): return true, func(): return 15,
			"你被同班小朋友嘲笑，心里很难过。", {"emotion": -1}),

		_make_choice_event(2000, 4, 6, func(): return true, func(): return 18,
			"幼儿园里，小伙伴想玩你最喜欢的玩具。",
			[
				{"text": "大方分享", "result": "你们成了好朋友。",
				 "effects": {"emotion": 1, "luck": 1}},
				{"text": "紧紧抱住不放手", "result": "你失去了一个朋友。",
				 "effects": {"emotion": -1}},
			]),

		_make_choice_event(2007, 4, 6, func(): return true, func(): return 16,
			"父母问你想不想学游泳。",
			[
				{"text": "想学", "result": "你学会了游泳，身体越来越结实。",
				 "effects": {"strong": 1}, "set_flags": ["sporty"]},
				{"text": "不想学", "result": "你留在家里看动画片。",
				 "effects": {"emotion": 1}},
			]),

		# ==================== 7-12 岁 ====================
		_make_event(120, 7, 12, func(): return true, func(): return 25, "你在小学里按部就班地上课、写作业。"),
		_make_event(121, 7, 12, func(): return true, func(): return 18,
			"你交到了几个好朋友，一起上下学。", {"emotion": 1}),
		_make_event(122, 7, 12, func(): return true, func(): return 20,
			"你考试没考好，被父母狠狠训斥了一顿。", {"emotion": -1}),
		_make_event(123, 7, 12, func(): return true, func(): return 18,
			"你作业写到深夜，第二天上课直打瞌睡。", {"strong": -1, "cleverness": -1}),
		_make_event(124, 7, 12, func(): return true, func(): return 15,
			"你参加了一次学校组织的春游，玩得很开心。", {"emotion": 1}),
		_make_event(125, 7, 12, func(): return true, func(): return 15,
			"你因为身材被同学起了难听的外号。", {"emotion": -1}),
		_make_event(126, 7, 12, func(): return _get_stat("strong") <= 4, func(): return 20,
			"你被父母送去学游泳，身体越来越结实。", {"strong": 1}),
		_make_event(127, 7, 12, func(): return _get_stat("luck") <= 3, func(): return 14,
			"你帮助了一位老奶奶过马路，她夸你是个好孩子。", {"luck": 1, "emotion": 1}),
		_make_event(128, 7, 12, func(): return _get_stat("cleverness") >= 7, func(): return 15,
			"你沉迷漫画书，上课偷偷看，被老师没收了。", {"cleverness": -1}),
		_make_event(129, 7, 12, func(): return _get_stat("beauty") >= 7, func(): return 15,
			"你长胖了不少，被同学开玩笑。", {"beauty": -1}),
		_make_event(30, 7, 12, func(): return _get_stat("cleverness") >= 7,
			func(): return maxi(1, _get_stat("cleverness") * 2),
			"你成绩名列前茅，老师很喜欢你。", {"cleverness": 1}),
		_make_event(31, 7, 12, func(): return _get_stat("strong") <= 3, func(): return 18,
			"你体育测试总是不及格，被同学嘲笑。", {"strong": -1, "emotion": -1}),
		_make_event(32, 7, 12, _cond_weak_or_ugly, func(): return 15,
			"你被同学欺负，却不敢告诉家长。", {"emotion": -1},
			false, [], ["bullied"], [], 0, {}, {}, true),
		_make_event(33, 7, 12, func(): return _get_stat("beauty") >= 8,
			func(): return maxi(1, _get_stat("beauty") * 2),
			"你成了学校里的风云人物。", {"beauty": 1}),
		_make_event(34, 7, 12, func(): return _get_stat("money") <= 2, func(): return 12,
			"家里生意失败，你被迫转学。", {"money": -1, "emotion": -1}),
		_make_event(35, 7, 12, _cond_low_luck_teen, func(): return 4,
			"你放学路上遭遇车祸。你死了。", {}, true),
		_make_event(36, 7, 12, func(): return _get_stat("luck") >= 8,
			func(): return maxi(1, _get_stat("luck") * 2),
			"家里随手买的彩票中了大奖。", {"money": 2}),
		_make_event(37, 7, 12, func(): return _get_stat("emotion") >= 7,
			func(): return 10, "你被选为班长，成了老师的小助手。", {"cleverness": 1, "emotion": 1}),
		_make_event(38, 7, 12, func(): return _get_stat("cleverness") >= 5, func(): return 15,
			"你沉迷电子游戏，成绩一落千丈。", {"cleverness": -1}),

		_make_choice_event(2001, 7, 12, func(): return true, func(): return 18,
			"你发现同桌考试时偷偷作弊。",
			[
				{"text": "告诉老师", "result": "同桌被批评，你被孤立了一阵。",
				 "effects": {"cleverness": 1, "emotion": -1}},
				{"text": "装作没看见", "result": "同桌请你吃了一根冰棍。",
				 "effects": {"emotion": 1, "cleverness": -1}},
			]),

		# ==================== 13-18 岁 ====================
		_make_event(130, 13, 18, func(): return true, func(): return 25, "你在中学里埋头读书，日子平淡而充实。"),
		_make_event(131, 13, 18, func(): return true, func(): return 18, "你迷上了某个爱好，投入了不少时间。", {"emotion": 1}),
		_make_event(132, 13, 18, func(): return true, func(): return 20,
			"你和父母大吵一架，冷战了很久。", {"emotion": -1}),
		_make_event(133, 13, 18, func(): return true, func(): return 18,
			"你被同学孤立，没人愿意和你说话。", {"emotion": -1}),
		_make_event(134, 13, 18, func(): return true, func(): return 15,
			"你和同学们一起为考试努力，互相打气。", {"cleverness": 1}),
		_make_event(135, 13, 18, func(): return true, func(): return 16,
			"你熬夜刷题，身体越来越差。", {"strong": -1}, false, [], [], [], 1),
		_make_event(136, 13, 18, func(): return _get_stat("strong") <= 4, func(): return 20,
			"你开始坚持晨跑，体质慢慢变好了。", {"strong": 1}),
		_make_event(137, 13, 18, func(): return _get_stat("luck") <= 3, func(): return 14,
			"你参加志愿者活动，认识了很多善良的人。", {"luck": 1, "emotion": 1}),
		_make_event(138, 13, 18, func(): return _get_stat("cleverness") >= 7, func(): return 15,
			"你上课看小说被老师发现，请了家长。", {"cleverness": -1, "emotion": -1}),
		_make_event(139, 13, 18, func(): return _get_stat("beauty") >= 7, func(): return 15,
			"你熬夜爆痘，颜值下降了不少。", {"beauty": -1}),
		_make_event(50, 13, 18, _cond_baosong, func(): return maxi(1, _get_stat("cleverness") * 2),
			"你在竞赛中获奖，获得保送资格。", {"cleverness": 2},
			false, [], [], [], 0,
			{"education": EducationStatus.HIGH},
			{"is_baosong": true}, true, "baosong"),
		_make_event(51, 13, 18, func(): return _get_stat("strong") >= 8,
			func(): return maxi(1, _get_stat("strong") * 2),
			"你被教练看中，成为体育特长生。", {"strong": 1}),
		_make_event(52, 13, 18, _cond_first_love_teen, func(): return maxi(1, _get_stat("beauty") * 2),
			"你收到很多情书，开始偷偷恋爱。", {"emotion": 1},
			false, [], ["in_love"], [], 0, {}, {"marital": MaritalStatus.DATING}, true, "first_love"),
		_make_event(53, 13, 18, _cond_dropout, func(): return 15,
			"家里供不起你读书，你只能辍学打工。", {"money": 1, "emotion": -1},
			false, [], [], [], 0, {"education": EducationStatus.HIGH},
			{"education": EducationStatus.DROPPED_OUT, "job": JobStatus.EMPLOYED}, true, "dropout"),
		_make_event(54, 13, 18, _cond_teen_depress, func(): return 15,
			"你长期情绪低落，被诊断出抑郁。", {"emotion": -2, "strong": -1},
			false, [], [], [], 0, {}, {}, true),
		_make_event(55, 13, 18, _cond_gaokao_fail, func(): return 15,
			"你高考失利，未来变得迷茫。", {"emotion": -1},
			false, [], [], [], 0, {"education": EducationStatus.HIGH},
			{"education": EducationStatus.GRADUATED}, true, "gaokao_fail"),
		_make_event(56, 13, 18, _cond_low_luck_teen, func(): return 4,
			"你遭遇了一场意外。你死了。", {}, true),
		_make_event(57, 13, 18, func(): return _get_stat("beauty") >= 9,
			func(): return maxi(1, _get_stat("beauty") * 2),
			"你因短视频走红，赚到第一桶金。", {"money": 2, "beauty": 1},
			false, [], [], [], 0, {}, {}, true),
		_make_event(58, 13, 18, func(): return true, func(): return 12,
			"你早恋被发现，手机被没收。", {"emotion": -1}),

		_make_choice_event(2002, 13, 18, func(): return marital_status == MaritalStatus.SINGLE, func(): return 18,
			"你收到一封匿名情书。",
			[
				{"text": "赴约", "result": "你开始了一段青涩的恋爱。",
				 "effects": {"emotion": 2, "cleverness": -1}, "set_flags": ["in_love"],
				 "set_status": {"marital": MaritalStatus.DATING}},
				{"text": "投入学习", "result": "你成绩突飞猛进。",
				 "effects": {"cleverness": 2, "emotion": -1}, "set_flags": ["studious"]},
			]),

		# ==================== 19-25 岁 ====================
		_make_event(140, 19, 25, func(): return education_status != EducationStatus.DROPPED_OUT,
			func(): return 25,
			"你进入了大学或社会工作，开始独立生活。",
			{}, false, [], [], [], 0, {}, {"living": LivingStatus.ALONE}),
		_make_event(141, 19, 25, func(): return true, func(): return 18,
			"你结识了一些新朋友，眼界开阔了不少。", {"emotion": 1}),
		_make_event(142, 19, 25, func(): return true, func(): return 20,
			"你工作压力巨大，经常失眠到深夜。", {"emotion": -1, "strong": -1}, false, [], [], [], 1),
		_make_event(143, 19, 25, func(): return true, func(): return 18,
			"你被领导当众批评，无地自容。", {"emotion": -1}),
		_make_event(144, 19, 25, func(): return true, func(): return 15,
			"你为了未来努力工作、学习，慢慢成长。", {"cleverness": 1}),
		_make_event(145, 19, 25, func(): return marital_status == MaritalStatus.DATING, func(): return 16,
			"你和恋人分手，消沉了很久。", {"emotion": -1},
			false, [], [], [], 0, {}, {"marital": MaritalStatus.SINGLE}),
		_make_event(146, 19, 25, func(): return _get_stat("strong") <= 4, func(): return 20,
			"你办了健身卡，坚持锻炼，身体越来越好。", {"strong": 1}),
		_make_event(147, 19, 25, func(): return _get_stat("luck") <= 3, func(): return 14,
			"你在公交车上让座，对方送了你一张彩票。", {"luck": 1}),
		_make_event(148, 19, 25, func(): return _get_stat("cleverness") >= 7, func(): return 15,
			"你沉迷短视频，注意力越来越难集中。", {"cleverness": -1}),
		_make_event(149, 19, 25, func(): return _get_stat("beauty") >= 7, func(): return 15,
			"你作息紊乱，皮肤状态越来越差。", {"beauty": -1}),
		_make_event(70, 19, 25, _cond_top_school, func(): return maxi(1, _get_stat("cleverness") * 2),
			"你考入顶尖名校，前途一片光明。", {"cleverness": 1},
			false, [], [], [], 0, {}, {"education": EducationStatus.UNIVERSITY}, true, "top_school"),
		_make_event(71, 19, 25, func(): return _get_stat("money") >= 8,
			func(): return maxi(1, _get_stat("money") * 2),
			"你拿家里的钱开始创业。", {"money": 1, "luck": -1},
			false, [], [], [], 0, {}, {"job": JobStatus.SELF_EMPLOYED}, true, "startup"),
		_make_event(72, 19, 25, _cond_fall_in_love, func(): return maxi(1, _get_stat("beauty") * 2),
			"你遇到喜欢的人，开始一段恋情。", {"emotion": 1},
			false, [], ["in_love"], [], 0, {}, {"marital": MaritalStatus.DATING}, true, "fall_in_love"),
		_make_event(73, 19, 25, _cond_poor_stuck, func(): return 10,
			"你被朋友骗进传销，损失惨重。", {"money": -2, "emotion": -1}),
		_make_event(74, 19, 25, func(): return _get_stat("luck") >= 8,
			func(): return maxi(1, _get_stat("luck") * 2),
			"你中了大奖，一夜暴富。", {"money": 3}),
		_make_event(75, 19, 25, func(): return _get_stat("strong") <= 2, func(): return 6,
			"你长期熬夜加班，身体彻底垮了。你死了。", {}, true),
		_make_event(76, 19, 25, _cond_postgrad, func(): return maxi(1, _get_stat("cleverness") * 2),
			"你考研成功，继续深造。", {"cleverness": 1},
			false, [], [], [], 0, {"education": EducationStatus.UNIVERSITY},
			{"education": EducationStatus.GRADUATED}, true, "postgrad"),
		_make_event(77, 19, 25, _cond_unemployed_after_grad, func(): return 15,
			"你毕业后找不到工作，只能打零工。", {"money": -1, "emotion": -1},
			false, [], [], [], 0, {"job": JobStatus.STUDENT},
			{"job": JobStatus.UNEMPLOYED, "education": EducationStatus.GRADUATED}, true, "unemployed"),

		_make_choice_event(2003, 19, 25, func(): return true, func(): return 18,
			"你拿到一份高薪但加班严重的 offer。",
			[
				{"text": "接受 offer", "result": "你赚到了钱，但身体越来越差。",
				 "effects": {"money": 2, "strong": -1, "emotion": -1},
				 "set_flags": ["overwork"], "stress": 1,
				 "set_status": {"job": JobStatus.EMPLOYED}},
				{"text": "拒绝，继续深造", "result": "你决定考研，生活清贫但充实。",
				 "effects": {"cleverness": 2, "money": -1},
				 "set_flags": ["studious"],
				 "set_status": {"education": EducationStatus.UNIVERSITY}},
			]),

		# ==================== 26-35 岁 ====================
		_make_event(150, 26, 35, func(): return true, func(): return 25, "你在工作岗位上忙碌着，日子一天天过去。"),
		_make_event(151, 26, 35, func(): return true, func(): return 18, "你和朋友聚会、旅行，享受生活。", {"emotion": 1}),
		_make_event(152, 26, 35, func(): return job_status == JobStatus.EMPLOYED, func(): return 20,
			"你被同事排挤，工作很不顺心。", {"emotion": -1, "money": -1}),
		_make_event(153, 26, 35, func(): return true, func(): return 18,
			"你长期熬夜加班，头发越来越少。", {"strong": -1, "beauty": -1}, false, [], [], [], 1),
		_make_event(154, 26, 35, func(): return true, func(): return 15,
			"你努力工作，攒下了一些积蓄。", {"money": 1}),
		_make_event(155, 26, 35, _cond_marriage_cold, func(): return 16,
			"你和伴侣渐渐无话可说，婚姻变得冷淡。", {"emotion": -1}),
		_make_event(156, 26, 35, func(): return _get_stat("strong") <= 4, func(): return 20,
			"你开始注意养生，早睡早起，身体恢复了不少。", {"strong": 1}),
		_make_event(157, 26, 35, func(): return _get_stat("luck") <= 3, func(): return 14,
			"你收养了一只流浪猫，它给你带来了很多好运。", {"luck": 1, "emotion": 1}),
		_make_event(158, 26, 35, func(): return _get_stat("cleverness") >= 7, func(): return 15,
			"你长期刷手机，感觉脑子越来越不够用。", {"cleverness": -1}),
		_make_event(159, 26, 35, func(): return _get_stat("beauty") >= 7, func(): return 15,
			"你应酬太多，身材走样，颜值下降。", {"beauty": -1}),
		_make_event(80, 26, 35, _cond_promote, func(): return maxi(1, _get_stat("money") * 2),
			"你升职加薪，事业进入上升期。", {"money": 2},
			false, [], [], [], 0, {}, {"income_add": 1}, true),
		_make_event(81, 26, 35, func(): return _get_stat("money") >= 7,
			func(): return maxi(1, _get_stat("money") * 2),
			"你终于买下属于自己的房子。", {"money": -1, "emotion": 1}),
		_make_event(82, 26, 35, _cond_marry, func(): return maxi(1, _get_stat("emotion") * 2),
			"你与爱人步入婚姻，生活幸福。", {"emotion": 2},
			false, [], [], [], 0, {"marital": MaritalStatus.DATING},
			{"marital": MaritalStatus.MARRIED, "living": LivingStatus.WITH_PARTNER}, true, "marry"),
		_make_event(83, 26, 35, _cond_divorce, func(): return 12,
			"你的婚姻破裂，最终离婚。", {"emotion": -1, "money": -1},
			false, [], [], [], 0, {"marital": MaritalStatus.MARRIED},
			{"marital": MaritalStatus.DIVORCED}, false, "divorce"),
		_make_event(84, 26, 35, _cond_poor_stuck, func(): return 10,
			"你投资失败，欠下债务。", {"money": -2, "emotion": -1}),
		_make_event(85, 26, 35, func(): return _get_stat("strong") <= 2, func(): return 6,
			"你连续加班后倒在工作岗位上。你死了。", {}, true),
		_make_event(86, 26, 35, _cond_ipo, func(): return maxi(1, _get_stat("money") * 2),
			"你的公司成功上市，实现财务自由。", {"money": 3},
			false, [], [], [], 0, {}, {"income_add": 5}, true, "ipo"),
		_make_event(87, 26, 35, _cond_lose_job, func(): return 15,
			"你失业了，只能靠积蓄度日。", {"money": -1, "emotion": -1},
			false, [], [], [], 0, {"job": JobStatus.EMPLOYED},
			{"job": JobStatus.UNEMPLOYED}, false, "lose_job"),
		_make_event(88, 26, 50, _cond_rehire, func(): return 20,
			"你重新找到了一份工作，生活重回正轨。", {"money": 1, "emotion": 1},
			false, [], [], [], 0, {"job": JobStatus.UNEMPLOYED},
			{"job": JobStatus.EMPLOYED}),

		_make_event(1000, 26, 35, _cond_birth, func(): return 15,
			"你迎来了自己的孩子，家庭更加完整。", {"emotion": 2},
			false, [], [], [], 0, {}, {"children_add": 1, "living": LivingStatus.WITH_CHILDREN}, true, "birth"),

		_make_choice_event(2004, 26, 35, func(): return job_status == JobStatus.EMPLOYED, func(): return 18,
			"朋友邀请你合伙创业，需要投入全部积蓄。",
			[
				{"text": "加入", "result": "公司起步艰难，你压力巨大。",
				 "effects": {"money": -1, "emotion": -1, "luck": 1},
				 "set_flags": ["startup"], "stress": 1,
				 "set_status": {"job": JobStatus.SELF_EMPLOYED}},
				{"text": "拒绝，保住稳定工作", "result": "你继续过着朝九晚五的生活。",
				 "effects": {"emotion": 1}},
			]),

		# ==================== 36-50 岁 ====================
		_make_event(160, 36, 50, func(): return true, func(): return 25, "你步入中年，生活按部就班地进行着。"),
		_make_event(161, 36, 50, func(): return true, func(): return 18,
			"你开始注重养生，作息规律了不少。", {"strong": 1}),
		_make_event(162, 36, 50, func(): return true, func(): return 20,
			"你被年轻同事取代，感到力不从心。", {"emotion": -1}),
		_make_event(163, 36, 50, _cond_parents_alive, func(): return 18,
			"父母生病需要照顾，你焦头烂额。", {"emotion": -1, "strong": -1}),
		_make_event(164, 36, 50, func(): return true, func(): return 15,
			"你和家人一起度过了平静的一年。", {"emotion": 1}),
		_make_event(165, 36, 50, func(): return true, func(): return 16,
			"你的腰腿开始出现问题，常年疼痛。", {"strong": -1}),
		_make_event(166, 36, 50, func(): return _get_stat("strong") <= 4, func(): return 22,
			"你开始每天打太极、散步，身体慢慢好转。", {"strong": 1}),
		_make_event(167, 36, 50, func(): return _get_stat("luck") <= 3, func(): return 14,
			"你帮助了一位迷路的老人，他家人送来锦旗。", {"luck": 1, "emotion": 1}),
		_make_event(168, 36, 50, func(): return _get_stat("cleverness") >= 7, func(): return 15,
			"你长期不学习新东西，思维越来越僵化。", {"cleverness": -1}),
		_make_event(169, 36, 50, func(): return _get_stat("beauty") >= 7, func(): return 15,
			"你疏于打理自己，看起来比实际年龄老。", {"beauty": -1}),
		_make_event(90, 36, 50, _cond_wealth_free, func(): return maxi(1, _get_stat("money") * 2),
			"你实现财务自由，开始享受生活。", {"emotion": 2}),
		_make_event(91, 36, 50, _cond_chronic, func(): return 18,
			"你查出高血压、高血脂、高血糖。", {"strong": -1, "emotion": -1},
			false, [], [], [], 0, {"health": HealthStatus.HEALTHY},
			{"health": HealthStatus.CHRONIC}, true, "chronic"),
		_make_event(92, 36, 50, _cond_industry_leader, func(): return maxi(1, _get_stat("cleverness") * 2),
			"你成为行业里举足轻重的人物。", {"money": 1, "emotion": 1}),
		_make_event(93, 36, 50, _cond_midlife_crisis, func(): return 15,
			"你陷入中年危机，对一切失去兴趣。", {"emotion": -1}),
		_make_event(94, 36, 50, func(): return _get_stat("money") <= 2, func(): return 10,
			"你生意失败，宣告破产。", {"money": -2, "emotion": -1}),
		_make_event(95, 36, 50, _cond_cancer, func(): return 8,
			"你的慢性病恶化，被查出癌症晚期。你死了。", {}, true,
			[], [], [], 0, {"health": HealthStatus.CHRONIC}, {}, true, "cancer"),
		_make_event(96, 36, 50, func(): return _get_stat("emotion") >= 8,
			func(): return maxi(1, _get_stat("emotion") * 2),
			"子女孝顺，家庭和睦，你感到满足。", {"emotion": 2}),

		_make_event(1001, 36, 50, _cond_child_edu, func(): return 20,
			"你为孩子的教育问题操碎了心。", {"emotion": -1},
			false, [], [], [], 0, {}, {}, true, "child_edu"),

		_make_choice_event(2005, 36, 50, func(): return true, func(): return 18,
			"医生警告你需要注意身体，但工作正处于关键期。",
			[
				{"text": "加班冲刺", "result": "项目成功了，你的身体却垮了。",
				 "effects": {"money": 2, "strong": -2, "emotion": -1}, "stress": 2},
				{"text": "请假休养", "result": "你失去了升职机会，但身体恢复了。",
				 "effects": {"money": -1, "strong": 1, "emotion": 1}, "stress": -2},
			]),

		# ==================== 51-65 岁 ====================
		_make_event(170, 51, 65, func(): return true, func(): return 12,
			"你逐渐放慢脚步，享受退休前后的生活。",
			{}, false, [], [], [], 0, {}, {}, true),
		_make_event(171, 51, 65, func(): return true, func(): return 12,
			"你每天散步、下棋，日子过得悠闲。", {"strong": 1}),
		_make_event(172, 51, 65, _cond_chronic_old, func(): return 20,
			"你被查出慢性病，需要长期服药。", {"strong": -1, "emotion": -1},
			false, [], [], [], 0, {"health": HealthStatus.HEALTHY},
			{"health": HealthStatus.CHRONIC}, true, "chronic_old"),
		_make_event(173, 51, 65, func(): return true, func(): return 12,
			"子女很少回家，你感到孤独。", {"emotion": -1}),
		_make_event(174, 51, 65, _cond_grandchild, func(): return 15,
			"你开始帮忙照顾孙辈，尽享天伦之乐。", {"emotion": 1}),
		_make_event(175, 51, 65, func(): return true, func(): return 12,
			"老朋友一个个离开，你感到伤感。", {"emotion": -1}),
		_make_event(176, 51, 65, func(): return _get_stat("strong") <= 4, func(): return 22,
			"你坚持每天晨练，身体比前几年还好。", {"strong": 1}),
		_make_event(177, 51, 65, func(): return _get_stat("luck") <= 3, func(): return 14,
			"你在公园里救了一只受伤的小鸟，心情很好。", {"luck": 1, "emotion": 1}),
		_make_event(178, 51, 65, func(): return _get_stat("cleverness") >= 7, func(): return 15,
			"你很少动脑，记忆力明显下降。", {"cleverness": -1}),
		_make_event(220, 51, 65, func(): return true, func(): return 10,
			"你参加了一场老同学聚会，回忆青春。", {"emotion": 1},
			false, [], [], [], 0, {}, {}, true),
		_make_event(221, 51, 65, func(): return true, func(): return 10,
			"你开始学习书法，日子过得充实。", {"cleverness": 1},
			false, [], [], [], 0, {}, {}, true),
		_make_event(222, 51, 65, func(): return true, func(): return 10,
			"你带老伴去了一趟年轻时想去的地方。", {"emotion": 2},
			false, [], [], [], 0, {}, {}, true),
		_make_event(223, 51, 65, func(): return true, func(): return 10,
			"你迷上了广场舞，认识了不少新朋友。", {"strong": 1, "emotion": 1},
			false, [], [], [], 0, {}, {}, true),
		_make_event(180, 51, 65, _cond_travel_retire, func(): return maxi(1, _get_stat("money") * 2),
			"你退休后四处旅游，生活惬意。", {"emotion": 2}),
		_make_event(181, 51, 65, _cond_serious_ill, func(): return 12,
			"你的慢性病突然加重，没能抢救过来。你死了。", {}, true,
			[], [], [], 0, {"health": HealthStatus.CHRONIC}, {}, true, "serious_ill"),
		_make_event(182, 51, 65, _cond_fraud_old, func(): return 10,
			"你被诈骗团伙骗走养老金。", {"money": -2, "emotion": -1}),
		_make_event(183, 51, 65, func(): return _get_stat("strong") >= 8,
			func(): return maxi(1, _get_stat("strong") * 2),
			"你身体硬朗，比同龄人年轻很多。", {"strong": 1}),
		_make_event(184, 51, 65, func(): return _get_stat("emotion") >= 8,
			func(): return maxi(1, _get_stat("emotion") * 2),
			"子女经常回来看你，你很欣慰。", {"emotion": 2}),
		_make_event(185, 51, 65, _cond_fall_old, func(): return 8,
			"你意外摔倒，引发并发症。你死了。", {}, true),

		_make_event(1002, 51, 65, _cond_child_leave, func(): return 18,
			"子女长大成人，离开家去闯荡。", {"emotion": -1},
			false, [], [], [], 0, {}, {}, true, "child_leave"),
		_make_event(1003, 51, 65, _cond_grandchild, func(): return 18,
			"你的孙辈出生了，你升级为祖辈。", {"emotion": 2},
			false, [], [], [], 0, {}, {}, true, "grandchild"),

		_make_choice_event(2006, 51, 65, func(): return true, func(): return 18,
			"你退休了，孩子邀请你搬去同住。",
			[
				{"text": "搬去和孩子住", "result": "你享受天伦之乐，但失去了自己的空间。",
				 "effects": {"emotion": 1, "strong": -1},
				 "set_status": {"living": LivingStatus.WITH_CHILDREN}},
				{"text": "留在老房子", "result": "你独自生活，孤独但自由。",
				 "effects": {"emotion": -1, "strong": 1},
				 "set_status": {"living": LivingStatus.ALONE}},
			], true),

		# ==================== 66 岁以上 ====================
		_make_event(190, 66, 200, func(): return true, func(): return 12,
			"你安享晚年，日子平静而缓慢。",
			{}, false, [], [], [], 0, {}, {}, true),
		_make_event(191, 66, 200, func(): return true, func(): return 12,
			"你经常在公园里晒太阳，和同龄人聊天。", {"emotion": 1}),
		_make_event(192, 66, 200, func(): return true, func(): return 18,
			"你身体越来越差，行动越来越不便。", {"strong": -1, "emotion": -1}),
		_make_event(193, 66, 200, func(): return true, func(): return 12,
			"你常常感到孤独，没人说话。", {"emotion": -1}),
		_make_event(194, 66, 200, func(): return true, func(): return 12,
			"你坚持锻炼，身体还算硬朗。", {"strong": 1}),
		_make_event(195, 66, 200, func(): return true, func(): return 16,
			"你摔了一跤，卧床休养了很久。", {"strong": -1, "emotion": -1}),
		_make_event(196, 66, 200, func(): return _get_stat("strong") <= 4, func(): return 22,
			"儿女带你去做了一次全面体检，调理后身体好转。", {"strong": 1}),
		_make_event(197, 66, 200, func(): return _get_stat("luck") <= 3, func(): return 14,
			"你随手买了一注彩票，竟然中了小奖。", {"luck": 1, "money": 1}),
		_make_event(230, 66, 200, func(): return true, func(): return 10,
			"你开始养花种草，日子过得有滋有味。", {"emotion": 1},
			false, [], [], [], 0, {}, {}, true),
		_make_event(231, 66, 200, func(): return true, func(): return 10,
			"你写下了自己的人生回忆录。", {"cleverness": 1, "emotion": 1},
			false, [], [], [], 0, {}, {}, true),
		_make_event(232, 66, 200, func(): return true, func(): return 10,
			"你迷上了听戏，每天守着收音机。", {"emotion": 1},
			false, [], [], [], 0, {}, {}, true),
		_make_event(200, 66, 200, _cond_peaceful_death, func(): return 8 + GlobalData.age / 15,
			"你在睡梦中安详离世。你死了。", {}, true),
		_make_event(201, 66, 200, _cond_longevity, func(): return maxi(1, _get_stat("strong") * 2),
			"你成为远近闻名的长寿老人。", {"emotion": 2}),
		_make_event(202, 66, 200, func(): return _get_stat("cleverness") <= 3, func(): return 15,
			"你记忆力越来越差，患上老年痴呆。", {"cleverness": -2, "emotion": -1}),
		_make_event(203, 66, 200, func(): return _get_stat("emotion") >= 8,
			func(): return maxi(1, _get_stat("emotion") * 2),
			"儿孙满堂，你度过幸福的晚年。", {"emotion": 2}),
		_make_event(204, 66, 200, _cond_centenarian, func(): return 20,
			"你走完漫长的一生，寿终正寝。你死了。", {}, true),
		_make_event(205, 66, 200, func(): return _get_stat("strong") <= 4, func(): return 15,
			"你疾病缠身，常年卧床。", {"strong": -1, "emotion": -1},
			false, [], [], [], 0, {}, {"health": HealthStatus.BEDRIDDEN}),
		_make_event(206, 66, 200, func(): return _get_stat("strong") >= 6, func(): return 10,
			"你每天早起打太极，精神矍铄。", {"strong": 1}),

		# ==================== 压力与健康铺垫 ====================
		_make_event(900, 26, 200, _cond_stress_warn, func(): return 18,
			"你经常感到疲惫，夜里睡不踏实，但没当回事。", {}, false, [], [], [], 0),
		_make_event(901, 36, 200, _cond_stress_checkup, func(): return 15,
			"体检报告亮起红灯，医生让你立刻休息。", {"strong": -1},
			false, [], ["sick"], [], 0),
		_make_event(902, 51, 200, _cond_stress_collapse_old, func(): return 12,
			"你长期透支的身体终于撑不住了，倒在了家中。你死了。", {}, true),
		_make_event(903, 40, 200, _cond_stress_collapse_mid, func(): return 10,
			"多年的劳累一次性爆发，你倒下了。你死了。", {}, true),

		_make_event(904, 26, 50, func(): return stress >= 3, func(): return 18,
			"你请了年假，去海边放松了一周。", {"emotion": 1}, false, [], [], [], -2),
		_make_event(905, 26, 50, func(): return stress >= 4, func(): return 16,
			"你约朋友喝酒聊天，把烦恼都说了出来。", {"emotion": 1}, false, [], [], [], -1),
		_make_event(906, 36, 65, func(): return stress >= 3, func(): return 15,
			"你开始练习冥想，心态平和了不少。", {"emotion": 1}, false, [], [], [], -1),

		# ==================== 因果链：运动 ====================
		_make_event(910, 13, 18, func(): return true, func(): return 25,
			"你从小就有的运动习惯让你每天坚持晨跑。", {"strong": 1},
			false, ["sporty"], [], [], 0),
		_make_event(911, 19, 25, func(): return true, func(): return 22,
			"你参加了一场半程马拉松，顺利完赛。", {"strong": 1, "emotion": 1},
			false, ["sporty"]),
		_make_event(912, 36, 50, func(): return true, func(): return 22,
			"多年坚持锻炼，你比同龄人年轻很多。", {"strong": 1, "emotion": 1},
			false, ["sporty"]),
		_make_event(913, 66, 200, func(): return true, func(): return 20,
			"你一辈子坚持锻炼，晚年依然精神矍铄。", {"strong": 1, "emotion": 1},
			false, ["sporty"]),

		# ==================== 因果链：加班 ====================
		_make_event(920, 26, 35, _cond_overwork, func(): return 25,
			"你每天加班到深夜，身体开始抗议。", {"emotion": -1},
			false, [], [], [], 1),
		_make_event(921, 36, 50, _cond_overwork_hospital, func(): return 20,
			"长期加班让你积劳成疾，不得不住院治疗。", {"strong": -2, "money": -1},
			false, ["overwork"], [], [], 0),

		# ==================== 因果链：被欺负 ====================
		_make_event(930, 13, 18, func(): return true, func(): return 20,
			"童年被欺负的经历让你暗下决心要变强，你开始锻炼。", {"strong": 1, "emotion": -1},
			false, ["bullied"], ["sporty"]),
		_make_event(931, 19, 25, func(): return true, func(): return 15,
			"你性格依然内向，不太擅长与人打交道。", {"emotion": -1},
			false, ["bullied"]),

		# ==================== 因果链：恋爱 ====================
		_make_event(940, 19, 25, _cond_dating_in_love, func(): return 20,
			"你和恋人感情稳定，一起规划未来。", {"emotion": 2},
			false, ["in_love"], [], [], 0, {"marital": MaritalStatus.DATING}),
		_make_event(941, 26, 35, _cond_dating_in_love, func(): return 20,
			"你和相恋多年的恋人步入婚姻。", {"emotion": 2},
			false, ["in_love"], [], [], 0, {"marital": MaritalStatus.DATING},
			{"marital": MaritalStatus.MARRIED, "living": LivingStatus.WITH_PARTNER}, true, "long_marry"),

		# ==================== 因果链：学术 ====================
		_make_event(950, 19, 25, _cond_studious, func(): return 20,
			"你在学术上小有成就，发表了人生第一篇论文。", {"cleverness": 1, "emotion": 1},
			false, ["studious"]),
		_make_event(951, 26, 35, _cond_studious, func(): return 20,
			"你成为所在领域的专家，受人尊敬。", {"cleverness": 1, "money": 1},
			false, ["studious"]),

		# ==================== 因果链：创业 ====================
		_make_event(960, 26, 35, _cond_startup, func(): return 20,
			"你的创业项目拿到了一笔天使投资。", {"money": 2, "luck": 1},
			false, ["startup"], [], [], 1),
		_make_event(961, 36, 50, _cond_startup, func(): return 20,
			"你的公司稳定盈利，你终于松了口气。", {"money": 3, "emotion": 1},
			false, ["startup"], [], [], -2),

		# ==================== 父母去世 ====================
		_make_event(980, 36, 65, _cond_parents_death, func(): return 12,
			"父母年事已高，最终离开了你。", {"emotion": -2},
			false, [], [], [], 0, {"parents_alive": true},
			{"parents_alive": false}, true, "parents_death"),

		# ==================== 天赋专属：逆天改命 T27（每10年重分配3点） ====================
		_make_choice_event(1100, 10, 110,
			func(): return _has_talent(52) and GlobalData.age > 0 and GlobalData.age % 10 == 0,
			func(): return 999,
			"【逆天改命】你隐约感觉到，命运的丝线似乎可以被拨动。",
			[
				{"text": "3点改到体质", "result": "你把3点属性挪到了体质上。", "func": func(): _reallocate(3, "strong")},
				{"text": "3点改到颜值", "result": "你把3点属性挪到了颜值上。", "func": func(): _reallocate(3, "beauty")},
				{"text": "3点改到智力", "result": "你把3点属性挪到了智力上。", "func": func(): _reallocate(3, "cleverness")},
				{"text": "3点改到家境", "result": "你把3点属性挪到了家境上。", "func": func(): _reallocate(3, "money")},
				{"text": "3点改到运气", "result": "你把3点属性挪到了运气上。", "func": func(): _reallocate(3, "luck")},
				{"text": "3点改到快乐", "result": "你把3点属性挪到了快乐上。", "func": func(): _reallocate(3, "emotion")},
			]),

		# ==================== 修仙触发链 X01 / X02（T30 神秘玉佩专属，走强制通道） ====================
		_make_choice_event(1200, 5, 60,
			func(): return _has_flag("mysterious_jade"),
			func(): return 0,
			"你在街角遇到一个衣衫褴褛的流浪汉，他眯着眼睛盯着你胸前的玉佩，低声道：「小友，我这有本小册子，和你的玉佩很配，只要 3 点家境，要不要？」",
			[
				{"text": "买下小册子（家境-3）", "result": "你买下了那本小册子，流浪汉转身消失在人群里。",
				 "effects": {"money": -3}, "set_flags": ["mysterious_book"],
				 "cond": func(): return _get_stat("money") >= 3},
				{"text": "拒绝", "result": "你摇了摇头，流浪汉叹了口气，转身消失了。",
				 "effects": {}},
			], true),
		_make_event(1201, 30, 99,
			func(): return _has_flag("mysterious_jade"),
			func(): return 0,
			"深夜，你胸前的玉佩微微发热，仿佛在低语：「时候未到……」", {"emotion": 1},
			false, ["mysterious_jade"], [], [], 0, {}, {}, false, "jade"),
	]

	# 恋爱线 L01-L64（数据表见 Data/RomanceEvents.gd）
	event_pool.append_array(RomanceEvents.build(self, MaritalStatus, LivingStatus))

	# 家庭线 F01-F45（数据表见 Data/FamilyEvents.gd）
	event_pool.append_array(FamilyEvents.build(self, MaritalStatus, LivingStatus))

	# 修仙线事件（数据表见 Data/CultivationEvents.gd；带 cult 标记，仅修仙期间可触发）
	event_pool.append_array(CultivationEvents.build(self))

	# 跨线互动事件（数据表见 Data/InteractionEvents.gd）
	event_pool.append_array(InteractionEvents.build(self, MaritalStatus, LivingStatus, JobStatus))

	# 修仙资源系统（数据表见 Data/ResourceEvents.gd）
	event_pool.append_array(ResourceEvents.build(self))

	# 性别专属事件（数据表见 Data/GenderEvents.gd）
	event_pool.append_array(GenderEvents.build(self))

	# 晋级物品获取 + 修仙期多样化事件（数据表见 Data/AdvanceEvents.gd）
	event_pool.append_array(AdvanceEvents.build(self))

	# 事件图鉴目录（id → 文本），供主菜单的收集统计使用
	var catalog: Dictionary = {}
	for e in event_pool:
		catalog[int(e.id)] = str(e.text)
	Progress.set_catalog(catalog, event_pool.size())

# ==================== 主流程 ====================
func start_text_sequence() -> void:
	_emit_next_line()
	if not is_dead and not is_waiting_for_choice:
		timer.start(wait_time)

func _emit_next_line() -> void:
	if GlobalData.age == 0:
		GlobalData.gender = randi_range(0, 1)
	var gender_text: String = "男" if GlobalData.gender == 1 else "女"

	_yearly_stress_decay()
	parents_health = maxi(0, parents_health - (1 if GlobalData.age >= 30 else 0))

	# 子女年龄增长
	for i in range(child_ages.size()):
		child_ages[i] = int(child_ages[i]) + 1

	# 修仙线每年的机制判定（天劫爆体 / 寿元耗尽 / 冲击瓶颈）
	if _cultivation_year():
		return

	# 凡人寿元上限：120 岁后自然死亡概率逐年升高（否则健康的角色会永生）
	#   注意：自然死亡同样要先走「时间循环 / 修仙入口」判定，否则拿了玉佩+小册子的玩家
	#   会在 120 岁被这条规则直接送进结算，永远进不了修仙线。
	if not cultivating and GlobalData.age >= 120:
		if randf() < 0.2 + float(GlobalData.age - 120) * 0.05:
			if _try_time_loop():
				timer.start(wait_time)
				return
			if _try_cultivation_entry():
				timer.start(wait_time)
				return
			_die_natural()
			return

	# 特殊强制事件（修仙触发链）：按精确概率判定，不走权重池
	var chosen: Dictionary = _check_forced_event()

	if chosen.is_empty():
		var candidates: Array[Dictionary] = []
		for e in event_pool:
			if GlobalData.age < int(e.age_min) or GlobalData.age > int(e.age_max):
				continue
			if e.once and triggered_once.get(e.id, false):
				continue
			var ok := true
			for f in e.get("require_flags", []):
				if not _has_flag(f):
					ok = false
					break
			if not ok:
				continue
			if not _check_status(e.get("require_status", {})):
				continue
			if cultivating != bool(e.get("cult", false)):
				continue
			if not (e.cond as Callable).call():
				continue
			if _get_event_weight(e) <= 0:
				continue
			candidates.append(e)

		var sum_weight := 0
		for e in candidates:
			sum_weight += _get_event_weight(e)

		if candidates.is_empty() or sum_weight <= 0:
			add_text_line("第%d岁，今年平平无奇，什么也没发生。" % GlobalData.age)
			GlobalData.age += 1
			return

		var r := randi_range(1, sum_weight)
		var acc := 0
		chosen = candidates[0]
		for e in candidates:
			acc += _get_event_weight(e)
			if acc >= r:
				chosen = e
				break

	history.append(int(chosen.id))

	# 随机分支事件（表白成功率、求婚成功率等）
	if chosen.has("branch"):
		chosen = _apply_branch(chosen)

	var body: String = chosen.text
	if GlobalData.age == 0:
		body = "你的性别为：%s。" % gender_text + body
	body = body.replace("{gender}", gender_text)
	var add_text := "第%d岁，" % GlobalData.age + body

	if chosen.has("choices"):
		add_text_line(add_text, _event_rarity(chosen))
		_show_choices(chosen)
		return

	var effects: Dictionary = chosen.effects
	var is_death: bool = bool(chosen.death) or add_text.ends_with("你死了。")

	# 先应用效果，拿到触发消息
	var trigger_msgs: Array = []
	if not effects.is_empty():
		trigger_msgs = _apply_effects(effects)
		_update_values()

	# 拼接文本
	if not is_death:
		var effect_str := _format_effects(effects)
		if effect_str != "":
			add_text += " " + effect_str
		for m in trigger_msgs:
			add_text += " 【%s】" % m

	add_text_line(add_text, _event_rarity(chosen))

	for f in chosen.get("set_flags", []):
		_set_flag(f)
	for f in chosen.get("clear_flags", []):
		_clear_flag(f)
	var sd: int = int(chosen.get("stress_delta", 0))
	if sd != 0:
		_add_stress(sd)
	_apply_status(chosen.get("set_status", {}))
	# 普通事件/分支结果的动态回调（赌石、拍卖、强行突破等需要按当前状态结算）
	var ev_cb = chosen.get("func", Callable())
	if ev_cb is Callable and ev_cb.is_valid():
		ev_cb.call()
		_update_values()
	if chosen.once:
		triggered_once[chosen.id] = true

	if is_death:
		if _try_time_loop():
			timer.start(wait_time)
			return
		if _try_cultivation_entry():
			timer.start(wait_time)
			return
		_finish_run()
		add_choose_line("结算")
		timer.stop()
		Speed_Slider.editable = false
		is_dead = true
		return

	GlobalData.age += 1

# ==================== 选择事件处理 ====================
func _show_choices(event: Dictionary) -> void:
	is_waiting_for_choice = true
	current_choice_event = event
	timer.stop()
	_clear_choices()
	pending_choices = []

	for c in event.choices:
		var ccond = c.get("cond", Callable())
		if ccond is Callable and ccond.is_valid() and not ccond.call():
			continue
		pending_choices.append(c)
		_add_choice_option(c.text, c)

	if pending_choices.is_empty():
		# 所有选项都不满足条件，视为什么都没发生
		is_waiting_for_choice = false
		current_choice_event = {}
		GlobalData.age += 1
		timer.start(wait_time)
		return

	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
	choose_box.columns = maxi(1, mini(3, choose_box.get_child_count()))
	_apply_choose_layout()

func _on_choice_selected(choice: Dictionary) -> void:
	if not is_waiting_for_choice:
		return

	# 修仙期间：买不起的东西不能买（数据表用 "cost" 声明价格）
	#   选项在展示时已按 cond 过滤过一遍，这里是点下去时的二次保护
	var price := int(choice.get("cost", 0))
	if price > 0 and cultivating and cult_zi < price:
		PopupManager.show_popup("资源不足，买不起", Color(1, 1, 1), 1)
		add_text_line("第%d岁，你数了数储物袋里的灵石——不够，只能作罢。" % GlobalData.age)
		return

	is_waiting_for_choice = false
	_clear_choices()
	pending_choices = []

	var ev_rarity := _event_rarity(current_choice_event)

	# 选项事件同样要记录 once，否则会无限重复触发
	if current_choice_event.get("once", false):
		triggered_once[int(current_choice_event.id)] = true
	current_choice_event = {}

	var effects: Dictionary = choice.get("effects", {})
	var result_text: String = choice.get("result", "")
	var is_death: bool = bool(choice.get("death", false)) or result_text.ends_with("你死了。")

	var trigger_msgs: Array = []
	if not effects.is_empty():
		trigger_msgs = _apply_effects(effects)

	var cb = choice.get("func", Callable())
	if cb is Callable and cb.is_valid():
		cb.call()
	_update_values()

	var display := "  → " + result_text
	if not is_death:
		var effect_str := _format_effects(effects)
		if effect_str != "":
			display += " " + effect_str
		for m in trigger_msgs:
			display += " 【%s】" % m

	add_text_line(display, ev_rarity)

	for f in choice.get("set_flags", []):
		_set_flag(f)
	for f in choice.get("clear_flags", []):
		_clear_flag(f)
	var sd: int = int(choice.get("stress", 0))
	if sd != 0:
		_add_stress(sd)
	_apply_status(choice.get("set_status", {}))

	if is_death:
		if _try_time_loop():
			timer.start(wait_time)
			return
		if _try_cultivation_entry():
			timer.start(wait_time)
			return
		_finish_run()
		add_choose_line("结算")
		timer.stop()
		Speed_Slider.editable = false
		is_dead = true
		return

	GlobalData.age += 1
	if not is_dead:
		timer.start(wait_time)

# ==================== 按钮与速度 ====================
func _on_choose_button_pressed(_btn: Button, content: String) -> void:
	if content == "结算":
		get_tree().change_scene_to_file.call_deferred("res://Settlement/settlement.tscn")

func _on_speed_slider_value_changed(value: float) -> void:
	if value <= 0:
		timer.stop()
		Speed_Text.text = "暂停"
	else:
		wait_time = 1.0 / value
		Speed_Text.text = "%.1fx" % value
		if not is_dead and not is_waiting_for_choice:
			if timer.is_stopped():
				timer.start(wait_time)
			else:
				timer.wait_time = wait_time

# ==================== 天赋专属机制 ====================
# 时间循环 T28：死亡时回到 10 年前，属性保留（每局一次）
func _try_time_loop() -> bool:
	if not _has_talent(53):
		return false
	if _has_flag("time_loop_used"):
		return false
	_set_flag("time_loop_used")
	GlobalData.age = maxi(0, GlobalData.age - 10)
	_add_stress(5)
	add_text_line("【时间循环】时间骤然倒流，你回到了十年前——第%d岁，你重新睁开了眼睛（属性与记忆保留）。" % GlobalData.age)
	return true

# 逆天改命 T27：把 points 点属性从其他项挪到 to_stat（总量不变）
func _reallocate(points: int, to_stat: String) -> void:
	var need := points
	var order: Array = []
	for k in STAT_KEYS:
		if k != to_stat:
			order.append(k)
	order.sort_custom(func(a, b): return _get_stat(a) > _get_stat(b))
	for k in order:
		while need > 0 and _get_stat(k) > 0:
			_set_stat(k, _get_stat(k) - 1)
			need -= 1
		if need == 0:
			break
	var gained := points - need
	if gained > 0:
		_set_stat(to_stat, _get_stat(to_stat) + gained)

# ==================== 特殊强制事件通道 ====================
func _event_by_id(id: int) -> Dictionary:
	for e in event_pool:
		if int(e.id) == id:
			return e
	return {}

# 按策划案的精确概率判定修仙触发链，命中则强制触发（不走权重池）
func _check_forced_event() -> Dictionary:
	# 修仙线期间不再走凡尘触发链
	if cultivating:
		return {}
	# X01 神秘流浪汉：拥有玉佩，5-60 岁，每年 3%，全局仅一次
	if _has_flag("mysterious_jade") and not triggered_once.get(1200, false) \
			and GlobalData.age >= 5 and GlobalData.age <= 60 and RandomProbability.chance(3):
		return _event_by_id(1200)
	# X02 玉佩的低语：拥有玉佩，30-99 岁，每年 5%
	if _has_flag("mysterious_jade") and GlobalData.age >= 30 and GlobalData.age <= 99 \
			and RandomProbability.chance(5):
		return _event_by_id(1201)
	return {}

# ==================== 供模拟器调用 ====================
func auto_pick_choice(index: int = -1) -> void:
	if not is_waiting_for_choice or pending_choices.is_empty():
		return
	var i := index
	if i < 0:
		i = randi() % pending_choices.size()
	_on_choice_selected(pending_choices[clampi(i, 0, pending_choices.size() - 1)])

# ==================== 修仙线核心机制（《修仙线完整体系表》） ====================
func _cult_cap() -> int:
	if realm >= REALM_CAP.size():
		return REALM_CAP[REALM_CAP.size() - 1]
	return REALM_CAP[realm]

func _has_cult_item(item: String) -> bool:
	return bool(cult_items.get(item, false))

func _grant_cult_item(item: String) -> void:
	cult_items[item] = true

# ==================== 晋级物品获取（⑨） ====================
# 随机补齐当前阶段缺失的一件物品；本阶段已齐则给下一阶段的普通件
func _grant_missing_item(kind: String = "common") -> String:
	var st: Dictionary = BreakthroughItems.stage(cult_path, realm)
	var pool: Array = st.get(kind, [])
	var missing: Array = []
	for it in pool:
		if not _has_cult_item(it):
			missing.append(it)
	if missing.is_empty() and realm < 8:
		var nxt: Dictionary = BreakthroughItems.stage(cult_path, realm + 1)
		for it in nxt.common:
			if not _has_cult_item(it):
				missing.append(it)
	if missing.is_empty():
		cult_zi = clampi(cult_zi + 5, 0, _cult_cap())      # 实在没有可给的，折算成资源
		return ""
	var got := str(missing[randi() % missing.size()])
	_grant_cult_item(got)
	return got

# 完成当前阶段的前置（道基稳固 / 心魔试炼 …）
func _grant_pre_event() -> String:
	var pre := BreakthroughItems.stage_name(cult_path, realm)
	if pre == "":
		return ""
	_set_flag("pre_%s" % pre)
	return pre

# 购买物品：资源不足直接买不了（⑦）
func _buy_cult_item(item: String, price: int) -> bool:
	if cult_zi < price:
		return false
	cult_zi -= price
	_grant_cult_item(item)
	return true

# 三线门槛与名称
func _realm_name() -> String:
	return PATH_REALM_NAMES[cult_path][clampi(realm, 0, 9)]

# 三线核心门槛：i=0 灵力/魔元/魂力，1 悟性/魔悟/魂悟，2 天道/业力/魂道
func _req_core(i: int) -> int:
	return PATH_REQ[cult_path][i][clampi(realm, 0, 8)]

func _req_mind() -> int:
	return REQ_MIND[clampi(realm, 0, 8)]

func _req_res_cost() -> int:
	return REQ_RESOURCE_COST[clampi(realm, 0, 8)]

func _req_face() -> int:
	return REQ_FACE[clampi(realm, 0, 8)]

func _req_extra() -> int:
	return PATH_REQ_EXTRA[cult_path][clampi(realm, 0, 8)]

func _req_age() -> int:
	return REALM_AGE[clampi(realm, 0, 8)]

# 借貸：资源 +10，一半概率日后以 10 年寿元偿还
func _borrow_resource() -> void:
	cult_zi = clampi(cult_zi + 10, 1, _cult_cap())
	if randf() < 0.5:
		GlobalData.age += 10

# 强行突破（资源不足时的赌博）：成功率 -20%，失败年龄 +30、灵力 -3、资源归零
func _force_breakthrough() -> void:
	var chance := clampf(_breakthrough_chance() - 20.0, 5.0, 95.0)
	var target_name: String = PATH_REALM_NAMES[cult_path][clampi(realm + 1, 0, 9)]
	cult_zi = 0
	if randf() * 100.0 < chance:
		realm += 1
		fail_streak = 0
		if realm >= 9:
			_end_cultivation("飞升")
			return
		lifespan = REALM_LIFESPAN[realm]
		add_text_line("第%d岁，你以空荡荡的储物袋硬撼天关，竟然成了！（成功率 %.0f%%）" % [GlobalData.age, chance])
		_update_values()
		return
	fail_streak += 1
	GlobalData.age += 30
	cult_ling = maxi(1, cult_ling - 3)
	add_text_line("第%d岁，你冲击【%s】失败（强行突破，成功率 %.0f%%）：年龄 +30，灵力 -3，资源归零。"
		% [GlobalData.age, target_name, chance])
	_update_values()
	if GlobalData.age >= lifespan:
		_end_cultivation("破产坐化")

# ==================== 天劫（硬抗） ====================
# 晋级条件：数值门槛 + 晋级物品 + 前置事件 + 天劫硬抗
#   物品不齐不会阻止晋升，而是抬高天劫总重、压低成功率、加重失败后果
func _tribulation() -> Dictionary:
	var pre_name := BreakthroughItems.stage_name(cult_path, realm)
	var pre_done := true
	if pre_name != "":
		pre_done = _has_flag("pre_%s" % pre_name) or _has_cult_item(pre_name)
	var tb: Dictionary = BreakthroughItems.tribulation(cult_items, cult_path, realm, pre_done)
	# 护身法宝：可抵消一次死亡，但天劫 +1 重
	if _has_guard_item():
		tb["weight"] = int(tb.weight) + 1
		tb["level"] = BreakthroughItems.level_name(int(tb.weight))
		tb["over"] = int(tb.weight) > 9
		tb["absolute"] = int(tb.weight) >= 13
	return tb

func _has_guard_item() -> bool:
	for it in ["护身法宝", "避劫法宝", "避劫魔器", "避劫魂器"]:
		if _has_cult_item(it):
			return true
	return false

func _has_revive_item() -> String:
	for it in ["替死符", "替死魔符", "替死魂符", "符箓"]:
		if _has_cult_item(it):
			return it
	return ""

# 硬抗成功率 = 基础突破成功率 + 悟性×1.5 + 天道×2 + 心智×1 + 面相×0.5
#            + 资源投入 + 物品齐全10 + 护道/丹药/法宝 - 劫重×5 - 年龄惩罚 - 超劫惩罚
#            最低 5%，最高 95%
func _breakthrough_chance() -> float:
	var tb := _tribulation()
	var chance := float(PATH_BASE[cult_path][clampi(realm, 0, 8)])
	chance += float(cult_wu) * 1.5
	chance += float(cult_dao) * 2.0
	chance += float(cult_xin) * 1.0
	chance += float(cult_face) * 0.5
	# 资源投入（每多 10 点 +2%，最多 +10%）
	if cult_zi > _req_res_cost():
		chance += minf(10.0, float(cult_zi - _req_res_cost()) / 10.0 * 2.0)
	# 物品齐全
	if bool(tb.complete):
		chance += 10.0
	# 护道者 / 丹药 / 洞府
	if marital_status == MaritalStatus.MARRIED:
		chance += 10.0                                            # 道侣护道
	if _has_cult_item("护道阵法") or _has_cult_item("护道魔阵") or _has_cult_item("护道魂阵"):
		chance += 5.0
	if _has_cult_item("洞府"):
		chance += 5.0
	if _has_cult_item("破境丹"):
		chance += 5.0
	if realm == 8 and _has_cult_item("渡劫丹"):
		chance += 5.0
	# 天劫总重惩罚
	chance -= float(tb.weight) * 5.0
	# 年龄惩罚
	chance -= float(maxi(0, GlobalData.age - REALM_AGE[realm])) * 0.1
	# 超劫额外惩罚
	if bool(tb.over):
		chance -= 20.0
	# 连续失败保护：每连续失败 3 次 +10%，最多 +30%
	chance += 10.0 * float(clampi(fail_streak / 3, 0, 3))
	return clampf(chance, 5.0, 95.0)

# 数值门槛：达标即可尝试渡劫
#   注意：晋级物品**不**在此拦截 —— 物品不齐只抬高天劫强度（⑨⑩ 的规则）
func _can_attempt_breakthrough() -> bool:
	if realm >= 9:
		return false
	if GlobalData.age < REALM_AGE[realm]:
		return false
	if cult_ling < _req_core(0) or cult_wu < _req_core(1) or cult_dao < _req_core(2):
		return false
	if cult_xin < _req_mind():
		return false
	if cult_zi < _req_res_cost():      # 资源必须够付突破消耗
		return false
	if cult_extra < _req_extra():
		return false
	return true

# 转修支线（魔修/魂修）：属性部分折损，天道↔业力、灵力↔魂力转换，获得专属资源
func _switch_path(p: int) -> void:
	if not cultivating or p == cult_path or p == 0:
		return
	cult_path = p
	if p == 1:
		# 魔修：天道清零转业力；灵力×0.9；获得天赋「魔心」
		cult_ling = maxi(1, int(float(cult_ling) * 0.9))
		cult_dao = maxi(1, cult_dao)
		cult_extra = 0
		_set_flag("mo_xin")
		add_text_line("【堕入魔道】你握住那缕血色的气机，天道自此与你无缘。修行之路，从今天起由你自己定义。")
	else:
		# 魂修：灵力×0.9 转魂力；天道×0.8 转魂道；获得魂火 1；肉身寿元 -50
		cult_ling = maxi(1, int(float(cult_ling) * 0.9))
		cult_dao = maxi(1, int(float(cult_dao) * 0.8))
		cult_extra = 1
		lifespan = maxi(50, lifespan - 50)
		add_text_line("【转修魂道】你以魂灯引路，将神识沉入幽冥。肉身衰败了五十年，但你的魂火，才刚刚点亮。")
	_refresh_panel_titles()
	_update_values()

# X03 百岁之死：玉佩 + 小册子 + 活到 100 岁死亡 → 进入修仙线
func _try_cultivation_entry() -> bool:
	if cultivating:
		return false
	if not (_has_flag("mysterious_jade") and _has_flag("mysterious_book")):
		return false
	if GlobalData.age < 100:
		return false
	_enter_cultivation()
	return true

func _enter_cultivation() -> void:
	cultivating = true
	cult_path = 0
	realm = 0
	cult_items.clear()
	fail_streak = 0
	heart_demon = 0
	cult_extra = 0
	# 属性转换：体质→灵力、智商→悟性、运气→天道、心情→心智、家境→资源、颜值→面相（÷5，钳制 1~20）
	cult_ling = clampi(int(GlobalData.strong) / 5, 1, 20)
	cult_wu = clampi(int(GlobalData.cleverness) / 5, 1, 20)
	cult_dao = clampi(int(GlobalData.luck) / 5, 1, 20)
	cult_xin = clampi(int(GlobalData.emotion) / 5, 1, 20)
	cult_zi = clampi(int(GlobalData.money) / 5, 1, 20)
	cult_face = clampi(int(GlobalData.beauty) / 5, 1, 20)
	_grant_cult_item("小册子")                      # 练气→筑基必需
	if _has_flag("mysterious_book"):
		cult_wu = clampi(cult_wu + 2, 1, 20)        # 小册子：练气期悟性 +2
	if _has_flag("mysterious_jade"):
		cult_dao = clampi(cult_dao + 2, 1, 20)      # 玉佩：练气期天道 +2
		_grant_cult_item("神秘玉佩")
	lifespan = REALM_LIFESPAN[0]
	add_text_line("【百岁之死】你走完漫长的一生，寿终正寝。然而就在咽下最后一口气的瞬间，胸前的玉佩爆发出耀眼的光芒，那本小册子自行翻开，金光四射——你，没有死。")
	add_text_line("你重新睁开眼，凡尘已了。境界：%s｜灵力 %d｜悟性 %d｜天道 %d｜心智 %d｜资源 %d｜面相 %d｜寿元上限 %d 年。"
		% [_realm_name(), cult_ling, cult_wu, cult_dao, cult_xin, cult_zi, cult_face, lifespan])
	_refresh_panel_titles()
	_update_values()

# 修仙线每年推进；返回 true 表示今年由修仙机制消耗
func _cultivation_year() -> bool:
	if not cultivating:
		return false
	# 灵脉产出：每 10 年 +2 资源
	if _has_cult_item("灵脉") and GlobalData.age % 10 == 0:
		cult_zi = clampi(cult_zi + 2, 1, _cult_cap())
	if GlobalData.age >= lifespan:
		_end_cultivation("寿尽")
		return true
	if _can_attempt_breakthrough():
		_try_breakthrough()
		return true
	_cultivate_year_gain()
	return false

# 每一年静修的基础收益：优先补足离门槛最远的那一项（再叠加事件收益）
func _cultivate_year_gain() -> void:
	var cap := _cult_cap()
	var gains: Array[int] = [
		maxi(0, _req_core(0) - cult_ling),
		maxi(0, _req_core(1) - cult_wu),
		maxi(0, _req_core(2) - cult_dao),
		maxi(0, _req_mind() - cult_xin),
		maxi(0, _req_res_cost() - cult_zi),
		maxi(0, _req_face() - cult_face),
	]
	if _req_extra() > 0:
		gains.append(maxi(0, _req_extra() - cult_extra))
	var idx := 0
	for i in range(1, gains.size()):
		if gains[i] > gains[idx]:
			idx = i
	match idx:
		0: cult_ling = clampi(cult_ling + 1, 1, cap)
		1: cult_wu = clampi(cult_wu + 1, 1, cap)
		2: cult_dao = clampi(cult_dao + 1, 1, cap)
		3: cult_xin = clampi(cult_xin + 1, 1, cap)
		4: cult_zi = clampi(cult_zi + 1, 1, cap)
		5: cult_face = clampi(cult_face + 1, 1, cap)
		6: cult_extra += 1

func _try_breakthrough() -> void:
	var tb := _tribulation()
	var chance := _breakthrough_chance()
	# 缺钥匙件：无法正常飞升，强行渡劫成功率固定 5%、失败必死
	var key_block: bool = int(tb.miss_key) > 0 and realm == 8
	if key_block:
		chance = 5.0

	var cost := _req_res_cost()
	var extra_cap := int(float(_cult_cap()) * 0.5)
	var extra := clampi(cult_zi - cost, 0, extra_cap)
	cult_zi = maxi(0, cult_zi - cost - extra)
	# 一次性加成道具在本次尝试后消耗
	cult_items.erase("洞府")
	cult_items.erase("破境丹")
	if realm == 8:
		cult_items.erase("渡劫丹")

	# 渡劫播报：告诉玩家缺了什么（但不直接说明条件清单）
	var miss_desc := ""
	if int(tb.missing_total) > 0:
		miss_desc = "（缺普通件 %d、核心件 %d、钥匙件 %d" % [tb.miss_common, tb.miss_core, tb.miss_key]
		if int(tb.alt) > 0:
			miss_desc += "，高阶替代抵消 %d 重" % int(tb.alt)
		miss_desc += "）"
	add_text_line("第%d岁，%s降临——【%s·%d 重】%s硬抗成功率 %.0f%%。"
		% [GlobalData.age, str(tb.type_name), str(tb.level), int(tb.weight), miss_desc, chance])
	tribulation_log.append({"realm": realm, "weight": int(tb.weight), "chance": chance,
		"level": str(tb.level), "miss": int(tb.missing_total), "age": GlobalData.age})

	if randf() * 100.0 < chance:
		_succeed_tribulation(tb, chance)
	else:
		_fail_tribulation(tb, chance, key_block, extra)

func _succeed_tribulation(tb: Dictionary, chance: float) -> void:
	realm += 1
	fail_streak = 0
	var bonus_text := ""
	cult_ling = clampi(cult_ling + 3, 1, _cult_cap())
	cult_xin = clampi(cult_xin + 2, 1, _cult_cap())
	match cult_path:
		1:
			cult_extra += 5
			cult_dao = clampi(cult_dao + 5, 1, _cult_cap())
			bonus_text = "魔元+3，煞气+5，业力+5"
		2:
			cult_dao = clampi(cult_dao + 3, 1, _cult_cap())
			cult_extra += 1
			bonus_text = "魂力+3，魂道+3，魂火+1"
		_:
			bonus_text = "灵力+3，心智+2"
	if bool(tb.complete):
		cult_ling = clampi(cult_ling + 2, 1, _cult_cap())
		cult_wu = clampi(cult_wu + 2, 1, _cult_cap())
		cult_dao = clampi(cult_dao + 2, 1, _cult_cap())
		cult_xin = clampi(cult_xin + 2, 1, _cult_cap())
		cult_zi = clampi(cult_zi + 2, 0, _cult_cap())
		cult_face = clampi(cult_face + 2, 1, _cult_cap())
		bonus_text += "　物品齐全：全属性+2"
	if bool(tb.over):
		_set_flag("渡劫者")
		cult_ling = clampi(cult_ling + 5, 1, _cult_cap())
		cult_wu = clampi(cult_wu + 5, 1, _cult_cap())
		cult_dao = clampi(cult_dao + 5, 1, _cult_cap())
		cult_xin = clampi(cult_xin + 5, 1, _cult_cap())
		cult_face = clampi(cult_face + 5, 1, _cult_cap())
		bonus_text += "　超劫硬抗成功：全属性+5，获得天赋「渡劫者」"

	if realm >= 9:
		_end_cultivation("飞升")
		return
	lifespan = REALM_LIFESPAN[clampi(realm, 0, 9)]
	add_text_line("第%d岁，%s散尽，你踏入【%s】。（成功率 %.0f%%）%s"
		% [GlobalData.age, str(tb.type_name), _realm_name(), chance, bonus_text])
	_refresh_panel_titles()
	_update_values()

func _fail_tribulation(tb: Dictionary, chance: float, key_block: bool, extra: int) -> void:
	fail_streak += 1
	var delta: int = int(tb.weight) - int(tb.base)
	var death := false
	var death_kind := "渡劫失败"

	# 死亡判定
	if key_block:
		death = true
	elif bool(tb.absolute):
		death = true
		if randf() < 0.35:
			death_kind = "兵解转世"
	elif bool(tb.over):
		death = true
		if randf() < 0.35:
			death_kind = "兵解转世"
	elif delta >= 5:
		if randf() < 0.5:
			death = true

	# 保命：护身法宝 / 替死符
	var saved_by := ""
	if death:
		if _has_cult_item("护身法宝"):
			cult_items.erase("护身法宝")
			saved_by = "护身法宝"
		elif _has_cult_item("避劫法宝"):
			cult_items.erase("避劫法宝")
			saved_by = "避劫法宝"
		elif _has_cult_item("避劫魔器"):
			cult_items.erase("避劫魔器")
			saved_by = "避劫魔器"
		elif _has_cult_item("避劫魂器"):
			cult_items.erase("避劫魂器")
			saved_by = "避劫魂器"
		else:
			var rev := _has_revive_item()
			if rev != "":
				cult_items.erase(rev)
				saved_by = rev
		if saved_by != "":
			death = false
			add_text_line("第%d岁，天劫落下的一瞬间，%s寸寸碎裂，替你挡下了这一劫。"
				% [GlobalData.age, saved_by])

	var loss_text := ""
	if not death:
		var age_add := 20
		var attr_loss := 2
		if delta >= 3:
			age_add = 50
			attr_loss = 5
			if realm > 0:
				realm -= 1                              # 降一大境
				lifespan = REALM_LIFESPAN[realm]
		elif delta >= 1:
			age_add = 30
			attr_loss = 3
		GlobalData.age += age_add
		cult_ling = maxi(1, cult_ling - attr_loss)
		cult_wu = maxi(1, cult_wu - attr_loss)
		loss_text = "年龄 +%d，灵力/悟性 -%d" % [age_add, attr_loss]
		match cult_path:
			1:
				heart_demon += 2
				cult_dao = clampi(cult_dao + 10, 1, _cult_cap())
				loss_text += "，心魔 +2，业力 +10"
			2:
				cult_extra = maxi(0, cult_extra - 1)
				loss_text += "，魂火 -1（余 %d）" % cult_extra
		add_text_line("第%d岁，你在【%s】下硬抗失败（成功率 %.0f%%，劫重%d）：%s"
			% [GlobalData.age, str(tb.type_name), chance, int(tb.weight), loss_text])
		# 固定消耗全扣，额外投入退还 50%
		cult_zi = mini(_cult_cap(), cult_zi + int(float(extra) * 0.5))
		_refresh_panel_titles()
		_update_values()

	# 路线专属生死线
	if cult_path == 2 and cult_extra <= 0:
		_end_cultivation("魂飞魄散")
		return
	if cult_path == 1 and heart_demon >= 5:
		_end_cultivation("心魔爆体")
		return
	if death:
		if cult_path == 2:
			_end_cultivation("魂飞魄散")
		else:
			_end_cultivation(death_kind)
		return
	_update_values()

# 修仙线结局（三线各自不同）
func _end_cultivation(kind: String) -> void:
	# 符箓：一次性保命（寿尽 / 渡劫失败时自动消耗）
	if _has_cult_item("符箓") and kind in ["寿尽", "渡劫失败"]:
		cult_items.erase("符箓")
		cult_ling = maxi(1, cult_ling - 1)
		add_text_line("第%d岁，命悬一线之际，怀中的符箓自行燃起，替你挡下了这一劫。" % GlobalData.age)
		_update_values()
		return
	# 魂修夺舍：死亡时若魂火≥1，消耗 1 点，年龄 -50，境界降一，魂力 -20%，不结束
	if cult_path == 2 and cult_extra >= 1 and kind in ["寿尽", "渡劫失败", "魂飞魄散"]:
		cult_extra -= 1
		GlobalData.age = maxi(50, GlobalData.age - 50)
		realm = maxi(0, realm - 1)
		cult_ling = maxi(1, int(float(cult_ling) * 0.8))
		lifespan = REALM_LIFESPAN[realm]
		fail_streak = 0
		add_text_line("第%d岁，你的肉身彻底崩坏。魂火燃起，你夺舍了一具新躯壳，境界跌回【%s】。剩余魂火：%d。"
			% [GlobalData.age, _realm_name(), cult_extra])
		_refresh_panel_titles()
		_update_values()
		return

	# 飞升按路线细分为不同结局名（成就与图鉴判定用）
	var ending_key := kind
	if kind == "飞升":
		match cult_path:
			1:
				ending_key = "魔祖" if (cult_dao >= 80 and cult_extra >= 60) else "飞升魔界"
			2:
				ending_key = "轮回之主" if (cult_dao >= 80 and cult_extra >= 9) else "飞升幽冥"
			_:
				ending_key = "飞升"
	cultivation_ended = ending_key
	# 结局摘要交给结算画面（本场景即将被替换，状态必须落到 GlobalData）
	GlobalData.ending_summary = "修仙线·%s｜终境：%s｜结局：%s" % [CULT_PATHS[cult_path], _realm_name(), ending_key]
	match kind:
		"飞升":
			match cult_path:
				1:
					if cult_dao >= 80 and cult_extra >= 60:
						add_text_line("第%d岁，你踏碎天穹，万魔俯首，血月为你而升。【魔祖】" % GlobalData.age)
					else:
						add_text_line("第%d岁，天劫散尽，魔气冲霄。你踏入魔界，人间再无人敢直呼你的名字。【飞升魔界】" % GlobalData.age)
				2:
					if cult_dao >= 80 and cult_extra >= 9:
						add_text_line("第%d岁，幽冥之门为你而开，六道轮回在你掌中缓缓转动。【轮回之主】" % GlobalData.age)
					else:
						add_text_line("第%d岁，魂灯长明不灭，你踏入幽冥，成为传说中的魂修。【飞升幽冥】" % GlobalData.age)
				_:
					add_text_line("第%d岁，九重天劫散尽，天门洞开。你回首人间，微微一笑，踏入仙界。【飞升仙界】" % GlobalData.age)
		"寿尽":
			var texts: Array = []
			match cult_path:
				1:
					texts = ["魔元枯竭，你在血池中化作一具枯骨。", "魔基崩毁，魔气溃散。", "魔丹碎裂，神魂俱灭。",
						"魔婴枯萎，消散于天地。", "魔化神崩解，魔道断绝。", "虚空反噬，魔体撕裂。",
						"魔合体溃散，法体崩坏。", "天劫未至，寿元先尽。", "魔渡劫失败，身死道消。"]
				2:
					texts = ["魂火熄灭，你在黑暗中彻底失去意识。", "凝魂溃散，魂魄重归幽冥。", "魂丹碎裂，神魂俱灭。",
						"魂婴枯竭，消散于轮回。", "魂神崩解，化道而亡。", "虚空反噬，魂体撕裂。",
						"合魂溃散，魂魄不全。", "魂劫未至，寿元先尽。", "魂劫失败，永世沉沦。"]
				_:
					texts = ["寿元耗尽，你在洞府中盘膝坐化。", "道基崩毁，身死道消。", "金丹碎裂，神魂俱灭。",
						"元婴枯竭，消散于天地之间。", "神念溃散，化道而亡。", "虚空反噬，形神俱灭。",
						"法体崩溃，合道失败。", "天劫未至，寿元先尽。", "渡劫失败，身死道消。"]
			add_text_line("第%d岁，%s【坐化】" % [GlobalData.age, texts[clampi(realm, 0, texts.size() - 1)]])
		"渡劫失败":
			match cult_path:
				1:
					if cult_dao >= 60:
						add_text_line("第%d岁，天雷贯体，业火焚身。你终究没能跨过那一步。【天劫诛灭】" % GlobalData.age)
					else:
						add_text_line("第%d岁，你已过千岁，终究未能渡过天劫，身死道消。【渡劫失败】" % GlobalData.age)
				2:
					if cult_dao < 20:
						add_text_line("第%d岁，魂道未成，你在轮回中彻底迷失。【永世沉沦】" % GlobalData.age)
					else:
						add_text_line("第%d岁，魂劫未过，你的魂体在雷光中崩散。【魂飞魄散】" % GlobalData.age)
				_:
					add_text_line("第%d岁，你已过千岁，终究未能渡过天劫，身死道消。【渡劫失败】" % GlobalData.age)
		"心魔爆体":
			add_text_line("第%d岁，心魔再也压制不住，你的肉身从内部炸开，血雾漫天。【心魔爆体】" % GlobalData.age)
		"魂飞魄散":
			add_text_line("第%d岁，魂火燃尽，你的意识在幽冥中彻底熄灭。【魂飞魄散】" % GlobalData.age)
		"归隐":
			add_text_line("第%d岁，你厌倦了长生路上的孤独，散去一身修为，回到人间。【归隐】" % GlobalData.age)
		"富甲修真界":
			add_text_line("第%d岁，你的灵石堆成了山，修真界半数坊市都挂着你的名号。【富甲修真界】" % GlobalData.age)
		"破产坐化":
			add_text_line("第%d岁，储物袋空空如也，你在洞府中枯坐至死。【破产坐化】" % GlobalData.age)
		_:
			add_text_line("第%d岁，你的修行之路走到了尽头。【%s】" % [GlobalData.age, kind])
	_finish_run()
	add_choose_line("结算")
	timer.stop()
	Speed_Slider.editable = false
	is_dead = true
