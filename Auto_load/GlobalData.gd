extends Node

var choose_talents: Array[int] = []

var values: Array[int] = [0,0,0,0,0,0]
# 0 : 体质
# 1 : 颜值
# 2 : 智商
# 3 : 家境
# 4 : 运气
# 5 : 心情

var strong: int:
	get: return values[0]
	set(v): values[0] = v
var beauty: int:
	get: return values[1]
	set(v): values[1] = v
var cleverness: int:
	get: return values[2]
	set(v): values[2] = v
var money: int:
	get: return values[3]
	set(v): values[3] = v
var luck: int:
	get: return values[4]
	set(v): values[4] = v
var emotion: int:
	get: return values[5]
	set(v): values[5] = v

var age = 0
var gender = 0

# ==================== 种子系统 ====================
# seed_input：主菜单「通过种子开始」里玩家填的种子（0 = 用随机种子）
# run_seed  ：本局实际使用的种子（进天赋界面时确定，结算界面可复制）
var seed_input: int = 0
var run_seed: int = 0

# 结算画面用的结局摘要（修仙线等特殊结局在场景切换前写入）
var ending_summary: String = ""
# 结算画面用：本局新解锁的成就、本局经历的事件 id
var new_achievements: Array = []
var run_history: Array = []

func reset() -> void:
	choose_talents.clear()
	values = [0, 0, 0, 0, 0, 0]
	age = 0
	gender = 0
	ending_summary = ""
	new_achievements = []
	run_history = []
	seed_input = 0
	run_seed = 0
