extends RefCounted

# ============================================================
# 结算页属性评语表（按属性名取值，列顺序怎么调都不会错位）
#   用法：SettlementPanels.evaluate("emotion", GlobalData.emotion)
#   注意：结算表格目前有 6 列 —— 享年/体质/颜值/智商/家境/心情（没有运气列），
#         所以这里也只需要这些属性；以后加回运气列，补一个 "luck" 条目即可。
# ============================================================

const EVAL := {
	"age": {
		"stops": [0, 10, 30, 60, 80, 100],
		"words": ["夭折", "早逝", "中年而终", "寿终正寝", "高寿", "人瑞"],
	},
	"strong": {"words": ["药罐子", "文弱", "康健", "硬朗", "天生神力"]},
	"beauty": {"words": ["其貌不扬", "普通", "清秀", "出众", "倾国倾城"]},
	"cleverness": {"words": ["迟钝", "平庸", "机敏", "聪慧", "天才"]},
	"money": {"words": ["一贫如洗", "清贫", "小康", "富足", "巨富"]},
	"luck": {"words": ["霉运缠身", "平平", "顺遂", "好运连连", "天选之人"]},
	"emotion": {"words": ["郁郁寡欢", "烦闷", "平和", "快乐", "极乐"]},
}

static func evaluate(key: String, value: int) -> String:
	if not EVAL.has(key):
		return ""
	var entry: Dictionary = EVAL[key]
	if entry.has("stops"):
		var stops: Array = entry.stops
		var words: Array = entry.words
		var idx := 0
		for i in range(stops.size()):
			if value >= int(stops[i]):
				idx = i
		return str(words[idx])
	# 0-10 的属性：0-2 / 3-4 / 5-6 / 7-8 / 9+
	var w: Array = entry.words
	var tier := 0
	if value >= 9:
		tier = 4
	elif value >= 7:
		tier = 3
	elif value >= 5:
		tier = 2
	elif value >= 3:
		tier = 1
	return str(w[tier])
