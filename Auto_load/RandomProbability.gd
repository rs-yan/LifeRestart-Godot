extends Node

func chance(percent : int) -> bool :
	if randi_range(1,100)<=percent :
		return true
	else :
		return false
