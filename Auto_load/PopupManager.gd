extends Node


func show_popup(text: String, color: Color, duration: float) -> void:
	# 1. 用 CanvasLayer 确保弹窗永远在最上层，不被其他 UI 遮挡
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	
	# 2. 全屏 Control 作为容器，方便计算位置
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不阻挡鼠标点击
	layer.add_child(root)
	
	# 3. PanelContainer 作为弹窗背景
	var panel := PanelContainer.new()
	root.add_child(panel)
	
	# 4. 自定义弹窗样式：半透明黑底 + 彩色边框
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(15)
	panel.add_theme_stylebox_override("panel", style)
	
	# 5. Label 显示文字
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 40)
	panel.add_child(label)
	
	# 6. 等待一帧，让 PanelContainer 根据文字内容计算出实际大小
	await get_tree().process_frame
	
	# 7. 定位：水平居中，距离屏幕顶部 80 像素
	var viewport_size := root.size
	panel.position = Vector2((viewport_size.x - panel.size.x) / 2.0, 80.0)
	
	# 8. 停留指定时长
	await get_tree().create_timer(duration).timeout
	
	# 9. 淡出 + 向上滑动（同时进行）
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)                        # 淡出
	tween.tween_property(panel, "position:y", panel.position.y - 50.0, 0.3)     # 向上滑动 50 像素
	
	# 10. 动画结束后销毁弹窗
	await tween.finished
	layer.queue_free()
